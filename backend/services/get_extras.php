<?php
require '../db.php';
$service_id = $_GET['service_id'];
$result = $conn->query("SELECT * FROM extra_services WHERE main_service_id = $service_id");
$data = [];
while ($r = $result->fetch_assoc()) $data[] = $r;
echo json_encode($data);
?>