<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once("../db.php");

$employeeId = isset($_GET['employee_id']) ? intval($_GET['employee_id']) : 0;
$date = isset($_GET['date']) ? $_GET['date'] : date("Y-m-d"); // nếu không truyền thì mặc định hôm nay

if ($employeeId <= 0) {
    echo json_encode(["error" => "Thiếu employee_id"]);
    exit;
}

// Lấy các khung giờ đã đặt cho nhân viên và ngày tương ứng (trừ trạng thái "Đã hủy")
$sql = "SELECT TIME_FORMAT(time, '%H:%i') as time_slot
        FROM bookings
        WHERE employee_id = ? AND date = ? AND status != ' '";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["error" => "SQL error", "details" => $conn->error]);
    exit;
}

$stmt->bind_param("is", $employeeId, $date);
$stmt->execute();
$result = $stmt->get_result();

$times = [];
while ($row = $result->fetch_assoc()) {
    $times[] = $row['time_slot'];
}

echo json_encode($times);
