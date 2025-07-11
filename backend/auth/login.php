<?php
header("Content-Type: application/json; charset=UTF-8");

require_once("../db.php");

$data = json_decode(file_get_contents("php://input"), true);
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin"]);
    exit;
}

$stmt = $conn->prepare("SELECT id, name, email, password, role, phone, gender, avatar FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if (password_verify($password, $row['password'])) {
        echo json_encode([
            "success" => true,
            "user" => [
                "id" => $row['id'],
                "name" => $row['name'],
                "email" => $row['email'],
                "role" => $row['role'],
                "phone" => $row['phone'],
                "gender" => $row['gender'],
                "avatar" => $row['avatar']
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Sai mật khẩu"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Email không tồn tại"]);
}
?>
