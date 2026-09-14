<?php
/**
 * config.php — Database connection + global settings
 * -----------------------------------------------------------
 * Fill these in with the values from hPanel → Databases → MySQL
 * Databases. Hostinger DB names/users are usually prefixed like
 * u123456789_pwestora / u123456789_dbuser.
 */

define('DB_HOST', 'localhost');           // almost always 'localhost' on Hostinger
define('DB_NAME', 'u456796838_pwestora');  // <-- replace with your real DB name
define('DB_USER', 'u456796838_pwestora');    // <-- replace with your real DB user
define('DB_PASS', 'pwestora*BSIT4B'); // <-- replace with your real DB password

// App-wide constants
define('APP_NAME', 'Pwestora');
define('APP_URL', 'https://pwestora.com'); // no trailing slash
define('UPLOAD_DIR', __DIR__ . '/uploads');

// -----------------------------------------------------------
// SMTP (real mailbox — fixes deliverability vs plain mail())
// -----------------------------------------------------------
// hPanel → Emails → your mailbox → "Configuration" shows these exact
// values. Hostinger's are usually: smtp.hostinger.com, port 465, SSL.
define('SMTP_HOST', 'smtp.hostinger.com');
define('SMTP_PORT', 465);
define('SMTP_ENCRYPTION', 'ssl'); // 'ssl' for port 465, 'tls' for port 587
define('SMTP_USER', 'admin@pwestora.com');
define('SMTP_PASS', 'pwestora*BSIT4B'); // <-- the password you set when creating this mailbox
define('SMTP_FROM_NAME', 'Pwestora');

// -----------------------------------------------------------
// PDO connection (used by every page via require 'config.php')
// -----------------------------------------------------------
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    // In production, never echo raw DB errors to visitors.
    error_log('DB connection failed: ' . $e->getMessage());
    die('Something went wrong connecting to the database. Please try again later.');
}

// Start the session on every page that includes this file.
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
