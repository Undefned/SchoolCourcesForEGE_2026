// =============================================
// API_BASE
// =============================================
const API_BASE = (() => {
  const path = window.location.pathname;
  const dir = path.replace(/\/[^\/]*$/, '/');
  const root = dir.includes('/pages/') ? dir.replace(/\/pages\/$/, '/') : dir;
  return root + 'api';
})();

console.log('API_BASE =', API_BASE);

// =============================================
// БАЗОВЫЙ ФЕТЧ
// =============================================
async function fetchApi(endpoint, options = {}) {
  let path  = endpoint;
  let query = '';
  const qIdx = endpoint.indexOf('?');
  if (qIdx !== -1) {
    path  = endpoint.slice(0, qIdx);
    query = endpoint.slice(qIdx);
  }
  if (!path.endsWith('.php')) {
    path = path + '.php';
  }
  const url = `${API_BASE}${path}${query}`;

  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  const token = document.cookie
    .split('; ')
    .find(row => row.startsWith('session_token='))
    ?.split('=')[1];

  if (token) headers['Authorization'] = `Bearer ${token}`;

  const response = await fetch(url, {
    credentials: 'same-origin',
    headers,
    ...options,
  });

  const raw = await response.text();
  const contentType = (response.headers.get('content-type') || '').toLowerCase();
  const looksLikeJson = contentType.includes('application/json');

  let data = null;
  if (raw && raw.length > 0) {
    if (looksLikeJson) {
      try {
        data = JSON.parse(raw);
      } catch (e) {
        throw new Error(`Сервер вернул некорректный JSON (${response.status}): ` + raw.slice(0, 120));
      }
    } else {
      const short = raw.replace(/\s+/g, ' ').trim().slice(0, 200);
      if (response.status === 404) {
        throw new Error(`API не найден: ${url}. Ответ: ${short}`);
      }
      if (response.status === 405) {
        throw new Error(`Метод ${options.method || 'GET'} не разрешён. Ответ: ${short}`);
      }
      throw new Error(`Сервер вернул не-JSON (${response.status}). Ответ: ${short}`);
    }
  }

  if (!response.ok) {
    const msg = (data && data.error && data.error.message) || `Ошибка ${response.status}`;
    throw new Error(msg);
  }
  if (!data || data.ok === false) {
    const msg = (data && data.error && data.error.message) || 'Неизвестная ошибка API';
    throw new Error(msg);
  }
  return data.data;
}

