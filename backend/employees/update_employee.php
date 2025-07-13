<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once("../db.php");

$data = json_decode(file_get_contents("php://input"), true);

$id = $data["id"] ?? 0;
$full_name = $data["full_name"] ?? '';
$working_hours = $data["working_hours"] ?? '';
$phone = $data["phone"] ?? '';
$service_ids = $data["service_ids"] ?? [];
$status = $data["status"] ?? 'Đang hoạt động';

if ($id <= 0 || $full_name === '' || $phone === '' || empty($service_ids)) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin cần thiết"]);
    exit;
}

if (!preg_match('/^\d{10}$/', $phone)) {
    echo json_encode(["success" => false, "message" => "Số điện thoại phải có đúng 10 chữ số"]);
    exit;
}

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("UPDATE employees SET full_name = ?, working_hours = ?, phone = ?, status = ? WHERE id = ?");
    $stmt->bind_param("ssssi", $full_name, $working_hours, $phone, $status, $id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        // Xóa các liên kết cũ
        $stmt = $conn->prepare("DELETE FROM employee_services WHERE employee_id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();

        // Thêm các liên kết mới
        $stmt = $conn->prepare("INSERT INTO employee_services (employee_id, service_id) VALUES (?, ?)");
        foreach ($service_ids as $service_id) {
            $stmt->bind_param("ii", $id, $service_id);
            $stmt->execute();
        }
    }

    $conn->commit();
    echo json_encode(["success" => true]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Lỗi khi cập nhật: " . $e->getMessage()]);
} finally {
    if (isset($stmt)) $stmt->close();
    $conn->close();
}
?>