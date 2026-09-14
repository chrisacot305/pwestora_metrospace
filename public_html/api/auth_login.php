<?php
/**
 * POST /api/auth_login.php
 * Body (JSON): { "email": "...", "password": "..." }
 * Response: { "ok": true, "token": "...", "user": { id, full_name, email } }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$body = json_body();
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';

$stmt = $pdo->prepare('SELECT * FROM users WHERE email = ? AND role = "lessee" LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    json_error('Incorrect email or password.', 401);
}

// Issue a fresh token on every login (simple, no expiry logic needed for v1).
$token = generate_api_token();
$pdo->prepare('UPDATE users SET api_token = ? WHERE id = ?')->execute([$token, $user['id']]);

json_ok([
    'token' => $token,
    'user'  => ['id' => $user['id'], 'full_name' => $user['full_name'], 'email' => $user['email']],
]);