// =============================================
// АВТОРИЗАЦИЯ
// =============================================
async function login(email, password) {
    return fetchApi('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) });
}
async function register(email, password, fullName, grade) {
    return fetchApi('/auth/register', { method: 'POST', body: JSON.stringify({ email, password, fullName, grade }) });
}
async function logout() {
    return fetchApi('/auth/logout', { method: 'POST' });
}
async function getCurrentUser() {
    return fetchApi('/auth/me');
}

// =============================================
// МАТЕРИАЛЫ
// =============================================
async function getMaterials(filters = {}) {
    const params = new URLSearchParams();
    if (filters.subject) params.append('subject', filters.subject);
    if (filters.type)    params.append('type', filters.type);
    if (filters.search)  params.append('search', filters.search);
    if (filters.limit)   params.append('limit', filters.limit);
    if (filters.offset)  params.append('offset', filters.offset);
    return fetchApi('/materials' + (params.toString() ? '?' + params.toString() : ''));
}
async function viewMaterial(materialId) {
    return fetchApi('/materials/view', { method: 'POST', body: JSON.stringify({ materialId }) });
}

// =============================================
// ЗАДАНИЯ
// =============================================
async function getAssignments(filters = {}) {
    const params = new URLSearchParams();
    if (filters.subject) params.append('subject', filters.subject);
    if (filters.status)  params.append('status', filters.status);
    if (filters.sort)    params.append('sort', filters.sort);
    if (filters.order)   params.append('order', filters.order);
    return fetchApi('/assignments' + (params.toString() ? '?' + params.toString() : ''));
}

async function startAssignment({ assignmentId = null, materialId = null }) {
    return fetchApi('/assignments', {
        method: 'POST',
        body: JSON.stringify({ assignmentId, materialId, action: 'start' }),
    });
}

async function completeAssignment({ assignmentId = null, materialId = null }) {
    return fetchApi('/assignments', {
        method: 'POST',
        body: JSON.stringify({ assignmentId, materialId, action: 'complete' }),
    });
}

// =============================================
// ПОДДЕРЖКА
// =============================================
async function getSupportMessages() {
    return fetchApi('/support');
}
async function sendSupportMessage(message) {
    return fetchApi('/support', { method: 'POST', body: JSON.stringify({ message }) });
}

// =============================================
// ЗАЯВКИ
// =============================================
async function sendApplication(data) {
    const payload = {
        email:    data.email    || null,
        fullName: data.fullName,
        grade:    data.grade,
        subject:  data.subject  || null,
        message:  data.message  || null,
        phone:    data.phone    || null,
        source:   data.source   || 'landing',
    };
    return fetchApi('/applications', { method: 'POST', body: JSON.stringify(payload) });
}

// =============================================
// ПОЛЬЗОВАТЕЛЬ
// =============================================
async function getUserProfile() {
    return fetchApi('/user');
}
async function updateUserProfile(data) {
    return fetchApi('/user', { method: 'PUT', body: JSON.stringify(data) });
}

// =============================================
// ХЕЛПЕРЫ
// =============================================
function formatDate(dateStr) {
    if (!dateStr) return '—';
    const d = new Date(dateStr);
    return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' });
}
function formatTime(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
}
function getAssignmentStatusText(status) {
    const map = {
        'not_started': 'Не начато',
        'in_progress': 'В процессе',
        'submitted':   'На проверке',
        'graded':      'Проверено',
    };
    return map[status] || 'Не начато';
}
function getAssignmentStatusClass(status) {
    const map = {
        'not_started': 'status-none',
        'in_progress': 'status-progress',
        'submitted':   'status-progress',
        'graded':      'status-done',
    };
    return map[status] || 'status-none';
}
function getMaterialTypeText(type) {
    const map = { 'conspect': 'Конспект', 'test': 'Тест', 'task': 'Задания', 'video': 'Видео' };
    return map[type] || type;
}
function getMaterialTypeClass(type) {
    const map = { 'conspect': 'type-default', 'test': 'type-test', 'task': 'type-task', 'video': 'type-video' };
    return map[type] || 'type-default';
}
function getMaterialTypeIcon(type) {
    const map = { 'conspect': '📄', 'test': '✅', 'task': '📝', 'video': '▶' };
    return map[type] || '📄';
}
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

// =============================================
// ЭКСПОРТ В WINDOW
// =============================================
Object.assign(window, {
    fetchApi, login, register, logout, getCurrentUser,
    getMaterials, viewMaterial,
    getAssignments, startAssignment, completeAssignment,
    getSupportMessages, sendSupportMessage,
    sendApplication,
    getUserProfile, updateUserProfile,
    formatDate, formatTime,
    getAssignmentStatusText, getAssignmentStatusClass,
    getMaterialTypeText, getMaterialTypeClass, getMaterialTypeIcon,
    escapeHtml,
});

// =============================================
// HEADER: аватар + баллы или кнопка «Записаться»
// =============================================
const GUEST_AVATAR = (() => {
    // путь к profile.svg относительно текущей страницы
    const inPages = window.location.pathname.includes('/pages/');
    return inPages ? '../assets/profile.svg' : 'assets/profile.svg';
})();

const AUTH_AVATAR_DEFAULT = (() => {
    const inPages = window.location.pathname.includes('/pages/');
    return inPages ? '../assets/Avatar.png' : 'assets/Avatar.png';
})();

async function initHeader() {
    const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('session_token='));
    const isAuth = !!token;

    // ---- Аватарки во всех местах ----
    const avatars = document.querySelectorAll('img[data-header-avatar], .nav-avatar img, .app-nav .avatar');
    avatars.forEach(img => {
        if (!isAuth) {
            img.src = GUEST_AVATAR;
            img.alt = 'Войти';
        } else {
            // Заменим на аватар пользователя, если бэк его отдал
            img.src = img.dataset.userAvatar || AUTH_AVATAR_DEFAULT;
        }
    });

    // Ссылки на аватар
    document.querySelectorAll('a.nav-avatar').forEach(a => {
        a.href = isAuth ? 'dashboard.html' : 'login.html';
        a.title = isAuth ? 'Личный кабинет' : 'Войти';
    });

    // ---- Баллы в шапке / кнопка «Записаться» ----
    const scoreBadges = document.querySelectorAll('#headerScore, .score-badge[data-dynamic]');
    scoreBadges.forEach(el => {
        if (!isAuth) {
            el.textContent = '';
            el.style.display = 'none';
        }
    });

    // Если не залогинен — подменяем .score-badge на «Записаться»
    if (!isAuth) {
        document.querySelectorAll('.app-nav-actions').forEach(actions => {
            const hasScore = actions.querySelector('.score-badge');
            if (!hasScore) return;
            // Уже есть кнопка? не дублируем
            if (actions.querySelector('.header-join-btn')) return;
            const btn = document.createElement('a');
            btn.href = 'login.html';
            btn.className = 'header-join-btn btn-primary btn-pill';
            btn.textContent = 'Записаться';
            actions.insertBefore(btn, hasScore);
        });
    } else {
        // Залогинен — тянем avg_score
        try {
            const me = await getCurrentUser();
            const avg = me && me.stats ? me.stats.avg_score : null;
            if (avg != null && !isNaN(Number(avg))) {
                scoreBadges.forEach(el => {
                    el.textContent = `${Math.round(Number(avg))} баллов`;
                });
            }
        } catch (_) { /* ignore */ }
    }

    // ---- Мобильное меню: ссылка «Личный кабинет» vs «Войти» ----
    document.querySelectorAll('.mobile-avatar').forEach(el => {
        if (!isAuth) {
            el.textContent = 'Войти';
            el.href = 'login.html';
        } else {
            el.textContent = 'Личный кабинет';
            el.href = 'dashboard.html';
        }
    });
}

