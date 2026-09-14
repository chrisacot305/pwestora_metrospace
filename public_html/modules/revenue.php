<?php
/**
 * modules/revenue.php  (SuperAdmin → "Revenue & Commission")
 * Same visual structure as the original prototype, but every figure is a
 * real aggregate from active leases — not demo data. Since there's no
 * payment-collection ledger yet, these are contracted/recurring rent
 * figures, not "cash already processed" — labeled honestly below.
 */
$feeStmt = $pdo->prepare('SELECT setting_value FROM platform_settings WHERE setting_key = "platform_fee_percent"');
$feeStmt->execute();
$feePercent = (float) ($feeStmt->fetchColumn() ?: 5);

$summary = $pdo->query(
    'SELECT COUNT(*) AS active_leases, COALESCE(SUM(a.rent),0) AS mrr, COALESCE(AVG(a.rent),0) AS avg_rent
     FROM tenants t JOIN applications a ON a.id = t.application_id'
)->fetch();

$activeLeases = (int) $summary['active_leases'];
$mrr = (float) $summary['mrr'];
$avgRent = (float) $summary['avg_rent'];
$estCommission = $mrr * ($feePercent / 100);

$byType = $pdo->query(
    'SELECT p.type, COALESCE(SUM(a.rent),0) AS total
     FROM tenants t
     JOIN applications a ON a.id = t.application_id
     JOIN properties p ON p.id = t.property_id
     GROUP BY p.type ORDER BY total DESC'
)->fetchAll();

$byLessor = $pdo->query(
    'SELECT u.company_name, COALESCE(SUM(a.rent),0) AS total
     FROM tenants t
     JOIN applications a ON a.id = t.application_id
     JOIN users u ON u.id = t.lessor_id
     GROUP BY u.company_name ORDER BY total DESC LIMIT 6'
)->fetchAll();

$typeMax = $byType ? max(array_column($byType, 'total')) : 0;
$lessorMax = $byLessor ? max(array_column($byLessor, 'total')) : 0;

function revenue_bar(string $label, float $value, float $max, string $color): string {
    $pctWidth = $max > 0 ? min(100, round(($value / $max) * 100)) : 0;
    return '
    <div style="margin-bottom:12px;">
      <div style="display:flex; justify-content:space-between; font-size:11.5px; margin-bottom:4px;">
        <span style="color:var(--ink-500);">' . htmlspecialchars($label) . '</span>
        <span style="font-weight:700; color:var(--ink-900);">₱' . number_format($value, 0) . '</span>
      </div>
      <div style="width:100%; height:6px; border-radius:999px; background:var(--border);">
        <div style="height:6px; border-radius:999px; width:' . $pctWidth . '%; background:' . $color . ';"></div>
      </div>
    </div>';
}

$barColors = ['var(--primary)', 'var(--accent)', 'var(--success)', 'var(--warning)', 'var(--error)', 'var(--steel)'];
?>
<h2 style="margin:0 0 4px;">Revenue &amp; Commission</h2>
<p style="color:var(--ink-500); margin:0 0 4px;">Platform commission is <?= rtrim(rtrim(number_format($feePercent, 1), '0'), '.') ?>% of gross monthly rent collected.</p>
<p style="color:var(--ink-300); font-size:11.5px; margin:0 0 20px;">
  Figures reflect contracted monthly rent across active leases — not yet a live payment ledger.
</p>

<div class="kpi-grid">
  <div class="card">
    <div class="kpi-label">Monthly Recurring Rent</div>
    <div class="kpi-value">₱<?= number_format($mrr, 0) ?></div>
    <div style="font-size:11px; color:var(--ink-500); margin-top:2px;">Across all active leases</div>
  </div>
  <div class="card">
    <div class="kpi-label">Est. Monthly Commission</div>
    <div class="kpi-value">₱<?= number_format($estCommission, 0) ?></div>
    <div style="font-size:11px; color:var(--ink-500); margin-top:2px;"><?= rtrim(rtrim(number_format($feePercent, 1), '0'), '.') ?>% of MRR</div>
  </div>
  <div class="card">
    <div class="kpi-label">Active Leases</div>
    <div class="kpi-value"><?= $activeLeases ?></div>
  </div>
  <div class="card">
    <div class="kpi-label">Avg. Lease Value</div>
    <div class="kpi-value">₱<?= number_format($avgRent, 0) ?></div>
  </div>
</div>

<div class="two-col">
  <div class="card">
    <p style="font-size:13px; font-weight:700; margin-bottom:14px;">Monthly rent by property type</p>
    <?php if (!$byType): ?>
      <p style="font-size:13px; color:var(--ink-500);">No active leases yet.</p>
    <?php else: foreach ($byType as $i => $row): ?>
      <?= revenue_bar($row['type'], (float) $row['total'], $typeMax, $barColors[$i % count($barColors)]) ?>
    <?php endforeach; endif; ?>
  </div>

  <div class="card">
    <p style="font-size:13px; font-weight:700; margin-bottom:14px;">Top lessors by monthly rent</p>
    <?php if (!$byLessor): ?>
      <p style="font-size:13px; color:var(--ink-500);">No active leases yet.</p>
    <?php else: foreach ($byLessor as $i => $row): ?>
      <?= revenue_bar($row['company_name'], (float) $row['total'], $lessorMax, $barColors[$i % count($barColors)]) ?>
    <?php endforeach; endif; ?>
  </div>
</div>
