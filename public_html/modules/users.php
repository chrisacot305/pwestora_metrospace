<?php
/**
 * modules/users.php  (SuperAdmin → "User Management")
 * PHP port of the UserManagement component in pwestora-superadmin-web.jsx.
 * Covers both Lessor and Lessee accounts platform-wide.
 */
$adminId = $user['id'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_user_id'])) {
    csrf_check();
    $targetId = (int) $_POST['toggle_user_id'];

    try {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE id = ? AND role IN ("lessor", "lessee")');
        $stmt->execute([$targetId]);
        $target = $stmt->fetch();

        if ($target) {
            $newStatus = $target['status'] === 'suspended' ? 'active' : 'suspended';
            $pdo->prepare('UPDATE users SET status = ? WHERE id = ?')->execute([$newStatus, $targetId]);
            audit_log($pdo, $adminId, ucfirst($newStatus) . ' user', $target['email']);
        }
        header('Location: /dashboard.php?page=users');
        exit;
    } catch (Throwable $e) {
        error_log('Toggle user status failed: ' . $e->getMessage());
        $error = 'Could not update this user — the error has been logged. Please try again.';
    }
}

$users = $pdo->query(
    "SELECT * FROM users WHERE role IN ('lessor', 'lessee') ORDER BY created_at DESC"
)->fetchAll();
?>
<h2 style="margin:0 0 4px;">User Management</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Suspend access instantly if platform rules are violated.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card" style="padding:0; overflow:hidden;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Name</th><th>Role</th><th>Email</th><th>Status</th><th></th></tr></thead>
    <tbody>
      <?php if (!$users): ?>
        <tr><td colspan="5" style="text-align:center; color:var(--ink-500);">No users yet.</td></tr>
      <?php else: foreach ($users as $u): ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($u['role'] === 'lessor' ? $u['company_name'] : $u['full_name']) ?></td>
          <td>
            <?php if ($u['role'] === 'lessor'): ?>
              <span class="badge" style="background:var(--bg); color:var(--primary);">Lessor</span>
            <?php else: ?>
              <span class="badge" style="background:var(--accent-soft); color:var(--primary);">Lessee</span>
            <?php endif; ?>
          </td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($u['email']) ?></td>
          <td>
            <?php if ($u['status'] === 'active'): ?>
              <span class="badge badge-active">Active</span>
            <?php elseif ($u['status'] === 'pending'): ?>
              <span class="badge badge-pending">Pending</span>
            <?php else: ?>
              <span class="badge badge-suspended">Suspended</span>
            <?php endif; ?>
          </td>
          <td>
            <form method="POST" style="display:inline;">
              <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
              <input type="hidden" name="toggle_user_id" value="<?= $u['id'] ?>">
              <?php if ($u['status'] === 'suspended'): ?>
                <button class="btn" style="background:var(--success); color:#fff; padding:6px 14px;" type="submit">
                  <i class="bi bi-play-fill"></i> Reinstate
                </button>
              <?php else: ?>
                <button class="btn" style="background:var(--error); color:#fff; padding:6px 14px;" type="submit">
                  <i class="bi bi-slash-circle"></i> Suspend
                </button>
              <?php endif; ?>
            </form>
          </td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>
