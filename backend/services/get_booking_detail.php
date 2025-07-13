<?php
require_once '../db.php';

$booking_id = $_GET['booking_id'] ?? 0;

// Prepare
$stmt = $conn->prepare("
  SELECT b.*,
         s.name AS service_title, s.price AS service_price,
         u.name AS customer_name, u.phone AS customer_phone,
         e.full_name AS employee_name
  FROM bookings b
  JOIN services s ON b.service_id = s.id
  JOIN users u ON b.user_id = u.id
  LEFT JOIN employees e ON b.employee_id = e.id
  WHERE b.id = ?
");

if (!$stmt) {
  die("Lỗi prepare: " . $conn->error);
}

$stmt->bind_param("i", $booking_id);
$stmt->execute();

$result = $stmt->get_result();
$data = $result->fetch_assoc();

if ($data) {
  echo json_encode(["success" => true, "data" => $data]);
} else {
  echo json_encode(["success" => false, "message" => "Không tìm thấy đơn hàng"]);
}
