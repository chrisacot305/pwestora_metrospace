<?php
/**
 * modules/lessors.php  (SuperAdmin → "Verify Lessors")
 * PHP port of the LessorVerification component in pwestora-superadmin-web.jsx.
 * Included by dashboard.php — $pdo, $user already available.
 */
require_once __DIR__ . '/../includes/mailer.php';
$error = '';

// ---- Handle Approve / Reject ----
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['lessor_id'])) {
    csrf_check();
    $lessorId = (int) $_POST['lessor_id'];
    $action   = $_POST['action'];

    try {
        $lessorRow = $pdo->prepare('SELECT email, full_name FROM users WHERE id = ? AND role = "lessor"');
        $lessorRow->execute([$lessorId]);
        $lessorRow = $lessorRow->fetch();

        if ($action === 'approve') {
            $pdo->prepare('UPDATE users SET status = "active" WHERE id = ? AND role = "lessor"')->execute([$lessorId]);
            $pdo->prepare('UPDATE lessor_profiles SET verified_by = ?, verified_at = NOW() WHERE user_id = ?')
                ->execute([$user['id'], $lessorId]);
            audit_log($pdo, $user['id'], 'Approved lessor verification', "Lessor #$lessorId");
            if ($lessorRow) send_lessor_status_email($lessorRow['email'], $lessorRow['full_name'], true);
        } elseif ($action === 'reject') {
            $pdo->prepare('UPDATE users SET status = "suspended" WHERE id = ? AND role = "lessor"')->execute([$lessorId]);
            audit_log($pdo, $user['id'], 'Rejected lessor verification', "Lessor #$lessorId");
            if ($lessorRow) send_lessor_status_email($lessorRow['email'], $lessorRow['full_name'], false);
        }
        header('Location: /dashboard.php?page=lessors');
        exit;
    } catch (Throwable $e) {
        error_log('Lessor verification decision failed: ' . $e->getMessage());
        $error = 'Could not process this decision — the error has been logged. Please try again.';
    }
}

// ---- Data ----
$pending = $pdo->query(
    'SELECT u.*, lp.business_permit_path, lp.sec_dti_path, lp.bir_cert_path, lp.land_title_path, lp.gov_id_path
     FROM users u
     LEFT JOIN lessor_profiles lp ON lp.user_id = u.id
     WHERE u.role = "lessor" AND u.status = "pending"
     ORDER BY u.created_at DESC'
)->fetchAll();

$verified = $pdo->query(
    'SELECT u.*, (SELECT COUNT(*) FROM properties p WHERE p.lessor_id = u.id) AS property_count
     FROM users u
     WHERE u.role = "lessor" AND u.status = "active"
     ORDER BY u.company_name ASC'
)->fetchAll();

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
if ($reviewId) {
    foreach ($pending as $l) {
        if ((int) $l['id'] === $reviewId) { $reviewing = $l; break; }
    }
}

$docLabels = [
    'business_permit_path' => 'Business Permit',
    'sec_dti_path'          => 'SEC / DTI Registration',
    'bir_cert_path'         => 'BIR Certificate',
    'land_title_path'       => 'Land Title',
    'gov_id_path'           => 'Government ID',
];
?>
<h2 style="margin:0 0 4px;">Lessor Verification</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Business documents are reviewed before a lessor can list any property.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<p style="font-weight:700; font-size:13px; margin-bottom:12px;">Pending (<?= count($pending) ?>)</p>
<div class="card" style="padding:0; overflow:hidden; margin-bottom:28px;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Lessor</th><th>Contact</th><th>Submitted</th><th>Documents</th><th></th></tr></thead>
    <tbody>
      <?php if (!$pending): ?>
        <tr><td colspan="5" style="text-align:center; color:var(--ink-500);">Nothing pending.</td></tr>
      <?php else: foreach ($pending as $l):
          $docCount = 0;
          foreach ($docLabels as $key => $label) { if (!empty($l[$key])) $docCount++; }
      ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($l['company_name']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($l['email']) ?></td>
          <td style="color:var(--ink-500);"><?= (new DateTime($l['created_at']))->format('M j') ?></td>
          <td style="color:var(--ink-500);"><?= $docCount ?> / <?= count($docLabels) ?> files</td>
          <td><a class="btn btn-primary" style="padding:6px 14px; display:inline-flex;"
                 href="/dashboard.php?page=lessors&review=<?= $l['id'] ?>">Review</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<p style="font-weight:700; font-size:13px; margin-bottom:12px;">Verified lessors</p>
<div class="two-col">
  <?php if (!$verified): ?>
    <p style="color:var(--ink-500); font-size:13px;">No verified lessors yet.</p>
  <?php else: foreach ($verified as $l): ?>
    <div class="card" style="display:flex; align-items:center; justify-content:space-between;">
      <div>
        <p style="margin:0; font-weight:600; font-size:13px;"><?= htmlspecialchars($l['company_name']) ?></p>
        <p style="margin:0; font-size:11.5px; color:var(--ink-500);">
          <?= $l['property_count'] ?> properties · since <?= (new DateTime($l['created_at']))->format('M Y') ?>
        </p>
      </div>
      <span class="badge badge-verified">Verified</span>
    </div>
  <?php endforeach; endif; ?>
</div>

<?php if ($reviewing): ?>
<!-- Review drawer (server-rendered, no JS needed) -->
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">LS-<?= str_pad($reviewing['id'], 3, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=lessors" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Lessor:</strong> <?= htmlspecialchars($reviewing['company_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Contact:</strong> <?= htmlspecialchars($reviewing['email']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Submitted:</strong> <?= (new DateTime($reviewing['created_at']))->format('M j, Y') ?></p>
    </div>

    <p style="font-size:12px; font-weight:700; margin-bottom:8px;">Documents</p>
    <div style="margin-bottom:20px;">
      <?php foreach ($docLabels as $key => $label): $path = $reviewing[$key] ?? null; ?>
        <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 12px; border:1px solid var(--border); border-radius:10px; margin-bottom:8px;">
          <span style="font-size:12.5px;"><i class="bi bi-file-earmark-text"></i> <?= $label ?></span>
          <?php if ($path): ?>
            <a href="/<?= htmlspecialchars($path) ?>" target="_blank" style="font-size:12px; color:var(--primary); font-weight:600;">View</a>
          <?php else: ?>
            <span style="font-size:12px; color:var(--ink-300);">Not uploaded</span>
          <?php endif; ?>
        </div>
      <?php endforeach; ?>
    </div>

    <div style="display:flex; gap:12px;">
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="lessor_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="approve">
        <button class="btn" style="width:100%; background:var(--success); color:#fff;" type="submit">
          <i class="bi bi-check-lg"></i> Approve
        </button>
      </form>
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="lessor_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="reject">
        <button class="btn" style="width:100%; background:var(--error); color:#fff;" type="submit">
          <i class="bi bi-x-lg"></i> Reject
        </button>
      </form>
    </div>
  </div>
</div>
<?php endif; ?>
