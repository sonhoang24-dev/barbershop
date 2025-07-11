<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");

$data = json_decode(file_get_contents("php://input"), true);
$bookingId = intval($data['booking_id']);
$userId = intval($data['user_id']);
$rating = floatval($data['rating']);
$feedback = $data['feedback'] ?? '';

$stmt = $conn->prepare("INSERT INTO reviews (booking_id, user_id, rating, feedback) VALUES (?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE rating = VALUES(rating), feedback = VALUES(feedback)");
$stmt->bind_param("iids", $bookingId, $userId, $rating, $feedback);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}
