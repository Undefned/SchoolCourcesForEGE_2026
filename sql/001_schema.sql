-- =============================================
-- 0. DROP
-- =============================================
DROP TABLE IF EXISTS assignment_submissions CASCADE;
DROP TABLE IF EXISTS assignments            CASCADE;
DROP TABLE IF EXISTS user_lessons           CASCADE;
DROP TABLE IF EXISTS lessons                CASCADE;
DROP TABLE IF EXISTS material_progress      CASCADE;
DROP TABLE IF EXISTS materials              CASCADE;
DROP TABLE IF EXISTS user_subjects          CASCADE;
DROP TABLE IF EXISTS subjects               CASCADE;
DROP TABLE IF EXISTS support_messages       CASCADE;
DROP TABLE IF EXISTS applications           CASCADE;
DROP TABLE IF EXISTS user_stats             CASCADE;
DROP TABLE IF EXISTS sessions               CASCADE;
DROP TABLE IF EXISTS users                  CASCADE;

DROP FUNCTION IF EXISTS update_user_stats() CASCADE;

-- =============================================
-- 1. ПОЛЬЗОВАТЕЛИ
-- =============================================
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    grade           INTEGER CHECK (grade BETWEEN 9 AND 11),
    avatar_url      VARCHAR(500) DEFAULT '../assets/Avatar.png',
    is_support      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_support ON users(is_support) WHERE is_support = TRUE;

-- =============================================
-- 2. ПРЕДМЕТЫ
-- =============================================
CREATE TABLE subjects (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    slug        VARCHAR(100) NOT NULL UNIQUE,
    color_code  VARCHAR(7)   DEFAULT '#8A15EA',
    icon        VARCHAR(50)  DEFAULT '📚',
    sort_order  INTEGER      DEFAULT 0,
    is_active   BOOLEAN      DEFAULT TRUE
);

CREATE INDEX idx_subjects_slug ON subjects(slug);
CREATE INDEX idx_subjects_sort_order ON subjects(sort_order);

-- =============================================
-- 3. ПОЛЬЗОВАТЕЛИ → ПРЕДМЕТЫ
-- =============================================
CREATE TABLE user_subjects (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    subject_id    INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    target_score  INTEGER DEFAULT 80 CHECK (target_score BETWEEN 0 AND 100),
    UNIQUE(user_id, subject_id)
);

CREATE INDEX idx_user_subjects_user ON user_subjects(user_id);
CREATE INDEX idx_user_subjects_subject ON user_subjects(subject_id);

