<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
log_user_out();
$back = '/index.php';
header('Location: ' . $back);
exit;
