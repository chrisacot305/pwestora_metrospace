<?php
/**
 * modules/payments.php  (Lessor → "Rent Payments")
 * Comprehensive payment ledger & verification queue.
 * Lessors can verify online tenant transfers (InstaPay / QR / Bank Transfer)
 * and manually log offline payments (cash, check).
 */
$lessorId = $user['id'];
$error = '';
$msg = $_GET['msg'] ?? '';

$METHODS = [
    'cash'          => 'Cash',
    'bank_transfer' => 'Bank Transfer / InstaPay',
    'gcash'         => 'GCash',
    'check'         => 'Check',
    'other'         => 'Other',
];

// Helper to parse payment targets & reference numbers from notes
function parse_payment_note(?string $note): array {
    $res = [
        'target' => 'Monthly Rent',
        'ref'    => '—',
        'raw'    => $note ?? '',
        'status' => 'recorded',
    ];
    if (!$note) return $res;

    if (str_starts_with($note, '[PENDING]')) {
        $res['status'] = 'pending';
    } elseif (str_starts_with($note, '[VERIFIED]')) {
        $res['status'] = 'verified';
    } elseif (str_starts_with($note, '[DECLINED')) {
        $res['status'] = 'declined';
    }

    if (preg_match('/Target:\s*([^|]+)/i', $note, $m)) {
        $res['target'] = trim($m[1]);
    }
    if (preg_match('/Ref:\s*([^|]+)/i', $note, $m)) {
        $res['ref'] = trim($m[1]);
    }
    return $res;
}

// 1. APPROVE / CONFIRM PAYMENT ACTION
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'approve_payment') {
    csrf_check();
    $paymentId = (int) ($_POST['payment_id'] ?? 0);

    try {
        $check = $pdo->prepare(
            'SELECT pay.*, t.tenant_name FROM payments pay
             JOIN tenants t ON t.id = pay.tenant_id
             WHERE pay.id = ? AND pay.lessor_id = ?'
        );
        $check->execute([$paymentId, $lessorId]);
        $pRow = $check->fetch();

        if ($pRow) {
            $currentNote = $pRow['note'] ?? '';
            $newNote = str_contains($currentNote, '[PENDING]')
                ? str_replace('[PENDING]', '[VERIFIED]', $currentNote)
                : ('[VERIFIED] ' . $currentNote);

            $update = $pdo->prepare('UPDATE payments SET logged_by = ?, note = ? WHERE id = ?');
            $update->execute([$lessorId, $newNote, $paymentId]);

            audit_log(
                $pdo,
                $lessorId,
                'Confirmed Tenant Payment',
                '₱' . number_format($pRow['amount'], 2) . ' from ' . $pRow['tenant_name']
            );

            header('Location: /dashboard.php?page=payments&msg=approved');
            exit;
        } else {
            $error = 'Payment record not found or unauthorized.';
        }
    } catch (Throwable $e) {
        error_log('Approve payment error: ' . $e->getMessage());
        $error = 'Could not approve this payment. Please try again.';
    }
}

// 2. DECLINE PAYMENT ACTION
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'decline_payment') {
    csrf_check();
    $paymentId = (int) ($_POST['payment_id'] ?? 0);
    $reason = trim($_POST['decline_reason'] ?? 'Declined by lessor');

    try {
        $check = $pdo->prepare(
            'SELECT pay.*, t.tenant_name FROM payments pay
             JOIN tenants t ON t.id = pay.tenant_id
             WHERE pay.id = ? AND pay.lessor_id = ?'
        );
        $check->execute([$paymentId, $lessorId]);
        $pRow = $check->fetch();

        if ($pRow) {
            $currentNote = $pRow['note'] ?? '';
            $tag = '[DECLINED: ' . htmlspecialchars($reason) . ']';
            $newNote = str_contains($currentNote, '[PENDING]')
                ? str_replace('[PENDING]', $tag, $currentNote)
                : ($tag . ' ' . $currentNote);

            $update = $pdo->prepare('UPDATE payments SET logged_by = NULL, note = ? WHERE id = ?');
            $update->execute([$newNote, $paymentId]);

            audit_log(
                $pdo,
                $lessorId,
                'Declined Tenant Payment',
                '₱' . number_format($pRow['amount'], 2) . ' from ' . $pRow['tenant_name'] . ' (' . $reason . ')'
            );

            header('Location: /dashboard.php?page=payments&msg=declined');
            exit;
        } else {
            $error = 'Payment record not found or unauthorized.';
        }
    } catch (Throwable $e) {
        error_log('Decline payment error: ' . $e->getMessage());
        $error = 'Could not decline this payment. Please try again.';
    }
}

