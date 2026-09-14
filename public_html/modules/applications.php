<?php
/**
 * modules/applications.php  (Lessor → "Applications")
 * PHP port of the Applications component in pwestora-lessor-web.jsx.
 * Approving auto-creates the tenant record (the "digital contract" step);
 * rejecting just logs the decision.
 */
$lessorId = $user['id'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['application_id'])) {
    csrf_check();
    $appId  = (int) $_POST['application_id'];
    $action = $_POST['action'];

    $stmt = $pdo->prepare('SELECT * FROM applications WHERE id = ? AND lessor_id = ?');
    $stmt->execute([$appId, $lessorId]);
    $app = $stmt->fetch();

    if ($app && $app['status'] === 'pending') {
        if ($action === 'approve') {
            $pdo->beginTransaction();
            try {
                $pdo->prepare('UPDATE applications SET status = "approved" WHERE id = ?')->execute([$appId]);
                $pdo->prepare(
                    'INSERT INTO tenants (lessor_id, property_id, application_id, lessee_id, tenant_name) VALUES (?, ?, ?, ?, ?)'
                )->execute([$lessorId, $app['property_id'], $appId, $app['lessee_id'], $app['tenant_name']]);
                audit_log($pdo, $lessorId, 'Approved application', $app['tenant_name']);
                $pdo->commit();
            } catch (Throwable $e) {
                $pdo->rollBack();
                error_log('Approve application failed: ' . $e->getMessage());
                $error = 'Could not approve this application — the error has been logged. '
                       . 'This usually means a recent database update hasn\'t been run yet.';
            }
        } elseif ($action === 'reject') {
            $pdo->prepare('UPDATE applications SET status = "rejected" WHERE id = ?')->execute([$appId]);
            audit_log($pdo, $lessorId, 'Rejected application', $app['tenant_name']);
        } elseif ($action === 'rebuttal') {
            $rebuttal = trim($_POST['lessor_rebuttal'] ?? '');
            if ($rebuttal !== '') {
                $negotiation = [];
                if (!empty($app['checklist_negotiation'])) {
                    $decoded = json_decode($app['checklist_negotiation'], true);
                    if (is_array($decoded)) $negotiation = $decoded;
                }
                if (!isset($negotiation['messages']) || !is_array($negotiation['messages'])) {
                    $negotiation['messages'] = [];
                }
                $negotiation['messages'][] = [
                    'sender'      => 'lessor',
                    'sender_name' => $user['company_name'] ?? 'Lessor',
                    'message'     => $rebuttal,
                    'sent_at'     => date('Y-m-d H:i:s'),
                ];
                $updatedJson = json_encode($negotiation);

                try {
                    $pdo->prepare('UPDATE applications SET lessor_rebuttal = ?, rebuttal_at = NOW(), checklist_negotiation = ? WHERE id = ? AND lessor_id = ?')
                        ->execute([$rebuttal, $updatedJson, $appId, $lessorId]);
                    audit_log($pdo, $lessorId, 'Sent counter-proposal/rebuttal', $app['tenant_name']);
                } catch (Throwable $e) {
                    try {
                        $pdo->exec("ALTER TABLE applications ADD COLUMN lessor_rebuttal TEXT NULL, ADD COLUMN rebuttal_at DATETIME NULL, ADD COLUMN checklist_negotiation LONGTEXT NULL");
                        $pdo->prepare('UPDATE applications SET lessor_rebuttal = ?, rebuttal_at = NOW(), checklist_negotiation = ? WHERE id = ? AND lessor_id = ?')
                            ->execute([$rebuttal, $updatedJson, $appId, $lessorId]);
                        audit_log($pdo, $lessorId, 'Sent counter-proposal/rebuttal', $app['tenant_name']);
                    } catch (Throwable $e2) {
                        error_log('Rebuttal update failed: ' . $e2->getMessage());
                        $error = 'Could not save reply: ' . $e2->getMessage();
                    }
                }
            }
        }
    }
    if (!$error) {
        header('Location: /dashboard.php?page=applications' . ($action === 'rebuttal' ? '&review=' . $appId : ''));
        exit;
    }
}

