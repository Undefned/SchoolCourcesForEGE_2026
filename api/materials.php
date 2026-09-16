<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('GET');

$pdo = Database::connection();
$user = get_session_user();
$userId = $user ? (int)$user['id'] : null;

// =============================================
// Параметры
// =============================================
$subjectSlug = $_GET['subject'] ?? null;
$type        = $_GET['type']    ?? null;
$search      = $_GET['search']  ?? null;
$limit       = min(max((int)($_GET['limit']  ?? 100), 1), 100);
$offset      = max((int)($_GET['offset'] ?? 0), 0);

// =============================================
// Базовый запрос
// =============================================
$sql = '
    SELECT
        m.id,
        m.subject_id,
        m.title,
        m.description,
        m.type,
        m.content,
        m.task_count,
        m.duration_minutes,
        m.sort_order,
        s.name       AS subject_name,
        s.slug       AS subject_slug,
        s.color_code AS color_code,
        mp.views_count,
        mp.last_viewed_at,
        CASE WHEN mp.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_viewed,
        (SELECT a.id FROM assignments a WHERE a.material_id = m.id LIMIT 1) AS assignment_id,
        CASE
            WHEN :userId IS NULL THEN FALSE
            ELSE EXISTS (
                SELECT 1 FROM assignment_submissions sub
                WHERE sub.assignment_id = (SELECT a.id FROM assignments a WHERE a.material_id = m.id LIMIT 1)
                  AND sub.user_id = :userId
                  AND sub.status = \'graded\'
            )
        END AS is_completed,
        (
            SELECT sub.score FROM assignment_submissions sub
            WHERE sub.assignment_id = (SELECT a.id FROM assignments a WHERE a.material_id = m.id LIMIT 1)
              AND sub.user_id = :userId
              AND sub.status = \'graded\'
            LIMIT 1
        ) AS user_score
    FROM materials m
    JOIN subjects s ON s.id = m.subject_id
    LEFT JOIN material_progress mp ON mp.material_id = m.id AND mp.user_id = :userId
    WHERE m.is_active = TRUE
';

$params = ['userId' => $userId];

if ($subjectSlug) {
    $sql .= ' AND s.slug = :subjectSlug';
    $params['subjectSlug'] = $subjectSlug;
}
if ($type) {
    $sql .= ' AND m.type = :type';
    $params['type'] = $type;
}
if ($search) {
    $sql .= ' AND (m.title ILIKE :search OR m.description ILIKE :search)';
    $params['search'] = "%{$search}%";
}

$sql .= ' ORDER BY s.sort_order ASC, m.sort_order ASC, m.id ASC LIMIT :limit OFFSET :offset';

$stmt = $pdo->prepare($sql);
foreach ($params as $k => $v) {
    if ($k === 'userId') {
        if ($v === null) {
            $stmt->bindValue(':' . $k, null, PDO::PARAM_NULL);
        } else {
            $stmt->bindValue(':' . $k, $v, PDO::PARAM_INT);
        }
    } else {
        $stmt->bindValue(':' . $k, $v);
    }
}
$stmt->bindValue(':limit',  $limit,  PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$materials = $stmt->fetchAll();

// =============================================
// Общее количество
// =============================================
$countSql = 'SELECT COUNT(*) AS total FROM materials m JOIN subjects s ON s.id = m.subject_id WHERE m.is_active = TRUE';
$countParams = [];
if ($subjectSlug) { $countSql .= ' AND s.slug = :subjectSlug'; $countParams['subjectSlug'] = $subjectSlug; }
if ($type)        { $countSql .= ' AND m.type = :type';        $countParams['type'] = $type; }
if ($search)      { $countSql .= ' AND (m.title ILIKE :search OR m.description ILIKE :search)'; $countParams['search'] = "%{$search}%"; }

$countStmt = $pdo->prepare($countSql);
$countStmt->execute($countParams);
$total = (int)$countStmt->fetchColumn();

// =============================================
// Общая статистика
// =============================================
$statsStmt = $pdo->prepare('
    SELECT
        (SELECT COUNT(*) FROM materials WHERE is_active = TRUE) AS total_materials,
        (SELECT COUNT(*) FROM subjects WHERE is_active = TRUE)  AS total_subjects,
        (
            SELECT COUNT(DISTINCT mp.material_id)
            FROM material_progress mp
            WHERE mp.user_id = :userId
        ) AS total_viewed
');
$statsStmt->execute(['userId' => $userId]);
$stats = $statsStmt->fetch();

json_success([
    'items' => $materials,
    'total' => $total,
    'stats' => [
        'total_materials' => (int)($stats['total_materials'] ?? 0),
        'total_subjects'  => (int)($stats['total_subjects']  ?? 0),
        'total_viewed'    => (int)($stats['total_viewed']    ?? 0),
    ],
    'offset' => $offset,
    'limit'  => $limit,
]);