<?php
/**
 * modules/properties.php  (SuperAdmin → "Verify Properties")
 * PHP port of the PropertyVerification component in pwestora-superadmin-web.jsx.
 */
require_once __DIR__ . '/../includes/mailer.php';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['property_id'])) {
    csrf_check();
    $propertyId = (int) $_POST['property_id'];
    $action     = $_POST['action'];

    try {
        $propRow = $pdo->prepare(
            'SELECT p.name, u.email, u.full_name FROM properties p JOIN users u ON u.id = p.lessor_id WHERE p.id = ?'
        );
        $propRow->execute([$propertyId]);
        $propRow = $propRow->fetch();

        if ($action === 'approve') {
            $pdo->prepare('UPDATE properties SET status = "verified" WHERE id = ?')->execute([$propertyId]);
            audit_log($pdo, $user['id'], 'Approved property verification', "Property #$propertyId");
            if ($propRow) send_property_status_email($propRow['email'], $propRow['full_name'], $propRow['name'], true);
        } elseif ($action === 'reject') {
            $pdo->prepare('UPDATE properties SET status = "rejected" WHERE id = ?')->execute([$propertyId]);
            audit_log($pdo, $user['id'], 'Rejected property verification', "Property #$propertyId");
            if ($propRow) send_property_status_email($propRow['email'], $propRow['full_name'], $propRow['name'], false);
        }
        header('Location: /dashboard.php?page=properties');
        exit;
    } catch (Throwable $e) {
        error_log('Property verification decision failed: ' . $e->getMessage());
        $error = 'Could not process this decision — the error has been logged. Please try again.';
    }
}

$pending = $pdo->query(
    'SELECT p.*, u.company_name AS lessor_name
     FROM properties p
     JOIN users u ON u.id = p.lessor_id
     WHERE p.status = "pending"
     ORDER BY p.created_at DESC'
)->fetchAll();

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
$reviewingPhotos = [];
if ($reviewId) {
    foreach ($pending as $p) {
        if ((int) $p['id'] === $reviewId) { $reviewing = $p; break; }
    }
    if ($reviewing) {
        $photoStmt = $pdo->prepare('SELECT photo_path FROM property_photos WHERE property_id = ? ORDER BY id ASC');
        $photoStmt->execute([$reviewId]);
        $reviewingPhotos = $photoStmt->fetchAll(PDO::FETCH_COLUMN);
    }
}

$docLabels = [
    'title_doc_path' => 'Land Title',
    'tax_dec_path'   => 'Tax Declaration',
];
?>
<h2 style="margin:0 0 4px;">Property Verification</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Every listing is checked against title and tax documents before it goes live.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card" style="padding:0; overflow:hidden;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Property</th><th>Lessor</th><th>Type</th><th>Documents</th><th></th></tr></thead>
    <tbody>
      <?php if (!$pending): ?>
        <tr><td colspan="5" style="text-align:center; color:var(--ink-500);">Nothing pending.</td></tr>
      <?php else: foreach ($pending as $p):
          $docCount = 0;
          foreach ($docLabels as $key => $label) { if (!empty($p[$key])) $docCount++; }
      ?>
        <tr>
          <td style="font-weight:600;"><?= htmlspecialchars($p['name']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($p['lessor_name']) ?></td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($p['type']) ?></td>
          <td style="color:var(--ink-500);"><?= $docCount ?> / <?= count($docLabels) ?> files</td>
          <td><a class="btn btn-primary" style="padding:6px 14px; display:inline-flex;"
                 href="/dashboard.php?page=properties&review=<?= $p['id'] ?>">Review</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<?php if ($reviewing): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">PR-<?= str_pad($reviewing['id'], 3, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=properties" style="font-size:20px; color:var(--ink-500);">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Property:</strong> <?= htmlspecialchars($reviewing['name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Lessor:</strong> <?= htmlspecialchars($reviewing['lessor_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Type:</strong> <?= htmlspecialchars($reviewing['type']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Address:</strong> <?= htmlspecialchars($reviewing['address']) ?></p>
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

    <p style="font-size:12px; font-weight:700; margin-bottom:8px;">Photos (<?= count($reviewingPhotos) ?>)</p>
    <div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; margin-bottom:20px;">
      <?php if (!$reviewingPhotos): ?>
        <p style="grid-column:1/-1; font-size:12px; color:var(--ink-300);">No photos uploaded.</p>
      <?php else: foreach ($reviewingPhotos as $photo): ?>
        <a href="/<?= htmlspecialchars($photo) ?>" target="_blank">
          <img src="/<?= htmlspecialchars($photo) ?>" alt="Property photo"
               style="width:100%; height:80px; object-fit:cover; border-radius:8px; border:1px solid var(--border);">
        </a>
      <?php endforeach; endif; ?>
    </div>

    <div style="display:flex; gap:12px;">
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="property_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="approve">
        <button class="btn" style="width:100%; background:var(--success); color:#fff;" type="submit">
          <i class="bi bi-check-lg"></i> Approve Listing
        </button>
      </form>
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="property_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="reject">
        <button class="btn" style="width:100%; background:var(--error); color:#fff;" type="submit">
          <i class="bi bi-x-lg"></i> Reject
        </button>
      </form>
    </div>
  </div>
</div>
<?php endif; ?>
