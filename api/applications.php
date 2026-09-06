<?php

declare(strict_types=1);

require_once __DIR__ . '/lib/bootstrap.php';

require_method('POST');

$body = read_json_body();

$email = required_email($body, 'email');
$fullName = required_string($body, 'fullName');
$grade = required_grade($body, 'grade');

$subject = optional_string($body, 'subject');
$message = optional_string($body, 'message');
$source = optional_string($body, 'source') ?? 'landing';

$pdo = Database::connection();

// Проверяем, не отправлял ли уже сегодня
$stmt = $pdo->prepare('
    SELECT COUNT(*) FROM applications 
    WHERE email = :email AND created_at > NOW() - INTERVAL \'1 day\'
');
$stmt->execute(['email' => $email]);

if ((int)$stmt->fetchColumn() > 0) {
    json_error_response('Вы уже отправляли заявку сегодня', 429);
}

// Проверяем, есть ли пользователь с таким email
$userStmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
$userStmt->execute(['email' => $email]);
$user = $userStmt->fetch();

$stmt = $pdo->prepare('
    INSERT INTO applications (
        user_id, email, full_name, grade, subject_interest, message, source
    ) VALUES (
        :userId, :email, :fullName, :grade, :subject, :message, :source
    )
    RETURNING id, created_at
');

$stmt->execute([
    'userId' => $user ? $user['id'] : null,
    'email' => $email,
    'fullName' => $fullName,
    'grade' => $grade,
    'subject' => $subject,
    'message' => $message,
    'source' => $source,
]);

$result = $stmt->fetch();

json_success([
    'id' => (int)$result['id'],
    'created_at' => $result['created_at'],
], 201);