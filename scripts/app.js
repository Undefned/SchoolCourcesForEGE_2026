// =============================================
// НАСТРОЙКИ
// =============================================
const API_BASE = '/api';
const USE_MOCK = false;

// =============================================
// БАЗОВЫЙ ФЕТЧ
// =============================================
async function fetchApi(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const headers = {
        'Content-Type': 'application/json',
        ...(options.headers || {})
    };
    
    // Добавляем токен из куки
    const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('session_token='))
        ?.split('=')[1];
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    const response = await fetch(url, {
        credentials: 'same-origin',
        headers,
        ...options,
    });
    
    const data = await response.json();
    
    if (!response.ok || !data.ok) {
        throw new Error(data.error?.message || 'Ошибка API');
    }
    
    return data.data;
}

// =============================================
// АВТОРИЗАЦИЯ
// =============================================
async function login(email, password) {
    return fetchApi('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
    });
}

async function register(email, password, fullName, grade) {
    return fetchApi('/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email, password, fullName, grade }),
    });
}

async function logout() {
    return fetchApi('/auth/logout', { method: 'POST' });
}

async function getCurrentUser() {
    return fetchApi('/auth/me');
}

// =============================================
// МАТЕРИАЛЫ (База знаний)
// =============================================
async function getMaterials(subject) {
    if (subject) {
        return fetchApi('/materials?subject=' + encodeURIComponent(subject));
    }
    return fetchApi('/materials');
}

async function getMaterialsWithFilters(filters = {}) {
    const params = new URLSearchParams();
    
    if (filters.subject) params.append('subject', filters.subject);
    if (filters.type) params.append('type', filters.type);
    if (filters.search) params.append('search', filters.search);
    if (filters.limit) params.append('limit', filters.limit);
    if (filters.offset) params.append('offset', filters.offset);
    
    return fetchApi('/materials?' + params.toString());
}

async function viewMaterial(materialId) {
    return fetchApi('/materials/view', {
        method: 'POST',
        body: JSON.stringify({ materialId }),
    });
}

// =============================================
// РАСПИСАНИЕ
// =============================================
async function getSchedule(weekStart) {
    const params = new URLSearchParams();
    if (weekStart) params.append('week', weekStart);
    return fetchApi('/schedule?' + params.toString());
}

// =============================================
// ЗАДАНИЯ
// =============================================
async function getAssignments(filters = {}) {
    const params = new URLSearchParams();
    if (filters.subject) params.append('subject', filters.subject);
    if (filters.status) params.append('status', filters.status);
    if (filters.sort) params.append('sort', filters.sort);
    if (filters.order) params.append('order', filters.order);
    
    return fetchApi('/assignments?' + params.toString());
}

// =============================================
// ПОДДЕРЖКА
// =============================================
async function getSupportMessages() {
    return fetchApi('/support');
}

async function sendSupportMessage(message) {
    return fetchApi('/support', {
        method: 'POST',
        body: JSON.stringify({ message }),
    });
}

// =============================================
// ЗАЯВКИ (формы записи)
// =============================================
async function sendApplication(data) {
    return fetchApi('/applications', {
        method: 'POST',
        body: JSON.stringify({
            email: data.email,
            fullName: data.fullName,
            grade: data.grade,
            subject: data.subject,
            message: data.message,
            source: data.source || 'landing',
        }),
    });
}

// =============================================
// ПОЛЬЗОВАТЕЛЬ
// =============================================
async function getUserProfile() {
    return fetchApi('/user');
}

async function updateUserProfile(data) {
    return fetchApi('/user', {
        method: 'PUT',
        body: JSON.stringify(data),
    });
}

// =============================================
// ХЕЛПЕРЫ ДЛЯ ФРОНТЕНДА
// =============================================

// Форматирование даты
function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('ru-RU', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
    });
}

// Форматирование времени
function formatTime(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('ru-RU', {
        hour: '2-digit',
        minute: '2-digit',
    });
}

