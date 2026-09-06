<?php

declare(strict_types=1);

require_once __DIR__ . '/../lib/bootstrap.php';

require_method('POST');

$body = read_json_body();

$email = required_email($body, 'email');
$password = required_string($body, 'password');

$pdo = Database::connection();

$stmt = $pdo->prepare('
    SELECT * FROM users 
    WHERE email = :email AND is_active = TRUE
    LIMIT 1
');
$stmt->execute(['email' => $email]);
$user = $stmt->fetch();

if (!$user || !verify_password($password, $user['password_hash'])) {
    json_error_response('Неверный email или пароль', 401);
}

// Создаем сессию
$token = create_session((int)$user['id']);

// Обновляем время последнего входа
$pdo->prepare('UPDATE users SET last_login = NOW() WHERE id = :id')
    ->execute(['id' => $user['id']]);

// Убираем пароль из ответа
unset($user['password_hash']);

global $session_lifetime;
setcookie('session_token', $token, time() + $session_lifetime, '/', '', false, true);

json_success([
    'user' => $user,
    'token' => $token,
]);