<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['service_id'])) {
    echo json_encode(["success" => false, "message" => "Thiếu service_id"]);
    exit;
}

$serviceId = intval($_GET['service_id']);

$sql = "SELECT r.rating, r.feedback, u.name AS name
        FROM reviews r
        JOIN bookings b ON r.booking_id = b.id
        JOIN users u ON r.user_id = u.id
        WHERE b.service_id = ?";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        "success" => false,
        "message" => "Lỗi prepare: " . $conn->error
    ]);
    exit;
}

$stmt->bind_param("i", $serviceId);
$stmt->execute();
$result = $stmt->get_result();

$reviews = [];
while ($row = $result->fetch_assoc()) {
    $reviews[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $reviews
]);