// =============================================
// МОДАЛКА МАТЕРИАЛА / ЗАДАНИЯ
// =============================================
let _currentModalMaterial = null;

function ensureMaterialModal() {
    let modal = document.getElementById('materialModal');
    if (modal) return modal;

    modal = document.createElement('dialog');
    modal.id = 'materialModal';
    modal.className = 'material-modal';
    modal.innerHTML = `
        <div class="material-modal__header">
            <h3 class="material-modal__title" id="materialModalTitle">Материал</h3>
            <button type="button" class="material-modal__close" id="materialModalClose" aria-label="Закрыть">✕</button>
        </div>
        <div class="material-modal__body" id="materialModalBody"></div>
        <div class="material-modal__footer" id="materialModalFooter"></div>
    `;
    document.body.appendChild(modal);

    modal.querySelector('#materialModalClose').addEventListener('click', () => modal.close());
    modal.addEventListener('click', (e) => {
        const rect = modal.getBoundingClientRect();
        const inDialog = e.clientX >= rect.left && e.clientX <= rect.right
                      && e.clientY >= rect.top  && e.clientY <= rect.bottom;
        if (!inDialog) modal.close();
    });
    modal.addEventListener('close', () => {
        _currentModalMaterial = null;
        setTimeout(() => {
            if (!modal.open) modal.remove();
        }, 0);
    });
    return modal;
}

function renderMaterialBody(material) {
    const type = material.type;
    const content = material.content || '';

    if (type === 'video') {
        let src = content.trim();
        const ytMatch = src.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]{6,})/);
        if (ytMatch) src = `https://www.youtube.com/embed/${ytMatch[1]}`;
        return `<div class="material-modal__video"><iframe src="${escapeHtml(src)}" allowfullscreen frameborder="0"></iframe></div>`;
    }
    if (type === 'conspect') {
        return `<div class="material-modal__conspect">${content || '<p>Конспект в разработке.</p>'}</div>`;
    }
    return `
        <div class="material-modal__task">
            <p>${escapeHtml(material.description || 'Описание задания отсутствует.')}</p>
            ${content ? `<div class="material-modal__task-content">${content}</div>` : ''}
        </div>
    `;
}

function renderMaterialFooter(material, onComplete) {
    const footer = document.getElementById('materialModalFooter');
    footer.innerHTML = '';

    if (material.type === 'conspect' || material.type === 'video') {
        footer.innerHTML = `<span class="material-modal__hint">Этот материал доступен без задания</span>`;
        return;
    }

    if (material.is_completed) {
        footer.innerHTML = `
            <div class="material-modal__done">
                <span class="material-modal__done-check">✓</span>
                Выполнено${material.user_score != null ? ` · ${material.user_score} баллов` : ''}
            </div>
        `;
        return;
    }

    const btn = document.createElement('button');
    btn.className = 'btn-primary';
    btn.textContent = 'Выполнить';
    btn.addEventListener('click', async () => {
        btn.disabled = true;
        btn.textContent = 'Выполняется...';
        try {
            await onComplete();
        } catch (err) {
            btn.disabled = false;
            btn.textContent = 'Выполнить';
            alert('Не удалось выполнить: ' + err.message);
        }
    });
    footer.appendChild(btn);
}

