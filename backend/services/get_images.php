<?php
require '../db.php';

$service_id = $_GET['service_id'] ?? 0;

$sql = "SELECT * FROM service_images WHERE service_id = $service_id";
$result = $conn->query($sql);

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode($data);
?>
