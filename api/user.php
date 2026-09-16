<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$user = require_auth();
$userId = (int)$user['id'];
$pdo = Database::connection();

// =============================================
// GET — профиль пользователя + статистика + активность
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

    if (!$userData) {
        json_error_response('Пользователь не найден', 404);
    }

    // =============================================
    // Считаем активные дни (простейший streak: 
    // количество уникальных дат, когда были graded-задания)
    // =============================================
    $streakStmt = $pdo->prepare('
        SELECT COUNT(DISTINCT DATE(submitted_at)) AS active_days
        FROM assignment_submissions
        WHERE user_id = :userId
          AND status = \'graded\'
          AND submitted_at IS NOT NULL
    ');
    $streakStmt->execute(['userId' => $userId]);
    $activeDays = (int)($streakStmt->fetchColumn() ?: 0);

    // =============================================
    // Активность за последние 7 дней (для графика)
    // =============================================
    $activityStmt = $pdo->prepare('
        SELECT
            d.day::date AS day,
            COALESCE(s.tasks, 0) AS tasks
        FROM (
            SELECT generate_series(
                CURRENT_DATE - INTERVAL \'6 days\',
                CURRENT_DATE,
                INTERVAL \'1 day\'
            ) AS day
        ) d
        LEFT JOIN (
            SELECT DATE(submitted_at) AS day, COUNT(*) AS tasks
            FROM assignment_submissions
            WHERE user_id = :userId
              AND status = \'graded\'
              AND submitted_at IS NOT NULL
              AND submitted_at >= CURRENT_DATE - INTERVAL \'6 days\'
            GROUP BY DATE(submitted_at)
        ) s ON s.day = d.day::date
        ORDER BY d.day
    ');
    $activityStmt->execute(['userId' => $userId]);
    $activity = $activityStmt->fetchAll();

    // Обновляем user_stats (streak, last_activity_date) — чтобы UI видел свежие данные
    $pdo->prepare('
        UPDATE user_stats
        SET streak_days = :streak,
            last_activity_date = (
                SELECT MAX(DATE(submitted_at))
                FROM assignment_submissions
                WHERE user_id = :userId AND status = \'graded\'
            ),
            updated_at = NOW()
        WHERE user_id = :userId
    ')->execute(['streak' => $activeDays, 'userId' => $userId]);

    // Подставляем свежие значения в ответ
    $userData['streak_days'] = $activeDays;

    // =============================================
    // Прогресс по предметам
    // progress = средний балл по graded-заданиям этого предмета
    // Если graded-заданий нет — 0
    // =============================================
    $progressStmt = $pdo->prepare('
        SELECT
            s.id,
            s.name,
            s.slug,
            s.color_code,
            s.icon,
            us.target_score,
            us.started_at,
            COALESCE((
                SELECT ROUND(AVG(sub.score))
                FROM assignment_submissions sub
                JOIN assignments a ON a.id = sub.assignment_id
                WHERE sub.user_id = us.user_id
                  AND a.subject_id = s.id
                  AND sub.status = \'graded\'
                  AND sub.score IS NOT NULL
            ), 0)::int AS progress
        FROM user_subjects us
        JOIN subjects s ON s.id = us.subject_id
        WHERE us.user_id = :userId
        ORDER BY s.sort_order
    ');
    $progressStmt->execute(['userId' => $userId]);
    $subjects = $progressStmt->fetchAll();

    // =============================================
    // Задания на ±30 дней
    // =============================================
    $assignStmt = $pdo->prepare('
        SELECT 
            a.id, a.title, a.due_date,
            s.name as subject_name,
            sub.status,
            sub.score
        FROM assignments a
        JOIN subjects s ON s.id = a.subject_id
        LEFT JOIN assignment_submissions sub ON sub.assignment_id = a.id AND sub.user_id = :userId
        WHERE a.due_date BETWEEN CURRENT_DATE - INTERVAL \'30 days\' AND CURRENT_DATE + INTERVAL \'30 days\'
        ORDER BY a.due_date ASC
        LIMIT 20
    ');
    $assignStmt->execute(['userId' => $userId]);
    $assignments = $assignStmt->fetchAll();

    json_success([
        'profile'     => $userData,
        'subjects'    => $subjects,
        'assignments' => $assignments,
        'activity'    => $activity,
    ]);
}

// =============================================
// PUT — обновить профиль
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