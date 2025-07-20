<?php
require_once("../db.php");
header("Content-Type: application/json; charset=UTF-8");
error_reporting(0);
ini_set('display_errors', 0);

$sql = "
SELECT
    s.id,
    s.name AS title,
    s.description,
    s.price,
    s.created_at,
    IFNULL(AVG(r.rating), 0) AS rating
FROM services s
LEFT JOIN bookings b ON s.id = b.service_id
LEFT JOIN reviews r ON b.id = r.booking_id
WHERE s.status = 'Đang hoạt động'
GROUP BY s.id
ORDER BY s.created_at DESC;
";

$result = $conn->query($sql);
$services = [];

while ($row = $result->fetch_assoc()) {
    $serviceId = $row['id'];

    $imgQuery = "SELECT image FROM service_images WHERE service_id = $serviceId";
    $imgResult = $conn->query($imgQuery);
    $images = [];

    while ($imgRow = $imgResult->fetch_assoc()) {
        $imageData = $imgRow['image'];

        $base64 = base64_encode($imageData);
        $images[] = "data:image/jpeg;base64,$base64";
    }

    $services[] = [
        "id" => $serviceId,
        "title" => $row['title'],
        "description" => $row['description'],
        "price" => (int)$row['price'],
        "rating" => round((float)$row['rating'], 1),
        "images" => $images,
        "created_at" => $row['created_at'],
    ];
}

echo json_encode($services, JSON_UNESCAPED_UNICODE);
?>