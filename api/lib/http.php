<?php

declare(strict_types=1);

// =============================================
// БАЗОВЫЙ КЛАСС ИСКЛЮЧЕНИЯ ДЛЯ API
// =============================================
final class ApiException extends RuntimeException
{
    public function __construct(
        private readonly int $statusCode,
        string $message,
        private readonly array $details = [],
    ) {
        parent::__construct($message);
    }

    public function statusCode(): int
    {
        return $this->statusCode;
    }

    public function details(): array
    {
        return $this->details;
    }
}

// =============================================
// JSON ОТВЕТЫ
// =============================================
function json_response(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function json_success(array $data = []): never
{
    json_response(['ok' => true, 'data' => $data]);
}

function json_error(string $message, int $status = 400, array $details = []): never
{
    throw new ApiException($status, $message, $details);
}

function json_error_response(string $message, int $status = 400, array $details = []): never
{
    json_response([
        'ok' => false,
        'error' => [
            'message' => $message,
            'details' => $details,
        ],
    ], $status);
}

// =============================================
// HTTP МЕТОДЫ
// =============================================
function require_method(string ...$allowedMethods): void
{
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    
    if (!in_array($method, $allowedMethods, true)) {
        header('Allow: ' . implode(', ', $allowedMethods));
        json_error_response('Метод не поддерживается', 405);
    }
}

// =============================================
// ЧТЕНИЕ JSON ТЕЛА ЗАПРОСА
// =============================================
function read_json_body(): array
{
    $raw = file_get_contents('php://input');

    if ($raw === false || trim($raw) === '') {
        return [];
    }

    $data = json_decode($raw, true);

    if (!is_array($data)) {
        json_error_response('Некорректный JSON в теле запроса', 400);
    }

    return $data;
}

// =============================================
// ВАЛИДАЦИЯ
// =============================================
function required_string(array $data, string $key): string
{
    $value = trim((string)($data[$key] ?? ''));

    if ($value === '') {
        json_error_response("Поле {$key} обязательно", 422);
    }

    return $value;
}

function optional_string(array $data, string $key): ?string
{
    if (!array_key_exists($key, $data) || $data[$key] === null) {
        return null;
    }

    $value = trim((string)$data[$key]);
    return $value === '' ? null : $value;
}

function required_int(array $data, string $key, int $min = 1): int
{
    $value = parse_int_value($data[$key] ?? null);

    if ($value === null || $value < $min) {
        json_error_response("Поле {$key} должно быть числом не меньше {$min}", 422);
    }

    return $value;
}

function required_email(array $data, string $key): string
{
    $email = required_string($data, $key);
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_error_response("Поле {$key} должно быть корректным email", 422);
    }
    
    return $email;
}

function required_grade(array $data, string $key): int
{
    $grade = required_int($data, $key, 9);
    
    if ($grade > 11) {
        json_error_response("Класс должен быть от 9 до 11", 422);
    }
    
    return $grade;
}

function parse_int_value(mixed $value): ?int
{
    if (is_int($value)) {
        return $value;
    }

    if (!is_string($value) && !is_float($value)) {
        return null;
    }

    $value = trim((string)$value);

    if (!preg_match('/^-?\d+$/', $value)) {
        return null;
    }

    return (int)$value;
}

function parse_bool_value(mixed $value): bool
{
    if (is_bool($value)) {
        return $value;
    }

    $value = strtolower(trim((string)$value));
    return in_array($value, ['1', 'true', 'yes', 'on'], true);
}

// =============================================
// ДОПОЛНИТЕЛЬНЫЕ ХЕЛПЕРЫ
// =============================================

/**
 * Получить значение из GET параметра с валидацией
 */
function query_string(string $key, ?string $default = null): ?string
{
    if (!isset($_GET[$key]) || $_GET[$key] === '') {
        return $default;
    }
    
    return trim((string)$_GET[$key]);
}

function query_int(string $key, ?int $default = null): ?int
{
    if (!isset($_GET[$key]) || $_GET[$key] === '') {
        return $default;
    }

    $value = parse_int_value($_GET[$key]);

    if ($value === null) {
        json_error_response("Параметр {$key} должен быть числом", 422);
    }

    return $value;
}

function query_bool(string $key, bool $default = false): bool
{
    if (!isset($_GET[$key]) || $_GET[$key] === '') {
        return $default;
    }

    return parse_bool_value($_GET[$key]);
}

/**
 * Получить текущий URL без параметров
 */
function current_url(): string
{
    return (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http')
        . '://' . $_SERVER['HTTP_HOST']
        . $_SERVER['REQUEST_URI'];
}

/**
 * Получить IP адрес клиента
 */
function client_ip(): string
{
    $headers = [
        'HTTP_CLIENT_IP',
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_FORWARDED',
        'HTTP_X_CLUSTER_CLIENT_IP',
        'HTTP_FORWARDED_FOR',
        'HTTP_FORWARDED',
        'REMOTE_ADDR'
    ];
    
    foreach ($headers as $header) {
        if (isset($_SERVER[$header])) {
            $ips = explode(',', $_SERVER[$header]);
            $ip = trim($ips[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }
    
    return '0.0.0.0';
}

/**
 * Логирование ошибок API
 */
function log_api_error(Throwable $exception, array $context = []): void
{
    $log = [
        'timestamp' => date('Y-m-d H:i:s'),
        'message' => $exception->getMessage(),
        'file' => $exception->getFile(),
        'line' => $exception->getLine(),
        'code' => $exception->getCode(),
        'context' => $context,
    ];
    
    error_log(json_encode($log, JSON_UNESCAPED_UNICODE));
}