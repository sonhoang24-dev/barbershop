<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require '../PHPMailer/src/Exception.php';
require '../PHPMailer/src/PHPMailer.php';
require '../PHPMailer/src/SMTP.php';
require_once('../db.php');

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$data = json_decode(file_get_contents("php://input"), true);
$email = $data['email'] ?? '';

if (empty($email)) {
    echo json_encode(["success" => false, "message" => "Vui lòng nhập email"]);
    exit;
}

// Kiểm tra tài khoản
$stmt = $conn->prepare("SELECT id, name FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

if (!$user) {
    echo json_encode(["success" => false, "message" => "Tài khoản không tồn tại"]);
    exit;
}

// Tạo mật khẩu mới
$newPassword = substr(str_shuffle('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'), 0, 8);
$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

// Cập nhật mật khẩu
$update = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
$update->bind_param("si", $hashedPassword, $user['id']);
$update->execute();

// Gửi email
$mail = new PHPMailer(true);
try {
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'barbershopdht.ct@gmail.com';
    $mail->Password = 'vlmk fnnd leyc pngg';
    $mail->SMTPSecure = 'tls';
    $mail->Port = 587;

    $mail->setFrom('barbershopdht.ct@gmail.com', 'Barbershop System');
    $mail->addAddress($email, $user['name']);
    $mail->isHTML(true);
    $mail->CharSet = 'UTF-8';
    $mail->Encoding = 'base64';
    $mail->Subject = 'Khôi phục mật khẩu - Barbershop';
    $mail->Body = "
        <p>Xin chào <strong>{$user['name']}</strong>,</p>
        <p>Mật khẩu mới của bạn là: <strong style='color:green'>{$newPassword}</strong></p>
        <p>Sau khi đăng nhập, vui lòng đổi mật khẩu.</p>
        <hr><p style='font-size:12px;color:gray'>Đây là email tự động, vui lòng không phản hồi.</p>
    ";

    $mail->send();
    echo json_encode(["success" => true, "message" => "Đã gửi mật khẩu mới đến email của bạn."]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Không thể gửi email. Lỗi: {$mail->ErrorInfo}"]);
}
?>
