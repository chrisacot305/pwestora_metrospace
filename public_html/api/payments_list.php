<?php
/**
 * GET /api/payments_list.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "payments": [ { id, amount, method, note, paid_at }, ... ] }
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
    json_ok(['payments' => []]);
}

$stmt = $pdo->prepare(
    'SELECT id, amount, method, note, paid_at FROM payments WHERE tenant_id = ? ORDER BY paid_at DESC, id DESC'
);
$stmt->execute([$tenantId]);
$payments = $stmt->fetchAll();

foreach ($payments as &$p) {
    $p['amount'] = (float) $p['amount'];
}

json_ok(['payments' => $payments]);
