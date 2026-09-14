<?php
/**
 * POST /api/applications_reply.php
 * Header: Authorization: Bearer <token>
 * Body: { "application_id": 8, "message": "I agree to the terms..." }
 * Response: { "ok": true }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

$applicationId = (int) ($body['application_id'] ?? 0);
$message = trim($body['message'] ?? '');

if ($applicationId <= 0 || $message === '') {
    json_error('application_id and message are required.');
}

$stmt = $pdo->prepare('SELECT * FROM applications WHERE id = ? AND lessee_id = ?');
$stmt->execute([$applicationId, $lessee['id']]);
$app = $stmt->fetch();

if (!$app) {
    json_error('Application not found or unauthorized.', 404);
}

if ($app['status'] !== 'pending') {
    json_error('This application is already ' . $app['status'] . ' and cannot be negotiated further.', 400);
}

$negotiation = [];
if (!empty($app['checklist_negotiation'])) {
    $decoded = json_decode($app['checklist_negotiation'], true);
    if (is_array($decoded)) {
        $negotiation = $decoded;
    }
}

if (!isset($negotiation['messages']) || !is_array($negotiation['messages'])) {
    $negotiation['messages'] = [];
}

// Append new lessee message
$negotiation['messages'][] = [
    'sender'      => 'lessee',
    'sender_name' => $lessee['full_name'] ?? 'Applicant',
    'message'     => $message,
    'sent_at'     => date('Y-m-d H:i:s'),
];

$updatedJson = json_encode($negotiation);

try {
    $update = $pdo->prepare('UPDATE applications SET checklist_negotiation = ? WHERE id = ?');
    $update->execute([$updatedJson, $applicationId]);
} catch (Throwable $e) {
    json_error('Failed to save reply: ' . $e->getMessage(), 500);
}

json_ok(['ok' => true, 'messages' => $negotiation['messages']]);
