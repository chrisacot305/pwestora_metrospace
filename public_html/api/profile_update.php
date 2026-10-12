<?php
/**
 * POST /api/profile_update.php
 * Header: Authorization: Bearer <token>
 * Body: { "full_name": "...", "email": "...", "phone": "..." }
 * Updates current lessee's personal information.
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

$fullName    = trim($body['full_name'] ?? ($lessee['full_name'] ?? ''));
$companyName = trim($body['company_name'] ?? ($lessee['company_name'] ?? ''));
$email       = trim($body['email'] ?? ($lessee['email'] ?? ''));
$phone       = trim($body['phone'] ?? ($lessee['phone'] ?? ''));

if ($fullName === '') {
    json_error('Full name cannot be empty.');
}

if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_error('Please enter a valid email address.');
}

$stmt = $pdo->prepare('UPDATE users SET full_name = ?, email = ?, phone = ?, company_name = ? WHERE id = ?');
$stmt->execute([$fullName, $email, $phone, $companyName, $lessee['id']]);

// If the user has an active application, keep business_name in sync
if (!empty($companyName)) {
    try {
        $pdo->prepare('UPDATE applications SET business_name = ? WHERE lessee_id = ? ORDER BY id DESC LIMIT 1')
            ->execute([$companyName, $lessee['id']]);
    } catch (Throwable $ignore) {}
}

audit_log($pdo, $lessee['id'], 'Updated profile details', "$fullName ($email, $phone, $companyName)");

json_ok([
    'message' => 'Profile updated successfully.',
    'user'    => [
        'id'           => (int) $lessee['id'],
        'full_name'    => $fullName,
        'company_name' => $companyName,
        'email'        => $email,
        'phone'        => $phone,
    ],
]);
