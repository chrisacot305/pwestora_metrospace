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

$lessee = require_lessee_auth($pdo, true);

$lesseeName = $lessee['full_name'] ?? ($lessee['name'] ?? '');
$tenantStmt = $pdo->prepare(
    'SELECT t.id FROM tenants t
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ? OR t.tenant_name = ? OR a.lessee_id = ?
     ORDER BY t.created_at DESC LIMIT 1'
);
$tenantStmt->execute([$lessee['id'], $lesseeName, $lessee['id']]);
$tenantId = $tenantStmt->fetchColumn();

if (!$tenantId) {
    $fallbackStmt = $pdo->query('SELECT id FROM tenants ORDER BY id DESC LIMIT 1');
    $tenantId = $fallbackStmt->fetchColumn();
}

if (!$tenantId) {
    json_ok(['payments' => []]);
}

$stmt = $pdo->prepare(
    'SELECT id, amount, method, note, paid_at, logged_by FROM payments WHERE tenant_id = ? ORDER BY paid_at DESC, id DESC'
);
$stmt->execute([$tenantId]);
$payments = $stmt->fetchAll();

foreach ($payments as &$p) {
    $p['id'] = (int) $p['id'];
    $p['amount'] = (float) $p['amount'];
    $isPending = ($p['logged_by'] === null || (is_string($p['note'] ?? '') && str_starts_with($p['note'], '[PENDING]')));
    $p['status'] = $isPending ? 'pending' : 'approved';
}

json_ok(['payments' => $payments]);
