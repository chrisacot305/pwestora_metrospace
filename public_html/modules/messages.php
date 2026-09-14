<?php
/**
 * modules/messages.php  (Lessor → "Messages")
 * PHP port of the Messages + ComposeNotification components.
 */
$lessorId = $user['id'];
$error = '';

$NOTICE_TYPES = ['General Notice', 'Payment Reminder', 'Maintenance Update'];

$tenants = $pdo->prepare('SELECT id, tenant_name FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

/** Get (or lazily create) the thread between this lessor and a tenant. */
function get_or_create_thread(PDO $pdo, int $lessorId, int $tenantId): int {
    $stmt = $pdo->prepare('SELECT id FROM message_threads WHERE lessor_id = ? AND tenant_id = ?');
    $stmt->execute([$lessorId, $tenantId]);
    $row = $stmt->fetch();
    if ($row) return (int) $row['id'];

    $pdo->prepare('INSERT INTO message_threads (lessor_id, tenant_id) VALUES (?, ?)')->execute([$lessorId, $tenantId]);
    return (int) $pdo->lastInsertId();
}

// ---- Send a direct message ----
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send_message'])) {
    csrf_check();
    $tenantId = (int) $_POST['tenant_id'];
    $body = trim($_POST['body'] ?? '');

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    try {
        if ($check->fetch() && $body !== '') {
            $threadId = get_or_create_thread($pdo, $lessorId, $tenantId);
            $pdo->prepare('INSERT INTO messages (thread_id, sender, body) VALUES (?, "lessor", ?)')->execute([$threadId, $body]);
        }
        header('Location: /dashboard.php?page=messages&tenant=' . $tenantId);
        exit;
    } catch (Throwable $e) {
        error_log('Send message failed: ' . $e->getMessage());
        $error = 'Could not send this message — the error has been logged. Please try again.';
    }
}

// ---- Broadcast a formal notification ----
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send_notification'])) {
    csrf_check();
    $allTenants = isset($_POST['all_tenants']);
    $recipientIds = $allTenants
        ? array_column($tenants, 'id')
        : array_map('intval', $_POST['recipient_ids'] ?? []);
    $type = in_array($_POST['notice_type'] ?? '', $NOTICE_TYPES, true) ? $_POST['notice_type'] : 'General Notice';
    $body = trim($_POST['notice_body'] ?? '');

    if (!$recipientIds || $body === '') {
        $error = 'Select at least one recipient and write a message.';
    } else {
        try {
            // Only send to tenants that actually belong to this lessor.
            $valid = array_column($tenants, 'id');
            $recipientIds = array_values(array_intersect($recipientIds, $valid));

            foreach ($recipientIds as $tid) {
                $threadId = get_or_create_thread($pdo, $lessorId, $tid);
                $pdo->prepare('INSERT INTO messages (thread_id, sender, notice_type, body) VALUES (?, "lessor", ?, ?)')
                    ->execute([$threadId, $type, $body]);
            }
            $pdo->prepare('INSERT INTO notifications_log (sender_id, audience, title, body) VALUES (?, ?, ?, ?)')
                ->execute([$lessorId, $allTenants ? 'all_tenants' : (count($recipientIds) . ' selected'), $type, $body]);
            audit_log($pdo, $lessorId, 'Sent notification', "$type to " . count($recipientIds) . ' tenant(s)');

            header('Location: /dashboard.php?page=messages');
            exit;
        } catch (Throwable $e) {
            error_log('Send notification failed: ' . $e->getMessage());
            $error = 'Could not send this notification — the error has been logged. Please try again.';
        }
    }
}

$activeTenantId = isset($_GET['tenant']) ? (int) $_GET['tenant'] : ($tenants[0]['id'] ?? null);
$activeTenant = null;
foreach ($tenants as $t) {
    if ((int) $t['id'] === $activeTenantId) { $activeTenant = $t; break; }
}

$thread = [];
if ($activeTenant) {
    $threadStmt = $pdo->prepare(
        'SELECT m.* FROM messages m
         JOIN message_threads mt ON mt.id = m.thread_id
         WHERE mt.lessor_id = ? AND mt.tenant_id = ?
         ORDER BY m.sent_at ASC'
    );
    $threadStmt->execute([$lessorId, $activeTenantId]);
    $thread = $threadStmt->fetchAll();
}

$sentLog = $pdo->prepare('SELECT * FROM notifications_log WHERE sender_id = ? ORDER BY sent_at DESC LIMIT 20');
$sentLog->execute([$lessorId]);
$sentLog = $sentLog->fetchAll();

