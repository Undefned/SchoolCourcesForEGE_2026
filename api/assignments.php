<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('GET');

$user = require_auth();
$userId = (int)$user['id'];

$subjectFilter = $_GET['subject'] ?? null;
$statusFilter = $_GET['status'] ?? null;
$sortBy = $_GET['sort'] ?? 'due_date'; // due_date, status, subject
$sortOrder = $_GET['order'] ?? 'ASC';

$pdo = Database::connection();

$sql = '
    SELECT 
        a.*,
        s.name as subject_name,
        s.slug as subject_slug,
        s.color_code,
        sub.status as submission_status,
        sub.score,
        sub.submitted_at,
        CASE 
            WHEN sub.id IS NOT NULL AND sub.status = \'graded\' THEN TRUE
            ELSE FALSE
        END as is_graded
    FROM assignments a
    JOIN subjects s ON s.id = a.subject_id
    LEFT JOIN assignment_submissions sub ON sub.assignment_id = a.id AND sub.user_id = :userId
    WHERE a.due_date >= CURRENT_DATE - INTERVAL \'7 days\'
';

$params = ['userId' => $userId];

if ($subjectFilter) {
    $sql .= ' AND s.slug = :subject';
    $params['subject'] = $subjectFilter;
}

if ($statusFilter) {
    $sql .= ' AND sub.status = :status';
    $params['status'] = $statusFilter;
}

// Сортировка
switch ($sortBy) {
    case 'subject':
        $sql .= ' ORDER BY s.name ' . ($sortOrder === 'DESC' ? 'DESC' : 'ASC');
        break;
    case 'status':
        $sql .= ' ORDER BY sub.status ' . ($sortOrder === 'DESC' ? 'DESC' : 'ASC');
        break;
    case 'due_date':
    default:
        $sql .= ' ORDER BY a.due_date ' . ($sortOrder === 'DESC' ? 'DESC' : 'ASC');
        break;
}

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$assignments = $stmt->fetchAll();

// Получаем список предметов для фильтра
$subjectsStmt = $pdo->query('
    SELECT slug, name 
    FROM subjects 
    WHERE is_active = TRUE 
    ORDER BY sort_order
');
$subjects = $subjectsStmt->fetchAll();

json_success([
    'items' => $assignments,
    'filters' => [
        'subjects' => $subjects,
        'statuses' => ['not_started', 'in_progress', 'submitted', 'graded'],
    ],
]);