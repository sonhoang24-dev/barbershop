<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");
$main_id = $_GET['main_service_id'] ?? 0;
$sql = "SELECT id, name, price FROM extra_services WHERE main_service_id = $main_id";
$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["success" => true, "data" => $data]);
