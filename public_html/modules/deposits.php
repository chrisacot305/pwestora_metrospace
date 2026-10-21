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

// Added property_name to the deposits query for visual context
$deposits = $pdo->prepare(
    'SELECT d.*, t.tenant_name, p.name AS property_name 
     FROM deposits d
     JOIN tenants t ON t.id = d.tenant_id
     LEFT JOIN properties p ON p.id = t.property_id
     WHERE d.lessor_id = ? ORDER BY d.id DESC'
);
$deposits->execute([$lessorId]);
$deposits = $deposits->fetchAll();

// Fetch properties for the new dropdown
$properties = $pdo->prepare('SELECT id, name FROM properties WHERE lessor_id = ? ORDER BY name');
$properties->execute([$lessorId]);
$properties = $properties->fetchAll();

// Included property_id in the query to allow JS filtering in the popup
$tenantsWithoutDeposit = $pdo->prepare(
    'SELECT id, tenant_name, property_id FROM tenants
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

// Track if the popup drawer should be open
$loggingDeposit = isset($_GET['log']);
?>

<div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:12px; margin-bottom:20px;">
  <div>
    <h2 style="margin:0 0 4px;">Security Deposits</h2>
    <p style="color:var(--ink-500); margin:0;">Locked assets by default. Emergency release is lessor-only and always logged.</p>
  </div>
  <!-- LOG DEPOSIT HEADER BUTTON -->
  <a href="/dashboard.php?page=deposits&log=1" class="btn btn-primary" style="width:auto; height:fit-content; display:inline-flex; align-items:center; gap:6px; padding:8px 14px; font-size:13px; white-space:nowrap; flex-shrink:0;">
    <i class="bi bi-plus-lg"></i> Log Deposit
  </a>
</div>

<?php if ($error && !$loggingDeposit && !$releasing): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card-grid" style="margin-bottom:28px;">
  <?php if (!$deposits): ?>
    <p style="color:var(--ink-500); font-size:13px;">No deposits on record yet.</p>
  <?php else: foreach ($deposits as $d): ?>
    <div class="card">
      <div style="display:flex; align-items:center; justify-content:space-between;">
        <div>
          <p style="font-size:13px; font-weight:600; margin:0;"><?= htmlspecialchars($d['tenant_name']) ?></p>
          <?php if (!empty($d['property_name'])): ?>
            <p style="font-size:11px; color:var(--ink-500); margin:2px 0 0;"><?= htmlspecialchars($d['property_name']) ?></p>
          <?php endif; ?>
        </div>
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

<!-- LOG DEPOSIT POPUP DRAWER -->
<?php if ($loggingDeposit || ($error && !$releasing)): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:440px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Log a deposit</h3>
      <a href="/dashboard.php?page=deposits" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
    </div>

    <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
      Record the security deposit collected when a lease was signed.
    </p>

    <?php if ($error): ?>
      <div class="error-msg" style="margin-bottom:16px;"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?php if (!$tenantsWithoutDeposit): ?>
      <p style="font-size:13px; color:var(--ink-500);">Every current tenant already has a deposit on record.</p>
    <?php else: ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="log_deposit" value="1">
        
        <div class="field">
          <label>Property</label>
          <select id="property_select" name="property_id" required>
            <option value="">Select property…</option>
            <?php foreach ($properties as $p): ?>
              <option value="<?= $p['id'] ?>"><?= htmlspecialchars($p['name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <div class="field">
          <label>Tenant</label>
          <select id="tenant_select" name="tenant_id" required disabled>
            <option value="">Select a property first…</option>
            <!-- These options are hidden and managed by JS based on property_id -->
            <?php foreach ($tenantsWithoutDeposit as $t): ?>
              <option value="<?= $t['id'] ?>" data-property="<?= $t['property_id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <div class="field">
          <label>Deposit Amount (₱)</label>
          <input type="number" name="amount" min="1" step="0.01" required>
        </div>

        <button class="btn btn-primary" type="submit" style="width:100%; margin-top:8px;">Log Deposit</button>
      </form>

      <!-- JAVASCRIPT FOR CASCADING DROPDOWN -->
      <script>
        document.addEventListener('DOMContentLoaded', function() {
           var propSel = document.getElementById('property_select');
           var tenSel = document.getElementById('tenant_select');
           
           if (propSel && tenSel) {
               // Clone all original tenant options to keep as a master list
               var allOptions = Array.from(tenSel.querySelectorAll('option[data-property]'));
               
               propSel.addEventListener('change', function() {
                   var pid = this.value;
                   
                   // Reset tenant dropdown
                   tenSel.innerHTML = '<option value="">Select tenant...</option>';
                   var hasTenants = false;
                   
                   // Append only tenants belonging to the selected property
                   allOptions.forEach(function(opt) {
                       if(opt.getAttribute('data-property') === pid) {
                           tenSel.appendChild(opt.cloneNode(true));
                           hasTenants = true;
                       }
                   });
                   
                   // Handle disabled states and messaging
                   if (!pid) {
                      tenSel.innerHTML = '<option value="">Select a property first...</option>';
                      tenSel.disabled = true;
                   } else if (!hasTenants) {
                      tenSel.innerHTML = '<option value="">No tenants await deposits here</option>';
                      tenSel.disabled = true;
                   } else {
                      tenSel.disabled = false;
                   }
               });
               
               // Initialize pure state
               tenSel.innerHTML = '<option value="">Select a property first...</option>';
               tenSel.disabled = true;
           }
        });
      </script>
    <?php endif; ?>
  </div>
</div>
<?php endif; ?>

<!-- EMERGENCY RELEASE POPUP DRAWER -->
<?php if ($releasing && !$confirming): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Emergency Deposit Release</h3>
      <a href="/dashboard.php?page=deposits" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
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

<!-- CONFIRM RELEASE POPUP DRAWER -->
<?php if ($releasing && $confirming): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Confirm Release</h3>
      <a href="/dashboard.php?page=deposits" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
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
         class="btn" style="flex:1; background:var(--bg); color:var(--ink-900); display:flex; justify-content:center;">Cancel</a>
    </div>
  </div>
</div>
<?php endif; ?>