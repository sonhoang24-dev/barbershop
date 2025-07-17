<?php
require_once("../db.php");

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");

$id = isset($_POST['id']) ? intval($_POST['id']) : null;
$name = $_POST['name'] ?? '';
$description = $_POST['description'] ?? '';
$price = isset($_POST['price']) ? floatval($_POST['price']) : 0;
$status = $_POST['status'] ?? 'Đang hoạt động';
$extras = isset($_POST['extras']) ? json_decode($_POST['extras'], true) : [];
$deletedImages = isset($_POST['deleted_images']) ? json_decode($_POST['deleted_images'], true) : [];
$remainingImages = isset($_POST['remaining_images']) ? json_decode($_POST['remaining_images'], true) : [];

if ($id === null || empty($name) || $price <= 0) {
    echo json_encode(['success' => false, 'message' => 'ID, tên và giá phải hợp lệ']);
    exit;
}

$conn->begin_transaction();
try {
    // Update main service
    $stmt = $conn->prepare("UPDATE services SET name=?, description=?, price=?, status=? WHERE id=?");
    $stmt->bind_param("ssdsi", $name, $description, $price, $status, $id);
    $stmt->execute();

    // Delete old extra services
    $conn->query("DELETE FROM extra_services WHERE main_service_id = $id");

    // Add new extra services
    $stmtExtra = $conn->prepare("INSERT INTO extra_services (main_service_id, name, price) VALUES (?, ?, ?)");
    foreach ($extras as $extra) {
        $extraName = $extra['name'] ?? '';
        $extraPrice = floatval($extra['price'] ?? 0);
        if (!empty($extraName) && $extraPrice > 0) {
            $stmtExtra->bind_param("isd", $id, $extraName, $extraPrice);
            $stmtExtra->execute();
        }
    }

    // Xóa tất cả ảnh cũ
    $conn->query("DELETE FROM service_images WHERE service_id = $id");

    // Thêm lại các ảnh còn lại và ảnh mới
    $stmtImg = $conn->prepare("INSERT INTO service_images (service_id, image) VALUES (?, ?)");
    if (!empty($_FILES['images'])) {
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
    // Thêm lại các ảnh cũ còn lại (từ remainingImages)
    foreach ($remainingImages as $base64Image) {
        $binaryData = base64_decode($base64Image);
        if ($binaryData !== false) {
            $null = NULL;
            $stmtImg->bind_param("ib", $id, $null);
            $stmtImg->send_long_data(1, $binaryData);
            $stmtImg->execute();
        }
    }

    // Fetch updated images
    $stmtFetchImages = $conn->prepare("SELECT image FROM service_images WHERE service_id = ?");
    $stmtFetchImages->bind_param("i", $id);
    $stmtFetchImages->execute();
    $result = $stmtFetchImages->get_result();
    $images = [];
    while ($row = $result->fetch_assoc()) {
        $images[] = 'data:image/jpeg;base64,' . base64_encode($row['image']);
    }

    $conn->commit();
    echo json_encode([
        'success' => true,
        'message' => 'Cập nhật thành công',
        'images' => $images
    ]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Lỗi: ' . $e->getMessage()]);
}
?>