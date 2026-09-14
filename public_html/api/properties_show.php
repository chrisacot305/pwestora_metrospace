<?php
/**
 * GET /api/properties_show.php?id=123
 * Response: { "ok": true, "property": { id, name, type, address, lessor_name, photos: [urls] } }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$id = (int) ($_GET['id'] ?? 0);
if ($id <= 0) {
    json_error('Missing or invalid id.');
}

$stmt = $pdo->prepare(
    "SELECT p.id, p.name, p.type, p.address, p.latitude, p.longitude, p.asking_rent, u.company_name AS lessor_name
     FROM properties p
     JOIN users u ON u.id = p.lessor_id
     WHERE p.id = ? AND p.status = 'verified'
     LIMIT 1"
);
$stmt->execute([$id]);
$property = $stmt->fetch();

if (!$property) {
    json_error('Property not found or not yet verified.', 404);
}

$property['latitude'] = $property['latitude'] !== null ? (float) $property['latitude'] : null;
$property['longitude'] = $property['longitude'] !== null ? (float) $property['longitude'] : null;
$property['asking_rent'] = $property['asking_rent'] !== null ? (float) $property['asking_rent'] : null;

$photoStmt = $pdo->prepare('SELECT photo_path FROM property_photos WHERE property_id = ? ORDER BY id ASC');
$photoStmt->execute([$id]);
$photos = $photoStmt->fetchAll(PDO::FETCH_COLUMN);
$property['photos'] = array_map(fn($p) => APP_URL . '/' . $p, $photos);

// If logged in, report whether this lessee has already saved it — optional, no error if not logged in.
$property['saved'] = false;
$header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
    $userStmt = $pdo->prepare('SELECT id FROM users WHERE api_token = ? AND role = "lessee"');
    $userStmt->execute([$m[1]]);
    if ($user = $userStmt->fetch()) {
        $savedStmt = $pdo->prepare('SELECT id FROM saved_properties WHERE user_id = ? AND property_id = ?');
        $savedStmt->execute([$user['id'], $id]);
        $property['saved'] = (bool) $savedStmt->fetch();
    }
}

json_ok(['property' => $property]);
