<?php
/**
 * modules/overview_lessor.php
 * PHP port of the `Overview` component in pwestora-lessor-web.jsx.
 * Included by dashboard.php — $pdo, $user are already available.
 */
$lessorId = $user['id'];

$activeLeases = $pdo->prepare('SELECT COUNT(*) FROM tenants WHERE lessor_id = ?');
$activeLeases->execute([$lessorId]);
$activeLeases = (int) $activeLeases->fetchColumn();

$pendingApps = $pdo->prepare('SELECT COUNT(*) FROM applications WHERE lessor_id = ? AND status = "pending"');
$pendingApps->execute([$lessorId]);
$pendingApps = (int) $pendingApps->fetchColumn();

$openTickets = $pdo->prepare('SELECT COUNT(*) FROM maintenance_tickets WHERE lessor_id = ? AND stage < 7');
$openTickets->execute([$lessorId]);
$openTickets = (int) $openTickets->fetchColumn();

$openViolations = $pdo->prepare('SELECT COUNT(*) FROM violations WHERE lessor_id = ?');
$openViolations->execute([$lessorId]);
$openViolations = (int) $openViolations->fetchColumn();

$pendingInstallments = $pdo->prepare(
    'SELECT ir.*, t.tenant_name FROM installment_requests ir
     JOIN tenants t ON t.id = ir.tenant_id
     WHERE ir.lessor_id = ? AND ir.status = "pending"'
);
$pendingInstallments->execute([$lessorId]);
$pendingInstallments = $pendingInstallments->fetchAll();

$ticketStages = ['Submitted','Under Review','Approved','Contractor Assigned','Scheduled','In Progress','Inspection','Completed'];
$openTicketRows = $pdo->prepare(
    'SELECT mt.*, t.tenant_name FROM maintenance_tickets mt
     JOIN tenants t ON t.id = mt.tenant_id
     WHERE mt.lessor_id = ? AND mt.stage < 7'
);
$openTicketRows->execute([$lessorId]);
$openTicketRows = $openTicketRows->fetchAll();

$pendingPaymentsStmt = $pdo->prepare(
    "SELECT p.*, t.tenant_name FROM payments p
     JOIN tenants t ON t.id = p.tenant_id
     WHERE p.lessor_id = ? AND (p.logged_by IS NULL OR p.note LIKE '[PENDING]%') AND (p.note NOT LIKE '[DECLINED%')
     ORDER BY p.id DESC"
);
$pendingPaymentsStmt->execute([$lessorId]);
$pendingPayments = $pendingPaymentsStmt->fetchAll();
$pendingPaymentsCount = count($pendingPayments);
$pendingPaymentsTotal = array_sum(array_column($pendingPayments, 'amount'));
?>
<h2 style="margin:0 0 4px;">Dashboard</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Portfolio overview across your branches.</p>

<?php if ($pendingPaymentsCount > 0): ?>
  <div class="card" style="margin-bottom:20px; border-left:4px solid var(--primary); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:14px; background:linear-gradient(90deg, #FFFFFF, var(--accent-soft));">
    <div style="display:flex; align-items:center; gap:14px;">
      <div style="width:42px; height:42px; border-radius:10px; background:var(--primary); color:#fff; display:flex; align-items:center; justify-content:center; font-size:20px;">
        <i class="bi bi-qr-code-scan"></i>
      </div>
      <div>
        <p style="margin:0; font-weight:700; font-size:14px; color:var(--primary);">
          <?= $pendingPaymentsCount ?> Tenant Payment<?= $pendingPaymentsCount > 1 ? 's' : '' ?> Awaiting Verification (₱<?= number_format($pendingPaymentsTotal, 2) ?>)
        </p>
        <p style="margin:2px 0 0; font-size:12.5px; color:var(--ink-500);">
          Transfers submitted via InstaPay QR code require your receipt confirmation to update the tenant ledger.
        </p>
      </div>
    </div>
    <a href="/dashboard.php?page=payments" class="btn btn-primary" style="width:auto; padding:9px 18px; font-size:13px; font-weight:700;">
      Review Payments <i class="bi bi-arrow-right"></i>
    </a>
  </div>
<?php endif; ?>

<div class="kpi-grid">
  <div class="card"><div class="kpi-label">Active Leases</div><div class="kpi-value"><?= $activeLeases ?></div></div>
  <div class="card">
    <div class="kpi-label">Pending Payments</div>
    <div class="kpi-value" style="<?= $pendingPaymentsCount > 0 ? 'color:var(--primary);' : '' ?>">
      <?= $pendingPaymentsCount ?>
    </div>
  </div>
  <div class="card"><div class="kpi-label">Pending Applications</div><div class="kpi-value"><?= $pendingApps ?></div></div>
  <div class="card"><div class="kpi-label">Open Maintenance</div><div class="kpi-value"><?= $openTickets ?></div></div>
</div>

<div class="two-col">
  <div class="card">
    <p style="font-weight:700; font-size:13px; margin-bottom:12px;">Pending installment requests</p>
    <?php if (!$pendingInstallments): ?>
      <p style="color:var(--ink-500); font-size:13px;">Nothing pending right now.</p>
    <?php else: foreach ($pendingInstallments as $r): ?>
      <div style="display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--border);">
        <div>
          <p style="margin:0; font-size:13px; font-weight:600;"><?= htmlspecialchars($r['tenant_name']) ?></p>
          <p style="margin:0; font-size:12px; color:var(--ink-500);"><?= htmlspecialchars($r['reason']) ?></p>
        </div>
        <span class="badge" style="background:var(--accent-soft); color:var(--primary);"><?= htmlspecialchars($r['plan_label']) ?></span>
      </div>
    <?php endforeach; endif; ?>
  </div>

  <div class="card">
    <p style="font-weight:700; font-size:13px; margin-bottom:12px;">Maintenance SLA watch</p>
    <?php if (!$openTicketRows): ?>
      <p style="color:var(--ink-500); font-size:13px;">No open tickets.</p>
    <?php else: foreach ($openTicketRows as $t): ?>
      <div style="display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--border);">
        <div>
          <p style="margin:0; font-size:13px; font-weight:600;"><?= htmlspecialchars($t['title']) ?></p>
          <p style="margin:0; font-size:12px; color:var(--ink-500);"><?= htmlspecialchars($t['tenant_name']) ?> · <?= $ticketStages[$t['stage']] ?></p>
        </div>
      </div>
    <?php endforeach; endif; ?>
  </div>
</div>