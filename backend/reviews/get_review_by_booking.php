<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['booking_id'])) {
    echo json_encode(["success" => false, "message" => "Thiếu booking_id"]);
    exit;
}

$bookingId = intval($_GET['booking_id']);
$sql = "SELECT rating, feedback FROM reviews WHERE booking_id = ? LIMIT 1";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Lỗi prepare: " . $conn->error]);
    exit;
}

$stmt->bind_param("i", $bookingId);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["success" => true, "data" => $row]);
} else {
    echo json_encode(["success" => false, "message" => "Không tìm thấy đánh giá"]);
}
