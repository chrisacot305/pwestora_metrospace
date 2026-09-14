<?php
/**
 * includes/auth.php — session + role helpers
 * Include this AFTER config.php (needs $pdo + session already started).
 */

function current_user(): ?array {
    return $_SESSION['user'] ?? null;
}

function is_logged_in(): bool {
    return isset($_SESSION['user']);
}

/** Redirect to login if not authenticated at all. */
function require_login(): void {
    if (!is_logged_in()) {
        header('Location: /login.php');
        exit;
    }
}

/**
 * Redirect to login unless the logged-in user has one of the given roles.
 * Usage: require_role(['lessor']);  or  require_role(['superadmin']);
 */
function require_role(array $roles): void {
    require_login();
    $user = current_user();
    if (!in_array($user['role'], $roles, true)) {
        header('Location: /dashboard.php');
        exit;
    }
    if ($user['status'] !== 'active') {
        header('Location: /pending.php');
        exit;
    }
}

/** Attempt to log a user in. Returns the user row on success, or null. */
function attempt_login(PDO $pdo, string $email, string $password): ?array {
    $stmt = $pdo->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        return null;
    }
    return $user;
}

/** Store the minimal, safe user info in the session. */
function log_user_in(array $user): void {
    $_SESSION['user'] = [
        'id'      => $user['id'],
        'role'    => $user['role'],
        'status'  => $user['status'],
        'name'    => $user['full_name'],
        'company' => $user['company_name'],
        'email'   => $user['email'],
    ];
}

function log_user_out(): void {
    $_SESSION = [];
    session_destroy();
}

/** Simple audit trail — call this after important actions. */
function audit_log(PDO $pdo, ?int $actorId, string $action, string $details = ''): void {
    $stmt = $pdo->prepare(
        'INSERT INTO audit_logs (actor_id, action, details) VALUES (?, ?, ?)'
    );
    $stmt->execute([$actorId, $action, $details]);
}

/** CSRF token helpers — use in every form that changes data. */
function csrf_token(): string {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrf_check(): void {
    $sent = $_POST['csrf_token'] ?? '';
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $sent)) {
        http_response_code(419);
        die('Session expired. Please go back and try again.');
    }
}
