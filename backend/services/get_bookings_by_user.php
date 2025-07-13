<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once("../db.php");

if (!isset($_GET['user_id'])) {
    echo json_encode(["success" => false, "message" => "Thiếu user_id"]);
    exit;
}

$user_id = intval($_GET['user_id']);

$sql = "SELECT b.*,
               s.name AS service,
               e.full_name AS employee
        FROM bookings b
        LEFT JOIN services s ON b.service_id = s.id
        LEFT JOIN employees e ON b.employee_id = e.id
        WHERE b.user_id = ?
        ORDER BY b.created_at DESC";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Lỗi SQL: " . $conn->error]);
    exit;
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$bookings = [];
while ($row = $result->fetch_assoc()) {
    $row['extras'] = json_decode($row['extras'] ?? '[]', true);
    $bookings[] = $row;
}

echo json_encode(["success" => true, "data" => $bookings], JSON_UNESCAPED_UNICODE);
