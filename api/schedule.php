<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('GET');

$user = require_auth();
$userId = (int)$user['id'];

$weekStart = $_GET['week'] ?? date('Y-m-d', strtotime('monday this week'));
$weekEnd = date('Y-m-d', strtotime($weekStart . ' +6 days'));

$pdo = Database::connection();

// Получаем занятия пользователя на эту неделю
$stmt = $pdo->prepare('
    SELECT 
        l.*,
        s.name as subject_name,
        s.slug as subject_slug,
        s.color_code,
        s.icon,
        ul.status as user_status,
        u.full_name as teacher_name
    FROM lessons l
    JOIN subjects s ON s.id = l.subject_id
    LEFT JOIN user_lessons ul ON ul.lesson_id = l.id AND ul.user_id = :userId
    LEFT JOIN users u ON u.id = l.teacher_id
    WHERE l.scheduled_at BETWEEN :weekStart AND :weekEnd
        AND l.is_cancelled = FALSE
    ORDER BY l.scheduled_at ASC
');

$stmt->execute([
    'userId' => $userId,
    'weekStart' => $weekStart . ' 00:00:00',
    'weekEnd' => $weekEnd . ' 23:59:59',
]);

$lessons = $stmt->fetchAll();

// Статистика на неделю
$statsStmt = $pdo->prepare('
    SELECT 
        COUNT(*) as total_lessons,
        SUM(l.duration_minutes) as total_hours,
        COUNT(ul.id) FILTER (WHERE ul.status = \'attended\') as completed
    FROM lessons l
    LEFT JOIN user_lessons ul ON ul.lesson_id = l.id AND ul.user_id = :userId
    WHERE l.scheduled_at BETWEEN :weekStart AND :weekEnd
        AND l.is_cancelled = FALSE
');

$statsStmt->execute([
    'userId' => $userId,
    'weekStart' => $weekStart . ' 00:00:00',
    'weekEnd' => $weekEnd . ' 23:59:59',
]);

$stats = $statsStmt->fetch();

json_success([
    'weekStart' => $weekStart,
    'weekEnd' => $weekEnd,
    'lessons' => $lessons,
    'stats' => [
        'total_lessons' => (int)($stats['total_lessons'] ?? 0),
        'total_hours' => (int)($stats['total_hours'] ?? 0),
        'completed' => (int)($stats['completed'] ?? 0),
    ],
]);