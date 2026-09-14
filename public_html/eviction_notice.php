<?php
/**
 * eviction_notice.php?id=123
 * A formal, printable notice for a 3rd-strike violation. Opens standalone
 * (no sidebar) so the lessor can use the browser's Print → Save as PDF.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
require_role(['lessor']);
$user = current_user();

$id = (int) ($_GET['id'] ?? 0);
$stmt = $pdo->prepare(
    'SELECT v.*, t.tenant_name, p.name AS property_name, p.address
     FROM violations v
     JOIN tenants t ON t.id = v.tenant_id
     JOIN properties p ON p.id = t.property_id
     WHERE v.id = ? AND v.lessor_id = ?'
);
$stmt->execute([$id, $user['id']]);
$v = $stmt->fetch();

if (!$v || $v['strike'] < 3) {
    http_response_code(404);
    die('Notice not available — this violation does not meet the 3-strike threshold.');
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Notice of Eviction — <?= htmlspecialchars($v['tenant_name']) ?></title>
<style>
  body { font-family: Georgia, 'Times New Roman', serif; max-width: 720px; margin: 60px auto; color: #16181D; line-height: 1.7; padding: 0 24px; }
  .letterhead { text-align: center; margin-bottom: 40px; }
  .letterhead h1 { font-size: 20px; letter-spacing: .04em; margin: 0; color: #102340; }
  .meta { display: flex; justify-content: space-between; font-size: 13px; color: #444; margin-bottom: 30px; }
  h2 { font-size: 16px; text-transform: uppercase; letter-spacing: .05em; border-bottom: 2px solid #102340; padding-bottom: 8px; }
  .signature { margin-top: 60px; }
  .print-btn { text-align: center; margin-bottom: 30px; }
  .print-btn button { padding: 10px 20px; font-size: 14px; cursor: pointer; }
  @media print { .print-btn { display: none; } }
</style>
</head>
<body>
  <div class="print-btn"><button onclick="window.print()">Print / Save as PDF</button></div>

  <div class="letterhead">
    <h1>PWESTORA</h1>
    <p style="font-size:12px; color:#666; margin-top:4px;">Formal Notice — Commercial Lease Violation</p>
  </div>

  <div class="meta">
    <span>Date issued: <?= (new DateTime($v['issued_at']))->format('F j, Y') ?></span>
    <span>Reference: VL-<?= str_pad($v['id'], 3, '0', STR_PAD_LEFT) ?></span>
  </div>

  <h2>Notice of Eviction</h2>

  <p>
    This notice is formally issued to <strong><?= htmlspecialchars($v['tenant_name']) ?></strong>, tenant of
    <strong><?= htmlspecialchars($v['property_name']) ?></strong>, located at
    <?= htmlspecialchars($v['address']) ?>.
  </p>

  <p>
    Records show this tenant has accumulated <strong>Strike <?= $v['strike'] ?></strong> under the category of
    <strong><?= htmlspecialchars($v['category']) ?></strong>, most recently issued on
    <?= (new DateTime($v['issued_at']))->format('F j, Y') ?>. Having reached the third-strike threshold as defined
    in the lease agreement, this constitutes grounds for termination of the lease and formal eviction proceedings.
  </p>

  <p>
    The tenant is hereby given notice to vacate the premises and settle any outstanding obligations within the
    period specified under the governing lease agreement and applicable local ordinances. Failure to comply may
    result in further legal action.
  </p>

  <p>This notice has been recorded in the platform's permanent audit trail and cannot be retroactively altered.</p>

  <div class="signature">
    <p>_________________________</p>
    <p style="font-size:13px; color:#555;">Authorized representative<br>Pwestora Property Management</p>
  </div>
</body>
</html>
