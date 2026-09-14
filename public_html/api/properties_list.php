<?php
/**
 * GET /api/properties_list.php
 * No auth required — anyone browsing the app can see verified listings.
 * If a Bearer token IS sent, each property also includes "saved": true|false.
 * Response: { "ok": true, "properties": [ { id, name, type, address, lessor_name, cover_photo, saved }, ... ] }
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$rows = $pdo->query(
    "SELECT p.id, p.name, p.type, p.address, p.latitude, p.longitude, p.asking_rent, u.company_name AS lessor_name,
            (SELECT pp.photo_path FROM property_photos pp WHERE pp.property_id = p.id ORDER BY pp.id ASC LIMIT 1) AS cover_photo
     FROM properties p
     JOIN users u ON u.id = p.lessor_id
     WHERE p.status = 'verified'
     ORDER BY p.created_at DESC"
)->fetchAll();

// If logged in, work out which of these are already saved — optional, no error if not logged in.
$savedIds = [];
$header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
    $userStmt = $pdo->prepare('SELECT id FROM users WHERE api_token = ? AND role = "lessee"');
    $userStmt->execute([$m[1]]);
    if ($user = $userStmt->fetch()) {
        $savedStmt = $pdo->prepare('SELECT property_id FROM saved_properties WHERE user_id = ?');
        $savedStmt->execute([$user['id']]);
        $savedIds = $savedStmt->fetchAll(PDO::FETCH_COLUMN);
    }
}

foreach ($rows as &$r) {
    $r['cover_photo'] = $r['cover_photo'] ? APP_URL . '/' . $r['cover_photo'] : null;
    $r['latitude'] = $r['latitude'] !== null ? (float) $r['latitude'] : null;
    $r['longitude'] = $r['longitude'] !== null ? (float) $r['longitude'] : null;
    $r['asking_rent'] = $r['asking_rent'] !== null ? (float) $r['asking_rent'] : null;
    $r['saved'] = in_array($r['id'], $savedIds, true);
}

json_ok(['properties' => $rows]);
