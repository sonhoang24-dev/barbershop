<?php
require_once("../db.php");

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$sql = "
SELECT
    s.id,
    s.name AS title,
    s.description,
    s.price,
    s.status,
    IFNULL(AVG(r.rating), 0) AS rating
FROM services s
LEFT JOIN bookings b ON s.id = b.service_id
LEFT JOIN reviews r ON b.id = r.booking_id
GROUP BY s.id
ORDER BY s.id DESC
";

$res = $conn->query($sql);

// Lấy danh sách hình ảnh
$imageMap = [];
$imgRes = $conn->query("SELECT service_id, image FROM service_images");
while ($row = $imgRes->fetch_assoc()) {
    $sid = $row['service_id'];
    $imageData = base64_encode($row['image']);
    $imageMap[$sid][] = "data:image/jpeg;base64,$imageData";
}

$services = [];

while ($row = $res->fetch_assoc()) {
    $sid = $row['id'];

    // Lấy extra services
    $extras = [];
    $extraRes = $conn->query("SELECT id, name, price FROM extra_services WHERE main_service_id = $sid");
    while ($e = $extraRes->fetch_assoc()) {
        $extras[] = [
            "id" => $e['id'],
            "name" => $e['name'],
            "price" => (float)$e['price'],
        ];
    }

    $services[] = [
        "id" => $sid,
        "title" => $row['title'],
        "description" => $row['description'],
        "price" => (float)$row['price'],
        "status" => $row['status'],
        "rating" => round((float)$row['rating'], 1),
        "images" => $imageMap[$sid] ?? [],
        "extras" => $extras,
    ];
}

echo json_encode(['success' => true, 'data' => $services], JSON_UNESCAPED_UNICODE);
?>
