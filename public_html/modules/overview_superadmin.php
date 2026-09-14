<?php
/**
 * modules/overview_superadmin.php
 * PHP port of the `Overview` component in pwestora-superadmin-web.jsx.
 */
$totalLessors  = (int) $pdo->query('SELECT COUNT(*) FROM users WHERE role = "lessor" AND status = "active"')->fetchColumn();
$totalLessees  = (int) $pdo->query('SELECT COUNT(DISTINCT id) FROM tenants')->fetchColumn();
$pendingLessors = (int) $pdo->query('SELECT COUNT(*) FROM users WHERE role = "lessor" AND status = "pending"')->fetchColumn();
$pendingProps   = (int) $pdo->query('SELECT COUNT(*) FROM properties WHERE status = "pending"')->fetchColumn();

$pendingLessorRows = $pdo->query(
    'SELECT id, company_name FROM users WHERE role = "lessor" AND status = "pending" ORDER BY created_at DESC LIMIT 5'
)->fetchAll();

$pendingPropRows = $pdo->query(
    'SELECT id, name FROM properties WHERE status = "pending" ORDER BY created_at DESC LIMIT 5'
)->fetchAll();
?>
<h2 style="margin:0 0 4px;">Platform Overview</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Pwestora — all branches, all roles.</p>

<div class="kpi-grid">
  <div class="card"><div class="kpi-label">Total Lessors</div><div class="kpi-value"><?= $totalLessors ?></div></div>
  <div class="card"><div class="kpi-label">Total Lessees</div><div class="kpi-value"><?= $totalLessees ?></div></div>
  <div class="card">
    <div class="kpi-label">Pending Verifications</div>
    <div class="kpi-value"><?= $pendingLessors + $pendingProps ?></div>
    <div style="font-size:12px; color:var(--ink-500);"><?= $pendingLessors ?> lessors · <?= $pendingProps ?> properties</div>
  </div>
</div>

<div class="card">
  <p style="font-weight:700; font-size:13px; margin-bottom:12px;">Awaiting verification</p>
  <?php foreach ($pendingLessorRows as $l): ?>
    <div style="display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--border);">
      <p style="margin:0; font-size:13px; font-weight:600;"><?= htmlspecialchars($l['company_name']) ?></p>
      <span class="badge" style="background:var(--accent-soft); color:var(--primary);">Lessor</span>
    </div>
  <?php endforeach; ?>
  <?php foreach ($pendingPropRows as $p): ?>
    <div style="display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--border);">
      <p style="margin:0; font-size:13px; font-weight:600;"><?= htmlspecialchars($p['name']) ?></p>
      <span class="badge" style="background:var(--bg); color:var(--primary);">Property</span>
    </div>
  <?php endforeach; ?>
  <?php if (!$pendingLessorRows && !$pendingPropRows): ?>
    <p style="color:var(--ink-500); font-size:13px;">Nothing awaiting verification.</p>
  <?php endif; ?>
</div>
