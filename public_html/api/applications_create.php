<?php
/**
 * POST /api/applications_create.php
 * Header: Authorization: Bearer <token>
 * Body (JSON): { "property_id": 12, "business_name": "...", "term_months": 24, "rent": 68000 }
 * Response: { "ok": true, "application_id": 45 }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Use POST.', 405);
}

$lessee = require_lessee_auth($pdo);
$body = json_body();

$propertyId = (int) ($body['property_id'] ?? 0);
$businessName = trim($body['business_name'] ?? '');
$termMonths = (int) ($body['term_months'] ?? 0);
$rent = (float) ($body['rent'] ?? 0);

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

$negotiation = $body['checklist_negotiation'] ?? null;
$negotiationJson = $negotiation ? (is_string($negotiation) ? $negotiation : json_encode($negotiation)) : null;

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
    try {
        $pdo->exec("ALTER TABLE applications ADD COLUMN checklist_negotiation LONGTEXT NULL, ADD COLUMN lessor_rebuttal TEXT NULL, ADD COLUMN rebuttal_at DATETIME NULL");
        $insert = $pdo->prepare(
            'INSERT INTO applications (property_id, lessor_id, lessee_id, tenant_name, business_name, term_months, rent, checklist_negotiation)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $insert->execute([
            $propertyId, $property['lessor_id'], $lessee['id'],
            $lessee['full_name'], $businessName, $termMonths, $rent, $negotiationJson,
        ]);
    } catch (Throwable $e2) {
        $insert = $pdo->prepare(
            'INSERT INTO applications (property_id, lessor_id, lessee_id, tenant_name, business_name, term_months, rent)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $insert->execute([
            $propertyId, $property['lessor_id'], $lessee['id'],
            $lessee['full_name'], $businessName, $termMonths, $rent,
        ]);
    }
}

json_ok(['application_id' => (int) $pdo->lastInsertId()], 201);
