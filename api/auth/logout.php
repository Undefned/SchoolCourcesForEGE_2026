<?php

declare(strict_types=1);

require_once __DIR__ . '/../lib/bootstrap.php';

require_method('POST');

$headers = getallheaders();
$token = $headers['Authorization'] ?? $_COOKIE['session_token'] ?? null;

if ($token) {
    if (str_starts_with($token, 'Bearer ')) {
        $token = substr($token, 7);
    }
    logout_session($token);
}

setcookie('session_token', '', time() - 3600, '/', '', false, true);

json_success(['message' => 'Выход выполнен']);