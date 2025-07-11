<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");
error_reporting(0); // Tắt warning để không phá JSON

$baseImageUrl = "http://10.0.2.2/barbershop/backend/uploads/";

// Truy vấn lấy dịch vụ + hình + đánh giá trung bình
$sql = "
SELECT
    s.id,
    s.name AS title,
    s.description,
    s.price,
    IFNULL(AVG(r.rating), 0) AS rating,
    si.image
FROM services s
LEFT JOIN service_images si ON s.id = si.service_id
LEFT JOIN bookings b ON s.id = b.service_id
LEFT JOIN reviews r ON b.id = r.booking_id
GROUP BY s.id, si.image
";

$result = $conn->query($sql);

$services = [];

while ($row = $result->fetch_assoc()) {
    $id = $row['id'];

    if (!isset($services[$id])) {
        $services[$id] = [
            "id" => $id,
            "title" => $row['title'],
            "description" => $row['description'],
            "price" => (int)$row['price'],
            "rating" => round((float)$row['rating'], 1),
            "images" => [],
        ];
    }

    if (!empty($row['image'])) {
        $services[$id]['images'][] = $baseImageUrl . $row['image'];
    }
}

echo json_encode(array_values($services), JSON_UNESCAPED_UNICODE);
?>
