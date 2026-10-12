<?php
/**
 * POST /api/auth_register.php
 * Body (JSON): { "full_name": "...", "email": "...", "phone": "...", "password": "...", "otp_code": "..." }
 * Response: { "ok": true, "token": "...", "user": { id, full_name, email } }
 */
require __DIR__ . '/_bootstrap.php';

$smsPath = __DIR__ . '/../includes/sms.php';
if (!file_exists($smsPath)) {
    json_error('Server configuration error: public_html/includes/sms.php has not been uploaded to the server yet.', 500);
}
require_once $smsPath;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$body = json_body();
$fullName = trim($body['full_name'] ?? '');
$email    = trim($body['email'] ?? '');
$phone    = trim($body['phone'] ?? '');
$password = $body['password'] ?? '';
$otpCode  = trim($body['otp_code'] ?? '');

if ($fullName === '' || $email === '' || strlen($password) < 8) {
    json_error('Full name, email, and a password of at least 8 characters are required.');
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_error('That email address looks invalid.');
}
if ($phone === '') {
    json_error('Mobile number is required.');
}

$normalizedPhone = format_ph_phone($phone);
if (!$normalizedPhone) {
    json_error('Please enter a valid 11-digit Philippine mobile number starting with 09.');
}

if ($otpCode === '') {
    json_error('Verification code (OTP) is required.');
}

// Verify OTP from phone_verifications table
$stmt = $pdo->prepare('SELECT * FROM phone_verifications WHERE phone = ? LIMIT 1');
$stmt->execute([$normalizedPhone]);
$otpRecord = $stmt->fetch();

if (!$otpRecord || !hash_equals($otpRecord['otp_code'], $otpCode) || strtotime($otpRecord['expires_at']) < time()) {
    json_error('Invalid or expired verification code. Please request a new code.');
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

// Clean up verified OTP
$pdo->prepare('DELETE FROM phone_verifications WHERE phone = ?')->execute([$normalizedPhone]);

audit_log($pdo, $userId, 'Lessee registered & phone verified via app', $email);

json_ok([
    'token' => $token,
    'user'  => ['id' => $userId, 'full_name' => $fullName, 'email' => $email, 'phone' => $phone],
], 201);