async function openMaterial(materialId, opts = {}) {
    // Если не залогинен — редирект на логин
    const token = document.cookie.split('; ').find(r => r.startsWith('session_token='));
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    let material = null;
    try {
        material = (window.__cachedMaterials || []).find(m => m.id === materialId);
        if (!material) {
            const data = await getMaterials({ limit: 100 });
            material = (data.items || []).find(m => m.id === materialId);
        }
    } catch (err) {
        alert('Не удалось загрузить материал: ' + err.message);
        return;
    }
    if (!material) {
        alert('Материал не найден');
        return;
    }

    _currentModalMaterial = material;

    const modal = ensureMaterialModal();
    modal.querySelector('#materialModalTitle').textContent = material.title || 'Материал';
    modal.querySelector('#materialModalBody').innerHTML = renderMaterialBody(material);

    renderMaterialFooter(material, async () => {
        const result = await completeAssignment({ materialId });
        material.is_completed = true;
        material.user_score = result.score;
        material.assignment_id = result.assignmentId;

        const card = document.querySelector(`.material-card[data-material-id="${materialId}"]`);
        if (card) {
            card.classList.add('material-card--done');
            const badge = card.querySelector('.material-card__score');
            if (badge) {
                badge.textContent = `✓ ${result.score}`;
                badge.style.display = 'inline-block';
            }
        }

        renderMaterialFooter(material, () => {});

        const headerScore = document.getElementById('headerScore');
        if (headerScore && result.avgScore != null) {
            headerScore.textContent = `${result.avgScore} баллов`;
        }

        const footer = document.getElementById('materialModalFooter');
        const ok = document.createElement('div');
        ok.className = 'material-modal__success';
        ok.textContent = `Задание выполнено! +${result.score} баллов`;
        footer.appendChild(ok);
    });

    modal.showModal();

    if (!material.is_viewed) {
        try { await viewMaterial(materialId); } catch (_) {}
        material.is_viewed = true;
    }
}

async function openAssignment(assignment, opts = {}) {
    if (assignment.material_id) {
        return openMaterial(assignment.material_id, { assignmentId: assignment.id });
    }

    _currentModalMaterial = { type: 'task', title: assignment.title, description: assignment.description };

    const modal = ensureMaterialModal();
    modal.querySelector('#materialModalTitle').textContent = assignment.title || 'Задание';
    modal.querySelector('#materialModalBody').innerHTML = `
        <div class="material-modal__task">
            <p>${escapeHtml(assignment.description || 'Описание задания отсутствует.')}</p>
            <p class="material-modal__hint">Предмет: <b>${escapeHtml(assignment.subject_name || '—')}</b></p>
            <p class="material-modal__hint">Дедлайн: <b>${formatDate(assignment.due_date)}</b></p>
        </div>
    `;

    renderMaterialFooter(
        { type: 'task', is_completed: assignment.submission_status === 'graded', user_score: assignment.score },
        async () => {
            const result = await completeAssignment({ assignmentId: assignment.id });

            const row = document.querySelector(`tr[data-assignment-id="${assignment.id}"]`);
            if (row) {
                const statusCell = row.querySelector('[data-cell="status"]');
                if (statusCell) {
                    statusCell.innerHTML = `<span class="status-pill status-done">${getAssignmentStatusText('graded')}</span>`;
                }
                const scoreCell = row.querySelector('[data-cell="score"]');
                if (scoreCell) scoreCell.textContent = result.score;
            }

            const headerScore = document.getElementById('headerScore');
            if (headerScore && result.avgScore != null) {
                headerScore.textContent = `${result.avgScore} баллов`;
            }

            renderMaterialFooter(
                { type: 'task', is_completed: true, user_score: result.score },
                () => {}
            );

            const footer = document.getElementById('materialModalFooter');
            const ok = document.createElement('div');
            ok.className = 'material-modal__success';
            ok.textContent = `Задание выполнено! +${result.score} баллов`;
            footer.appendChild(ok);
        }
    );

    modal.showModal();
}

Object.assign(window, { openMaterial, openAssignment });

// =============================================
// DASHBOARD
// =============================================
async function loadDashboard() {
    try {
        const user = await getCurrentUser();
        if (!user) { window.location.href = 'login.html'; return; }
    } catch (err) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const data = await getUserProfile();
        renderDashboard(data);
    } catch (err) {
        console.error('Ошибка загрузки дашборда:', err);
    }
}