// Manually log a new application (until the tenant-facing app can submit these directly).
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_application'])) {
    csrf_check();
    $propertyId = (int) $_POST['property_id'];
    $tenantName = trim($_POST['tenant_name'] ?? '');
    $business   = trim($_POST['business_name'] ?? '');
    $term       = (int) $_POST['term_months'];
    $rent       = (float) $_POST['rent'];

    // Make sure the property is really this lessor's and verified.
    $check = $pdo->prepare('SELECT id FROM properties WHERE id = ? AND lessor_id = ? AND status = "verified"');
    $check->execute([$propertyId, $lessorId]);

    if (!$check->fetch() || $tenantName === '' || $term <= 0 || $rent <= 0) {
        $error = 'Please select a verified property and fill in every field correctly.';
    } else {
        $pdo->prepare(
            'INSERT INTO applications (property_id, lessor_id, tenant_name, business_name, term_months, rent)
             VALUES (?, ?, ?, ?, ?, ?)'
        )->execute([$propertyId, $lessorId, $tenantName, $business, $term, $rent]);
        header('Location: /dashboard.php?page=applications');
        exit;
    }
}

$applications = $pdo->prepare(
    'SELECT a.*, p.name AS property_name, t.id AS tenant_id
     FROM applications a
     JOIN properties p ON p.id = a.property_id
     LEFT JOIN tenants t ON t.application_id = a.id
     WHERE a.lessor_id = ?
     ORDER BY a.submitted_at DESC'
);
$applications->execute([$lessorId]);
$applications = $applications->fetchAll();

$verifiedProperties = $pdo->prepare('SELECT id, name FROM properties WHERE lessor_id = ? AND status = "verified" ORDER BY name');
$verifiedProperties->execute([$lessorId]);
$verifiedProperties = $verifiedProperties->fetchAll();

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
if ($reviewId) {
    foreach ($applications as $a) {
        if ((int) $a['id'] === $reviewId) { $reviewing = $a; break; }
    }
}
?>
<h2 style="margin:0 0 4px;">Tenant Applications</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Review and decide — every decision is logged with a timestamp.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="card" style="padding:0; overflow:hidden; margin-bottom:28px;">
  <div class="table-scroll">
  <table>
    <thead><tr><th>Applicant</th><th>Property</th><th>Term</th><th>Rent</th><th>Submitted</th><th>Status</th><th></th></tr></thead>
    <tbody>
      <?php if (!$applications): ?>
        <tr><td colspan="7" style="text-align:center; color:var(--ink-500);">No applications yet.</td></tr>
      <?php else: foreach ($applications as $a): ?>
        <tr>
          <td style="font-weight:600;">
            <?= htmlspecialchars($a['tenant_name']) ?>
            <?php if ($a['business_name']): ?>
              <div style="font-size:11.5px; color:var(--ink-500); font-weight:400;"><?= htmlspecialchars($a['business_name']) ?></div>
            <?php endif; ?>
          </td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($a['property_name']) ?></td>
          <td style="color:var(--ink-500);"><?= (int) $a['term_months'] ?> mo</td>
          <td style="color:var(--ink-500);">₱<?= number_format($a['rent'], 0) ?></td>
          <td style="color:var(--ink-500);"><?= (new DateTime($a['submitted_at']))->format('M j') ?></td>
          <td>
            <?php if ($a['status'] === 'pending'): ?>
              <span class="badge badge-pending">Pending</span>
            <?php elseif ($a['status'] === 'approved'): ?>
              <span class="badge badge-approved">Approved</span>
            <?php else: ?>
              <span class="badge badge-rejected">Rejected</span>
            <?php endif; ?>
          </td>
          <td>
            <?php if ($a['status'] === 'pending'): ?>
              <a class="btn btn-primary" style="padding:6px 14px; display:inline-flex;"
                 href="/dashboard.php?page=applications&review=<?= $a['id'] ?>">Review</a>
            <?php elseif ($a['status'] === 'approved' && $a['tenant_id']): ?>
              <a class="btn" style="background:var(--bg); color:var(--ink-900); padding:6px 14px; display:inline-flex; border:1px solid var(--border);"
                 href="/lease_contract.php?tenant_id=<?= $a['tenant_id'] ?>" target="_blank">
                <i class="bi bi-file-earmark-text"></i> View Contract
              </a>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
  </div>
