-- ============================================================
-- Exametrika — seed data (под упрощённую схему)
-- Images: пути вида '../assets/...' (относительно pages/*.html)
-- ============================================================

BEGIN;

-- =============================================
-- 1. ПРЕДМЕТЫ
-- =============================================
INSERT INTO subjects (name, slug, color_code, icon, sort_order) VALUES
    ('Математика',     'math',    '#8A15EA', '📐', 1),
    ('Русский язык',   'russian', '#75EA15', '📝', 2),
    ('Обществознание', 'social',  '#2B7FFF', '⚖️', 3),
    ('Физика',         'physics', '#F04438', '⚡', 4),
    ('История',        'history', '#F79009', '📜', 5),
    ('Биология',       'biology', '#12B76A', '🧬', 6);

-- =============================================
-- 2. ПОЛЬЗОВАТЕЛИ (пароль: 123456)
-- =============================================
INSERT INTO users (email, password_hash, full_name, grade, avatar_url, is_support) VALUES
    ('alex@ege.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Александр Волков', 11, '../assets/Avatar.png', FALSE),

    ('support@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Анна Смирнова', NULL, '../assets/men 1.png', TRUE),

    ('teacher.math@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Марина Иванова', NULL, '../assets/Photo.png', FALSE),

    ('teacher.rus@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Лилия Петрова', NULL, '../assets/image(1).png', FALSE),

    ('teacher.soc@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Сергей Волков', NULL, '../assets/men 2.png', FALSE),

    ('teacher.phys@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Александр Сидоров', NULL, '../assets/Avatar.png', FALSE),

    ('teacher.hist@exametrika.ru',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'Дмитрий Козлов', NULL, '../assets/men 2.png', FALSE);

-- =============================================
-- 3. МАТЕРИАЛЫ
-- =============================================
INSERT INTO materials (subject_id, title, description, type, content, task_count, duration_minutes) VALUES
    ((SELECT id FROM subjects WHERE slug = 'math'),
     'Производная и её применение',
     'Подробный конспект с разбором всех типов задач на производную',
     'conspect',
     E'# Производная функции\n\n## Определение\nПроизводная функции — это предел отношения приращения функции к приращению аргумента...',
     24, 45),

    ((SELECT id FROM subjects WHERE slug = 'math'),
     'Тригонометрические уравнения',
     'Тест на проверку навыков решения тригонометрических уравнений',
     'test',
     E'Вопрос 1: Решите уравнение sin(x) = 0.5\nВарианты: а) π/6, б) π/3, в) π/4',
     15, 30),

    ((SELECT id FROM subjects WHERE slug = 'math'),
     'Геометрия: планиметрия. Часть 2',
     'Задания по планиметрии из второй части ЕГЭ',
     'task',
     'Задача 1. В треугольнике ABC ...',
     32, 45),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     'Лексика и фразеология ЕГЭ',
     'Видеоурок по основным правилам лексики',
     'video',
     'https://www.youtube.com/embed/dQw4w9WgXcQ',
     14, 30),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     'Алгоритм написания сочинения 27',
     'Пошаговый алгоритм для сочинения ЕГЭ по русскому',
     'conspect',
     E'# Структура сочинения ЕГЭ 27\n\n## Вступление (2-3 предложения)\n- Ввести в тему...',
     24, 45),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     'Пунктуация: сложные случаи',
     'Тест по сложным случаям пунктуации',
     'test',
     'Вопрос 1. Обособленные определения...',
     20, 50),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     'Социальные нормы и институты',
     'Тест по обществознанию',
     'test',
     'Вопрос 1: Что такое социальный институт?\nВарианты: ...',
     22, 45),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     'Правовая система РФ',
     'Конспект по правовой системе РФ',
     'conspect',
     E'# Правовая система РФ\n\n## Отрасли права...',
     22, 35),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     'Экономика: основные понятия',
     'Видео по основам экономики',
     'video',
     'https://www.youtube.com/embed/dQw4w9WgXcQ',
     10, 30),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     'Механика: кинематика и динамика',
     'Конспект по механике',
     'conspect',
     E'# Механика\n\n## Кинематика\n- Равномерное движение: S = v*t\n- Равноускоренное движение: S = v0*t + at²/2',
     22, 25),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     'Электродинамика: законы',
     'Видео по электродинамике',
     'video',
     'https://www.youtube.com/embed/dQw4w9WgXcQ',
     12, 30),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     'Термодинамика: задачи ЕГЭ',
     'Конспект с задачами по термодинамике',
     'conspect',
     E'# Термодинамика\n\n## Первое начало...',
     15, 35),

    ((SELECT id FROM subjects WHERE slug = 'history'),
     'Россия в XX веке: ключевые события',
     'Тест по истории России XX века',
     'test',
     'Вопрос 1: В каком году произошла революция?\nВарианты: 1905, 1917, 1921',
     22, 25),

    ((SELECT id FROM subjects WHERE slug = 'history'),
     'Исторические личности: таблица',
     'Видео-обзор ключевых личностей',
     'video',
     'https://www.youtube.com/embed/dQw4w9WgXcQ',
     12, 30),

    ((SELECT id FROM subjects WHERE slug = 'history'),
     'Культура России: хронология',
     'Конспект по культуре России',
     'conspect',
     E'# Культура России\n\n## XIX век...',
     15, 35),

    ((SELECT id FROM subjects WHERE slug = 'biology'),
     'Клетка: строение и функции',
     'Тест по биологии',
     'test',
     'Вопрос 1: Что такое митохондрии?\nВарианты: ...',
     22, 35),

    ((SELECT id FROM subjects WHERE slug = 'biology'),
     'Генетика: законы Менделя + задачи',
     'Задания по генетике',
     'task',
     'Задача 1. Скрещивание гороха...',
     12, 30),

    ((SELECT id FROM subjects WHERE slug = 'biology'),
     'Эволюция: теории и доказательства',
     'Видео по теории эволюции',
     'video',
     'https://www.youtube.com/embed/dQw4w9WgXcQ',
     10, 50);

-- =============================================
-- 4. ЗАНЯТИЯ
-- =============================================
INSERT INTO lessons (subject_id, teacher_id, title, description, lesson_type, scheduled_at, duration_minutes) VALUES
    ((SELECT id FROM subjects WHERE slug = 'math'),
     (SELECT id FROM users WHERE email = 'teacher.math@exametrika.ru'),
     'Математика. Профиль', 'Производная и её применение',
     'webinar', CURRENT_DATE + INTERVAL '1 day' + TIME '10:00', 90),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     (SELECT id FROM users WHERE email = 'teacher.phys@exametrika.ru'),
     'Физика. Механика', 'Кинематика и динамика',
     'webinar', CURRENT_DATE + INTERVAL '2 days' + TIME '12:00', 90),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     (SELECT id FROM users WHERE email = 'teacher.soc@exametrika.ru'),
     'Обществознание. Политика', 'Социальные нормы и институты',
     'webinar', CURRENT_DATE + INTERVAL '3 days' + TIME '14:00', 90),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     (SELECT id FROM users WHERE email = 'teacher.rus@exametrika.ru'),
     'Русский. Сочинение', 'Алгоритм написания сочинения 27',
     'webinar', CURRENT_DATE + INTERVAL '4 days' + TIME '16:00', 90),

    ((SELECT id FROM subjects WHERE slug = 'history'),
     (SELECT id FROM users WHERE email = 'teacher.hist@exametrika.ru'),
     'История. XX век', 'Россия в XX веке: ключевые события',
     'webinar', CURRENT_DATE - INTERVAL '1 day' + TIME '15:00', 90),

    ((SELECT id FROM subjects WHERE slug = 'math'),
     (SELECT id FROM users WHERE email = 'teacher.math@exametrika.ru'),
     'Математика. Практика', 'Разбор задач 2-й части',
     'practice', CURRENT_DATE - INTERVAL '2 days' + TIME '11:00', 120);

-- =============================================
-- 5. ЗАПИСЬ НА ЗАНЯТИЯ
-- =============================================
INSERT INTO user_lessons (user_id, lesson_id, status) VALUES
    (1, (SELECT id FROM lessons WHERE title = 'Математика. Профиль'),  'scheduled'),
    (1, (SELECT id FROM lessons WHERE title = 'Физика. Механика'),     'scheduled'),
    (1, (SELECT id FROM lessons WHERE title = 'Обществознание. Политика'), 'scheduled'),
    (1, (SELECT id FROM lessons WHERE title = 'Русский. Сочинение'),    'scheduled'),
    (1, (SELECT id FROM lessons WHERE title = 'История. XX век'),       'attended'),
    (1, (SELECT id FROM lessons WHERE title = 'Математика. Практика'),  'attended');

-- =============================================
-- 6. ЗАДАНИЯ
-- =============================================
INSERT INTO assignments (subject_id, title, description, material_id, due_date) VALUES
    ((SELECT id FROM subjects WHERE slug = 'math'),
     'Производная и её применение (Тест)',
     'Решить 10 задач на применение производной',
     (SELECT id FROM materials WHERE title = 'Производная и её применение'),
     CURRENT_DATE + INTERVAL '2 days'),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     'Сочинение по тексту Толстого',
     'Написать сочинение-рассуждение по тексту',
     (SELECT id FROM materials WHERE title = 'Алгоритм написания сочинения 27'),
     CURRENT_DATE + INTERVAL '5 days'),

    ((SELECT id FROM subjects WHERE slug = 'social'),
     'Правовая система РФ (Конспект)',
     'Составить конспект по теме "Правовая система"',
     (SELECT id FROM materials WHERE title = 'Правовая система РФ'),
     CURRENT_DATE + INTERVAL '9 days'),

    ((SELECT id FROM subjects WHERE slug = 'math'),
     'Практика: Геометрия 2 часть',
     'Решить задачи по геометрии из второй части ЕГЭ',
     (SELECT id FROM materials WHERE title = 'Геометрия: планиметрия. Часть 2'),
     CURRENT_DATE + INTERVAL '12 days'),

    ((SELECT id FROM subjects WHERE slug = 'physics'),
     'Механика: задачи на движение',
     'Решить 15 задач по кинематике и динамике',
     (SELECT id FROM materials WHERE title = 'Механика: кинематика и динамика'),
     CURRENT_DATE + INTERVAL '7 days'),

    ((SELECT id FROM subjects WHERE slug = 'history'),
     'Россия в XX веке: тест',
     'Пройти тест по ключевым событиям',
     (SELECT id FROM materials WHERE title = 'Россия в XX веке: ключевые события'),
     CURRENT_DATE + INTERVAL '3 days'),

    ((SELECT id FROM subjects WHERE slug = 'biology'),
     'Генетика: задачи Менделя',
     'Решить 10 задач на законы Менделя',
     (SELECT id FROM materials WHERE title = 'Генетика: законы Менделя + задачи'),
     CURRENT_DATE + INTERVAL '14 days'),

    ((SELECT id FROM subjects WHERE slug = 'russian'),
     'Пунктуация: сложные случаи',
     'Разобрать 20 сложных случаев пунктуации',
     (SELECT id FROM materials WHERE title = 'Пунктуация: сложные случаи'),
     CURRENT_DATE + INTERVAL '18 days');

-- =============================================
-- 7. ВЫПОЛНЕНИЕ ЗАДАНИЙ
-- =============================================
INSERT INTO assignment_submissions (user_id, assignment_id, status, score, submitted_at, graded_at) VALUES
    (1,
     (SELECT id FROM assignments WHERE title = 'Производная и её применение (Тест)'),
     'graded', 88, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),

    (1,
     (SELECT id FROM assignments WHERE title = 'Сочинение по тексту Толстого'),
     'graded', 92, NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days'),

    (1,
     (SELECT id FROM assignments WHERE title = 'Россия в XX веке: тест'),
     'graded', 79, NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),

    (1,
     (SELECT id FROM assignments WHERE title = 'Практика: Геометрия 2 часть'),
     'in_progress', NULL, NULL, NULL),

    (1,
     (SELECT id FROM assignments WHERE title = 'Механика: задачи на движение'),
     'in_progress', NULL, NULL, NULL);

-- =============================================
-- 8. ПРОГРЕСС ПО ПРЕДМЕТАМ (без progress — считается на лету)
-- =============================================
INSERT INTO user_subjects (user_id, subject_id, target_score) VALUES
    (1, (SELECT id FROM subjects WHERE slug = 'math'),    90),
    (1, (SELECT id FROM subjects WHERE slug = 'russian'), 95),
    (1, (SELECT id FROM subjects WHERE slug = 'social'),  85),
    (1, (SELECT id FROM subjects WHERE slug = 'physics'), 80),
    (1, (SELECT id FROM subjects WHERE slug = 'history'), 75),
    (1, (SELECT id FROM subjects WHERE slug = 'biology'), 70);

-- =============================================
-- 9. user_stats — заполняется триггером
-- =============================================

-- =============================================
-- 10. ПРОГРЕСС ПО МАТЕРИАЛАМ
-- =============================================
INSERT INTO material_progress (user_id, material_id, views_count, last_viewed_at) VALUES
    (1, (SELECT id FROM materials WHERE title = 'Производная и её применение'), 3, NOW() - INTERVAL '2 days'),
    (1, (SELECT id FROM materials WHERE title = 'Алгоритм написания сочинения 27'), 5, NOW() - INTERVAL '1 day'),
    (1, (SELECT id FROM materials WHERE title = 'Правовая система РФ'), 1, NOW() - INTERVAL '5 hours'),
    (1, (SELECT id FROM materials WHERE title = 'Механика: кинематика и динамика'), 2, NOW() - INTERVAL '3 days'),
    (1, (SELECT id FROM materials WHERE title = 'Россия в XX веке: ключевые события'), 4, NOW() - INTERVAL '4 days'),
    (1, (SELECT id FROM materials WHERE title = 'Клетка: строение и функции'), 1, NOW() - INTERVAL '6 days');

-- =============================================
-- 11. СООБЩЕНИЯ ПОДДЕРЖКИ
-- =============================================
INSERT INTO support_messages (user_id, support_user_id, message, is_from_support, is_read, created_at) VALUES
    (1, NULL, 'Здравствуйте! У меня проблема с загрузкой домашнего задания', FALSE, TRUE, NOW() - INTERVAL '2 days'),
    (NULL, 2, 'Привет! Я Анна, ваш личный куратор. Чем могу помочь?',       TRUE,  TRUE, NOW() - INTERVAL '2 days' + INTERVAL '5 minutes'),
    (1, NULL, 'Не открывается файл с тестом по производной',                 FALSE, TRUE, NOW() - INTERVAL '2 days' + INTERVAL '10 minutes'),
    (NULL, 2, 'Попробуйте обновить страницу — мы уже починили. Если не поможет, напишите снова.', TRUE, TRUE, NOW() - INTERVAL '2 days' + INTERVAL '15 minutes'),
    (1, NULL, 'Спасибо, всё заработало!',                                    FALSE, TRUE, NOW() - INTERVAL '1 day'),
    (NULL, 2, 'Отлично! Если будут вопросы — пишите.',                       TRUE,  TRUE, NOW() - INTERVAL '1 day' + INTERVAL '2 minutes'),
    (1, NULL, 'А можно перенести занятие по математике на час позже?',       FALSE, TRUE, NOW() - INTERVAL '3 hours'),
    (NULL, 2, 'Конечно, сейчас посмотрю расписание и перенесу.',             TRUE,  FALSE, NOW() - INTERVAL '2 hours');

-- =============================================
-- 12. ЗАЯВКИ
-- =============================================
INSERT INTO applications (user_id, email, phone, full_name, grade, subject_interest, message, source, status) VALUES
    (NULL, 'parent1@mail.ru', '+79001112233', 'Ирина Смирнова', 11, 'math',
     'Интересует подготовка к профильной математике, 11 класс', 'landing', 'new'),

    (NULL, 'parent2@mail.ru', '+79004445566', 'Ольга Кузнецова', 10, 'russian',
     'Нужна подготовка к сочинению', 'cta', 'contacted'),

    (1, 'alex@ege.ru', '+79007778899', 'Александр Волков', 11, 'social',
     'Хочу перейти на тариф с куратором', 'landing', 'processing'),

    (NULL, 'parent3@mail.ru', '+79009998877', 'Мария Петрова', 9, 'physics',
     'Нужен репетитор по физике для подготовки к ОГЭ', 'cta', 'new'),

    (NULL, 'parent4@mail.ru', '+79002223344', 'Сергей Иванов', 11, 'history',
     'Подготовка к ЕГЭ по истории, 11 класс', 'landing', 'done');

COMMIT;