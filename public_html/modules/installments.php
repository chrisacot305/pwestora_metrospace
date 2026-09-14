<?php
/**
 * modules/installments.php  (Lessor → "Installments")
 * PHP port of the Installments component in pwestora-lessor-web.jsx.
 */
$lessorId = $user['id'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['request_id'])) {
    csrf_check();
    $reqId  = (int) $_POST['request_id'];
    $action = $_POST['action'];

    try {
        $stmt = $pdo->prepare('SELECT * FROM installment_requests WHERE id = ? AND lessor_id = ?');
        $stmt->execute([$reqId, $lessorId]);
        $reqRow = $stmt->fetch();

        if ($reqRow && $reqRow['status'] === 'pending') {
            $newStatus = $action === 'approve' ? 'approved' : 'rejected';
            $pdo->prepare('UPDATE installment_requests SET status = ? WHERE id = ?')->execute([$newStatus, $reqId]);
            audit_log($pdo, $lessorId, ucfirst($newStatus) . ' installment plan', $reqRow['plan_label']);
        }
        header('Location: /dashboard.php?page=installments');
        exit;
    } catch (Throwable $e) {
        error_log('Installment decision failed: ' . $e->getMessage());
        $error = 'Could not process this request — the error has been logged. Please try again.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_request'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $reason   = trim($_POST['reason'] ?? '');
    $plan     = $_POST['plan_label'] ?? '';
    $amount   = (float) $_POST['amount'];

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    if (!$check->fetch() || $reason === '' || !in_array($plan, ['2 payments', '3 payments'], true) || $amount <= 0) {
        $error = 'Please fill in every field with a valid tenant, plan, and amount.';
    } else {
        try {
            $pdo->prepare(
                'INSERT INTO installment_requests (lessor_id, tenant_id, reason, plan_label, amount) VALUES (?, ?, ?, ?, ?)'
            )->execute([$lessorId, $tenantId, $reason, $plan, $amount]);
            header('Location: /dashboard.php?page=installments');
            exit;
        } catch (Throwable $e) {
            error_log('Log installment request failed: ' . $e->getMessage());
            $error = 'Could not log this request — the error has been logged. Please try again.';
        }
    }
}

$requests = $pdo->prepare(
    'SELECT ir.*, t.tenant_name FROM installment_requests ir
     JOIN tenants t ON t.id = ir.tenant_id
     WHERE ir.lessor_id = ? ORDER BY ir.created_at DESC'
);
$requests->execute([$lessorId]);
$requests = $requests->fetchAll();

$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
if ($reviewId) {
    foreach ($requests as $r) {
        if ((int) $r['id'] === $reviewId) { $reviewing = $r; break; }
    }
}
?>
<h2 style="margin:0 0 4px;">Installment Requests</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Structured restructuring only — no informal rent-reduction negotiation.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card" style="padding:0; overflow:hidden; margin-bottom:28px;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Tenant</th><th>Reason</th><th>Plan</th><th>Amount</th><th>Status</th><th></th></tr></thead>
    <tbody>
      <?php if (!$requests): ?>
        <tr><td colspan="6" style="text-align:center; color:var(--ink-500);">No installment requests yet.</td></tr>
      <?php else: foreach ($requests as $r): ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($r['tenant_name']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($r['reason']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($r['plan_label']) ?></td>
          <td style="color:var(--ink-500);">₱<?= number_format($r['amount'], 0) ?></td>
          <td>
            <?php if ($r['status'] === 'pending'): ?>
              <span class="badge badge-pending">Pending</span>
            <?php elseif ($r['status'] === 'approved'): ?>
              <span class="badge badge-approved">Approved</span>
            <?php else: ?>
              <span class="badge badge-rejected">Rejected</span>
            <?php endif; ?>
          </td>
          <td>
            <?php if ($r['status'] === 'pending'): ?>
              <a class="btn btn-primary" style="padding:6px 14px; display:inline-flex;"
                 href="/dashboard.php?page=installments&review=<?= $r['id'] ?>">Review</a>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<div class="card" style="max-width:480px;">
  <p style="font-weight:700; font-size:14px; margin-bottom:4px;">Log a request</p>
  <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
    Received an installment request offline? Log it here so it goes through the same review flow.
  </p>

  <?php if (!$tenants): ?>
    <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet — approve an application first.</p>
  <?php else: ?>
    <form method="POST">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="log_request" value="1">
      <div class="field">
        <label>Tenant</label>
        <select name="tenant_id" required>
          <option value="">Select tenant…</option>
          <?php foreach ($tenants as $t): ?>
            <option value="<?= $t['id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>Reason</label>
        <input type="text" name="reason" placeholder="e.g. Seasonal slowdown in business" required>
      </div>
      <div class="field">
        <label>Plan</label>
        <select name="plan_label" required>
          <option value="2 payments">2 payments</option>
          <option value="3 payments">3 payments</option>
        </select>
      </div>
      <div class="field">
        <label>Total Amount (₱)</label>
        <input type="number" name="amount" min="1" step="0.01" required>
      </div>
      <button class="btn btn-primary" type="submit">Log Request</button>
    </form>
  <?php endif; ?>
</div>

<?php if ($reviewing):
    $splitCount = $reviewing['plan_label'] === '3 payments' ? 3 : 2;
    $perPayment = round($reviewing['amount'] / $splitCount);
?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">IR-<?= str_pad($reviewing['id'], 3, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=installments" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Tenant:</strong> <?= htmlspecialchars($reviewing['tenant_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Reason:</strong> <?= htmlspecialchars($reviewing['reason']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Requested plan:</strong> <?= htmlspecialchars($reviewing['plan_label']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Total amount:</strong> ₱<?= number_format($reviewing['amount'], 0) ?></p>
    </div>

    <p style="font-size:12px; font-weight:700; margin-bottom:8px;">System-generated schedule</p>
    <div class="card" style="margin-bottom:16px;">
      <?php for ($n = 1; $n <= $splitCount; $n++): ?>
        <p style="margin:6px 0; font-size:13px; display:flex; justify-content:space-between;">
          <span style="color:var(--ink-500);">Payment <?= $n ?></span>
          <span style="font-weight:600;">₱<?= number_format($perPayment, 0) ?></span>
        </p>
      <?php endfor; ?>
    </div>

    <p style="font-size:12px; color:var(--ink-500); margin-bottom:20px;">
      Approving updates the tenant ledger, recalculates due dates, and notifies both parties automatically.
    </p>

    <div style="display:flex; gap:12px;">
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="request_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="approve">
        <button class="btn" style="width:100%; background:var(--success); color:#fff;" type="submit">
          <i class="bi bi-check-lg"></i> Approve Plan
        </button>
      </form>
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="request_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="reject">
        <button class="btn" style="width:100%; background:var(--error); color:#fff;" type="submit">
          <i class="bi bi-x-lg"></i> Reject
        </button>
      </form>
    </div>
  </div>
</div>
<?php endif; ?>