-- =============================================
-- 4. МАТЕРИАЛЫ
-- =============================================
CREATE TABLE materials (
    id                SERIAL PRIMARY KEY,
    subject_id        INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    type              VARCHAR(50)  NOT NULL CHECK (type IN ('conspect', 'test', 'task', 'video')),
    content           TEXT,
    task_count        INTEGER DEFAULT 0,
    duration_minutes  INTEGER DEFAULT 30,
    sort_order        INTEGER DEFAULT 0,
    is_active         BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_materials_subject ON materials(subject_id);
CREATE INDEX idx_materials_type ON materials(type);

-- =============================================
-- 5. ПРОГРЕСС ПО МАТЕРИАЛАМ
-- =============================================
CREATE TABLE material_progress (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
    material_id     INTEGER NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    views_count     INTEGER DEFAULT 0,
    last_viewed_at  TIMESTAMP,
    UNIQUE(user_id, material_id)
);

CREATE INDEX idx_material_progress_user ON material_progress(user_id);

-- =============================================
-- 6. ЗАНЯТИЯ
-- =============================================
CREATE TABLE lessons (
    id                SERIAL PRIMARY KEY,
    subject_id        INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id        INTEGER REFERENCES users(id) ON DELETE SET NULL,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    lesson_type       VARCHAR(50) DEFAULT 'webinar'
                      CHECK (lesson_type IN ('webinar', 'practice', 'lecture', 'consultation')),
    scheduled_at      TIMESTAMP NOT NULL,
    duration_minutes  INTEGER DEFAULT 60,
    is_cancelled      BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_lessons_subject ON lessons(subject_id);
CREATE INDEX idx_lessons_scheduled_at ON lessons(scheduled_at);

-- =============================================
-- 7. ЗАПИСЬ НА ЗАНЯТИЯ
-- =============================================
CREATE TABLE user_lessons (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    lesson_id    INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status       VARCHAR(20) DEFAULT 'scheduled'
                 CHECK (status IN ('scheduled', 'attended', 'missed', 'cancelled')),
    UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_user_lessons_user ON user_lessons(user_id);
CREATE INDEX idx_user_lessons_status ON user_lessons(status);

-- =============================================
-- 8. ЗАДАНИЯ
-- =============================================
CREATE TABLE assignments (
    id              SERIAL PRIMARY KEY,
    subject_id      INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    material_id     INTEGER REFERENCES materials(id) ON DELETE SET NULL,
    due_date        DATE NOT NULL
);

CREATE INDEX idx_assignments_subject ON assignments(subject_id);
CREATE INDEX idx_assignments_due_date ON assignments(due_date);
CREATE INDEX idx_assignments_material ON assignments(material_id);

-- =============================================
-- 9. ВЫПОЛНЕНИЕ ЗАДАНИЙ
-- =============================================
CREATE TABLE assignment_submissions (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES users(id)       ON DELETE CASCADE,
    assignment_id    INTEGER NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    status           VARCHAR(20) DEFAULT 'not_started'
                     CHECK (status IN ('not_started', 'in_progress', 'submitted', 'graded')),
    score            INTEGER CHECK (score BETWEEN 0 AND 100),
    submitted_at     TIMESTAMP,
    graded_at        TIMESTAMP,
    UNIQUE(user_id, assignment_id)
);

CREATE INDEX idx_submissions_user ON assignment_submissions(user_id);
CREATE INDEX idx_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX idx_submissions_status ON assignment_submissions(status);

-- =============================================
-- 10. СООБЩЕНИЯ ПОДДЕРЖКИ
-- =============================================
CREATE TABLE support_messages (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER REFERENCES users(id) ON DELETE SET NULL,
    support_user_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
    message          TEXT NOT NULL,
    is_from_support  BOOLEAN DEFAULT FALSE,
    is_read          BOOLEAN DEFAULT FALSE,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_user ON support_messages(user_id);
CREATE INDEX idx_support_created ON support_messages(created_at);

-- =============================================
-- 11. ЗАЯВКИ
-- =============================================
CREATE TABLE applications (
    id                SERIAL PRIMARY KEY,
    user_id           INTEGER REFERENCES users(id) ON DELETE SET NULL,
    email             VARCHAR(255),
    phone             VARCHAR(32),
    full_name         VARCHAR(255) NOT NULL,
    grade             INTEGER CHECK (grade BETWEEN 9 AND 11),
    subject_interest  VARCHAR(100),
    message           TEXT,
    status            VARCHAR(50) DEFAULT 'new'
                      CHECK (status IN ('new', 'processing', 'contacted', 'done')),
    source            VARCHAR(50) DEFAULT 'landing'
                      CHECK (source IN ('landing', 'cta', 'special_order')),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT applications_contact_check
        CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE INDEX idx_applications_email ON applications(email);
CREATE INDEX idx_applications_status ON applications(status);

-- =============================================
-- 12. СТАТИСТИКА ПОЛЬЗОВАТЕЛЯ
-- =============================================
CREATE TABLE user_stats (
    user_id                     INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_lessons_attended      INTEGER DEFAULT 0,
    total_assignments_completed INTEGER DEFAULT 0,
    avg_score                   DECIMAL(5,2) DEFAULT 0,
    streak_days                 INTEGER DEFAULT 0
);

-- =============================================
-- 13. СЕССИИ
-- =============================================
CREATE TABLE sessions (
    id             SERIAL PRIMARY KEY,
    user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token  VARCHAR(255) NOT NULL UNIQUE,
    expires_at     TIMESTAMP NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(session_token);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);

-- =============================================
-- 14. ТРИГГЕР: обновление статистики пользователя
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

    INSERT INTO user_stats (
        user_id,
        total_lessons_attended,
        total_assignments_completed,
        avg_score
    )
    VALUES (
        user_id_val,
        (SELECT COUNT(*) FROM user_lessons
            WHERE user_id = user_id_val AND status = 'attended'),
        (SELECT COUNT(*) FROM assignment_submissions
            WHERE user_id = user_id_val AND status = 'graded'),
        COALESCE(
            (SELECT AVG(score) FROM assignment_submissions
                WHERE user_id = user_id_val AND status = 'graded'),
            0
        )
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_lessons_attended      = EXCLUDED.total_lessons_attended,
        total_assignments_completed = EXCLUDED.total_assignments_completed,
        avg_score                   = EXCLUDED.avg_score;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stats_on_submission
    AFTER INSERT OR UPDATE ON assignment_submissions
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();

CREATE TRIGGER trigger_stats_on_lesson
    AFTER INSERT OR UPDATE ON user_lessons
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();