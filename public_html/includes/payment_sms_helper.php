<?php
/**
 * includes/payment_sms_helper.php — Automated computation & SMS dispatch
 * for Pwestora rent receipts, pre-due reminders, and overdue grace notices.
 * ---------------------------------------------------------------------------
 * Constraints:
 *  - Never references unit numbers (uses "you" / "your monthly rent").
 *  - Calculates remaining monthly rent and remaining restructuring plan balances.
 *  - Applies ₱500 flat late fee upon post-grace overdue.
 *  - Uses PhilSMS Gateway via includes/sms.php.
 */

require_once __DIR__ . '/sms.php';

/**
 * Ensures the dedup tracking table for SMS reminders exists.
 */
function ensure_sms_reminder_logs_table(PDO $pdo): void {
    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS `sms_reminder_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `tenant_id` INT NOT NULL,
            `lessee_id` INT DEFAULT NULL,
            `billing_month` VARCHAR(7) NOT NULL,
            `reminder_type` ENUM('3_day_advance', 'overdue_grace', 'restructure_due') NOT NULL,
            `amount_due` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            `sent_to` VARCHAR(30) NOT NULL,
            `sms_message` TEXT NOT NULL,
            `sent_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_reminder` (`tenant_id`, `billing_month`, `reminder_type`),
            INDEX `idx_tenant_month` (`tenant_id`, `billing_month`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
    );
}

/**
 * Dispatches a dynamic SMS payment receipt with automated remaining balance computation.
 * Called when a lessor approves an online payment OR logs an offline payment (cash/check).
 *
 * @param PDO $pdo
 * @param int $paymentId
 * @return array{ok: bool, message?: string, error?: string}
 */
function send_payment_receipt_sms(PDO $pdo, int $paymentId): array {
    try {
        $stmt = $pdo->prepare(
            'SELECT pay.*, t.tenant_name, t.lessee_id, t.created_at AS lease_start,
                    a.rent AS monthly_rent,
                    u.phone AS lessee_phone, u.full_name AS lessee_full_name
             FROM payments pay
             JOIN tenants t ON t.id = pay.tenant_id
             LEFT JOIN applications a ON a.id = t.application_id
             LEFT JOIN users u ON u.id = t.lessee_id
             WHERE pay.id = ?'
        );
        $stmt->execute([$paymentId]);
        $pRow = $stmt->fetch();

        if (!$pRow) {
            return ['ok' => false, 'error' => 'Payment record not found.'];
        }

        $phone = $pRow['lessee_phone'] ?? '';
        if (empty($phone)) {
            return ['ok' => false, 'error' => 'Tenant has no registered mobile number.'];
        }

        $amountPaid = (float) $pRow['amount'];
        $monthlyRent = (float) ($pRow['monthly_rent'] ?? 0);
        $note = $pRow['note'] ?? '';

        // Extract reference number if present
        $refNo = '';
        if (preg_match('/Ref:\s*([A-Za-z0-9\-]+)/i', $note, $refMatch)) {
            $refNo = trim($refMatch[1]);
        }
        $refStr = $refNo ? " Ref #$refNo." : "";

        $isRestructuring = stripos($note, 'Restructuring') !== false;
        $isOverdue       = stripos($note, 'Overdue') !== false;

        // 1. Calculate Monthly Rent Remaining for current billing month
        $monthRentPaidStmt = $pdo->prepare(
            "SELECT COALESCE(SUM(amount), 0) FROM payments 
             WHERE tenant_id = ? AND (note LIKE '%[VERIFIED]%' OR id = ? OR logged_by IS NOT NULL)
               AND (note LIKE '%Monthly Rent%' OR note NOT LIKE '%Restructuring%')
               AND MONTH(paid_at) = MONTH(CURRENT_DATE()) AND YEAR(paid_at) = YEAR(CURRENT_DATE())"
        );
        $monthRentPaidStmt->execute([$pRow['tenant_id'], $paymentId]);
        $totalRentPaidThisMonth = (float) $monthRentPaidStmt->fetchColumn();
        $rentRemaining = max(0.0, $monthlyRent - $totalRentPaidThisMonth);

        // 2. Calculate Restructuring Plan Remaining if active
        $planStmt = $pdo->prepare(
            "SELECT * FROM installment_requests WHERE tenant_id = ? AND status = 'approved' ORDER BY id DESC LIMIT 1"
        );
        $planStmt->execute([$pRow['tenant_id']]);
        $activePlan = $planStmt->fetch();

        $planRemaining = 0.0;
        if ($activePlan) {
            $planTotal = (float) $activePlan['amount'];
            $planPaidStmt = $pdo->prepare(
                "SELECT COALESCE(SUM(amount), 0) FROM payments 
                 WHERE tenant_id = ? AND (note LIKE '%[VERIFIED]%' OR id = ? OR logged_by IS NOT NULL)
                   AND note LIKE '%Restructuring%'"
            );
            $planPaidStmt->execute([$pRow['tenant_id'], $paymentId]);
            $totalPlanPaid = (float) $planPaidStmt->fetchColumn();
            $planRemaining = max(0.0, $planTotal - $totalPlanPaid);
        }

        // 3. Formulate dynamic SMS receipt using personal "you" (no unit numbers)
        $formattedPaid = '₱' . number_format($amountPaid, 2);
        $smsBody = '';

        if ($isRestructuring) {
            $formattedPlanRemaining = '₱' . number_format($planRemaining, 2);
            if ($rentRemaining > 0 && $monthlyRent > 0) {
                $formattedRentRemaining = '₱' . number_format($rentRemaining, 2);
                $smsBody = "[Pwestora] Restructuring installment of $formattedPaid received!$refStr Remaining plan balance: $formattedPlanRemaining. Notice: You still have an unpaid monthly rent balance of $formattedRentRemaining.";
            } else {
                $smsBody = "[Pwestora] Restructuring installment of $formattedPaid received!$refStr Remaining plan balance: $formattedPlanRemaining. Your monthly rent is also fully settled. Thank you!";
            }
        } elseif ($isOverdue) {
            $smsBody = "[Pwestora] Overdue payment of $formattedPaid received!$refStr Your account is now updated and in good standing. Thank you!";
        } else {
            // Regular monthly rent
            if ($rentRemaining <= 0) {
                $smsBody = "[Pwestora] Payment received! $formattedPaid for your monthly rent.$refStr Your rent for this month is fully settled (Remaining balance: ₱0.00). Thank you!";
            } else {
                $formattedRentRemaining = '₱' . number_format($rentRemaining, 2);
                $smsBody = "[Pwestora] Partial rent payment of $formattedPaid received.$refStr Your remaining rent balance for this month is $formattedRentRemaining. Thank you!";
            }
        }

        $res = send_sms($phone, $smsBody);
        return [
            'ok'      => $res['ok'] ?? false,
            'message' => $smsBody,
            'result'  => $res,
        ];
    } catch (Throwable $e) {
        error_log('send_payment_receipt_sms error: ' . $e->getMessage());
        return ['ok' => false, 'error' => $e->getMessage()];
    }
}

/**
 * Executes the automated daily rent reminder workflow:
 *  1. 3-day advance pre-due reminder (reminds tenants before due date if rent is still unpaid).
 *  2. Post-grace overdue notice (triggers after grace period, applies ₱500 late fee & multi-month balance).
 *  3. Restructuring installment pre-due reminder (if active plan exists).
 *
 * @param PDO $pdo
 * @param bool $dryRun If true, computes balances and logs actions without dispatching real SMS.
 * @return array Detailed report of execution results.
 */
function run_daily_rent_reminders(PDO $pdo, bool $dryRun = false): array {
    ensure_sms_reminder_logs_table($pdo);

    $report = [
        'timestamp'         => date('Y-m-d H:i:s'),
        'dry_run'           => $dryRun,
        'tenants_checked'   => 0,
        'advance_sent'      => 0,
        'overdue_sent'      => 0,
        'plan_remind_sent'  => 0,
        'already_settled'   => 0,
        'already_reminded'  => 0,
        'skipped_no_phone'  => 0,
        'actions'           => [],
    ];

    // Fetch all active tenants with their application details and user profile
    $stmt = $pdo->query(
        "SELECT t.id AS tenant_id, t.tenant_name, t.lessee_id, t.created_at AS lease_start,
                a.rent AS monthly_rent, a.term_months,
                u.phone AS lessee_phone, u.full_name AS lessee_full_name
         FROM tenants t
         LEFT JOIN applications a ON a.id = t.application_id
         LEFT JOIN users u ON u.id = t.lessee_id
         ORDER BY t.id ASC"
    );
    $tenants = $stmt->fetchAll();

    $today = new DateTime('today');
    $currentYear  = (int) $today->format('Y');
    $currentMonth = (int) $today->format('m');
    $currentBillingMonth = $today->format('Y-m');
    $daysInMonth  = (int) $today->format('t');

    foreach ($tenants as $t) {
        $report['tenants_checked']++;
        $tenantId = (int) $t['tenant_id'];
        $phone = $t['lessee_phone'] ?? '';
        $monthlyRent = (float) ($t['monthly_rent'] ?? 0);

        if (empty($phone)) {
            $report['skipped_no_phone']++;
            $report['actions'][] = [
                'tenant_id' => $tenantId,
                'name'      => $t['tenant_name'],
                'status'    => 'skipped',
                'reason'    => 'No registered mobile number',
            ];
            continue;
        }

        // Determine monthly recurring due day based on lease start date
        $startDay = 1;
        if (!empty($t['lease_start'])) {
            $startDay = (int) date('j', strtotime($t['lease_start']));
        }
        $dueDay = min($startDay, $daysInMonth);
        $dueDateStr = sprintf('%04d-%02d-%02d', $currentYear, $currentMonth, $dueDay);
        $dueDate = new DateTime($dueDateStr);

        // Days until due date: positive = days before due date, 0 = due today, negative = past due
        $diff = (int) $today->diff($dueDate)->format('%r%a');

        // Calculate verified rent payments made by tenant this month
        $paidStmt = $pdo->prepare(
            "SELECT COALESCE(SUM(amount), 0) FROM payments
             WHERE tenant_id = ? AND (note LIKE '%[VERIFIED]%' OR logged_by IS NOT NULL)
               AND (note LIKE '%Monthly Rent%' OR note NOT LIKE '%Restructuring%')
               AND MONTH(paid_at) = ? AND YEAR(paid_at) = ?"
        );
        $paidStmt->execute([$tenantId, $currentMonth, $currentYear]);
        $rentPaidThisMonth = (float) $paidStmt->fetchColumn();
        $rentRemainingThisMonth = max(0.0, $monthlyRent - $rentPaidThisMonth);

        // Check if there is an active restructuring plan
        $planStmt = $pdo->prepare(
            "SELECT * FROM installment_requests WHERE tenant_id = ? AND status = 'approved' ORDER BY id DESC LIMIT 1"
        );
        $planStmt->execute([$tenantId]);
        $activePlan = $planStmt->fetch();

        // -------------------------------------------------------------
        // STAGE 1: 3-Day Advance Pre-Due Reminder
        // -------------------------------------------------------------
        // Trigger condition: Today is exactly 3 days before due date (diff == 3)
        // AND monthly rent is still unpaid.
        if ($diff === 3 && $rentRemainingThisMonth > 0) {
            // Check dedup log
            $logCheck = $pdo->prepare(
                "SELECT id FROM sms_reminder_logs WHERE tenant_id = ? AND billing_month = ? AND reminder_type = '3_day_advance'"
            );
            $logCheck->execute([$tenantId, $currentBillingMonth]);
            if ($logCheck->fetch()) {
                $report['already_reminded']++;
            } else {
                $formattedRent = '₱' . number_format($rentRemainingThisMonth, 2);
                $formattedDueDate = $dueDate->format('M d, Y');
                $advanceMsg = "[Pwestora] Friendly Reminder: Your monthly rent of $formattedRent is due in 3 days ($formattedDueDate). Please settle your payment on time via the Pwestora app to maintain good standing. Thank you!";

                $smsSuccess = true;
                if (!$dryRun) {
                    $smsRes = send_sms($phone, $advanceMsg);
                    $smsSuccess = $smsRes['ok'] ?? false;
                    $insertLog = $pdo->prepare(
                        "INSERT INTO sms_reminder_logs (tenant_id, lessee_id, billing_month, reminder_type, amount_due, sent_to, sms_message)
                         VALUES (?, ?, ?, '3_day_advance', ?, ?, ?)"
                    );
                    $insertLog->execute([
                        $tenantId,
                        $t['lessee_id'],
                        $currentBillingMonth,
                        $rentRemainingThisMonth,
                        $phone,
                        $advanceMsg,
                    ]);
                }

                $report['advance_sent']++;
                $report['actions'][] = [
                    'tenant_id' => $tenantId,
                    'name'      => $t['tenant_name'],
                    'type'      => '3_day_advance',
                    'amount'    => $rentRemainingThisMonth,
                    'message'   => $advanceMsg,
                    'dispatched'=> !$dryRun && $smsSuccess,
                ];
            }
        }

        // -------------------------------------------------------------
        // STAGE 2: Post-Grace Overdue Notice (₱500 Late Fee & Multi-Month)
        // -------------------------------------------------------------
        // In Pwestora lease terms, the grace period is 5 to 7 days.
        // Once diff <= -5 (5 or more days past due date), overdue notice is sent.
        if ($diff <= -5 && $rentRemainingThisMonth > 0 && !$activePlan) {
            // Check dedup log so overdue notice is sent once per billing cycle
            $logCheck = $pdo->prepare(
                "SELECT id FROM sms_reminder_logs WHERE tenant_id = ? AND billing_month = ? AND reminder_type = 'overdue_grace'"
            );
            $logCheck->execute([$tenantId, $currentBillingMonth]);
            if ($logCheck->fetch()) {
                $report['already_reminded']++;
            } else {
                // Calculate historical unpaid rent months
                // Find total months from lease start to now
                $leaseStartDate = new DateTime($t['lease_start'] ?: 'now');
                $monthsElapsed = max(1, ($currentYear - (int) $leaseStartDate->format('Y')) * 12 + ($currentMonth - (int) $leaseStartDate->format('m')) + 1);
                $totalExpectedRent = $monthsElapsed * $monthlyRent;

                $totalPaidStmt = $pdo->prepare(
                    "SELECT COALESCE(SUM(amount), 0) FROM payments
                     WHERE tenant_id = ? AND (note LIKE '%[VERIFIED]%' OR logged_by IS NOT NULL)
                       AND (note LIKE '%Monthly Rent%' OR note NOT LIKE '%Restructuring%')"
                );
                $totalPaidStmt->execute([$tenantId]);
                $totalPaidAllTime = (float) $totalPaidStmt->fetchColumn();

                $unpaidRentTotal = max($rentRemainingThisMonth, $totalExpectedRent - $totalPaidAllTime);

                // Add ₱500 flat late fee
                $lateFee = 500.00;
                $totalOverdueBalance = $unpaidRentTotal + $lateFee;

                $formattedBalance = '₱' . number_format($totalOverdueBalance, 2);
                $overdueMsg = "[Pwestora] URGENT: Your monthly rent is now OVERDUE as the grace period has ended. A late fee of ₱500.00 has been applied. Your new total balance is $formattedBalance. Please settle immediately in Pwestora to avoid account escalation.";

                $smsSuccess = true;
                if (!$dryRun) {
                    $smsRes = send_sms($phone, $overdueMsg);
                    $smsSuccess = $smsRes['ok'] ?? false;
                    $insertLog = $pdo->prepare(
                        "INSERT INTO sms_reminder_logs (tenant_id, lessee_id, billing_month, reminder_type, amount_due, sent_to, sms_message)
                         VALUES (?, ?, ?, 'overdue_grace', ?, ?, ?)"
                    );
                    $insertLog->execute([
                        $tenantId,
                        $t['lessee_id'],
                        $currentBillingMonth,
                        $totalOverdueBalance,
                        $phone,
                        $overdueMsg,
                    ]);
                }

                $report['overdue_sent']++;
                $report['actions'][] = [
                    'tenant_id' => $tenantId,
                    'name'      => $t['tenant_name'],
                    'type'      => 'overdue_grace',
                    'amount'    => $totalOverdueBalance,
                    'message'   => $overdueMsg,
                    'dispatched'=> !$dryRun && $smsSuccess,
                ];
            }
        }

        // -------------------------------------------------------------
        // STAGE 3: Restructuring Plan Due Reminder (if active)
        // -------------------------------------------------------------
        if ($activePlan && $diff === 3) {
            $planTotal = (float) $activePlan['amount'];
            $planPaidStmt = $pdo->prepare(
                "SELECT COALESCE(SUM(amount), 0) FROM payments 
                 WHERE tenant_id = ? AND (note LIKE '%[VERIFIED]%' OR logged_by IS NOT NULL)
                   AND note LIKE '%Restructuring%'"
            );
            $planPaidStmt->execute([$tenantId]);
            $planPaidSoFar = (float) $planPaidStmt->fetchColumn();
            $planRemaining = max(0.0, $planTotal - $planPaidSoFar);

            if ($planRemaining > 0) {
                $logCheck = $pdo->prepare(
                    "SELECT id FROM sms_reminder_logs WHERE tenant_id = ? AND billing_month = ? AND reminder_type = 'restructure_due'"
                );
                $logCheck->execute([$tenantId, $currentBillingMonth]);
                if ($logCheck->fetch()) {
                    $report['already_reminded']++;
                } else {
                    $formattedPlanRemaining = '₱' . number_format($planRemaining, 2);
                    $planMsg = "[Pwestora] Friendly Reminder: Your restructuring plan installment is due in 3 days. Your remaining balance is $formattedPlanRemaining. Please submit your payment via the Pwestora app. Thank you!";

                    $smsSuccess = true;
                    if (!$dryRun) {
                        $smsRes = send_sms($phone, $planMsg);
                        $smsSuccess = $smsRes['ok'] ?? false;
                        $insertLog = $pdo->prepare(
                            "INSERT INTO sms_reminder_logs (tenant_id, lessee_id, billing_month, reminder_type, amount_due, sent_to, sms_message)
                             VALUES (?, ?, ?, 'restructure_due', ?, ?, ?)"
                        );
                        $insertLog->execute([
                            $tenantId,
                            $t['lessee_id'],
                            $currentBillingMonth,
                            $planRemaining,
                            $phone,
                            $planMsg,
                        ]);
                    }

                    $report['plan_remind_sent']++;
                    $report['actions'][] = [
                        'tenant_id' => $tenantId,
                        'name'      => $t['tenant_name'],
                        'type'      => 'restructure_due',
                        'amount'    => $planRemaining,
                        'message'   => $planMsg,
                        'dispatched'=> !$dryRun && $smsSuccess,
                    ];
                }
            }
        }

        if ($rentRemainingThisMonth <= 0) {
            $report['already_settled']++;
        }
    }

    return $report;
}
