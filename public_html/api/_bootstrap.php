<?php
/**
 * api/_bootstrap.php
 * Every file in /api/ starts with: require __DIR__ . '/_bootstrap.php';
 * Gives you: $pdo, json_ok(), json_error(), and require_lessee_auth().
 */
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php'; // gives us audit_log() and password helpers

header('Content-Type: application/json; charset=utf-8');
// Mobile apps (and Flutter's own dev web server) call this from a different origin.
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function json_ok($data = [], int $status = 200): void {
    http_response_code($status);
    echo json_encode(['ok' => true] + (is_array($data) ? $data : ['data' => $data]));
    exit;
}

function json_error(string $message, int $status = 400): void {
    http_response_code($status);
    echo json_encode(['ok' => false, 'error' => $message]);
    exit;
}

/** Reads JSON body sent by the app, e.g. {"email":"...","password":"..."} */
function json_body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

/**
 * Requires a valid `Authorization: Bearer <token>` header for a lessee account.
 * Returns the user row on success, or sends a 401 JSON error and exits.
 */
function require_lessee_auth(PDO $pdo): array {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
        json_error('Missing or malformed Authorization header.', 401);
    }
    $token = $m[1];

    $stmt = $pdo->prepare('SELECT * FROM users WHERE api_token = ? AND role = "lessee" LIMIT 1');
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        json_error('Invalid or expired token. Please log in again.', 401);
    }
    return $user;
}

function generate_api_token(): string {
    return bin2hex(random_bytes(32)); // 64-character token
}
