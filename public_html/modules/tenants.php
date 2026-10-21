<?php
/**
 * modules/tenants.php  (Lessor → "Tenants")
 * Roster of active tenants with their negotiated checklist history,
 * counter-offer records, and conversation dialogue.
 */
require_once __DIR__ . '/../includes/lease_checklist.php';
$lessorId = $user['id'];
$error = '';

$tenants = $pdo->prepare(
    "SELECT t.id, t.tenant_name, t.created_at, t.application_id, p.name AS property_name,
            a.term_months, a.rent, a.business_name, a.submitted_at,
            a.checklist_negotiation, a.lessor_rebuttal, a.rebuttal_at,
            u.email AS lessee_email, u.phone AS lessee_phone
     FROM tenants t
     JOIN properties p ON p.id = t.property_id
     LEFT JOIN applications a ON a.id = t.application_id
     LEFT JOIN users u ON u.id = t.lessee_id
     WHERE t.lessor_id = ?
     ORDER BY t.created_at DESC"
);
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

$now = new DateTime();
$totalActive = count($tenants);
$expiringSoon = 0;
$monthlyRentTotal = 0;

foreach ($tenants as &$t) {
    $t['rent'] = (float) ($t['rent'] ?? 0);
    $monthlyRentTotal += $t['rent'];

    $t['lease_end'] = null;
    $t['status_label'] = 'Active';
    $t['status_style'] = 'background:var(--success-soft); color:var(--success);';

    if ($t['term_months']) {
        $end = (clone $now)->setTimestamp(strtotime($t['created_at']));
        $end->modify('+' . (int) $t['term_months'] . ' months');
        $t['lease_end'] = $end;

        $daysLeft = (int) $now->diff($end)->format('%r%a');
        if ($daysLeft <= 30 && $daysLeft >= 0) {
            $expiringSoon++;
            $t['status_label'] = 'Expiring (' . $daysLeft . 'd)';
            $t['status_style'] = 'background:var(--warning-soft); color:var(--warning);';
        } elseif ($daysLeft < 0) {
            $t['status_label'] = 'Lease ended';
            $t['status_style'] = 'background:var(--bg); color:var(--ink-500);';
        }
    }

    // Parse checklist negotiation for this tenant
    $negotiation = [];
    if (!empty($t['checklist_negotiation'])) {
        $decoded = json_decode($t['checklist_negotiation'], true);
        if (is_array($decoded)) $negotiation = $decoded;
    }

    $clauseKeys = array_filter(array_keys($negotiation), function($k) { return $k !== 'messages'; });
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
    $t['checklist_total'] = $totalClauses;
    $t['checklist_agreed'] = $agreedCount;
    $t['counter_offers'] = $counterOffers;
    $t['negotiation'] = $negotiation;
}
unset($t);

$viewTermsId = isset($_GET['view_terms']) ? (int) $_GET['view_terms'] : null;
$viewingTenant = null;
if ($viewTermsId) {
    foreach ($tenants as $t) {
        if ((int) $t['id'] === $viewTermsId) { $viewingTenant = $t; break; }
    }
}
?>
<h2 style="margin:0 0 4px;">Tenants</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Your active roster and agreed checklist records.</p>

<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<div class="kpi-grid">
  <div class="card">
    <div class="kpi-label">Total Active Tenants</div>
    <div class="kpi-value"><?= $totalActive ?></div>
  </div>
  <div class="card">
    <div class="kpi-label">Expiring Leases (30d)</div>
    <div class="kpi-value"><?= $expiringSoon ?></div>
    <?php if ($expiringSoon > 0): ?>
      <div style="font-size:11px; color:var(--warning); margin-top:2px;">Requires attention</div>
    <?php endif; ?>
  </div>
  <div class="card">
    <div class="kpi-label">Total Monthly Rent</div>
    <div class="kpi-value">₱<?= number_format($monthlyRentTotal, 0) ?></div>
  </div>
</div>