// 3. LOG MANUAL PAYMENT (Offline: Cash, Check, etc.)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_payment'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $amount   = (float) $_POST['amount'];
    $method   = $_POST['method'] ?? 'cash';
    $paidAt   = $_POST['paid_at'] ?? '';
    $note     = trim($_POST['note'] ?? '');

    $check = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);
    $tRow = $check->fetch();

    $validDate = DateTime::createFromFormat('Y-m-d', $paidAt) !== false;

    if (!$tRow || $amount <= 0 || !isset($METHODS[$method]) || !$validDate) {
        $error = 'Please fill in every field with a valid tenant, amount, method, and date.';
    } else {
        try {
            $pdo->prepare(
                'INSERT INTO payments (tenant_id, lessor_id, amount, method, note, paid_at, logged_by)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute([$tenantId, $lessorId, $amount, $method, $note ?: null, $paidAt, $lessorId]);

            audit_log($pdo, $lessorId, 'Logged rent payment', "₱$amount via {$METHODS[$method]} for {$tRow['tenant_name']}");
            header('Location: /dashboard.php?page=payments&msg=logged');
            exit;
        } catch (Throwable $e) {
            error_log('Log payment failed: ' . $e->getMessage());
            $error = 'Could not log this payment — the error has been logged. Please try again.';
        }
    }
}

// PENDING INCOMING PAYMENTS (awaiting lessor review)
$pendingQuery = $pdo->prepare(
    "SELECT pay.*, t.tenant_name, p.name AS property_name
     FROM payments pay
     JOIN tenants t ON t.id = pay.tenant_id
     LEFT JOIN properties p ON p.id = t.property_id
     WHERE pay.lessor_id = ? AND (pay.logged_by IS NULL OR pay.note LIKE '[PENDING]%') AND (pay.note NOT LIKE '[DECLINED%')
     ORDER BY pay.id DESC"
);
$pendingQuery->execute([$lessorId]);
$pendingPayments = $pendingQuery->fetchAll();

// HISTORICAL / RECORDED PAYMENTS
$historyQuery = $pdo->prepare(
    "SELECT pay.*, t.tenant_name, p.name AS property_name
     FROM payments pay
     JOIN tenants t ON t.id = pay.tenant_id
     LEFT JOIN properties p ON p.id = t.property_id
     WHERE pay.lessor_id = ? AND (pay.logged_by IS NOT NULL OR pay.note LIKE '[DECLINED%')
     ORDER BY pay.paid_at DESC, pay.id DESC LIMIT 100"
);
$historyQuery->execute([$lessorId]);
$historyPayments = $historyQuery->fetchAll();

// TENANTS FOR MANUAL LOGGING FORM
$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

// STATS
$pendingTotal = array_sum(array_column($pendingPayments, 'amount'));
$monthTotalStmt = $pdo->prepare(
    "SELECT COALESCE(SUM(amount), 0) FROM payments
     WHERE lessor_id = ? AND logged_by IS NOT NULL
     AND paid_at >= DATE_FORMAT(CURDATE(), '%Y-%m-01')"
);
$monthTotalStmt->execute([$lessorId]);
$monthTotal = (float) $monthTotalStmt->fetchColumn();
?>

