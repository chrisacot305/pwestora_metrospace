<?php
/**
 * index.php — Public landing page for Pwestora.
 * If already logged in, skip straight to the dashboard (or pending screen).
 * Otherwise: marketing page with a login/register modal instead of a
 * separate page — submitting still does a normal POST to login.php /
 * register.php (proven, working code), so the modal is purely presentational.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';

if (is_logged_in()) {
    $user = current_user();
    header('Location: ' . ($user['status'] === 'active' ? '/dashboard.php' : '/pending.php'));
    exit;
}

$REQUIRED_DOCS = [
    'business_permit' => 'Business Permit',
    'sec_dti'          => 'SEC / DTI Registration',
    'bir_cert'         => 'BIR Certificate',
    'land_title'       => 'Land Title',
    'gov_id'           => "Owner's Government ID",
];

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pwestora - Commercial Leasing Platform</title>
<meta name="description" content="Pwestora is the leasing management platform built for commercial property lessors documented agreements, payments, maintenance, and tenant communication in one workspace.">
<link rel="stylesheet" href="/assets/css/landing.css?v=6">
<link rel="icon" type="image/png" href="/assets/img/icon.png">
<meta name="theme-color" content="#102340">
</head>
<body class="landing">

<header class="l-nav">
  <a class="brand-mark" href="/"><img src="/assets/img/logo-web.png?v=2" alt="Pwestora"></a>
  <nav class="l-links">
    <a href="#platform">Platform</a><a href="#portfolio">Portfolio</a><a href="#capabilities">Capabilities</a><a href="#process">How it works</a><a href="#research">Research Foundation</a>
  </nav>
  <div class="l-nav-actions">
    <a class="l-login-link" href="#" onclick="openAuthModal('login'); return false;">Log in</a>
    <a class="l-nav-cta" href="#" onclick="openAuthModal('register'); return false;">Get started</a>
  </div>
  <button class="l-menu" onclick="openAuthModal('login')">☰</button>
</header>

<main>
<section class="l-hero">
  <div>
    <div class="l-kicker">Built for commercial property lessors</div>
    <h1>List the space.<br>Run the <span>business.</span></h1>
    <p class="l-lead">Pwestora gives lessors one workspace to manage leases, tenants, payments, maintenance, and disputes replacing scattered messages and verbal agreements with a documented, accountable system.</p>
    <div class="l-buttons">
      <a class="l-btn l-btn-primary" href="#" onclick="openAuthModal('register'); return false;">Manage your portfolio →</a>
      <a class="l-btn l-btn-secondary" href="#platform">Explore Pwestora</a>
    </div>
  </div>
  <div class="l-hero-visual">
    <div class="l-photo"></div>
    <div class="l-floating l-float-top"><div class="l-small">Your lease income</div><div class="l-big">₱28,500 / month</div><div class="l-verified">✓ Agreement documented</div></div>
    <div class="l-floating l-float-bottom"><div class="l-small">Portfolio status</div><div class="l-big">92% Occupied</div><div class="l-verified">● 12 active leases</div></div>
  </div>
</section>

<div class="l-marquee"><span>Property Owners</span><span>Commercial Spaces</span><span>Documented Agreements</span><span>Tenant Screening</span><span>Payment Tracking</span></div>

<section class="l-section" id="platform">
  <div class="l-intro">
    <div><div class="l-label">Why Pwestora</div><h2>Less uncertainty. More professional leasing.</h2></div>
    <div>
      <p>Managing commercial tenants well means clear boundaries, reliable communication, and a shared record of what was agreed. Pwestora is built around those principles for you, the lessor.</p>
      <p>Instead of relying on scattered messages and informal handshake agreements, every lease, payment, and maintenance request lives in one accountable system.</p>
    </div>
  </div>
  <div class="l-roles">
    <article class="l-role"><div class="l-icon-block">01</div><h3>Manage every space with confidence.</h3><p>Keep your commercial units, occupancy, agreements, and asking rates organized in one portfolio view.</p>
      <ul><li>Property and unit overview</li><li>Lease and agreement records</li><li>Payment monitoring</li><li>Maintenance request tracking</li></ul>
    </article>
    <article class="l-role"><div class="l-icon-block">02</div><h3>Build accountable partnerships.</h3><p>Screen prospective tenants, document lease conditions, and manage communication through a structured, traceable channel.</p>
      <ul><li>Tenant screening and verification</li><li>Digital lease agreements</li><li>Negotiated payment terms</li><li>Complaint and dispute logs</li></ul>
    </article>
  </div>
</section>

<section class="l-section" id="portfolio">
  <div class="l-label">Your portfolio</div><h2>Every space, tracked and accounted for.</h2>
  <div class="l-roles" style="grid-template-columns:repeat(3,1fr);">
    <article class="l-role" style="padding:0; overflow:hidden;">
      <div style="height:160px; background-size:cover; background-position:center; background-image:url('https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=900&q=80');"></div>
      <div style="padding:18px;">
        <span style="display:inline-block; padding:4px 10px; border-radius:20px; font-size:10px; font-weight:700; background:rgba(22,163,74,.1); color:#16A34A;">OCCUPIED</span>
        <h3 style="margin:10px 0 4px; font-size:16px;">Modern Retail Unit</h3>
        <p style="font-size:12.5px; color:var(--l-muted); margin:0;">Tenant: Dela Cruz Boutique · Bacolod City</p>
        <div style="margin-top:12px; font-weight:800; color:var(--l-navy);">₱35,000 <small style="font-weight:500; color:var(--l-muted);">/ month</small></div>
      </div>
    </article>
    <article class="l-role" style="padding:0; overflow:hidden;">
      <div style="height:160px; background-size:cover; background-position:center; background-image:url('https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80');"></div>
      <div style="padding:18px;">
        <span style="display:inline-block; padding:4px 10px; border-radius:20px; font-size:10px; font-weight:700; background:rgba(245,158,11,.14); color:#F59E0B;">VACANT</span>
        <h3 style="margin:10px 0 4px; font-size:16px;">Business Office Suite</h3>
        <p style="font-size:12.5px; color:var(--l-muted); margin:0;">Listed 9 days ago · Bacolod City</p>
        <div style="margin-top:12px; font-weight:800; color:var(--l-navy);">₱24,500 <small style="font-weight:500; color:var(--l-muted);">/ month</small></div>
      </div>
    </article>
    <article class="l-role" style="padding:0; overflow:hidden;">
      <div style="height:160px; background-size:cover; background-position:center; background-image:url('https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=900&q=80');"></div>
      <div style="padding:18px;">
        <span style="display:inline-block; padding:4px 10px; border-radius:20px; font-size:10px; font-weight:700; background:rgba(22,163,74,.1); color:#16A34A;">OCCUPIED</span>
        <h3 style="margin:10px 0 4px; font-size:16px;">Food &amp; Beverage Space</h3>
        <p style="font-size:12.5px; color:var(--l-muted); margin:0;">Tenant: Bacolod Brew Co. · Bacolod City</p>
        <div style="margin-top:12px; font-weight:800; color:var(--l-navy);">₱42,000 <small style="font-weight:500; color:var(--l-muted);">/ month</small></div>
      </div>
    </article>
  </div>
</section>

<section class="l-section" id="capabilities">
  <div class="l-label">Platform capabilities</div><h2>Built around the real friction points of leasing.</h2>
  <div class="l-features">
    <article class="l-feature"><div class="l-fico">01</div><h3>Lease &amp; Documentation</h3><p>Centralize lease terms, responsibilities, penalties, and amendments for every unit you manage.</p></article>
    <article class="l-feature"><div class="l-fico">02</div><h3>Payment Oversight</h3><p>Track due dates, document grace periods, and manage restructured payment arrangements with tenants.</p></article>
    <article class="l-feature"><div class="l-fico">03</div><h3>Facility Maintenance</h3><p>Log and track maintenance requests, repairs, and responsibilities so nothing falls through the cracks.</p></article>
    <article class="l-feature"><div class="l-fico">04</div><h3>Conflict Resolution</h3><p>Keep a structured record of complaints, response times, and step-by-step dispute resolution.</p></article>
    <article class="l-feature"><div class="l-fico">05</div><h3>Tenant Communication</h3><p>Keep decisions and conversations with tenants organized instead of relying on undocumented calls and texts.</p></article>
    <article class="l-feature"><div class="l-fico">06</div><h3>Portfolio Management</h3><p>Get a centralized operational view across every commercial space and tenant relationship you manage.</p></article>
  </div>

</section>

<section class="l-section l-workflow" id="process">
  <div class="l-label">The Pwestora process</div><h2>From listing a space to managing the relationship.</h2>
  <div class="l-steps">
    <article class="l-step"><div class="l-stepnum">01 — LIST</div><h3>List</h3><p>Add your commercial space with photos, terms, and asking rate.</p></article>
    <article class="l-step"><div class="l-stepnum">02 — SCREEN</div><h3>Screen</h3><p>Review applicants, verify tenants, and formalize lease conditions.</p></article>
    <article class="l-step"><div class="l-stepnum">03 — MANAGE</div><h3>Manage</h3><p>Track payments, maintenance, and communications in one place.</p></article>
    <article class="l-step"><div class="l-stepnum">04 — RESOLVE</div><h3>Resolve</h3><p>Handle disputes through documented, structured communication.</p></article>
  </div>
</section>

<section class="l-section l-research" id="research">
  <div class="l-intro">

    <div>
      <div class="l-label">Research Foundation</div>
      <h2>Designed from the Bacolod City leasing findings.</h2>
      </div>

    <div>
      <p> The capstone research found that maintaining formal written records was the most effective conflict-resolution strategy for lessors, while rent concessions showed the highest negotiation friction. </p>
      
      <p> The study recommends moving away from informal handshake agreements toward professionalized, documented lessor-tenant relationships with a centralized digital system as the technological intervention. </p>
    </div>
  </div>
</section>

<section class="l-cta" id="get-started">
  <h2>Professionalize your leasing business.</h2>
  <p>Pwestora gives lessors clearer records, structured negotiations, and a more accountable way to manage every property and tenant relationship.</p>
  <a class="l-btn-gold" href="#" onclick="openAuthModal('register'); return false;">Start managing your properties →</a>
</section>
</main>

<footer class="l-footer">
  <div><div class="l-footbrand"><div class="l-brand-badge"><img src="/assets/img/logo-web.png?v=2" alt="Pwestora" style="height:20px;"></div></div><p>Commercial leasing, professionalized for lessors.</p></div>
  <div class="l-foot"><h4>Platform</h4><a href="#portfolio">Your Portfolio</a><a href="#platform">Lease Management</a><a href="#process">How it works</a><a href="#get-started">Get Started</a></div>
  <div class="l-foot"><h4>System</h4><a href="#research">Capabilities</a><a href="#research">Research</a><a href="#get-started">Get Started</a></div>
  <div class="l-copyright">© <?= date('Y') ?> Pwestora. All rights reserved.</div>
</footer>

<!-- ===================== Auth Modal ===================== -->
<div class="l-modal-overlay" id="authOverlay" onclick="if(event.target===this) closeAuthModal()">
  <div class="l-modal">
    <button class="l-modal-close" onclick="closeAuthModal()">&times;</button>

    <div style="text-align:center; margin-bottom:18px;">
      <img src="/assets/img/logo-web.png?v=2" alt="Pwestora" style="height:28px;">
    </div>

    <div class="l-modal-tabs">
      <button type="button" class="l-modal-tab" id="tabLogin" onclick="switchTab('login')">Log In</button>
      <button type="button" class="l-modal-tab" id="tabRegister" onclick="switchTab('register')">Sign Up</button>
    </div>

    <!-- LOGIN PANE -->
    <div class="l-modal-pane" id="paneLogin">
      <p class="l-modal-hint">Log in as Admin (Lessor) or Super Admin.</p>
      <form method="POST" action="/login.php">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <div class="l-field">
          <label>Email</label>
          <input type="email" name="email" required autocomplete="email">
        </div>
        <div class="l-field">
          <label>Password</label>
          <input type="password" name="password" required autocomplete="current-password">
        </div>
        <button class="l-modal-submit" type="submit">Log In</button>
      </form>
    </div>

    <!-- REGISTER PANE -->
    <div class="l-modal-pane" id="paneRegister">
      <p class="l-modal-hint">Register your business as a Lessor. Our team verifies your documents before you can list properties.</p>

      <div class="l-wizard-steps">
        <div class="l-wizard-dot-wrap"><div class="l-wizard-step-dot" data-step="1">1</div><div class="l-wizard-label">Company</div></div>
        <div class="l-wizard-line"></div>
        <div class="l-wizard-dot-wrap"><div class="l-wizard-step-dot" data-step="2">2</div><div class="l-wizard-label">Contact</div></div>
        <div class="l-wizard-line"></div>
        <div class="l-wizard-dot-wrap"><div class="l-wizard-step-dot" data-step="3">3</div><div class="l-wizard-label">Documents</div></div>
      </div>

      <form method="POST" action="/register.php" enctype="multipart/form-data" id="registerForm">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">

        <div class="l-wizard-pane active" data-step="1">
          <div class="l-field"><label>Company / Business Name</label><input type="text" name="company_name" required></div>
          <div class="l-field"><label>Full Name</label><input type="text" name="full_name" required></div>
        </div>

        <div class="l-wizard-pane" data-step="2">
          <div class="l-field"><label>Email</label><input type="email" name="email" required></div>
          <div class="l-field"><label>Phone</label><input type="tel" name="phone"></div>
          <div class="l-field"><label>Password (min. 8 characters)</label><input type="password" name="password" required minlength="8"></div>
        </div>

        <div class="l-wizard-pane" data-step="3">
          <p class="l-modal-hint">PDF, JPG, or PNG · max 5MB each.</p>
          <?php foreach ($REQUIRED_DOCS as $field => $label): ?>
            <label class="l-upload-box" for="upload_<?= $field ?>">
              <div class="l-upload-icon">⬆</div>
              <div class="l-upload-text"><?= htmlspecialchars($label) ?></div>
              <div class="l-upload-filename"></div>
              <input type="file" id="upload_<?= $field ?>" name="<?= $field ?>" accept=".pdf,.jpg,.jpeg,.png" required>
            </label>
          <?php endforeach; ?>
        </div>

        <div class="l-wizard-nav">
          <button type="button" class="l-wizard-btn" id="wizPrev" onclick="prevStep()" style="visibility:hidden;">Previous</button>
          <button type="button" class="l-wizard-btn primary" id="wizNext" onclick="nextStep()">Next</button>
          <button type="submit" class="l-wizard-btn primary" id="wizSubmit" style="display:none;">Create Account</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
function openAuthModal(tab) {
  document.getElementById('authOverlay').classList.add('open');
  switchTab(tab);
  document.body.style.overflow = 'hidden';
}
function closeAuthModal() {
  document.getElementById('authOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
function switchTab(tab) {
  const isLogin = tab === 'login';
  document.getElementById('tabLogin').classList.toggle('active', isLogin);
  document.getElementById('tabRegister').classList.toggle('active', !isLogin);
  document.getElementById('paneLogin').classList.toggle('active', isLogin);
  document.getElementById('paneRegister').classList.toggle('active', !isLogin);
  if (!isLogin) showStep(1);
}
// Close on Escape key
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') closeAuthModal();
});

// ---------------- Registration wizard ----------------
let currentStep = 1;
const totalSteps = 3;

function showStep(n) {
  document.querySelectorAll('.l-wizard-pane').forEach(function (p) {
    p.classList.toggle('active', +p.dataset.step === n);
  });
  document.querySelectorAll('.l-wizard-step-dot').forEach(function (d) {
    const s = +d.dataset.step;
    d.classList.toggle('active', s === n);
    d.classList.toggle('done', s < n);
    d.textContent = s < n ? '✓' : s;
  });
  document.querySelectorAll('.l-wizard-line').forEach(function (l, i) {
    l.classList.toggle('done', (i + 1) < n);
  });
  document.getElementById('wizPrev').style.visibility = n === 1 ? 'hidden' : 'visible';
  document.getElementById('wizNext').style.display = n === totalSteps ? 'none' : 'block';
  document.getElementById('wizSubmit').style.display = n === totalSteps ? 'block' : 'none';
  currentStep = n;
}

function nextStep() {
  const pane = document.querySelector('.l-wizard-pane[data-step="' + currentStep + '"]');
  const inputs = pane.querySelectorAll('input[required]');
  for (const inp of inputs) {
    if (!inp.reportValidity()) return;
  }
  if (currentStep < totalSteps) showStep(currentStep + 1);
}

function prevStep() {
  if (currentStep > 1) showStep(currentStep - 1);
}

// Professional file-upload boxes: show the chosen filename, mark as filled.
document.querySelectorAll('.l-upload-box input[type="file"]').forEach(function (inp) {
  inp.addEventListener('change', function () {
    const box = this.closest('.l-upload-box');
    const nameEl = box.querySelector('.l-upload-filename');
    if (this.files.length) {
      box.classList.add('has-file');
      nameEl.textContent = this.files[0].name;
    } else {
      box.classList.remove('has-file');
      nameEl.textContent = '';
    }
  });
});

/* ---------------- Landing refresh behavior ----------------
   If a user refreshes while the URL contains #platform, #process,
   #research, etc., remove the hash and return to the hero section.
------------------------------------------------------------ */
(function () {
  if (window.location.hash) {
    if ('scrollRestoration' in history) {
      history.scrollRestoration = 'manual';
    }

    window.addEventListener('load', function () {
      history.replaceState(
        null,
        document.title,
        window.location.pathname + window.location.search
      );

      window.scrollTo(0, 0);
    }, { once: true });
  }
})();

</script>

</body>
</html>