<?php
/**
 * GET /api/requests_list.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "requests": [ { id, reason, plan_label, amount, status, created_at }, ... ] }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

$tenantStmt = $pdo->prepare('SELECT id FROM tenants WHERE lessee_id = ? ORDER BY created_at DESC LIMIT 1');
$tenantStmt->execute([$lessee['id']]);
$tenantId = $tenantStmt->fetchColumn();

if (!$tenantId) {
    json_ok(['requests' => []]);
}

$stmt = $pdo->prepare(
    'SELECT id, reason, plan_label, amount, status, created_at
     FROM installment_requests WHERE tenant_id = ? ORDER BY created_at DESC'
);
$stmt->execute([$tenantId]);
$requests = $stmt->fetchAll();

foreach ($requests as &$r) {
    $r['amount'] = (float) $r['amount'];
}

json_ok(['requests' => $requests]);
