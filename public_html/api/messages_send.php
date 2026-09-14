<?php
/**
 * POST /api/messages_send.php
 * Header: Authorization: Bearer <token>
 * Body: { "body": "..." }
 * Response: { "ok": true }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();
$text = trim($body['body'] ?? '');

if ($text === '') {
    json_error('Message cannot be empty.');
}

$tenantStmt = $pdo->prepare('SELECT id AS tenant_id, lessor_id FROM tenants WHERE lessee_id = ? ORDER BY created_at DESC LIMIT 1');
$tenantStmt->execute([$lessee['id']]);
$tenant = $tenantStmt->fetch();

if (!$tenant) {
    json_error('You need an active lease before messaging your lessor.', 403);
}

$threadStmt = $pdo->prepare('SELECT id FROM message_threads WHERE lessor_id = ? AND tenant_id = ?');
$threadStmt->execute([$tenant['lessor_id'], $tenant['tenant_id']]);
$threadId = $threadStmt->fetchColumn();

if (!$threadId) {
    $pdo->prepare('INSERT INTO message_threads (lessor_id, tenant_id) VALUES (?, ?)')
        ->execute([$tenant['lessor_id'], $tenant['tenant_id']]);
    $threadId = (int) $pdo->lastInsertId();
}

$pdo->prepare('INSERT INTO messages (thread_id, sender, body) VALUES (?, "tenant", ?)')->execute([$threadId, $text]);

json_ok([]);
