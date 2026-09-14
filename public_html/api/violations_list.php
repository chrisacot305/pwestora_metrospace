<?php
/**
 * GET /api/violations_list.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "violations": [ { id, category, strike, acknowledged, issued_at }, ... ] }
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
    json_ok(['violations' => []]);
}

$stmt = $pdo->prepare(
    'SELECT id, category, strike, acknowledged, issued_at
     FROM violations WHERE tenant_id = ? ORDER BY issued_at DESC'
);
$stmt->execute([$tenantId]);
$violations = $stmt->fetchAll();

foreach ($violations as &$v) {
    $v['strike'] = (int) $v['strike'];
    $v['acknowledged'] = (bool) $v['acknowledged'];
}

json_ok(['violations' => $violations]);
