<?php
/**
 * POST /api/tickets_create.php
 * Header: Authorization: Bearer <token>
 * Body: { "category": "plumbing", "priority": "high", "title": "...", "description": "..." }
 * Response: { "ok": true, "ticket_id": 12 }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

$CATEGORIES = ['plumbing','electrical','structural','internet','hvac','cleaning','security','lighting'];
$PRIORITIES = ['low','medium','high','urgent'];

$category = $body['category'] ?? '';
$priority = $body['priority'] ?? 'medium';
$title = trim($body['title'] ?? '');

if (!in_array($category, $CATEGORIES, true) || !in_array($priority, $PRIORITIES, true) || $title === '') {
    json_error('A valid category, priority, and title are required.');
}

$tenantStmt = $pdo->prepare('SELECT id, lessor_id FROM tenants WHERE lessee_id = ? ORDER BY created_at DESC LIMIT 1');
$tenantStmt->execute([$lessee['id']]);
$tenant = $tenantStmt->fetch();

if (!$tenant) {
    json_error('You need an active lease before reporting a maintenance issue.', 403);
}

$insert = $pdo->prepare(
    'INSERT INTO maintenance_tickets (lessor_id, tenant_id, category, priority, title) VALUES (?, ?, ?, ?, ?)'
);
$insert->execute([$tenant['lessor_id'], $tenant['id'], $category, $priority, $title]);

json_ok(['ticket_id' => (int) $pdo->lastInsertId()], 201);
