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
            p.name AS property_name, p.address AS property_address, p.type AS property_type,
            u.company_name AS lessor_name,
            a.rent, a.term_months
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     JOIN users u ON u.id = t.lessor_id
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ?
     ORDER BY t.created_at DESC
     LIMIT 1"
);
$stmt->execute([$lessee['id']]);
$lease = $stmt->fetch();

if (!$lease) {
    json_ok(['has_lease' => false]);
}

$lease['rent'] = (float) ($lease['rent'] ?? 0);
$lease['term_months'] = (int) ($lease['term_months'] ?? 0);

$ticketStmt = $pdo->prepare('SELECT COUNT(*) FROM maintenance_tickets WHERE tenant_id = ? AND stage < 7');
$ticketStmt->execute([$lease['tenant_id']]);
$lease['open_tickets'] = (int) $ticketStmt->fetchColumn();

json_ok(['has_lease' => true, 'lease' => $lease]);
