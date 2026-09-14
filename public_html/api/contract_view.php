<?php
/**
 * GET /api/contract_view.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "contract": {
 *   tenant_name, lessor_name, property_name, property_address, property_type,
 *   rent, term_months, since, clauses: [ { label, text }, ... ]
 * } }
 * Returns has_lease:false if the tenant doesn't have an active lease yet.
 */
require __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../includes/lease_checklist.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

$stmt = $pdo->prepare(
    "SELECT t.created_at AS since,
            p.name AS property_name, p.address AS property_address, p.type AS property_type,
            u.company_name AS lessor_name,
            a.rent, a.term_months
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     JOIN users u ON u.id = t.lessor_id
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ?
     ORDER BY t.created_at DESC LIMIT 1"
);
$stmt->execute([$lessee['id']]);
$lease = $stmt->fetch();

if (!$lease) {
    json_ok(['has_lease' => false]);
}

$clauses = [];
foreach ($LEASE_CHECKLIST_ITEMS as $item) {
    $clauses[] = ['label' => $item['label'], 'text' => $item['text']];
}

json_ok([
    'has_lease' => true,
    'contract' => [
        'tenant_name'       => $lessee['full_name'],
        'lessor_name'       => $lease['lessor_name'],
        'property_name'     => $lease['property_name'],
        'property_address'  => $lease['property_address'],
        'property_type'     => $lease['property_type'],
        'rent'              => (float) ($lease['rent'] ?? 0),
        'term_months'       => (int) ($lease['term_months'] ?? 0),
        'since'             => $lease['since'],
        'clauses'           => $clauses,
    ],
]);