<div class="card" style="padding:0; overflow:hidden;">
  <?php if ($tenants): ?>
  <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center; padding:14px 16px; border-bottom:1px solid var(--border);">
    <div style="flex:1; min-width:220px; position:relative;">
      <i class="bi bi-search" style="position:absolute; left:12px; top:50%; transform:translateY(-50%); color:var(--ink-400); font-size:13px;"></i>
      <input id="tenant-search" type="search" placeholder="Search tenant, business, property, or contact…"
             autocomplete="off"
             style="width:100%; box-sizing:border-box; padding:8px 12px 8px 34px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:13px; background:var(--bg); color:var(--ink-900);">
    </div>
    <select id="tenant-status-filter"
            style="padding:8px 12px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:13px; background:#fff; color:var(--ink-900); min-width:160px;">
      <option value="">All statuses</option>
      <option value="active">Active</option>
      <option value="expiring">Expiring (30d)</option>
      <option value="ended">Lease ended</option>
    </select>
    <span id="tenant-filter-count" style="font-size:12.5px; color:var(--ink-500); white-space:nowrap;"></span>
  </div>
  <?php endif; ?>
  <div class="table-scroll">
  <table>
    <thead><tr><th>Tenant</th><th>Property</th><th>Checklist</th><th>Lease Status</th><th>Contact</th><th>Move-in Date</th><th>End Date</th><th>Rent</th><th></th></tr></thead>
    <tbody>
      <?php if (!$tenants): ?>
        <tr><td colspan="9" style="text-align:center; color:var(--ink-500);">No active tenants yet — approve an application to get started.</td></tr>
      <?php else: foreach ($tenants as $t):
        $statusKey = 'active';
        if ($t['status_label'] === 'Lease ended') $statusKey = 'ended';
        elseif (strpos($t['status_label'], 'Expiring') === 0) $statusKey = 'expiring';
        $searchBlob = strtolower(trim(implode(' ', array_filter([
            $t['tenant_name'],
            $t['business_name'] ?? '',
            $t['property_name'] ?? '',
            $t['lessee_email'] ?? '',
            $t['lessee_phone'] ?? '',
            $t['status_label'],
        ]))));
      ?>
        <tr class="tenant-row" data-status="<?= htmlspecialchars($statusKey) ?>" data-search="<?= htmlspecialchars($searchBlob) ?>">
          <td style="font-weight:600;">
            <?= htmlspecialchars($t['tenant_name']) ?>
            <?php if (!empty($t['business_name'])): ?>
              <div style="font-size:11.5px; color:var(--ink-500); font-weight:400;"><?= htmlspecialchars($t['business_name']) ?></div>
            <?php endif; ?>
          </td>
          <td style="color:var(--ink-500);"><?= htmlspecialchars($t['property_name']) ?></td>
          <td>
            <?php if (empty($t['counter_offers'])): ?>
              <span class="badge" style="background:var(--success-soft); color:var(--success); font-weight:600;"><?= $t['checklist_agreed'] ?>/<?= $t['checklist_total'] ?> Agreed</span>
            <?php else: ?>
              <span class="badge" style="background:var(--warning-soft); color:var(--warning); font-weight:600;"><?= $t['checklist_agreed'] ?>/<?= $t['checklist_total'] ?> (<?= count($t['counter_offers']) ?> Counter)</span>
            <?php endif; ?>
          </td>
          <td><span class="badge" style="<?= $t['status_style'] ?>"><?= htmlspecialchars($t['status_label']) ?></span></td>
          <td style="color:var(--ink-500); font-size:12.5px;">
            <?php if ($t['lessee_email']): ?>
              <?= htmlspecialchars($t['lessee_email']) ?><?php if ($t['lessee_phone']): ?><br><?= htmlspecialchars($t['lessee_phone']) ?><?php endif; ?>
            <?php else: ?>
              <span style="color:var(--ink-300);">Not on file</span>
            <?php endif; ?>
          </td>
          <td style="color:var(--ink-500);"><?= (new DateTime($t['created_at']))->format('M j, Y') ?></td>
          <td style="color:var(--ink-500);">
            <?= $t['lease_end'] ? $t['lease_end']->format('M j, Y') : '<span style="color:var(--ink-300);">Unknown</span>' ?>
          </td>
          <td style="color:var(--ink-500);">₱<?= number_format($t['rent'], 0) ?></td>
          <td>
            <div style="display:flex; gap:6px;">
              <a href="/dashboard.php?page=tenants&view_terms=<?= $t['id'] ?>"
                 class="btn" style="background:var(--bg); color:var(--ink-900); padding:6px 12px; display:inline-flex; border:1px solid var(--border); font-size:12px;">
                <i class="bi bi-file-text"></i> Terms
              </a>
              <a href="/dashboard.php?page=messages&tenant=<?= $t['id'] ?>"
                 class="btn" style="background:var(--bg); color:var(--ink-900); padding:6px 12px; display:inline-flex; border:1px solid var(--border); font-size:12px;">
                <i class="bi bi-chat-dots"></i> Message
              </a>
            </div>
          </td>
        </tr>
      <?php endforeach; endif; ?>
        <tr id="tenant-empty-filter" style="display:none;">
          <td colspan="9" style="text-align:center; color:var(--ink-500);">No tenants match your search or filter.</td>
        </tr>
    </tbody>
  </table>
  </div>
</div>
<?php if ($tenants): ?>
<script>
(function () {
  var search = document.getElementById('tenant-search');
  var status = document.getElementById('tenant-status-filter');
  var count = document.getElementById('tenant-filter-count');
  var empty = document.getElementById('tenant-empty-filter');
  var rows = Array.prototype.slice.call(document.querySelectorAll('.tenant-row'));
  var total = rows.length;

  function applyFilter() {
    var q = (search.value || '').trim().toLowerCase();
    var st = status.value || '';
    var shown = 0;
    rows.forEach(function (row) {
      var matchQ = !q || (row.getAttribute('data-search') || '').indexOf(q) !== -1;
      var matchS = !st || row.getAttribute('data-status') === st;
      var visible = matchQ && matchS;
      row.style.display = visible ? '' : 'none';
      if (visible) shown++;
    });
    if (empty) empty.style.display = shown ? 'none' : '';
    if (count) {
      count.textContent = (q || st) ? (shown + ' of ' + total) : (total + ' tenant' + (total === 1 ? '' : 's'));
    }
  }

  search.addEventListener('input', applyFilter);
  status.addEventListener('change', applyFilter);
  applyFilter();
})();
</script>
<?php endif; ?>

