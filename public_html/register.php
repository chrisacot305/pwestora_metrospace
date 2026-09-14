<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/mailer.php';

if (is_logged_in()) {
    header('Location: /dashboard.php');
    exit;
}

$error = '';

// The 5 documents SuperAdmin needs to see in Verify Lessors → Review.
// key => [db column, human label]
$REQUIRED_DOCS = [
    'business_permit' => ['business_permit_path', 'Business Permit'],
    'sec_dti'          => ['sec_dti_path',          'SEC / DTI Registration'],
    'bir_cert'         => ['bir_cert_path',          'BIR Certificate'],
    'land_title'       => ['land_title_path',        'Land Title'],
    'gov_id'           => ['gov_id_path',             "Owner's Government ID"],
];
$ALLOWED_EXT  = ['pdf', 'jpg', 'jpeg', 'png'];
$MAX_FILE_MB  = 5;

/** Validate + move one uploaded file. Returns the stored relative path, or throws on failure. */
function handle_doc_upload(string $field, int $userId, array $allowedExt, int $maxMb): string {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
        throw new RuntimeException("Please attach a file for every document — \"$field\" is missing.");
    }
    $file = $_FILES[$field];
    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException('Upload failed. Please try again.');
    }
    if ($file['size'] > $maxMb * 1024 * 1024) {
        throw new RuntimeException("Each file must be under {$maxMb}MB.");
    }
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $allowedExt, true)) {
        throw new RuntimeException('Only PDF, JPG, and PNG files are accepted.');
    }

    $dir = UPLOAD_DIR . "/verification/{$userId}";
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    $filename = $field . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $dest = "$dir/$filename";
    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        throw new RuntimeException('Could not save the uploaded file. Please try again.');
    }
    // Relative path stored in DB (relative to project root, so header.php's <a href="/..."> works)
    return "uploads/verification/{$userId}/{$filename}";
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $company  = trim($_POST['company_name'] ?? '');
    $name     = trim($_POST['full_name'] ?? '');
    $email    = trim($_POST['email'] ?? '');
    $phone    = trim($_POST['phone'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($company === '' || $name === '' || $email === '' || strlen($password) < 8) {
        $error = 'Please fill in every field. Password must be at least 8 characters.';
    } else {
        $check = $pdo->prepare('SELECT id FROM users WHERE email = ?');
        $check->execute([$email]);

        if ($check->fetch()) {
            $error = 'An account with that email already exists.';
        } else {
            $pdo->beginTransaction();
            try {
                $stmt = $pdo->prepare(
                    'INSERT INTO users (role, status, company_name, full_name, email, phone, password_hash)
                     VALUES ("lessor", "pending", ?, ?, ?, ?, ?)'
                );
                $stmt->execute([
                    $company, $name, $email, $phone,
                    password_hash($password, PASSWORD_DEFAULT),
                ]);
                $userId = (int) $pdo->lastInsertId();

                // Upload each required document now that we have a user id.
                $docPaths = [];
                foreach ($REQUIRED_DOCS as $field => [$column, $label]) {
                    $docPaths[$column] = handle_doc_upload($field, $userId, $ALLOWED_EXT, $MAX_FILE_MB);
                }

                $pdo->prepare(
                    'INSERT INTO lessor_profiles (user_id, business_permit_path, sec_dti_path, bir_cert_path, land_title_path, gov_id_path)
                     VALUES (?, ?, ?, ?, ?, ?)'
                )->execute([
                    $userId,
                    $docPaths['business_permit_path'],
                    $docPaths['sec_dti_path'],
                    $docPaths['bir_cert_path'],
                    $docPaths['land_title_path'],
                    $docPaths['gov_id_path'],
                ]);

                audit_log($pdo, $userId, 'register', "New lessor: $company");
                $pdo->commit();

                // Verify the email address is real before letting them in at all.
                $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
                $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));
                $pdo->prepare('UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE id = ?')
                    ->execute([$code, $expiresAt, $userId]);
                send_otp_email($email, $name, $code);

                $_SESSION['otp_pending_user_id'] = $userId;
                header('Location: /verify_otp.php');
                exit;
            } catch (Exception $e) {
                $pdo->rollBack();
                // A thrown validation message (e.g. wrong file type) is safe to show as-is.
                $error = ($e instanceof RuntimeException) ? $e->getMessage() : 'Something went wrong. Please try again.';
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Register as Lessor · <?= APP_NAME ?></title>
<link rel="stylesheet" href="/assets/css/style.css?v=12">
<link rel="icon" type="image/png" href="/assets/img/icon.png">
<meta name="theme-color" content="#102340">
</head>
<body>
<div class="auth-shell">

  <div class="auth-visual">
    <div class="brand-mark"><div class="brand-badge"><img src="/assets/img/logo-web.png?v=2" alt="Pwestora" style="height:22px;"></div></div>
    <div class="tagline">
      <h1>List your commercial space with confidence.</h1>
      <p>Every lessor and property is document-verified before going live —
         so tenants trust what they see, and you get serious applicants.</p>
      <div class="badges">
        <span>1–2 Business Day Review</span>
        <span>Secure Document Upload</span>
      </div>
    </div>
    <div></div>
  </div>

  <div class="auth-form-side">
    <div class="auth-card">
      <div class="card-brand"><img src="/assets/img/logo-web.png?v=2" alt="Pwestora"></div>

      <h2 class="auth-title">Create your lessor account</h2>
      <p class="auth-sub">Register your business — our team verifies your documents before you can list properties.</p>

      <?php if ($error): ?>
        <div class="error-msg"><?= htmlspecialchars($error) ?></div>
      <?php endif; ?>

      <form method="POST" enctype="multipart/form-data">
        <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">
        <div class="field">
          <label>Company / Business Name</label>
          <input type="text" name="company_name" required value="<?= htmlspecialchars($_POST['company_name'] ?? '') ?>">
        </div>
        <div class="field">
          <label>Full Name</label>
          <input type="text" name="full_name" required value="<?= htmlspecialchars($_POST['full_name'] ?? '') ?>">
        </div>
        <div class="field">
          <label>Email</label>
          <input type="email" name="email" required value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
        </div>
        <div class="field">
          <label>Phone</label>
          <input type="tel" name="phone" value="<?= htmlspecialchars($_POST['phone'] ?? '') ?>">
        </div>
        <div class="field">
          <label>Password (min. 8 characters)</label>
          <input type="password" name="password" required minlength="8">
        </div>

        <hr style="border:none; border-top:1px solid var(--border); margin:20px 0;">
        <p style="font-size:13px; font-weight:700; margin-bottom:4px;">Verification documents</p>
        <p style="font-size:12px; color:var(--ink-500); margin-bottom:14px;">
          PDF, JPG, or PNG · max 5MB each. Our team reviews these before your account is activated.
        </p>

        <?php foreach ($REQUIRED_DOCS as $field => [$column, $label]): ?>
          <div class="field">
            <label><?= htmlspecialchars($label) ?></label>
            <input type="file" name="<?= $field ?>" accept=".pdf,.jpg,.jpeg,.png" required>
          </div>
        <?php endforeach; ?>

        <button class="btn btn-primary" type="submit">Create Account</button>
      </form>

      <div style="margin-top:16px; text-align:center; font-size:13px; color: var(--ink-500);">
        Already have an account? <a class="btn-link" href="/login.php">Log in</a>
      </div>
    </div>
  </div>

</div>
</body>
</html>