// Получение статуса задания на русском
function getAssignmentStatusText(status) {
    const statusMap = {
        'not_started': 'Не начато',
        'in_progress': 'В процессе',
        'submitted': 'На проверке',
        'graded': 'Проверено',
    };
    return statusMap[status] || status;
}

// Получение CSS класса для статуса
function getAssignmentStatusClass(status) {
    const classMap = {
        'not_started': 'status-none',
        'in_progress': 'status-progress',
        'submitted': 'status-submitted',
        'graded': 'status-done',
    };
    return classMap[status] || 'status-none';
}

// Получение типа материала на русском
function getMaterialTypeText(type) {
    const typeMap = {
        'conspect': 'Конспект',
        'test': 'Тест',
        'task': 'Задания',
        'video': 'Видео',
    };
    return typeMap[type] || type;
}

// Получение CSS класса для типа материала
function getMaterialTypeClass(type) {
    const classMap = {
        'conspect': 'type-default',
        'test': 'type-test',
        'task': 'type-task',
        'video': 'type-video',
    };
    return classMap[type] || 'type-default';
}

// Экранирование HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// =============================================
// ИНИЦИАЛИЗАЦИЯ СТРАНИЦ
// =============================================

// Проверка авторизации на страницах, где нужна
async function requireAuth(redirectUrl = '/login') {
    try {
        const user = await getCurrentUser();
        return user;
    } catch (error) {
        window.location.href = redirectUrl;
        return null;
    }
}

// Загрузка данных для дашборда
async function loadDashboard() {
    const user = await requireAuth();
    if (!user) return;
    
    try {
        const data = await getUserProfile();
        renderDashboard(data);
    } catch (error) {
        console.error('Ошибка загрузки дашборда:', error);
    }
}

// Загрузка базы знаний
async function loadKnowledgeBase(filters = {}) {
    try {
        const data = await getMaterialsWithFilters(filters);
        renderMaterials(data);
    } catch (error) {
        console.error('Ошибка загрузки материалов:', error);
    }
}

// Загрузка расписания
async function loadSchedule(weekStart) {
    try {
        const data = await getSchedule(weekStart);
        renderSchedule(data);
    } catch (error) {
        console.error('Ошибка загрузки расписания:', error);
    }
}

// Загрузка заданий
async function loadAssignments(filters = {}) {
    try {
        const data = await getAssignments(filters);
        renderAssignments(data);
    } catch (error) {
        console.error('Ошибка загрузки заданий:', error);
    }
}

// =============================================
// РЕНДЕРИНГ (примеры)
// =============================================

