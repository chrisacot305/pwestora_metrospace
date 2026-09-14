<?php
/**
 * GET /api/tickets_list.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "tickets": [ { id, category, priority, title, stage, contractor, created_at }, ... ] }
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
    json_ok(['tickets' => []]); // no active lease yet — nothing to show
}

$stmt = $pdo->prepare(
    'SELECT id, category, priority, title, stage, contractor, created_at
     FROM maintenance_tickets WHERE tenant_id = ? ORDER BY created_at DESC'
);
$stmt->execute([$tenantId]);
$tickets = $stmt->fetchAll();

foreach ($tickets as &$t) {
    $t['stage'] = (int) $t['stage'];
}

json_ok(['tickets' => $tickets]);
