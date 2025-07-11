<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

// Kiểm tra phương thức
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    echo json_encode(["success" => false, "message" => "Chỉ hỗ trợ phương thức POST"]);
    exit;
}

// Lấy dữ liệu từ Flutter
$data = json_decode(file_get_contents("php://input"), true);
$email = trim($data["email"] ?? '');

if (empty($email)) {
    echo json_encode(["success" => false, "message" => "Vui lòng nhập email"]);
    exit;
}

// Kết nối CSDL
require_once("../db.php");

// Kiểm tra email có tồn tại không
$stmt = $conn->prepare("SELECT name, password FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    $to = $email;
    $subject = "Khôi phục mật khẩu - BarberShop App";
    $message = "Xin chào {$row['name']},\n\nMật khẩu của bạn là: {$row['password']}\n\nVui lòng đổi lại mật khẩu sau khi đăng nhập.";
    $headers = "From: no-reply@barbershop.com";

    if (mail($to, $subject, $message, $headers)) {
        echo json_encode(["success" => true, "message" => "Mật khẩu đã được gửi đến email của bạn"]);
    } else {
        echo json_encode(["success" => false, "message" => "Không thể gửi email. Hãy thử lại sau."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Email không tồn tại"]);
}

$conn->close();
