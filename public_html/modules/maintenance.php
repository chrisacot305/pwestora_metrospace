<?php
/**
 * modules/maintenance.php  (Lessor → "Maintenance")
 * PHP port of the Maintenance component in pwestora-lessor-web.jsx.
 */
$lessorId = $user['id'];
$error = '';

$STAGES = ['Submitted', 'Under Review', 'Approved', 'Contractor Assigned', 'Scheduled', 'In Progress', 'Inspection', 'Completed'];
$LAST_STAGE = count($STAGES) - 1;

$CATEGORIES = [
    'plumbing'   => ['Plumbing',   'bi-droplet'],
    'electrical' => ['Electrical', 'bi-lightning-charge'],
    'structural' => ['Structural', 'bi-tools'],
    'internet'   => ['Internet',   'bi-wifi'],
    'hvac'       => ['HVAC',       'bi-snow'],
    'cleaning'   => ['Cleaning',   'bi-stars'],
    'security'   => ['Security',   'bi-shield-check'],
    'lighting'   => ['Lighting',   'bi-lightbulb'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['advance_ticket_id'])) {
    csrf_check();
    $ticketId = (int) $_POST['advance_ticket_id'];

    try {
        $stmt = $pdo->prepare('SELECT * FROM maintenance_tickets WHERE id = ? AND lessor_id = ?');
        $stmt->execute([$ticketId, $lessorId]);
        $ticket = $stmt->fetch();

        if ($ticket && $ticket['stage'] < $LAST_STAGE) {
            $newStage = $ticket['stage'] + 1;
            $pdo->prepare('UPDATE maintenance_tickets SET stage = ? WHERE id = ?')->execute([$newStage, $ticketId]);
            audit_log($pdo, $lessorId, 'Advanced maintenance ticket', $ticket['title'] . ' → ' . $STAGES[$newStage]);
        }
        header('Location: /dashboard.php?page=maintenance&review=' . $ticketId);
        exit;
    } catch (Throwable $e) {
        error_log('Advance ticket failed: ' . $e->getMessage());
        $error = 'Could not advance this ticket — the error has been logged. Please try again.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['log_ticket'])) {
    csrf_check();
    $tenantId   = (int) $_POST['tenant_id'];
    $category   = $_POST['category'] ?? '';
    $priority   = strtolower(trim($_POST['priority'] ?? 'medium'));
    if (!in_array($priority, ['low', 'medium', 'high', 'urgent'], true)) {
        $priority = 'medium';
    }
    $title      = trim($_POST['title'] ?? '');
    $contractor = trim($_POST['contractor'] ?? '');
    $slaHours   = (int) ($_POST['sla_hours'] ?? 0);

    $check = $pdo->prepare('SELECT id FROM tenants WHERE id = ? AND lessor_id = ?');
    $check->execute([$tenantId, $lessorId]);

    if (!$check->fetch() || !isset($CATEGORIES[$category]) || $title === '') {
        $error = 'Please fill in every required field.';
    } else {
        try {
            $slaDue = $slaHours > 0 ? date('Y-m-d H:i:s', strtotime("+{$slaHours} hours")) : null;
            $pdo->prepare(
                'INSERT INTO maintenance_tickets (lessor_id, tenant_id, category, priority, title, contractor, sla_due_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute([$lessorId, $tenantId, $category, $priority, $title, $contractor ?: null, $slaDue]);
            header('Location: /dashboard.php?page=maintenance');
            exit;
        } catch (Throwable $e) {
            error_log('Log ticket failed: ' . $e->getMessage());
            $error = 'Could not log this ticket — the error has been logged. Please try again.';
        }
    }
}

// Updated query to pull the property name associated with the tenant
$tickets = $pdo->prepare(
    'SELECT mt.*, t.tenant_name, p.name AS property_name 
     FROM maintenance_tickets mt
     JOIN tenants t ON t.id = mt.tenant_id
     LEFT JOIN properties p ON p.id = t.property_id
     WHERE mt.lessor_id = ? ORDER BY mt.created_at DESC'
);
$tickets->execute([$lessorId]);
$tickets = $tickets->fetchAll();

// Fetch properties for the dropdown
$properties = $pdo->prepare('SELECT id, name FROM properties WHERE lessor_id = ? ORDER BY name');
$properties->execute([$lessorId]);
$properties = $properties->fetchAll();

// Include property_id to allow JS filtering in the popup
$tenants = $pdo->prepare('SELECT id, tenant_name, property_id FROM tenants WHERE lessor_id = ? ORDER BY tenant_name');
$tenants->execute([$lessorId]);
$tenants = $tenants->fetchAll();

/** Compute the "Met / Xh left / Overdue" label the same way the original UI showed it. */
function sla_label(array $t, int $lastStage): array {
    if ((int) $t['stage'] === $lastStage) {
        return ['Met', true];
    }
    if (!$t['sla_due_at']) {
        return ['—', true];
    }
    $hoursLeft = (strtotime($t['sla_due_at']) - time()) / 3600;
    if ($hoursLeft <= 0) {
        return ['Overdue', false];
    }
    return [ceil($hoursLeft) . 'h left', false];
}

/** 3-Color priority basis: Normal (Blue), High (Orange), Urgent (Red) */
function get_priority_meta(?string $priority): array {
    $p = strtolower(trim((string)$priority));
    if ($p === 'urgent') {
        return [
            'label'  => 'Urgent',
            'color'  => '#DC2626', // Red
            'bg'     => '#FEF2F2',
            'border' => '#FCA5A5',
        ];
    } elseif ($p === 'high') {
        return [
            'label'  => 'High',
            'color'  => '#D97706', // Orange
            'bg'     => '#FFFBEB',
            'border' => '#FDE68A',
        ];
    } else {
        return [
            'label'  => 'Normal',
            'color'  => '#2563EB', // Blue
            'bg'     => '#EFF6FF',
            'border' => '#BFDBFE',
        ];
    }
}

$reviewId = isset($_GET['review']) ? (int) $_GET['review'] : null;
$reviewing = null;
if ($reviewId) {
    foreach ($tickets as $t) {
        if ((int) $t['id'] === $reviewId) { $reviewing = $t; break; }
    }
}

$loggingTicket = isset($_GET['log']);
?>

<div style="margin-bottom:20px;">
  <h2 style="margin:0 0 4px;">Maintenance</h2>
  <p style="color:var(--ink-500); margin:0;">Same timeline the tenant sees, nothing is hidden on either side.</p>
</div>

<?php if ($error && !$loggingTicket && !$reviewing): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<!-- FILTER BAR & LOG BUTTON -->
<div style="display:flex; gap:10px; flex-wrap:nowrap; align-items:center; padding:14px 16px; margin-bottom:20px; border:1px solid var(--border); border-radius:12px; background:var(--surface); overflow-x:auto;">
  
  <div style="flex:1; min-width:220px; position:relative;">
    <i class="bi bi-search" style="position:absolute; left:12px; top:50%; transform:translateY(-50%); color:var(--ink-400); font-size:13px;"></i>
    <input id="ticket-search" type="search" placeholder="Search title, property, tenant, or priority..."
           autocomplete="off"
           style="width:100%; box-sizing:border-box; padding:8px 12px 8px 34px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:13px; background:var(--bg); color:var(--ink-900);">
  </div>

  <a href="/dashboard.php?page=maintenance&log=1" class="btn btn-primary" style="width:auto; display:inline-flex; align-items:center; gap:6px; padding:6px 14px; font-size:12px; flex-shrink:0;">
    <i class="bi bi-plus-lg"></i> Log Ticket
  </a>

  <!-- Priority Filter (3 colors: Blue, Orange, Red) -->
  <select id="ticket-priority-filter"
          style="padding:8px 12px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:13px; background:#fff; color:var(--ink-900); min-width:140px; flex-shrink:0;">
    <option value="">All priorities</option>
    <option value="normal">🔵 Normal (Blue)</option>
    <option value="high">🟠 High (Orange)</option>
    <option value="urgent">🔴 Urgent (Red)</option>
  </select>

  <select id="ticket-status-filter"
          style="padding:8px 12px; border:1px solid var(--border); border-radius:8px; font:inherit; font-size:13px; background:#fff; color:var(--ink-900); min-width:150px; flex-shrink:0;">
    <option value="">All stages</option>
    <?php foreach($STAGES as $i => $stage): ?>
        <option value="<?= $i ?>"><?= $stage ?></option>
    <?php endforeach; ?>
  </select>
  <span id="ticket-filter-count" style="font-size:12.5px; color:var(--ink-500); white-space:nowrap; flex-shrink:0;"></span>
  
</div>
<!-- END FILTER BAR -->

<div class="card-grid" id="ticket-grid" style="margin-bottom:28px;">
  <?php if (!$tickets): ?>
    <p style="color:var(--ink-500); font-size:13px; grid-column: 1 / -1;">No maintenance tickets yet.</p>
  <?php else: foreach ($tickets as $t):
      [$catLabel, $catIcon] = $CATEGORIES[$t['category']] ?? ['Other', 'bi-three-dots'];
      [$slaText, $slaGood] = sla_label($t, $LAST_STAGE);
      $prioMeta = get_priority_meta($t['priority'] ?? 'medium');
      $pct = round(($t['stage'] / $LAST_STAGE) * 100);
      
      // Generate hidden search text for this card
      $searchBlob = strtolower(trim(implode(' ', array_filter([
          $t['title'],
          $t['tenant_name'],
          $t['property_name'] ?? '',
          $catLabel,
          $prioMeta['label'],
          $STAGES[$t['stage']]
      ]))));
  ?>
    <a href="/dashboard.php?page=maintenance&review=<?= $t['id'] ?>" class="ticket-card" data-status="<?= $t['stage'] ?>" data-priority="<?= strtolower($prioMeta['label']) ?>" data-search="<?= htmlspecialchars($searchBlob) ?>" style="text-decoration:none;">
      <div class="card" style="box-shadow: 0 1px 4px rgba(0,0,0,0.05); position:relative;">
        <div style="display:flex; align-items:center; justify-content:space-between; gap:6px;">
          <div style="display:flex; align-items:center; gap:8px;">
            <div style="width:34px; height:34px; border-radius:8px; background:var(--bg); display:flex; align-items:center; justify-content:center;" title="<?= htmlspecialchars($catLabel) ?>">
              <i class="bi <?= $catIcon ?>" style="color:var(--primary);"></i>
            </div>
            <!-- Priority Level Badge (3 Colors) -->
            <span style="font-size:11px; font-weight:700; color:<?= $prioMeta['color'] ?>; background:<?= $prioMeta['bg'] ?>; border:1px solid <?= $prioMeta['border'] ?>; padding:2px 8px; border-radius:6px; letter-spacing:0.3px; text-transform:uppercase;">
              <?= $prioMeta['label'] ?>
            </span>
          </div>
          <span class="badge <?= $slaGood ? 'badge-approved' : 'badge-pending' ?>"><?= $slaText ?></span>
        </div>
        <p style="font-size:13.5px; font-weight:700; margin:10px 0 2px; color:var(--ink-900);"><?= htmlspecialchars($t['title']) ?></p>
        <p style="font-size:11px; font-weight:600; color:var(--ink-500); margin:0 0 2px;"><?= htmlspecialchars($t['property_name'] ?? 'Unknown Property') ?></p>
        <p style="font-size:11.5px; color:var(--ink-500); margin:0;"><?= htmlspecialchars($t['tenant_name']) ?> · MT-<?= str_pad($t['id'], 4, '0', STR_PAD_LEFT) ?></p>
        <div style="width:100%; height:6px; border-radius:999px; background:var(--border); margin-top:10px;">
          <div style="height:6px; border-radius:999px; width:<?= $pct ?>%; background:var(--accent);"></div>
        </div>
        <p style="font-size:11px; color:var(--ink-500); margin:6px 0 0;"><?= $STAGES[$t['stage']] ?></p>
      </div>
    </a>
  <?php endforeach; endif; ?>
  <p id="ticket-empty-filter" style="display:none; grid-column: 1 / -1; color:var(--ink-500); text-align:center; padding:20px;">No tickets match your search or filter.</p>
</div>

<script>
(function () {
  var search = document.getElementById('ticket-search');
  var status = document.getElementById('ticket-status-filter');
  var priority = document.getElementById('ticket-priority-filter');
  var count = document.getElementById('ticket-filter-count');
  var empty = document.getElementById('ticket-empty-filter');
  var cards = Array.prototype.slice.call(document.querySelectorAll('.ticket-card'));
  var total = cards.length;

  function applyFilter() {
    var q = (search.value || '').trim().toLowerCase();
    var st = status.value || '';
    var pr = (priority ? priority.value : '') || '';
    var shown = 0;

    cards.forEach(function (card) {
      var matchQ = !q || (card.getAttribute('data-search') || '').indexOf(q) !== -1;
      var matchS = !st || card.getAttribute('data-status') === st;
      var matchP = !pr || card.getAttribute('data-priority') === pr;
      var visible = matchQ && matchS && matchP;

      card.style.display = visible ? '' : 'none';
      if (visible) shown++;
    });

    if (empty && total > 0) empty.style.display = shown ? 'none' : '';
    if (count) {
      count.textContent = (q || st || pr) ? (shown + ' of ' + total) : (total + ' ticket' + (total === 1 ? '' : 's'));
    }
  }

  if (search && status) {
    search.addEventListener('input', applyFilter);
    status.addEventListener('change', applyFilter);
    if (priority) priority.addEventListener('change', applyFilter);
    applyFilter(); // Run on load
  }
})();
</script>

<!-- LOG TICKET POPUP DRAWER -->
<?php if ($loggingTicket || ($error && !$reviewing)): ?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:440px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">Log a ticket</h3>
      <a href="/dashboard.php?page=maintenance" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
    </div>
    
    <p style="font-size:12.5px; color:var(--ink-500); margin-bottom:16px;">
      Received a maintenance issue by phone or in person? Log it so it's tracked the same way.
    </p>

    <?php if ($error): ?>
      <div class="error-msg" style="margin-bottom:16px;"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?php if (!$tenants): ?>
      <p style="font-size:13px; color:var(--ink-500);">You don't have any active tenants yet.</p>
    <?php else: ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="log_ticket" value="1">
        
        <div class="field">
          <label>Property</label>
          <select id="maint_property_select" name="property_id" required>
            <option value="">Select property…</option>
            <?php foreach ($properties as $p): ?>
              <option value="<?= $p['id'] ?>"><?= htmlspecialchars($p['name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <div class="field">
          <label>Tenant</label>
          <select id="maint_tenant_select" name="tenant_id" required disabled>
            <option value="">Select a property first…</option>
            <!-- These options are hidden and managed by JS based on property_id -->
            <?php foreach ($tenants as $t): ?>
              <option value="<?= $t['id'] ?>" data-property="<?= $t['property_id'] ?>"><?= htmlspecialchars($t['tenant_name']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        
        <div class="field">
          <label>Category</label>
          <select name="category" required>
            <option value="">Select category…</option>
            <?php foreach ($CATEGORIES as $id => [$label, $icon]): ?>
              <option value="<?= $id ?>"><?= $label ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <div class="field">
          <label>Priority Level</label>
          <select name="priority">
            <option value="medium">🔵 Normal (Blue)</option>
            <option value="high">🟠 High (Orange)</option>
            <option value="urgent">🔴 Urgent (Red)</option>
          </select>
        </div>
        
        <div class="field">
          <label>Issue Title</label>
          <input type="text" name="title" placeholder="e.g. Flickering lights — dining area" required>
        </div>
        
        <div class="field">
          <label>Contractor (optional)</label>
          <input type="text" name="contractor">
        </div>
        
        <div class="field">
          <label>Service Level Agreement (optional)</label>
          <input type="number" name="sla_hours" min="1" placeholder="e.g. 24">
        </div>
        
        <button class="btn btn-primary" type="submit" style="width:100%; margin-top:8px;">Log Ticket</button>
      </form>

      <!-- JAVASCRIPT FOR CASCADING DROPDOWN -->
      <script>
        document.addEventListener('DOMContentLoaded', function() {
           var propSel = document.getElementById('maint_property_select');
           var tenSel = document.getElementById('maint_tenant_select');
           
           if (propSel && tenSel) {
               var allOptions = Array.from(tenSel.querySelectorAll('option[data-property]'));
               
               propSel.addEventListener('change', function() {
                   var pid = this.value;
                   tenSel.innerHTML = '<option value="">Select tenant...</option>';
                   var hasTenants = false;
                   
                   allOptions.forEach(function(opt) {
                       if(opt.getAttribute('data-property') === pid) {
                           tenSel.appendChild(opt.cloneNode(true));
                           hasTenants = true;
                       }
                   });
                   
                   if (!pid) {
                      tenSel.innerHTML = '<option value="">Select a property first...</option>';
                      tenSel.disabled = true;
                   } else if (!hasTenants) {
                      tenSel.innerHTML = '<option value="">No tenants found here</option>';
                      tenSel.disabled = true;
                   } else {
                      tenSel.disabled = false;
                   }
               });
               
               tenSel.innerHTML = '<option value="">Select a property first...</option>';
               tenSel.disabled = true;
           }
        });
      </script>
    <?php endif; ?>
  </div>
</div>
<?php endif; ?>

<!-- REVIEW TICKET POPUP DRAWER -->
<?php if ($reviewing):
    [$slaText, $slaGood] = sla_label($reviewing, $LAST_STAGE);
    $revPrio = get_priority_meta($reviewing['priority'] ?? 'medium');
?>
<div style="position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; justify-content:flex-end; z-index:50;">
  <div style="background:#fff; width:420px; max-width:92vw; height:100%; padding:24px; overflow-y:auto;">
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
      <h3 style="margin:0;">MT-<?= str_pad($reviewing['id'], 4, '0', STR_PAD_LEFT) ?></h3>
      <a href="/dashboard.php?page=maintenance" style="font-size:20px; color:var(--ink-500); text-decoration:none;">&times;</a>
    </div>

    <div class="card" style="margin-bottom:16px;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid var(--border);">
        <span style="font-size:11px; font-weight:700; color:<?= $revPrio['color'] ?>; background:<?= $revPrio['bg'] ?>; border:1px solid <?= $revPrio['border'] ?>; padding:3px 10px; border-radius:6px; letter-spacing:0.3px; text-transform:uppercase;">
          Priority: <?= $revPrio['label'] ?>
        </span>
        <span class="badge <?= $slaGood ? 'badge-approved' : 'badge-pending' ?>"><?= $slaText ?></span>
      </div>
      <p style="margin:4px 0; font-size:13px;"><strong>Property:</strong> <?= htmlspecialchars($reviewing['property_name'] ?? 'Unknown') ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Tenant:</strong> <?= htmlspecialchars($reviewing['tenant_name']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Issue:</strong> <?= htmlspecialchars($reviewing['title']) ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>Contractor:</strong> <?= htmlspecialchars($reviewing['contractor'] ?: '—') ?></p>
      <p style="margin:4px 0; font-size:13px;"><strong>SLA:</strong> <?= $slaText ?></p>
    </div>

    <?php
      $reviewPhotos = [];
      if (!empty($reviewing['photos'])) {
          $decoded = json_decode($reviewing['photos'], true);
          if (is_array($decoded)) {
              $reviewPhotos = $decoded;
          } else {
              $reviewPhotos = [$reviewing['photos']];
          }
      }
    ?>
    <?php if (!empty($reviewPhotos)): ?>
      <div class="card" style="margin-bottom:16px; padding:14px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
          <p style="margin:0; font-size:12.5px; font-weight:700; color:var(--ink-900);">
            <i class="bi bi-images" style="color:var(--primary); margin-right:4px;"></i> Uploaded Photos (<?= count($reviewPhotos) ?>)
          </p>
          <span style="font-size:11px; color:var(--ink-400);">Click to enlarge</span>
        </div>
        <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(80px, 1fr)); gap:8px;">
          <?php foreach ($reviewPhotos as $photoPath): 
              $cleanPath = '/' . ltrim($photoPath, '/');
          ?>
            <a href="<?= htmlspecialchars($cleanPath) ?>" target="_blank" rel="noopener" title="Click to view full image" style="display:block; position:relative; aspect-ratio:1/1; border-radius:8px; overflow:hidden; border:1px solid var(--border); box-shadow:0 1px 3px rgba(0,0,0,0.06); background:#f8fafc;">
              <img src="<?= htmlspecialchars($cleanPath) ?>" alt="Issue Photo" style="width:100%; height:100%; object-fit:cover; transition:transform 0.2s;" onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
            </a>
          <?php endforeach; ?>
        </div>
      </div>
    <?php endif; ?>

    <p style="font-size:12px; font-weight:700; margin-bottom:12px;">Timeline</p>
    <div style="position:relative; padding-left:24px; margin-bottom:20px;">
      <div style="position:absolute; left:7px; top:4px; bottom:4px; width:2px; background:var(--border);"></div>
      <?php foreach ($STAGES as $i => $label): $done = $i <= $reviewing['stage']; ?>
        <div style="position:relative; padding-bottom:16px;">
          <div style="position:absolute; left:-24px; width:16px; height:16px; border-radius:50%; display:flex; align-items:center; justify-content:center;
                      background:<?= $done ? 'var(--accent)' : '#fff' ?>; border:2px solid <?= $done ? 'var(--accent)' : 'var(--border)' ?>;">
            <?php if ($done): ?><i class="bi bi-check" style="color:#fff; font-size:10px;"></i><?php endif; ?>
          </div>
          <p style="font-size:12.5px; font-weight:500; margin:0; color:<?= $done ? 'var(--ink-900)' : 'var(--ink-300)' ?>;"><?= $label ?></p>
        </div>
      <?php endforeach; ?>
    </div>

    <?php if ($reviewing['stage'] < $LAST_STAGE): ?>
      <form method="POST">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <input type="hidden" name="advance_ticket_id" value="<?= $reviewing['id'] ?>">
        <button class="btn btn-primary" style="display:flex; width:100%; justify-content:center;" type="submit">
          Advance to Next Stage <i class="bi bi-arrow-right"></i>
        </button>
      </form>
    <?php endif; ?>
  </div>
</div>
<?php endif; ?>