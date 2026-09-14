<?php
/**
 * GET /api/checklist_items.php
 * No auth required — shown before/during registration.
 * Response: { "ok": true, "items": [ { key, label, text }, ... ] }
 */
require __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../includes/lease_checklist.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('Use GET.', 405);
}

$items = [];
foreach ($LEASE_CHECKLIST_ITEMS as $key => $item) {
    $items[] = ['key' => $key, 'label' => $item['label'], 'text' => $item['text']];
}

json_ok(['items' => $items]);
