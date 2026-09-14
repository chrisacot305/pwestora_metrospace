<?php
/**
 * export_audit_log.php
 * Downloads the ENTIRE audit_logs table as CSV (no 200-row cap like the
 * on-screen view). SuperAdmin only.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
require_role(['superadmin']);

$logs = $pdo->query(
    "SELECT al.*, u.company_name, u.full_name, u.role AS actor_role
     FROM audit_logs al
     LEFT JOIN users u ON u.id = al.actor_id
     ORDER BY al.created_at DESC"
)->fetchAll();

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="pwestora-audit-log-' . date('Y-m-d') . '.csv"');

$out = fopen('php://output', 'w');
fputcsv($out, ['Actor', 'Role', 'Action', 'Target', 'Timestamp']);

foreach ($logs as $l) {
    $actor = $l['actor_role']
        ? ($l['actor_role'] === 'lessor' ? ($l['company_name'] ?: 'Lessor') : ($l['full_name'] ?: 'User'))
        : 'System';
    fputcsv($out, [
        $actor,
        $l['actor_role'] ?: '—',
        $l['action'],
        $l['details'] ?: '—',
        $l['created_at'],
    ]);
}
fclose($out);
exit;
