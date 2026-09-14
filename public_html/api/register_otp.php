<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

$action = $_GET['action'] ?? 'send_otp';
$data = json_decode(file_get_contents('php://input'), true);

if ($action === 'send_otp') {
    $email = $data['email'] ?? '';
    if (empty($email)) {
        echo json_encode(['success' => false, 'message' => 'Email required']);
        exit;
    }

    $otp = rand(100000, 999999);
    // Save OTP to database or session with timestamp
    $stmt = $pdo->prepare("INSERT INTO otp_verifications (email, otp_code, created_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE otp_code=?, created_at=NOW()");
    $stmt->execute([$email, $otp, $otp]);

    // Send email via mail() or PHPMailer
    mail($email, "Pwestora Verification Code", "Your OTP code is: $otp");

    echo json_encode(['success' => true, 'message' => 'OTP sent successfully']);
    exit;
}

if ($action === 'verify_otp') {
    $email = $data['email'] ?? '';
    $otp = $data['otp'] ?? '';
    $name = $data['name'] ?? '';
    $password = password_hash($data['password'] ?? '', PASSWORD_DEFAULT);

    $stmt = $pdo->prepare("SELECT * FROM otp_verifications WHERE email = ? AND otp_code = ?");
    $stmt->execute([$email, $otp]);
    if ($stmt->fetch()) {
        // Activate User Account
        $userStmt = $pdo->prepare("INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'lessee', 'active')");
        $userStmt->execute([$name, $email, $password]);

        echo json_encode(['success' => true, 'message' => 'Account activated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP']);
    }
    exit;
}