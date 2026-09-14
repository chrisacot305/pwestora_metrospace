<?php
/**
 * lease_contract.php?tenant_id=123
 * A system-generated commercial lease document combining the tenant's
 * checklist acknowledgments with the specific application terms.
 *
 * IMPORTANT: This is a TEMPLATE built from standard/common Philippine
 * commercial-leasing practice — not a substitute for legal advice. Both
 * parties should have a licensed attorney review the final lease before
 * signing anything based on this document.
 *
 * Accessible by the lessor who owns the tenant, or the tenant themself
 * if they're viewing it through a browser logged into the website.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/lease_checklist.php';
require_login();
$user = current_user();

$tenantId = (int) ($_GET['tenant_id'] ?? 0);

$stmt = $pdo->prepare(
    "SELECT t.*, p.name AS property_name, p.address AS property_address, p.type AS property_type,
            u.company_name AS lessor_name,
            lessee.full_name AS tenant_full_name,
            a.rent, a.term_months
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     JOIN users u ON u.id = t.lessor_id
     LEFT JOIN users lessee ON lessee.id = t.lessee_id
     LEFT JOIN applications a ON a.id = t.application_id
     WHERE t.id = ?"
);
$stmt->execute([$tenantId]);
$lease = $stmt->fetch();

if (!$lease) {
    http_response_code(404);
    die('Lease not found.');
}

// Access control: only the lessor who owns this tenant, or the tenant themself.
$isOwnerLessor = $user['role'] === 'lessor' && (int) $lease['lessor_id'] === (int) $user['id'];
$isThisTenant  = $user['role'] === 'lessee' && (int) $lease['lessee_id'] === (int) $user['id'];
if (!$isOwnerLessor && !$isThisTenant) {
    http_response_code(403);
    die('You do not have access to this document.');
}

$rent = (float) ($lease['rent'] ?? 0);
$term = (int) ($lease['term_months'] ?? 0);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Lease Contract — <?= htmlspecialchars($lease['tenant_name']) ?></title>
<style>
  body { font-family: Georgia, 'Times New Roman', serif; max-width: 760px; margin: 50px auto; color: #16181D; line-height: 1.7; padding: 0 24px; }
  .letterhead { text-align: center; margin-bottom: 30px; }
  .letterhead h1 { font-size: 20px; letter-spacing: .04em; margin: 0; color: #102340; }
  .disclaimer { background: #FCF1E0; border: 1px solid #E8A33D; border-radius: 8px; padding: 14px 16px; font-size: 12.5px; font-family: -apple-system, sans-serif; margin-bottom: 30px; }
  .meta { display: flex; justify-content: space-between; font-size: 13px; color: #444; margin-bottom: 24px; flex-wrap: wrap; gap: 8px; }
  h2 { font-size: 15px; text-transform: uppercase; letter-spacing: .05em; border-bottom: 2px solid #102340; padding-bottom: 6px; margin-top: 34px; }
  .party-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 10px; }
  .clause { margin-bottom: 16px; }
  .clause .num { font-weight: 700; }
  .signature { margin-top: 50px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
  .print-btn { text-align: center; margin-bottom: 20px; }
  .print-btn button { padding: 10px 20px; font-size: 14px; cursor: pointer; font-family: -apple-system, sans-serif; }
  @media print { .print-btn { display: none; } }
</style>
</head>
<body>
  <div class="print-btn"><button onclick="window.print()">Print / Save as PDF</button></div>

  <div class="letterhead">
    <h1>PWESTORA</h1>
    <p style="font-size:12px; color:#666; margin-top:4px;">Commercial Lease Agreement — System-Generated Template</p>
  </div>

  <div class="disclaimer">
    <strong>Note:</strong> This document reflects standard, common Philippine commercial-leasing practice and the terms
    both parties confirmed on the platform. It is <strong>not legal advice</strong> and is not a substitute for review
    by a licensed attorney. Both parties are encouraged to have this reviewed before signing.
  </div>

  <div class="meta">
    <span>Generated: <?= (new DateTime())->format('F j, Y') ?></span>
    <span>Reference: LC-<?= str_pad($tenantId, 4, '0', STR_PAD_LEFT) ?></span>
  </div>

  <h2>Parties</h2>
  <div class="party-grid">
    <div><strong>Lessor</strong><br><?= htmlspecialchars($lease['lessor_name']) ?></div>
    <div><strong>Tenant</strong><br><?= htmlspecialchars($lease['tenant_full_name'] ?? $lease['tenant_name']) ?></div>
  </div>

  <h2>Premises</h2>
  <p>
    <strong><?= htmlspecialchars($lease['property_name']) ?></strong> (<?= htmlspecialchars($lease['property_type']) ?>),
    located at <?= htmlspecialchars($lease['property_address']) ?>.
  </p>

  <h2>Term &amp; Rent</h2>
  <p>
    This lease is for a term of <strong><?= $term ?> months</strong>, commencing
    <?= (new DateTime($lease['created_at']))->format('F j, Y') ?>, at a monthly rent of
    <strong>₱<?= number_format($rent, 2) ?></strong>, exclusive of applicable taxes unless stated otherwise.
  </p>

  <h2>Standard Clauses</h2>
  <?php $n = 1; foreach ($LEASE_CHECKLIST_ITEMS as $item): ?>
    <div class="clause">
      <p><span class="num"><?= $n++ ?>. <?= htmlspecialchars($item['label']) ?>.</span>
      <?= htmlspecialchars($item['text']) ?></p>
    </div>
  <?php endforeach; ?>

  <h2>Acknowledgment</h2>
  <p>
    By proceeding on the Pwestora platform, the tenant confirmed acknowledgment of each clause above at the time
    of registration, and the lessor confirmed the property and lease terms at the time of listing and application review.
  </p>

  <div class="signature">
    <div>
      <p>_________________________</p>
      <p style="font-size:13px; color:#555;"><?= htmlspecialchars($lease['lessor_name']) ?><br>Lessor</p>
    </div>
    <div>
      <p>_________________________</p>
      <p style="font-size:13px; color:#555;"><?= htmlspecialchars($lease['tenant_full_name'] ?? $lease['tenant_name']) ?><br>Tenant</p>
    </div>
  </div>
</body>
</html>
