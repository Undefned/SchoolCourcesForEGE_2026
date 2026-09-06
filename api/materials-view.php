<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('POST');

$user = require_auth();
$userId = (int)$user['id'];

$body = read_json_body();
$materialId = required_int($body, 'materialId');

$pdo = Database::connection();

// Проверяем, существует ли материал
$stmt = $pdo->prepare('SELECT id FROM materials WHERE id = :id AND is_active = TRUE');
$stmt->execute(['id' => $materialId]);

if (!$stmt->fetch()) {
    json_error_response('Материал не найден', 404);
}

// Увеличиваем счетчик просмотров
$stmt = $pdo->prepare('
    INSERT INTO material_progress (user_id, material_id, views_count, last_viewed_at)
    VALUES (:userId, :materialId, 1, NOW())
    ON CONFLICT (user_id, material_id) 
    DO UPDATE SET 
        views_count = material_progress.views_count + 1,
        last_viewed_at = NOW()
');

$stmt->execute([
    'userId' => $userId,
    'materialId' => $materialId,
]);

json_success(['message' => 'Просмотр зафиксирован']);