<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:20px; flex-wrap:wrap; gap:12px;">
  <div>
    <h2 style="margin:0 0 4px;">Rent Payments</h2>
    <p style="color:var(--ink-500); margin:0;">
      Verify incoming tenant InstaPay transfers and manage your rent ledger.
    </p>
  </div>
</div>

<?php if ($msg === 'approved'): ?>
  <div class="success-msg" style="display:flex; align-items:center; gap:8px;">
    <i class="bi bi-check-circle-fill"></i>
    <span><strong>Payment Confirmed!</strong> The payment has been verified, recorded in the ledger, and the tenant's app balance has been updated.</span>
  </div>
<?php elseif ($msg === 'declined'): ?>
  <div class="error-msg" style="display:flex; align-items:center; gap:8px;">
    <i class="bi bi-x-circle-fill"></i>
    <span><strong>Payment Declined.</strong> The submission was declined and marked accordingly.</span>
  </div>
<?php elseif ($msg === 'logged'): ?>
  <div class="success-msg" style="display:flex; align-items:center; gap:8px;">
    <i class="bi bi-check-circle-fill"></i>
    <span>Manual payment entry recorded successfully.</span>
  </div>
<?php endif; ?>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- Summary KPI Grid -->
<div class="kpi-grid" style="margin-bottom:24px;">
  <div class="card" style="border-left: 3px solid <?= count($pendingPayments) > 0 ? 'var(--warning)' : 'var(--border)' ?>;">
    <div class="kpi-label">Pending Verification</div>
    <div class="kpi-value" style="color:<?= count($pendingPayments) > 0 ? 'var(--primary)' : 'inherit' ?>;">
      <?= count($pendingPayments) ?> <span style="font-size:14px; font-weight:600; color:var(--ink-500);">(₱<?= number_format($pendingTotal, 2) ?>)</span>
    </div>
  </div>
  <div class="card">
    <div class="kpi-label">Verified This Month</div>
    <div class="kpi-value">₱<?= number_format($monthTotal, 2) ?></div>
  </div>
  <div class="card">
    <div class="kpi-label">Total Verified Records</div>
    <div class="kpi-value"><?= count($historyPayments) ?></div>
  </div>
</div>

<!-- =============================================================
     SECTION 1: INCOMING TENANT PAYMENTS (AWAITING VERIFICATION)
     ============================================================= -->
