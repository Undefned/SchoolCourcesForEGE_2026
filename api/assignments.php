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
// GET — список заданий
// =============================================
if ($method === 'GET') {
    $user = require_auth();
    $userId = (int)$user['id'];

    $subjectFilter = $_GET['subject'] ?? null;
    $statusFilter  = $_GET['status']  ?? null;
    $sortBy        = $_GET['sort']    ?? 'due_date';
    $sortOrder     = strtoupper($_GET['order'] ?? 'ASC') === 'DESC' ? 'DESC' : 'ASC';

    $sql = '
        SELECT
            a.id,
            a.title,
            a.description,
            a.material_id,
            a.points_possible,
            a.due_date,
            s.name        AS subject_name,
            s.slug        AS subject_slug,
            s.color_code  AS color_code,
            sub.status    AS submission_status,
            sub.score     AS score,
            sub.submitted_at,
            sub.graded_at,
            CASE
                WHEN sub.status = \'graded\' THEN TRUE
                ELSE FALSE
            END AS is_graded
        FROM assignments a
        JOIN subjects s ON s.id = a.subject_id
        LEFT JOIN assignment_submissions sub
               ON sub.assignment_id = a.id AND sub.user_id = :userId
        WHERE a.due_date >= CURRENT_DATE - INTERVAL \'7 days\'
    ';

    $params = ['userId' => $userId];

    if ($subjectFilter) {
        $sql .= ' AND s.slug = :subject';
        $params['subject'] = $subjectFilter;
    }
    if ($statusFilter) {
        $sql .= ' AND COALESCE(sub.status, \'not_started\') = :status';
        $params['status'] = $statusFilter;
    }

    switch ($sortBy) {
        case 'subject':
            $sql .= " ORDER BY s.name $sortOrder";
            break;
        case 'status':
            $sql .= " ORDER BY COALESCE(sub.status, 'not_started') $sortOrder";
            break;
        case 'due_date':
        default:
            $sql .= " ORDER BY a.due_date $sortOrder";
            break;
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $assignments = $stmt->fetchAll();

    // Список предметов для фильтра
    $subjects = $pdo->query('
        SELECT slug, name
        FROM subjects
        WHERE is_active = TRUE
        ORDER BY sort_order
    ')->fetchAll();

    json_success([
        'items' => $assignments,
        'filters' => [
            'subjects' => $subjects,
            'statuses' => ['not_started', 'in_progress', 'submitted', 'graded'],
        ],
    ]);
}

// =============================================
// POST — начать / завершить задание
// body: { assignmentId?: int, materialId?: int, action?: 'start'|'complete' }
// =============================================
$user = require_auth();
$userId = (int)$user['id'];
$body = read_json_body();

$assignmentId = isset($body['assignmentId']) ? (int)$body['assignmentId'] : null;
$materialId   = isset($body['materialId'])   ? (int)$body['materialId']   : null;
$action       = $body['action'] ?? 'complete';

if (!in_array($action, ['start', 'complete'], true)) {
    json_error_response('action должен быть start или complete', 422);
}

if (!$assignmentId && !$materialId) {
    json_error_response('Нужен assignmentId или materialId', 422);
}

// ---- Резолвим assignmentId по materialId, при необходимости создаём assignment ----
if (!$assignmentId && $materialId) {
    // Есть ли материал?
    $stmt = $pdo->prepare('
        SELECT id, subject_id, title, description, duration_minutes
        FROM materials
        WHERE id = :mid AND is_active = TRUE
        LIMIT 1
    ');
    $stmt->execute(['mid' => $materialId]);
    $material = $stmt->fetch();

    if (!$material) {
        json_error_response('Материал не найден', 404);
    }

    // Ищем assignment по material_id
    $stmt = $pdo->prepare('SELECT id FROM assignments WHERE material_id = :mid LIMIT 1');
    $stmt->execute(['mid' => $materialId]);
    $row = $stmt->fetch();

    if ($row) {
        $assignmentId = (int)$row['id'];
    } else {
        // Вариант C: автоматически создаём assignment под этот материал
        $stmt = $pdo->prepare('
            INSERT INTO assignments (subject_id, title, description, material_id, points_possible, due_date)
            VALUES (:sid, :title, :descr, :mid, 100, CURRENT_DATE + INTERVAL \'30 days\')
            RETURNING id
        ');
        $stmt->execute([
            'sid'    => (int)$material['subject_id'],
            'title'  => $material['title'],
            'descr'  => $material['description'],
            'mid'    => $materialId,
        ]);
        $assignmentId = (int)$stmt->fetch()['id'];
    }
} else {
    // Проверяем, что assignment существует
    $stmt = $pdo->prepare('SELECT id FROM assignments WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $assignmentId]);
    if (!$stmt->fetch()) {
        json_error_response('Задание не найдено', 404);
    }
}

// =============================================
// action = start → статус in_progress (если ещё не graded)
// =============================================
if ($action === 'start') {
    $stmt = $pdo->prepare('
        INSERT INTO assignment_submissions (user_id, assignment_id, status)
        VALUES (:uid, :aid, \'in_progress\')
        ON CONFLICT (user_id, assignment_id) DO UPDATE
            SET status = CASE
                WHEN assignment_submissions.status = \'graded\' THEN \'graded\'
                ELSE \'in_progress\'
            END
        RETURNING id, status, score, graded_at
    ');
    $stmt->execute(['uid' => $userId, 'aid' => $assignmentId]);
    $row = $stmt->fetch();

    json_success([
        'assignmentId' => $assignmentId,
        'status'       => $row['status'],
        'score'        => $row['score'] !== null ? (int)$row['score'] : null,
        'gradedAt'     => $row['graded_at'],
    ]);
}

// =============================================
// action = complete → graded + случайный балл (60..100)
// ВАЖНО: балл — не сумма, а одно значение. Средний балл пользователя
// считается триггером update_user_stats как AVG(score) по graded.
// =============================================
$score = random_int(60, 100);

$stmt = $pdo->prepare('
    INSERT INTO assignment_submissions (
        user_id, assignment_id, status, score, submitted_at, graded_at
    ) VALUES (
        :uid, :aid, \'graded\', :score, NOW(), NOW()
    )
    ON CONFLICT (user_id, assignment_id) DO UPDATE
        SET status       = \'graded\',
            score        = EXCLUDED.score,
            submitted_at = NOW(),
            graded_at    = NOW()
    RETURNING id, status, score, graded_at
');
$stmt->execute([
    'uid'   => $userId,
    'aid'   => $assignmentId,
    'score' => $score,
]);
$row = $stmt->fetch();

// Пересчитываем stats (на случай, если триггер не сработал)
$pdo->prepare('
    INSERT INTO user_stats (user_id, total_lessons_attended, total_assignments_completed, avg_score, updated_at)
    VALUES (
        :uid,
        (SELECT COUNT(*) FROM user_lessons WHERE user_id = :uid AND status = \'attended\'),
        (SELECT COUNT(*) FROM assignment_submissions WHERE user_id = :uid AND status = \'graded\'),
        COALESCE((SELECT AVG(score) FROM assignment_submissions WHERE user_id = :uid AND status = \'graded\'), 0),
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_lessons_attended      = EXCLUDED.total_lessons_attended,
        total_assignments_completed = EXCLUDED.total_assignments_completed,
        avg_score                   = EXCLUDED.avg_score,
        updated_at                  = EXCLUDED.updated_at
')->execute(['uid' => $userId]);

// Забираем актуальный avg_score
$stmt = $pdo->prepare('SELECT avg_score, total_assignments_completed FROM user_stats WHERE user_id = :uid');
$stmt->execute(['uid' => $userId]);
$stats = $stmt->fetch();

json_success([
    'assignmentId'              => $assignmentId,
    'status'                    => $row['status'],
    'score'                     => (int)$row['score'],
    'gradedAt'                  => $row['graded_at'],
    'avgScore'                  => $stats ? round((float)$stats['avg_score'], 1) : (float)$score,
    'totalAssignmentsCompleted' => $stats ? (int)$stats['total_assignments_completed'] : 1,
], 201);