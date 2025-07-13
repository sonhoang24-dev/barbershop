<?php
require_once("../db.php");

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");

$id = isset($_POST['id']) ? intval($_POST['id']) : null;
$name = $_POST['name'] ?? '';
$description = $_POST['description'] ?? '';
$price = isset($_POST['price']) ? floatval($_POST['price']) : 0;
$extras = isset($_POST['extras']) ? json_decode($_POST['extras'], true) : [];

if ($id === null || empty($name) || $price <= 0) {
    echo json_encode(['success' => false, 'message' => 'ID, tên và giá phải hợp lệ']);
    exit;
}

$conn->begin_transaction();
try {
    $stmt = $conn->prepare("UPDATE services SET name=?, description=?, price=? WHERE id=?");
    $stmt->bind_param("ssdi", $name, $description, $price, $id);
    $stmt->execute();

    $conn->query("DELETE FROM extra_services WHERE main_service_id = $id");

    $stmtExtra = $conn->prepare("INSERT INTO extra_services (main_service_id, name, price) VALUES (?, ?, ?)");
    foreach ($extras as $extra) {
        $extraName = $extra['name'] ?? '';
        $extraPrice = floatval($extra['price'] ?? 0);
        if (!empty($extraName) && $extraPrice > 0) {
            $stmtExtra->bind_param("isd", $id, $extraName, $extraPrice);
            $stmtExtra->execute();
        }
    }

    if (!empty($_FILES['images'])) {
        $stmtImg = $conn->prepare("INSERT INTO service_images (service_id, image) VALUES (?, ?)");
        foreach ($_FILES['images']['tmp_name'] as $index => $tmpName) {
            if (is_uploaded_file($tmpName)) {
                $data = file_get_contents($tmpName);
                $null = NULL;
                $stmtImg->bind_param("ib", $id, $null);
                $stmtImg->send_long_data(1, $data);
                $stmtImg->execute();
            }
        }
    }

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Cập nhật thành công']);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Lỗi: ' . $e->getMessage()]);
}
?>