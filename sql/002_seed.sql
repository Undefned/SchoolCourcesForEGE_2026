-- ============================================================
-- Exametrika — seed data
-- Run schema.sql first.
-- Images: пути вида '../../assets/...' (относительно pages/*.html)
-- ============================================================

BEGIN;

-- =============================================
-- 1. ПРЕДМЕТЫ
-- =============================================
INSERT INTO subjects (name, slug, color_code, icon, icon_url, sort_order) VALUES
    ('Математика',     'math',    '#8A15EA', '📐', NULL, 1),
    ('Русский язык',   'russian', '#75EA15', '📝', NULL, 2),
    ('Обществознание', 'social',  '#2B7FFF', '⚖️', NULL, 3),
    ('Физика',         'physics', '#F04438', '⚡', NULL, 4),
    ('История',        'history', '#F79009', '📜', NULL, 5),
    ('Биология',       'biology', '#12B76A', '🧬', NULL, 6);

-- =============================================
-- 2. ПОЛЬЗОВАТЕЛИ (пароль: 123456)
-- =============================================
INSERT INTO users (email, password_hash, full_name, grade, avatar_url, is_support) VALUES
    ('alex@ege.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Александр Волков', 11, '../../assets/Avatar.png', FALSE),

    ('support@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Анна Смирнова', NULL, '../../assets/men 1.png', TRUE),

    ('teacher.math@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Марина Иванова', NULL, '../../assets/Photo.png', FALSE),

    ('teacher.rus@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Лилия Петрова', NULL, '../../assets/image(1).png', FALSE),

    ('teacher.soc@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Сергей Волков', NULL, '../../assets/men 2.png', FALSE),

    ('teacher.phys@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Александр Сидоров', NULL, '../../assets/Avatar.png', FALSE);

-- =============================================
-- 3. МАТЕРИАЛЫ (контент прямо в БД)
-- =============================================
INSERT INTO materials (subject_id, title, description, type, content, cover_url, task_count, duration_minutes) VALUES
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Производная и её применение',
        'Подробный конспект с разбором всех типов задач на производную',
        'conspect',
        E'# Производная функции\n\n## Определение\nПроизводная функции — это предел отношения приращения функции к приращению аргумента...',
        '../../assets/image.png',
        24, 45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Тригонометрические уравнения',
        'Тест на проверку навыков решения тригонометрических уравнений',
        'test',
        E'Вопрос 1: Решите уравнение sin(x) = 0.5\nВарианты: а) π/6, б) π/3, в) π/4',
        '../../assets/image-1.png',
        15, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Геометрия: планиметрия. Часть 2',
        'Задания по планиметрии из второй части ЕГЭ',
        'task',
        'Задача 1. В треугольнике ABC ...',
        '../../assets/image-2.png',
        32, 45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Лексика и фразеология ЕГЭ',
        'Видеоурок по основным правилам лексики',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        '../../assets/image-3.png',
        14, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Алгоритм написания сочинения 27',
        'Пошаговый алгоритм для сочинения ЕГЭ по русскому',
        'conspect',
        E'# Структура сочинения ЕГЭ 27\n\n## Вступление (2-3 предложения)\n- Ввести в тему...',
        '../../assets/image.png',
        24, 45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Пунктуация: сложные случаи',
        'Тест по сложным случаям пунктуации',
        'test',
        'Вопрос 1. Обособленные определения...',
        '../../assets/image-1.png',
        20, 50
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Социальные нормы и институты',
        'Тест по обществознанию',
        'test',
        'Вопрос 1: Что такое социальный институт?\nВарианты: ...',
        '../../assets/image-2.png',
        22, 45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Правовая система РФ',
        'Конспект по правовой системе РФ',
        'conspect',
        E'# Правовая система РФ\n\n## Отрасли права...',
        '../../assets/image-3.png',
        22, 35
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Экономика: основные понятия',
        'Видео по основам экономики',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        '../../assets/image.png',
        10, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'physics'),
        'Механика: кинематика и динамика',
        'Конспект по механике',
        'conspect',
        E'# Механика\n\n## Кинематика\n- Равномерное движение: S = v*t\n- Равноускоренное движение: S = v0*t + at²/2',
        '../../assets/image-1.png',
        22, 25
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'physics'),
        'Электродинамика: законы',
        'Видео по электродинамике',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        '../../assets/image-2.png',
        12, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'physics'),
        'Термодинамика: задачи ЕГЭ',
        'Конспект с задачами по термодинамике',
        'conspect',
        E'# Термодинамика\n\n## Первое начало...',
        '../../assets/image-3.png',
        15, 35
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'history'),
        'Россия в XX веке: ключевые события',
        'Тест по истории России XX века',
        'test',
        'Вопрос 1: В каком году произошла революция?\nВарианты: 1905, 1917, 1921',
        '../../assets/image.png',
        22, 25
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'history'),
        'Исторические личности: таблица',
        'Видео-обзор ключевых личностей',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        '../../assets/image-1.png',
        12, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'history'),
        'Культура России: хронология',
        'Конспект по культуре России',
        'conspect',
        E'# Культура России\n\n## XIX век...',
        '../../assets/image-2.png',
        15, 35
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'biology'),
        'Клетка: строение и функции',
        'Тест по биологии',
        'test',
        'Вопрос 1: Что такое митохондрии?\nВарианты: ...',
        '../../assets/image-3.png',
        22, 35
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'biology'),
        'Генетика: законы Менделя + задачи',
        'Задания по генетике',
        'task',
        'Задача 1. Скрещивание гороха...',
        '../../assets/image.png',
        12, 30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'biology'),
        'Эволюция: теории и доказательства',
        'Видео по теории эволюции',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        '../../assets/image-1.png',
        10, 50
    );

-- =============================================
-- 4. ЗАНЯТИЯ (расписание)
-- =============================================
INSERT INTO lessons (subject_id, teacher_id, title, description, lesson_type, scheduled_at, duration_minutes, meeting_url) VALUES
    ((SELECT id FROM subjects WHERE slug = 'math'),
     (SELECT id FROM users WHERE email = 'teacher.math@exametrika.ru'),
     'Математика. Профиль', 'Производная и её применение',
     'webinar', '2026-09-07 10:00:00', 90, 'https://meet.google.com/abc-defg-hij'),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     (SELECT id FROM users WHERE email = 'teacher.phys@exametrika.ru'),
     'Физика. Механика', 'Кинематика и динамика',
     'webinar', '2026-09-08 12:00:00', 90, 'https://meet.google.com/phys-mech-001'),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     (SELECT id FROM users WHERE email = 'teacher.soc@exametrika.ru'),
     'Обществознание. Политика', 'Социальные нормы и институты',
     'webinar', '2026-09-09 14:00:00', 90, 'https://meet.google.com/xyz-uvwx-yza'),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     (SELECT id FROM users WHERE email = 'teacher.rus@exametrika.ru'),
     'Русский. Сочинение', 'Алгоритм написания сочинения 27',
     'webinar', '2026-09-10 16:00:00', 90, 'https://meet.google.com/rus-soch-001');

-- =============================================
-- 5. ЗАПИСЬ ПОЛЬЗОВАТЕЛЯ НА ЗАНЯТИЯ
-- ВАЖНО: этот блок триггерит update_user_stats() → создаёт user_stats для user_id=1
-- =============================================
INSERT INTO user_lessons (user_id, lesson_id, status) VALUES
    (1, (SELECT id FROM lessons WHERE title = 'Математика. Профиль'),  'attended'),
    (1, (SELECT id FROM lessons WHERE title = 'Физика. Механика'),     'attended'),
    (1, (SELECT id FROM lessons WHERE title = 'Обществознание. Политика'), 'scheduled'),
    (1, (SELECT id FROM lessons WHERE title = 'Русский. Сочинение'),    'scheduled');

-- =============================================
-- 6. ЗАДАНИЯ
-- =============================================
INSERT INTO assignments (subject_id, title, description, material_id, points_possible, due_date) VALUES
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Производная и её применение (Тест)',
        'Решить 10 задач на применение производной',
        (SELECT id FROM materials WHERE title = 'Производная и её применение'),
        100, '2026-09-07'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Сочинение по тексту Толстого',
        'Написать сочинение-рассуждение по тексту',
        (SELECT id FROM materials WHERE title = 'Алгоритм написания сочинения 27'),
        100, '2026-09-08'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Правовая система РФ (Конспект)',
        'Составить конспект по теме "Правовая система"',
        (SELECT id FROM materials WHERE title = 'Правовая система РФ'),
        100, '2026-09-25'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Практика: Геометрия 2 часть',
        'Решить задачи по геометрии из второй части ЕГЭ',
        (SELECT id FROM materials WHERE title = 'Геометрия: планиметрия. Часть 2'),
        100, '2026-09-28'
    );

-- =============================================
-- 7. ВЫПОЛНЕНИЕ ЗАДАНИЙ (демо для пользователя 1)
-- ВАЖНО: этот блок триггерит update_user_stats() → обновляет user_stats для user_id=1
-- =============================================
INSERT INTO assignment_submissions (user_id, assignment_id, status, score, submitted_at, graded_at) VALUES
    (1,
     (SELECT id FROM assignments WHERE title = 'Производная и её применение (Тест)'),
     'graded', 88, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),

    (1,
     (SELECT id FROM assignments WHERE title = 'Сочинение по тексту Толстого'),
     'graded', 92, NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days'),

    (1,
     (SELECT id FROM assignments WHERE title = 'Практика: Геометрия 2 часть'),
     'in_progress', NULL, NULL, NULL);

-- =============================================
-- 8. ПРОГРЕСС ПОЛЬЗОВАТЕЛЯ ПО ПРЕДМЕТАМ
-- =============================================
INSERT INTO user_subjects (user_id, subject_id, progress, target_score) VALUES
    (1, (SELECT id FROM subjects WHERE slug = 'math'),    82, 90),
    (1, (SELECT id FROM subjects WHERE slug = 'russian'), 94, 95),
    (1, (SELECT id FROM subjects WHERE slug = 'social'),  78, 85);

-- =============================================
-- 9. (УДАЛЕНО) INSERT INTO user_stats
-- user_stats пересчитывается автоматически триггером update_user_stats()
-- после INSERT'ов в user_lessons (блок 5) и assignment_submissions (блок 7).
-- Ручной INSERT приводит к duplicate key, потому что триггер уже создал строку.
-- =============================================

-- =============================================
-- 10. ПРОГРЕСС ПО МАТЕРИАЛАМ
-- =============================================
INSERT INTO material_progress (user_id, material_id, views_count, last_viewed_at) VALUES
    (1, (SELECT id FROM materials WHERE title = 'Производная и её применение'), 3, NOW() - INTERVAL '2 days'),
    (1, (SELECT id FROM materials WHERE title = 'Алгоритм написания сочинения 27'), 5, NOW() - INTERVAL '1 day'),
    (1, (SELECT id FROM materials WHERE title = 'Правовая система РФ'), 1, NOW() - INTERVAL '5 hours');

-- =============================================
-- 11. СООБЩЕНИЯ ПОДДЕРЖКИ
-- =============================================
INSERT INTO support_messages (user_id, support_user_id, message, is_from_support, is_read, created_at) VALUES
    (1, NULL, 'Здравствуйте! У меня проблема с загрузкой домашнего задания', FALSE, TRUE, NOW() - INTERVAL '1 hour'),
    (NULL, 2, 'Привет! Я Анна, ваш личный куратор. Чем могу помочь?',       TRUE,  FALSE, NOW() - INTERVAL '55 minutes'),
    (1, NULL, 'Не открывается файл с тестом по производной',                 FALSE, TRUE, NOW() - INTERVAL '50 minutes'),
    (NULL, 2, 'Попробуйте обновить страницу — мы уже починили. Если не поможет, напишите снова.', TRUE, FALSE, NOW() - INTERVAL '45 minutes');

-- =============================================
-- 12. ЗАЯВКИ
-- email теперь nullable, но нужен хотя бы email ИЛИ phone (CHECK constraint)
-- =============================================
INSERT INTO applications (user_id, email, phone, full_name, grade, subject_interest, message, source, status) VALUES
    (NULL, 'parent1@mail.ru', '+79001112233', 'Ирина Смирнова', 11, 'math',
     'Интересует подготовка к профильной математике, 11 класс', 'landing', 'new'),

    (NULL, 'parent2@mail.ru', '+79004445566', 'Ольга Кузнецова', 10, 'russian',
     'Нужна подготовка к сочинению', 'cta', 'contacted'),

    (1, 'alex@ege.ru', '+79007778899', 'Александр Волков', 11, 'social',
     'Хочу перейти на тариф с куратором', 'landing', 'processing');

COMMIT;