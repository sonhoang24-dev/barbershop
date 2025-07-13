<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once("../db.php");

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Kết nối database thất bại: ' . $conn->connect_error]));
}

$sql = "
    SELECT
        CAST(e.id AS UNSIGNED) AS id,
        e.full_name,
        e.working_hours,
        e.phone,
        GROUP_CONCAT(s.name SEPARATOR ', ') as service_names,
        e.status
    FROM employees e
    LEFT JOIN employee_services es ON e.id = es.employee_id
    LEFT JOIN services s ON es.service_id = s.id
    GROUP BY e.id
    ORDER BY e.id DESC
";

$result = $conn->query($sql);

if (!$result) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Lỗi truy vấn: ' . $conn->error]));
}

$employees = [];
while ($row = $result->fetch_assoc()) {
    $row['service_names'] = $row['service_names'] ?? '';
    $employees[] = $row;
}

echo json_encode(['success' => true, 'data' => $employees]);
?>