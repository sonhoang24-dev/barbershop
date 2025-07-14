<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require_once("../db.php");

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Kết nối database thất bại: ' . $conn->connect_error]));
}

// Lấy tham số từ yêu cầu
$name = isset($_GET['name']) ? trim($_GET['name']) : '';
$phone = isset($_GET['phone']) ? trim($_GET['phone']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : '';

// Xây dựng câu truy vấn SQL
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
";

// Thêm điều kiện WHERE nếu có tham số tìm kiếm/lọc
$conditions = [];
$params = [];
$types = '';

if (!empty($phone) && preg_match('/^\d{10}$/', $phone)) {
    // Nếu có số điện thoại hợp lệ (10 chữ số), tìm theo phone
    $conditions[] = "e.phone LIKE ?";
    $params[] = "%$phone%";
    $types .= 's';
} elseif (!empty($name)) {
    // Nếu không có số điện thoại, tìm theo tên
    $conditions[] = "e.full_name LIKE ?";
    $params[] = "%$name%";
    $types .= 's';
}

if (!empty($status)) {
    // Nếu có trạng thái, lọc theo status
    $conditions[] = "e.status = ?";
    $params[] = $status;
    $types .= 's';
}

// Thêm điều kiện vào câu truy vấn
if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

$sql .= " GROUP BY e.id ORDER BY e.id DESC";

// Chuẩn bị và thực thi câu truy vấn
$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Lỗi chuẩn bị truy vấn: ' . $conn->error]));
}

if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}

if (!$stmt->execute()) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Lỗi thực thi truy vấn: ' . $stmt->error]));
}

$result = $stmt->get_result();
$employees = [];
while ($row = $result->fetch_assoc()) {
    $row['service_names'] = $row['service_names'] ?? '';
    $employees[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'data' => $employees]);
?>