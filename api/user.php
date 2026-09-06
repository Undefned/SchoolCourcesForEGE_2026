<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$user = require_auth();
$userId = (int)$user['id'];
$pdo = Database::connection();

// =============================================
// GET - Получить профиль пользователя
// =============================================
if ($method === 'GET') {
    // Основные данные
    $stmt = $pdo->prepare('
        SELECT 
            u.id, u.email, u.full_name, u.grade, u.avatar_url, u.created_at,
            us.total_lessons_attended,
            us.total_assignments_completed,
            us.avg_score,
            us.streak_days,
            us.last_activity_date
        FROM users u
        LEFT JOIN user_stats us ON us.user_id = u.id
        WHERE u.id = :userId
    ');
    $stmt->execute(['userId' => $userId]);
    $userData = $stmt->fetch();
    
    // Прогресс по предметам
    $progressStmt = $pdo->prepare('
        SELECT 
            s.id, s.name, s.slug, s.color_code, s.icon,
            us.progress,
            us.target_score,
            us.started_at
        FROM user_subjects us
        JOIN subjects s ON s.id = us.subject_id
        WHERE us.user_id = :userId
        ORDER BY s.sort_order
    ');
    $progressStmt->execute(['userId' => $userId]);
    $subjects = $progressStmt->fetchAll();
    
    // Задания на эту неделю
    $assignStmt = $pdo->prepare('
        SELECT 
            a.id, a.title, a.due_date,
            s.name as subject_name,
            sub.status,
            sub.score
        FROM assignments a
        JOIN subjects s ON s.id = a.subject_id
        LEFT JOIN assignment_submissions sub ON sub.assignment_id = a.id AND sub.user_id = :userId
        WHERE a.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL \'7 days\'
        ORDER BY a.due_date ASC
        LIMIT 10
    ');
    $assignStmt->execute(['userId' => $userId]);
    $assignments = $assignStmt->fetchAll();
    
    json_success([
        'profile' => $userData,
        'subjects' => $subjects,
        'assignments' => $assignments,
    ]);
}

// =============================================
// PUT - Обновить профиль
// =============================================
if ($method === 'PUT') {
    $body = read_json_body();
    
    $updates = [];
    $params = ['userId' => $userId];
    
    if (isset($body['fullName'])) {
        $updates[] = 'full_name = :fullName';
        $params['fullName'] = required_string($body, 'fullName');
    }
    
    if (isset($body['grade'])) {
        $updates[] = 'grade = :grade';
        $params['grade'] = required_grade($body, 'grade');
    }
    
    if (isset($body['avatarUrl'])) {
        $updates[] = 'avatar_url = :avatarUrl';
        $params['avatarUrl'] = optional_string($body, 'avatarUrl');
    }
    
    if (empty($updates)) {
        json_success(['message' => 'Нет данных для обновления']);
    }
    
    $sql = 'UPDATE users SET ' . implode(', ', $updates) . ', updated_at = NOW() WHERE id = :userId';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    json_success(['message' => 'Профиль обновлен']);
}

require_method('GET', 'PUT');