$composing = isset($_GET['compose']);
?>
<h2 style="margin:0 0 4px;">Messages</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Direct threads per tenant, plus formal notifications you can send to one or all.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div style="display:flex; justify-content:flex-end; margin-bottom:16px;">
  <a href="/dashboard.php?page=messages&compose=1<?= $activeTenantId ? '&tenant=' . $activeTenantId : '' ?>"
     class="btn" style="background:var(--accent); color:#fff; display:inline-flex;">
    <i class="bi bi-megaphone"></i> New Notification
  </a>
</div>

<?php if (!$tenants): ?>
  <div class="card"><p style="color:var(--ink-500); font-size:13px; margin:0;">You don't have any active tenants yet — messaging opens up once an application is approved.</p></div>
<?php else: ?>
<div class="chat-shell">
  <div class="chat-sidebar">
    <?php foreach ($tenants as $t): ?>
      <a href="/dashboard.php?page=messages&tenant=<?= $t['id'] ?>" class="chat-tenant-btn <?= $t['id'] == $activeTenantId ? 'active' : '' ?>">
        <p style="font-size:12.5px; font-weight:600; color:var(--ink-900);"><?= htmlspecialchars($t['tenant_name']) ?></p>
      </a>
    <?php endforeach; ?>
  </div>
  <div class="chat-main">
    <div class="chat-messages">
      <?php if (!$thread): ?>
        <p style="font-size:12.5px; color:var(--ink-500);">No messages yet with this tenant.</p>
      <?php else: foreach ($thread as $m): $isMe = $m['sender'] === 'lessor'; ?>
        <div class="chat-bubble-row <?= $isMe ? 'me' : '' ?>">
          <div class="chat-bubble <?= $isMe ? 'me' : 'tenant' ?>">
            <?php if ($m['notice_type']): ?><p class="notice-label"><?= htmlspecialchars($m['notice_type']) ?></p><?php endif; ?>
            <div class="bubble-text"><?= nl2br(htmlspecialchars($m['body'])) ?></div>
            <p class="bubble-time"><?= (new DateTime($m['sent_at']))->format('M j, g:i A') ?></p>
          </div>
        </div>
      <?php endforeach; endif; ?>
    </div>
    <form method="POST" class="chat-input-row">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="send_message" value="1">
      <input type="hidden" name="tenant_id" value="<?= $activeTenantId ?>">
      <input type="text" name="body" placeholder="Write a message…" required autocomplete="off">
      <button type="submit" class="chat-send-btn"><i class="bi bi-send-fill"></i></button>
    </form>
  </div>
</div>
<?php endif; ?>

<p style="font-weight:700; font-size:14px; margin:28px 0 12px;">Sent notifications</p>
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

<?php if ($composing && $tenants): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">New Notification</h3>
      <a href="/dashboard.php?page=messages" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <form method="POST" id="notifyForm">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="send_notification" value="1">

      <p style="font-size:12px; font-weight:700; margin-bottom:8px;">Send to</p>
      <label style="display:flex; align-items:center; justify-content:space-between; padding:12px; border:1px solid var(--border); border-radius:10px; margin-bottom:10px; cursor:pointer;">
        <span style="font-size:12.5px; font-weight:500;"><i class="bi bi-people"></i> All tenants</span>
        <input type="checkbox" name="all_tenants" id="allTenantsBox">
      </label>
      <div id="tenantCheckboxes">
        <?php foreach ($tenants as $t): ?>
          <label style="display:flex; align-items:center; justify-content:space-between; padding:12px; border:1px solid var(--border); border-radius:10px; margin-bottom:8px; cursor:pointer;">
            <span style="font-size:12.5px; font-weight:500;"><?= htmlspecialchars($t['tenant_name']) ?></span>
            <input type="checkbox" name="recipient_ids[]" value="<?= $t['id'] ?>"
                   <?= ($activeTenantId == $t['id']) ? 'checked' : '' ?>>
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
        <i class="bi bi-megaphone"></i> Send Notification
      </button>
    </form>
  </div>
</div>
<script>
  // Purely a convenience toggle — disables individual checkboxes when "All tenants" is checked.
  document.getElementById('allTenantsBox').addEventListener('change', function () {
    document.querySelectorAll('#tenantCheckboxes input[type="checkbox"]').forEach(function (cb) {
      cb.disabled = document.getElementById('allTenantsBox').checked;
    });
  });
</script>
<?php endif; ?>
