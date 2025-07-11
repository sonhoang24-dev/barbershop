<?php
require '../db.php';

$data = json_decode(file_get_contents("php://input"), true);
$extras = json_encode($data['extras'] ?? [], JSON_UNESCAPED_UNICODE);

// 🚨 Gán trước rồi mới kiểm tra
$user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;
if ($user_id <= 0) {
  echo json_encode(["success" => false, "message" => "Thiếu hoặc sai user_id"]);
  exit;
}

$date = date("Y-m-d");
$time = $data['time_slot'];
$extras = isset($data['extras']) ? json_encode($data['extras']) : json_encode([]);

$sql = "INSERT INTO bookings (
  user_id, service_id, employee_id, date, time, extras, total, customer_name, customer_phone, note
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);

if (!$stmt) {
  echo json_encode(["success" => false, "message" => "SQL error: " . $conn->error]);
  exit;
}

// Gán biến trước khi bind
$service_id = $data['service_id'];
$employee_id = $data['employee_id'];
$total = $data['total_price'];
$customer_name = $data['customer_name'];
$customer_phone = $data['customer_phone'];
$note = $data['note'];

$stmt->bind_param(
  "iiisssdsss",
  $user_id,
  $service_id,
  $employee_id,
  $date,
  $time,
  $extras,
  $total,
  $customer_name,
  $customer_phone,
  $note
);

if ($stmt->execute()) {
  echo json_encode(["success" => true]);
} else {
  echo json_encode(["success" => false, "message" => $stmt->error]);
}
?>
