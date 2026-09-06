<?php

declare(strict_types=1);

// Включаем логирование, но НЕ выводим ошибки в HTML
error_reporting(E_ALL);
ini_set('display_errors', '0');  // <-- ВАЖНО: 0, а не 1
ini_set('display_startup_errors', '0');
ini_set('log_errors', '1');

// Заголовки
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');

// CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Allow-Credentials: true');
    http_response_code(204);
    exit;
}

// Подключаем необходимые файлы
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/http.php';
require_once __DIR__ . '/auth.php';

// Глобальный обработчик ошибок
set_exception_handler(static function (Throwable $exception): void {
    // Всегда логируем
    error_log(sprintf(
        '[ERROR] %s in %s:%d',
        $exception->getMessage(),
        $exception->getFile(),
        $exception->getLine()
    ));
    error_log($exception->getTraceAsString());

    if ($exception instanceof ApiException) {
        json_response([
            'ok' => false,
            'error' => [
                'message' => $exception->getMessage(),
                'details' => $exception->details(),
            ],
        ], $exception->statusCode());
    }

    // Отдаем JSON с ошибкой, а не HTML
    json_response([
        'ok' => false,
        'error' => [
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
        ],
    ], 500);
});

// Обработка фатальных ошибок
register_shutdown_function(function (): void {
    $error = error_get_last();
    if ($error !== null && in_array($error['type'], [E_ERROR, E_PARSE, E_COMPILE_ERROR], true)) {
        error_log(sprintf(
            '[FATAL] %s in %s:%d',
            $error['message'],
            $error['file'],
            $error['line']
        ));
        
        // ВАЖНО: отдаем JSON, а не HTML
        json_response([
            'ok' => false,
            'error' => [
                'message' => $error['message'],
                'file' => $error['file'],
                'line' => $error['line'],
            ],
        ], 500);
    }
});