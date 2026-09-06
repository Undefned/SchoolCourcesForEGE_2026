<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$pdo = Database::connection();

// =============================================
// GET - Получить историю чата
// =============================================
if ($method === 'GET') {
    $user = get_session_user();
    $userId = $user ? $user['id'] : null;
    
    $stmt = $pdo->prepare('
        SELECT 
            sm.*,
            u.full_name as user_name,
            u.avatar_url as user_avatar,
            su.full_name as support_name,
            su.avatar_url as support_avatar
        FROM support_messages sm
        LEFT JOIN users u ON u.id = sm.user_id
        LEFT JOIN users su ON su.id = sm.support_user_id
        WHERE 
            (sm.user_id = :userId OR sm.user_id IS NULL)
            AND sm.created_at > NOW() - INTERVAL \'7 days\'
        ORDER BY sm.created_at ASC
        LIMIT 100
    ');
    
    $stmt->execute(['userId' => $userId]);
    $messages = $stmt->fetchAll();
    
    // Помечаем сообщения как прочитанные
    if ($userId) {
        $pdo->prepare('
            UPDATE support_messages 
            SET is_read = TRUE, read_at = NOW()
            WHERE user_id = :userId AND is_from_support = TRUE AND is_read = FALSE
        ')->execute(['userId' => $userId]);
    }
    
    json_success($messages);
}

// =============================================
// POST - Отправить сообщение
// =============================================
if ($method === 'POST') {
    $body = read_json_body();
    $message = required_string($body, 'message');
    
    $user = get_session_user();
    $userId = $user ? (int)$user['id'] : null;
    
    // Находим сотрудника поддержки (если есть)
    $supportStmt = $pdo->prepare('
        SELECT id FROM users 
        WHERE is_support = TRUE AND is_active = TRUE 
        LIMIT 1
    ');
    $supportStmt->execute();
    $support = $supportStmt->fetch();
    
    $stmt = $pdo->prepare('
        INSERT INTO support_messages (user_id, support_user_id, message, is_from_support)
        VALUES (:userId, :supportId, :message, FALSE)
        RETURNING id, created_at
    ');
    
    $stmt->execute([
        'userId' => $userId,
        'supportId' => $support ? $support['id'] : null,
        'message' => $message,
    ]);
    
    $result = $stmt->fetch();
    
    json_success([
        'id' => (int)$result['id'],
        'created_at' => $result['created_at'],
    ], 201);
}

require_method('GET', 'POST');