<?php
$host = "localhost";
$user = "root";
$pass = "";
$db   = "barbershop";
$conn = new mysqli($host, $user, $pass, $db);

// Kiểm tra lỗi kết nối
if ($conn->connect_error) {
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode([
        "success" => false,
        "message" => "Kết nối CSDL thất bại: " . $conn->connect_error
    ]);
    exit;
}
$conn->set_charset("utf8");
