<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");

// Base URL ảnh
$baseImageUrl = "http://10.0.2.2/barbershop/backend/uploads/";

// Truy vấn dịch vụ + rating trung bình
$sql = "
SELECT
    s.id,
    s.name AS title,
    s.description,
    s.price,
    ROUND(AVG(r.rating), 1) AS rating
FROM services s
LEFT JOIN bookings b ON s.id = b.service_id
LEFT JOIN reviews r ON b.id = r.booking_id
GROUP BY s.id
ORDER BY s.id DESC
";

$result = $conn->query($sql);

$services = [];

// Lấy ảnh dịch vụ trước để gom theo service_id
$imageSql = "SELECT service_id, image FROM service_images";
$imageResult = $conn->query($imageSql);

$imagesMap = [];

while ($img = $imageResult->fetch_assoc()) {
    $sid = $img['service_id'];
    if (!isset($imagesMap[$sid])) {
        $imagesMap[$sid] = [];
    }
    $imagesMap[$sid][] = $baseImageUrl . $img['image'];
}

// Duyệt qua dịch vụ
while ($row = $result->fetch_assoc()) {
    $sid = $row['id'];
    $services[] = [
        "id" => $row['id'],
        "title" => $row['title'],
        "description" => $row['description'],
        "price" => (int)$row['price'],
        "rating" => isset($row['rating']) ? (float)$row['rating'] : 0,
        "images" => $imagesMap[$sid] ?? [],
    ];
}

echo json_encode([
    "success" => true,
    "data" => $services
]);
?>
