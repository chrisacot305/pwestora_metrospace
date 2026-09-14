<?php
/**
 * GET /api/messages_thread.php
 * Header: Authorization: Bearer <token>
 * Response: { "ok": true, "lessor_name": "...", "messages": [ { sender, notice_type, body, sent_at }, ... ] }
 * Messages are chronological (oldest first), same as the web chat view.
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$lessee = require_lessee_auth($pdo);

$tenantStmt = $pdo->prepare(
    'SELECT t.id AS tenant_id, t.lessor_id, u.company_name AS lessor_name
     FROM tenants t JOIN users u ON u.id = t.lessor_id
     WHERE t.lessee_id = ? ORDER BY t.created_at DESC LIMIT 1'
);
$tenantStmt->execute([$lessee['id']]);
$tenant = $tenantStmt->fetch();

if (!$tenant) {
    json_ok(['lessor_name' => null, 'messages' => []]);
}

$threadStmt = $pdo->prepare('SELECT id FROM message_threads WHERE lessor_id = ? AND tenant_id = ?');
$threadStmt->execute([$tenant['lessor_id'], $tenant['tenant_id']]);
$threadId = $threadStmt->fetchColumn();

$messages = [];
if ($threadId) {
    $msgStmt = $pdo->prepare('SELECT sender, notice_type, body, sent_at FROM messages WHERE thread_id = ? ORDER BY sent_at ASC');
    $msgStmt->execute([$threadId]);
    $messages = $msgStmt->fetchAll();
}

json_ok(['lessor_name' => $tenant['lessor_name'], 'messages' => $messages]);
