<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('GET');

$pdo = Database::connection();
$user = get_session_user();
$userId = $user ? $user['id'] : null;

// Параметры фильтрации
$subjectSlug = $_GET['subject'] ?? null;
$type = $_GET['type'] ?? null;
$search = $_GET['search'] ?? null;
$limit = min((int)($_GET['limit'] ?? 100), 100);
$offset = max((int)($_GET['offset'] ?? 0), 0);

// Базовый запрос
$sql = '
    SELECT 
        m.*,
        s.name as subject_name,
        s.slug as subject_slug,
        s.color_code,
        mp.views_count,
        mp.last_viewed_at,
        CASE WHEN mp.id IS NOT NULL THEN TRUE ELSE FALSE END as is_viewed
    FROM materials m
    JOIN subjects s ON s.id = m.subject_id
    LEFT JOIN material_progress mp ON mp.material_id = m.id AND mp.user_id = :userId
    WHERE m.is_active = TRUE
';

$params = ['userId' => $userId];

// Фильтры
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

$sql .= ' ORDER BY m.sort_order ASC, m.id ASC LIMIT :limit OFFSET :offset';

$stmt->bindValue(':userId', $userId, PDO::PARAM_INT);
$stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

foreach ($params as $key => $value) {
    if ($key !== 'userId' && $key !== 'limit' && $key !== 'offset') {
        $stmt->bindValue(':' . $key, $value);
    }
}

$stmt->execute();
$materials = $stmt->fetchAll();

// Получаем общее количество
$countSql = str_replace(
    'SELECT m.*, s.name as subject_name, s.slug as subject_slug, s.color_code, mp.views_count, mp.last_viewed_at, CASE WHEN mp.id IS NOT NULL THEN TRUE ELSE FALSE END as is_viewed',
    'SELECT COUNT(*) as total',
    $sql
);
$countStmt = $pdo->prepare($countSql);
$countParams = $params;
unset($countParams['limit'], $countParams['offset']);
foreach ($countParams as $key => $value) {
    $countStmt->bindValue($key, $value);
}
$countStmt->execute();
$total = (int)$countStmt->fetchColumn();

// Подсчет статистики по материалам
$statsSql = '
    SELECT 
        COUNT(*) as total_materials,
        COUNT(DISTINCT subject_id) as total_subjects,
        COUNT(DISTINCT mp.user_id) as total_viewed
    FROM materials m
    LEFT JOIN material_progress mp ON mp.material_id = m.id AND mp.user_id = :userId
    WHERE m.is_active = TRUE
';
$statsStmt = $pdo->prepare($statsSql);
$statsStmt->execute(['userId' => $userId]);
$stats = $statsStmt->fetch();

json_success([
    'items' => $materials,
    'total' => $total,
    'stats' => [
        'total_materials' => (int)($stats['total_materials'] ?? 0),
        'total_subjects' => (int)($stats['total_subjects'] ?? 0),
        'total_viewed' => (int)($stats['total_viewed'] ?? 0),
    ],
    'offset' => $offset,
    'limit' => $limit,
]);