<div class="card" style="margin-bottom:28px; padding:0; overflow:hidden; border: 1px solid <?= count($pendingPayments) > 0 ? 'var(--tint)' : 'var(--border)' ?>;">
  <div style="padding:16px 20px; background:var(--surface); border-bottom:1px solid var(--border); display:flex; justify-content:space-between; align-items:center;">
    <div style="display:flex; align-items:center; gap:10px;">
      <div style="width:32px; height:32px; border-radius:8px; background:var(--accent-soft); color:var(--primary); display:flex; align-items:center; justify-content:center;">
        <i class="bi bi-qr-code"></i>
      </div>
      <div>
        <h3 style="margin:0; font-size:15px; font-weight:700;">Incoming Transfers Awaiting Verification</h3>
        <p style="margin:2px 0 0; font-size:12px; color:var(--ink-500);">
          Submitted by tenants via QR Code / InstaPay / Bank Transfer from the mobile app.
        </p>
      </div>
    </div>
    <?php if (count($pendingPayments) > 0): ?>
      <span class="badge badge-pending"><?= count($pendingPayments) ?> Pending Review</span>
    <?php endif; ?>
  </div>

  <div class="table-scroll">
    <table>
      <thead>
        <tr>
          <th>Tenant</th>
          <th>Amount</th>
          <th>Payment Target</th>
          <th>Reference Number</th>
          <th>Date Submitted</th>
          <th style="text-align:right;">Verification Action</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$pendingPayments): ?>
          <tr>
            <td colspan="6" style="text-align:center; padding:32px 16px; color:var(--ink-500);">
              <i class="bi bi-check2-circle" style="font-size:24px; color:var(--success); display:block; margin-bottom:6px;"></i>
              No pending payment submissions. All transfers have been verified.
            </td>
          </tr>
        <?php else: foreach ($pendingPayments as $p):
          $parsed = parse_payment_note($p['note']);
        ?>
          <tr>
            <td>
              <div style="font-weight:700; color:var(--ink-900);"><?= htmlspecialchars($p['tenant_name']) ?></div>
              <?php if (!empty($p['property_name'])): ?>
                <div style="font-size:11.5px; color:var(--ink-500);"><?= htmlspecialchars($p['property_name']) ?></div>
              <?php endif; ?>
            </td>
            <td>
              <span style="font-size:15px; font-weight:800; color:var(--primary);">
                ₱<?= number_format($p['amount'], 2) ?>
              </span>
            </td>
            <td>
              <span class="badge" style="background:var(--accent-soft); color:var(--primary); font-size:11.5px;">
                <i class="bi bi-tag" style="margin-right:3px;"></i><?= htmlspecialchars($parsed['target']) ?>
              </span>
            </td>
            <td>
              <code style="font-family:ui-monospace,SFMono-Regular,Consolas,monospace; font-size:12.5px; font-weight:700; background:var(--bg); padding:4px 8px; border-radius:6px; border:1px solid var(--border); color:var(--primary);">
                <?= htmlspecialchars($parsed['ref']) ?>
              </code>
            </td>
            <td style="color:var(--ink-500); font-size:13px;">
              <?= (new DateTime($p['paid_at']))->format('M j, Y') ?>
            </td>
            <td style="text-align:right;">
              <div style="display:inline-flex; gap:8px; justify-content:flex-end;">
                <!-- Confirm / Approve Button -->
                <form method="POST" style="margin:0;">
                  <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
                  <input type="hidden" name="action" value="approve_payment">
                  <input type="hidden" name="payment_id" value="<?= $p['id'] ?>">
                  <button type="submit" class="btn" style="padding:7px 14px; font-size:12.5px; background:var(--success); color:#fff; border-radius:8px;">
                    <i class="bi bi-check-circle-fill"></i> Confirm Received
                  </button>
                </form>

                <!-- Decline Button -->
                <form method="POST" style="margin:0;" onsubmit="return confirm('Are you sure you want to decline this transfer?');">
                  <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
                  <input type="hidden" name="action" value="decline_payment">
                  <input type="hidden" name="payment_id" value="<?= $p['id'] ?>">
                  <button type="submit" class="btn" style="padding:7px 12px; font-size:12.5px; background:var(--error-soft); color:var(--error); border-radius:8px;">
                    <i class="bi bi-x-circle"></i> Decline
                  </button>
                </form>
              </div>
            </td>
          </tr>
        <?php endforeach; endif; ?>
      </tbody>
    </table>
  </div>
</div>

<!-- =============================================================
     SECTION 2: VERIFIED PAYMENTS LEDGER & MANUAL LOGGING
     ============================================================= -->
