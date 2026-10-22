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

$tenantIdParam = isset($_GET['tenant_id']) && (int)$_GET['tenant_id'] > 0 ? (int)$_GET['tenant_id'] : 0;

if ($tenantIdParam > 0) {
    $tenantStmt = $pdo->prepare('SELECT id FROM tenants WHERE lessee_id = ? AND id = ? LIMIT 1');
    $tenantStmt->execute([$lessee['id'], $tenantIdParam]);
    $tenantId = $tenantStmt->fetchColumn();
    if (!$tenantId) {
        json_ok(['violations' => []]);
    }
    $stmt = $pdo->prepare(
        'SELECT v.id, v.tenant_id, v.lessor_id, u.company_name AS lessor_name,
                v.category, v.strike, v.acknowledged, v.issued_at
         FROM violations v
         JOIN users u ON u.id = v.lessor_id
         WHERE v.tenant_id = ?
         ORDER BY v.issued_at DESC'
    );
    $stmt->execute([$tenantId]);
} else {
    $stmt = $pdo->prepare(
        'SELECT v.id, v.tenant_id, v.lessor_id, u.company_name AS lessor_name,
                v.category, v.strike, v.acknowledged, v.issued_at
         FROM violations v
         JOIN users u ON u.id = v.lessor_id
         JOIN tenants t ON t.id = v.tenant_id
         WHERE t.lessee_id = ?
         ORDER BY v.issued_at DESC'
    );
    $stmt->execute([$lessee['id']]);
}
$violations = $stmt->fetchAll();

foreach ($violations as &$v) {
    $v['id'] = (int) $v['id'];
    $v['tenant_id'] = (int) $v['tenant_id'];
    $v['lessor_id'] = (int) $v['lessor_id'];
    $v['strike'] = (int) $v['strike'];
    $v['acknowledged'] = (bool) $v['acknowledged'];
}

json_ok(['violations' => $violations]);
