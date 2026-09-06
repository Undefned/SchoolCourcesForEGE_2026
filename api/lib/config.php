<?php

declare(strict_types=1);

// =============================================
// БАЗА ДАННЫХ
// =============================================
$db_host = getenv('PGHOST') ?: 'db';
$db_port = getenv('PGPORT') ?: '5432';
$db_name = getenv('PGDATABASE') ?: 'exametrika-db';
$db_user = getenv('PGUSER') ?: 'exametrika';
$db_pass = getenv('PGPASSWORD') ?: 'exametrika-big-pass';

// =============================================
// НАСТРОЙКИ СЕССИИ
// =============================================
$session_name = 'EXAMETRIKA_SESSION';
$session_lifetime = 86400;

// =============================================
// ПУТИ
// =============================================
$base_path = '/';
$api_base = '/api/';

// =============================================
// CORS
// =============================================
$allowed_origins = [
    'http://localhost:8080',
    'http://localhost:3000',
];