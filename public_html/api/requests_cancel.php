<?php
/**
 * POST /api/requests_cancel.php
 * Header: Authorization: Bearer <token>
 * Body: { "request_id": 123 }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();
$reqId = isset($body['request_id']) ? (int) $body['request_id'] : 0;

if ($reqId <= 0) {
    json_error('A valid request_id is required.');
}

// Find any tenant records belonging to this lessee
$tenantStmt = $pdo->prepare('SELECT id FROM tenants WHERE lessee_id = ?');
$tenantStmt->execute([$lessee['id']]);
$tenantIds = $tenantStmt->fetchAll(PDO::FETCH_COLUMN);

if (empty($tenantIds)) {
    json_error('No tenant account associated with this session.', 404);
}

$placeholders = implode(',', array_fill(0, count($tenantIds), '?'));
$sql = "DELETE FROM installment_requests WHERE id = ? AND tenant_id IN ($placeholders) AND LOWER(status) = 'pending'";
$params = array_merge([$reqId], $tenantIds);
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

if ($stmt->rowCount() > 0) {
    json_ok(['cancelled' => true]);
} else {
    // If already gone or processed
    $check = $pdo->prepare('SELECT status FROM installment_requests WHERE id = ?');
    $check->execute([$reqId]);
    $currStatus = $check->fetchColumn();

    if (!$currStatus) {
        // Request does not exist anymore — treat as successfully cancelled
        json_ok(['cancelled' => true]);
    } else {
        json_error("Request is in '$currStatus' status and cannot be cancelled.", 400);
    }
}
