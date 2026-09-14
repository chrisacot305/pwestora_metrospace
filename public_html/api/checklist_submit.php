<?php
/**
 * POST /api/checklist_submit.php
 * Header: Authorization: Bearer <token>
 * Body: { "acknowledged_keys": ["security_deposit", "rent_escalation", ...] }
 * All keys from checklist_items.php must be present, or this fails —
 * this is meant to be required, not optional, per item.
 * Response: { "ok": true }
 */
require __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../includes/lease_checklist.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();
$submitted = $body['acknowledged_keys'] ?? [];

$requiredKeys = array_keys($LEASE_CHECKLIST_ITEMS);
$missing = array_diff($requiredKeys, $submitted);

if (!empty($missing)) {
    json_error('All checklist items must be acknowledged before continuing.');
}

$stmt = $pdo->prepare(
    'INSERT INTO lease_checklist_acknowledgments (user_id, item_key) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE acknowledged_at = NOW()'
);
foreach ($requiredKeys as $key) {
    $stmt->execute([$lessee['id'], $key]);
}

json_ok([]);
