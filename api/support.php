<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if (!in_array($method, ['GET', 'POST'], true)) {
    header('Allow: GET, POST');
    json_error_response('Метод не поддерживается', 405);
}

$pdo = Database::connection();

// =============================================
// GET — история чата
// =============================================
if ($method === 'GET') {
    $user = get_session_user();
    $userId = $user ? (int)$user['id'] : null;

    if ($userId !== null) {
        $stmt = $pdo->prepare('
            SELECT 
                sm.*,
                u.full_name AS user_name,
                u.avatar_url AS user_avatar,
                su.full_name AS support_name,
                su.avatar_url AS support_avatar
            FROM support_messages sm
            LEFT JOIN users u ON u.id = sm.user_id
            LEFT JOIN users su ON su.id = sm.support_user_id
            WHERE sm.user_id = :userId
              AND sm.created_at > NOW() - INTERVAL \'7 days\'
            ORDER BY sm.created_at ASC
            LIMIT 100
        ');
        $stmt->execute(['userId' => $userId]);
    } else {
        // Анонимный — отдаём только сообщения без user_id (общий поток)
        $stmt = $pdo->prepare('
            SELECT 
                sm.*,
                su.full_name AS support_name,
                su.avatar_url AS support_avatar
            FROM support_messages sm
            LEFT JOIN users su ON su.id = sm.support_user_id
            WHERE sm.user_id IS NULL
              AND sm.created_at > NOW() - INTERVAL \'7 days\'
            ORDER BY sm.created_at ASC
            LIMIT 100
        ');
        $stmt->execute();
    }

    $messages = $stmt->fetchAll();

    // Помечаем входящие как прочитанные (без read_at — колонки нет в новой схеме)
    if ($userId !== null) {
        $pdo->prepare('
            UPDATE support_messages 
            SET is_read = TRUE
            WHERE user_id = :userId 
              AND is_from_support = TRUE 
              AND is_read = FALSE
        ')->execute(['userId' => $userId]);
    }

    json_success($messages);
}

// =============================================
// POST — отправить сообщение
// =============================================
$body = read_json_body();
$message = required_string($body, 'message');

$user = get_session_user();
$userId = $user ? (int)$user['id'] : null;

// Находим сотрудника поддержки
$supportStmt = $pdo->prepare('
    SELECT id FROM users 
    WHERE is_support = TRUE AND is_active = TRUE 
    LIMIT 1
');
$supportStmt->execute();
$support = $supportStmt->fetch();
$supportId = $support ? (int)$support['id'] : null;

$stmt = $pdo->prepare('
    INSERT INTO support_messages (user_id, support_user_id, message, is_from_support)
    VALUES (:userId, :supportId, :message, FALSE)
    RETURNING id, created_at, user_id, is_from_support, message
');

$stmt->execute([
    'userId'    => $userId,
    'supportId' => $supportId,
    'message'   => $message,
]);

$result = $stmt->fetch();

json_success([
    'id'             => (int)$result['id'],
    'created_at'     => $result['created_at'],
    'user_id'        => $result['user_id'],
    'is_from_support'=> (bool)$result['is_from_support'],
    'message'        => $result['message'],
], 201);