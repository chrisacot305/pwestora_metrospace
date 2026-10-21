<?php
/**
 * POST /api/applications_create.php
 * Header: Authorization: Bearer <token>
 * Body: JSON or multipart/form-data with fields:
 *   property_id (int)
 *   business_name (string)
 *   term_months (int)
 *   rent (float)
 *   checklist_negotiation (JSON string/object)
 * Files (optional):
 *   valid_id (file: PDF/JPG/PNG/WEBP)
 *   sec_dti (file: PDF/JPG/PNG/WEBP)
 *   business_permit (file: PDF/JPG/PNG/WEBP)
 *   bir_cert (file: PDF/JPG/PNG/WEBP)
 * Response: { "ok": true, "application_id": 45 }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

// Read from either $_POST or JSON body
$propertyId   = (int) ($_POST['property_id'] ?? $body['property_id'] ?? 0);
$businessName = trim((string) ($_POST['business_name'] ?? $body['business_name'] ?? ''));
$termMonths   = (int) ($_POST['term_months'] ?? $body['term_months'] ?? 0);
$rent         = (float) ($_POST['rent'] ?? $body['rent'] ?? 0);

if ($propertyId <= 0 || $termMonths <= 0 || $rent <= 0) {
    json_error('property_id, term_months, and rent are required and must be positive.');
}

$stmt = $pdo->prepare("SELECT id, lessor_id FROM properties WHERE id = ? AND status = 'verified'");
$stmt->execute([$propertyId]);
$property = $stmt->fetch();

if (!$property) {
    json_error('Property not found or not currently accepting applications.', 404);
}

// Prevent the same tenant from spamming duplicate pending applications on the same listing.
$dupe = $pdo->prepare(
    "SELECT id FROM applications WHERE property_id = ? AND lessee_id = ? AND status = 'pending'"
);
$dupe->execute([$propertyId, $lessee['id']]);
if ($dupe->fetch()) {
    json_error('You already have a pending application for this property.', 409);
}

$negotiation = $_POST['checklist_negotiation'] ?? $body['checklist_negotiation'] ?? null;
$negotiationJson = $negotiation ? (is_string($negotiation) ? $negotiation : json_encode($negotiation)) : null;

// Ensure new columns exist on applications table
try {
    $pdo->exec("
        ALTER TABLE applications 
        ADD COLUMN checklist_negotiation LONGTEXT NULL,
        ADD COLUMN lessor_rebuttal TEXT NULL,
        ADD COLUMN rebuttal_at DATETIME NULL,
        ADD COLUMN valid_id_path VARCHAR(255) NULL,
        ADD COLUMN sec_dti_path VARCHAR(255) NULL,
        ADD COLUMN business_permit_path VARCHAR(255) NULL,
        ADD COLUMN bir_cert_path VARCHAR(255) NULL
    ");
} catch (Throwable $e) {
    // Columns already exist or database ignored
}

try {
    $insert = $pdo->prepare(
        'INSERT INTO applications (property_id, lessor_id, lessee_id, tenant_name, business_name, term_months, rent, checklist_negotiation)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $insert->execute([
        $propertyId, $property['lessor_id'], $lessee['id'],
        $lessee['full_name'], $businessName, $termMonths, $rent, $negotiationJson,
    ]);
} catch (Throwable $e) {
    $insert = $pdo->prepare(
        'INSERT INTO applications (property_id, lessor_id, lessee_id, tenant_name, business_name, term_months, rent)
         VALUES (?, ?, ?, ?, ?, ?, ?)'
    );
    $insert->execute([
        $propertyId, $property['lessor_id'], $lessee['id'],
        $lessee['full_name'], $businessName, $termMonths, $rent,
    ]);
}

$appId = (int) $pdo->lastInsertId();

// Handle uploaded verification documents
$ALLOWED_EXT = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
$MAX_FILE_MB = 10;

function save_app_doc(string $field, int $appId, array $allowedExt, int $maxMb): ?string {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    $file = $_FILES[$field];
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return null;
    }
    if ($file['size'] > $maxMb * 1024 * 1024) {
        throw new RuntimeException("File \"$field\" exceeds {$maxMb}MB limit.");
    }
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $allowedExt, true)) {
        throw new RuntimeException("Invalid file format for \"$field\". Accepted: " . implode(', ', $allowedExt));
    }

    $dir = UPLOAD_DIR . "/applications/{$appId}";
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    $filename = $field . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $dest = "$dir/$filename";
    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        throw new RuntimeException("Could not save \"$field\".");
    }
    return "uploads/applications/{$appId}/{$filename}";
}

try {
    $docUpdates = [];
    $docParams = [];

    $fields = [
        'valid_id'        => 'valid_id_path',
        'sec_dti'         => 'sec_dti_path',
        'business_permit' => 'business_permit_path',
        'bir_cert'        => 'bir_cert_path',
    ];

    foreach ($fields as $field => $col) {
        $path = save_app_doc($field, $appId, $ALLOWED_EXT, $MAX_FILE_MB);
        if ($path !== null) {
            $docUpdates[] = "$col = ?";
            $docParams[] = $path;
        }
    }

    if (!empty($docUpdates)) {
        $docParams[] = $appId;
        $pdo->prepare("UPDATE applications SET " . implode(', ', $docUpdates) . " WHERE id = ?")->execute($docParams);
    }
} catch (Throwable $e) {
    // If file handling had an issue, report or log
    error_log("Application doc upload error: " . $e->getMessage());
}

json_ok(['application_id' => $appId], 201);
