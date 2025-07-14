<?php
require_once("../db.php");

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Lấy tham số lọc từ query string (nếu có)
$rating = $_GET['rating'] ?? null;
$service_id = $_GET['service_id'] ?? null;

// Câu SQL cơ bản
$sql = "
SELECT
  r.id AS review_id,
  u.name AS customer_name,
  u.phone AS customer_phone,
  s.name AS service_name,
  r.rating,
  r.feedback,
  r.reviewed_at
FROM reviews r
JOIN users u ON r.user_id = u.id
JOIN bookings b ON r.booking_id = b.id
JOIN services s ON b.service_id = s.id
WHERE 1=1
";

// Thêm điều kiện lọc nếu có
if (!empty($rating)) {
    $sql .= " AND r.rating = " . intval($rating);
}

if (!empty($service_id)) {
    $sql .= " AND s.id = " . intval($service_id);
}

// Chỉ thêm ORDER BY một lần
$sql .= " ORDER BY r.reviewed_at DESC";

// Thực thi truy vấn
$result = $conn->query($sql);

if (!$result) {
    echo json_encode([
        'success' => false,
        'message' => 'Lỗi SQL: ' . $conn->error,
        'sql' => $sql
    ]);
    exit;
}

// Lấy dữ liệu kết quả
$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

// Trả về JSON
echo json_encode([
    'success' => true,
    'data' => $data
]);
?>
