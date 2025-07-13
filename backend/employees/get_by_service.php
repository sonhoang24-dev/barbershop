<?php
require '../db.php';
$service_id = $_GET['service_id'];
$result = $conn->query("SELECT e.* FROM employees e JOIN employee_services es ON e.id = es.employee_id WHERE es.service_id = $service_id  AND e.status = 'Đang hoạt động'");
$data = [];
while ($r = $result->fetch_assoc()) $data[] = $r;
echo json_encode($data);
?>