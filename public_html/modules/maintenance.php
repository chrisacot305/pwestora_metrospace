<?php
/**
 * modules/maintenance.php  (Lessor → "Maintenance")
 * PHP port of the Maintenance component in pwestora-lessor-web.jsx.
 */
$lessorId = $user['id'];
$error = '';

$STAGES = ['Submitted', 'Under Review', 'Approved', 'Contractor Assigned', 'Scheduled', 'In Progress', 'Inspection', 'Completed'];
$LAST_STAGE = count($STAGES) - 1;

$CATEGORIES = [
    'plumbing'   => ['Plumbing',   'bi-droplet'],
    'electrical' => ['Electrical', 'bi-lightning-charge'],
    'structural' => ['Structural', 'bi-tools'],
    'internet'   => ['Internet',   'bi-wifi'],
    'hvac'       => ['HVAC',       'bi-snow'],
    'cleaning'   => ['Cleaning',   'bi-stars'],
    'security'   => ['Security',   'bi-shield-check'],
    'lighting'   => ['Lighting',   'bi-lightbulb'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['advance_ticket_id'])) {
    csrf_check();
    $ticketId = (int) $_POST['advance_ticket_id'];

    try {
        $stmt = $pdo->prepare('SELECT * FROM maintenance_tickets WHERE id = ? AND lessor_id = ?');
        $stmt->execute([$ticketId, $lessorId]);
        $ticket = $stmt->fetch();

        if ($ticket && $ticket['stage'] < $LAST_STAGE) {
            $newStage = $ticket['stage'] + 1;
            $pdo->prepare('UPDATE maintenance_tickets SET stage = ? WHERE id = ?')->execute([$newStage, $ticketId]);
            audit_log($pdo, $lessorId, 'Advanced maintenance ticket', $ticket['title'] . ' → ' . $STAGES[$newStage]);
        }
        header('Location: /dashboard.php?page=maintenance&review=' . $ticketId);
        exit;
    } catch (Throwable $e) {
        error_log('Advance ticket failed: ' . $e->getMessage());
        $error = 'Could not advance this ticket — the error has been logged. Please try again.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_ticket'])) {
    csrf_check();
    $tenantId   = (int) $_POST['tenant_id'];
    $category   = $_POST['category'] ?? '';
    $title      = trim($_POST['title'] ?? '');
    $contractor = trim($_POST['contractor'] ?? '');
    $slaHours   = (int) ($_POST['sla_hours'] ?? 0);

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    if (!$check->fetch() || !isset($CATEGORIES[$category]) || $title === '') {
        $error = 'Please fill in every required field.';
    } else {
        try {
            $slaDue = $slaHours > 0 ? date('Y-m-d H:i:s', strtotime("+{$slaHours} hours")) : null;
            $pdo->prepare(
                'INSERT INTO maintenance_tickets (lessor_id, tenant_id, category, title, contractor, sla_due_at)
                 VALUES (?, ?, ?, ?, ?, ?)'
            )->execute([$lessorId, $tenantId, $category, $title, $contractor ?: null, $slaDue]);
            header('Location: /dashboard.php?page=maintenance');
            exit;
        } catch (Throwable $e) {
            error_log('Log ticket failed: ' . $e->getMessage());
            $error = 'Could not log this ticket — the error has been logged. Please try again.';
        }
    }
}

$tickets = $pdo->prepare(
    'SELECT mt.*, t.tenant_name FROM maintenance_tickets mt
     JOIN tenants t ON t.id = mt.tenant_id
     WHERE mt.lessor_id = ? ORDER BY mt.created_at DESC'
);
$tickets->execute([$lessorId]);
$tickets = $tickets->fetchAll();

$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

