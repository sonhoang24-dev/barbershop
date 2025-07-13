<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");
$data = json_decode(file_get_contents("php://input"), true);

$main_service_id = $data['main_service_id'] ?? 0;
$name = $data['name'] ?? '';
$price = $data['price'] ?? 0;

if (empty($name) || !$main_service_id) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO extra_services(main_service_id, name, price) VALUES (?, ?, ?)");
$stmt->bind_param("isd", $main_service_id, $name, $price);
$success = $stmt->execute();

echo json_encode(["success" => $success]);