<div style="display:grid; grid-template-columns: 2fr 1fr; gap:24px; align-items:start;">
  <!-- Verified Ledger -->
  <div class="card" style="padding:0; overflow:hidden;">
    <div style="padding:14px 18px; background:var(--surface); border-bottom:1px solid var(--border);">
      <h3 style="margin:0; font-size:14px; font-weight:700;">Verified Payment Ledger</h3>
      <p style="margin:2px 0 0; font-size:12px; color:var(--ink-500);">
        Credited payments visible to tenants in their mobile app ledger.
      </p>
    </div>

    <div class="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Tenant</th>
            <th>Amount</th>
            <th>Method</th>
            <th>Details & Reference</th>
            <th>Date</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <?php if (!$historyPayments): ?>
            <tr>
              <td colspan="6" style="text-align:center; padding:24px; color:var(--ink-500);">
                No verified payments in the ledger yet.
              </td>
            </tr>
          <?php else: foreach ($historyPayments as $p):
            $parsed = parse_payment_note($p['note']);
            $isDeclined = $parsed['status'] === 'declined';
          ?>
            <tr>
              <td style="font-weight:600;"><?= htmlspecialchars($p['tenant_name']) ?></td>
              <td style="font-weight:700; color:<?= $isDeclined ? 'var(--ink-500)' : 'var(--ink-900)' ?>;">
                ₱<?= number_format($p['amount'], 2) ?>
              </td>
              <td style="color:var(--ink-500); font-size:12.5px;">
                <?= htmlspecialchars($METHODS[$p['method']] ?? $p['method']) ?>
              </td>
              <td>
                <div style="font-size:12px;">
                  <?php if ($parsed['target'] !== 'Monthly Rent'): ?>
                    <span style="font-weight:600; color:var(--primary);"><?= htmlspecialchars($parsed['target']) ?></span>
                  <?php endif; ?>
                  <?php if ($parsed['ref'] !== '—'): ?>
                    <span style="color:var(--ink-500); font-family:monospace; margin-left:4px;">Ref: <?= htmlspecialchars($parsed['ref']) ?></span>
                  <?php elseif (!empty($p['note']) && !$isDeclined): ?>
                    <span style="color:var(--ink-500);"><?= htmlspecialchars($p['note']) ?></span>
                  <?php else: ?>
                    <span style="color:var(--ink-300);">—</span>
                  <?php endif; ?>
                </div>
              </td>
              <td style="color:var(--ink-500); font-size:12.5px;">
                <?= (new DateTime($p['paid_at']))->format('M j, Y') ?>
              </td>
              <td>
                <?php if ($isDeclined): ?>
                  <span class="badge badge-rejected" style="font-size:11px;">Declined</span>
                <?php elseif ($p['logged_by'] !== null): ?>
                  <span class="badge badge-approved" style="font-size:11px;">
                    <i class="bi bi-shield-check" style="margin-right:2px;"></i> Verified
                  </span>
                <?php else: ?>
                  <span class="badge badge-pending" style="font-size:11px;">Pending</span>
                <?php endif; ?>
              </td>
            </tr>
          <?php endforeach; endif; ?>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Manual Logging Card -->
  <div class="card">
    <p style="font-weight:700; font-size:14px; margin:0 0 4px;">Log Offline Payment</p>
    <p style="font-size:12.5px; color:var(--ink-500); margin:0 0 16px;">
      Directly record payments received in cash, cheque, or OTC deposit.
    </p>

    <?php if (!$tenants): ?>
      <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet.</p>
    <?php else: ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="log_payment" value="1">
        <div class="field">
          <label>Tenant</label>
          <select name="tenant_id" required>
            <option value="">Select tenant…</option>
            <?php foreach ($tenants as $t): ?>
              <option value="<?= $t['id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="field">
          <label>Amount (₱)</label>
          <input type="number" name="amount" min="1" step="0.01" placeholder="e.g. 2500" required>
        </div>
        <div class="field">
          <label>Payment Method</label>
          <select name="method" required>
            <?php foreach ($METHODS as $key => $label): ?>
              <option value="<?= $key ?>"><?= $label ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="field">
          <label>Date Received</label>
          <input type="date" name="paid_at" value="<?= date('Y-m-d') ?>" required>
        </div>
        <div class="field">
          <label>Note / Remarks (optional)</label>
          <input type="text" name="note" placeholder="e.g. Official Receipt #10492">
        </div>
        <button class="btn btn-primary" type="submit" style="margin-top:6px;">
          <i class="bi bi-save2"></i> Log Payment
        </button>
      </form>
    <?php endif; ?>
  </div>
</div>