// =============================================
// РЕНДЕРИНГ ДАШБОРДА — ПОЛНОСТЬЮ ДИНАМИЧЕСКИ
// =============================================
function renderDashboard(data) {
    const { profile, subjects, assignments } = data || { profile: {}, subjects: [], assignments: [] };
    
    // ===== ПРОФИЛЬ =====
    const profileName = document.getElementById('profileName');
    const profileEmail = document.getElementById('profileEmail');
    const profileAvatar = document.getElementById('profileAvatar');
    
    if (profileName) profileName.textContent = profile.full_name || 'Пользователь';
    if (profileEmail) profileEmail.textContent = profile.email || '—';
    if (profileAvatar) {
        profileAvatar.src = profile.avatar_url && profile.avatar_url !== '/uploads/avatars/default.png' 
            ? profile.avatar_url 
            : '/assets/Avatar.png';
        profileAvatar.alt = profile.full_name || 'Аватар';
    }
    
    // ===== СТАТИСТИКА В ШАПКЕ =====
    const headerScore = document.getElementById('headerScore');
    if (headerScore) {
        headerScore.textContent = profile.avg_score ? `${Math.round(profile.avg_score)} баллов` : '—';
    }
    
    // ===== СТАТИСТИКА =====
    document.getElementById('statLessons').textContent = profile.total_lessons_attended || 0;
    document.getElementById('statScore').textContent = Math.round(profile.avg_score || 0);
    document.getElementById('statStreak').textContent = profile.streak_days || 0;
    
    // ===== ПРЕДМЕТЫ =====
    const subjectList = document.getElementById('subjectList');
    if (subjectList) {
        if (subjects && subjects.length) {
            subjectList.innerHTML = subjects.map(subject => `
                <div class="subject-row">
                    <div class="left">
                        <div class="ring" style="--pct:${subject.progress || 0};--ring-color:${subject.color_code || '#8A15EA'}" data-pct="${subject.progress || 0}"></div>
                        <div>
                            <div class="name">${escapeHtml(subject.name || 'Без названия')}</div>
                            <div class="activity">Цель: ${subject.target_score || 0} баллов</div>
                        </div>
                    </div>
                    <button class="btn-primary btn-continue" onclick="window.location.href='/knowledge-base?subject=${subject.slug}'">
                        Продолжить
                    </button>
                </div>
            `).join('');
        } else {
            subjectList.innerHTML = `
                <div class="empty-state">
                    <span class="icon">📚</span>
                    <p>Вы пока не добавили ни одного предмета</p>
                </div>
            `;
        }
    }
    
    // ===== ГРАФИК АКТИВНОСТИ =====
    const weeklyBars = document.getElementById('weeklyBars');
    if (weeklyBars) {
        // Пример данных — замените на реальные из БД
        const weekData = [
            { day: 'Пн', height: 120 },
            { day: 'Вт', height: 80 },
            { day: 'Ср', height: 160 },
            { day: 'Чт', height: 100 },
            { day: 'Пт', height: 140 },
            { day: 'Сб', height: 40 },
            { day: 'Вс', height: 15 },
        ];
        
        weeklyBars.innerHTML = weekData.map(day => `
            <div class="bar-col">
                <div class="bar" style="height:${day.height}px;background:${day.height > 50 ? '#75EA15' : '#4E4E5E'};"></div>
                <span class="day">${day.day}</span>
            </div>
        `).join('');
    }
    
    // ===== ЗАДАНИЯ =====
    const assignmentsBody = document.getElementById('assignmentsBody');
    if (assignmentsBody) {
        if (assignments && assignments.length) {
            const today = new Date();
            assignmentsBody.innerHTML = assignments.map(assignment => {
                const dueDate = new Date(assignment.due_date);
                const isUrgent = (dueDate - today) < 86400000 * 2;
                const statusText = getAssignmentStatusText(assignment.status);
                const statusClass = getAssignmentStatusClass(assignment.status);
                
                return `
                    <tr>
                        <td class="assign-name">${escapeHtml(assignment.title || 'Без названия')}</td>
                        <td class="assign-subject">${escapeHtml(assignment.subject_name || '—')}</td>
                        <td><span class="status-pill ${statusClass}">${statusText}</span></td>
                        <td class="${isUrgent ? 'deadline-urgent' : 'deadline-normal'}">${formatDate(assignment.due_date)}</td>
                        <td>${assignment.score || '—'}</td>
                    </tr>
                `;
            }).join('');
        } else {
            assignmentsBody.innerHTML = `
                <tr>
                    <td colspan="5" style="text-align:center;padding:40px;color:var(--main-text);">
                        🎉 Нет заданий на эту неделю
                    </td>
                </tr>
            `;
        }
    }
}

// =============================================
// ЗАГРУЗКА ДАШБОРДА С ПРОВЕРКОЙ АВТОРИЗАЦИИ
// =============================================
async function loadDashboard() {
    try {
        // Проверяем авторизацию
        const user = await getCurrentUser();
        if (!user) {
            window.location.href = '/login';
            return;
        }
        
        // Загружаем данные профиля
        const data = await getUserProfile();
        renderDashboard(data);
        
    } catch (error) {
        console.error('Ошибка загрузки дашборда:', error);
        // Если ошибка 401 — редирект на логин
        if (error.message.includes('401') || error.message.includes('авторизован')) {
            window.location.href = '/login';
        }
    }
}

