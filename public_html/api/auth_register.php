<?php
/**
 * POST /api/auth_register.php
 * Body (JSON): { "full_name": "...", "email": "...", "phone": "...", "password": "..." }
 * Response: { "ok": true, "token": "...", "user": { id, full_name, email } }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$body = json_body();
$fullName = trim($body['full_name'] ?? '');
$email    = trim($body['email'] ?? '');
$phone    = trim($body['phone'] ?? '');
$password = $body['password'] ?? '';

if ($fullName === '' || $email === '' || strlen($password) < 8) {
    json_error('full_name, email, and a password of at least 8 characters are required.');
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_error('That email address looks invalid.');
}

$check = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$check->execute([$email]);
if ($check->fetch()) {
    json_error('An account with that email already exists.', 409);
}

$token = generate_api_token();
$stmt = $pdo->prepare(
    'INSERT INTO users (role, status, full_name, email, phone, password_hash, api_token)
     VALUES ("lessee", "active", ?, ?, ?, ?, ?)'
);
// Lessees don't go through document verification like lessors do — active immediately.
$stmt->execute([$fullName, $email, $phone, password_hash($password, PASSWORD_DEFAULT), $token]);
$userId = (int) $pdo->lastInsertId();

audit_log($pdo, $userId, 'Lessee registered via app', $email);

json_ok([
    'token' => $token,
    'user'  => ['id' => $userId, 'full_name' => $fullName, 'email' => $email],
], 201);
