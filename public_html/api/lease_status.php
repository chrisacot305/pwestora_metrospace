<?php
/**
 * GET /api/lease_status.php
 * Header: Authorization: Bearer <token>
 * Response when no active lease:
 *   { "ok": true, "has_lease": false }
 * Response when active:
 *   { "ok": true, "has_lease": true, "lease": {
 *       tenant_id, property_name, property_address, property_type,
 *       lessor_name, rent, term_months, open_tickets, since
 *   } }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

$stmt = $pdo->prepare(
    "SELECT t.id AS tenant_id, t.created_at AS since,
            p.id AS property_id, p.name AS property_name, p.address AS property_address, p.type AS property_type,
            (SELECT photo_path FROM property_photos pp WHERE pp.property_id = p.id ORDER BY pp.id ASC LIMIT 1) AS cover_photo,
            u.company_name AS lessor_name,
            COALESCE(a.rent, p.price, 0) AS rent,
            COALESCE(a.term_months, 12) AS term_months,
            COALESCE(a.business_name, t.tenant_name) AS business_name
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     JOIN users u ON u.id = t.lessor_id
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ?
     ORDER BY t.created_at DESC"
);
$stmt->execute([$lessee['id']]);
$allLeases = $stmt->fetchAll() ?: [];

// Also check for approved applications
$appStmt = $pdo->prepare(
    "SELECT a.id AS application_id, a.submitted_at AS since,
            p.id AS property_id, p.name AS property_name, p.address AS property_address, p.type AS property_type,
            (SELECT photo_path FROM property_photos pp WHERE pp.property_id = p.id ORDER BY pp.id ASC LIMIT 1) AS cover_photo,
            u.company_name AS lessor_name,
            a.rent, a.term_months, a.business_name
     FROM applications a
     JOIN properties p ON p.id = a.property_id
     JOIN users u ON u.id = a.lessor_id
     WHERE a.lessee_id = ? AND a.status = 'approved'
     ORDER BY a.submitted_at DESC"
);
$appStmt->execute([$lessee['id']]);
$approvedApps = $appStmt->fetchAll() ?: [];

$existingPropIds = array_column($allLeases, 'property_id');
foreach ($approvedApps as $app) {
    if (!in_array($app['property_id'], $existingPropIds)) {
        $app['tenant_id'] = $app['application_id'];
        $allLeases[] = $app;
        $existingPropIds[] = $app['property_id'];
    }
}

$userPayload = [
    'id'           => (int) $lessee['id'],
    'full_name'    => $lessee['full_name'] ?? ($lessee['name'] ?? ''),
    'company_name' => $lessee['company_name'] ?? '',
    'email'        => $lessee['email'] ?? '',
    'phone'        => $lessee['phone'] ?? '',
];

if (empty($allLeases)) {
    json_ok(['has_lease' => false, 'user' => $userPayload, 'leases' => []]);
}

foreach ($allLeases as &$l) {
    $l['rent'] = (float) ($l['rent'] ?? 0);
    $l['term_months'] = (int) ($l['term_months'] ?? 0);
    if (!empty($l['cover_photo'])) {
        $l['cover_photo'] = APP_URL . '/' . ltrim($l['cover_photo'], '/');
    }
}
unset($l);

$lease = $allLeases[0];
$companyName = !empty($lease['business_name'])
    ? $lease['business_name']
    : (!empty($lessee['company_name']) ? $lessee['company_name'] : '');
$userPayload['company_name'] = $companyName;

$ticketStmt = $pdo->prepare('SELECT COUNT(*) FROM maintenance_tickets WHERE tenant_id = ? AND stage < 7');
$ticketStmt->execute([$lease['tenant_id']]);
$lease['open_tickets'] = (int) $ticketStmt->fetchColumn();

json_ok(['has_lease' => true, 'lease' => $lease, 'leases' => $allLeases, 'user' => $userPayload]);