// Рендеринг материалов (база знаний)
function renderMaterials(data) {
    const { items, stats } = data;
    
    // Обновляем статистику
    const statsElements = document.querySelectorAll('.mini-stat .num');
    if (statsElements.length >= 3) {
        statsElements[0].textContent = stats.total_materials || 0;
        statsElements[1].textContent = stats.total_subjects || 0;
        statsElements[2].textContent = stats.total_viewed || 0;
    }
    
    // Рендерим материалы по предметам
    const sections = document.querySelectorAll('.subject-section');
    sections.forEach(section => {
        const subjectSlug = section.dataset.subject;
        const subjectItems = items.filter(item => item.subject_slug === subjectSlug);
        const grid = section.querySelector('.material-grid');
        
        if (grid && subjectItems.length) {
            grid.innerHTML = subjectItems.map(material => `
                <article class="material-card" data-material-id="${material.id}">
                    <span class="type-badge ${getMaterialTypeClass(material.type)}">
                        <span class="icon">${material.type === 'conspect' ? '📄' : material.type === 'test' ? '✅' : material.type === 'task' ? '📝' : '▶'}</span>
                        ${getMaterialTypeText(material.type)}
                    </span>
                    <div class="material-title">${escapeHtml(material.title)}</div>
                    <div class="material-tag">
                        <span class="dot" style="background:${material.color_code || '#8A15EA'}"></span>
                        <span>${escapeHtml(material.subject_name)}</span>
                    </div>
                    <div class="material-meta">
                        <span>${material.task_count || 0} заданий</span>
                        <span>${material.duration_minutes || 30} мин</span>
                    </div>
                    <button class="btn-soft" onclick="openMaterial(${material.id})">Открыть</button>
                </article>
            `).join('');
        }
    });
}

// Открытие материала (модалка)
async function openMaterial(materialId) {
    try {
        // Отмечаем просмотр
        await viewMaterial(materialId);
        
        // Находим материал в данных
        const material = findMaterialById(materialId);
        if (!material) return;
        
        // Создаем модалку
        const modal = document.createElement('dialog');
        modal.className = 'material-modal';
        
        let content = '';
        if (material.type === 'video') {
            content = `
                <iframe src="${escapeHtml(material.content)}" width="100%" height="400" allowfullscreen></iframe>
            `;
        } else if (material.type === 'conspect') {
            content = `
                <div class="conspect-content">
                    ${escapeHtml(material.content || 'Конспект в разработке')}
                </div>
            `;
        } else {
            content = `
                <div class="material-content">
                    <p>${escapeHtml(material.description || 'Материал в разработке')}</p>
                    ${material.content ? `<pre>${escapeHtml(material.content)}</pre>` : ''}
                </div>
            `;
        }
        
        modal.innerHTML = `
            <div class="modal-header">
                <h3>${escapeHtml(material.title)}</h3>
                <button onclick="this.closest('dialog').close()">✕</button>
            </div>
            <div class="modal-body">
                ${content}
            </div>
        `;
        
        document.body.appendChild(modal);
        modal.showModal();
        
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.close();
        });
        
        modal.addEventListener('close', () => {
            modal.remove();
        });
        
    } catch (error) {
        console.error('Ошибка открытия материала:', error);
        alert('Не удалось открыть материал');
    }
}

// Поиск материала по ID в загруженных данных
let cachedMaterials = [];

function findMaterialById(id) {
    return cachedMaterials.find(m => m.id === id);
}

// Сохраняем материалы при рендере
const originalRenderMaterials = renderMaterials;
renderMaterials = function(data) {
    cachedMaterials = data.items || [];
    originalRenderMaterials(data);
};

// =============================================
// ИНИЦИАЛИЗАЦИЯ ПРИ ЗАГРУЗКЕ СТРАНИЦЫ
// =============================================

