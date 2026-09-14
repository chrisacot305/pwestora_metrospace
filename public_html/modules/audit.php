<?php
/**
 * modules/audit.php  (SuperAdmin → "Audit Logs")
 * PHP port of the AuditLogs component. Pulls from the real audit_logs table
 * that every module in this app has been writing to since Phase 1.
 */
$logs = $pdo->query(
    "SELECT al.*, u.company_name, u.full_name, u.role AS actor_role
     FROM audit_logs al
     LEFT JOIN users u ON u.id = al.actor_id
     ORDER BY al.created_at DESC
     LIMIT 200"
)->fetchAll();

function actor_label(array $row): string {
    if (!$row['actor_role']) return 'System';
    return $row['actor_role'] === 'lessor' ? ($row['company_name'] ?: 'Lessor') : ($row['full_name'] ?: 'User');
}
?>
<h2 style="margin:0 0 4px;">Audit Logs</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Immutable record of every consequential action on the platform.</p>

<div class="card" style="padding:0; overflow:hidden;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Actor</th><th>Action</th><th>Target</th><th>Time</th></tr></thead>
    <tbody>
      <?php if (!$logs): ?>
        <tr><td colspan="4" style="text-align:center; color:var(--ink-500);">Nothing logged yet.</td></tr>
      <?php else: foreach ($logs as $l): ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars(actor_label($l)) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($l['action']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($l['details'] ?: '—') ?></td>
          <td style="color:var(--ink-500);"><?= (new DateTime($l['created_at']))->format('M j, g:i A') ?></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<div style="margin-top:16px;">
  <a href="/export_audit_log.php" class="btn" style="background:var(--bg); color:var(--ink-900); display:inline-flex; border:1px solid var(--border);">
    <i class="bi bi-download"></i> Export Full Log
  </a>
</div>
