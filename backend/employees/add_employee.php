<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once("../db.php");

$data = json_decode(file_get_contents("php://input"), true);

$full_name = $data["full_name"] ?? '';
$working_hours = $data["working_hours"] ?? '';
$phone = $data["phone"] ?? '';
$service_ids = $data["service_ids"] ?? [];
$status = $data["status"] ?? 'Đang hoạt động';

if ($full_name === '' || $phone === '' || empty($service_ids)) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin cần thiết (họ tên, số điện thoại hoặc dịch vụ)"]);
    exit;
}

if (!preg_match('/^\d{10}$/', $phone)) {
    echo json_encode(["success" => false, "message" => "Số điện thoại phải có đúng 10 chữ số"]);
    exit;
}

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("INSERT INTO employees (full_name, working_hours, phone, status) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $full_name, $working_hours, $phone, $status);
    $stmt->execute();
    $employee_id = $conn->insert_id;

    if ($employee_id > 0) {
        $stmt = $conn->prepare("INSERT INTO employee_services (employee_id, service_id) VALUES (?, ?)");
        foreach ($service_ids as $service_id) {
            $stmt->bind_param("ii", $employee_id, $service_id);
            $stmt->execute();
        }
    }

    $conn->commit();
    echo json_encode(["success" => true, "id" => $employee_id]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Lỗi khi thêm: " . $e->getMessage()]);
} finally {
    if (isset($stmt)) $stmt->close();
    $conn->close();
}
?>