document.addEventListener('DOMContentLoaded', function() {
    const path = window.location.pathname;
    
    // Дашборд
    if (path.includes('dashboard')) {
        loadDashboard();
    }
    
    // База знаний
    if (path.includes('knowledge-base')) {
        loadKnowledgeBase();
    }
    
    // Расписание
    if (path.includes('schedule')) {
        loadSchedule();
    }
    
    // Поддержка
    if (path.includes('support')) {
        initSupport();
    }
    
    // Формы заявок
    const applicationForms = document.querySelectorAll('.lead-form, .cta-form');
    applicationForms.forEach(form => {
        form.addEventListener('submit', handleApplicationSubmit);
    });
});

// =============================================
// ОБРАБОТЧИКИ ФОРМ
// =============================================

async function handleApplicationSubmit(e) {
    e.preventDefault();
    const form = e.target;
    const submitBtn = form.querySelector('button[type="submit"]');
    
    try {
        submitBtn.disabled = true;
        submitBtn.textContent = 'Отправка...';
        
        const data = {
            email: form.querySelector('input[type="email"], input[type="tel"]')?.value || '',
            fullName: form.querySelector('input[type="text"]')?.value || '',
            grade: form.querySelector('select[name="grade"]')?.value || 11,
            subject: form.querySelector('select')?.value || '',
            message: form.querySelector('textarea')?.value || '',
            source: 'landing',
        };
        
        await sendApplication(data);
        
        // Показываем успех
        alert('Заявка отправлена! Мы свяжемся с вами в ближайшее время.');
        form.reset();
        
    } catch (error) {
        alert(error.message || 'Ошибка отправки заявки');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Записаться бесплатно';
    }
}

// =============================================
// ПОДДЕРЖКА (чат)
// =============================================

async function initSupport() {
    const chatBody = document.querySelector('.chat-body');
    const chatForm = document.querySelector('.chat-input-row');
    
    if (!chatBody || !chatForm) return;
    
    try {
        const messages = await getSupportMessages();
        renderSupportMessages(messages, chatBody);
    } catch (error) {
        console.error('Ошибка загрузки чата:', error);
    }
    
    chatForm.addEventListener('submit', async function(e) {
        e.preventDefault();
        const input = this.querySelector('input');
        const text = input.value.trim();
        if (!text) return;
        
        try {
            await sendSupportMessage(text);
            input.value = '';
            const messages = await getSupportMessages();
            renderSupportMessages(messages, chatBody);
        } catch (error) {
            alert('Не удалось отправить сообщение');
        }
    });
}

function renderSupportMessages(messages, container) {
    if (!messages.length) {
        container.innerHTML = `
            <div class="msg">
                <div class="bubble">Здравствуйте! Чем я могу вам помочь?</div>
                <span class="time">${new Date().toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
        `;
        return;
    }
    
    container.innerHTML = messages.map(msg => {
        const isSupport = msg.is_from_support;
        return `
            <div class="msg" style="${isSupport ? '' : 'align-items: flex-end; margin-left: auto;'}">
                <div class="bubble" style="${isSupport ? '' : 'background: #111111; color: white; border-radius: 16px 16px 4px 16px;'}">
                    ${escapeHtml(msg.message)}
                </div>
                <span class="time">${formatTime(msg.created_at)}</span>
            </div>
        `;
    }).join('');
    
    container.scrollTop = container.scrollHeight;
}

// =============================================
// РЕНДЕРИНГ РАСПИСАНИЯ
// =============================================
let currentWeekStart = null; // ISO yyyy-mm-dd

const SCHED_HOURS = [9,10,11,12,13,14,15,16,17,18];
const DOW_LABELS = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];

