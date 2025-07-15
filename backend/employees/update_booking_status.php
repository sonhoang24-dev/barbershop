<?php
require_once("../db.php");
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

$conn->set_charset("utf8mb4");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Phương thức không hợp lệ, yêu cầu POST"]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
if (!isset($input['booking_id']) || !isset($input['status']) || !isset($input['user_id'])) {
    echo json_encode(["success" => false, "message" => "Thiếu booking_id, status hoặc user_id"]);
    exit;
}

$booking_id = intval($input['booking_id']);
$status = trim($input['status']);
$user_id = intval($input['user_id']);

$valid_statuses = ['Chờ xác nhận', 'Đã xác nhận', 'Đang thực hiện', 'Đã hoàn thành', 'Đã huỷ'];
if (!in_array($status, $valid_statuses)) {
    echo json_encode(["success" => false, "message" => "Trạng thái không hợp lệ"]);
    exit;
}

$sql = "UPDATE bookings SET status = ? WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    error_log("Prepare error: " . $conn->error);
    echo json_encode(["success" => false, "message" => "Lỗi SQL: " . $conn->error]);
    exit;
}

$stmt->bind_param("sii", $status, $booking_id, $user_id);
if (!$stmt->execute()) {
    error_log("Execute error: " . $stmt->error);
    echo json_encode(["success" => false, "message" => "Lỗi cập nhật trạng thái: " . $stmt->error]);
    exit;
}

if ($stmt->affected_rows === 0) {
    echo json_encode(["success" => false, "message" => "Không tìm thấy lịch hẹn hoặc không có quyền cập nhật"]);
    exit;
}

echo json_encode([
    "success" => true,
    "message" => "Cập nhật trạng thái thành công",
    "new_status" => $status
], JSON_UNESCAPED_UNICODE);
$stmt->close();
$conn->close();
?>