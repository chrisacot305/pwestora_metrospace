<?php
/**
 * modules/violations.php  (Lessor → "Violations")
 * PHP port of the Violations component. Strike level auto-escalates per
 * tenant (their prior highest strike + 1) exactly like the original.
 */
$lessorId = $user['id'];
$error = '';

$CATEGORIES = ['Noise Complaint', 'Improper Waste Disposal', 'Late Operating Hours', 'Unauthorized Modifications', 'Lease Violation', 'Safety Violation'];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['issue_violation'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $category = $_POST['category'] ?? '';

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    if (!$check->fetch() || !in_array($category, $CATEGORIES, true)) {
        $error = 'Please select a tenant and a category.';
    } else {
        try {
            $maxStrike = $pdo->prepare('SELECT COALESCE(MAX(strike), 0) FROM violations WHERE tenant_id = ?');
            $maxStrike->execute([$tenantId]);
            $newStrike = (int) $maxStrike->fetchColumn() + 1;

            $pdo->prepare('INSERT INTO violations (lessor_id, tenant_id, category, strike) VALUES (?, ?, ?, ?)')
                ->execute([$lessorId, $tenantId, $category, $newStrike]);
            audit_log($pdo, $lessorId, 'Issued violation', "$category — strike $newStrike");

            header('Location: /dashboard.php?page=violations');
            exit;
        } catch (Throwable $e) {
            error_log('Issue violation failed: ' . $e->getMessage());
            $error = 'Could not issue this violation — the error has been logged. Please try again.';
        }
    }
}

$violations = $pdo->prepare(
    'SELECT v.*, t.tenant_name FROM violations v
     JOIN tenants t ON t.id = v.tenant_id
     WHERE v.lessor_id = ? ORDER BY v.issued_at DESC'
);
$violations->execute([$lessorId]);
$violations = $violations->fetchAll();

$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

$issuing = isset($_GET['issue']);
?>
<h2 style="margin:0 0 4px;">Violations &amp; Escalation</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Every warning is documented, timestamped, and impossible to deny receipt of.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div style="display:flex; justify-content:flex-end; margin-bottom:16px;">
  <a href="/dashboard.php?page=violations&issue=1" class="btn" style="background:var(--accent); color:#fff; display:inline-flex;">
    <i class="bi bi-exclamation-triangle"></i> Issue Violation
  </a>
</div>

<div class="card" style="padding:0; overflow:hidden;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Tenant</th><th>Category</th><th>Strike</th><th>Issued</th><th>Acknowledged</th><th></th></tr></thead>
    <tbody>
      <?php if (!$violations): ?>
        <tr><td colspan="6" style="text-align:center; color:var(--ink-500);">No violations on record.</td></tr>
      <?php else: foreach ($violations as $v): ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($v['tenant_name']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($v['category']) ?></td>
          <td>
            <?php
              $strikeClass = $v['strike'] >= 3 ? 'badge-rejected' : ($v['strike'] == 2 ? 'badge-pending' : '');
              $strikeStyle = $v['strike'] == 1 ? 'background:var(--accent-soft); color:var(--primary);' : '';
            ?>
            <span class="badge <?= $strikeClass ?>" style="<?= $strikeStyle ?>">Strike <?= $v['strike'] ?></span>
          </td>
          <td style="color:var(--ink-500);"><?= (new DateTime($v['issued_at']))->format('M j') ?></td>
          <td>
            <?php if ($v['acknowledged']): ?>
              <span class="badge badge-approved">Read</span>
            <?php else: ?>
              <span class="badge" style="background:var(--bg); color:var(--ink-500);">Pending</span>
            <?php endif; ?>
          </td>
          <td>
            <?php if ($v['strike'] >= 3): ?>
              <a href="/eviction_notice.php?id=<?= $v['id'] ?>" target="_blank"
                 class="btn" style="background:var(--error); color:#fff; padding:6px 12px; display:inline-flex;">
                <i class="bi bi-download"></i> Notice of Eviction
              </a>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<?php if ($issuing): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Issue Violation</h3>
      <a href="/dashboard.php?page=violations" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <?php if (!$tenants): ?>
      <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet.</p>
    <?php else: ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="issue_violation" value="1">

        <div class="field">
          <label>Tenant</label>
          <select name="tenant_id" required>
            <option value="">Select tenant…</option>
            <?php foreach ($tenants as $t): ?>
              <option value="<?= $t['id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <p style="font-size:12px; font-weight:700; margin:16px 0 8px;">Category</p>
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-bottom:16px;">
          <?php foreach ($CATEGORIES as $c): ?>
            <label style="text-align:left; padding:10px; border-radius:8px; font-size:12px; font-weight:500; border:1px solid var(--border); cursor:pointer;">
              <input type="radio" name="category" value="<?= $c ?>" required style="margin-right:6px;"><?= $c ?>
            </label>
          <?php endforeach; ?>
        </div>

        <p style="font-size:12px; color:var(--ink-500); margin-bottom:20px;">
          This creates a permanent digital citation. The tenant receives a notification with a read receipt —
          escalation strikes accumulate automatically per tenant.
        </p>

        <button class="btn btn-primary" style="width:100%; display:flex;" type="submit">
          Issue &amp; Notify Tenant <i class="bi bi-arrow-right"></i>
        </button>
      </form>
    <?php endif; ?>
  </div>
</div>
<?php endif; ?>