function renderDashboard(data) {
    const { profile = {}, subjects = [], assignments = [] } = data || {};

    const nameEl = document.getElementById('profileName');
    const emailEl = document.getElementById('profileEmail');
    const avatarEl = document.getElementById('profileAvatar');
    if (nameEl) nameEl.textContent = profile.full_name || 'Пользователь';
    if (emailEl) emailEl.textContent = profile.email || '—';
    if (avatarEl) {
        avatarEl.src = (profile.avatar_url && profile.avatar_url !== '/uploads/avatars/default.png')
            ? profile.avatar_url
            : AUTH_AVATAR_DEFAULT;
    }

    const headerScore = document.getElementById('headerScore');
    if (headerScore) {
        const avg = Math.round(profile.avg_score || 0);
        headerScore.textContent = avg > 0 ? `${avg} баллов` : '—';
    }

    const statLessons = document.getElementById('statLessons');
    const statScore = document.getElementById('statScore');
    const statStreak = document.getElementById('statStreak');
    if (statLessons) statLessons.textContent = profile.total_assignments_completed || 0;
    if (statScore)   statScore.textContent   = Math.round(profile.avg_score || 0);
    if (statStreak) statStreak.textContent = profile.streak_days != null ? profile.streak_days : 0;

    const subjectList = document.getElementById('subjectList');
    if (subjectList) {
        if (subjects.length) {
            subjectList.innerHTML = subjects.map(s => `
                <div class="subject-row">
                    <div class="left">
                        <div class="ring" style="--pct:${s.progress || 0};--ring-color:${s.color_code || '#8A15EA'}" data-pct="${s.progress || 0}"></div>
                        <div>
                            <div class="name">${escapeHtml(s.name || 'Без названия')}</div>
                            <div class="activity">Цель: ${s.target_score || 0} баллов</div>
                        </div>
                    </div>
                    <button class="btn-primary btn-continue" onclick="window.location.href='knowledge-base.html?subject=${encodeURIComponent(s.slug || '')}'">Продолжить</button>
                </div>
            `).join('');
        } else {
            subjectList.innerHTML = `<div class="empty-state"><span class="icon">📚</span><p>Вы пока не добавили ни одного предмета</p></div>`;
        }
    }

    const weeklyBars = document.getElementById('weeklyBars');
    if (weeklyBars) {
        const activity = data.activity || [];
        const maxTasks = Math.max(1, ...activity.map(a => Number(a.tasks) || 0));
        const DOW_SHORT = ['Вс','Пн','Вт','Ср','Чт','Пт','Сб'];

        if (activity.length === 0) {
            weeklyBars.innerHTML = '<span class="muted" style="color:#6B6B7A;font-size:13px;">Нет активности за последние 7 дней</span>';
        } else {
            weeklyBars.innerHTML = activity.map(a => {
                const d = new Date(a.day + 'T00:00:00');
                const dayLabel = DOW_SHORT[d.getDay()];
                const tasks = Number(a.tasks) || 0;
                const height = tasks > 0 ? Math.round((tasks / maxTasks) * 140) : 8;
                const color = tasks > 0 ? '#75EA15' : '#4E4E5E';
                return `
                    <div class="bar-col">
                        <div class="bar" style="height:${height}px;background:${color};" title="${tasks} заданий"></div>
                        <span class="day">${dayLabel}</span>
                    </div>
                `;
            }).join('');
        }
    }

    const tbody = document.getElementById('assignmentsBody');
    if (tbody) {
        if (assignments.length) {
            const today = new Date();
            tbody.innerHTML = assignments.map(a => {
                const due = new Date(a.due_date);
                const isUrgent = (due - today) < 86400000 * 2;
                const status = a.status || a.submission_status || 'not_started';
                const statusText = getAssignmentStatusText(status);
                const statusClass = getAssignmentStatusClass(status);
                const score = a.score != null ? a.score : '—';

                return `
                    <tr data-assignment-id="${a.id}">
                        <td class="assign-name">${escapeHtml(a.title || 'Без названия')}</td>
                        <td class="assign-subject">${escapeHtml(a.subject_name || '—')}</td>
                        <td data-cell="status"><span class="status-pill ${statusClass}">${statusText}</span></td>
                        <td class="${isUrgent ? 'deadline-urgent' : 'deadline-normal'}">${formatDate(a.due_date)}</td>
                        <td data-cell="score">${score}</td>
                    </tr>
                `;
            }).join('');

            tbody.querySelectorAll('tr[data-assignment-id]').forEach(row => {
                row.style.cursor = 'pointer';
                row.addEventListener('click', () => {
                    const id = Number(row.dataset.assignmentId);
                    const assignment = assignments.find(a => a.id === id);
                    if (assignment) openAssignment(assignment);
                });
            });
        } else {
            tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:40px;color:var(--main-text);">🎉 Нет заданий на эту неделю</td></tr>`;
        }
    }
}

// =============================================
// KNOWLEDGE BASE
// =============================================
async function loadKnowledgeBase(filters = {}) {
    try {
        const data = await getMaterials(filters);
        window.__cachedMaterials = data.items || [];
        renderKnowledgeBase(data, filters);
    } catch (err) {
        console.error('Ошибка загрузки материалов:', err);
        const container = document.querySelector('.kb');
        if (container) {
            const errEl = document.createElement('div');
            errEl.className = 'kb__error';
            errEl.textContent = 'Не удалось загрузить материалы: ' + err.message;
            container.prepend(errEl);
        }
    }
}

