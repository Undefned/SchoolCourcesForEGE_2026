<?php

declare(strict_types=1);

require_once __DIR__ . '/../lib/bootstrap.php';

require_method('POST');

$body = read_json_body();

$email    = required_email($body, 'email');
$password = required_string($body, 'password');
$fullName = required_string($body, 'fullName');
$grade    = required_grade($body, 'grade');

// Проверяем длину пароля
if (strlen($password) < 6) {
    json_error_response('Пароль должен быть не менее 6 символов', 422);
}

$pdo = Database::connection();

// Проверяем, не занят ли email
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
$stmt->execute(['email' => $email]);

if ($stmt->fetch()) {
    json_error_response('Пользователь с таким email уже существует', 409);
}

// Создаём пользователя
$hash = hash_password($password);

$stmt = $pdo->prepare('
    INSERT INTO users (email, password_hash, full_name, grade)
    VALUES (:email, :hash, :name, :grade)
    RETURNING id, email, full_name, grade, created_at
');

$stmt->execute([
    'email' => $email,
    'hash'  => $hash,
    'name'  => $fullName,
    'grade' => $grade,
]);

$user = $stmt->fetch();
$newUserId = (int)$user['id'];

// =============================================
// 4A: автоматически подписываем на все активные предметы
// =============================================
$subjectsStmt = $pdo->query('SELECT id FROM subjects WHERE is_active = TRUE');
foreach ($subjectsStmt->fetchAll() as $subject) {
    $pdo->prepare('
        INSERT INTO user_subjects (user_id, subject_id, progress, target_score)
        VALUES (:uid, :sid, 0, 80)
        ON CONFLICT (user_id, subject_id) DO NOTHING
    ')->execute([
        'uid' => $newUserId,
        'sid' => (int)$subject['id'],
    ]);
}

// Создаём сессию
$token = create_session($newUserId);

global $session_lifetime;
setcookie('session_token', $token, time() + $session_lifetime, '/', '', false, true);

json_success([
    'user'  => $user,
    'token' => $token,
], 201);