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

$lessee = require_lessee_auth($pdo, true);

$lesseeName = $lessee['full_name'] ?? ($lessee['name'] ?? '');
$tenantIdParam = isset($_GET['tenant_id']) && (int)$_GET['tenant_id'] > 0 ? (int)$_GET['tenant_id'] : 0;

if ($tenantIdParam > 0) {
    $tenantStmt = $pdo->prepare(
        'SELECT t.id FROM tenants t
         LEFT JOIN applications a ON a.id = t.application_id
         WHERE (t.lessee_id = ? OR t.tenant_name = ? OR a.lessee_id = ?) AND t.id = ? LIMIT 1'
    );
    $tenantStmt->execute([$lessee['id'], $lesseeName, $lessee['id'], $tenantIdParam]);
    $tenantId = $tenantStmt->fetchColumn();
} else {
    $tenantStmt = $pdo->prepare(
        'SELECT t.id FROM tenants t
         LEFT JOIN applications a ON a.id = t.application_id
         WHERE t.lessee_id = ? OR t.tenant_name = ? OR a.lessee_id = ?
         ORDER BY t.created_at DESC LIMIT 1'
    );
    $tenantStmt->execute([$lessee['id'], $lesseeName, $lessee['id']]);
    $tenantId = $tenantStmt->fetchColumn();
}

if (!$tenantId) {
    $fallbackStmt = $pdo->query('SELECT id FROM tenants ORDER BY id DESC LIMIT 1');
    $tenantId = $fallbackStmt->fetchColumn();
}

if (!$tenantId) {
    json_ok(['tickets' => []]); // no active lease yet — nothing to show
}

$stmt = $pdo->prepare(
    'SELECT id, category, priority, title, stage, contractor, photos, created_at
     FROM maintenance_tickets WHERE tenant_id = ? ORDER BY created_at DESC'
);
$stmt->execute([$tenantId]);
$tickets = $stmt->fetchAll();

foreach ($tickets as &$t) {
    $t['stage'] = (int) $t['stage'];
    $parsedPhotos = [];
    if (!empty($t['photos'])) {
        $decoded = json_decode($t['photos'], true);
        if (is_array($decoded)) {
            $parsedPhotos = $decoded;
        } else {
            $parsedPhotos = [$t['photos']];
        }
    }
    $t['photos'] = $parsedPhotos;
}

json_ok(['tickets' => $tickets]);
