<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

$data = json_decode(file_get_contents('php://input'), true);
$lease_id = $data['lease_id'] ?? null;
$selected_terms = $data['selected_terms'] ?? []; // Array of checked checklist IDs

if (!$lease_id) {
    echo json_encode(['success' => false, 'message' => 'Lease ID required']);
    exit;
}

// Fetch Lease, Property, Lessor, and Lessee Info
$stmt = $pdo->prepare("SELECT l.*, p.name as property_name, p.address, p.asking_rent, 
                              u1.name as lessor_name, u2.name as lessee_name
                       FROM lease_requests l
                       JOIN properties p ON l.property_id = p.id
                       JOIN users u1 ON p.lessor_id = u1.id
                       JOIN users u2 ON l.lessee_id = u2.id
                       WHERE l.id = ?");
$stmt->execute([$lease_id]);
$details = $stmt->fetch(PDO::FETCH_ASSOC);

// Generate Contract Text dynamically based on selected terms
$contractHtml = "<h2>COMMERCIAL SPACE LEASE CONTRACT</h2>";
$contractHtml .= "<p><strong>LESSOR:</strong> {$details['lessor_name']}</p>";
$contractHtml .= "<p><strong>LESSEE:</strong> {$details['lessee_name']}</p>";
$contractHtml .= "<p><strong>PROPERTY:</strong> {$details['property_name']} ({$details['address']})</p>";
$contractHtml .= "<p><strong>RENTAL AMOUNT:</strong> ₱" . number_format($details['asking_rent']) . " / month</p>";
$contractHtml .= "<hr><h3>AGREED LEASE TERMS & CONDITIONS</h3><ul>";

foreach ($selected_terms as $term) {
    $contractHtml .= "<li>" . htmlspecialchars($term) . "</li>";
}
$contractHtml .= "</ul>";

// Update status to 'Contract Review'
$updateStmt = $pdo->prepare("UPDATE lease_requests SET status = 'Contract Review', contract_body = ? WHERE id = ?");
$updateStmt->execute([$contractHtml, $lease_id]);

echo json_encode([
    'success' => true,
    'contract' => $contractHtml,
    'status' => 'Contract Review'
]);