function renderSchedule(data) {
    currentWeekStart = data.weekStart;

    const startDate = new Date(data.weekStart + 'T00:00:00');
    const endDate = new Date(data.weekEnd + 'T00:00:00');
    const rangeLabel = `${startDate.getDate()} ${startDate.toLocaleDateString('ru-RU',{month:'short'})} – ${endDate.getDate()} ${endDate.toLocaleDateString('ru-RU',{month:'short'})} ${endDate.getFullYear()}`;

    const rangeEl = document.getElementById('week-range-label');
    if (rangeEl) rangeEl.textContent = rangeLabel;
    const weekNavLabel = document.querySelector('.week-nav .label');
    if (weekNavLabel) weekNavLabel.textContent = rangeLabel;

    // Head stats
    const stats = document.querySelectorAll('.sched-head-stats .mini-stat .num');
    if (stats.length >= 3) {
        stats[0].textContent = data.stats.total_lessons;
        stats[1].textContent = data.stats.total_hours;
        stats[2].textContent = data.stats.completed;
    }

    // Day headers (grid-column 2..7)
    document.querySelectorAll('.day-head').forEach((el, i) => {
        const d = new Date(startDate);
        d.setDate(d.getDate() + i);
        const isToday = d.toDateString() === new Date().toDateString();
        el.classList.toggle('today', isToday);
        el.querySelector('.dow').textContent = DOW_LABELS[i];
        el.querySelector('.date').textContent = d.getDate();
    });

    // Clear old events + hour rows, rebuild background grid
    document.querySelectorAll('.event').forEach(e => e.remove());
    document.querySelectorAll('.time-cell, .day-col-bg').forEach(e => e.remove());

    const grid = document.querySelector('.schedule-grid');
    SCHED_HOURS.forEach((hour, rowIdx) => {
        const row = rowIdx + 2; // row 1 = day headers
        const timeCell = document.createElement('div');
        timeCell.className = 'time-cell';
        timeCell.style.gridRow = row;
        timeCell.textContent = `${hour}:00`;
        grid.appendChild(timeCell);

        for (let col = 2; col <= 7; col++) {
            const bg = document.createElement('div');
            bg.className = 'day-col-bg';
            bg.style.gridRow = row;
            bg.style.gridColumn = col;
            grid.appendChild(bg);
        }
    });

    // Place lessons
    data.lessons.forEach(lesson => {
        const dt = new Date(lesson.scheduled_at);
        const dayIdx = (dt.getDay() + 6) % 7; // Mon=0
        if (dayIdx > 5) return; // schedule only shows Mon-Sat
        const col = dayIdx + 2;
        const startHour = dt.getHours() + dt.getMinutes() / 60;
        const hourIdx = SCHED_HOURS.findIndex(h => h === Math.floor(startHour));
        if (hourIdx === -1) return;
        const row = hourIdx + 2;
        const span = Math.max(1, Math.round(lesson.duration_minutes / 60));

        const ev = document.createElement('div');
        ev.className = 'event';
        ev.style.gridColumn = col;
        ev.style.gridRow = `${row} / span ${span}`;
        ev.style.setProperty('--event-color', lesson.color_code || '#8A15EA');
        ev.innerHTML = `
            <span class="title">${escapeHtml(lesson.subject_name)}</span>
            <span class="teacher">${escapeHtml(lesson.teacher_name || '')}</span>
            <span class="badge">Вебинар</span>
        `;
        grid.appendChild(ev);
    });
}

// Week navigation
function shiftWeek(days) {
    if (!currentWeekStart) return;
    const d = new Date(currentWeekStart + 'T00:00:00');
    d.setDate(d.getDate() + days);
    loadSchedule(d.toISOString().slice(0, 10));
}

document.addEventListener('DOMContentLoaded', function() {
    const arrows = document.querySelectorAll('.nav-arrow');
    if (arrows.length === 2) {
        arrows[0].addEventListener('click', () => shiftWeek(-7));
        arrows[1].addEventListener('click', () => shiftWeek(7));
    }
});

// Вызываем после загрузки DOM
document.addEventListener('DOMContentLoaded', function() {
});

// =============================================
// ЭКСПОРТ
// =============================================
// В браузере все функции доступны глобально через window
// Для модулей можно использовать export


