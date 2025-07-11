<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

// Chỉ xử lý POST
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    echo json_encode(["success" => false, "message" => "Chỉ hỗ trợ POST"]);
    exit;
}

// Kết nối CSDL
require_once("../db.php");

// Nhận dữ liệu JSON
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

// Lấy và kiểm tra dữ liệu đầu vào
$name     = trim($data["name"] ?? '');
$email    = trim($data["email"] ?? '');
$password = trim($data["password"] ?? '');
$gender   = trim($data["gender"] ?? '');
$phone    = trim($data["phone"] ?? '');

if (!$name || !$email || !$password || !$gender || !$phone) {
    echo json_encode(["success" => false, "message" => "Vui lòng điền đầy đủ thông tin"]);
    exit;
}

// Kiểm tra email đã tồn tại chưa
$check = $conn->prepare("SELECT id FROM users WHERE email = ?");
$check->bind_param("s", $email);
$check->execute();
$check->store_result();

if ($check->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Email đã được sử dụng"]);
    exit;
}

// Mã hóa mật khẩu
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// Chèn dữ liệu người dùng mới
$stmt = $conn->prepare("INSERT INTO users (name, email, password, gender, phone, role) VALUES (?, ?, ?, ?, ?, 'customer')");
$stmt->bind_param("sssss", $name, $email, $hashedPassword, $gender, $phone);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Đăng ký thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi khi đăng ký"]);
}

$conn->close();
?>