function renderKnowledgeBase(data, filters = {}) {
    const { items = [], stats = {} } = data;

    // Статы в шапке
    const statNums = document.querySelectorAll('.kb-head-stats .mini-stat .num');
    if (statNums.length >= 3) {
        statNums[0].textContent = stats.total_materials || 0;
        statNums[1].textContent = stats.total_subjects  || 0;
        statNums[2].textContent = stats.total_viewed    || 0;
    }

    // ---- Сортировка ----
    // Значение select#kbSort: date_desc, date_asc, title_asc, title_desc
    const sort = filters.sort || 'default';
    let sortedItems = items.slice();
    if (sort === 'title_asc') {
        sortedItems.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
    } else if (sort === 'title_desc') {
        sortedItems.sort((a, b) => (b.title || '').localeCompare(a.title || ''));
    } else if (sort === 'duration_asc') {
        sortedItems.sort((a, b) => (a.duration_minutes || 0) - (b.duration_minutes || 0));
    } else if (sort === 'duration_desc') {
        sortedItems.sort((a, b) => (b.duration_minutes || 0) - (a.duration_minutes || 0));
    }

    // Группируем по slug предмета (сохраняем порядок появления)
    const bySubject = new Map();
    for (const m of sortedItems) {
        const key = m.subject_slug || 'other';
        if (!bySubject.has(key)) {
            bySubject.set(key, {
                slug: key,
                name: m.subject_name,
                color: m.color_code || '#8A15EA',
                items: [],
            });
        }
        bySubject.get(key).items.push(m);
    }

    const container = document.querySelector('.kb');
    if (!container) return;

    // Удаляем все .subject-section и всё, что мы сами добавляли
    container.querySelectorAll('.subject-section, .kb__error').forEach(el => el.remove());

    // Если ничего нет — сообщение
    if (bySubject.size === 0) {
        const empty = document.createElement('div');
        empty.className = 'kb__error';
        empty.textContent = 'Ничего не найдено по заданным фильтрам.';
        container.appendChild(empty);
        return;
    }

    for (const section of bySubject.values()) {
        const sec = document.createElement('div');
        sec.className = 'subject-section';
        sec.dataset.subject = section.slug;
        sec.innerHTML = `
            <div class="subject-header">
                <div class="left">
                    <span class="subject-dot" style="background:${section.color}"></span>
                    <h3>${escapeHtml(section.name)}</h3>
                    <span class="count-pill">${section.items.length} ${pluralize(section.items.length, ['материал','материала','материалов'])}</span>
                </div>
            </div>
            <div class="material-grid"></div>
        `;
        const grid = sec.querySelector('.material-grid');
        grid.innerHTML = section.items.map(m => materialCardHTML(m)).join('');
        container.appendChild(sec);
    }

    // Делегируем клики
    if (!container.dataset.bound) {
        container.dataset.bound = '1';
        container.addEventListener('click', (e) => {
            const card = e.target.closest('.material-card');
            if (!card) return;
            const id = Number(card.dataset.materialId);
            if (id) openMaterial(id);
        });
    }
}

function pluralize(n, forms) {
    const a = Math.abs(n) % 100;
    const b = a % 10;
    if (a > 10 && a < 20) return forms[2];
    if (b > 1 && b < 5) return forms[1];
    if (b === 1) return forms[0];
    return forms[2];
}

function materialCardHTML(m) {
    const typeClass = getMaterialTypeClass(m.type);
    const typeIcon  = getMaterialTypeIcon(m.type);
    const typeText  = getMaterialTypeText(m.type);
    const isDone    = !!m.is_completed;
    const score     = m.user_score;

    return `
        <article class="material-card ${isDone ? 'material-card--done' : ''}" data-material-id="${m.id}">
            <div class="material-card__top">
                <span class="type-badge ${typeClass}">
                    <span class="icon">${typeIcon}</span>${typeText}
                </span>
                ${isDone ? `<span class="material-card__score">✓ ${score ?? ''}</span>` : `<span class="material-card__score" style="display:none;"></span>`}
            </div>
            <div class="material-title">${escapeHtml(m.title)}</div>
            <div class="material-tag">
                <span class="dot" style="background:${m.color_code || '#8A15EA'}"></span>
                <span>${escapeHtml(m.subject_name || '')}</span>
            </div>
            <div class="material-meta">
                <span>${m.task_count || 0} заданий</span>
                <span>${m.duration_minutes || 30} мин</span>
            </div>
            <button class="btn-soft" type="button">Открыть</button>
        </article>
    `;
}

