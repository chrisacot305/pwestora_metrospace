<?php
/**
 * tools/test_sms.php — Quick CLI/Web test tool for PhilSMS
 * Usage via CLI: php public_html/tools/test_sms.php 09171234567
 */
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/sms.php';

$phone = $argv[1] ?? ($_GET['phone'] ?? null);

if (!$phone) {
    echo "Usage: php tools/test_sms.php <mobile_number>\n";
    echo "Example: php tools/test_sms.php 09171234567\n";
    exit(1);
}

echo "Testing PhilSMS dispatch to: $phone\n";
$msg = "[Pwestora Test] Verification test from Pwestora SMS Gateway. Time: " . date('H:i:s');
$result = send_sms($phone, $msg);

echo "\nResult:\n";
print_r($result);
echo "\n";
