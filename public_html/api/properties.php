<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $type = $_GET['type'] ?? null;
    $sql = 'SELECT p.id, p.name, p.type, p.address, p.latitude, p.longitude, p.asking_rent,
                  (SELECT photo_path FROM property_photos pp WHERE pp.property_id = p.id ORDER BY pp.id ASC LIMIT 1) AS cover_photo
           FROM properties p 
           WHERE p.status = "verified"';

    if ($type && $type !== 'All') {
        $sql .= ' AND p.type = :type';
    }

    $stmt = $pdo->prepare($sql);
    if ($type && $type !== 'All') {
        $stmt->bindValue(':type', $type);
    }
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}