// =============================================
// SUPPORT
// =============================================
async function initSupport() {
    const chatBody = document.querySelector('.chat-body');
    const chatForm = document.querySelector('.chat-input-row');
    if (!chatBody || !chatForm) return;

    try {
        const messages = await getSupportMessages();
        renderSupportMessages(messages, chatBody);
    } catch (err) {
        console.error('Ошибка загрузки чата:', err);
    }

    if (chatForm.dataset.bound === '1') return;
    chatForm.dataset.bound = '1';

    chatForm.addEventListener('submit', async function (e) {
        e.preventDefault();
        const input = this.querySelector('input');
        const text = input.value.trim();
        if (!text) return;

        // Если не залогинен — ведём на вход
        const token = document.cookie.split('; ').find(r => r.startsWith('session_token='));
        if (!token) {
            window.location.href = 'login.html';
            return;
        }

        try {
            await sendSupportMessage(text);
            input.value = '';
            const messages = await getSupportMessages();
            renderSupportMessages(messages, chatBody);
        } catch (err) {
            alert('Не удалось отправить сообщение: ' + err.message);
        }
    });
}

function renderSupportMessages(messages, container) {
    if (!Array.isArray(messages) || !messages.length) {
        container.innerHTML = `
            <div class="msg">
                <div class="bubble">Здравствуйте! Чем я могу вам помочь?</div>
                <span class="time">${new Date().toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
        `;
        return;
    }
    container.innerHTML = messages.map(msg => {
        const isSupport = !!msg.is_from_support;
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
// SCHEDULE
// =============================================
let currentWeekStart = null;
const SCHED_HOURS = [9,10,11,12,13,14,15,16,17,18];
const DOW_LABELS = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];

async function loadSchedule(weekStart) {
    try {
        const params = new URLSearchParams();
        if (weekStart) params.append('week', weekStart);
        const data = await fetchApi('/schedule' + (params.toString() ? '?' + params.toString() : ''));
        renderSchedule(data);
    } catch (err) {
        console.error('Ошибка загрузки расписания:', err);
    }
}

function renderSchedule(data) {
    currentWeekStart = data.weekStart;
    const startDate = new Date(data.weekStart + 'T00:00:00');
    const endDate = new Date(data.weekEnd + 'T00:00:00');
    const rangeLabel = `${startDate.getDate()} ${startDate.toLocaleDateString('ru-RU',{month:'short'})} – ${endDate.getDate()} ${endDate.toLocaleDateString('ru-RU',{month:'short'})} ${endDate.getFullYear()}`;

    const rangeEl = document.getElementById('week-range-label');
    if (rangeEl) rangeEl.textContent = rangeLabel;
    const weekNavLabel = document.querySelector('.week-nav .label');
    if (weekNavLabel) weekNavLabel.textContent = rangeLabel;

    const stats = document.querySelectorAll('.sched-head-stats .mini-stat .num');
    if (stats.length >= 3) {
        stats[0].textContent = data.stats.total_lessons;
        stats[1].textContent = data.stats.total_hours;
        stats[2].textContent = data.stats.completed;
    }

    // DESKTOP
    document.querySelectorAll('.day-head').forEach((el, i) => {
        const d = new Date(startDate);
        d.setDate(d.getDate() + i);
        el.classList.toggle('today', d.toDateString() === new Date().toDateString());
        const dowEl = el.querySelector('.dow'); const dateEl = el.querySelector('.date');
        if (dowEl)  dowEl.textContent  = DOW_LABELS[i];
        if (dateEl) dateEl.textContent = d.getDate();
    });

    document.querySelectorAll('.event').forEach(e => e.remove());
    document.querySelectorAll('.time-cell, .day-col-bg').forEach(e => e.remove());

    const grid = document.querySelector('.schedule-grid');
    if (grid) {
        SCHED_HOURS.forEach((hour, rowIdx) => {
            const row = rowIdx + 2;
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

        (data.lessons || []).forEach(lesson => {
            const dt = new Date(lesson.scheduled_at);
            const dayIdx = (dt.getDay() + 6) % 7;
            if (dayIdx > 5) return;
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
                <span class="title">${escapeHtml(lesson.title || lesson.subject_name)}</span>
                <span class="teacher">${escapeHtml(lesson.teacher_name || '')}</span>
                <span class="badge">Вебинар</span>
            `;
            grid.appendChild(ev);
        });
    }

    // MOBILE
    renderMobileSchedule(startDate, data.lessons || []);
}

function renderMobileSchedule(startDate, lessons) {
    const picker = document.querySelector('.day-picker');
    const agenda = document.querySelector('.day-agenda');
    if (!picker || !agenda) return;

    const DOW_SHORT = ['Пн','Вт','Ср','Чт','Пт','Сб'];

    const byDay = { 0:[], 1:[], 2:[], 3:[], 4:[], 5:[] };
    lessons.forEach(lesson => {
        const dt = new Date(lesson.scheduled_at);
        const dayIdx = (dt.getDay() + 6) % 7;
        if (dayIdx > 5) return;
        byDay[dayIdx].push(lesson);
    });

    const today = new Date();
    let activeDay = (today.getDay() + 6) % 7;
    const todayStr = today.toDateString();
    const rangeStartStr = startDate.toDateString();
    const rangeEnd = new Date(startDate);
    rangeEnd.setDate(rangeEnd.getDate() + 5);
    if (todayStr < rangeStartStr || todayStr > rangeEnd.toDateString()) {
        activeDay = 0;
    }
    if (activeDay > 5) activeDay = 0;

    picker.innerHTML = DOW_SHORT.map((dow, i) => {
        const d = new Date(startDate);
        d.setDate(d.getDate() + i);
        const isActive = i === activeDay;
        return `
            <button class="day-tab ${isActive ? 'active' : ''}" data-day="${i}">
                <span class="dow">${dow}</span>
                <span class="date">${d.getDate()}</span>
            </button>
        `;
    }).join('');

    const MONTHS = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
    const FULL_DOW = ['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота'];

    agenda.innerHTML = DOW_SHORT.map((_, i) => {
        const d = new Date(startDate);
        d.setDate(d.getDate() + i);
        const isActive = i === activeDay;
        const dayLessons = byDay[i].slice().sort((a, b) => new Date(a.scheduled_at) - new Date(b.scheduled_at));
        const countLabel = dayLessons.length === 0
            ? 'нет занятий'
            : `${dayLessons.length} ${pluralize(dayLessons.length, ['занятие','занятия','занятий'])}`;
        const dateTitle = `${FULL_DOW[i]}, ${d.getDate()} ${MONTHS[d.getMonth()]}`;

        const cards = dayLessons.length === 0
            ? `<div class="day-agenda-empty">На этот день занятий нет</div>`
            : dayLessons.map(lesson => {
                const dt = new Date(lesson.scheduled_at);
                const timeStart = dt.toLocaleTimeString('ru-RU', {hour:'2-digit', minute:'2-digit'});
                const endDt = new Date(dt.getTime() + (lesson.duration_minutes || 60) * 60000);
                const timeEnd = endDt.toLocaleTimeString('ru-RU', {hour:'2-digit', minute:'2-digit'});
                const color = lesson.color_code || '#8A15EA';
                const type = lesson.lesson_type || 'webinar';
                const typeLabel = {
                    webinar: 'Вебинар', practice: 'Практика',
                    lecture: 'Лекция', consultation: 'Консультация'
                }[type] || 'Вебинар';
                return `
                    <div class="day-event-card" style="--event-color:${color};">
                        <div class="row">
                            <span class="time">${timeStart} — ${timeEnd}</span>
                            <span class="badge">${typeLabel}</span>
                        </div>
                        <div class="subject">${escapeHtml(lesson.title || lesson.subject_name || '')}</div>
                        <div class="teacher">${escapeHtml(lesson.teacher_name || '')}</div>
                    </div>
                `;
            }).join('');

        return `
            <div class="day-agenda-panel ${isActive ? 'active' : ''}" data-day="${i}">
                <div class="day-agenda-head">
                    <span class="date-title">${dateTitle}</span>
                    <span class="day-agenda-count">${countLabel}</span>
                </div>
                ${cards}
            </div>
        `;
    }).join('');

    picker.querySelectorAll('.day-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            const day = Number(tab.dataset.day);
            picker.querySelectorAll('.day-tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            agenda.querySelectorAll('.day-agenda-panel').forEach(p => {
                p.classList.toggle('active', Number(p.dataset.day) === day);
            });
        });
    });
}

function shiftWeek(days) {
    if (!currentWeekStart) return;
    const d = new Date(currentWeekStart + 'T00:00:00');
    d.setDate(d.getDate() + days);
    loadSchedule(d.toISOString().slice(0, 10));
}

Object.assign(window, {
    loadDashboard, renderDashboard,
    loadKnowledgeBase, renderKnowledgeBase,
    openMaterial, openAssignment,
    initSupport, renderSupportMessages,
    loadSchedule, renderSchedule, shiftWeek,
    initHeader,
});

// =============================================
// ИНИЦИАЛИЗАЦИЯ
// =============================================
document.addEventListener('DOMContentLoaded', function () {
    const path = window.location.pathname;

    // Header — на всех страницах, кроме login/register
    if (!path.includes('login') && !path.includes('register')) {
        initHeader();
    }

    if (path.includes('dashboard'))       loadDashboard();
    if (path.includes('knowledge-base'))  loadKnowledgeBase();
    if (path.includes('support'))         initSupport();
    if (path.includes('schedule'))        loadSchedule();

    const arrows = document.querySelectorAll('.nav-arrow');
    if (arrows.length === 2) {
        arrows[0].addEventListener('click', () => shiftWeek(-7));
        arrows[1].addEventListener('click', () => shiftWeek(7));
    }
});