</div>

<div class="card" style="max-width:480px;">
  <p style="font-weight:700; font-size:14px; margin-bottom:4px;">Log an application</p>
  <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
    Received an inquiry by phone or in person? Log it here so it goes through the same review flow.
  </p>

  <?php if (!$verifiedProperties): ?>
    <p style="font-size:13px; color:var(--ink-500);">You need at least one verified property before you can log applications.</p>
  <?php else: ?>
    <form method="POST">
      <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
      <input type="hidden" name="log_application" value="1">
      <div class="field">
        <label>Property</label>
        <select name="property_id" required>
          <option value="">Select property…</option>
          <?php foreach ($verifiedProperties as $p): ?>
            <option value="<?= $p['id'] ?>"><?= htmlspecialchars($p['name']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>Applicant Name</label>
        <input type="text" name="tenant_name" required>
      </div>
      <div class="field">
        <label>Business Name (optional)</label>
        <input type="text" name="business_name">
      </div>
      <div class="field">
        <label>Lease Term (months)</label>
        <input type="number" name="term_months" min="1" required>
      </div>
      <div class="field">
        <label>Monthly Rent (₱)</label>
        <input type="number" name="rent" min="1" step="0.01" required>
      </div>
      <button class="btn btn-primary" type="submit">Log Application</button>
    </form>
  <?php endif; ?>
</div>

<?php if ($reviewing): 
  require_once __DIR__ . '/../includes/lease_checklist.php';
  $negotiation = [];
  if (!empty($reviewing['checklist_negotiation'])) {
      $decoded = json_decode($reviewing['checklist_negotiation'], true);
      if (is_array($decoded)) {
          $negotiation = $decoded;
      }
  }

  $clauseKeys = array_filter(array_keys($negotiation), function($k) {
      return $k !== 'messages';
  });
  $totalClauses = !empty($clauseKeys) ? count($clauseKeys) : count($LEASE_CHECKLIST_ITEMS);
  $counterOffers = [];
  $agreedCount = 0;

  if (empty($clauseKeys)) {
      $agreedCount = $totalClauses;
  } else {
      foreach ($clauseKeys as $key) {
          $clauseStatus = $negotiation[$key];
          $isAgreed = true;
          $note = '';
          if (is_array($clauseStatus)) {
              $isAgreed = !isset($clauseStatus['agreed']) || $clauseStatus['agreed'] === true || $clauseStatus['agreed'] === 1 || $clauseStatus['agreed'] === 'true';
              $note = trim($clauseStatus['rebuttal_note'] ?? $clauseStatus['counter_note'] ?? $clauseStatus['note'] ?? '');
          }
          
          if (!$isAgreed || !empty($note)) {
              $label = $LEASE_CHECKLIST_ITEMS[$key]['label'] ?? ucwords(str_replace('_', ' ', $key));
              $counterOffers[] = [
                  'key'   => $key,
                  'label' => $label,
                  'note'  => !empty($note) ? $note : 'Counter-offer proposed.',
              ];
          } else {
              $agreedCount++;
          }
      }
  }
  $conversation = [];
  if (isset($negotiation['messages']) && is_array($negotiation['messages']) && !empty($negotiation['messages'])) {
      $conversation = $negotiation['messages'];
  } else {
      if (!empty($counterOffers)) {
          $initialText = [];
          foreach ($counterOffers as $co) {
              $initialText[] = $co['label'] . ': "' . $co['note'] . '"';
          }
          $conversation[] = [
              'sender'      => 'lessee',
              'sender_name' => $reviewing['tenant_name'],
              'message'     => implode("\n", $initialText),
              'sent_at'     => $reviewing['submitted_at'],
          ];
      }
      if (!empty($reviewing['lessor_rebuttal'])) {
          $conversation[] = [
              'sender'      => 'lessor',
              'sender_name' => 'Lessor',
              'message'     => $reviewing['lessor_rebuttal'],
              'sent_at'     => $reviewing['rebuttal_at'] ?? '',
          ];
      }
  }
?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:440px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">AP-<?= str_pad($reviewing['id'], 3, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=applications" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Applicant:</strong> <?= htmlspecialchars($reviewing['tenant_name']) ?></p>
      <?php if ($reviewing['business_name']): ?>
        <p style="margin:4px 0; font-size:13px;"><strong>Business:</strong> <?= htmlspecialchars($reviewing['business_name']) ?></p>
      <?php endif; ?>
      <p style="margin:4px 0; font-size:13px;"><strong>Property:</strong> <?= htmlspecialchars($reviewing['property_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Lease term:</strong> <?= (int) $reviewing['term_months'] ?> months</p>
      <p style="margin:4px 0; font-size:13px;"><strong>Monthly rent:</strong> ₱<?= number_format($reviewing['rent'], 0) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Submitted:</strong> <?= (new DateTime($reviewing['submitted_at']))->format('M j, Y') ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Checklist:</strong> 
        <?php if (empty($counterOffers)): ?>
          <span style="color:var(--success); font-weight:600;"><?= $agreedCount ?>/<?= $totalClauses ?> (All Agreed)</span>
        <?php else: ?>
          <span style="color:var(--ink-700); font-weight:600;"><?= $agreedCount ?>/<?= $totalClauses ?> (<?= count($counterOffers) ?> Counter-Offer<?= count($counterOffers) > 1 ? 's' : '' ?>)</span>
        <?php endif; ?>
      </p>
    </div>

    <?php if (!empty($conversation)): ?>
      <div class="card" style="margin-bottom:16px;">
        <p style="margin:0 0 10px; font-size:12.5px; font-weight:700; color:var(--ink-900);">Negotiation Conversation</p>
        <div style="display:flex; flex-direction:column; gap:8px;">
          <?php foreach ($conversation as $msg): 
            $isLessor = ($msg['sender'] ?? '') === 'lessor';
          ?>
            <div style="padding:8px 10px; border-radius:6px; background:<?= $isLessor ? '#f0f7ff' : 'var(--bg)' ?>; border:1px solid <?= $isLessor ? '#cce3ff' : 'var(--border)' ?>;">
              <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:3px;">
                <span style="font-size:11.5px; font-weight:700; color:<?= $isLessor ? '#0b57d0' : 'var(--ink-800)' ?>;">
                  <?= htmlspecialchars($msg['sender_name'] ?? ($isLessor ? 'Lessor' : 'Applicant')) ?> (<?= $isLessor ? 'Lessor' : 'Applicant' ?>)
                </span>
                <span style="font-size:10.5px; color:var(--ink-500);">
                  <?= !empty($msg['sent_at']) ? (new DateTime($msg['sent_at']))->format('M j, g:i A') : '' ?>
                </span>
              </div>
              <div style="font-size:12px; color:<?= $isLessor ? '#1a3c6d' : 'var(--ink-700)' ?>; line-height:1.4;">
                <?= nl2br(htmlspecialchars($msg['message'] ?? '')) ?>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      </div>
    <?php endif; ?>

    <div class="card" style="margin-bottom:20px;">
      <p style="margin:0 0 6px; font-size:12.5px; font-weight:700;">Reply / Counter-Proposal to Applicant</p>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="application_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="rebuttal">
        <textarea name="lessor_rebuttal" rows="3" style="width:100%; box-sizing:border-box; font-family:inherit; font-size:12.5px; padding:8px; border:1px solid var(--border); border-radius:6px; margin-bottom:8px;" placeholder="Type your reply, counter-terms, or response..." required></textarea>
        <button class="btn btn-primary" style="width:100%; font-size:13px; padding:8px 14px;" type="submit">
          Send Reply
        </button>
      </form>
    </div>

    <div style="display:flex; gap:12px;">
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="application_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="approve">
        <button class="btn" style="width:100%; background:var(--success); color:#fff; padding:8px 14px;" type="submit">
          Approve
        </button>
      </form>
      <form method="POST" style="flex:1;">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="application_id" value="<?= $reviewing['id'] ?>">
        <input type="hidden" name="action" value="reject">
        <button class="btn" style="width:100%; background:var(--error); color:#fff; padding:8px 14px;" type="submit">
          Reject
        </button>
      </form>
    </div>
  </div>
</div>
<?php endif; ?>
