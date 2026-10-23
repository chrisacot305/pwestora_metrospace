<?php
/**
 * GET /api/lease_status.php
 * Header: Authorization: Bearer <token>
 * Response when no active lease:
 *   { "ok": true, "has_lease": false }
 * Response when active:
 *   { "ok": true, "has_lease": true, "lease": { ... }, "leases": [ ... ] }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

$stmt = $pdo->prepare(
    "SELECT t.id AS tenant_id, t.property_id, t.created_at AS since,
            t.start_date, t.end_date, t.due_day,
            COALESCE(NULLIF(t.business_name, ''), a.business_name, '') AS business_name,
            t.unit_label,
            p.name AS property_name, p.address AS property_address, p.type AS property_type,
            p.description AS property_description, p.floor_area, p.lease_term, p.escalation,
            p.latitude, p.longitude,
            (SELECT photo_path FROM property_photos pp WHERE pp.property_id = p.id ORDER BY pp.id ASC LIMIT 1) AS cover_photo,
            u.company_name AS lessor_name, u.email AS lessor_email, u.phone AS lessor_phone,
            a.rent, a.term_months
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     JOIN users u ON u.id = t.lessor_id
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ?
     ORDER BY t.created_at DESC"
 );
$stmt->execute([$lessee['id']]);
$leases = $stmt->fetchAll();

$userPayload = [
    'id'        => (int) $lessee['id'],
    'full_name' => $lessee['full_name'] ?? ($lessee['name'] ?? ''),
    'email'     => $lessee['email'] ?? '',
    'phone'     => $lessee['phone'] ?? '',
];

if (empty($leases)) {
    json_ok(['has_lease' => false, 'user' => $userPayload]);
}

$ticketStmt = $pdo->prepare('SELECT COUNT(*) FROM maintenance_tickets WHERE tenant_id = ? AND stage < 7');

foreach ($leases as &$l) {
    $l['tenant_id'] = (int) $l['tenant_id'];
    $l['property_id'] = (int) ($l['property_id'] ?? 0);
    $l['rent'] = (float) ($l['rent'] ?? 0);
    $l['term_months'] = (int) ($l['term_months'] ?? 0);
    if (!empty($l['cover_photo'])) {
        $l['cover_photo'] = APP_URL . '/' . ltrim($l['cover_photo'], '/');
    }
    $ticketStmt->execute([$l['tenant_id']]);
    $l['open_tickets'] = (int) $ticketStmt->fetchColumn();
}

$primaryLease = $leases[0];

json_ok([
    'has_lease' => true,
    'lease'     => $primaryLease,
    'leases'    => $leases,
    'user'      => $userPayload
]);
