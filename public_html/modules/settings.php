<?php
/**
 * modules/settings.php  (SuperAdmin → "Platform Settings")
 * PHP port of the PlatformSettings component. Also exposes the commission
 * rate here since it's the same kind of global setting (used by Revenue).
 */
$adminId = $user['id'];
$saved = false;
$error = '';

$TOGGLES = [
    'auto_renewal_offers'    => ['Automated lease renewal offers', 'Trigger 60 days before contract expiration'],
    'qr_audit_required'      => ['Require QR audit for common areas', 'Maintenance staff must scan to log cleaning/inspection'],
    'auto_generate_eviction' => ['Auto-generate eviction notice at Strike 3', 'If off, the lessor must manually trigger the document'],
    'maintenance_mode'       => ['Platform maintenance mode', 'Temporarily blocks new logins platform-wide — use with care'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();

    try {
        $update = $pdo->prepare('UPDATE platform_settings SET setting_value = ? WHERE setting_key = ?');
        foreach ($TOGGLES as $key => $label) {
            $update->execute([isset($_POST[$key]) ? '1' : '0', $key]);
        }

        $fee = (float) ($_POST['platform_fee_percent'] ?? 5);
        $fee = max(0, min(100, $fee)); // sane bounds
        $update->execute([(string) $fee, 'platform_fee_percent']);

        audit_log($pdo, $adminId, 'Updated platform settings');
        $saved = true;
    } catch (Throwable $e) {
        error_log('Update settings failed: ' . $e->getMessage());
        $error = 'Could not save settings — the error has been logged. Please try again.';
    }
}

$rows = $pdo->query('SELECT setting_key, setting_value FROM platform_settings')->fetchAll(PDO::FETCH_KEY_PAIR);
?>
<h2 style="margin:0 0 4px;">Platform Settings</h2>
<p style="color:var(--ink-500); margin:0 0 20px;">Global rules that apply across every branch and lessor.</p>

<?php if ($saved): ?>
  <div class="success-msg">Settings saved.</div>
<?php endif; ?>
<?php if ($error): ?>
  <div class="error-msg"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<form method="POST">
  <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">

  <div class="card" style="max-width:560px;">
    <?php foreach ($TOGGLES as $key => [$label, $note]): $on = ($rows[$key] ?? '0') === '1'; ?>
      <div class="settings-row">
        <div>
          <p style="font-size:13px; font-weight:500;"><?= htmlspecialchars($label) ?></p>
          <p class="settings-note"><?= htmlspecialchars($note) ?></p>
        </div>
        <label class="toggle-switch">
          <input type="checkbox" name="<?= $key ?>" <?= $on ? 'checked' : '' ?>>
          <span class="toggle-slider"></span>
        </label>
      </div>
    <?php endforeach; ?>
  </div>

  <div class="card" style="max-width:560px; margin-top:16px;">
    <p style="font-size:13px; font-weight:700; margin-bottom:4px;">Platform commission rate</p>
    <p style="font-size:11.5px; color:var(--ink-500); margin-bottom:12px;">Applied to gross monthly rent across all leases — shown in Revenue &amp; Commission.</p>
    <div style="display:flex; align-items:center; gap:8px; max-width:160px;">
      <input type="number" name="platform_fee_percent" min="0" max="100" step="0.1"
             value="<?= htmlspecialchars($rows['platform_fee_percent'] ?? '5') ?>"
             style="width:100%; padding:11px 13px; border:1px solid var(--border); border-radius:10px; font-size:14px;">
      <span style="font-weight:700; color:var(--ink-500);">%</span>
    </div>
  </div>

  <div style="margin-top:16px;">
    <button type="submit" class="btn" style="background:var(--accent); color:#fff;">Save Changes</button>
  </div>
</form>
