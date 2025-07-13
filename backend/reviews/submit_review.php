<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once("../db.php");

$data = json_decode(file_get_contents("php://input"));

if (!$data) {
    echo json_encode([
        "success" => false,
        "message" => "Không nhận được dữ liệu JSON hợp lệ"
    ]);
    exit;
}

if (!isset($data->booking_id, $data->user_id, $data->rating)) {
    echo json_encode([
        "success" => false,
        "message" => "Thiếu trường bắt buộc: booking_id, user_id hoặc rating"
    ]);
    exit;
}

$booking_id = $data->booking_id;
$user_id = $data->user_id;
$rating = $data->rating;
$feedback = isset($data->feedback) ? $data->feedback : "";

$sql = "INSERT INTO reviews (booking_id, user_id, rating, feedback)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE rating = VALUES(rating), feedback = VALUES(feedback)";

$stmt = $conn->prepare($sql);
$stmt->bind_param("iiis", $booking_id, $user_id, $rating, $feedback);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Gửi đánh giá thành công"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Lỗi SQL: " . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
