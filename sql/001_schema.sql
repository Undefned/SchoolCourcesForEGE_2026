-- =============================================
-- 1. ПОЛЬЗОВАТЕЛИ
-- =============================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    grade INTEGER CHECK (grade BETWEEN 9 AND 11),
    avatar_url VARCHAR(500) DEFAULT '/uploads/avatars/default.png',
    is_support BOOLEAN DEFAULT FALSE, -- флаг, что это сотрудник поддержки
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP
);

-- =============================================
-- 2. ПРЕДМЕТЫ
-- =============================================
CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    color_code VARCHAR(7) DEFAULT '#8A15EA',
    icon VARCHAR(50) DEFAULT '📚',
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- =============================================
-- 3. ПОЛЬЗОВАТЕЛИ → ПРЕДМЕТЫ (прогресс)
-- =============================================
CREATE TABLE user_subjects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    progress INTEGER DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    target_score INTEGER DEFAULT 0 CHECK (target_score BETWEEN 0 AND 100),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, subject_id)
);

-- =============================================
-- 4. МАТЕРИАЛЫ (база знаний) - УПРОЩЕНО!
-- =============================================
CREATE TABLE materials (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('conspect', 'test', 'task', 'video')),
    content TEXT, -- Сам контент: текст конспекта, ссылка на YouTube, или просто описание
    task_count INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 30,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. ПРОГРЕСС ПО МАТЕРИАЛАМ - МАКСИМАЛЬНО УПРОЩЕНО!
-- =============================================
CREATE TABLE material_progress (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    material_id INTEGER NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    views_count INTEGER DEFAULT 0, -- Счетчик открытий
    last_viewed_at TIMESTAMP,
    UNIQUE(user_id, material_id)
);

-- =============================================
-- 6. ЗАНЯТИЯ (расписание)
-- =============================================
CREATE TABLE lessons (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    lesson_type VARCHAR(50) DEFAULT 'webinar' CHECK (lesson_type IN ('webinar', 'practice', 'lecture', 'consultation')),
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    meeting_url VARCHAR(500), -- Ссылка на Zoom/YouTube
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 7. ЗАПИСЬ НА ЗАНЯТИЯ (расписание пользователя)
-- =============================================
CREATE TABLE user_lessons (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'attended', 'missed', 'cancelled')),
    attended_at TIMESTAMP,
    UNIQUE(user_id, lesson_id)
);

-- =============================================
-- 8. ЗАДАНИЯ
-- =============================================
CREATE TABLE assignments (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    material_id INTEGER REFERENCES materials(id) ON DELETE SET NULL,
    points_possible INTEGER DEFAULT 100,
    due_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 9. ВЫПОЛНЕНИЕ ЗАДАНИЙ
-- =============================================
CREATE TABLE assignment_submissions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assignment_id INTEGER NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'submitted', 'graded')),
    submission_text TEXT,
    file_url VARCHAR(500),
    score INTEGER CHECK (score BETWEEN 0 AND 100),
    feedback TEXT,
    submitted_at TIMESTAMP,
    graded_at TIMESTAMP,
    UNIQUE(user_id, assignment_id)
);

-- =============================================
-- 10. СООБЩЕНИЯ ЧАТА ПОДДЕРЖКИ
-- =============================================
CREATE TABLE support_messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    support_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    is_from_support BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 11. ЗАЯВКИ (форма "Записаться бесплатно")
-- =============================================
CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    grade INTEGER CHECK (grade BETWEEN 9 AND 11),
    subject_interest VARCHAR(100),
    message TEXT,
    status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'processing', 'contacted', 'done')),
    source VARCHAR(50) DEFAULT 'landing' CHECK (source IN ('landing', 'cta', 'special_order')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- =============================================
-- 12. СТАТИСТИКА ПОЛЬЗОВАТЕЛЯ
-- =============================================
CREATE TABLE user_stats (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_lessons_attended INTEGER DEFAULT 0,
    total_assignments_completed INTEGER DEFAULT 0,
    avg_score DECIMAL(5,2) DEFAULT 0,
    streak_days INTEGER DEFAULT 0, -- "ударный режим"
    last_activity_date DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 13. ВЕБ-СЕССИИ
-- =============================================
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 14. ТРИГГЕРЫ
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================
-- 15. ФУНКЦИЯ ОБНОВЛЕНИЯ СТАТИСТИКИ
-- =============================================
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
DECLARE
    user_id_val INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'assignment_submissions' THEN
        user_id_val = NEW.user_id;
    ELSIF TG_TABLE_NAME = 'user_lessons' THEN
        user_id_val = NEW.user_id;
    ELSE
        RETURN NEW;
    END IF;

    INSERT INTO user_stats (user_id, total_lessons_attended, total_assignments_completed, avg_score, updated_at)
    VALUES (
        user_id_val,
        (SELECT COUNT(*) FROM user_lessons WHERE user_id = user_id_val AND status = 'attended'),
        (SELECT COUNT(*) FROM assignment_submissions WHERE user_id = user_id_val AND status = 'graded'),
        COALESCE((SELECT AVG(score) FROM assignment_submissions WHERE user_id = user_id_val AND status = 'graded'), 0),
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_lessons_attended = EXCLUDED.total_lessons_attended,
        total_assignments_completed = EXCLUDED.total_assignments_completed,
        avg_score = EXCLUDED.avg_score,
        updated_at = EXCLUDED.updated_at;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stats_on_submission
AFTER INSERT OR UPDATE ON assignment_submissions
FOR EACH ROW EXECUTE FUNCTION update_user_stats();

CREATE TRIGGER trigger_stats_on_lesson
AFTER INSERT OR UPDATE ON user_lessons
FOR EACH ROW EXECUTE FUNCTION update_user_stats();