<?php if ($viewingTenant): 
  $conv = [];
  if (isset($viewingTenant['negotiation']['messages']) && is_array($viewingTenant['negotiation']['messages']) && !empty($viewingTenant['negotiation']['messages'])) {
      $conv = $viewingTenant['negotiation']['messages'];
  } else {
      if (!empty($viewingTenant['counter_offers'])) {
          $initialText = [];
          foreach ($viewingTenant['counter_offers'] as $co) {
              $initialText[] = $co['label'] . ': "' . $co['note'] . '"';
          }
          $conv[] = [
              'sender'      => 'lessee',
              'sender_name' => $viewingTenant['tenant_name'],
              'message'     => implode("\n", $initialText),
              'sent_at'     => $viewingTenant['submitted_at'] ?? $viewingTenant['created_at'],
          ];
      }
      if (!empty($viewingTenant['lessor_rebuttal'])) {
          $conv[] = [
              'sender'      => 'lessor',
              'sender_name' => 'Lessor',
              'message'     => $viewingTenant['lessor_rebuttal'],
              'sent_at'     => $viewingTenant['rebuttal_at'] ?? '',
          ];
      }
  }
?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:440px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Tenant Lease Terms</h3>
      <a href="/dashboard.php?page=tenants" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <p style="margin:4px 0; font-size:13px;"><strong>Tenant:</strong> <?= htmlspecialchars($viewingTenant['tenant_name']) ?></p>
      <?php if (!empty($viewingTenant['business_name'])): ?>
        <p style="margin:4px 0; font-size:13px;"><strong>Business:</strong> <?= htmlspecialchars($viewingTenant['business_name']) ?></p>
      <?php endif; ?>
      <p style="margin:4px 0; font-size:13px;"><strong>Property:</strong> <?= htmlspecialchars($viewingTenant['property_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Lease term:</strong> <?= (int) $viewingTenant['term_months'] ?> months</p>
      <p style="margin:4px 0; font-size:13px;"><strong>Monthly rent:</strong> ₱<?= number_format($viewingTenant['rent'], 0) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Move-in Date:</strong> <?= (new DateTime($viewingTenant['created_at']))->format('M j, Y') ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Checklist:</strong> 
        <?php if (empty($viewingTenant['counter_offers'])): ?>
          <span style="color:var(--success); font-weight:600;"><?= $viewingTenant['checklist_agreed'] ?>/<?= $viewingTenant['checklist_total'] ?> (All Agreed)</span>
        <?php else: ?>
          <span style="color:var(--warning); font-weight:600;"><?= $viewingTenant['checklist_agreed'] ?>/<?= $viewingTenant['checklist_total'] ?> (<?= count($viewingTenant['counter_offers']) ?> Counter-Offer<?= count($viewingTenant['counter_offers']) > 1 ? 's' : '' ?>)</span>
        <?php endif; ?>
      </p>
    </div>

    <?php if (!empty($viewingTenant['counter_offers'])): ?>
      <div class="card" style="margin-bottom:16px; border-left:3px solid var(--warning);">
        <p style="margin:0 0 8px; font-size:12.5px; font-weight:700; color:var(--ink-900);">Agreed Counter-Offer Details:</p>
        <?php foreach ($viewingTenant['counter_offers'] as $co): ?>
          <div style="margin-bottom:8px; font-size:12px;">
            <strong style="color:var(--ink-800);">Clause: <?= htmlspecialchars($co['label']) ?></strong>
            <div style="color:var(--ink-600); margin-top:3px; padding:6px 8px; background:var(--bg); border-radius:4px;">
              Applicant Note: "<?= htmlspecialchars($co['note']) ?>"
            </div>
          </div>
        <?php endforeach; ?>
      </div>
    <?php endif; ?>

    <?php if (!empty($conv)): ?>
      <div class="card" style="margin-bottom:16px;">
        <p style="margin:0 0 10px; font-size:12.5px; font-weight:700; color:var(--ink-900);">Negotiation Dialogue History</p>
        <div style="display:flex; flex-direction:column; gap:8px;">
          <?php foreach ($conv as $msg): 
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

    <div style="margin-top:20px;">
      <a class="btn btn-primary" style="width:100%; text-align:center; display:block; padding:10px 0; text-decoration:none;"
         href="/lease_contract.php?tenant_id=<?= $viewingTenant['id'] ?>" target="_blank">
        <i class="bi bi-file-earmark-text"></i> View / Print Official Contract
      </a>
    </div>
  </div>
</div>
<?php endif; ?>