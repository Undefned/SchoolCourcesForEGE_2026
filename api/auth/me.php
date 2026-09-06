<?php

declare(strict_types=1);

require_once __DIR__ . '/../lib/bootstrap.php';

require_method('GET');

$user = require_auth();

// Получаем статистику
$pdo = Database::connection();

$stmt = $pdo->prepare('
    SELECT 
        us.*,
        (
            SELECT COUNT(*) 
            FROM user_subjects us2 
            WHERE us2.user_id = u.id
        ) as total_subjects
    FROM users u
    LEFT JOIN user_stats us ON us.user_id = u.id
    WHERE u.id = :userId
');
$stmt->execute(['userId' => $user['id']]);
$stats = $stmt->fetch();

unset($user['password_hash']);

json_success([
    'user' => $user,
    'stats' => $stats ?: [
        'total_lessons_attended' => 0,
        'total_assignments_completed' => 0,
        'avg_score' => 0,
        'streak_days' => 0,
        'total_subjects' => 0,
    ],
]);