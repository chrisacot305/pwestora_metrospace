<?php
/**
 * modules/deposits.php  (Lessor → "Security Deposits")
 * PHP port of the Deposits component in pwestora-lessor-web.jsx.
 * Two-step confirmation for release, done via ?release=ID then &confirm=1
 * instead of client-side state (no JS framework here).
 */
$lessorId = $user['id'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['confirm_release'])) {
    csrf_check();
    $depositId = (int) $_POST['deposit_id'];

    try {
        $stmt = $pdo->prepare('SELECT * FROM deposits WHERE id = ? AND lessor_id = ? AND status = "locked"');
        $stmt->execute([$depositId, $lessorId]);
        $deposit = $stmt->fetch();

        if ($deposit) {
            $note = 'Emergency release · ' . date('M j') . ' · replenishment scheduled';
            $pdo->prepare('UPDATE deposits SET status = "released", note = ?, released_at = NOW() WHERE id = ?')
                ->execute([$note, $depositId]);
            audit_log($pdo, $lessorId, 'Emergency deposit release', $deposit['tenant_id'] . ' — ₱' . $deposit['amount']);
        }
        header('Location: /dashboard.php?page=deposits');
        exit;
    } catch (Throwable $e) {
        error_log('Deposit release failed: ' . $e->getMessage());
        $error = 'Could not release this deposit — the error has been logged. Please try again.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_deposit'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $amount   = (float) $_POST['amount'];

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    if (!$check->fetch() || $amount <= 0) {
        $error = 'Please select a tenant and enter a valid amount.';
    } else {
        try {
            $pdo->prepare('INSERT INTO deposits (lessor_id, tenant_id, amount) VALUES (?, ?, ?)')
                ->execute([$lessorId, $tenantId, $amount]);
            header('Location: /dashboard.php?page=deposits');
            exit;
        } catch (Throwable $e) {
            error_log('Log deposit failed: ' . $e->getMessage());
            $error = 'Could not log this deposit — the error has been logged. Please try again.';
        }
    }
}

$deposits = $pdo->prepare(
    'SELECT d.*, t.tenant_name FROM deposits d
     JOIN tenants t ON t.id = d.tenant_id
     WHERE d.lessor_id = ? ORDER BY d.id DESC'
);
$deposits->execute([$lessorId]);
$deposits = $deposits->fetchAll();

$tenantsWithoutDeposit = $pdo->prepare(
    'SELECT id, tenant_name FROM tenants
     WHERE lessor_id = ? AND id NOT IN (SELECT tenant_id FROM deposits WHERE lessor_id = ?)
     ORDER BY tenant_name'
);
$tenantsWithoutDeposit->execute([$lessorId, $lessorId]);
$tenantsWithoutDeposit = $tenantsWithoutDeposit->fetchAll();

$releaseId = isset($_GET['release']) ? (int) $_GET['release'] : null;
$confirming = isset($_GET['confirm']);
$releasing = null;
if ($releaseId) {
    foreach ($deposits as $d) {
        if ((int) $d['id'] === $releaseId && $d['status'] === 'locked') { $releasing = $d; break; }
    }
}
?>
<h2 style="margin:0 0 4px;">Security Deposits</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Locked assets by default. Emergency release is lessor-only and always logged.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card-grid" style="margin-bottom:28px;">
  <?php if (!$deposits): ?>
    <p style="color:var(--ink-500); font-size:13px;">No deposits on record yet.</p>
  <?php else: foreach ($deposits as $d): ?>
    <div class="card">
      <div style="display:flex; align-items:center; justify-content:space-between;">
        <p style="font-size:13px; font-weight:600; margin:0;"><?= htmlspecialchars($d['tenant_name']) ?></p>
        <i class="bi <?= $d['status'] === 'locked' ? 'bi-lock-fill' : 'bi-unlock-fill' ?>"
           style="color: <?= $d['status'] === 'locked' ? 'var(--primary)' : 'var(--warning)' ?>;"></i>
      </div>
      <p style="font-size:20px; font-weight:800; color:var(--primary); margin:10px 0 6px;">₱<?= number_format($d['amount'], 0) ?></p>
      <?php if ($d['status'] === 'locked'): ?>
        <span class="badge" style="background:var(--bg); color:var(--primary);">Locked</span>
      <?php else: ?>
        <span class="badge badge-pending">Released</span>
      <?php endif; ?>
      <?php if ($d['note']): ?>
        <p style="font-size:11px; color:var(--ink-500); margin:8px 0 0;"><?= htmlspecialchars($d['note']) ?></p>
      <?php endif; ?>
      <?php if ($d['status'] === 'locked'): ?>
        <div style="margin-top:12px;">
          <a href="/dashboard.php?page=deposits&release=<?= $d['id'] ?>"
             style="font-size:12.5px; font-weight:600; color:var(--error); border:1px solid var(--error-soft); padding:6px 12px; border-radius:8px; display:inline-block;">
            Emergency Release
          </a>
        </div>
      <?php endif; ?>
    </div>
  <?php endforeach; endif; ?>
</div>

<div class="card" style="max-width:480px;">
  <p style="font-weight:700; font-size:14px; margin-bottom:4px;">Log a deposit</p>
  <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
    Record the security deposit collected when a lease was signed.
  </p>

  <?php if (!$tenantsWithoutDeposit): ?>
    <p style="font-size:13px; color:var(--ink-500);">Every current tenant already has a deposit on record.</p>
  <?php else: ?>
    <form method="POST">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="log_deposit" value="1">
      <div class="field">
        <label>Tenant</label>
        <select name="tenant_id" required>
          <option value="">Select tenant…</option>
          <?php foreach ($tenantsWithoutDeposit as $t): ?>
            <option value="<?= $t['id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>Deposit Amount (₱)</label>
        <input type="number" name="amount" min="1" step="0.01" required>
      </div>
      <button class="btn btn-primary" type="submit">Log Deposit</button>
    </form>
  <?php endif; ?>
</div>

<?php if ($releasing && !$confirming): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Emergency Deposit Release</h3>
      <a href="/dashboard.php?page=deposits" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <div style="display:flex; gap:10px; align-items:flex-start; background:var(--error-soft); padding:12px 14px; border-radius:12px; margin-bottom:16px;">
      <i class="bi bi-exclamation-triangle" style="color:var(--error); flex-shrink:0; margin-top:2px;"></i>
      <p style="font-size:12px; color:var(--error); margin:0;">
        This is an emergency-only action. It cannot be used as a routine substitute for unpaid rent.
      </p>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Tenant:</strong> <?= htmlspecialchars($releasing['tenant_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Deposit amount:</strong> ₱<?= number_format($releasing['amount'], 0) ?></p>
    </div>

    <p style="font-size:12px; color:var(--ink-500); margin-bottom:20px;">
      Releasing will automatically record the transaction, create a replenishment schedule, and add the top-up to future billing.
    </p>

    <a href="/dashboard.php?page=deposits&release=<?= $releasing['id'] ?>&confirm=1"
       class="btn" style="width:100%; background:var(--error); color:#fff; display:flex;">
      <i class="bi bi-unlock"></i> Continue to Confirm
    </a>
  </div>
</div>
<?php endif; ?>

<?php if ($releasing && $confirming): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Confirm Release</h3>
      <a href="/dashboard.php?page=deposits" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <p style="font-size:13px; margin-bottom:20px;">
      Release ₱<?= number_format($releasing['amount'], 0) ?> from <?= htmlspecialchars($releasing['tenant_name']) ?>'s deposit?
      This action is logged permanently in the audit trail.
    </p>

    <div style="display:flex; gap:12px;">
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="deposit_id" value="<?= $releasing['id'] ?>">
        <input type="hidden" name="confirm_release" value="1">
        <button class="btn" style="width:100%; background:var(--error); color:#fff;" type="submit">
          <i class="bi bi-check-lg"></i> Confirm Release
        </button>
      </form>
      <a href="/dashboard.php?page=deposits&release=<?= $releasing['id'] ?>"
         class="btn" style="flex:1; background:var(--bg); color:var(--ink-900); display:flex;">Cancel</a>
    </div>
  </div>
</div>
<?php endif; ?>
