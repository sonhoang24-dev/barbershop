<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
require_once("../db.php");

$data = json_decode(file_get_contents("php://input"), true);

$id         = $data["id"] ?? null;
$name       = $data["name"] ?? "";
$email      = $data["email"] ?? "";
$phone      = $data["phone"] ?? "";
$gender     = $data["gender"] ?? null;
$newPass    = $data["newPassword"] ?? null;
$avatarBase64 = $data["avatarBase64"] ?? null;

if (!$id || empty($name) || empty($email)) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin bắt buộc"]);
    exit;
}

// Build SQL động
$sql = "UPDATE users SET name = ?, email = ?, phone = ?, gender = ?";
$params = [$name, $email, $phone, $gender];

// Mật khẩu mới
if (!empty($newPass)) {
    $sql .= ", password = ?";
    $params[] = password_hash($newPass, PASSWORD_DEFAULT);
}

// Avatar base64
if (!empty($avatarBase64)) {
    $sql .= ", avatar = ?";
    $params[] = $avatarBase64;
}

$sql .= " WHERE id = ?";
$params[] = $id;

$stmt = $conn->prepare($sql);
$stmt->bind_param(str_repeat("s", count($params) - 1) . "i", ...$params);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => "Cập nhật thất bại"]);
}