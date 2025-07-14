<?php
require_once('../db.php');

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$start = $_GET['start_date'] ?? null;
$end = $_GET['end_date'] ?? null;

if (!$start || !$end) {
    echo json_encode(['success' => false, 'message' => 'Thiếu tham số start_date hoặc end_date']);
    exit;
}

ini_set('display_errors', 1);
error_reporting(E_ALL);

$sql1 = "
    SELECT COUNT(*) AS total_bookings, SUM(total) AS total_revenue
    FROM bookings
    WHERE date BETWEEN ? AND ? AND status = 'Đã hoàn thành'
";
$stmt1 = $conn->prepare($sql1);
if (!$stmt1) {
    echo json_encode(['success' => false, 'message' => 'Lỗi prepare sql1: ' . $conn->error]);
    exit;
}
$stmt1->bind_param("ss", $start, $end);
$stmt1->execute();
$result1 = $stmt1->get_result();
$data1 = $result1 ? $result1->fetch_assoc() : ['total_bookings' => 0, 'total_revenue' => 0];

// -------------------------
// 2. Tổng khách hàng mới
// -------------------------
$sql2 = "
    SELECT COUNT(*) AS total_customers
    FROM users
    WHERE DATE(created_at) BETWEEN ? AND ?
";
$stmt2 = $conn->prepare($sql2);
if (!$stmt2) {
    echo json_encode(['success' => false, 'message' => 'Lỗi prepare sql2: ' . $conn->error]);
    exit;
}
$stmt2->bind_param("ss", $start, $end);
$stmt2->execute();
$result2 = $stmt2->get_result();
$data2 = $result2 ? $result2->fetch_assoc() : ['total_customers' => 0];

$sql3 = "
    SELECT
        s.name,
        COUNT(b.id) AS count,
        ROUND(AVG(r.rating), 1) AS average_rating
    FROM bookings b
    JOIN services s ON b.service_id = s.id
    LEFT JOIN reviews r ON r.booking_id = b.id
    WHERE b.date BETWEEN ? AND ? AND b.status = 'Đã hoàn thành'
    GROUP BY s.id
    ORDER BY count DESC
    LIMIT 5
";
$stmt3 = $conn->prepare($sql3);
if (!$stmt3) {
    echo json_encode(['success' => false, 'message' => 'Lỗi prepare sql3: ' . $conn->error]);
    exit;
}
$stmt3->bind_param("ss", $start, $end);
$stmt3->execute();
$result3 = $stmt3->get_result();
if (!$result3) {
    echo json_encode(['success' => false, 'message' => 'Lỗi lấy dữ liệu dịch vụ: ' . $stmt3->error]);
    exit;
}

$topServices = [];
while ($row = $result3->fetch_assoc()) {
    $topServices[] = $row;
}

echo json_encode([
    'success' => true,
    'data' => [
        'total_bookings' => $data1['total_bookings'] ?? 0,
        'total_revenue' => $data1['total_revenue'] ?? 0,
        'total_customers' => $data2['total_customers'] ?? 0,
        'top_services' => $topServices
    ]
]);
