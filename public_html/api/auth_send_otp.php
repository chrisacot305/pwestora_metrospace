<?php
/**
 * POST /api/auth_send_otp.php
 * Body (JSON): { "phone": "09171234567", "email": "user@example.com" }
 * Dispatches a 6-digit verification code via PhilSMS.
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
$phone = trim($body['phone'] ?? '');
$email = trim($body['email'] ?? '');

if ($phone === '') {
    json_error('Mobile number is required.');
}

$normalizedPhone = format_ph_phone($phone);
if (!$normalizedPhone) {
    json_error('Please enter a valid 11-digit Philippine mobile number starting with 09 (e.g. 09171234567).');
}

if ($email !== '') {
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_error('Please enter a valid email address.');
    }
    // Check if email already registered
    $checkEmail = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
    $checkEmail->execute([$email]);
    if ($checkEmail->fetch()) {
        json_error('An account with that email already exists.', 409);
    }
}

// Check if phone number is already registered in active accounts
$checkPhone = $pdo->prepare('SELECT id FROM users WHERE phone = ? OR phone = ? LIMIT 1');
$checkPhone->execute([$phone, $normalizedPhone]);
if ($checkPhone->fetch()) {
    json_error('An account with that mobile number already exists. Please log in instead.', 409);
}

// Ensure phone_verifications table exists
$pdo->exec("CREATE TABLE IF NOT EXISTS phone_verifications (
    phone VARCHAR(20) PRIMARY KEY,
    otp_code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)");

// Generate secure 6-digit numeric OTP
$otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));

$stmt = $pdo->prepare('INSERT INTO phone_verifications (phone, otp_code, expires_at)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE otp_code = VALUES(otp_code), expires_at = VALUES(expires_at)');
$stmt->execute([$normalizedPhone, $otp, $expiresAt]);

// Dispatch SMS via PhilSMS
$message = "[Pwestora] Your verification code is $otp. Valid for 10 minutes. Do not share this code with anyone.";
$result = send_sms($normalizedPhone, $message);

if (!$result['ok']) {
    error_log("[SMS OTP Failure] " . ($result['error'] ?? 'Unknown gateway error'));
    json_error($result['error'] ?? 'Failed to send SMS code. Please verify your mobile number or try again later.', 500);
}

json_ok([
    'message' => 'Verification code sent successfully.',
    'phone'   => $phone,
]);
