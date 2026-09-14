<?php
/**
 * POST /api/violations_acknowledge.php
 * Header: Authorization: Bearer <token>
 * Body: { "violation_id": 41 }
 * Response: { "ok": true }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();
$violationId = (int) ($body['violation_id'] ?? 0);

$stmt = $pdo->prepare(
    'UPDATE violations v
     JOIN tenants t ON t.id = v.tenant_id
     SET v.acknowledged = 1
     WHERE v.id = ? AND t.lessee_id = ?'
);
$stmt->execute([$violationId, $lessee['id']]);

if ($stmt->rowCount() === 0) {
    json_error('Violation not found.', 404);
}

json_ok([]);
