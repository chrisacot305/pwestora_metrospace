<?php
/**
 * GET /api/applications_mine.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "applications": [ { id, property_name, term_months, rent, status, submitted_at }, ... ] }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

try {
    $stmt = $pdo->prepare(
        "SELECT a.id, a.term_months, a.rent, a.status, a.submitted_at,
                a.checklist_negotiation, a.lessor_rebuttal, a.rebuttal_at,
                p.name AS property_name, u.company_name AS lessor_name
         FROM applications a
         JOIN properties p ON p.id = a.property_id
         JOIN users u ON u.id = a.lessor_id
         WHERE a.lessee_id = ?
         ORDER BY a.submitted_at DESC"
    );
    $stmt->execute([$lessee['id']]);
    $applications = $stmt->fetchAll();
} catch (Throwable $e) {
    $stmt = $pdo->prepare(
        "SELECT a.id, a.term_months, a.rent, a.status, a.submitted_at,
                p.name AS property_name, u.company_name AS lessor_name
         FROM applications a
         JOIN properties p ON p.id = a.property_id
         JOIN users u ON u.id = a.lessor_id
         WHERE a.lessee_id = ?
         ORDER BY a.submitted_at DESC"
    );
    $stmt->execute([$lessee['id']]);
    $applications = $stmt->fetchAll();
}

// MySQL/PDO returns DECIMAL columns as strings — cast explicitly so the
// JSON output has real numbers, not "68000.00" as text.
foreach ($applications as &$a) {
    $a['rent'] = (float) $a['rent'];
    $a['term_months'] = (int) $a['term_months'];
    $messages = [];
    if (isset($a['checklist_negotiation']) && is_string($a['checklist_negotiation'])) {
        $decoded = json_decode($a['checklist_negotiation'], true);
        if (is_array($decoded)) {
            $a['checklist_negotiation'] = $decoded;
        }
    }
    if (isset($a['checklist_negotiation']['messages']) && is_array($a['checklist_negotiation']['messages'])) {
        $messages = $a['checklist_negotiation']['messages'];
    }
    $a['negotiation_messages'] = $messages;
}

json_ok(['applications' => $applications]);