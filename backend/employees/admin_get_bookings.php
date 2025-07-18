<?php
require_once("../db.php");
header("Content-Type: application/json; charset=utf-8");
$conn->set_charset("utf8mb4");

$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : '';

error_log("Received search: $search, status: $status");

$sql = "
    SELECT
        b.id, b.date, b.time, b.status, b.total,
        b.customer_name, b.customer_phone, b.note,
        s.name AS service_name,
        u.name AS user_name,
        e.full_name AS employee_name,
        b.created_at AS created_at
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN services s ON b.service_id = s.id
    LEFT JOIN employees e ON b.employee_id = e.id
";

$conditions = [];
if (!empty($search)) {
    $search = $conn->real_escape_string($search);
    $conditions[] = "(b.customer_name LIKE '%$search%' OR b.customer_phone LIKE '%$search%')";
}
if (!empty($status)) {
    $status = $conn->real_escape_string(trim($status));
    $conditions[] = "b.status = '$status'";
}

if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

$sql .= " ORDER BY b.date DESC, b.time DESC";

error_log("SQL query: $sql");

$result = $conn->query($sql);

if (!$result) {
    error_log("Query error: " . $conn->error);
    echo json_encode(['success' => false, 'message' => 'Lỗi truy vấn: ' . $conn->error, 'sql' => $sql]);
    exit;
}

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

error_log("Response data: " . json_encode($data, JSON_UNESCAPED_UNICODE));
echo json_encode(['success' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
?>