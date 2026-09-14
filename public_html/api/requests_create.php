<?php
/**
 * POST /api/requests_create.php
 * Header: Authorization: Bearer <token>
 * Body: { "reason": "...", "plan_label": "2 payments" | "3 payments" }
 * Amount is derived server-side from the tenant's actual monthly rent —
 * never trust a client-supplied amount for something billing-related.
 * Response: { "ok": true, "request_id": 7 }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

$REASONS = ['Cash flow delay this month', 'Seasonal slowdown in business', 'Unexpected business expense', 'Other'];
$reason = $body['reason'] ?? '';
$plan   = $body['plan_label'] ?? '';

if (!in_array($reason, $REASONS, true) || !in_array($plan, ['2 payments', '3 payments'], true)) {
    json_error('A valid reason and plan are required.');
}

$tenantStmt = $pdo->prepare(
    'SELECT t.id AS tenant_id, t.lessor_id, a.rent
     FROM tenants t
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.lessee_id = ? ORDER BY t.created_at DESC LIMIT 1'
);
$tenantStmt->execute([$lessee['id']]);
$tenant = $tenantStmt->fetch();

if (!$tenant) {
    json_error('You need an active lease before requesting an installment plan.', 403);
}

$insert = $pdo->prepare(
    'INSERT INTO installment_requests (lessor_id, tenant_id, reason, plan_label, amount) VALUES (?, ?, ?, ?, ?)'
);
$insert->execute([$tenant['lessor_id'], $tenant['tenant_id'], $reason, $plan, (float) $tenant['rent']]);

json_ok(['request_id' => (int) $pdo->lastInsertId()], 201);
