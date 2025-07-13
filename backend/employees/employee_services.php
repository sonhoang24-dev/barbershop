<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once("../db.php");

$employeeId = isset($_GET['id']) ? (int)$_GET['id'] : 0; // Lấy từ query parameter

if ($employeeId <= 0) {
    echo json_encode(["success" => false, "message" => "ID nhân viên không hợp lệ"]);
    exit;
}

try {
    $stmt = $conn->prepare("SELECT s.* FROM services s JOIN employee_services es ON s.id = es.service_id WHERE es.employee_id = ?");
    $stmt->bind_param("i", $employeeId);
    $stmt->execute();
    $result = $stmt->get_result();

    $services = [];
    while ($row = $result->fetch_assoc()) {
        $services[] = $row;
    }

    echo json_encode(["success" => true, "data" => $services]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Lỗi khi lấy dịch vụ: " . $e->getMessage()]);
} finally {
    if (isset($stmt)) $stmt->close();
    $conn->close();
}
?>