<?php

declare(strict_types=1);

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/http.php';
require_once __DIR__ . '/config.php';

function hash_password(string $password): string
{
    return password_hash($password, PASSWORD_DEFAULT);
}

function verify_password(string $password, string $hash): bool
{
    return password_verify($password, $hash);
}

function create_session(int $userId): string
{
    global $session_lifetime;
    
    $pdo = Database::connection();
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', time() + $session_lifetime);
    
    // Удаляем старые сессии
    $pdo->prepare('DELETE FROM sessions WHERE expires_at < NOW()')->execute();
    
    // Создаем новую сессию
    $stmt = $pdo->prepare('
        INSERT INTO sessions (user_id, session_token, expires_at)
        VALUES (:userId, :token, :expiresAt)
    ');
    
    $stmt->execute([
        'userId'    => $userId,
        'token'     => $token,
        'expiresAt' => $expiresAt,
    ]);
    
    return $token;
}

function get_session_user(): ?array
{
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? $_COOKIE['session_token'] ?? null;
    
    if (!$token) {
        return null;
    }
    
    // Убираем "Bearer " если есть
    if (str_starts_with($token, 'Bearer ')) {
        $token = substr($token, 7);
    }
    
    $pdo = Database::connection();
    
    $stmt = $pdo->prepare('
        SELECT u.* 
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.session_token = :token 
            AND s.expires_at > NOW()
            AND u.is_active = TRUE
        LIMIT 1
    ');
    
    $stmt->execute(['token' => $token]);
    $user = $stmt->fetch();
    
    if (!$user) {
        return null;
    }
    
    return $user;
}

function get_current_user_id(): int
{
    $user = get_session_user();
    
    if (!$user) {
        json_error_response('Не авторизован', 401);
    }
    
    return (int)$user['id'];
}

function require_auth(): array
{
    $user = get_session_user();
    
    if (!$user) {
        json_error_response('Не авторизован', 401);
    }
    
    return $user;
}

function logout_session(string $token): void
{
    $pdo = Database::connection();
    $pdo->prepare('DELETE FROM sessions WHERE session_token = :token')
        ->execute(['token' => $token]);
}