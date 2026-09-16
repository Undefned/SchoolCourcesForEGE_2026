<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('POST');

$body = read_json_body();

$email    = optional_string($body, 'email');     // теперь НЕобязателен
$fullName = required_string($body, 'fullName');
$grade    = required_grade($body, 'grade');
$phone    = optional_string($body, 'phone');
$subject  = optional_string($body, 'subject');
$message  = optional_string($body, 'message');
$source   = optional_string($body, 'source') ?? 'landing';

if ($email === null && $phone === null) {
    json_error_response('Нужно указать хотя бы email или телефон', 422);
}

$pdo = Database::connection();

// =============================================
// АНТИСПАМ: не чаще 1 раза в сутки
// =============================================
if ($email !== null) {
    $stmt = $pdo->prepare('
        SELECT COUNT(*) FROM applications 
        WHERE email = :email AND created_at > NOW() - INTERVAL \'1 day\'
    ');
    $stmt->execute(['email' => $email]);
    if ((int)$stmt->fetchColumn() > 0) {
        json_error_response('Вы уже отправляли заявку сегодня', 429);
    }
} elseif ($phone !== null) {
    $stmt = $pdo->prepare('
        SELECT COUNT(*) FROM applications 
        WHERE phone = :phone AND created_at > NOW() - INTERVAL \'1 day\'
    ');
    $stmt->execute(['phone' => $phone]);
    if ((int)$stmt->fetchColumn() > 0) {
        json_error_response('Вы уже отправляли заявку сегодня', 429);
    }
}

// =============================================
// СВЯЗЬ С ПОЛЬЗОВАТЕЛЕМ (если он есть)
// =============================================
$userId = null;
if ($email !== null) {
    $userStmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
    $userStmt->execute(['email' => $email]);
    $user = $userStmt->fetch();
    if ($user) $userId = (int)$user['id'];
}

// =============================================
// INSERT
// =============================================
$stmt = $pdo->prepare('
    INSERT INTO applications (
        user_id, email, phone, full_name, grade, subject_interest, message, source
    ) VALUES (
        :userId, :email, :phone, :fullName, :grade, :subject, :message, :source
    )
    RETURNING id, created_at
');

$stmt->execute([
    'userId'   => $userId,
    'email'    => $email,
    'phone'    => $phone,
    'fullName' => $fullName,
    'grade'    => $grade,
    'subject'  => $subject,
    'message'  => $message,
    'source'   => $source,
]);

$result = $stmt->fetch();

json_success([
    'id'         => (int)$result['id'],
    'created_at' => $result['created_at'],
], 201);