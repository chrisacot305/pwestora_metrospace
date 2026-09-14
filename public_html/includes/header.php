<?php
/**
 * includes/header.php
 * Expects: $user (from current_user()), $page (current ?page= id)
 */
require_once __DIR__ . '/sidebar_nav.php';
$nav = $NAV_BY_ROLE[$user['role']] ?? [];
$roleLabel = $user['role'] === 'superadmin' ? 'Super Admin' : 'Admin (Lessor)';

// Notification bell — currently only lessors receive admin notices.
$notices = [];
$unreadCount = 0;
if ($user['role'] === 'lessor') {
    $stmt = $pdo->prepare(
        "SELECT nl.*, nr.read_at FROM notification_recipients nr
         JOIN notifications_log nl ON nl.id = nr.notification_id
         WHERE nr.user_id = ? ORDER BY nl.sent_at DESC LIMIT 8"
    );
    $stmt->execute([$user['id']]);
    $notices = $stmt->fetchAll();

    $countStmt = $pdo->prepare('SELECT COUNT(*) FROM notification_recipients WHERE user_id = ? AND read_at IS NULL');
    $countStmt->execute([$user['id']]);
    $unreadCount = (int) $countStmt->fetchColumn();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title><?= APP_NAME ?> · <?= htmlspecialchars(ucfirst($page)) ?></title>
<link rel="stylesheet" href="/assets/css/style.css?v=12">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
<link rel="icon" type="image/png" href="/assets/img/icon.png">
<link rel="apple-touch-icon" href="/assets/img/apple-touch-icon.png?v=2">
<meta name="theme-color" content="#102340">
</head>
<body>
<div class="app-shell">
  <div class="sidebar-overlay" id="sidebarOverlay"></div>

  <aside class="sidebar" id="sidebar">
    <div class="brand"><img src="/assets/img/logo-web.png?v=2" alt="Pwestora"></div>
    <nav>
      <?php foreach ($nav as $item): ?>
        <a class="nav-item <?= $page === $item['id'] ? 'active' : '' ?>"
           href="/dashboard.php?page=<?= $item['id'] ?>">
          <i class="bi <?= $item['icon'] ?>"></i> <?= $item['label'] ?>
        </a>
      <?php endforeach; ?>
    </nav>
  </aside>

  <div class="main">
    <div class="topbar">
      <div class="who">
        <button class="menu-toggle" id="menuToggle" aria-label="Open menu"><i class="bi bi-list"></i></button>
        <div style="min-width:0;">
          <strong><?= htmlspecialchars($user['company'] ?: $user['name']) ?></strong>
          <span class="role-pill" style="margin-left:8px;"><?= $roleLabel ?></span>
        </div>
      </div>
      <div class="right">
        <?php if ($user['role'] === 'lessor'): ?>
        <div class="notif-wrap">
          <button class="notif-bell" id="notifBell" aria-label="Notifications" type="button">
            <i class="bi bi-bell"></i>
            <?php if ($unreadCount > 0): ?>
              <span class="notif-badge"><?= $unreadCount > 9 ? '9+' : $unreadCount ?></span>
            <?php endif; ?>
          </button>
          <div class="notif-dropdown" id="notifDropdown">
            <div class="notif-dropdown-header">
              <strong>Notices from Pwestora</strong>
              <?php if ($unreadCount > 0): ?>
                <a href="/notifications_mark_read.php">Mark all read</a>
              <?php endif; ?>
            </div>
            <?php if (!$notices): ?>
              <div class="notif-empty">No notices yet.</div>
            <?php else: foreach ($notices as $n): ?>
              <div class="notif-item">
                <div class="notif-meta">
                  <span class="badge" style="background:var(--accent-soft); color:var(--primary);"><?= htmlspecialchars($n['title']) ?></span>
                  <span style="font-size:10.5px; color:var(--ink-300);"><?= (new DateTime($n['sent_at']))->format('M j') ?></span>
                </div>
                <p><?= nl2br(htmlspecialchars($n['body'])) ?></p>
              </div>
            <?php endforeach; endif; ?>
          </div>
        </div>
        <?php endif; ?>
        <span class="email-full"><?= htmlspecialchars($user['email']) ?></span>
        <a href="/logout.php" class="btn btn-primary" style="padding:8px 14px;">
          <i class="bi bi-box-arrow-right"></i> <span class="d-none-mobile">Log out</span>
        </a>
      </div>
    </div>
    <div class="content">
<script>
(function () {
  var sidebar = document.getElementById('sidebar');
  var overlay = document.getElementById('sidebarOverlay');
  var toggle = document.getElementById('menuToggle');
  function open() { sidebar.classList.add('open'); overlay.classList.add('open'); }
  function close() { sidebar.classList.remove('open'); overlay.classList.remove('open'); }
  toggle && toggle.addEventListener('click', open);
  overlay && overlay.addEventListener('click', close);

  var bell = document.getElementById('notifBell');
  var dropdown = document.getElementById('notifDropdown');
  if (bell && dropdown) {
    bell.addEventListener('click', function (e) {
      e.stopPropagation();
      dropdown.classList.toggle('open');
    });
    document.addEventListener('click', function (e) {
      if (!dropdown.contains(e.target) && e.target !== bell) {
        dropdown.classList.remove('open');
      }
    });
  }
})();
</script>