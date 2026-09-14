<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
require_login();
$user = current_user();

$pdo->prepare('UPDATE notification_recipients SET read_at = NOW() WHERE user_id = ? AND read_at IS NULL')
    ->execute([$user['id']]);

$back = $_SERVER['HTTP_REFERER'] ?? '/dashboard.php';
header('Location: ' . $back);
exit;
