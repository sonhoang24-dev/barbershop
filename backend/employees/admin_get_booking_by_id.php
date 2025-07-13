<?php
require_once("../db.php");
header("Content-Type: application/json");

$id = $_GET['id'] ?? null;
if (!$id) {
    echo json_encode(['success' => false, 'message' => 'Thiếu ID lịch hẹn']);
    exit;
}

$sql = "
    SELECT
        b.*,
        u.name AS user_name,
        s.name AS service_name,
        e.full_name AS employee_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN services s ON b.service_id = s.id
    LEFT JOIN employees e ON b.employee_id = e.id
    WHERE b.id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Không tìm thấy lịch hẹn']);
    exit;
}

$row = $result->fetch_assoc();
$row['extras'] = json_decode($row['extras'], true); // parse JSON extras nếu có
echo json_encode(['success' => true, 'data' => $row]);
