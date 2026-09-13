<?php

declare(strict_types=1);

require_once __DIR__ . '/config.php';

final class Database
{
    private static ?PDO $pdo = null;

    public static function connection(): PDO
    {
        if (self::$pdo instanceof PDO) {
            return self::$pdo;
        }

        // Используем глобальные переменные из config.php
        global $db_host, $db_port, $db_name, $db_user, $db_pass, $db_schema;

        $dsn = sprintf(
            'pgsql:host=%s;port=%s;dbname=%s',
            $db_host,
            $db_port,
            $db_name
        );

        self::$pdo = new PDO($dsn, $db_user, $db_pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);

        // Все таблицы лежат в схеме $db_schema, а не в public
        if (!empty($db_schema)) {
            self::$pdo->exec(
                'SET search_path TO ' . self::quoteIdentifier($db_schema) . ', public'
            );
        }

        return self::$pdo;
    }

    public static function quoteIdentifier(string $identifier): string
    {
        return '"' . str_replace('"', '""', $identifier) . '"';
    }
}