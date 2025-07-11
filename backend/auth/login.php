<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once("../db.php");

// Nhận dữ liệu từ client
$data = json_decode(file_get_contents("php://input"), true);
$email = trim($data["email"] ?? "");
$password = $data["password"] ?? "";

// Kiểm tra đầu vào
if (empty($email) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Thiếu email hoặc mật khẩu"]);
    exit;
}

// Truy vấn người dùng
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    // Kiểm tra mật khẩu
    if (password_verify($password, $user["password"])) {
        echo json_encode([
            "success" => true,
            "user" => [
                "id"     => (int)$user["id"],
                "name"   => $user["name"],
                "email"  => $user["email"],
                "phone"  => $user["phone"],
                "gender" => $user["gender"],
                "role"   => $user["role"],
                "avatar" => $user["avatar"] ?? ""
            ]
        ]);
        exit;
    }
}

// Mặc định trả về lỗi
echo json_encode(["success" => false, "message" => "Tài khoản hoặc mật khẩu sai"]);
