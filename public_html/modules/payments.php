<?php
/**
 * modules/payments.php  (Lessor → "Rent Payments")
 * New module — a real payment ledger. Lessors log rent as it's received
 * (cash, bank transfer, GCash, etc.); tenants see this history in the app.
 */
$lessorId = $user['id'];
$error = '';

$METHODS = [
    'cash'          => 'Cash',
    'bank_transfer' => 'Bank Transfer',
    'gcash'         => 'GCash',
    'check'         => 'Check',
    'other'         => 'Other',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_payment'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $amount   = (float) $_POST['amount'];
    $method   = $_POST['method'] ?? 'cash';
    $paidAt   = $_POST['paid_at'] ?? '';
    $note     = trim($_POST['note'] ?? '');

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    $validDate = DateTime::createFromFormat('Y-m-d', $paidAt) !== false;

    if (!$check->fetch() || $amount <= 0 || !isset($METHODS[$method]) || !$validDate) {
        $error = 'Please fill in every field with a valid tenant, amount, method, and date.';
    } else {
        try {
            $pdo->prepare(
                'INSERT INTO payments (tenant_id, lessor_id, amount, method, note, paid_at, logged_by)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute([$tenantId, $lessorId, $amount, $method, $note ?: null, $paidAt, $lessorId]);
            audit_log($pdo, $lessorId, 'Logged rent payment', "₱$amount via {$METHODS[$method]}");
            header('Location: /dashboard.php?page=payments');
            exit;
        } catch (Throwable $e) {
            error_log('Log payment failed: ' . $e->getMessage());
            $error = 'Could not log this payment — the error has been logged. Please try again.';
        }
    }
}

$payments = $pdo->prepare(
    'SELECT pay.*, t.tenant_name FROM payments pay
     JOIN tenants t ON t.id = pay.tenant_id
     WHERE pay.lessor_id = ? ORDER BY pay.paid_at DESC, pay.id DESC LIMIT 100'
);
$payments->execute([$lessorId]);
$payments = $payments->fetchAll();

$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();
?>
<h2 style="margin:0 0 4px;">Rent Payments</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">A running ledger of rent received — visible to the tenant in their app.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card" style="padding:0; overflow:hidden; margin-bottom:28px;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Tenant</th><th>Amount</th><th>Method</th><th>Date</th><th>Note</th></tr></thead>
    <tbody>
      <?php if (!$payments): ?>
        <tr><td colspan="5" style="text-align:center; color:var(--ink-500);">No payments logged yet.</td></tr>
      <?php else: foreach ($payments as $p): ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($p['tenant_name']) ?></td>
          <td style="color:var(--ink-500);">₱<?= number_format($p['amount'], 0) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($METHODS[$p['method']] ?? $p['method']) ?></td>
          <td style="color:var(--ink-500);"><?= (new DateTime($p['paid_at']))->format('M j, Y') ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($p['note'] ?: '—') ?></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<div class="card" style="max-width:480px;">
  <p style="font-weight:700; font-size:14px; margin-bottom:4px;">Log a payment</p>
  <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
    Record rent as it's received — this becomes visible to the tenant immediately.
  </p>

  <?php if (!$tenants): ?>
    <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet.</p>
  <?php else: ?>
    <form method="POST">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="log_payment" value="1">
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
        <label>Amount (₱)</label>
        <input type="number" name="amount" min="1" step="0.01" required>
      </div>
      <div class="field">
        <label>Method</label>
        <select name="method" required>
          <?php foreach ($METHODS as $key => $label): ?>
            <option value="<?= $key ?>"><?= $label ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>Date Paid</label>
        <input type="date" name="paid_at" value="<?= date('Y-m-d') ?>" required>
      </div>
      <div class="field">
        <label>Note (optional)</label>
        <input type="text" name="note" placeholder="e.g. August rent, Unit 2A">
      </div>
      <button class="btn btn-primary" type="submit">Log Payment</button>
    </form>
  <?php endif; ?>
</div>