/** Compute the "Met / Xh left / Overdue" label the same way the original UI showed it. */
function sla_label(array $t, int $lastStage): array {
    if ((int) $t['stage'] === $lastStage) {
        return ['Met', true];
    }
    if (!$t['sla_due_at']) {
        return ['—', true];
    }
    $hoursLeft = (strtotime($t['sla_due_at']) - time()) / 3600;
    if ($hoursLeft <= 0) {
        return ['Overdue', false];
    }
    return [ceil($hoursLeft) . 'h left', false];
}

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
if ($reviewId) {
    foreach ($tickets as $t) {
        if ((int) $t['id'] === $reviewId) { $reviewing = $t; break; }
    }
}
?>
<h2 style="margin:0 0 4px;">Maintenance</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Same timeline the tenant sees — nothing is hidden on either side.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card-grid" style="margin-bottom:28px;">
  <?php if (!$tickets): ?>
    <p style="color:var(--ink-500); font-size:13px;">No maintenance tickets yet.</p>
  <?php else: foreach ($tickets as $t):
      [$catLabel, $catIcon] = $CATEGORIES[$t['category']] ?? ['Other', 'bi-three-dots'];
      [$slaText, $slaGood] = sla_label($t, $LAST_STAGE);
      $pct = round(($t['stage'] / $LAST_STAGE) * 100);
  ?>
    <a href="/dashboard.php?page=maintenance&review=<?= $t['id'] ?>" style="text-decoration:none;">
      <div class="card">
        <div style="display:flex; align-items:center; justify-content:space-between;">
          <div style="width:36px; height:36px; border-radius:8px; background:var(--bg); display:flex; align-items:center; justify-content:center;">
            <i class="bi <?= $catIcon ?>" style="color:var(--primary);"></i>
          </div>
          <span class="badge <?= $slaGood ? 'badge-approved' : 'badge-pending' ?>"><?= $slaText ?></span>
        </div>
        <p style="font-size:13px; font-weight:600; margin:10px 0 2px; color:var(--ink-900);"><?= htmlspecialchars($t['title']) ?></p>
        <p style="font-size:11.5px; color:var(--ink-500); margin:0;"><?= htmlspecialchars($t['tenant_name']) ?> · MT-<?= str_pad($t['id'], 4, '0', STR_PAD_LEFT) ?></p>
        <div style="width:100%; height:6px; border-radius:999px; background:var(--border); margin-top:10px;">
          <div style="height:6px; border-radius:999px; width:<?= $pct ?>%; background:var(--accent);"></div>
        </div>
        <p style="font-size:11px; color:var(--ink-500); margin:6px 0 0;"><?= $STAGES[$t['stage']] ?></p>
      </div>
    </a>
  <?php endforeach; endif; ?>
</div>

<div class="card" style="max-width:480px;">
  <p style="font-weight:700; font-size:14px; margin-bottom:4px;">Log a ticket</p>
  <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
    Received a maintenance issue by phone or in person? Log it so it's tracked the same way.
  </p>

  <?php if (!$tenants): ?>
    <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet.</p>
  <?php else: ?>
    <form method="POST">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="log_ticket" value="1">
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
        <label>Category</label>
        <select name="category" required>
          <option value="">Select category…</option>
          <?php foreach ($CATEGORIES as $id => [$label, $icon]): ?>
            <option value="<?= $id ?>"><?= $label ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>Issue Title</label>
        <input type="text" name="title" placeholder="e.g. Flickering lights — dining area" required>
      </div>
      <div class="field">
        <label>Contractor (optional)</label>
        <input type="text" name="contractor">
      </div>
      <div class="field">
        <label>SLA — hours to resolve (optional)</label>
        <input type="number" name="sla_hours" min="1" placeholder="e.g. 24">
      </div>
      <button class="btn btn-primary" type="submit">Log Ticket</button>
    </form>
  <?php endif; ?>
</div>

<?php if ($reviewing):
    [$slaText, $slaGood] = sla_label($reviewing, $LAST_STAGE);
?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">MT-<?= str_pad($reviewing['id'], 4, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=maintenance" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Tenant:</strong> <?= htmlspecialchars($reviewing['tenant_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Issue:</strong> <?= htmlspecialchars($reviewing['title']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Contractor:</strong> <?= htmlspecialchars($reviewing['contractor'] ?: '—') ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>SLA:</strong> <?= $slaText ?></p>
    </div>

    <p style="font-size:12px; font-weight:700; margin-bottom:12px;">Timeline</p>
    <div style="position:relative; padding-left:24px; margin-bottom:20px;">
      <div style="position:absolute; left:7px; top:4px; bottom:4px; width:2px; background:var(--border);"></div>
      <?php foreach ($STAGES as $i => $label): $done = $i <= $reviewing['stage']; ?>
        <div style="position:relative; padding-bottom:16px;">
          <div style="position:absolute; left:-24px; width:16px; height:16px; border-radius:50%; display:flex; align-items:center; justify-content:center;
                      background:<?= $done ? 'var(--accent)' : '#fff' ?>; border:2px solid <?= $done ? 'var(--accent)' : 'var(--border)' ?>;">
            <?php if ($done): ?><i class="bi bi-check" style="color:#fff; font-size:10px;"></i><?php endif; ?>
          </div>
          <p style="font-size:12.5px; font-weight:500; margin:0; color:<?= $done ? 'var(--ink-900)' : 'var(--ink-300)' ?>;"><?= $label ?></p>
        </div>
      <?php endforeach; ?>
    </div>

    <?php if ($reviewing['stage'] < $LAST_STAGE): ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="advance_ticket_id" value="<?= $reviewing['id'] ?>">
        <button class="btn btn-primary" style="display:flex;" type="submit">
          Advance to Next Stage <i class="bi bi-arrow-right"></i>
        </button>
      </form>
    <?php endif; ?>
  </div>
</div>
<?php endif; ?>
