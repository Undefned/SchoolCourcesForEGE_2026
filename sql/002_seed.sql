-- =============================================
-- 1. ПРЕДМЕТЫ
-- =============================================
INSERT INTO subjects (name, slug, color_code, icon, sort_order) VALUES
    ('Математика', 'math', '#8A15EA', '📐', 1),
    ('Русский язык', 'russian', '#75EA15', '📝', 2),
    ('Обществознание', 'social', '#2B7FFF', '⚖️', 3),
    ('Физика', 'physics', '#F04438', '⚡', 4),
    ('История', 'history', '#F79009', '📜', 5),
    ('Биология', 'biology', '#12B76A', '🧬', 6);

-- =============================================
-- 2. ПОЛЬЗОВАТЕЛИ (пароль: 123456)
-- =============================================
INSERT INTO users (email, password_hash, full_name, grade, is_support) VALUES
    ('alex@ege.ru', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Александр Волков', 11, FALSE),
    ('support@exametrika.ru', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Анна Смирнова', NULL, TRUE);

-- =============================================
-- 3. МАТЕРИАЛЫ (контент прямо в БД)
-- =============================================
INSERT INTO materials (subject_id, title, description, type, content, task_count, duration_minutes) VALUES
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Производная и её применение',
        'Подробный конспект с разбором всех типов задач на производную',
        'conspect',
        '# Производная функции\n\n## Определение\nПроизводная функции — это предел отношения приращения функции к приращению аргумента...',
        24,
        45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Тригонометрические уравнения',
        'Тест на проверку навыков решения тригонометрических уравнений',
        'test',
        'Вопрос 1: Решите уравнение sin(x) = 0.5\nВарианты: а) π/6, б) π/3, в) π/4',
        15,
        30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Лексика и фразеология ЕГЭ',
        'Видеоурок по основным правилам лексики',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ', -- Рофл-ссылка 😂
        14,
        30
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Алгоритм написания сочинения 27',
        'Пошаговый алгоритм для сочинения ЕГЭ по русскому',
        'conspect',
        '# Структура сочинения ЕГЭ 27\n\n## Вступление (2-3 предложения)\n- Ввести в тему...',
        24,
        45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Социальные нормы и институты',
        'Тест по обществознанию',
        'test',
        'Вопрос 1: Что такое социальный институт?\nВарианты: ...',
        22,
        45
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'physics'),
        'Механика: кинематика и динамика',
        'Конспект по механике',
        'conspect',
        '# Механика\n\n## Кинематика\n- Равномерное движение: S = v*t\n- Равноускоренное движение: S = v0*t + at²/2',
        22,
        25
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'history'),
        'Россия в XX веке: ключевые события',
        'Тест по истории России XX века',
        'test',
        'Вопрос 1: В каком году произошла революция?\nВарианты: 1905, 1917, 1921',
        22,
        25
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'biology'),
        'Клетка: строение и функции',
        'Тест по биологии',
        'test',
        'Вопрос 1: Что такое митохондрии?\nВарианты: ...',
        22,
        35
    );

-- =============================================
-- 4. ЗАНЯТИЯ (расписание)
-- =============================================
INSERT INTO lessons (subject_id, teacher_id, title, scheduled_at, duration_minutes, meeting_url) VALUES
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        (SELECT id FROM users WHERE email = 'alex@ege.ru'),
        'Математика. Профиль',
        '2026-09-07 10:00:00',
        90,
        'https://meet.google.com/abc-defg-hij'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'physics'),
        (SELECT id FROM users WHERE email = 'alex@ege.ru'),
        'Физика. Механика',
        '2026-09-08 12:00:00',
        90,
        'https://youtu.be/dQw4w9WgXcQ' -- Рофл 😂
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        (SELECT id FROM users WHERE email = 'alex@ege.ru'),
        'Обществознание. Политика',
        '2026-09-09 14:00:00',
        90,
        'https://meet.google.com/xyz-uvwx-yza'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        (SELECT id FROM users WHERE email = 'alex@ege.ru'),
        'Русский. Сочинение',
        '2026-09-10 16:00:00',
        90,
        'https://youtu.be/dQw4w9WgXcQ' -- 😂
    );

-- =============================================
-- 5. ЗАДАНИЯ
-- =============================================
INSERT INTO assignments (subject_id, title, description, points_possible, due_date) VALUES
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Производная и её применение (Тест)',
        'Решить 10 задач на применение производной',
        100,
        '2026-09-07'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'russian'),
        'Сочинение по тексту Толстого',
        'Написать сочинение-рассуждение по тексту',
        100,
        '2026-09-08'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'social'),
        'Правовая система РФ (Конспект)',
        'Составить конспект по теме "Правовая система"',
        100,
        '2026-09-25'
    ),
    (
        (SELECT id FROM subjects WHERE slug = 'math'),
        'Практика: Геометрия 2 часть',
        'Решить задачи по геометрии из второй части ЕГЭ',
        100,
        '2026-09-28'
    );

-- =============================================
-- 6. ПРОГРЕСС ПОЛЬЗОВАТЕЛЯ
-- =============================================
INSERT INTO user_subjects (user_id, subject_id, progress, target_score) VALUES
    (1, (SELECT id FROM subjects WHERE slug = 'math'), 82, 90),
    (1, (SELECT id FROM subjects WHERE slug = 'russian'), 94, 95),
    (1, (SELECT id FROM subjects WHERE slug = 'social'), 78, 85);

-- =============================================
-- 7. СТАТИСТИКА
-- =============================================
INSERT INTO user_stats (user_id, total_lessons_attended, total_assignments_completed, avg_score, streak_days) VALUES
    (1, 42, 15, 84, 5);

-- =============================================
-- 8. СООБЩЕНИЯ ПОДДЕРЖКИ
-- =============================================
INSERT INTO support_messages (user_id, support_user_id, message, is_from_support) VALUES
    (1, NULL, 'Здравствуйте! У меня проблема с загрузкой домашнего задания', FALSE),
    (NULL, 2, 'Привет! Я Анна, ваш личный куратор. Чем могу помочь?', TRUE);