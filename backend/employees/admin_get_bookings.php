<?php
require_once("../db.php");
header("Content-Type: application/json");

$sql = "
    SELECT
        b.id, b.date, b.time, b.status, b.total,
        b.customer_name, b.customer_phone, b.note,
        s.name AS service_name,
        u.name AS user_name,
        e.full_name AS employee_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN services s ON b.service_id = s.id
    LEFT JOIN employees e ON b.employee_id = e.id
    ORDER BY b.date DESC, b.time DESC
";

$result = $conn->query($sql);

if (!$result) {
    echo json_encode(['success' => false, 'message' => 'Lỗi truy vấn: ' . $conn->error]);
    exit;
}

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode(['success' => true, 'data' => $data]);
