<?php
/**
 * modules/notify.php  (SuperAdmin → "Notify Lessors")
 * PHP port of NotifyLessors + ComposeAdminNotice components.
 */
$adminId = $user['id'];
$error = '';

$NOTICE_TYPES = ['Policy Update', 'Verification Reminder', 'Compliance Notice'];

$lessors = $pdo->query(
    "SELECT id, company_name FROM users WHERE role = 'lessor' AND status = 'active' ORDER BY company_name"
)->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send_notice'])) {
    csrf_check();
    $allLessors = isset($_POST['all_lessors']);
    $recipientIds = $allLessors
        ? array_column($lessors, 'id')
        : array_map('intval', $_POST['recipient_ids'] ?? []);
    $type = in_array($_POST['notice_type'] ?? '', $NOTICE_TYPES, true) ? $_POST['notice_type'] : 'Policy Update';
    $body = trim($_POST['notice_body'] ?? '');

    // Only allow recipients that are genuinely active lessors.
    $valid = array_column($lessors, 'id');
    $recipientIds = array_values(array_intersect($recipientIds, $valid));

    if (!$recipientIds || $body === '') {
        $error = 'Select at least one lessor and write a message.';
    } else {
        try {
            $names = [];
            foreach ($lessors as $l) {
                if (in_array($l['id'], $recipientIds, true)) $names[] = $l['company_name'];
            }
            $audience = $allLessors ? 'All lessors (' . count($recipientIds) . ')' : implode(', ', $names);

            $pdo->prepare('INSERT INTO notifications_log (sender_id, audience, title, body) VALUES (?, ?, ?, ?)')
                ->execute([$adminId, $audience, $type, $body]);
            $notificationId = (int) $pdo->lastInsertId();

            $recipientStmt = $pdo->prepare('INSERT INTO notification_recipients (notification_id, user_id) VALUES (?, ?)');
            foreach ($recipientIds as $rid) {
                $recipientStmt->execute([$notificationId, $rid]);
            }

            audit_log($pdo, $adminId, 'Sent lessor notice', "$type to " . count($recipientIds) . ' lessor(s)');

            header('Location: /dashboard.php?page=notify');
            exit;
        } catch (Throwable $e) {
            error_log('Send lessor notice failed: ' . $e->getMessage());
            $error = 'Could not send this notice — the error has been logged. Please try again.';
        }
    }
}

$sentLog = $pdo->prepare('SELECT * FROM notifications_log WHERE sender_id = ? ORDER BY sent_at DESC LIMIT 30');
$sentLog->execute([$adminId]);
$sentLog = $sentLog->fetchAll();

$composing = isset($_GET['compose']);
?>
<h2 style="margin:0 0 4px;">Notify Lessors</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Formal, logged notices — choose one lessor, several, or everyone.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div style="display:flex; justify-content:flex-end; margin-bottom:16px;">
  <a href="/dashboard.php?page=notify&compose=1" class="btn" style="background:var(--accent); color:#fff; display:inline-flex;">
    <i class="bi bi-megaphone"></i> New Notice
  </a>
</div>

<div class="card" style="padding:0; overflow:hidden;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Type</th><th>Recipients</th><th>Message</th><th>Sent</th></tr></thead>
    <tbody>
      <?php if (!$sentLog): ?>
        <tr><td colspan="4" style="text-align:center; color:var(--ink-500);">Nothing sent yet.</td></tr>
      <?php else: foreach ($sentLog as $n): ?>
        <tr>
          <td><span class="badge" style="background:var(--accent-soft); color:var(--primary);"><?= htmlspecialchars($n['title']) ?></span></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($n['audience']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($n['body']) ?></td>
          <td style="color:var(--ink-500);"><?= (new DateTime($n['sent_at']))->format('M j, g:i A') ?></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<?php if ($composing): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Notify Lessors</h3>
      <a href="/dashboard.php?page=notify" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <?php if (!$lessors): ?>
      <p style="font-size:13px; color:var(--ink-500);">No active lessors on the platform yet.</p>
    <?php else: ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="send_notice" value="1">

        <p style="font-size:12px; font-weight:700; margin-bottom:8px;">Send to</p>
        <label style="display:flex; align-items:center; justify-content:space-between; padding:12px; border:1px solid var(--border); border-radius:10px; margin-bottom:10px; cursor:pointer;">
          <span style="font-size:12.5px; font-weight:500;"><i class="bi bi-people"></i> All lessors</span>
          <input type="checkbox" name="all_lessors" id="allLessorsBox">
        </label>
        <div id="lessorCheckboxes">
          <?php foreach ($lessors as $l): ?>
            <label style="display:flex; align-items:center; justify-content:space-between; padding:12px; border:1px solid var(--border); border-radius:10px; margin-bottom:8px; cursor:pointer;">
              <span style="font-size:12.5px; font-weight:500;"><?= htmlspecialchars($l['company_name']) ?></span>
              <input type="checkbox" name="recipient_ids[]" value="<?= $l['id'] ?>">
            </label>
          <?php endforeach; ?>
        </div>

        <p style="font-size:12px; font-weight:700; margin:16px 0 8px;">Type</p>
        <div style="display:flex; gap:8px; flex-wrap:wrap; margin-bottom:16px;">
          <?php foreach ($NOTICE_TYPES as $i => $type): ?>
            <label style="font-size:11.5px; font-weight:600; padding:6px 12px; border-radius:999px; border:1px solid var(--border); cursor:pointer;">
              <input type="radio" name="notice_type" value="<?= $type ?>" <?= $i === 0 ? 'checked' : '' ?> style="margin-right:4px;"><?= $type ?>
            </label>
          <?php endforeach; ?>
        </div>

        <div class="field">
          <label>Message</label>
          <textarea name="notice_body" rows="4" required style="width:100%; padding:11px 13px; border:1px solid var(--border); border-radius:10px; font-size:14px; font-family:inherit; resize:vertical;"></textarea>
        </div>

        <button class="btn" style="width:100%; background:var(--accent); color:#fff; display:flex;" type="submit">
          <i class="bi bi-megaphone"></i> Send Notice
        </button>
      </form>
    <?php endif; ?>
  </div>
</div>
<script>
  document.getElementById('allLessorsBox')?.addEventListener('change', function () {
    document.querySelectorAll('#lessorCheckboxes input[type="checkbox"]').forEach(function (cb) {
      cb.disabled = document.getElementById('allLessorsBox').checked;
    });
  });
</script>
<?php endif; ?>
