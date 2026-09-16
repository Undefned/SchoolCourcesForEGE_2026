<?php

declare(strict_types=1);

// =============================================
// ЛОГИ И ВЫВОД
// =============================================
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
ini_set('log_errors', '1');
ini_set('default_charset', 'UTF-8');

// Буферизируем весь вывод — чтобы никакой HTML/варнинг
// не попал в ответ до того, как мы отдадим JSON.
if (!ob_get_level()) {
    ob_start();
}

// =============================================
// ЗАГОЛОВКИ
// =============================================
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('X-Content-Type-Options: nosniff');

// =============================================
// CORS
// =============================================
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Allow-Credentials: true');
    http_response_code(204);
    exit;
}

// =============================================
// ПОДКЛЮЧЕНИЯ
// =============================================
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/http.php';
require_once __DIR__ . '/auth.php';

// =============================================
// ФУНКЦИЯ ОТДАЧИ ЧИСТОГО JSON
// =============================================
if (!function_exists('emit_json')) {
    function emit_json(array $payload, int $status = 200): void
    {
        // Чистим всё, что накопилось в буфере (варнинги, notice'ы и т.п.)
        while (ob_get_level() > 0) {
            ob_end_clean();
        }
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

// =============================================
// ГЛОБАЛЬНЫЙ ОБРАБОТЧИК ИСКЛЮЧЕНИЙ
// =============================================
set_exception_handler(static function (Throwable $exception): void {
    error_log(sprintf(
        '[ERROR] %s in %s:%d',
        $exception->getMessage(),
        $exception->getFile(),
        $exception->getLine()
    ));
    error_log($exception->getTraceAsString());

    if ($exception instanceof ApiException) {
        emit_json([
            'ok' => false,
            'error' => [
                'message' => $exception->getMessage(),
                'details' => $exception->details(),
            ],
        ], $exception->statusCode());
    }

    emit_json([
        'ok' => false,
        'error' => [
            'message' => $exception->getMessage(),
            'file' => basename($exception->getFile()),
            'line' => $exception->getLine(),
        ],
    ], 500);
});

// =============================================
// ОБРАБОТКА ФАТАЛЬНЫХ ОШИБОК
// =============================================
register_shutdown_function(function (): void {
    $error = error_get_last();
    if ($error === null) return;
    if (!in_array($error['type'], [E_ERROR, E_PARSE, E_COMPILE_ERROR], true)) return;

    error_log(sprintf(
        '[FATAL] %s in %s:%d',
        $error['message'],
        $error['file'],
        $error['line']
    ));

    emit_json([
        'ok' => false,
        'error' => [
            'message' => $error['message'],
            'file' => basename($error['file']),
            'line' => $error['line'],
        ],
    ], 500);
});