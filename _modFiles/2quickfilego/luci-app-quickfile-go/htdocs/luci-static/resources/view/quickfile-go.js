'use strict';
'require view';
'require ui';

const QF_VERSION = '2.0.1-r90';
function qfResource(url) { return url + (url.includes('?') ? '&' : '?') + 'v=' + encodeURIComponent(QF_VERSION); }

const API_BASE = (() => {
    const h = window.location.hostname;
    const host = h.includes(':') && !h.startsWith('[') ? `[${h}]` : h;
    const proto = window.location.protocol === 'https:' ? 'https:' : 'http:';
    const qfPort = new URLSearchParams(window.location.search).get('qfport') || localStorage.getItem('quickfileGoPort') || '8989';
    if (/^\d{1,5}$/.test(qfPort)) localStorage.setItem('quickfileGoPort', qfPort);
    return `${proto}//${host}:${qfPort}`;
})();
const API = API_BASE + '/api';

function apiUrl(action, params) {
    const u = new URL(API);
    u.searchParams.set('action', action);
    Object.keys(params || {}).forEach(k => u.searchParams.set(k, params[k]));
    return u.toString();
}


function luciSession() {
    if (window.L && L.env && L.env.sessionid) return L.env.sessionid;
    const m = document.cookie.match(/(?:^|;\s*)sysauth(?:_[^=;]+)?=([^;]+)/);
    return m ? decodeURIComponent(m[1]) : '';
}

function downloadUrl(path) {
    const params = { path: path };
    const sid = luciSession();
    if (sid) params.sid = sid;
    return apiUrl('download', params);
}

function terminalUrl(path, cols, rows) {
    const wsBase = API_BASE.replace(/^https:/, 'wss:').replace(/^http:/, 'ws:');
    const u = new URL(wsBase + '/term');
    u.searchParams.set('path', path || '/');
    u.searchParams.set('cols', String(cols || 100));
    u.searchParams.set('rows', String(rows || 30));
    const sid = luciSession();
    if (sid) u.searchParams.set('sid', sid);
    return u.toString();
}

function loadScriptOnce(url, opts) {
    opts = opts || {};
    window.__qfScriptPromises = window.__qfScriptPromises || {};
    const key = url;
    if (opts.force) {
        delete window.__qfScriptPromises[key];
        document.querySelectorAll('script[data-qf-src="' + url + '"]').forEach(el => el.remove());
    } else if (window.__qfScriptPromises[key]) {
        return window.__qfScriptPromises[key];
    }
    const p = new Promise((resolve, reject) => {
        const old = document.querySelector('script[data-qf-src="' + url + '"]');
        if (old) {
            if (old.dataset.loaded === '1') return resolve();
            if (old.dataset.error === '1') {
                old.remove();
            } else {
                const timer = setTimeout(() => {
                    old.dataset.error = '1';
                    old.remove();
                    delete window.__qfScriptPromises[key];
                    reject(new Error('加载脚本超时: ' + url));
                }, opts.timeout || 8000);
                old.addEventListener('load', () => { clearTimeout(timer); resolve(); }, { once: true });
                old.addEventListener('error', () => { clearTimeout(timer); old.dataset.error = '1'; delete window.__qfScriptPromises[key]; reject(new Error('加载脚本失败: ' + url)); }, { once: true });
                return;
            }
        }
        const s = document.createElement('script');
        const timer = setTimeout(() => {
            s.dataset.error = '1';
            s.remove();
            delete window.__qfScriptPromises[key];
            reject(new Error('加载脚本超时: ' + url));
        }, opts.timeout || 8000);
        s.src = url;
        s.async = true;
        s.dataset.qfSrc = url;
        s.onload = () => { clearTimeout(timer); s.dataset.loaded = '1'; resolve(); };
        s.onerror = () => { clearTimeout(timer); s.dataset.error = '1'; s.remove(); delete window.__qfScriptPromises[key]; reject(new Error('加载脚本失败: ' + url)); };
        document.head.appendChild(s);
    });
    window.__qfScriptPromises[key] = p;
    return p;
}

function loadScriptWithRetry(urls, idx) {
    idx = idx || 0;
    if (idx >= urls.length) return Promise.reject(new Error('本地脚本资源加载失败'));
    const force = idx > 0;
    return loadScriptOnce(urls[idx], { force: force, timeout: 8000 }).catch(() => loadScriptWithRetry(urls, idx + 1));
}

function loadCSSOnce(url) {
    if (document.querySelector('link[data-qf-href="' + url + '"]')) return;
    const l = document.createElement('link');
    l.rel = 'stylesheet';
    l.href = url;
    l.dataset.qfHref = url;
    document.head.appendChild(l);
}

// xterm.js and its fit addon are UMD bundles. Once Monaco has installed its AMD
// loader, injecting those bundles as ordinary <script> tags registers anonymous
// AMD modules instead of exporting window.Terminal/window.fit. Load via AMD in
// that case, otherwise use classic script loading for terminals opened first.
function hasAMDLoader() {
    return typeof window.define === 'function' && !!window.define.amd && typeof window.require === 'function';
}

function loadAMDModule(url, timeout) {
    window.__qfAMDPromises = window.__qfAMDPromises || {};
    if (window.__qfAMDPromises[url]) return window.__qfAMDPromises[url];
    const p = new Promise((resolve, reject) => {
        let done = false;
        const timer = setTimeout(() => {
            if (done) return;
            done = true;
            delete window.__qfAMDPromises[url];
            reject(new Error('AMD 模块加载超时: ' + url));
        }, timeout || 8000);
        try {
            window.require([url], mod => {
                if (done) return;
                done = true;
                clearTimeout(timer);
                resolve(mod);
            }, err => {
                if (done) return;
                done = true;
                clearTimeout(timer);
                delete window.__qfAMDPromises[url];
                reject(err || new Error('AMD 模块加载失败: ' + url));
            });
        } catch (err) {
            done = true;
            clearTimeout(timer);
            delete window.__qfAMDPromises[url];
            reject(err);
        }
    });
    window.__qfAMDPromises[url] = p;
    return p;
}

function loadXtermLocal() {
    if (window.Terminal) return Promise.resolve(window.Terminal);
    const base = '/luci-static/resources/quickfile-go/xterm/';
    loadCSSOnce(qfResource(base + 'xterm.css'));

    if (hasAMDLoader()) {
        const xtermAMD = base + 'xterm.js';
        const fitAMD = base + 'fit.js';
        return loadAMDModule(xtermAMD, 8000).then(TerminalModule => {
            const Terminal = TerminalModule && (TerminalModule.Terminal || TerminalModule.default || TerminalModule);
            if (typeof Terminal !== 'function') throw new Error('本地 xterm.js AMD 导出无效');
            window.Terminal = Terminal;
            return loadAMDModule(fitAMD, 8000).catch(() => null).then(FitModule => {
                const fit = FitModule && (FitModule.default || FitModule);
                if (fit && fit.apply) {
                    window.fit = fit;
                    try { fit.apply(Terminal); } catch (_) {}
                }
                return Terminal;
            });
        });
    }

    const bust = String(Date.now());
    const xtermUrls = [
        qfResource(base + 'xterm.js'),
        base + 'xterm.js',
        qfResource(base + 'xterm.js') + '&retry=' + bust
    ];
    const fitUrls = [
        qfResource(base + 'fit.js'),
        base + 'fit.js',
        qfResource(base + 'fit.js') + '&retry=' + bust
    ];
    return loadScriptWithRetry(xtermUrls).then(() => {
        if (!window.Terminal) throw new Error('本地 xterm.js 未加载');
        return loadScriptWithRetry(fitUrls).catch(() => null).then(() => {
            if (window.fit && window.fit.apply) {
                try { window.fit.apply(window.Terminal); } catch (_) {}
            }
            return window.Terminal;
        });
    });
}

function promiseWithTimeout(promise, ms, message) {
    return new Promise((resolve, reject) => {
        let done = false;
        const timer = setTimeout(() => {
            if (done) return;
            done = true;
            reject(new Error(message || '操作超时'));
        }, ms);
        promise.then(value => {
            if (done) return;
            done = true;
            clearTimeout(timer);
            resolve(value);
        }, err => {
            if (done) return;
            done = true;
            clearTimeout(timer);
            reject(err);
        });
    });
}

function loadMonacoEditor() {
    if (window.monaco && window.monaco.editor) {
        registerQuickFileExtraLanguages(window.monaco);
        return Promise.resolve(window.monaco);
    }
    const candidates = [
        { loader: qfResource('/luci-static/resources/quickfile-go/monaco/vs/loader.js'), base: '/luci-static/resources/quickfile-go/monaco/vs' }
    ];
    const tryOne = idx => {
        if (idx >= candidates.length) return Promise.reject(new Error('Monaco Editor 未加载，已使用内置编辑器'));
        const c = candidates[idx];
        return loadScriptOnce(c.loader).then(() => new Promise((resolve, reject) => {
            if (!window.require) return reject(new Error('Monaco loader 不可用'));
            window.require.config({ paths: { vs: c.base } });
            window.require(['vs/editor/editor.main'], () => {
                if (!window.monaco || !window.monaco.editor) return reject(new Error('Monaco editor 初始化失败'));
                registerQuickFileExtraLanguages(window.monaco);
                resolve(window.monaco);
            }, reject);
        })).catch(() => tryOne(idx + 1));
    };
    return tryOne(0);
}

function detectEditorLanguage(path) {
    const name = String(path || '').toLowerCase();
    const base = name.split('/').pop() || name;
    const ext = base.split('.').pop();
    const map = {
        js: 'javascript', mjs: 'javascript', cjs: 'javascript', ts: 'typescript', tsx: 'typescript', json: 'json', html: 'html', htm: 'html', css: 'css',
        go: 'go', rs: 'rust', sh: 'shell', bash: 'shell', zsh: 'shell', ps1: 'powershell', psm1: 'powershell', lua: 'lua', py: 'python', rb: 'ruby', php: 'php',
        java: 'java', swift: 'swift', toml: 'toml', xml: 'xml', yml: 'yaml', yaml: 'yaml', md: 'markdown', sql: 'sql', c: 'c', h: 'c', cpp: 'cpp', cc: 'cpp', hpp: 'cpp',
        ini: 'ini', conf: 'ini', cfg: 'ini', log: 'plaintext', txt: 'plaintext', csv: 'plaintext'
    };
    if (base === 'dockerfile' || base.startsWith('dockerfile.')) return 'dockerfile';
    if (base === 'makefile' || base.endsWith('.mk')) return 'makefile';
    return map[ext] || 'plaintext';
}

// Monaco ships no standalone TOML/Makefile modules in the trimmed resource set used here.
// Register compact offline tokenizers for the additional configuration/build formats.
function registerQuickFileExtraLanguages(monaco) {
    if (!monaco || !monaco.languages || !monaco.languages.getLanguages) return;
    const languages = monaco.languages.getLanguages();
    if (!languages.some(lang => lang.id === 'toml')) {
        monaco.languages.register({ id: 'toml', extensions: ['.toml'], aliases: ['TOML', 'toml'] });
    }
    if (!languages.some(lang => lang.id === 'makefile')) {
        monaco.languages.register({ id: 'makefile', extensions: ['.mk'], filenames: ['Makefile', 'makefile'], aliases: ['Makefile', 'makefile'] });
    }
    if (!monaco.__quickfileTomlReady) {
        monaco.languages.setMonarchTokensProvider('toml', {
            tokenizer: {
                root: [
                    [/\s+/, 'white'],
                    [/#.*$/, 'comment'],
                    [/^\s*\[\[?[^\]]+\]\]?\s*$/, 'type.identifier'],
                    [/^[ \t]*[A-Za-z0-9_.-]+(?=\s*=)/, 'key'],
                    [/\b(true|false)\b/, 'keyword'],
                    [/\b\d{4}-\d{2}-\d{2}(?:[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})?)?\b/, 'number.date'],
                    [/[-+]?\b(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][-+]?\d+)?)\b/, 'number'],
                    [/'{3}/, { token: 'string.quote', next: '@multiliteral' }],
                    [/"{3}/, { token: 'string.quote', next: '@multibasic' }],
                    [/'[^']*'/, 'string'],
                    [/"/, { token: 'string.quote', next: '@basic' }],
                    [/[=.,{}\[\]]/, 'delimiter']
                ],
                basic: [
                    [/[^\"]+/, 'string'],
                    [/\\./, 'string.escape'],
                    [/"/, { token: 'string.quote', next: '@pop' }]
                ],
                multiliteral: [
                    [/[^']+/, 'string'],
                    [/'{3}/, { token: 'string.quote', next: '@pop' }],
                    [/'/, 'string']
                ],
                multibasic: [
                    [/[^\"]+/, 'string'],
                    [/\\./, 'string.escape'],
                    [/"{3}/, { token: 'string.quote', next: '@pop' }],
                    [/"/, 'string']
                ]
            }
        });
        monaco.__quickfileTomlReady = true;
    }
    if (!monaco.__quickfileMakefileReady) {
        monaco.languages.setMonarchTokensProvider('makefile', {
            tokenizer: {
                root: [
                    [/^\s*#.*$/, 'comment'],
                    [/^\t.*$/, 'string'],
                    [/\$\([^)]+\)|\$\{[^}]+\}/, 'variable'],
                    [/^[A-Za-z0-9_./%+@-]+(?=\s*:)/, 'type.identifier'],
                    [/^[A-Za-z_][A-Za-z0-9_]*(?=\s*(?:[:?+]?=))/, 'variable'],
                    [/[:?+]?=/, 'operator'],
                    [/\b(?:include|define|endef|ifeq|ifneq|ifdef|ifndef|else|endif|export|override|private|vpath)\b/, 'keyword'],
                    [/#.*$/, 'comment']
                ]
            }
        });
        monaco.__quickfileMakefileReady = true;
    }
}

function bytesToText(data, decoder, streaming) {
    if (typeof data === 'string') return Promise.resolve(data);
    const d = decoder || new TextDecoder();
    const options = decoder && streaming !== false ? { stream: true } : undefined;
    if (data instanceof Blob) return data.arrayBuffer().then(buf => d.decode(new Uint8Array(buf), options));
    if (data instanceof ArrayBuffer) return Promise.resolve(d.decode(new Uint8Array(data), options));
    return Promise.resolve(String(data || ''));
}

function formData(values) {
    const fd = new FormData();
    Object.keys(values || {}).forEach(k => fd.append(k, values[k]));
    return fd;
}

function apiFetch(action, options, params) {
    const opts = Object.assign({ credentials: 'include' }, options || {});
    const sid = luciSession();
    if (sid) {
        opts.headers = Object.assign({}, opts.headers || {}, { 'X-LuCI-Session': sid });
    }
    return fetch(apiUrl(action, params), opts).then(async r => {
        const body = await r.json().catch(() => ({ code: r.status, msg: r.statusText || '请求失败' }));
        if (!r.ok || (body.code && body.code >= 400)) {
            throw new Error(body.data || body.msg || '请求失败');
        }
        return body;
    });
}

function notifyError(err) {
    ui.addNotification(null, E('p', {}, String(err && err.message ? err.message : err)), 'danger');
}

function friendlyUploadError(status, body, fallback) {
    const raw = String((body && (body.data || body.msg)) || fallback || '').trim();
    const lower = raw.toLowerCase();
    if (status === 413 || lower.includes('too large') || lower.includes('超过') || lower.includes('maxbytesreader'))
        return raw.includes('超过') ? raw : '上传失败：文件超过最大上传限制';
    if (lower.includes('no space left') || lower.includes('空间不足'))
        return '上传失败：目标磁盘空间不足，请换到 /mnt 下空间更大的目录';
    if (lower.includes('permission denied') || lower.includes('operation not permitted') || lower.includes('权限'))
        return '上传失败：权限不足，无法写入当前目录';
    if (lower.includes('no such file') || lower.includes('not a directory') || lower.includes('目标目录不存在'))
        return '上传失败：目标目录不存在或不是目录';
    if (lower.includes('unexpected eof') || lower.includes('connection reset') || lower.includes('broken pipe') || lower.includes('network'))
        return '上传失败：连接中断或浏览器上传未完成';
    if (lower.includes('file exists'))
        return '上传失败：目标文件已存在或无法覆盖';
    return raw || '上传失败：未知错误';
}

function validName(name) {
    return !!name && name !== '.' && name !== '..' && !name.includes('/') && !name.includes('\\') && !name.includes('\0');
}

return view.extend({
    icons: {
        folder: '<svg viewBox="0 0 1024 1024" width="56" height="56"><path d="M928 256H599.168L501.76 158.592A64 64 0 0 0 456.448 140.8H96a64 64 0 0 0-64 64v614.4a64 64 0 0 0 64 64h832a64 64 0 0 0 64-64V320a64 64 0 0 0-64-64z" fill="#ff9800"/></svg>',
        file: '<svg viewBox="0 0 1024 1024" width="52" height="52"><path d="M854.6 288.6L639.4 73.4c-6-6-14.1-9.4-22.6-9.4H192c-17.7 0-32 14.3-32 32v832c0 17.7 14.3 32 32 32h640c17.7 0 32-14.3 32-32V311.3c0-8.5-3.4-16.7-9.4-22.7zM790.2 326H602V137.8L790.2 326zm1.8 562H232V136h302v216a42 42 0 0 0 42 42h216v494z" fill="#9e9e9e"/></svg>'
    },
    currentPath: '/',
    viewMode: 'list',
    clipboard: null,
    theme: 'light',
    fileInput: null,
    selectedFiles: new Set(),
    toolbarRefs: null,
    sortBy: 'time',
    sortDir: 'desc',
    settingsRefs: null,
    marqueeState: null,
    suppressItemOpenUntil: 0,
    clientTasks: null,
    taskCenterState: null,
    taskToastState: null,

    injectCSS: function() {
        if (document.getElementById('qf-custom-css')) return;
        const css = `
        .qf-app { background: #202124; color: #cfd3dc; font-family: "Helvetica Neue", Helvetica, sans-serif; border: 0; box-shadow: none; border-radius: 0; min-height: 0; position: relative; padding: 0; margin: 0; font-size: 14px; transition: 0.3s; }
        .qf-app.drag-over { outline: 2px dashed #409eff; background: rgba(64,158,255,0.05); }
        .qf-header { display: flex; justify-content: space-between; align-items: center; padding: 15px 20px; margin-bottom: 15px; background: #202124; border: 0; border-radius: 4px; }
        .qf-logo { font-size: 18px; font-weight: 600; color: #fff; display: flex; align-items: center; gap: 8px; }
        .qf-header-right { font-size: 13px; color: #a3a6ad; cursor: pointer; display: flex; gap: 15px; user-select: none; }
        .qf-header-right span:hover { color: #409eff; }
        .qf-card { background: #202124; border: 0; border-radius: 4px; box-shadow: none; margin-bottom: 15px; transition: 0.3s; }
        .qf-card:last-child { margin-bottom: 0; }
        .qf-breadcrumb { padding: 15px 20px; color: #cfd3dc; display: flex; align-items: center; flex-wrap: wrap; font-size: 13px; }
        .qf-breadcrumb span.qf-bc-link:hover { color: #409eff; text-decoration: underline; cursor: pointer; }
        /* r85: keep the desktop toolbar in one row like upstream; wrap only on narrow screens. */
        .qf-toolbar { display: flex; gap: 8px; padding: 14px 16px; flex-wrap: nowrap; border-bottom: 0; align-items: center; transition: 0.3s; min-width: 0; }
        .qf-btn { display: inline-flex; align-items: center; gap: 6px; line-height: 1; cursor: pointer; background: #363637; border: 1px solid #414243; color: #cfd3dc; text-align: center; box-sizing: border-box; outline: none; margin: 0; transition: .15s; font-weight: 600; padding: 8px 11px; font-size: 12px; border-radius: 4px; min-height: 32px; white-space: nowrap; flex: 0 0 auto; }
        .qf-btn:hover { color: #409eff; border-color: #409eff; background-color: rgba(64,158,255,0.1); }
        .qf-btn-primary { color: #fff; background-color: #2f7df6; border-color: #2f7df6; }
        .qf-btn-primary:hover { background: #4a8ef7; border-color: #4a8ef7; color: #fff; }
        .qf-btn-danger-text { color: #f56c6c; border-color: transparent; background: transparent; }
        .qf-btn-danger-text:hover { background: rgba(245,108,108,0.1); border-color: transparent; }
        .qf-btn:disabled, .qf-btn.disabled { cursor: not-allowed; opacity: .55; color: #909399 !important; border-color: #4a4b4c !important; background: #303133 !important; }
        .qf-btn:disabled:hover, .qf-btn.disabled:hover { color: #909399 !important; border-color: #4a4b4c !important; background: #303133 !important; }
        .qf-btn-icon { font-size: 13px; display: inline-flex; align-items: center; justify-content: center; min-width: 12px; }
        .qf-search-box { margin-left: auto; display: flex; align-items: center; flex: 1 1 218px; min-width: 150px; max-width: 250px; background: #1a1a1a; border: 1px solid #414243; border-radius: 4px; box-sizing: border-box; }
        .qf-search-box input { flex: 1 1 auto; min-width: 0; width: 100%; box-sizing: border-box; background: transparent !important; border: none !important; box-shadow: none !important; color: #cfd3dc; padding: 8px 6px 8px 12px; outline: none; font-size: 12px; }
        .qf-search-box input::placeholder { color: #9aa4b2; opacity: 1; }
        .qf-search-icon { padding: 0 10px 0 4px; color: #9aa4b2; flex: none; }
        @media (max-width: 1180px) {
            .qf-toolbar { flex-wrap: wrap; }
            .qf-search-box { flex-basis: 100%; min-width: min(100%, 220px); max-width: 100%; margin-left: 0; margin-top: 4px; }
        }

        .qf-settings-panel { padding: 18px; background: #202124; color: #cfd3dc; flex: 1 1 auto; min-height: 0; overflow: auto; box-sizing: border-box; }
        .qf-settings-note { color: #909399; font-size: 12px; margin-bottom: 14px; }
        .qf-settings-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px 14px; }
        .qf-settings-field { display: flex; flex-direction: column; gap: 6px; font-size: 12px; color: #a3a6ad; }
        .qf-settings-field span { font-weight: 600; }
        .qf-settings-field input, .qf-settings-field select { width: 100%; box-sizing: border-box; background: #111214; border: 1px solid #3b3f45; color: #d7dce5; border-radius: 6px; padding: 9px 12px; min-height: 38px; line-height: 20px; outline: none; transition: .15s; }
        .qf-settings-field select { appearance: auto; -webkit-appearance: menulist; padding-right: 34px; }
        .qf-settings-field option { background: #111214; color: #d7dce5; }
        .qf-settings-field input:focus, .qf-settings-field select:focus { border-color: #409eff; box-shadow: 0 0 0 2px rgba(64,158,255,.15); }
        .qf-settings-actions { display: flex; gap: 10px; flex-wrap: wrap; justify-content: flex-end; padding-top: 16px; margin-top: 16px; border-top: 1px solid #34383e; }
        .qf-diagnose-output { display: none; background: #0f1012; border: 1px solid #34383e; color: #cfd3dc; border-radius: 6px; padding: 12px; white-space: pre-wrap; max-height: min(240px, 34vh); overflow: auto; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 12px; margin-top: 14px; }
        .qf-settings-dialog { width: 620px; max-width: min(92vw, 620px); max-height: min(760px, calc(100vh - 32px)); background: #202124; border: 1px solid #34383e; }
        .qf-settings-dialog .qf-dialog-body { min-height: 0; overflow: hidden; }
        .qf-settings-dialog .qf-dialog-header { background: #202124; color: #f0f3f8; border-bottom: 1px solid #34383e; }
        .qf-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(110px, 1fr)); gap: 15px; padding: 20px; padding-bottom: 50px; }
        .qf-grid.qf-list-view { display: flex; flex-direction: column; gap: 0; padding: 10px; }
        .qf-item { display: flex; flex-direction: column; align-items: center; padding: 15px 10px; border-radius: 4px; cursor: pointer; transition: 0.2s; border: 1px solid transparent; user-select: none; position: relative; }
        .qf-item:hover { background-color: rgba(255,255,255,0.05); }
        .qf-item.selected { background-color: rgba(64,158,255,0.1) !important; border-color: #409eff; }
        .qf-item.context-target { background-color: rgba(64,158,255,0.08) !important; border-color: #409eff; }
        .qf-item-name { margin-top: 10px; font-size: 13px; color: #cfd3dc; text-align: center; word-break: break-all; }
        .qf-item-icon { min-height: 58px; display: flex; align-items: center; justify-content: center; }
        /* r85: thumbnails follow the active theme without a heavy dark picture frame. */
        .qf-thumb { width: 72px; height: 58px; max-width: 88px; object-fit: cover; border-radius: 6px; border: 1px solid rgba(148,163,184,.20); background: transparent; box-shadow: none; box-sizing: border-box; }
        .qf-thumb-svg { object-fit: contain; background: rgba(255,255,255,.96); padding: 4px; box-sizing: border-box; }
        .qf-item-meta { display: none; margin-left: auto; color: #909399; font-size: 12px; }
        .qf-grid.qf-list-view .qf-item { flex-direction: row; justify-content: flex-start; padding: 10px 15px 10px 35px; border-bottom: 1px solid #363637; border-radius: 0; }
        .qf-grid.qf-list-view .qf-item svg { width: 30px; height: 30px; margin-right: 15px; }
        .qf-grid.qf-list-view .qf-item-name { margin-top: 0; }
        .qf-grid.qf-list-view .qf-item-meta { display: block; }
        /* r84: use a private visual marker instead of styling LuCI native checkbox inputs. */
        .qf-check-control { position: relative; display: inline-flex; align-items: center; justify-content: center; width: 14px; height: 14px; flex: none; cursor: pointer; }
        .qf-native-check { position: absolute !important; opacity: 0 !important; width: 1px !important; height: 1px !important; margin: 0 !important; padding: 0 !important; border: 0 !important; box-shadow: none !important; -webkit-appearance: none !important; appearance: none !important; overflow: hidden !important; clip: rect(0 0 0 0) !important; clip-path: inset(50%) !important; }
        .qf-checkmark { display: inline-block; width: 14px; height: 14px; box-sizing: border-box; border: 1px solid #d0d7de; border-radius: 3px; background: #fff; position: relative; transition: border-color .14s, background-color .14s, box-shadow .14s; }
        .qf-check-control:hover .qf-checkmark { border-color: #409eff; }
        .qf-native-check:focus-visible + .qf-checkmark { border-color: #409eff; box-shadow: 0 0 0 2px rgba(64,158,255,.18); }
        .qf-native-check:checked + .qf-checkmark, .qf-native-check:indeterminate + .qf-checkmark { border-color: #2f7df6; background: #2f7df6; }
        .qf-native-check:checked + .qf-checkmark::after { content: ''; position: absolute; left: 4px; top: 1.5px; width: 4px; height: 7px; border: solid #fff; border-width: 0 1.7px 1.7px 0; transform: rotate(45deg); }
        .qf-native-check:indeterminate + .qf-checkmark::after { content: ''; position: absolute; left: 3px; top: 5.5px; width: 6px; height: 2px; border-radius: 1px; background: #fff; }
        .qf-row-select { position: absolute; top: 8px; left: 8px; width: 14px; height: 14px; display: inline-flex; justify-content: center; align-items: center; z-index: 10; }
        /* Original behavior: grid view selects by marquee/card highlight and never shows a checkbox. */
        .qf-grid:not(.qf-list-view) .qf-row-select { display: none !important; }
        .qf-empty { padding: 40px; color: #909399; text-align: center; }
        .qf-context-menu { position: absolute; background: #202124; border: 1px solid #414243; border-radius: 4px; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.5); z-index: 1000; padding: 5px 0; min-width: 150px; font-size: 13px; color: #cfd3dc; }
        .qf-menu-item { padding: 8px 20px; cursor: pointer; transition: 0.2s; display: flex; align-items: center; gap: 8px; }
        .qf-menu-item:hover { background: #414243; color: #409eff; }
        .qf-menu-separator { height: 1px; background: #414243; margin: 5px 0; }
        .qf-menu-item.disabled { color: #666; cursor: not-allowed; }
        .qf-menu-item.disabled:hover { background: transparent; color: #666; }
        /* r79 list view: compact file-manager table inspired by the original QuickFile layout */
        .qf-grid.qf-list-view { display: block; padding: 0 0 14px; overflow-x: auto; }
        .qf-list-header, .qf-grid.qf-list-view .qf-item { min-width: 900px; display: grid; grid-template-columns: minmax(271px, 1fr) 92px 172px 124px 132px 100px; column-gap: 8px; align-items: center; }
        .qf-list-header { min-height: 42px; padding: 0 18px; border-bottom: 1px solid #363637; color: #aeb6c2; font-size: 12px; font-weight: 700; position: sticky; top: 0; background: #202124; z-index: 5; }
        .qf-list-header span { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-list-header span[data-sort] { cursor: pointer; user-select: none; }
        .qf-list-header span[data-sort]:hover { color: #409eff; }
        .qf-head-name { grid-column: 1; display: inline-flex; align-items: center; gap: 12px; min-width: 0; }
        .qf-head-size { grid-column: 2; }
        .qf-head-time { grid-column: 3; }
        .qf-head-mode { grid-column: 4; }
        .qf-head-owner { grid-column: 5; }
        .qf-head-actions { grid-column: 6; text-align: center; }
        .qf-select-all-checkbox:disabled + .qf-checkmark { opacity: .45; cursor: not-allowed; }
        .qf-selection-rectangle { position: fixed; display: none; pointer-events: none; z-index: 1200; border: 1px solid #409eff; background: rgba(64,158,255,.18); border-radius: 3px; box-sizing: border-box; }
        body.qf-marquee-selecting, body.qf-marquee-selecting * { user-select: none !important; -webkit-user-select: none !important; }
        .qf-grid.qf-list-view .qf-item { min-height: 45px; padding: 0 18px; border-bottom: 1px solid #363637; border-radius: 0; }
        .qf-grid.qf-list-view .qf-item:hover { background-color: rgba(64,158,255,.08); }
        .qf-list-name-cell { grid-column: 1; min-width: 0; display: inline-flex; align-items: center; gap: 12px; }
        .qf-grid.qf-list-view .qf-row-select { position: static; width: 14px; height: 14px; display: inline-flex; justify-content: center; align-items: center; flex: none; }
        .qf-list-header .qf-check-control { width: 14px; height: 14px; }
        .qf-grid.qf-list-view .qf-list-placeholder { width: 14px; height: 14px; display: inline-block; flex: none; }
        .qf-grid.qf-list-view .qf-item-icon { display: inline-flex; align-items: center; justify-content: center; width: 24px; min-width: 24px; flex: none; }
        .qf-grid.qf-list-view .qf-item-icon svg { width: 22px; height: 22px; margin: 0; }
        .qf-grid.qf-list-view .qf-thumb { width: 24px; height: 23px; max-width: 24px; border-radius: 4px; }
        .qf-grid.qf-list-view .qf-item-name { flex: 1 1 auto; min-width: 0; margin-top: 0; text-align: left; word-break: normal; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; font-size: 13px; color: #e5eaf3; }
        .qf-grid.qf-list-view .qf-item-meta { display: contents; color: #aeb6c2; font-size: 12px; }
        .qf-grid.qf-list-view .qf-item-meta span { display: block; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-grid.qf-list-view .qf-col-size { grid-column: 2; color: #cdd6e3; }
        .qf-grid.qf-list-view .qf-col-time { grid-column: 3; color: #9aa4b2; }
        .qf-grid.qf-list-view .qf-col-mode { grid-column: 4; color: #9aa4b2; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 11px; }
        .qf-grid.qf-list-view .qf-col-owner { grid-column: 5; color: #aeb6c2; }
        .qf-item-actions { display: none; }
        .qf-grid.qf-list-view .qf-item-actions { grid-column: 6; display: inline-flex; justify-content: center; align-items: center; gap: 5px; }
        .qf-row-action { width: 26px; height: 26px; border: 0; border-radius: 5px; padding: 0; background: transparent; color: #aeb6c2; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; line-height: 1; }
        .qf-row-action > div { display: inline-flex; align-items: center; justify-content: center; }
        .qf-row-action-svg { width: 15px !important; height: 15px !important; margin: 0 !important; display: block; }
        .qf-row-action:hover { color: #409eff; background: rgba(64,158,255,.12); }
        .qf-row-action.qf-danger { color: #f56c6c; }
        .qf-row-action.qf-danger:hover { color: #f56c6c; background: rgba(245,108,108,.12); }
        .qf-grid.qf-list-view .qf-item.qf-parent-row .qf-item-name { color: #dce8ff; }
        .qf-grid.qf-list-view .qf-item.qf-folder-item .qf-item-name { color: #63aaff; font-weight: 600; }
        .qf-grid.qf-list-view .qf-item.qf-parent-row .qf-col-size { color: #f0c674; }
        @media (max-width: 1100px) {
            .qf-list-header, .qf-grid.qf-list-view .qf-item { min-width: 830px; grid-template-columns: minmax(235px, 1fr) 82px 146px 110px 116px 94px; column-gap: 7px; }
        }
        .qf-app.qf-light { background: #ffffff; color: #606266; }
        .qf-app.qf-light .qf-logo { color: #303133; }
        .qf-app.qf-light .qf-header-right { color: #606266; }
        .qf-app.qf-light .qf-card { background: #fff; border-color: transparent; box-shadow: none; }
        .qf-app.qf-light .qf-breadcrumb { color: #606266; }
        .qf-app.qf-light .qf-toolbar, .qf-app.qf-light .qf-grid.qf-list-view .qf-item { border-color: #ebeef5; }
        .qf-app.qf-light .qf-btn { background: #f5f7fa; border-color: #e4e7ed; color: #606266; }
        .qf-app.qf-light .qf-btn:hover { color: #409eff; border-color: #c6e2ff; background-color: #ecf5ff; }
        .qf-app.qf-light .qf-btn-primary { color: #fff; background-color: #2f7df6; border-color: #2f7df6; }
        .qf-app.qf-light .qf-btn:disabled, .qf-app.qf-light .qf-btn.disabled { background: #f5f7fa !important; border-color: #ebeef5 !important; color: #c0c4cc !important; }

        .qf-app.qf-light .qf-settings-panel { background: #fff; color: #303133; }
        .qf-app.qf-light .qf-settings-note { color: #909399; }
        .qf-app.qf-light .qf-settings-field { color: #606266; }
        .qf-app.qf-light .qf-settings-field input, .qf-app.qf-light .qf-settings-field select { background: #fff; border-color: #dcdfe6; color: #606266; }
        .qf-app.qf-light .qf-diagnose-output { background: #f8f8f8; border-color: #ebeef5; color: #303133; }
        .qf-app.qf-light .qf-search-box { background: #fff; border-color: #dcdfe6; }
        .qf-app.qf-light .qf-search-box input { color: #303133 !important; background: transparent !important; }
        .qf-app.qf-light .qf-search-box input::placeholder { color: #606266; opacity: .78; }
        .qf-app.qf-light .qf-search-icon { color: #606266; }
        .qf-app.qf-light .qf-item:hover { background-color: #f5f7fa; }
        .qf-app.qf-light .qf-item.selected { background-color: #e6f7ff !important; border-color: #93c9ff; }
        .qf-app.qf-light .qf-item.context-target { background-color: #eef7ff !important; border-color: #93c9ff; }
        .qf-app.qf-light .qf-item-name { color: #303133; }
        .qf-app.qf-light .qf-thumb { border-color: #e4e7ed; background: transparent; box-shadow: none; }
        .qf-app.qf-light .qf-thumb-svg { background: #fff; }
        .qf-app.qf-light .qf-context-menu { background: #fff; border-color: #ebeef5; color: #606266; box-shadow: 0 2px 12px 0 rgba(0,0,0,0.1); }
        .qf-app.qf-light .qf-list-header { border-color: #ebeef5; color: #909399; background: #fff; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item-name { color: #303133; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item-meta, .qf-app.qf-light .qf-grid.qf-list-view .qf-col-time, .qf-app.qf-light .qf-grid.qf-list-view .qf-col-mode { color: #606266; }
        .qf-app.qf-light .qf-menu-item:hover { background: #ecf5ff; color: #66b1ff; }
        .qf-app.qf-light .qf-menu-separator { background: #ebeef5; }
        .qf-app.qf-light .qf-grid.qf-list-view { background: #fff; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item { border-color: #ebeef5; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item:hover { background: #f5f9ff; }
        .qf-app.qf-light .qf-checkmark { background: #fff; border-color: #c0c9d4; }
        .qf-app.qf-light .qf-check-control:hover .qf-checkmark { border-color: #2f7df6; }
        .qf-app.qf-light .qf-native-check:checked + .qf-checkmark, .qf-app.qf-light .qf-native-check:indeterminate + .qf-checkmark { background: #2f7df6; border-color: #2f7df6; }
        .qf-app:not(.qf-light) .qf-checkmark { background: transparent; border-color: #7f8996; }
        .qf-app:not(.qf-light) .qf-native-check:checked + .qf-checkmark, .qf-app:not(.qf-light) .qf-native-check:indeterminate + .qf-checkmark { background: #409eff; border-color: #409eff; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item.selected { background: #ecf5ff !important; border-color: #ebeef5; box-shadow: inset 3px 0 #409eff; }
        .qf-app.qf-light .qf-row-action { color: #606266; }
        .qf-app.qf-light .qf-row-action:hover { color: #409eff; background: #ecf5ff; }
        .qf-app.qf-light .qf-row-action.qf-danger { color: #f56c6c; }
        .qf-app.qf-light .qf-row-action.qf-danger:hover { background: #fef0f0; }
        .qf-quickfile-light .qf-selection-rectangle { border-color: #409eff; background: rgba(64,158,255,.15); }
        /* Complete light-mode coverage for main UI and floating UI */
        .qf-app.qf-light .qf-header { background: #fff; border-color: transparent; }
        .qf-app.qf-light .qf-breadcrumb span[style] { color: #909399 !important; }
        .qf-app.qf-light .qf-toolbar { background: #fff; border-color: transparent; }
        .qf-app.qf-light .qf-empty { color: #909399; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-col-size { color: #606266; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item.qf-parent-row .qf-item-name { color: #303133; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item.qf-folder-item .qf-item-name { color: #2563eb; }
        .qf-app.qf-light .qf-grid.qf-list-view .qf-item.qf-parent-row .qf-col-size { color: #909399; }
        .qf-app.qf-light .qf-list-header span[data-sort]:hover { color: #409eff; }
        .qf-quickfile-light .qf-overlay { background: rgba(245,247,250,.72); }
        .qf-quickfile-light .qf-dialog { box-shadow: 0 14px 42px rgba(0,0,0,.16); }
        .qf-quickfile-light .qf-dialog .qf-btn { background: #f5f7fa; border-color: #dcdfe6; color: #606266; }
        .qf-quickfile-light .qf-dialog .qf-btn:hover { color: #409eff; border-color: #c6e2ff; background-color: #ecf5ff; }
        .qf-quickfile-light .qf-dialog .qf-btn-primary { color: #fff; background-color: #2f7df6; border-color: #2f7df6; }
        .qf-quickfile-light .qf-dialog .qf-btn:disabled,
        .qf-quickfile-light .qf-dialog .qf-btn.disabled { background: #f5f7fa !important; border-color: #ebeef5 !important; color: #c0c4cc !important; }
        .qf-quickfile-light .qf-settings-dialog,
        .qf-quickfile-light .qf-confirm-dialog { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-settings-dialog .qf-dialog-header,
        .qf-quickfile-light .qf-confirm-dialog .qf-dialog-header { background: #fff; color: #303133; border-bottom-color: #ebeef5; }
        .qf-quickfile-light .qf-confirm-dialog .qf-dialog-body { color: #606266; }
        .qf-quickfile-light .qf-confirm-message { color: #303133; }
        .qf-quickfile-light .qf-confirm-target { background: #f8f8f8; border-color: #ebeef5; color: #606266; }
        .qf-quickfile-light .qf-confirm-dialog .qf-dialog-footer { background: #fff; border-top-color: #ebeef5; }
        .qf-quickfile-light .qf-confirm-cancel { background: #f5f7fa; border-color: #dcdfe6; color: #606266; }
        .qf-quickfile-light .qf-confirm-cancel:hover { background: #ecf5ff; border-color: #c6e2ff; color: #409eff; }
        .qf-quickfile-light .qf-settings-panel { background: #fff; color: #303133; }
        .qf-quickfile-light .qf-settings-note { color: #909399; }
        .qf-quickfile-light .qf-settings-field { color: #606266; }
        .qf-quickfile-light .qf-settings-field input,
        .qf-quickfile-light .qf-settings-field select { background: #fff; border-color: #dcdfe6; color: #606266; }
        .qf-quickfile-light .qf-settings-field option { background: #fff; color: #606266; }
        .qf-quickfile-light .qf-settings-actions { border-top-color: #ebeef5; }
        .qf-quickfile-light .qf-diagnose-output { background: #f8f8f8; border-color: #ebeef5; color: #303133; }
        .qf-quickfile-light .qf-context-menu { background: #fff; border-color: #ebeef5; color: #606266; box-shadow: 0 2px 12px rgba(0,0,0,.12); }
        .qf-quickfile-light .qf-menu-item:hover { background: #ecf5ff; color: #409eff; }
        .qf-quickfile-light .qf-menu-separator { background: #ebeef5; }
        .qf-quickfile-light .qf-editor-dialog { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-editor-dialog .qf-dialog-header,
        .qf-quickfile-light .qf-editor-dialog .qf-dialog-footer { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-editor-host,
        .qf-quickfile-light .qf-editor { background: #fff; color: #303133; }
        .qf-quickfile-light .qf-editor-status { color: #606266; }
        .qf-quickfile-light .qf-terminal-dialog { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-terminal-dialog .qf-dialog-header { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-terminal-status { background: #f5f7fa; border-top-color: #ebeef5; color: #606266; }
        .qf-quickfile-light .qf-terminal-action { background: #f5f7fa; border-color: #dcdfe6; color: #606266; }
        .qf-quickfile-light .qf-terminal-action:hover { background: #ecf5ff; border-color: #c6e2ff; color: #409eff; }
        .qf-quickfile-light .qf-window-controls { border-left-color: #e4e7ed; }
        .qf-quickfile-light .qf-window-control { background: #f5f7fa; border-color: #dcdfe6; color: #606266; }
        .qf-quickfile-light .qf-window-control:hover { background: #ecf5ff; border-color: #c6e2ff; color: #409eff; }
        .qf-quickfile-light .qf-window-control.qf-window-close:hover { background: #fef0f0; border-color: #fbc4c4; color: #f56c6c; }
        .qf-quickfile-light .qf-task-dialog,
        .qf-quickfile-light .qf-task-dialog .qf-dialog-header,
        .qf-quickfile-light .qf-task-dialog .qf-dialog-footer { background: #fff; border-color: #ebeef5; color: #303133; }
        .qf-quickfile-light .qf-task-row { background: #fff; border-color: #ebeef5; }
        .qf-quickfile-light .qf-task-title { color: #303133; }
        .qf-quickfile-light .qf-task-state { background: #ecf5ff; color: #337ecc; }
        .qf-quickfile-light .qf-task-state.done { background: #f0f9eb; color: #529b2e; }
        .qf-quickfile-light .qf-task-state.error { background: #fef0f0; color: #c45656; }
        .qf-quickfile-light .qf-task-state.cancelled { background: #f4f4f5; color: #73767a; }
        .qf-quickfile-light .qf-task-meta { color: #606266; }
        .qf-quickfile-light .qf-task-log-wrap summary { color: #337ecc; }
        .qf-quickfile-light .qf-task-log { background: #f8f8f8; border-color: #ebeef5; color: #303133; }
        .qf-quickfile-light .qf-task-footer-note { color: #909399; }
        .qf-overlay { position: fixed; inset: 0; background: rgba(0,0,0,.52); z-index: 999999; display: flex; align-items: center; justify-content: center; padding: 24px; box-sizing: border-box; }
        .qf-dialog { border-radius: 6px; box-shadow: 0 16px 48px rgba(0,0,0,.42); display: flex; flex-direction: column; overflow: hidden; font-family: sans-serif; }
        .qf-dialog-header { height: 46px; padding: 0 14px; display: flex; justify-content: space-between; align-items: center; box-sizing: border-box; font-weight: 700; }
        .qf-dialog-title { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-dialog-close { color: #9aa4b2; cursor: pointer; font-size: 24px; text-decoration: none; width: 30px; height: 30px; text-align: center; line-height: 28px; border-radius: 4px; }
        .qf-dialog-close:hover { color: #f56c6c; background: rgba(245,108,108,.10); }
        .qf-dialog-body { padding: 0; flex: 1; display: flex; flex-direction: column; position: relative; min-height: 0; }
        .qf-dialog-footer { min-height: 58px; padding: 12px 16px; display: flex; align-items: center; justify-content: flex-end; gap: 10px; box-sizing: border-box; }
        .qf-confirm-dialog { width: min(92vw, 440px); background: #202124; color: #d7dce5; border: 1px solid #34383e; }
        .qf-confirm-dialog .qf-dialog-header { background: #202124; color: #f0f3f8; border-bottom: 1px solid #34383e; }
        .qf-confirm-dialog .qf-dialog-body { padding: 18px; display: block; line-height: 1.65; color: #cfd3dc; }
        .qf-confirm-icon { width: 38px; height: 38px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; margin-right: 12px; background: rgba(64,158,255,.12); color: #409eff; font-size: 18px; flex: none; }
        .qf-confirm-icon.danger { background: rgba(245,108,108,.12); color: #f56c6c; }
        .qf-confirm-content { display: flex; align-items: flex-start; }
        .qf-confirm-main { flex: 1; min-width: 0; }
        .qf-confirm-message { font-size: 14px; color: #e5e7eb; margin-bottom: 8px; }
        .qf-confirm-target { color: #9aa4b2; font-size: 12px; word-break: break-all; white-space: pre-wrap; background: #111827; border: 1px solid #2a3441; border-radius: 6px; padding: 8px 10px; }
        .qf-confirm-dialog .qf-dialog-footer { background: #202124; border-top: 1px solid #2a3441; }
        .qf-confirm-cancel { border: 1px solid #3b3f45; background: #2b2f36; color: #d7dce5; border-radius: 6px; padding: 8px 16px; cursor: pointer; font-weight: 600; }
        .qf-confirm-ok { border: 1px solid #2f7df6; background: #2f7df6; color: #fff; border-radius: 6px; padding: 8px 16px; cursor: pointer; font-weight: 600; }
        .qf-confirm-ok.danger { border-color: #f56c6c; background: #f56c6c; }
        .qf-confirm-cancel:hover { background: #343a43; }
        .qf-confirm-ok:hover { filter: brightness(1.08); }
        .qf-form-row { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
        .qf-form-label { color: #aeb6c2; font-size: 12px; font-weight: 700; }
        .qf-form-input { width: 100%; box-sizing: border-box; background: #111214; border: 1px solid #3b3f45; color: #e5eaf3; border-radius: 6px; padding: 10px 12px; min-height: 38px; outline: none; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 13px; }
        .qf-form-input:focus { border-color: #409eff; box-shadow: 0 0 0 2px rgba(64,158,255,.14); }
        .qf-form-help { color: #8f98a6; font-size: 12px; line-height: 1.5; margin-top: 8px; }
        .qf-form-error { color: #f56c6c; font-size: 12px; min-height: 18px; margin-top: 8px; }
        .qf-download-dialog { width: min(92vw, 560px); }
        .qf-download-path { color: #9aa4b2; font-size: 12px; word-break: break-all; background: #111827; border: 1px solid #2a3441; border-radius: 6px; padding: 8px 10px; margin-top: 8px; }
        .qf-download-grid { display: grid; grid-template-columns: 1fr; gap: 14px; margin-top: 12px; }
        .qf-download-tip { display: flex; align-items: flex-start; gap: 8px; color: #8f98a6; font-size: 12px; line-height: 1.6; background: rgba(64,158,255,.06); border: 1px solid rgba(64,158,255,.16); border-radius: 6px; padding: 9px 10px; }
        .qf-download-tip strong { color: #cfd7e6; }
        .qf-copy-path-value { user-select: text; -webkit-user-select: text; }
        .qf-quickfile-light .qf-form-label { color: #606266; }
        .qf-quickfile-light .qf-form-input { background: #fff; border-color: #dcdfe6; color: #303133; }
        .qf-quickfile-light .qf-form-help { color: #909399; }
        .qf-quickfile-light .qf-form-error { color: #f56c6c; }
        .qf-quickfile-light .qf-download-path { background: #f8f8f8; border-color: #ebeef5; color: #606266; }
        .qf-quickfile-light .qf-download-tip { background: #f4f8ff; border-color: #d9ecff; color: #606266; }
        .qf-quickfile-light .qf-download-tip strong { color: #303133; }
        /* r89: the install body owns its scrolling region; the footer remains visible and never overlays log text. */
        .qf-install-dialog { width: min(92vw, 820px); height: min(86vh, 760px); max-height: min(86vh, 760px); background: #202124; color: #d7dce5; border: 1px solid #34383e; }
        .qf-install-dialog .qf-dialog-header { flex: 0 0 46px; background: #202124; color: #f0f3f8; border-bottom: 1px solid #34383e; }
        .qf-install-dialog .qf-dialog-body { flex: 1 1 auto; min-height: 0; overflow-x: hidden; overflow-y: auto; padding: 16px; gap: 12px; display: flex; flex-direction: column; }
        .qf-install-dialog .qf-dialog-footer { flex: 0 0 auto; min-height: 58px; background: #202124; border-top: 1px solid #2a3441; }
        .qf-install-status-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .qf-install-status { display: inline-flex; align-items: center; gap: 8px; font-weight: 700; color: #d7dce5; }
        .qf-install-dot { width: 10px; height: 10px; border-radius: 50%; background: #409eff; box-shadow: 0 0 0 5px rgba(64,158,255,.12); }
        .qf-install-status.success { color: #67c23a; }
        .qf-install-status.success .qf-install-dot { background: #67c23a; box-shadow: 0 0 0 5px rgba(103,194,58,.12); }
        .qf-install-status.fail { color: #f56c6c; }
        .qf-install-status.fail .qf-install-dot { background: #f56c6c; box-shadow: 0 0 0 5px rgba(245,108,108,.12); }
        .qf-install-meta { display: grid; grid-template-columns: 88px minmax(0,1fr); gap: 7px 10px; background: #111827; border: 1px solid #2a3441; border-radius: 8px; padding: 10px 12px; font-size: 12px; }
        .qf-install-meta-label { color: #8f98a6; font-weight: 700; }
        .qf-install-meta-value { color: #d7dce5; word-break: break-all; user-select: text; -webkit-user-select: text; }
        .qf-install-warning { background: rgba(245,108,108,.08); border: 1px solid rgba(245,108,108,.22); color: #f3b4b4; border-radius: 8px; padding: 10px 12px; line-height: 1.55; font-size: 12px; }
        .qf-install-log { flex: 1 1 auto; height: auto; min-height: min(210px, 30vh); overflow: auto; white-space: pre-wrap; word-break: break-word; background: #0b1018; color: #d1d5db; border: 1px solid #2a3441; border-radius: 8px; padding: 12px; box-sizing: border-box; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 13px; line-height: 1.45; user-select: text; -webkit-user-select: text; }
        .qf-install-actions-left { min-width: 0; margin-right: auto; color: #9aa4b2; font-size: 12px; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-install-footer-actions { display: inline-flex; gap: 10px; align-items: center; flex: none; }
        .qf-quickfile-light .qf-install-dialog { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-install-dialog .qf-dialog-header,
        .qf-quickfile-light .qf-install-dialog .qf-dialog-footer { background: #fff; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-install-status { color: #303133; }
        .qf-quickfile-light .qf-install-status.success { color: #529b2e; }
        .qf-quickfile-light .qf-install-status.fail { color: #c45656; }
        .qf-quickfile-light .qf-install-meta { background: #f8f8f8; border-color: #ebeef5; }
        .qf-quickfile-light .qf-install-meta-label { color: #606266; }
        .qf-quickfile-light .qf-install-meta-value { color: #303133; }
        .qf-quickfile-light .qf-install-warning { background: #fff7f7; border-color: #f5d6d6; color: #9f3a3a; }
        .qf-quickfile-light .qf-install-log { background: #f8f8f8; color: #303133; border-color: #ebeef5; }
        .qf-quickfile-light .qf-install-actions-left { color: #606266; }
        .qf-editor-dialog { width: min(86vw, 1280px); height: min(82vh, 820px); background: #111827; color: #e5e7eb; border: 1px solid #2a3441; }
        .qf-editor-dialog .qf-dialog-header { background: #202124; color: #f9fafb; border-bottom: 1px solid #2a3441; }
        .qf-editor-dialog .qf-dialog-footer { background: #202124; border-top: 1px solid #2a3441; }
        .qf-editor { width: 100%; height: 100%; resize: none; background: #0b1018; color: #d1d5db; border: 0; padding: 12px; box-sizing: border-box; outline: none; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 13px; line-height: 1.45; }
        .qf-editor-host { width: 100%; flex: 1; min-height: 0; background: #0b1018; position: relative; }
        .qf-editor-status { margin-right: auto; font-size: 12px; color: #9aa4b2; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-terminal-dialog { width: min(70vw, 1040px); min-width: 720px; height: min(68vh, 660px); background: #202124; color: #e5e7eb; }
        .qf-terminal-dialog .qf-dialog-header { background: #202124; color: #f9fafb; border-bottom: 1px solid #2a3441; }
        .qf-terminal-host { width: 100%; flex: 1; min-height: 0; background: #000; color: #ddd; overflow: hidden; border: 1px solid #111827; border-left: 0; border-right: 0; }
        .qf-terminal-fallback { height: 100%; overflow: auto; white-space: pre; outline: none; padding: 12px; box-sizing: border-box; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 14px; line-height: 1.35; background: #000; color: #eee; user-select: text; -webkit-user-select: text; caret-color: transparent; tab-size: 8; }
        .qf-terminal-actions { margin-left: auto; display: inline-flex; gap: 7px; align-items: center; flex: none; }
        .qf-terminal-action { border: 1px solid #2a3441; background: #1f2937; color: #cbd5e1; border-radius: 4px; padding: 5px 9px; cursor: pointer; font-size: 12px; line-height: 1; min-height: 26px; }
        .qf-terminal-action:hover { background: #334155; color: #fff; border-color: #475569; }
        .qf-terminal-status { height: 38px; line-height: 38px; font-size: 12px; color: #9aa4b2; padding: 0 12px; border-top: 1px solid #2a3441; background: #202124; box-sizing: border-box; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        .qf-terminal-host .terminal { height: 100%; padding: 10px; box-sizing: border-box; }
        /* Desktop-style editor / terminal windows: draggable, minimizable and maximizable. */
        .qf-overlay.qf-desktop-overlay { align-items: stretch; justify-content: stretch; }
        .qf-overlay.qf-desktop-overlay.qf-window-minimized-overlay { background: transparent; pointer-events: none; }
        .qf-desktop-dialog { position: absolute; margin: 0; transition: box-shadow .15s ease; }
        .qf-desktop-dialog .qf-dialog-header.qf-window-drag-handle { cursor: move; user-select: none; -webkit-user-select: none; }
        .qf-desktop-dialog .qf-dialog-title { cursor: inherit; }
        .qf-window-controls { margin-left: 4px; padding-left: 7px; border-left: 1px solid #334155; display: inline-flex; align-items: center; gap: 5px; }
        .qf-window-control { display: inline-flex; align-items: center; justify-content: center; width: 29px; height: 26px; padding: 0; border: 1px solid #2a3441; border-radius: 4px; background: #1f2937; color: #cbd5e1; cursor: pointer; font-size: 15px; line-height: 1; }
        .qf-window-control:hover { background: #334155; border-color: #475569; color: #fff; }
        .qf-window-control.qf-window-close:hover { background: rgba(245,108,108,.18); border-color: rgba(245,108,108,.45); color: #f56c6c; }
        .qf-desktop-dialog.qf-window-maximized { left: 12px !important; top: 12px !important; bottom: auto !important; width: calc(100vw - 24px) !important; height: calc(100vh - 24px) !important; min-width: 0 !important; max-width: none !important; max-height: none !important; border-radius: 6px; }
        .qf-desktop-dialog.qf-window-minimized { width: min(430px, calc(100vw - 24px)) !important; min-width: 0 !important; height: 46px !important; max-height: 46px !important; pointer-events: auto; box-shadow: 0 12px 34px rgba(0,0,0,.4); }
        .qf-desktop-dialog.qf-window-minimized .qf-dialog-body,
        .qf-desktop-dialog.qf-window-minimized .qf-dialog-footer,
        .qf-desktop-dialog.qf-window-minimized .qf-terminal-action { display: none; }
        .qf-desktop-dialog.qf-window-minimized .qf-dialog-header { border-bottom: 0; cursor: move; }
        .qf-task-dialog { width: min(92vw, 760px); max-height: min(84vh, 760px); background: #202124; color: #d7dce5; border: 1px solid #34383e; }
        .qf-task-dialog .qf-dialog-header, .qf-task-dialog .qf-dialog-footer { background: #202124; border-color: #34383e; color: #f0f3f8; }
        .qf-task-dialog .qf-dialog-body { min-height: 0; overflow: hidden; }
        .qf-task-list { flex: 1 1 auto; min-height: 0; overflow: auto; padding: 12px; }
        .qf-task-row { border: 1px solid #374151; background: #1f242c; border-radius: 8px; padding: 10px; margin-bottom: 10px; }
        .qf-task-title { font-weight: 700; color: #e5e7eb; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; gap: 12px; }
        .qf-task-title-left { display: inline-flex; align-items: center; gap: 8px; min-width: 0; }
        .qf-task-state { border-radius: 999px; padding: 2px 8px; font-size: 11px; font-weight: 700; background: rgba(64,158,255,.14); color: #7db8ff; }
        .qf-task-state.done { background: rgba(103,194,58,.15); color: #86d966; }
        .qf-task-state.error { background: rgba(245,108,108,.15); color: #f58a8a; }
        .qf-task-state.cancelled { background: rgba(148,163,184,.15); color: #b9c2cf; }
        .qf-task-meta { color: #a6adbb; font-size: 12px; white-space: pre-wrap; word-break: break-all; margin-top: 7px; }
        .qf-task-log-wrap { margin-top: 8px; }
        .qf-task-log-wrap summary { cursor: pointer; color: #8ab4ff; font-size: 12px; }
        .qf-task-log { max-height: 220px; overflow: auto; background: #0b1018; border: 1px solid #2a3441; border-radius: 6px; padding: 9px; margin-top: 7px; color: #cfd3dc; font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; white-space: pre-wrap; word-break: break-word; }
        .qf-task-footer-note { margin-right: auto; color: #9aa4b2; font-size: 12px; }
        /* r90: non-blocking task toast. Unlike LuCI notifications it never pushes the page down. */
        .qf-task-toast-wrap { position: fixed; top: 88px; right: 22px; z-index: 12050; width: min(380px, calc(100vw - 32px)); pointer-events: none; }
        .qf-task-toast { pointer-events: auto; display: flex; align-items: flex-start; gap: 10px; background: #202124; border: 1px solid #34383e; border-left: 3px solid #409eff; border-radius: 7px; box-shadow: 0 12px 30px rgba(0,0,0,.32); padding: 11px 10px 11px 12px; color: #d7dce5; opacity: 0; transform: translateY(-9px); transition: opacity .18s ease, transform .18s ease; }
        .qf-task-toast.show { opacity: 1; transform: translateY(0); }
        .qf-task-toast.success { border-left-color: #67c23a; }
        .qf-task-toast.error { border-left-color: #f56c6c; }
        .qf-task-toast.cancelled { border-left-color: #909399; }
        .qf-task-toast-dot { width: 9px; height: 9px; flex: 0 0 auto; margin-top: 6px; border-radius: 50%; background: #409eff; box-shadow: 0 0 0 4px rgba(64,158,255,.13); }
        .qf-task-toast.success .qf-task-toast-dot { background: #67c23a; box-shadow: 0 0 0 4px rgba(103,194,58,.13); }
        .qf-task-toast.error .qf-task-toast-dot { background: #f56c6c; box-shadow: 0 0 0 4px rgba(245,108,108,.14); }
        .qf-task-toast.cancelled .qf-task-toast-dot { background: #909399; box-shadow: 0 0 0 4px rgba(144,147,153,.13); }
        .qf-task-toast-content { flex: 1; min-width: 0; }
        .qf-task-toast-title { font-size: 13px; font-weight: 700; color: #f0f3f8; line-height: 1.4; }
        .qf-task-toast-message { margin-top: 3px; color: #a6adbb; font-size: 12px; line-height: 1.42; word-break: break-all; }
        .qf-task-toast-actions { display: inline-flex; flex: 0 0 auto; align-items: center; gap: 5px; margin-left: 3px; }
        .qf-task-toast-link, .qf-task-toast-close { border: 0; background: transparent; color: #8ab4ff; cursor: pointer; font-size: 12px; line-height: 1; padding: 5px 6px; border-radius: 4px; }
        .qf-task-toast-link:hover { background: rgba(64,158,255,.13); color: #b7d3ff; }
        .qf-task-toast-close { color: #9aa4b2; font-size: 16px; padding: 3px 5px; }
        .qf-task-toast-close:hover { background: rgba(148,163,184,.12); color: #f0f3f8; }
        .qf-task-toast-wrap.qf-light .qf-task-toast { background: #fff; border-color: #e4e7ed; border-left-color: #409eff; color: #303133; box-shadow: 0 10px 26px rgba(0,0,0,.12); }
        .qf-task-toast-wrap.qf-light .qf-task-toast.success { border-left-color: #67c23a; }
        .qf-task-toast-wrap.qf-light .qf-task-toast.error { border-left-color: #f56c6c; }
        .qf-task-toast-wrap.qf-light .qf-task-toast.cancelled { border-left-color: #909399; }
        .qf-task-toast-wrap.qf-light .qf-task-toast-title { color: #303133; }
        .qf-task-toast-wrap.qf-light .qf-task-toast-message { color: #606266; }
        .qf-task-toast-wrap.qf-light .qf-task-toast-link { color: #337ecc; }
        .qf-task-toast-wrap.qf-light .qf-task-toast-link:hover { background: #ecf5ff; color: #409eff; }
        .qf-task-toast-wrap.qf-light .qf-task-toast-close { color: #909399; }
        @media (max-width: 680px) { .qf-task-toast-wrap { top: 66px; right: 12px; width: calc(100vw - 24px); } }
        @media (max-width: 900px) { .qf-terminal-dialog, .qf-editor-dialog { width: 94vw; min-width: 0; height: 78vh; } .qf-terminal-actions { gap: 4px; } .qf-terminal-action { padding: 5px 7px; } .qf-window-control { width: 27px; } }
        `;
        document.head.appendChild(E('style', { id: 'qf-custom-css' }, css));
    },

    load: function() {
        this.injectCSS();
        return this.fetchList(this.currentPath);
    },

    fetchList: function(path) {
        this.selectedFiles.clear();
        this.updateSelectionUI();
        return apiFetch('list', {}, { path: path }).then(res => res.data || []).catch(err => {
            notifyError(err);
            return [];
        });
    },

    refresh: function(newPath) {
        this.currentPath = newPath || '/';
        return this.fetchList(this.currentPath).then(files => {
            const app = document.querySelector('.qf-app');
            if (!app || !app.parentNode) return;
            const container = app.parentNode;
            container.innerHTML = '';
            container.appendChild(this.render(files));
        });
    },

    makeIcon: function(svgHTML) {
        const div = document.createElement('div');
        div.innerHTML = svgHTML;
        return div;
    },

    formatSize: function(size) {
        if (size < 1024) return size + ' B';
        if (size < 1024 * 1024) return (size / 1024).toFixed(1) + ' KB';
        return (size / 1024 / 1024).toFixed(1) + ' MB';
    },


    formatTime: function(ts) {
        if (!ts) return '-';
        const d = new Date(ts * 1000);
        const pad = n => String(n).padStart(2, '0');
        return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
    },

    sortFiles: function(files) {
        const arr = Array.from(files || []);
        let key = this.sortBy || 'name';
        if (key === 'owner') key = 'name';
        const dir = this.sortDir === 'desc' ? -1 : 1;
        const byName = (a, b) => String(a.name || '').localeCompare(String(b.name || ''), undefined, { numeric: true, sensitivity: 'base' });
        arr.sort((a, b) => {
            // Directories are always grouped first, but sorting still applies inside the directory group.
            if (a.isDir !== b.isDir) return a.isDir ? -1 : 1;

            const getTime = v => {
                if (typeof v === 'number') return v;
                if (typeof v === 'string') {
                    const n = Number(v);
                    if (!Number.isNaN(n)) return n;
                    const t = Date.parse(v);
                    return Number.isNaN(t) ? 0 : Math.floor(t / 1000);
                }
                return 0;
            };

            let result = 0;
            if (key === 'name') {
                result = byName(a, b);
            } else if (key === 'size') {
                result = Number(a.size || 0) - Number(b.size || 0);
            } else if (key === 'time') {
                result = getTime(a.time || a.mtime) - getTime(b.time || b.mtime);
            } else if (key === 'mode') {
                result = String(a[key] || '').localeCompare(String(b[key] || ''), undefined, { numeric: true, sensitivity: 'base' });
            } else {
                result = byName(a, b);
            }
            if (result === 0) result = byName(a, b);
            return result * dir;
        });
        return arr;
    },

    setSort: function(key) {
        if (this.sortBy === key) this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
        else { this.sortBy = key; this.sortDir = key === 'name' ? 'asc' : 'desc'; }
        this.refresh(this.currentPath);
    },

    sortLabel: function(key, label) {
        return label + (this.sortBy === key ? (this.sortDir === 'asc' ? ' ↑' : ' ↓') : '');
    },

    confirmAction: function(opts) {
        opts = opts || {};
        return new Promise(resolve => {
            const overlay = E('div', { class: 'qf-overlay' });
            const close = value => {
                overlay.remove();
                document.removeEventListener('keydown', onKey);
                resolve(!!value);
            };
            const onKey = ev => {
                if (ev.key === 'Escape') close(false);
                if (ev.key === 'Enter') close(true);
            };
            const danger = opts.type === 'danger';
            const dialog = E('div', { class: 'qf-dialog qf-confirm-dialog' }, [
                E('div', { class: 'qf-dialog-header' }, [
                    E('span', { class: 'qf-dialog-title' }, opts.title || '确认操作'),
                    E('a', { class: 'qf-dialog-close', click: () => close(false) }, '×')
                ]),
                E('div', { class: 'qf-dialog-body' }, [
                    E('div', { class: 'qf-confirm-content' }, [
                        E('span', { class: 'qf-confirm-icon' + (danger ? ' danger' : '') }, danger ? '!' : 'i'),
                        E('div', { class: 'qf-confirm-main' }, [
                            E('div', { class: 'qf-confirm-message' }, opts.message || '确定继续操作吗？'),
                            opts.target ? E('div', { class: 'qf-confirm-target' }, opts.target) : E('span', {})
                        ])
                    ])
                ]),
                E('div', { class: 'qf-dialog-footer' }, [
                    E('button', { class: 'qf-confirm-cancel', click: () => close(false) }, opts.cancelText || '取消'),
                    E('button', { class: 'qf-confirm-ok' + (danger ? ' danger' : ''), click: () => close(true) }, opts.okText || '确定')
                ])
            ]);
            overlay.appendChild(dialog);
            document.body.appendChild(overlay);
            setTimeout(() => document.addEventListener('keydown', onKey), 0);
        });
    },

    inputDialog: function(opts) {
        opts = opts || {};
        return new Promise(resolve => {
            const overlay = E('div', { class: 'qf-overlay' });
            const input = E('input', { class: 'qf-form-input', value: opts.value || '', placeholder: opts.placeholder || '', input: () => { err.textContent = ''; } });
            const err = E('div', { class: 'qf-form-error' }, '');
            const close = value => {
                overlay.remove();
                document.removeEventListener('keydown', onKey);
                resolve(value);
            };
            const submit = () => {
                const value = String(input.value || '').trim();
                if (typeof opts.validate === 'function') {
                    const msg = opts.validate(value);
                    if (msg) {
                        err.textContent = msg;
                        input.focus();
                        return;
                    }
                }
                close(value);
            };
            const onKey = ev => {
                if (ev.key === 'Escape') close(null);
                if (ev.key === 'Enter') submit();
            };
            const dialog = E('div', { class: 'qf-dialog qf-confirm-dialog' }, [
                E('div', { class: 'qf-dialog-header' }, [
                    E('span', { class: 'qf-dialog-title' }, opts.title || '输入'),
                    E('a', { class: 'qf-dialog-close', click: () => close(null) }, '×')
                ]),
                E('div', { class: 'qf-dialog-body' }, [
                    E('div', { class: 'qf-confirm-content' }, [
                        E('span', { class: 'qf-confirm-icon' }, opts.icon || 'i'),
                        E('div', { class: 'qf-confirm-main' }, [
                            E('div', { class: 'qf-confirm-message' }, opts.message || ''),
                            opts.target ? E('div', { class: 'qf-confirm-target' }, opts.target) : E('span', {}),
                            E('div', { class: 'qf-form-row' }, [
                                opts.label ? E('div', { class: 'qf-form-label' }, opts.label) : E('span', {}),
                                input,
                                opts.help ? E('div', { class: 'qf-form-help' }, opts.help) : E('span', {}),
                                err
                            ])
                        ])
                    ])
                ]),
                E('div', { class: 'qf-dialog-footer' }, [
                    E('button', { class: 'qf-confirm-cancel', click: () => close(null) }, opts.cancelText || '取消'),
                    E('button', { class: 'qf-confirm-ok', click: submit }, opts.okText || '确定')
                ])
            ]);
            overlay.appendChild(dialog);
            document.body.appendChild(overlay);
            setTimeout(() => { document.addEventListener('keydown', onKey); input.focus(); input.select(); }, 0);
        });
    },

    showProgressDialog: function(title) {
        const overlay = E('div', { class: 'qf-overlay' });
        const fill = E('div', { class: 'qf-progress-fill' });
        const text = E('div', { class: 'qf-progress-text' }, '准备中...');
        const cancelBtn = E('button', { class: 'qf-btn', style: 'display:none;margin-top:12px;' }, '取消任务');
        const box = E('div', { class: 'qf-progress-box' }, [
            E('div', { class: 'qf-progress-title' }, title),
            E('div', { class: 'qf-progress-bar' }, [fill]),
            text,
            E('div', { style: 'text-align:right;' }, [cancelBtn])
        ]);
        overlay.appendChild(box);
        document.body.appendChild(overlay);
        return {
            set: (pct, msg) => {
                if (pct >= 0) fill.style.width = Math.max(0, Math.min(100, pct)) + '%';
                if (msg) text.textContent = msg;
            },
            setCancel: fn => {
                cancelBtn.style.display = '';
                cancelBtn.onclick = ev => { ev.preventDefault(); if (fn) fn(); };
            },
            close: () => overlay.remove()
        };
    },

    monitorTask: function(taskId, title, doneRefreshPath) {
        const progress = this.showProgressDialog(title || '后台任务');
        let closed = false;
        progress.setCancel(() => {
            apiFetch('task_cancel', { method: 'POST', body: formData({ id: taskId }) }).then(() => {
                progress.set(-1, '已请求取消任务...');
            }).catch(notifyError);
        });
        return new Promise((resolve, reject) => {
            const poll = () => {
                if (closed) return;
                apiFetch('task', {}, { id: taskId }).then(tres => {
                    const t = tres.data || {};
                    const pct = Number(t.progress || 0);
                    let msg = t.message || '正在处理';
                    if (t.total > 0) msg += ` (${this.formatSize(t.current || 0)} / ${this.formatSize(t.total || 0)})`;
                    else if (t.current > 0) msg += ` (${this.formatSize(t.current || 0)})`;
                    progress.set(pct, msg);
                    if (t.status === 'done') {
                        progress.set(100, t.message || '任务完成');
                        setTimeout(() => { closed = true; progress.close(); resolve(t); }, 500);
                    } else if (t.status === 'error') {
                        closed = true; progress.close(); reject(new Error(t.error || '任务失败'));
                    } else if (t.status === 'cancelled') {
                        closed = true; progress.close(); reject(new Error('任务已取消'));
                    } else {
                        setTimeout(poll, 1500);
                    }
                }).catch(err => { closed = true; progress.close(); reject(err); });
            };
            poll();
        }).then(t => {
            this.refresh(doneRefreshPath || this.currentPath);
            return t;
        }).catch(err => { notifyError(err); throw err; });
    },

    startTaskAction: function(action, body, title, refreshPath) {
        return apiFetch(action, { method: 'POST', body: body }).then(res => {
            const id = res.data && res.data.id;
            if (!id) throw new Error('任务创建失败');
            return this.monitorTask(id, title || '后台任务', refreshPath);
        });
    },

    startBackgroundTaskAction: function(action, body, refreshPath) {
        return apiFetch(action, { method: 'POST', body: body }).then(res => {
            const id = res.data && res.data.id;
            if (!id) throw new Error('任务创建失败');
            // 真正后台任务：不弹遮罩、不阻塞文件管理页面。进度在右上角“任务”里查看。
            if (refreshPath) {
                setTimeout(() => this.refresh(refreshPath), 300);
            }
            return id;
        });
    },

    getVisibleSelectableItems: function() {
        return Array.from(document.querySelectorAll('.qf-grid .qf-selectable-item')).filter(item => item.style.display !== 'none');
    },

    syncSelectAllControls: function() {
        const visibleItems = this.getVisibleSelectableItems();
        const selectedVisible = visibleItems.filter(item => this.selectedFiles.has(item.dataset.qfPath));
        const allSelected = visibleItems.length > 0 && selectedVisible.length === visibleItems.length;
        document.querySelectorAll('.qf-select-all-checkbox').forEach(chk => {
            chk.disabled = visibleItems.length === 0;
            chk.checked = allSelected;
            chk.indeterminate = selectedVisible.length > 0 && !allSelected;
        });
    },

    toggleSelectVisible: function(forceSelected) {
        const items = this.getVisibleSelectableItems();
        if (!items.length) return ui.addNotification(null, E('p', {}, '当前没有可选择的项目'), 'warning');
        const allSelected = items.every(item => this.selectedFiles.has(item.dataset.qfPath));
        const selected = typeof forceSelected === 'boolean' ? forceSelected : !allSelected;
        items.forEach(item => {
            const path = item.dataset.qfPath;
            const chk = item.querySelector('.qf-checkbox');
            if (selected) this.selectedFiles.add(path);
            else this.selectedFiles.delete(path);
            item.classList.toggle('selected', selected);
            if (chk) chk.checked = selected;
        });
        this.updateSelectionUI();
    },

    setItemSelection: function(item, selected) {
        if (!item || !item.dataset.qfPath) return;
        const path = item.dataset.qfPath;
        const chk = item.querySelector('.qf-checkbox');
        if (selected) this.selectedFiles.add(path);
        else this.selectedFiles.delete(path);
        item.classList.toggle('selected', selected);
        if (chk) chk.checked = selected;
    },

    beginMarqueeSelection: function(grid, ev) {
        if (ev.button !== 0 || ev.target.closest('.qf-item, .qf-list-header, input, button, a, .qf-context-menu')) return;
        const visibleItems = this.getVisibleSelectableItems();
        if (!visibleItems.length) return;

        const additive = ev.ctrlKey || ev.metaKey;
        if (!additive) this.clearSelection();
        const rectangle = E('div', { class: 'qf-selection-rectangle' });
        document.body.appendChild(rectangle);
        const state = {
            startX: ev.clientX,
            startY: ev.clientY,
            rectangle: rectangle,
            additive: additive,
            base: new Set(this.selectedFiles),
            dragged: false
        };
        this.marqueeState = state;
        document.body.classList.add('qf-marquee-selecting');

        const move = moveEv => {
            if (this.marqueeState !== state) return;
            const dx = moveEv.clientX - state.startX;
            const dy = moveEv.clientY - state.startY;
            if (!state.dragged && Math.abs(dx) <= 3 && Math.abs(dy) <= 3) return;
            state.dragged = true;
            const left = Math.min(state.startX, moveEv.clientX);
            const top = Math.min(state.startY, moveEv.clientY);
            const right = Math.max(state.startX, moveEv.clientX);
            const bottom = Math.max(state.startY, moveEv.clientY);
            rectangle.style.display = 'block';
            rectangle.style.left = left + 'px';
            rectangle.style.top = top + 'px';
            rectangle.style.width = (right - left) + 'px';
            rectangle.style.height = (bottom - top) + 'px';
            this.getVisibleSelectableItems().forEach(item => {
                const r = item.getBoundingClientRect();
                const hit = !(right < r.left || left > r.right || bottom < r.top || top > r.bottom);
                this.setItemSelection(item, hit || (state.additive && state.base.has(item.dataset.qfPath)));
            });
            this.updateSelectionUI();
            moveEv.preventDefault();
        };
        const up = () => {
            if (this.marqueeState !== state) return;
            document.removeEventListener('mousemove', move, true);
            document.removeEventListener('mouseup', up, true);
            window.removeEventListener('blur', up, true);
            document.body.classList.remove('qf-marquee-selecting');
            rectangle.remove();
            this.marqueeState = null;
            if (state.dragged) this.suppressItemOpenUntil = Date.now() + 120;
        };
        document.addEventListener('mousemove', move, true);
        document.addEventListener('mouseup', up, true);
        window.addEventListener('blur', up, true);
        ev.preventDefault();
    },

    updateSelectionUI: function() {
        this.updateToolbarState();
        this.syncSelectAllControls();
    },

    updateToolbarState: function() {
        // 顶部工具栏不再通过 disabled 变灰；需要选择时由按钮点击后的提示处理。
        Object.values(this.toolbarRefs || {}).forEach(btn => {
            if (btn) btn.disabled = false;
        });
        const count = this.selectedFiles.size;
        [['copy', '复制'], ['cut', '剪切'], ['deleteBtn', '批量删除']].forEach(pair => {
            const btn = this.toolbarRefs && this.toolbarRefs[pair[0]];
            if (btn && btn.qfLabel) btn.qfLabel.textContent = pair[1] + (count ? ' (' + count + ')' : '');
        });
    },

    clearSelection: function() {
        this.selectedFiles.clear();
        document.querySelectorAll('.qf-selectable-item').forEach(el => el.classList.remove('selected'));
        document.querySelectorAll('.qf-checkbox').forEach(chk => { chk.checked = false; });
        this.updateSelectionUI();
    },

    clearContextTarget: function() {
        document.querySelectorAll('.qf-item.context-target').forEach(el => el.classList.remove('context-target'));
    },

    setContextTarget: function(item) {
        this.clearContextTarget();
        if (item) item.classList.add('context-target');
    },

    setClipboard: function(action) {
        if (this.selectedFiles.size === 0) {
            return ui.addNotification(null, E('p', {}, '请先选择要' + (action === 'copy' ? '复制' : '剪切') + '的文件或目录'), 'warning');
        }
        this.clipboard = { action: action, files: Array.from(this.selectedFiles) };
        this.clearSelection();
        this.refresh(this.currentPath);
    },

    makeToolbarButton: function(opts) {
        const cls = 'qf-btn' + (opts.primary ? ' qf-btn-primary' : '') + (opts.danger ? ' qf-btn-danger-text' : '');
        const attrs = {
            class: cls,
            click: ev => {
                ev.stopPropagation();
                if (btn.disabled) return;
                if (typeof opts.onClick === 'function') opts.onClick(ev);
            }
        };
        // 注意：HTML 里 disabled="false" 仍然会被浏览器当作禁用。
        // 所以只有真正需要禁用时才写入 disabled 属性，普通按钮不能带 disabled:false。
        if (opts.disabled) attrs.disabled = true;
        const label = E('span', {}, opts.label || '');
        const btn = E('button', attrs, [E('span', { class: 'qf-btn-icon' }, opts.icon || ''), label]);
        btn.qfLabel = label;
        btn.qfBaseLabel = opts.label || '';
        return btn;
    },

    getSingleSelectedPath: function() {
        return this.selectedFiles.size === 1 ? Array.from(this.selectedFiles)[0] : '';
    },

    getSingleSelectedName: function() {
        const p = this.getSingleSelectedPath();
        return p ? p.split('/').pop() : '';
    },

    showCompressToolbarMenu: function(ev) {
        if (this.selectedFiles.size !== 1) {
            return ui.addNotification(null, E('p', {}, '请先只选择一个文件或目录再压缩'), 'warning');
        }
        const path = this.getSingleSelectedPath();
        this.removeMenus();
        const menu = E('div', { class: 'qf-context-menu', style: `left:${ev.pageX}px;top:${ev.pageY + 8}px;` }, [
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'tar.gz'); menu.remove(); } }, '压缩为 .tar.gz'),
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'tar.xz'); menu.remove(); } }, '压缩为 .tar.xz'),
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'zip'); menu.remove(); } }, '压缩为 .zip')
        ]);
        this.showMenu(menu);
    },

    renderSettingsCard: function() {
        const enabled = E('select', {}, [E('option', { value: '1' }, '启用'), E('option', { value: '0' }, '禁用')]);
        const listenAddr = E('input', { type: 'text', value: '0.0.0.0' });
        const listenPort = E('input', { type: 'number', min: '1', max: '65535', value: '8989' });
        const terminal = E('select', {}, [E('option', { value: '1' }, '启用'), E('option', { value: '0' }, '禁用')]);
        const maxUpload = E('input', { type: 'number', min: '0', value: '0' });
        const maxEdit = E('input', { type: 'number', min: '0', value: '0' });
        const diag = E('pre', { class: 'qf-diagnose-output' }, '');
        const hideDiag = E('button', { class: 'qf-btn', style: 'display:none', title: '收起诊断输出', click: ev => { ev.stopPropagation(); this.hideDiagnose(); } }, '收起诊断');
        this.settingsRefs = { enabled, listenAddr, listenPort, terminal, maxUpload, maxEdit, diag, hideDiag };
        return E('div', { class: 'qf-settings-panel' }, [
            E('div', { class: 'qf-settings-note' }, '这些是服务级配置，保存并重启后新地址/端口才会完全生效。大小单位 MiB，0 表示不限制。诊断可查看当前实际运行状态。'),
            E('div', { class: 'qf-settings-grid' }, [
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '服务状态'), enabled]),
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '终端功能'), terminal]),
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '监听地址'), listenAddr]),
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '监听端口'), listenPort]),
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '最大上传'), maxUpload]),
                E('label', { class: 'qf-settings-field' }, [E('span', {}, '最大编辑'), maxEdit])
            ]),
            E('div', { class: 'qf-settings-actions' }, [
                E('button', { class: 'qf-btn qf-btn-primary', click: ev => { ev.stopPropagation(); this.saveSettings(false); } }, '保存'),
                E('button', { class: 'qf-btn', click: ev => { ev.stopPropagation(); this.saveSettings(true); } }, '保存并重启'),
                E('button', { class: 'qf-btn', click: ev => { ev.stopPropagation(); this.showDiagnose(); } }, '诊断'),
                hideDiag
            ]),
            diag
        ]);
    },

    openSettingsDialog: function() {
        let closed = false;
        let closeFn;
        const overlay = E('div', { class: 'qf-overlay' });
        const dialog = E('div', { class: 'qf-dialog qf-settings-dialog' }, [
            E('div', { class: 'qf-dialog-header' }, [E('span', { class: 'qf-dialog-title' }, '设置 / 诊断'), E('span', { class: 'qf-dialog-close', click: () => closeFn() }, '×')]),
            E('div', { class: 'qf-dialog-body' }, [this.renderSettingsCard()])
        ]);
        const keyHandler = ev => { if (ev.key === 'Escape') { ev.preventDefault(); closeFn(); } };
        closeFn = () => {
            if (closed) return;
            closed = true;
            document.removeEventListener('keydown', keyHandler);
            overlay.remove();
        };
        overlay.addEventListener('click', ev => { if (ev.target === overlay) closeFn(); });
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        document.addEventListener('keydown', keyHandler);
        this.loadSettings();
    },

    loadSettings: function() {
        return apiFetch('config_get', {}, {}).then(res => {
            const d = res.data || {};
            const r = this.settingsRefs || {};
            if (r.enabled) r.enabled.value = String(d.enabled || '1');
            if (r.listenAddr) r.listenAddr.value = String(d.listen_addr || '0.0.0.0');
            if (r.listenPort) r.listenPort.value = String(d.listen_port || '8989');
            if (r.terminal) r.terminal.value = String(d.enable_terminal || '1');
            if (r.maxUpload) r.maxUpload.value = String(d.max_upload_mb || '0');
            if (r.maxEdit) r.maxEdit.value = String(d.max_edit_mb || '0');
        }).catch(notifyError);
    },

    saveSettings: function(restart) {
        const r = this.settingsRefs || {};
        const port = r.listenPort ? String(r.listenPort.value || '8989') : '8989';
        if (restart && /^\d{1,5}$/.test(port)) localStorage.setItem('quickfileGoPort', port);
        const body = formData({
            enabled: r.enabled ? r.enabled.value : '1',
            listen_addr: r.listenAddr ? r.listenAddr.value : '0.0.0.0',
            listen_port: port,
            enable_terminal: r.terminal ? r.terminal.value : '1',
            max_upload_mb: r.maxUpload ? r.maxUpload.value : '0',
            max_edit_mb: r.maxEdit ? r.maxEdit.value : '0',
            restart: restart ? '1' : '0'
        });
        apiFetch('config_set', { method: 'POST', body }).then(res => {
            ui.addNotification(null, E('p', {}, String(res.data || '配置已保存')), 'info');
            if (restart) setTimeout(() => window.location.reload(), 1800);
        }).catch(notifyError);
    },

    showDiagnose: function() {
        apiFetch('diagnose', {}, {}).then(res => {
            const r = this.settingsRefs || {};
            if (r.diag) {
                r.diag.style.display = 'block';
                r.diag.textContent = JSON.stringify(res.data || {}, null, 2);
            }
            if (r.hideDiag) r.hideDiag.style.display = 'inline-flex';
        }).catch(notifyError);
    },

    hideDiagnose: function() {
        const r = this.settingsRefs || {};
        if (r.diag) {
            r.diag.style.display = 'none';
            r.diag.textContent = '';
        }
        if (r.hideDiag) r.hideDiag.style.display = 'none';
    },

    render: function(files) {
        document.body.classList.toggle('qf-quickfile-light', this.theme === 'light');
        document.body.classList.toggle('qf-quickfile-dark', this.theme !== 'light');
        if (this.taskToastState && this.taskToastState.node) {
            this.taskToastState.node.classList.toggle('qf-light', this.theme === 'light');
        }
        this.fileInput = E('input', { type: 'file', multiple: 'multiple', style: 'display:none', change: ev => this.uploadFiles(ev.target.files) });
        const btnRefresh = E('span', { click: () => this.refresh(this.currentPath) }, '↻ 刷新');
        const btnView = E('span', { click: () => { this.viewMode = this.viewMode === 'grid' ? 'list' : 'grid'; this.refresh(this.currentPath); } }, this.viewMode === 'grid' ? '☶ 列表' : '☷ 网格');
        const btnTheme = E('span', { click: () => { this.theme = this.theme === 'dark' ? 'light' : 'dark'; this.refresh(this.currentPath); } }, this.theme === 'light' ? '🌙 深色模式' : '☀ 浅色模式');
        const btnTasks = E('span', { click: () => this.showTaskCenter() }, '▣ 任务');
        const btnSettings = E('span', { click: () => this.openSettingsDialog() }, '⚙ 设置');

        const logoIcon = this.makeIcon(`<svg viewBox="0 0 1024 1024" width="22" height="22"><path d="M928 256H599.168L501.76 158.592A64 64 0 0 0 456.448 140.8H96a64 64 0 0 0-64 64v614.4a64 64 0 0 0 64 64h832a64 64 0 0 0 64-64V320a64 64 0 0 0-64-64z" fill="#409eff"/></svg>`);
        const header = E('div', { class: 'qf-header' }, [
            E('div', { class: 'qf-logo' }, [logoIcon, E('span', {}, 'Quick 文件管理')]),
            E('div', { class: 'qf-header-right' }, [btnRefresh, btnView, btnTasks, btnTheme, btnSettings])
        ]);

        const breadcrumb = E('div', { class: 'qf-breadcrumb' });
        breadcrumb.appendChild(E('span', { class: 'qf-bc-link', click: () => this.refresh('/') }, '🏠 根目录'));
        let curPath = '';
        this.currentPath.split('/').filter(Boolean).forEach(p => {
            curPath += '/' + p;
            const targetPath = curPath;
            breadcrumb.appendChild(E('span', { style: 'margin:0 5px;color:#c0c4cc;' }, '/'));
            breadcrumb.appendChild(E('span', { class: 'qf-bc-link', click: () => this.refresh(targetPath) }, p));
        });
        const breadcrumbCard = E('div', { class: 'qf-card' }, [breadcrumb]);

        const searchInput = E('input', { type: 'text', placeholder: '搜索文件...', input: ev => this.filterItems(ev.target.value) });
        const btnUpload = this.makeToolbarButton({ primary: true, icon: '☁', label: '上传文件', onClick: () => this.fileInput.click() });
        const btnNew = this.makeToolbarButton({ icon: '✚', label: '新建 ▾', onClick: ev => this.showNewMenu(ev) });
        const btnTerminal = this.makeToolbarButton({ icon: '〉_', label: '终端', onClick: () => this.openTerminal() });
        const btnCompress = this.makeToolbarButton({ icon: '🗜', label: '压缩', onClick: ev => this.showCompressToolbarMenu(ev) });
        const btnCopy = this.makeToolbarButton({ icon: '⧉', label: '复制', onClick: () => this.setClipboard('copy') });
        const btnCut = this.makeToolbarButton({ icon: '✂', label: '剪切', onClick: () => this.setClipboard('move') });
        const btnPaste = this.makeToolbarButton({ icon: '📋', label: '粘贴', onClick: () => this.paste() });
        const btnDownload = this.makeToolbarButton({ icon: '☁', label: '下载文件', onClick: () => this.remoteDownload() });
        const btnDelete = this.makeToolbarButton({ icon: '🗑', label: '批量删除', danger: true, onClick: () => this.deleteSelected() });
        this.toolbarRefs = { upload: btnUpload, newBtn: btnNew, terminal: btnTerminal, compress: btnCompress, copy: btnCopy, cut: btnCut, paste: btnPaste, download: btnDownload, deleteBtn: btnDelete };
        const toolbar = E('div', { class: 'qf-toolbar' }, [
            btnUpload, btnNew, btnTerminal, btnCompress, btnCopy, btnCut, btnPaste, btnDownload, btnDelete,
            E('div', { class: 'qf-search-box' }, [searchInput, E('span', { class: 'qf-search-icon' }, '🔍')])
        ]);

        const grid = E('div', { class: 'qf-grid' + (this.viewMode === 'list' ? ' qf-list-view' : '') });
        if (this.viewMode === 'list') {
            const selectAllCheckbox = E('input', { type: 'checkbox', class: 'qf-select-all-checkbox qf-native-check', title: '全选/取消全选当前显示项目', click: ev => { ev.stopPropagation(); this.toggleSelectVisible(ev.target.checked); } });
            const selectAllControl = E('label', { class: 'qf-check-control', title: '全选/取消全选当前显示项目', click: ev => ev.stopPropagation() }, [
                selectAllCheckbox,
                E('span', { class: 'qf-checkmark' })
            ]);
            grid.appendChild(E('div', { class: 'qf-list-header' }, [
                E('span', { class: 'qf-head-name', 'data-sort': 'name', click: () => this.setSort('name') }, [
                    selectAllControl,
                    E('span', {}, this.sortLabel('name', '名称'))
                ]),
                E('span', { class: 'qf-head-size', 'data-sort': 'size', click: () => this.setSort('size') }, this.sortLabel('size', '大小')),
                E('span', { class: 'qf-head-time', 'data-sort': 'time', click: () => this.setSort('time') }, this.sortLabel('time', '修改时间')),
                E('span', { class: 'qf-head-mode', 'data-sort': 'mode', click: () => this.setSort('mode') }, this.sortLabel('mode', '权限')),
                E('span', { class: 'qf-head-owner' }, '所有者'),
                E('span', { class: 'qf-head-actions' }, '操作')
            ]));
        }
        if (this.currentPath !== '/') {
            const upPath = this.currentPath.split('/').slice(0, -1).join('/') || '/';
            const parentChildren = this.viewMode === 'list' ? [
                E('div', { class: 'qf-list-name-cell' }, [
                    E('span', { class: 'qf-list-placeholder' }),
                    E('div', { class: 'qf-item-icon' }, [this.makeIcon(this.icons.folder)]),
                    E('div', { class: 'qf-item-name' }, '.. (返回上一级)')
                ]),
                E('div', { class: 'qf-item-meta' }, [
                    E('span', { class: 'qf-col-size' }, '—'),
                    E('span', { class: 'qf-col-time' }, ''),
                    E('span', { class: 'qf-col-mode' }, ''),
                    E('span', { class: 'qf-col-owner' }, '')
                ]),
                E('div', { class: 'qf-item-actions' })
            ] : [
                E('div', { class: 'qf-item-icon' }, [this.makeIcon(this.icons.folder)]),
                E('div', { class: 'qf-item-name' }, '.. (返回上一级)'),
                E('div', { class: 'qf-item-meta' }, [E('span', { class: 'qf-col-size' }, '目录'), E('span', { class: 'qf-col-time' }, ''), E('span', { class: 'qf-col-mode' }, '')])
            ];
            grid.appendChild(E('div', { class: 'qf-item qf-parent-row', click: ev => { ev.stopPropagation(); this.refresh(upPath); } }, parentChildren));
        }

        if (!files || files.length === 0) {
            grid.appendChild(E('div', { class: 'qf-empty' }, '当前目录为空或无权限读取'));
        } else {
            this.sortFiles(files).forEach(f => this.appendFileItem(grid, f));
        }

        grid.addEventListener('mousedown', ev => this.beginMarqueeSelection(grid, ev));
        grid.addEventListener('click', ev => {
            if (Date.now() < this.suppressItemOpenUntil) {
                ev.preventDefault();
                ev.stopPropagation();
                return;
            }
            if ((ev.ctrlKey || ev.metaKey) && !ev.target.closest('.qf-item')) {
                ev.preventDefault();
                ev.stopPropagation();
            }
        }, true);
        grid.addEventListener('contextmenu', ev => {
            if (ev.target.closest('.qf-item')) return;
            ev.preventDefault();
            this.showBlankContextMenu(ev);
        });

        const mainCard = E('div', { class: 'qf-card' }, [toolbar, grid]);
        const appWrapper = E('div', { class: 'qf-app' + (this.theme === 'light' ? ' qf-light' : '') }, [this.fileInput, header, breadcrumbCard, mainCard]);
        appWrapper.addEventListener('click', ev => {
            if (ev.target.closest('.qf-context-menu') || ev.target.closest('.qf-toolbar') || ev.target.closest('.qf-settings') || ev.target.closest('.qf-item')) return;
            this.clearContextTarget();
            this.clearSelection();
        });
        appWrapper.addEventListener('dragover', ev => { ev.preventDefault(); appWrapper.classList.add('drag-over'); });
        appWrapper.addEventListener('dragleave', ev => { ev.preventDefault(); appWrapper.classList.remove('drag-over'); });
        appWrapper.addEventListener('drop', ev => {
            ev.preventDefault();
            appWrapper.classList.remove('drag-over');
            if (ev.dataTransfer.files.length > 0) this.uploadFiles(ev.dataTransfer.files);
        });
        this.updateSelectionUI();
        return appWrapper;
    },

    isImageFileName: function(name) {
        const lower = String(name || '').toLowerCase();
        return /\.(png|jpe?g|gif|webp|bmp|svg|ico|avif)$/i.test(lower);
    },

    getNormalizedExt: function(name) {
        const lower = String(name || '').toLowerCase();
        if (lower.endsWith('.tar.gz')) return 'tar.gz';
        if (lower.endsWith('.tar.xz')) return 'tar.xz';
        const idx = lower.lastIndexOf('.');
        return idx >= 0 ? lower.slice(idx + 1) : '';
    },

    getFileTypeInfo: function(name) {
        const ext = this.getNormalizedExt(name);
        const make = (category, label, accent, soft) => ({ category: category, label: label, accent: accent, soft: soft || accent });
        const direct = {
            apk: make('package', 'APK', '#f59e0b', '#fcd34d'),
            ipk: make('package', 'IPK', '#fb923c', '#fdba74'),
            txt: make('text', 'TXT', '#60a5fa', '#bfdbfe'),
            log: make('text', 'LOG', '#94a3b8', '#cbd5e1'),
            md: make('text', 'MD', '#22c55e', '#86efac'),
            json: make('config', 'JSON', '#10b981', '#6ee7b7'),
            xml: make('config', 'XML', '#14b8a6', '#99f6e4'),
            yml: make('config', 'YAML', '#22c55e', '#86efac'),
            yaml: make('config', 'YAML', '#22c55e', '#86efac'),
            ini: make('config', 'INI', '#84cc16', '#bef264'),
            cfg: make('config', 'CFG', '#84cc16', '#bef264'),
            conf: make('config', 'CONF', '#84cc16', '#bef264'),
            leases: make('config', 'LEASE', '#65a30d', '#a3e635'),
            sh: make('code', 'SH', '#a855f7', '#d8b4fe'),
            bash: make('code', 'SH', '#a855f7', '#d8b4fe'),
            zsh: make('code', 'SH', '#a855f7', '#d8b4fe'),
            js: make('code', 'JS', '#eab308', '#fde047'),
            ts: make('code', 'TS', '#3b82f6', '#93c5fd'),
            html: make('code', 'HTML', '#f97316', '#fdba74'),
            css: make('code', 'CSS', '#06b6d4', '#67e8f9'),
            go: make('code', 'GO', '#00add8', '#67e8f9'),
            c: make('code', 'C', '#6366f1', '#a5b4fc'),
            h: make('code', 'H', '#818cf8', '#c7d2fe'),
            cpp: make('code', 'C++', '#6366f1', '#a5b4fc'),
            hpp: make('code', 'H++', '#818cf8', '#c7d2fe'),
            py: make('code', 'PY', '#3776ab', '#93c5fd'),
            lua: make('code', 'LUA', '#2563eb', '#93c5fd'),
            java: make('code', 'JAVA', '#ea580c', '#fdba74'),
            php: make('code', 'PHP', '#7c3aed', '#c4b5fd'),
            rb: make('code', 'RB', '#dc2626', '#fca5a5'),
            rs: make('code', 'RS', '#f97316', '#fdba74'),
            toml: make('config', 'TOML', '#14b8a6', '#99f6e4'),
            mk: make('code', 'MK', '#a855f7', '#d8b4fe'),
            ps1: make('code', 'PS', '#2563eb', '#93c5fd'),
            psm1: make('code', 'PS', '#2563eb', '#93c5fd'),
            swift: make('code', 'SWIFT', '#f97316', '#fdba74'),
            tsx: make('code', 'TSX', '#3b82f6', '#93c5fd'),
            zip: make('archive', 'ZIP', '#8b5cf6', '#c4b5fd'),
            tar: make('archive', 'TAR', '#8b5cf6', '#c4b5fd'),
            'tar.gz': make('archive', 'TGZ', '#8b5cf6', '#c4b5fd'),
            tgz: make('archive', 'TGZ', '#8b5cf6', '#c4b5fd'),
            'tar.xz': make('archive', 'TXZ', '#8b5cf6', '#c4b5fd'),
            txz: make('archive', 'TXZ', '#8b5cf6', '#c4b5fd'),
            gz: make('archive', 'GZ', '#8b5cf6', '#c4b5fd'),
            xz: make('archive', 'XZ', '#8b5cf6', '#c4b5fd'),
            '7z': make('archive', '7Z', '#8b5cf6', '#c4b5fd'),
            rar: make('archive', 'RAR', '#8b5cf6', '#c4b5fd'),
            pdf: make('doc', 'PDF', '#ef4444', '#fca5a5'),
            doc: make('doc', 'DOC', '#2563eb', '#93c5fd'),
            docx: make('doc', 'DOCX', '#2563eb', '#93c5fd'),
            xls: make('doc', 'XLS', '#16a34a', '#86efac'),
            xlsx: make('doc', 'XLSX', '#16a34a', '#86efac'),
            csv: make('text', 'CSV', '#16a34a', '#86efac'),
            ppt: make('doc', 'PPT', '#ea580c', '#fdba74'),
            pptx: make('doc', 'PPTX', '#ea580c', '#fdba74'),
            mp3: make('media-audio', 'AUDIO', '#ec4899', '#f9a8d4'),
            wav: make('media-audio', 'AUDIO', '#ec4899', '#f9a8d4'),
            flac: make('media-audio', 'AUDIO', '#ec4899', '#f9a8d4'),
            aac: make('media-audio', 'AUDIO', '#ec4899', '#f9a8d4'),
            m4a: make('media-audio', 'AUDIO', '#ec4899', '#f9a8d4'),
            mp4: make('media-video', 'VIDEO', '#f43f5e', '#fda4af'),
            webm: make('media-video', 'VIDEO', '#f43f5e', '#fda4af'),
            ogg: make('media-video', 'VIDEO', '#f43f5e', '#fda4af'),
            mov: make('media-video', 'VIDEO', '#f43f5e', '#fda4af')
        };
        if (direct[ext]) return direct[ext];
        if (!ext) return make('generic', 'FILE', '#94a3b8', '#cbd5e1');
        if (ext.length <= 5) return make('generic', ext.toUpperCase(), '#94a3b8', '#cbd5e1');
        return make('generic', 'FILE', '#94a3b8', '#cbd5e1');
    },

    makeTypedFileSVG: function(info) {
        const label = String((info && info.label) || 'FILE').replace(/[^A-Za-z0-9+]/g, '').slice(0, 5).toUpperCase() || 'FILE';
        const accent = String((info && info.accent) || '#94a3b8');
        const soft = String((info && info.soft) || accent);
        const category = String((info && info.category) || 'generic');

        if (category === 'package') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<path d="M14 26l18-9 18 9-18 9-18-9z" fill="', soft, '"/>',
                '<path d="M14 26v18l18 9V35z" fill="', accent, '" opacity="0.96"/>',
                '<path d="M50 26v18l-18 9V35z" fill="#d48b00" opacity="0.92"/>',
                '<path d="M23 21l18 9" stroke="#fff7d6" stroke-width="2" stroke-linecap="round" opacity="0.7"/>',
                '<path d="M32 17v18" stroke="#fff7d6" stroke-width="1.8" opacity="0.5"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="9.8" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'archive') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<rect x="17" y="18" width="30" height="30" rx="6" fill="#f5f3ff" stroke="', accent, '" stroke-width="2.2"/>',
                '<rect x="29" y="16" width="6" height="34" rx="2.5" fill="', accent, '"/>',
                '<rect x="30.2" y="20" width="3.6" height="3.6" rx="1" fill="#ffffff"/>',
                '<rect x="30.2" y="26" width="3.6" height="3.6" rx="1" fill="#ffffff"/>',
                '<rect x="30.2" y="32" width="3.6" height="3.6" rx="1" fill="#ffffff"/>',
                '<rect x="30.2" y="38" width="3.6" height="3.6" rx="1" fill="#ffffff"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="9.8" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'config') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<circle cx="32" cy="31" r="18" fill="#f0fdf4" stroke="', accent, '" stroke-width="2.2"/>',
                '<path d="M20 24h24" stroke="', accent, '" stroke-width="3" stroke-linecap="round"/>',
                '<circle cx="28" cy="24" r="4" fill="', accent, '"/>',
                '<path d="M20 31h24" stroke="', accent, '" stroke-width="3" stroke-linecap="round" opacity="0.85"/>',
                '<circle cx="37" cy="31" r="4" fill="', accent, '" opacity="0.95"/>',
                '<path d="M20 38h24" stroke="', accent, '" stroke-width="3" stroke-linecap="round" opacity="0.72"/>',
                '<circle cx="24" cy="38" r="4" fill="', accent, '" opacity="0.88"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', soft, '"/>',
                '<text x="32" y="63" fill="#14532d" font-size="9.2" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'code') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<rect x="15" y="16" width="34" height="30" rx="6" fill="#0f172a" stroke="#1e293b" stroke-width="1.6"/>',
                '<rect x="15" y="16" width="34" height="7" rx="6" fill="', accent, '"/>',
                '<circle cx="21" cy="19.5" r="1.35" fill="#ffffff"/>',
                '<circle cx="25" cy="19.5" r="1.35" fill="#ffffff" opacity="0.82"/>',
                '<circle cx="29" cy="19.5" r="1.35" fill="#ffffff" opacity="0.64"/>',
                '<path d="M23 31l-5 4.2 5 4.2" stroke="', soft, '" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M41 31l5 4.2-5 4.2" stroke="', soft, '" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M35 29.5l-5 11.2" stroke="#ffffff" stroke-width="1.9" stroke-linecap="round" opacity="0.9"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="9.8" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'media-audio') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<circle cx="32" cy="31" r="18" fill="#fdf2f8" stroke="', accent, '" stroke-width="2.2"/>',
                '<path d="M28 23v15" stroke="', accent, '" stroke-width="3.2" stroke-linecap="round"/>',
                '<path d="M28 23l11-3v15" stroke="', accent, '" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
                '<circle cx="26" cy="42" r="4.6" fill="#ffffff" stroke="', accent, '" stroke-width="2.2"/>',
                '<circle cx="40" cy="39" r="4.6" fill="#ffffff" stroke="', accent, '" stroke-width="2.2"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="8.9" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">AUDIO</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'media-video') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<circle cx="32" cy="31" r="18" fill="#fff1f2" stroke="', accent, '" stroke-width="2.2"/>',
                '<circle cx="32" cy="31" r="10" fill="', soft, '" opacity="0.48"/>',
                '<path d="M28 24.5l12 6.5-12 6.5z" fill="', accent, '"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="8.9" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">VIDEO</text>',
                '</svg>'
            ].join('');
        }

        if (category === 'doc') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<defs><linearGradient id="qfDocBg" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#ffffff"/><stop offset="100%" stop-color="#eef2f7"/></linearGradient></defs>',
                '<path d="M16 4h22l14 14v46a4 4 0 0 1-4 4H16a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z" fill="url(#qfDocBg)"/>',
                '<path d="M38 4v10a4 4 0 0 0 4 4h10" fill="#dde5ef"/>',
                '<path d="M38 4l14 14H42a4 4 0 0 1-4-4V4z" fill="#cfd8e3"/>',
                '<rect x="20" y="22" width="24" height="16" rx="3" fill="', soft, '" opacity="0.45"/>',
                '<rect x="23" y="26" width="18" height="2.8" rx="1.4" fill="', accent, '"/>',
                '<rect x="23" y="31" width="14" height="2.8" rx="1.4" fill="', accent, '" opacity="0.82"/>',
                '<path d="M45.5 42.5l-5 5" stroke="', accent, '" stroke-width="2.4" stroke-linecap="round"/>',
                '<circle cx="37.5" cy="36.5" r="6" fill="none" stroke="', accent, '" stroke-width="2.2"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
                '<text x="32" y="63" fill="#ffffff" font-size="9.4" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '<rect x="12" y="4" width="40" height="64" rx="4" fill="none" stroke="#cbd5e1" stroke-width="1.2"/>',
                '</svg>'
            ].join('');
        }

        if (category === 'text') {
            return [
                '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
                '<defs><linearGradient id="qfTextBg" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#ffffff"/><stop offset="100%" stop-color="#eef2f7"/></linearGradient></defs>',
                '<path d="M16 4h22l14 14v46a4 4 0 0 1-4 4H16a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z" fill="url(#qfTextBg)"/>',
                '<path d="M38 4v10a4 4 0 0 0 4 4h10" fill="#dde5ef"/>',
                '<path d="M38 4l14 14H42a4 4 0 0 1-4-4V4z" fill="#cfd8e3"/>',
                '<rect x="18" y="22" width="28" height="3.6" rx="1.8" fill="', accent, '"/>',
                '<rect x="18" y="29" width="24" height="3.6" rx="1.8" fill="', accent, '" opacity="0.82"/>',
                '<rect x="18" y="36" width="20" height="3.6" rx="1.8" fill="', accent, '" opacity="0.64"/>',
                '<rect x="12" y="56" width="40" height="10" rx="5" fill="', soft, '"/>',
                '<text x="32" y="63" fill="#1e3a8a" font-size="9.8" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
                '<rect x="12" y="4" width="40" height="64" rx="4" fill="none" stroke="#cbd5e1" stroke-width="1.2"/>',
                '</svg>'
            ].join('');
        }

        return [
            '<svg viewBox="0 0 64 72" width="56" height="56" aria-hidden="true">',
            '<defs><linearGradient id="qfGenericBg" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#ffffff"/><stop offset="100%" stop-color="#eef2f7"/></linearGradient></defs>',
            '<path d="M16 4h22l14 14v46a4 4 0 0 1-4 4H16a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z" fill="url(#qfGenericBg)"/>',
            '<path d="M38 4v10a4 4 0 0 0 4 4h10" fill="#dde5ef"/>',
            '<path d="M38 4l14 14H42a4 4 0 0 1-4-4V4z" fill="#cfd8e3"/>',
            '<circle cx="32" cy="31" r="10" fill="', soft, '"/>',
            '<path d="M32 25v12M26 31h12" stroke="', accent, '" stroke-width="2.4" stroke-linecap="round"/>',
            '<rect x="12" y="56" width="40" height="10" rx="5" fill="', accent, '"/>',
            '<text x="32" y="63" fill="#ffffff" font-size="9.8" font-weight="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif">', label, '</text>',
            '<rect x="12" y="4" width="40" height="64" rx="4" fill="none" stroke="#cbd5e1" stroke-width="1.2"/>',
            '</svg>'
        ].join('');
    },

    makeFileIconNode: function(fPath, f) {
        if (f.isDir) return this.makeIcon(this.icons.folder);
        if (this.isImageFileName(f.name)) {
            const img = E('img', {
                class: 'qf-thumb' + (String(f.name || '').toLowerCase().endsWith('.svg') ? ' qf-thumb-svg' : ''),
                src: downloadUrl(fPath),
                loading: 'lazy',
                decoding: 'async',
                alt: f.name || '',
                error: ev => {
                    const parent = ev.target && ev.target.parentNode;
                    if (parent) {
                        parent.textContent = '';
                        parent.appendChild(this.makeIcon(this.makeTypedFileSVG(this.getFileTypeInfo(f.name))));
                    }
                }
            });
            return img;
        }
        return this.makeIcon(this.makeTypedFileSVG(this.getFileTypeInfo(f.name)));
    },

    appendFileItem: function(grid, f) {
        const fPath = this.currentPath === '/' ? '/' + f.name : this.currentPath + '/' + f.name;
        let item;
        const chk = E('input', { type: 'checkbox', class: 'qf-checkbox qf-native-check', click: ev => {
            ev.stopPropagation();
            if (ev.target.checked) this.selectedFiles.add(fPath);
            else this.selectedFiles.delete(fPath);
            item.classList.toggle('selected', this.selectedFiles.has(fPath));
            this.updateSelectionUI();
        }});
        const ownerText = [f.owner || '-', f.group ? '/' + f.group : ''].join('');
        const editIcon = this.makeIcon('<svg class="qf-row-action-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>');
        const modeIcon = this.makeIcon('<svg class="qf-row-action-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>');
        const deleteIcon = this.makeIcon('<svg class="qf-row-action-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v5M14 11v5"/></svg>');
        const actions = E('div', { class: 'qf-item-actions' }, [
            E('button', { class: 'qf-row-action', title: '重命名', click: ev => { ev.preventDefault(); ev.stopPropagation(); this.renameItem(fPath, f.name); } }, [editIcon]),
            E('button', { class: 'qf-row-action', title: '修改权限', click: ev => { ev.preventDefault(); ev.stopPropagation(); this.changeMode(fPath); } }, [modeIcon]),
            E('button', { class: 'qf-row-action qf-danger', title: '删除', click: ev => { ev.preventDefault(); ev.stopPropagation(); this.deleteOne(fPath); } }, [deleteIcon])
        ]);
        const nameCells = this.viewMode === 'list' ? [
            E('div', { class: 'qf-list-name-cell' }, [
                E('label', { class: 'qf-row-select qf-check-control', click: ev => ev.stopPropagation() }, [chk, E('span', { class: 'qf-checkmark' })]),
                E('div', { class: 'qf-item-icon' }, [this.makeFileIconNode(fPath, f)]),
                E('div', { class: 'qf-item-name' }, f.name)
            ])
        ] : [
            E('span', { class: 'qf-row-select qf-grid-select', 'aria-hidden': 'true' }, [chk]),
            E('div', { class: 'qf-item-icon' }, [this.makeFileIconNode(fPath, f)]),
            E('div', { class: 'qf-item-name' }, f.name)
        ];
        item = E('div', { class: 'qf-item qf-selectable-item' + (f.isDir ? ' qf-folder-item' : '') }, nameCells.concat([
            E('div', { class: 'qf-item-meta' }, [
                E('span', { class: 'qf-col-size' }, f.isDir ? '—' : this.formatSize(f.size || 0)),
                E('span', { class: 'qf-col-time' }, this.formatTime(f.time)),
                E('span', { class: 'qf-col-mode' }, f.mode || ''),
                E('span', { class: 'qf-col-owner' }, ownerText)
            ]),
            actions
        ]));
        item.dataset.qfPath = fPath;
        item.addEventListener('click', ev => {
            ev.stopPropagation();
            this.clearContextTarget();
            if (f.isDir) this.refresh(fPath);
            else this.smartOpenFile(fPath, f.name);
        });
        item.addEventListener('contextmenu', ev => {
            ev.preventDefault();
            ev.stopPropagation();
            this.setContextTarget(item);
            this.showContextMenu(ev, fPath, f.name, f.isDir);
        });
        grid.appendChild(item);
    },

    filterItems: function(keyword) {
        const kw = String(keyword || '').toLowerCase();
        document.querySelectorAll('.qf-grid .qf-item').forEach(item => {
            const name = item.querySelector('.qf-item-name');
            if (name && !name.innerText.includes('返回上一级')) {
                const visible = name.innerText.toLowerCase().includes(kw);
                item.style.display = visible ? '' : 'none';
                if (!visible && item.classList.contains('qf-selectable-item')) {
                    this.selectedFiles.delete(item.dataset.qfPath);
                    item.classList.remove('selected');
                    const chk = item.querySelector('.qf-checkbox');
                    if (chk) chk.checked = false;
                }
            }
        });
        this.updateSelectionUI();
    },

    showNewMenu: function(ev) {
        this.removeMenus();
        const menu = E('div', { class: 'qf-context-menu', style: `left:${ev.pageX}px;top:${ev.pageY + 10}px;` }, [
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(true); menu.remove(); } }, '新建文件夹'),
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(false); menu.remove(); } }, '新建文件')
        ]);
        this.showMenu(menu);
    },

    showContextMenu: function(ev, path, name, isDir) {
        this.removeMenus();
        const ext = this.getNormalizedExt(name);
        const lowerName = name.toLowerCase();
        const isArch = ['zip', 'gz', 'tgz', 'tar', 'txz', 'tar.gz', 'tar.xz', 'xz', '7z', 'rar'].includes(ext) || lowerName.endsWith('.tar.gz') || lowerName.endsWith('.tar.xz');
        const menu = E('div', { class: 'qf-context-menu', style: `left:${ev.pageX}px;top:${ev.pageY}px;` }, [
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(true); menu.remove(); } }, '新建文件夹'),
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(false); menu.remove(); } }, '新建文件'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item' + (isDir ? ' disabled' : ''), click: () => { if (!isDir) this.openEditor(path); else ui.addNotification(null, E('p', {}, '目录不能编辑'), 'warning'); menu.remove(); } }, '编辑'),
            E('div', { class: 'qf-menu-item', click: () => { this.renameItem(path, name); menu.remove(); } }, '重命名'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item', click: () => { this.clipboard = { action: 'copy', files: [path] }; this.updateToolbarState(); menu.remove(); } }, '复制'),
            E('div', { class: 'qf-menu-item', click: () => { this.clipboard = { action: 'move', files: [path] }; this.updateToolbarState(); menu.remove(); } }, '剪切'),
            E('div', { class: 'qf-menu-item', click: () => { this.paste(); menu.remove(); } }, '粘贴'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item' + (isDir ? ' disabled' : ''), click: () => { if (!isDir) window.open(downloadUrl(path), '_blank'); menu.remove(); } }, '下载'),
            E('div', { class: 'qf-menu-item', style: 'color:#f56c6c;', click: () => { this.deleteOne(path); menu.remove(); } }, '删除'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item', click: () => { this.showFileProperties(path); menu.remove(); } }, '查看属性'),
            E('div', { class: 'qf-menu-item', click: () => { this.copyPath(path); menu.remove(); } }, '复制路径'),
            E('div', { class: 'qf-menu-item', click: () => { this.changeMode(path); menu.remove(); } }, '修改权限'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'tar.gz'); menu.remove(); } }, '压缩 (.tar.gz)'),
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'tar.xz'); menu.remove(); } }, '压缩 (.tar.xz)'),
            E('div', { class: 'qf-menu-item', click: () => { this.compress(path, 'zip'); menu.remove(); } }, '压缩 (.zip)'),
            E('div', { class: 'qf-menu-item' + (isArch ? '' : ' disabled'), click: () => { if (isArch) this.extract(path); else ui.addNotification(null, E('p', {}, '请选择压缩包'), 'warning'); menu.remove(); } }, '解压')
        ]);
        this.showMenu(menu);
    },

    showBlankContextMenu: function(ev) {
        this.removeMenus();
        const menu = E('div', { class: 'qf-context-menu', style: `left:${ev.pageX}px;top:${ev.pageY}px;` }, [
            E('div', { class: 'qf-menu-item', click: () => { this.refresh(this.currentPath); menu.remove(); } }, '刷新'),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item', click: () => { this.fileInput.click(); menu.remove(); } }, '上传文件'),
            E('div', { class: 'qf-menu-item', click: () => { this.remoteDownload(); menu.remove(); } }, '在线下载'),
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(true); menu.remove(); } }, '新建文件夹'),
            E('div', { class: 'qf-menu-item', click: () => { this.createNew(false); menu.remove(); } }, '新建文件'),
            E('div', { class: 'qf-menu-item', click: () => { this.paste(); menu.remove(); } }, '粘贴' + (this.clipboard ? ` (${this.clipboard.files.length}项)` : '')),
            E('div', { class: 'qf-menu-separator' }),
            E('div', { class: 'qf-menu-item', click: () => { this.openTerminal(); menu.remove(); } }, '终端')
        ]);
        this.showMenu(menu);
    },

    showMenu: function(menu) {
        document.body.appendChild(menu);
        const closeMenu = () => {
            if (menu) menu.remove();
            this.clearContextTarget();
            document.removeEventListener('click', closeMenu);
        };
        setTimeout(() => document.addEventListener('click', closeMenu), 10);
    },

    removeMenus: function() {
        document.querySelectorAll('.qf-context-menu').forEach(el => el.remove());
    },

    smartOpenFile: function(path, name) {
        const lower = name.toLowerCase();
        const base = lower.split('/').pop() || lower;
        const ext = this.getNormalizedExt(name);
        const imgs = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'ico', 'bmp', 'avif'];
        const vids = ['mp4', 'webm', 'ogg', 'mov'];
        const pkgs = ['apk', 'ipk'];
        const archs = ['zip', 'gz', 'tgz', 'tar', 'txz', 'tar.gz', 'tar.xz', 'xz', '7z', 'rar'];
        const txts = ['txt', 'text', 'conf', 'cfg', 'cnf', 'toml', 'sh', 'bash', 'zsh', 'ps1', 'psm1', 'json', 'js', 'ts', 'tsx', 'html', 'css', 'go', 'rs', 'java', 'swift', 'c', 'cpp', 'h', 'hpp', 'yml', 'yaml', 'xml', 'ini', 'md', 'log', 'csv', 'list', 'leases', 'mk'];
        const specialText = base === 'dockerfile' || base.startsWith('dockerfile.') || base === 'makefile';
        if (imgs.includes(ext)) this.previewMedia(path, name, true);
        else if (vids.includes(ext)) this.previewMedia(path, name, false);
        else if (pkgs.includes(ext)) {
            this.confirmPackageInstall(path, name).then(ok => { if (ok) this.install(path); });
        }
        else if (archs.includes(ext) || lower.endsWith('.tar.gz') || lower.endsWith('.tar.xz')) {
            this.confirmAction({ title: '解压文件', message: '是否解压到当前目录？', target: name, okText: '解压' }).then(ok => { if (ok) this.extract(path); });
        }
        else if (specialText || txts.includes(ext) || !name.includes('.')) this.openEditor(path);
        else return;
    },

    previewMedia: function(path, name, isImg) {
        const url = downloadUrl(path);
        const content = isImg ? E('img', { src: url, style: 'max-width:100%;max-height:65vh;border-radius:4px;' }) : E('video', { src: url, controls: true, autoplay: true, style: 'max-width:100%;max-height:65vh;border-radius:4px;' });
        ui.showModal('预览: ' + name, [E('div', { style: 'text-align:center;' }, [content]), E('div', { class: 'right', style: 'margin-top:15px;' }, [E('button', { class: 'btn', click: ui.hideModal }, '关闭')])]);
    },

    createNew: function(isDir) {
        this.inputDialog({
            title: isDir ? '新建文件夹' : '新建文件',
            icon: '✚',
            message: isDir ? '请输入新文件夹名称' : '请输入新文件名称',
            label: '名称',
            help: '名称不能包含 / 或 \\，也不能是 . 或 ..',
            okText: '创建',
            validate: value => !value ? '名称不能为空' : (!validName(value) ? '名称不能包含 / 或 \\，也不能是 . 或 ..' : '')
        }).then(name => {
            if (!name) return;
            const path = this.currentPath === '/' ? '/' + name : this.currentPath + '/' + name;
            apiFetch('create', { method: 'POST', body: formData({ path: path, isDir: String(!!isDir) }) }).then(() => this.refresh(this.currentPath)).catch(notifyError);
        });
    },

    renameItem: function(path, oldName) {
        this.inputDialog({
            title: '重命名',
            icon: '✎',
            message: '请输入新的名称',
            target: oldName,
            label: '新名称',
            value: oldName,
            help: '名称不能包含 / 或 \\，也不能是 . 或 ..',
            okText: '保存',
            validate: value => !value ? '名称不能为空' : (!validName(value) ? '名称不能包含 / 或 \\，也不能是 . 或 ..' : '')
        }).then(newName => {
            if (!newName || newName === oldName) return;
            const dst = this.currentPath === '/' ? '/' + newName : this.currentPath + '/' + newName;
            apiFetch('rename', { method: 'POST', body: formData({ src: path, dst: dst }) }).then(() => this.refresh(this.currentPath)).catch(notifyError);
        });
    },

    paste: function() {
        if (!this.clipboard || !this.clipboard.files || this.clipboard.files.length === 0) {
            return ui.addNotification(null, E('p', {}, '剪贴板为空'), 'warning');
        }
        const action = this.clipboard.action;
        const files = Array.from(this.clipboard.files);
        Promise.all(files.map(src => {
            const name = src.split('/').pop();
            const dst = this.currentPath === '/' ? '/' + name : this.currentPath + '/' + name;
            return this.startBackgroundTaskAction(action, formData({ src: src, dst: dst }), this.currentPath);
        })).then(() => {
            if (action === 'move') this.clipboard = null;
            this.updateToolbarState();
            setTimeout(() => this.refresh(this.currentPath), 1200);
        }).catch(notifyError);
    },

    compress: function(path, format) {
        this.startBackgroundTaskAction('compress', formData({ path: path, format: format || 'tar.gz' }), this.currentPath).catch(notifyError);
    },


    copyPath: function(path) {
        const overlay = E('div', { class: 'qf-overlay' });
        const input = E('input', { class: 'qf-form-input qf-copy-path-value', readonly: 'readonly', value: path });
        const status = E('div', { class: 'qf-form-help' }, '点击“复制”可复制完整路径；也可以直接选中文本手动复制。');
        const close = () => overlay.remove();
        const doCopy = () => {
            const fallback = () => {
                try {
                    input.focus();
                    input.select();
                    document.execCommand('copy');
                    status.textContent = '路径已复制';
                } catch (e) {
                    status.textContent = '浏览器阻止自动复制，请手动选中复制。';
                }
            };
            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(path).then(() => { status.textContent = '路径已复制'; }).catch(fallback);
            } else {
                fallback();
            }
        };
        const dialog = E('div', { class: 'qf-dialog qf-confirm-dialog' }, [
            E('div', { class: 'qf-dialog-header' }, [
                E('span', { class: 'qf-dialog-title' }, '复制路径'),
                E('a', { class: 'qf-dialog-close', click: close }, '×')
            ]),
            E('div', { class: 'qf-dialog-body' }, [
                E('div', { class: 'qf-confirm-content' }, [
                    E('span', { class: 'qf-confirm-icon' }, '⧉'),
                    E('div', { class: 'qf-confirm-main' }, [
                        E('div', { class: 'qf-confirm-message' }, '文件路径'),
                        E('div', { class: 'qf-form-row' }, [input, status])
                    ])
                ])
            ]),
            E('div', { class: 'qf-dialog-footer' }, [
                E('button', { class: 'qf-confirm-cancel', click: close }, '关闭'),
                E('button', { class: 'qf-confirm-ok', click: doCopy }, '复制')
            ])
        ]);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        setTimeout(() => { input.focus(); input.select(); }, 0);
    },

    showFileProperties: function(path) {
        apiFetch('stat', {}, { path: path }).then(res => {
            const d = res.data || {};
            const rows = [
                ['名称', d.name || ''],
                ['路径', d.path || path],
                ['类型', d.type || (d.isDir ? 'directory' : 'file')],
                ['大小', this.formatSize(d.size || 0)],
                ['修改时间', d.mtime || this.formatTime(d.time)],
                ['权限', (d.mode || '') + (d.perm ? ' (' + d.perm + ')' : '')],
                ['所有者', [d.owner || '', d.group ? ':' + d.group : ''].join('')]
            ];
            const body = E('div', { class: 'qf-prop-grid' }, rows.flatMap(r => [
                E('div', { class: 'qf-prop-key' }, r[0]),
                E('div', { class: 'qf-prop-val' }, r[1] || '-')
            ]));
            const closeBtn = E('button', { class: 'qf-btn', click: ui.hideModal }, '关闭');
            ui.showModal('文件属性', [body, E('div', { class: 'right', style: 'padding: 0 18px 18px;' }, [closeBtn])]);
        }).catch(notifyError);
    },

    changeMode: function(path) {
        apiFetch('stat', {}, { path: path }).then(res => {
            const d = res.data || {};
            const oldMode = String(d.perm || '').replace(/^0+/, '') || '644';
            const overlay = E('div', { class: 'qf-overlay' });
            const input = E('input', { class: 'qf-form-input', value: oldMode, maxlength: '4', input: () => { err.textContent = ''; } });
            const err = E('div', { class: 'qf-form-error' }, '');
            const close = () => overlay.remove();
            const save = () => {
                const mode = String(input.value || '').trim();
                if (!/^[0-7]{3,4}$/.test(mode)) {
                    err.textContent = '权限格式错误，请输入 644、755 或 0755 这种八进制权限。';
                    input.focus();
                    return;
                }
                apiFetch('chmod', { method: 'POST', body: formData({ path: path, mode: mode }) }).then(() => {
                    close();
                    this.refresh(this.currentPath);
                }).catch(e => {
                    err.textContent = e.message || String(e);
                });
            };
            const dialog = E('div', { class: 'qf-dialog qf-confirm-dialog' }, [
                E('div', { class: 'qf-dialog-header' }, [
                    E('span', { class: 'qf-dialog-title' }, '修改权限'),
                    E('a', { class: 'qf-dialog-close', click: close }, '×')
                ]),
                E('div', { class: 'qf-dialog-body' }, [
                    E('div', { class: 'qf-confirm-content' }, [
                        E('span', { class: 'qf-confirm-icon' }, '⚙'),
                        E('div', { class: 'qf-confirm-main' }, [
                            E('div', { class: 'qf-confirm-message' }, d.name ? ('修改权限：' + d.name) : '修改权限'),
                            E('div', { class: 'qf-confirm-target' }, path),
                            E('div', { class: 'qf-form-row' }, [
                                E('div', { class: 'qf-form-label' }, '权限值'),
                                input,
                                E('div', { class: 'qf-form-help' }, '常用：644=普通文件，755=可执行文件/目录。'),
                                err
                            ])
                        ])
                    ])
                ]),
                E('div', { class: 'qf-dialog-footer' }, [
                    E('button', { class: 'qf-confirm-cancel', click: close }, '取消'),
                    E('button', { class: 'qf-confirm-ok', click: save }, '保存')
                ])
            ]);
            overlay.appendChild(dialog);
            document.body.appendChild(overlay);
            setTimeout(() => { input.focus(); input.select(); }, 0);
        }).catch(notifyError);
    },

    remoteDownload: function() {
        const overlay = E('div', { class: 'qf-overlay' });
        const urlInput = E('input', { class: 'qf-form-input', placeholder: 'https://example.com/file.bin', input: () => { err.textContent = ''; this.guessDownloadName(urlInput.value, nameInput); } });
        const nameInput = E('input', { class: 'qf-form-input', placeholder: '留空则自动识别文件名', input: () => { err.textContent = ''; nameInput.dataset.userEdited = '1'; } });
        const err = E('div', { class: 'qf-form-error' }, '');
        const close = () => {
            overlay.remove();
            document.removeEventListener('keydown', onKey);
        };
        const startDownload = () => {
            const url = String(urlInput.value || '').trim();
            const name = String(nameInput.value || '').trim();
            if (!url) {
                err.textContent = '下载 URL 不能为空。';
                urlInput.focus();
                return;
            }
            if (!/^https?:\/\//i.test(url)) {
                err.textContent = '只支持 http:// 或 https:// URL。';
                urlInput.focus();
                return;
            }
            if (name && !validName(name)) {
                err.textContent = '文件名不能包含 / 或 \\，也不能是 . 或 ..。';
                nameInput.focus();
                return;
            }
            close();
            this.startBackgroundTaskAction('remote_download_start', formData({ url: url, path: this.currentPath, name: name }), this.currentPath)
                .then(() => this.showTaskCenter())
                .catch(notifyError);
        };
        const onKey = ev => {
            if (ev.key === 'Escape') close();
            if (ev.key === 'Enter' && (ev.ctrlKey || ev.metaKey)) startDownload();
        };
        const dialog = E('div', { class: 'qf-dialog qf-confirm-dialog qf-download-dialog' }, [
            E('div', { class: 'qf-dialog-header' }, [
                E('span', { class: 'qf-dialog-title' }, '下载文件'),
                E('a', { class: 'qf-dialog-close', click: close }, '×')
            ]),
            E('div', { class: 'qf-dialog-body' }, [
                E('div', { class: 'qf-confirm-content' }, [
                    E('span', { class: 'qf-confirm-icon' }, '☁'),
                    E('div', { class: 'qf-confirm-main' }, [
                        E('div', { class: 'qf-confirm-message' }, '添加一个后台下载任务'),
                        E('div', { class: 'qf-download-path' }, '保存目录：' + this.currentPath),
                        E('div', { class: 'qf-download-grid' }, [
                            E('label', { class: 'qf-form-row' }, [
                                E('span', { class: 'qf-form-label' }, '下载 URL'),
                                urlInput
                            ]),
                            E('label', { class: 'qf-form-row' }, [
                                E('span', { class: 'qf-form-label' }, '保存文件名'),
                                nameInput,
                                E('span', { class: 'qf-form-help' }, '可留空，后端会根据 URL 或响应头自动识别文件名。')
                            ]),
                            E('div', { class: 'qf-download-tip' }, [
                                E('span', {}, 'i'),
                                E('div', {}, [
                                    E('strong', {}, '后台下载：'),
                                    E('span', {}, '开始后不会遮挡页面，可在右上角“任务”里查看进度或取消。')
                                ])
                            ]),
                            err
                        ])
                    ])
                ])
            ]),
            E('div', { class: 'qf-dialog-footer' }, [
                E('button', { class: 'qf-confirm-cancel', click: close }, '取消'),
                E('button', { class: 'qf-confirm-ok', click: startDownload }, '加入后台任务')
            ])
        ]);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        setTimeout(() => { document.addEventListener('keydown', onKey); urlInput.focus(); }, 0);
    },

    guessDownloadName: function(url, nameInput) {
        if (!nameInput || nameInput.dataset.userEdited === '1') return;
        const current = String(nameInput.value || '').trim();
        if (current) return;
        try {
            const u = new URL(String(url || '').trim());
            const last = decodeURIComponent((u.pathname.split('/').filter(Boolean).pop() || '').trim());
            if (last && validName(last)) nameInput.value = last;
        } catch (e) {}
    },

    ensureClientTasks: function() {
        if (!this.clientTasks) this.clientTasks = new Map();
        return this.clientTasks;
    },

    newClientTask: function(type, title, path) {
        const now = Math.floor(Date.now() / 1000);
        const id = 'page-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
        const task = {
            id: id,
            local: true,
            type: type,
            title: title || type,
            status: 'running',
            progress: 0,
            current: 0,
            total: 0,
            message: '准备中...',
            path: path || '',
            error: '',
            log: '',
            created: now,
            updated: now,
            cancelable: false,
            cancel: null
        };
        this.ensureClientTasks().set(id, task);
        this.refreshTaskCenterIfOpen();
        return task;
    },

    updateClientTask: function(task, patch) {
        if (!task) return;
        Object.assign(task, patch || {});
        task.updated = Math.floor(Date.now() / 1000);
        this.ensureClientTasks().set(task.id, task);
        this.refreshTaskCenterIfOpen();
    },

    refreshTaskCenterIfOpen: function() {
        const state = this.taskCenterState;
        if (state && !state.closed && typeof state.refresh === 'function') state.refresh();
    },

    dismissTaskToast: function() {
        const state = this.taskToastState;
        if (!state) return;
        this.taskToastState = null;
        if (state.timer) clearTimeout(state.timer);
        if (state.node && state.node.parentNode) {
            state.toast.classList.remove('show');
            setTimeout(() => {
                if (state.node && state.node.parentNode) state.node.remove();
            }, 190);
        }
    },

    showTaskToast: function(title, message, tone, options) {
        const opts = options || {};
        this.dismissTaskToast();
        const wrapper = E('div', { class: 'qf-task-toast-wrap' + (this.theme === 'light' ? ' qf-light' : '') });
        const actions = E('div', { class: 'qf-task-toast-actions' });
        const toast = E('div', { class: 'qf-task-toast ' + (tone || 'info') }, [
            E('span', { class: 'qf-task-toast-dot' }),
            E('div', { class: 'qf-task-toast-content' }, [
                E('div', { class: 'qf-task-toast-title' }, title || '任务状态'),
                message ? E('div', { class: 'qf-task-toast-message' }, message) : E('span', {})
            ]),
            actions
        ]);
        wrapper.appendChild(toast);
        document.body.appendChild(wrapper);
        const close = () => {
            if (this.taskToastState && this.taskToastState.node === wrapper) this.dismissTaskToast();
            else if (wrapper.parentNode) wrapper.remove();
        };
        if (opts.openTasks) {
            actions.appendChild(E('button', { type: 'button', class: 'qf-task-toast-link', click: ev => {
                ev.preventDefault();
                ev.stopPropagation();
                close();
                this.showTaskCenter();
            } }, '查看'));
        }
        actions.appendChild(E('button', { type: 'button', class: 'qf-task-toast-close', title: '关闭', click: ev => {
            ev.preventDefault();
            ev.stopPropagation();
            close();
        } }, '×'));
        const timeout = Number(opts.timeout == null ? (tone === 'error' ? 6000 : 3400) : opts.timeout);
        const state = { node: wrapper, toast: toast, timer: null };
        this.taskToastState = state;
        requestAnimationFrame(() => toast.classList.add('show'));
        if (timeout > 0) state.timer = setTimeout(close, timeout);
    },

    taskTypeLabel: function(type) {
        const labels = { upload: '上传', install: '安装', remote_download: '下载', compress: '压缩', extract: '解压', copy: '复制', move: '移动' };
        return labels[type] || type || '任务';
    },

    taskStateLabel: function(status) {
        const labels = { queued: '等待中', running: '进行中', cancelling: '取消中', done: '成功', error: '失败', cancelled: '已取消' };
        return labels[status] || status || '';
    },

    showTaskCenter: function() {
        if (this.taskCenterState && !this.taskCenterState.closed) {
            this.taskCenterState.refresh();
            return;
        }
        const overlay = E('div', { class: 'qf-overlay' });
        const body = E('div', { class: 'qf-task-list' });
        const note = E('span', { class: 'qf-task-footer-note' }, '上传与安装任务在当前页面保持运行；刷新或离开页面会中断仍在上传的文件。');
        const clearBtn = E('button', { class: 'qf-btn' }, '清除已完成记录');
        const closeBtn = E('button', { class: 'qf-btn' }, '关闭');
        const dialog = E('div', { class: 'qf-dialog qf-task-dialog' }, [
            E('div', { class: 'qf-dialog-header' }, [
                E('span', { class: 'qf-dialog-title' }, '后台任务'),
                E('a', { class: 'qf-dialog-close' }, '×')
            ]),
            E('div', { class: 'qf-dialog-body' }, [body]),
            E('div', { class: 'qf-dialog-footer' }, [note, clearBtn, closeBtn])
        ]);
        let refreshPending = false;
        const state = { overlay: overlay, dialog: dialog, closed: false, timer: null, refresh: null };
        const close = () => {
            if (state.closed) return;
            state.closed = true;
            if (state.timer) clearInterval(state.timer);
            overlay.remove();
            if (this.taskCenterState === state) this.taskCenterState = null;
        };
        const rowFor = t => {
            const pct = Math.max(0, Math.min(100, Number(t.progress || 0)));
            const stateText = this.taskStateLabel(t.status);
            const terminal = ['done', 'error', 'cancelled'].includes(t.status);
            const cancelBtn = E('button', { class: 'qf-btn' }, '取消');
            cancelBtn.disabled = terminal || !t.cancelable;
            cancelBtn.onclick = ev => {
                ev.preventDefault();
                ev.stopPropagation();
                if (cancelBtn.disabled) return;
                if (t.local && typeof t.cancel === 'function') {
                    t.cancel();
                } else {
                    apiFetch('task_cancel', { method: 'POST', body: formData({ id: t.id }) }).then(() => state.refresh()).catch(notifyError);
                }
            };
            let meta = `${pct}%  ${t.message || ''}`;
            if (t.total > 0) meta += `\n${this.formatSize(t.current || 0)} / ${this.formatSize(t.total || 0)}`;
            else if (t.current > 0) meta += `\n${this.formatSize(t.current || 0)}`;
            if (t.error) meta += '\n错误：' + t.error;
            if (t.path) meta += '\n路径：' + t.path;
            const children = [
                E('div', { class: 'qf-task-title' }, [
                    E('div', { class: 'qf-task-title-left' }, [
                        E('span', {}, `${this.taskTypeLabel(t.type)} · ${t.title || t.message || ''}`),
                        E('span', { class: 'qf-task-state ' + (terminal ? t.status : '') }, stateText)
                    ]),
                    cancelBtn
                ]),
                E('div', { class: 'qf-progress-bar' }, [E('div', { class: 'qf-progress-fill', style: `width:${pct}%;` })]),
                E('div', { class: 'qf-task-meta' }, meta)
            ];
            if (t.log) {
                children.push(E('details', { class: 'qf-task-log-wrap' }, [
                    E('summary', {}, '查看完整日志'),
                    E('pre', { class: 'qf-task-log' }, t.log)
                ]));
            }
            return E('div', { class: 'qf-task-row' }, children);
        };
        const render = (serverTasks, loadError) => {
            if (state.closed) return;
            body.textContent = '';
            const localTasks = Array.from(this.ensureClientTasks().values());
            const items = localTasks.concat(serverTasks || []).sort((a, b) => Number(b.updated || 0) - Number(a.updated || 0));
            if (!items.length) {
                body.appendChild(E('div', { class: 'qf-empty' }, loadError ? '任务读取失败：' + loadError.message : '暂无后台任务'));
                return;
            }
            if (loadError) body.appendChild(E('div', { class: 'qf-task-meta', style: 'padding:0 0 10px 2px;color:#f56c6c;' }, '服务端任务读取失败：' + loadError.message));
            items.forEach(t => body.appendChild(rowFor(t)));
        };
        state.refresh = () => {
            if (state.closed || refreshPending) return;
            refreshPending = true;
            apiFetch('task_list', {}, {}).then(res => render(res.data || [], null)).catch(err => render([], err)).finally(() => { refreshPending = false; });
        };
        clearBtn.onclick = ev => {
            ev.preventDefault();
            Array.from(this.ensureClientTasks().entries()).forEach(([id, t]) => {
                if (['done', 'error', 'cancelled'].includes(t.status)) this.clientTasks.delete(id);
            });
            state.refresh();
        };
        closeBtn.onclick = ev => { ev.preventDefault(); close(); };
        dialog.querySelector('.qf-dialog-close').onclick = ev => { ev.preventDefault(); close(); };
        overlay.onclick = ev => { if (ev.target === overlay) close(); };
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        this.taskCenterState = state;
        state.refresh();
        state.timer = setInterval(() => state.refresh(), 1100);
    },

    extract: function(path) {
        this.startBackgroundTaskAction('extract', formData({ path: path }), this.currentPath).catch(notifyError);
    },

    uploadFiles: function(files) {
        if (!files || files.length === 0) return;
        const list = Array.from(files);
        if (this.fileInput) this.fileInput.value = '';
        const totalBytes = list.reduce((sum, file) => sum + Number(file.size || 0), 0);
        const task = this.newClientTask('upload', list.length === 1 ? list[0].name : `${list.length} 个文件`, this.currentPath);
        this.updateClientTask(task, {
            total: totalBytes,
            message: `等待上传 ${list.length} 个文件`,
            cancelable: true
        });
        let index = 0;
        let completedBytes = 0;
        let currentXHR = null;
        let cancelled = false;
        task.cancel = () => {
            if (cancelled || ['done', 'error', 'cancelled'].includes(task.status)) return;
            cancelled = true;
            task.cancelable = false;
            if (currentXHR) currentXHR.abort();
            this.updateClientTask(task, { status: 'cancelled', message: '上传已取消', error: '', cancelable: false });
            this.showTaskToast('上传已取消', task.title, 'cancelled', { timeout: 3200, openTasks: true });
        };
        this.showTaskToast('已加入后台任务', task.title + ' · 可在“任务”中查看进度或取消', 'info', { timeout: 3600, openTasks: true });
        const failTask = message => {
            this.updateClientTask(task, { status: 'error', message: '上传失败', error: message, cancelable: false });
            this.showTaskToast('上传失败', message, 'error', { timeout: 6200, openTasks: true });
        };
        const uploadNext = () => {
            if (cancelled) return;
            if (index >= list.length) {
                this.updateClientTask(task, { status: 'done', progress: 100, current: totalBytes, message: '上传完成', cancelable: false });
                this.showTaskToast('上传完成', task.title, 'success', { timeout: 3000, openTasks: true });
                this.refresh(this.currentPath);
                return;
            }
            const file = list[index];
            const fileNo = index + 1;
            const baseBytes = completedBytes;
            const fd = new FormData();
            fd.append('path', this.currentPath);
            fd.append('file', file, file.name);
            const xhr = new XMLHttpRequest();
            currentXHR = xhr;
            xhr.open('POST', apiUrl('upload'), true);
            const sid = luciSession();
            if (sid) xhr.setRequestHeader('X-LuCI-Session', sid);
            let lastProgressAt = 0;
            xhr.upload.onprogress = ev => {
                if (cancelled) return;
                const now = Date.now();
                if (now - lastProgressAt < 160 && (!ev.lengthComputable || ev.loaded < ev.total)) return;
                lastProgressAt = now;
                const sentForFile = Math.min(Number(file.size || 0), Number(ev.loaded || 0));
                const current = totalBytes > 0 ? Math.min(totalBytes, baseBytes + sentForFile) : 0;
                const pct = totalBytes > 0 ? current * 100 / totalBytes : (fileNo - 1) * 100 / list.length;
                let msg = `正在上传 ${file.name} (${fileNo}/${list.length})`;
                if (ev.lengthComputable) msg += ` ${this.formatSize(ev.loaded)} / ${this.formatSize(ev.total)}`;
                this.updateClientTask(task, { status: 'running', progress: pct, current: current, message: msg });
            };
            xhr.onload = () => {
                if (cancelled) return;
                let body = {};
                try { body = JSON.parse(xhr.responseText || '{}'); } catch (_) {}
                if (xhr.status >= 200 && xhr.status < 300 && (!body.code || body.code < 400)) {
                    completedBytes += Number(file.size || 0);
                    index += 1;
                    const pct = totalBytes > 0 ? completedBytes * 100 / totalBytes : index * 100 / list.length;
                    this.updateClientTask(task, { progress: pct, current: completedBytes, message: `已上传 ${file.name} (${index}/${list.length})` });
                    uploadNext();
                } else {
                    failTask(friendlyUploadError(xhr.status, body, '上传失败: HTTP ' + xhr.status));
                }
            };
            xhr.onerror = () => { if (!cancelled) failTask('上传失败：网络连接中断，请检查浏览器到路由器的连接'); };
            xhr.ontimeout = () => { if (!cancelled) failTask('上传失败：连接超时，请确认目标目录磁盘速度和剩余空间'); };
            xhr.onabort = () => { if (!cancelled) failTask('上传失败：请求被中断'); };
            xhr.send(fd);
        };
        uploadNext();
    },

    deleteOne: function(path) {
        this.confirmAction({
            title: '删除确认',
            message: '确定删除这个文件/目录吗？此操作不可撤销。',
            target: path,
            okText: '删除',
            type: 'danger'
        }).then(ok => {
            if (!ok) return;
            apiFetch('delete', { method: 'POST', body: formData({ path: path }) }).then(() => this.refresh(this.currentPath)).catch(notifyError);
        });
    },

    deleteSelected: function() {
        if (this.selectedFiles.size === 0) {
            return ui.addNotification(null, E('p', {}, '请先选择要删除的文件或目录'), 'warning');
        }
        const files = Array.from(this.selectedFiles);
        this.confirmAction({
            title: '删除确认',
            message: `确定删除选中的 ${files.length} 个文件/目录吗？此操作不可撤销。`,
            target: files.slice(0, 3).join('\n') + (files.length > 3 ? `\n... 以及另外 ${files.length - 3} 项` : ''),
            okText: '删除',
            type: 'danger'
        }).then(ok => {
            if (!ok) return;
            Promise.all(files.map(path => apiFetch('delete', { method: 'POST', body: formData({ path: path }) })))
                .then(() => { this.clearSelection(); this.refresh(this.currentPath); })
                .catch(notifyError);
        });
    },

    packageNameFromPath: function(path) {
        const p = String(path || '');
        return p.split('/').filter(Boolean).pop() || p || '软件包';
    },

    confirmPackageInstall: function(path, name) {
        const fileName = name || this.packageNameFromPath(path);
        return this.confirmAction({
            title: '安装系统软件包',
            message: '将以 root 权限调用 apk/opkg 安装此软件包，可能修改系统软件包、依赖、配置文件或服务。请确认文件来源可信后再继续。',
            target: '文件名：' + fileName + '\n完整路径：' + path,
            okText: '确认安装',
            type: 'danger'
        });
    },

    copyText: function(text) {
        text = String(text || '');
        if (navigator.clipboard && navigator.clipboard.writeText) return navigator.clipboard.writeText(text);
        return new Promise((resolve, reject) => {
            try {
                const ta = document.createElement('textarea');
                ta.value = text;
                ta.style.position = 'fixed';
                ta.style.left = '-9999px';
                document.body.appendChild(ta);
                ta.focus();
                ta.select();
                const ok = document.execCommand('copy');
                ta.remove();
                ok ? resolve() : reject(new Error('复制失败'));
            } catch (e) {
                reject(e);
            }
        });
    },

    showInstallDialog: function(path) {
        const fileName = this.packageNameFromPath(path);
        const overlay = E('div', { class: 'qf-overlay' });
        const statusText = E('span', {}, '正在安装，等待后端返回安装日志...');
        const status = E('div', { class: 'qf-install-status' }, [E('span', { class: 'qf-install-dot' }), statusText]);
        const logBox = E('div', { class: 'qf-install-log' }, '准备安装...\n');
        const hint = E('div', { class: 'qf-install-actions-left' }, '可收起窗口，安装会在当前页面继续，并可在“任务”中查看日志。');
        const tasksBtn = E('button', { class: 'qf-btn' }, '任务');
        const copyBtn = E('button', { class: 'qf-btn' }, '复制日志');
        const closeBtn = E('button', { class: 'qf-btn' }, '收起');
        let completed = false;
        const close = () => overlay.remove();
        const dialog = E('div', { class: 'qf-dialog qf-install-dialog' }, [
            E('div', { class: 'qf-dialog-header' }, [
                E('span', { class: 'qf-dialog-title', title: path }, '安装软件包 - ' + fileName),
                E('span', { class: 'qf-dialog-close', click: close }, '×')
            ]),
            E('div', { class: 'qf-dialog-body' }, [
                E('div', { class: 'qf-install-status-row' }, [status]),
                E('div', { class: 'qf-install-meta' }, [
                    E('div', { class: 'qf-install-meta-label' }, '文件名'),
                    E('div', { class: 'qf-install-meta-value' }, fileName),
                    E('div', { class: 'qf-install-meta-label' }, '完整路径'),
                    E('div', { class: 'qf-install-meta-value' }, path)
                ]),
                E('div', { class: 'qf-install-warning' }, '提示：这是 root 权限安装操作，会修改系统软件包/依赖，可能触发服务重启或配置变更。'),
                logBox
            ]),
            E('div', { class: 'qf-dialog-footer' }, [
                hint,
                E('div', { class: 'qf-install-footer-actions' }, [tasksBtn, copyBtn, closeBtn])
            ])
        ]);
        const appendLog = text => {
            logBox.textContent += String(text || '');
            logBox.scrollTop = logBox.scrollHeight;
        };
        const setStatus = (cls, text) => {
            status.className = 'qf-install-status' + (cls ? ' ' + cls : '');
            statusText.textContent = text;
            if (completed) hint.textContent = text;
        };
        copyBtn.onclick = ev => {
            ev.preventDefault();
            this.copyText(logBox.textContent).then(() => {
                const old = copyBtn.textContent;
                copyBtn.textContent = '已复制';
                setTimeout(() => { copyBtn.textContent = old; }, 1200);
            }).catch(notifyError);
        };
        tasksBtn.onclick = ev => { ev.preventDefault(); close(); this.showTaskCenter(); };
        closeBtn.onclick = ev => { ev.preventDefault(); close(); };
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        return {
            appendLog: appendLog,
            setStatus: setStatus,
            finish: (ok, text) => {
                completed = true;
                setStatus(ok ? 'success' : 'fail', text || (ok ? '安装成功' : '安装失败'));
                closeBtn.textContent = '关闭';
            },
            setLog: text => { logBox.textContent = String(text || ''); logBox.scrollTop = logBox.scrollHeight; }
        };
    },

    install: function(path) {
        const fileName = this.packageNameFromPath(path);
        const task = this.newClientTask('install', fileName, path);
        this.updateClientTask(task, { message: '正在安装，等待后端返回日志...', cancelable: false });
        const dlg = this.showInstallDialog(path);
        const fd = formData({ path: path, stream: '1' });
        const sid = luciSession();
        const headers = sid ? { 'X-LuCI-Session': sid } : {};
        let raw = '';
        const finishFromLog = () => {
            let ok = false;
            let text = '安装失败';
            let visible = raw;
            const marker = visible.match(/\n?__QF_INSTALL_STATUS__:(OK|FAIL)\s*\n?$/);
            if (marker) {
                ok = marker[1] === 'OK';
                text = ok ? '安装成功' : '安装失败，已保留完整错误日志';
                visible = visible.replace(/\n?__QF_INSTALL_STATUS__:(OK|FAIL)\s*\n?$/, '');
            }
            dlg.setLog(visible || (ok ? '安装完成' : '安装失败'));
            dlg.finish(ok, text);
            this.updateClientTask(task, {
                status: ok ? 'done' : 'error',
                progress: ok ? 100 : task.progress,
                message: text,
                error: ok ? '' : text,
                log: visible || raw,
                cancelable: false
            });
            if (ok) this.refresh(this.currentPath);
        };
        fetch(apiUrl('install'), { method: 'POST', body: fd, credentials: 'include', headers: headers }).then(async res => {
            if (!res.ok) {
                const body = await res.json().catch(() => null);
                throw new Error((body && (body.data || body.msg)) || res.statusText || '安装请求失败');
            }
            if (!res.body || !res.body.getReader) {
                const body = await res.text();
                raw += body;
                this.updateClientTask(task, { log: raw, message: '安装日志已返回，正在确认状态...' });
                finishFromLog();
                return;
            }
            dlg.setLog('正在安装，实时等待后端返回安装日志...\n');
            const reader = res.body.getReader();
            const decoder = new TextDecoder();
            while (true) {
                const part = await reader.read();
                if (part.done) break;
                const text = decoder.decode(part.value, { stream: true });
                raw += text;
                dlg.appendLog(text);
                this.updateClientTask(task, { status: 'running', progress: 35, message: '正在安装，实时接收日志...', log: raw });
            }
            const tail = decoder.decode();
            if (tail) { raw += tail; dlg.appendLog(tail); }
            finishFromLog();
        }).catch(err => {
            const message = String(err && err.message ? err.message : err);
            raw += '\n[QuickFile-Go] 安装请求失败：' + message + '\n';
            dlg.setLog(raw);
            dlg.finish(false, '安装失败，已保留错误信息');
            this.updateClientTask(task, { status: 'error', message: '安装失败，已保留错误信息', error: message, log: raw, cancelable: false });
        });
    },

    isFrontDesktopWindow: function(dialog) {
        if (!dialog || dialog.classList.contains('qf-window-minimized')) return false;
        const visible = Array.from(document.querySelectorAll('.qf-desktop-dialog:not(.qf-window-minimized)'));
        return visible.length > 0 && visible[visible.length - 1] === dialog;
    },

    attachDesktopWindow: function(overlay, dialog, header, buttons, onLayout) {
        buttons = buttons || {};
        const initial = dialog.getBoundingClientRect();
        const state = {
            left: initial.left,
            top: initial.top,
            minimized: false,
            maximized: false,
            restoreMaximized: false,
            minimizedLeft: null,
            minimizedTop: null,
            dragging: false,
            dragPointerId: null,
            disposed: false
        };
        overlay.classList.add('qf-desktop-overlay');
        dialog.classList.add('qf-desktop-dialog');
        header.classList.add('qf-window-drag-handle');
        dialog.style.left = Math.max(8, Math.round(initial.left)) + 'px';
        dialog.style.top = Math.max(8, Math.round(initial.top)) + 'px';

        const updateControls = () => {
            if (buttons.minBtn) {
                buttons.minBtn.textContent = state.minimized ? '↗' : '—';
                buttons.minBtn.title = state.minimized ? '恢复窗口' : '最小化';
                buttons.minBtn.setAttribute('aria-label', buttons.minBtn.title);
            }
            if (buttons.maxBtn) {
                buttons.maxBtn.textContent = state.maximized ? '❐' : '□';
                buttons.maxBtn.title = state.maximized ? '恢复窗口' : '最大化';
                buttons.maxBtn.setAttribute('aria-label', buttons.maxBtn.title);
            }
        };
        const layout = () => {
            if (!state.disposed && typeof onLayout === 'function') setTimeout(onLayout, 50);
        };
        const rememberNormalPosition = () => {
            if (state.minimized || state.maximized) return;
            const rect = dialog.getBoundingClientRect();
            state.left = rect.left;
            state.top = rect.top;
        };
        const clampNormalPosition = () => {
            if (state.minimized || state.maximized) return;
            const rect = dialog.getBoundingClientRect();
            const maxLeft = Math.max(8, window.innerWidth - Math.min(rect.width, window.innerWidth - 16) - 8);
            const maxTop = Math.max(8, window.innerHeight - 54);
            state.left = Math.max(8, Math.min(state.left, maxLeft));
            state.top = Math.max(8, Math.min(state.top, maxTop));
            dialog.style.left = Math.round(state.left) + 'px';
            dialog.style.top = Math.round(state.top) + 'px';
        };
        const clampMinimizedPosition = () => {
            if (!state.minimized) return;
            const rect = dialog.getBoundingClientRect();
            const maxLeft = Math.max(8, window.innerWidth - Math.min(rect.width, window.innerWidth - 16) - 8);
            const maxTop = Math.max(8, window.innerHeight - rect.height - 8);
            state.minimizedLeft = Math.max(8, Math.min(Number.isFinite(state.minimizedLeft) ? state.minimizedLeft : 12, maxLeft));
            state.minimizedTop = Math.max(8, Math.min(Number.isFinite(state.minimizedTop) ? state.minimizedTop : maxTop, maxTop));
            dialog.style.bottom = '';
            dialog.style.left = Math.round(state.minimizedLeft) + 'px';
            dialog.style.top = Math.round(state.minimizedTop) + 'px';
        };
        const normal = () => {
            state.minimized = false;
            state.maximized = false;
            state.restoreMaximized = false;
            overlay.classList.remove('qf-window-minimized-overlay');
            dialog.classList.remove('qf-window-minimized', 'qf-window-maximized');
            dialog.style.bottom = '';
            dialog.style.removeProperty('--qf-window-dock-offset');
            dialog.style.left = Math.round(state.left) + 'px';
            dialog.style.top = Math.round(state.top) + 'px';
            clampNormalPosition();
            updateControls();
            layout();
        };
        const maximize = () => {
            if (!state.minimized && !state.maximized) rememberNormalPosition();
            state.minimized = false;
            state.maximized = true;
            state.restoreMaximized = true;
            overlay.classList.remove('qf-window-minimized-overlay');
            dialog.classList.remove('qf-window-minimized');
            dialog.classList.add('qf-window-maximized');
            dialog.style.bottom = '';
            dialog.style.removeProperty('--qf-window-dock-offset');
            updateControls();
            layout();
        };
        const minimize = () => {
            if (state.minimized) {
                if (state.restoreMaximized) maximize();
                else normal();
                return;
            }
            if (!state.maximized) rememberNormalPosition();
            state.restoreMaximized = state.maximized;
            state.minimized = true;
            state.maximized = false;
            if (!Number.isFinite(state.minimizedLeft) || !Number.isFinite(state.minimizedTop)) {
                const dockCount = Array.from(document.querySelectorAll('.qf-desktop-dialog.qf-window-minimized')).filter(el => el !== dialog).length;
                state.minimizedLeft = 12;
                state.minimizedTop = Math.max(8, window.innerHeight - 58 - dockCount * 54);
            }
            dialog.style.removeProperty('--qf-window-dock-offset');
            dialog.classList.remove('qf-window-maximized');
            dialog.classList.add('qf-window-minimized');
            overlay.classList.add('qf-window-minimized-overlay');
            clampMinimizedPosition();
            updateControls();
        };
        const toggleMaximize = () => {
            if (state.minimized) { maximize(); return; }
            if (state.maximized) normal();
            else maximize();
        };
        const interactiveTarget = target => target && target.closest && target.closest('button, a, input, textarea, select, .qf-window-controls, .qf-terminal-action');
        let dragOffsetX = 0;
        let dragOffsetY = 0;
        const stopDrag = ev => {
            if (!state.dragging) return;
            if (ev && state.dragPointerId !== null && ev.pointerId !== state.dragPointerId) return;
            state.dragging = false;
            state.dragPointerId = null;
            document.removeEventListener('pointermove', moveDrag);
            document.removeEventListener('pointerup', stopDrag);
            document.removeEventListener('pointercancel', stopDrag);
            if (!state.minimized) rememberNormalPosition();
        };
        const moveDrag = ev => {
            if (!state.dragging || ev.pointerId !== state.dragPointerId) return;
            const rect = dialog.getBoundingClientRect();
            const maxLeft = Math.max(8, window.innerWidth - Math.min(rect.width, window.innerWidth - 16) - 8);
            const maxTop = state.minimized ? Math.max(8, window.innerHeight - rect.height - 8) : Math.max(8, window.innerHeight - 54);
            const nextLeft = Math.max(8, Math.min(ev.clientX - dragOffsetX, maxLeft));
            const nextTop = Math.max(8, Math.min(ev.clientY - dragOffsetY, maxTop));
            if (state.minimized) {
                state.minimizedLeft = nextLeft;
                state.minimizedTop = nextTop;
            } else {
                state.left = nextLeft;
                state.top = nextTop;
            }
            dialog.style.bottom = '';
            dialog.style.left = Math.round(nextLeft) + 'px';
            dialog.style.top = Math.round(nextTop) + 'px';
        };
        const startDrag = ev => {
            if (state.maximized || ev.button !== 0 || interactiveTarget(ev.target)) return;
            const rect = dialog.getBoundingClientRect();
            state.dragging = true;
            state.dragPointerId = ev.pointerId;
            dragOffsetX = ev.clientX - rect.left;
            dragOffsetY = ev.clientY - rect.top;
            ev.preventDefault();
            document.addEventListener('pointermove', moveDrag);
            document.addEventListener('pointerup', stopDrag);
            document.addEventListener('pointercancel', stopDrag);
        };
        const doubleClickHeader = ev => {
            if (!interactiveTarget(ev.target)) {
                ev.preventDefault();
                toggleMaximize();
            }
        };
        const clickMin = ev => { ev.preventDefault(); ev.stopPropagation(); minimize(); };
        const clickMax = ev => { ev.preventDefault(); ev.stopPropagation(); toggleMaximize(); };
        const resizeWindow = () => {
            if (state.minimized) { clampMinimizedPosition(); return; }
            if (!state.maximized) clampNormalPosition();
            layout();
        };
        header.addEventListener('pointerdown', startDrag);
        header.addEventListener('dblclick', doubleClickHeader);
        if (buttons.minBtn) buttons.minBtn.addEventListener('click', clickMin);
        if (buttons.maxBtn) buttons.maxBtn.addEventListener('click', clickMax);
        window.addEventListener('resize', resizeWindow);
        updateControls();
        clampNormalPosition();
        return {
            minimize: minimize,
            toggleMaximize: toggleMaximize,
            layout: layout,
            isMinimized: () => state.minimized,
            destroy: () => {
                state.disposed = true;
                stopDrag();
                header.removeEventListener('pointerdown', startDrag);
                header.removeEventListener('dblclick', doubleClickHeader);
                if (buttons.minBtn) buttons.minBtn.removeEventListener('click', clickMin);
                if (buttons.maxBtn) buttons.maxBtn.removeEventListener('click', clickMax);
                window.removeEventListener('resize', resizeWindow);
            }
        };
    },

    openEditor: function(path) {
        ui.showModal('读取中...', [E('p', {}, '加载中...')]);
        apiFetch('read', {}, { path: path }).then(res => {
            ui.hideModal();
            let closeFn;
            let editor = null;
            let desktopWindow = null;
            let closed = false;
            const overlay = E('div', { class: 'qf-overlay' });
            const editorHost = E('div', { class: 'qf-editor-host' });
            const textarea = E('textarea', { class: 'qf-editor', spellcheck: 'false' }, res.data || '');
            const status = E('div', { class: 'qf-editor-status' }, '内置编辑器已启用；正在检测本地 Monaco...');
            editorHost.appendChild(textarea);
            const saveBtn = E('button', { class: 'qf-btn qf-btn-primary' }, '保存');
            const cancelBtn = E('button', { class: 'qf-btn', click: () => closeFn() }, '取消');
            const minBtn = E('button', { type: 'button', class: 'qf-window-control', title: '最小化' }, '—');
            const maxBtn = E('button', { type: 'button', class: 'qf-window-control', title: '最大化' }, '□');
            const closeBtn = E('button', { type: 'button', class: 'qf-window-control qf-window-close', title: '关闭' }, '×');
            const fileTitle = path.split('/').pop() || path;
            const header = E('div', { class: 'qf-dialog-header' }, [
                E('span', { class: 'qf-dialog-title', title: path }, '文本编辑器 - ' + fileTitle),
                E('span', { class: 'qf-terminal-actions' }, [E('span', { class: 'qf-window-controls' }, [minBtn, maxBtn, closeBtn])])
            ]);
            const dialog = E('div', { class: 'qf-dialog qf-editor-dialog' }, [
                header,
                E('div', { class: 'qf-dialog-body' }, [editorHost]),
                E('div', { class: 'qf-dialog-footer' }, [status, cancelBtn, saveBtn])
            ]);
            overlay.appendChild(dialog);
            document.body.appendChild(overlay);

            const saveCode = () => {
                if (closed || saveBtn.disabled) return;
                const content = editor ? editor.getValue() : textarea.value;
                saveBtn.disabled = true;
                saveBtn.textContent = '保存中...';
                apiFetch('write', { method: 'POST', body: formData({ path: path, content: content }) }).then(() => {
                    ui.addNotification(null, E('p', {}, '已保存'), 'info');
                    closeFn();
                    this.refresh(this.currentPath);
                }).catch(err => { saveBtn.disabled = false; saveBtn.textContent = '保存'; notifyError(err); });
            };
            saveBtn.addEventListener('click', saveCode);
            const layoutEditor = () => setTimeout(() => {
                if (closed || (desktopWindow && desktopWindow.isMinimized())) return;
                try { if (editor && editor.layout) editor.layout(); } catch (_) {}
                if (!this.isFrontDesktopWindow(dialog)) return;
                if (editor && editor.focus) editor.focus();
                else textarea.focus();
            }, 60);
            desktopWindow = this.attachDesktopWindow(overlay, dialog, header, { minBtn: minBtn, maxBtn: maxBtn }, layoutEditor);
            closeBtn.addEventListener('click', ev => { ev.preventDefault(); ev.stopPropagation(); closeFn(); });
            const keyHandler = ev => {
                if (!this.isFrontDesktopWindow(dialog)) return;
                if ((ev.ctrlKey || ev.metaKey) && ev.key.toLowerCase() === 's') { ev.preventDefault(); saveCode(); }
                if (ev.key === 'Escape') { ev.preventDefault(); closeFn(); }
            };
            closeFn = () => {
                if (closed) return;
                closed = true;
                document.removeEventListener('keydown', keyHandler);
                if (desktopWindow) desktopWindow.destroy();
                if (editor) editor.dispose();
                overlay.remove();
            };
            document.addEventListener('keydown', keyHandler);
            setTimeout(() => { if (!closed && this.isFrontDesktopWindow(dialog)) textarea.focus(); }, 50);

            promiseWithTimeout(loadMonacoEditor(), 5000, '本地 Monaco 不存在或加载超时').then(monaco => {
                if (closed) return;
                const liveContent = textarea.value;
                editorHost.innerHTML = '';
                editor = monaco.editor.create(editorHost, {
                    value: liveContent,
                    language: detectEditorLanguage(path),
                    theme: this.theme === 'light' ? 'vs' : 'vs-dark',
                    automaticLayout: true,
                    minimap: { enabled: false },
                    fontSize: 13,
                    wordWrap: 'on',
                    scrollBeyondLastLine: false,
                    renderWhitespace: 'selection',
                    tabSize: 4,
                    insertSpaces: false
                });
                if (monaco.KeyMod && monaco.KeyCode) editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, saveCode);
                status.textContent = 'Monaco Editor 已启用：支持拖动 / 最小化 / 最大化 / Ctrl+S 保存';
                layoutEditor();
            }).catch(() => {
                if (closed) return;
                status.textContent = '内置编辑器已启用：支持拖动 / 最小化 / 最大化；本地 Monaco 未加载成功';
                setTimeout(() => { if (!closed && this.isFrontDesktopWindow(dialog)) textarea.focus(); }, 50);
            });
        }).catch(err => { ui.hideModal(); notifyError(err); });
    },

    openTerminal: function() {
        let closeFn;
        let ws = null;
        let term = null;
        let desktopWindow = null;
        let closed = false;
        const overlay = E('div', { class: 'qf-overlay' });
        const terminalHost = E('div', { class: 'qf-terminal-host' });
        const status = E('div', { class: 'qf-terminal-status' }, '正在加载本地 xterm.js...');
        const copyBtn = E('button', { type: 'button', class: 'qf-terminal-action' }, '复制');
        const pasteBtn = E('button', { type: 'button', class: 'qf-terminal-action' }, '粘贴');
        const clearBtn = E('button', { type: 'button', class: 'qf-terminal-action' }, '清屏');
        const minBtn = E('button', { type: 'button', class: 'qf-window-control', title: '最小化' }, '—');
        const maxBtn = E('button', { type: 'button', class: 'qf-window-control', title: '最大化' }, '□');
        const closeBtn = E('button', { type: 'button', class: 'qf-window-control qf-window-close', title: '关闭' }, '×');
        const header = E('div', { class: 'qf-dialog-header' }, [
            E('span', { class: 'qf-dialog-title' }, '实时终端 - ' + this.currentPath),
            E('span', { class: 'qf-terminal-actions' }, [copyBtn, pasteBtn, clearBtn, E('span', { class: 'qf-window-controls' }, [minBtn, maxBtn, closeBtn])])
        ]);
        const dialog = E('div', { class: 'qf-dialog qf-terminal-dialog' }, [
            header,
            E('div', { class: 'qf-dialog-body' }, [terminalHost, status])
        ]);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        const writeClipboard = text => {
            if (!text) return Promise.resolve(false);
            if (navigator.clipboard && navigator.clipboard.writeText) return navigator.clipboard.writeText(text).then(() => true).catch(() => false);
            return Promise.resolve(false);
        };
        const pasteClipboard = () => {
            if (!term) return;
            if (navigator.clipboard && navigator.clipboard.readText) {
                navigator.clipboard.readText().then(text => { if (text && ws && ws.readyState === WebSocket.OPEN) ws.send(text); term.focus(); }).catch(() => {
                    status.textContent = '浏览器禁止读取剪贴板，请用 Ctrl+V 或右键粘贴';
                });
            }
        };
        const fitTerm = () => {
            if (!term) return { cols: 100, rows: 30 };
            try { if (typeof term.fit === 'function') term.fit(); } catch (_) {}
            return { cols: term.cols || 100, rows: term.rows || 30 };
        };
        const syncTermSize = () => {
            const sz = fitTerm();
            if (ws && ws.readyState === WebSocket.OPEN) ws.send(`__QF_RESIZE__:${sz.cols}:${sz.rows}`);
            return sz;
        };
        desktopWindow = this.attachDesktopWindow(overlay, dialog, header, { minBtn: minBtn, maxBtn: maxBtn }, () => {
            if (term) {
                syncTermSize();
                term.focus();
            }
        });
        closeBtn.addEventListener('click', ev => { ev.preventDefault(); ev.stopPropagation(); closeFn(); });
        const connect = () => {
            const sz = fitTerm();
            const outputDecoder = new TextDecoder('utf-8');
            ws = new WebSocket(terminalUrl(this.currentPath, sz.cols, sz.rows));
            ws.binaryType = 'arraybuffer';
            ws.onopen = () => {
                if (closed) { ws.close(); return; }
                status.textContent = 'PTY 已连接：支持拖动 / 最小化 / 最大化；UTF-8 中文流式解码已启用';
                fitTerm();
                if (this.isFrontDesktopWindow(dialog)) term.focus();
            };
            ws.onmessage = ev => bytesToText(ev.data, outputDecoder, true).then(text => { if (!closed && text && term) term.write(text); });
            ws.onerror = () => { if (!closed) status.textContent = '终端连接错误，请确认 quickfile-go-api 正在运行并且已登录 LuCI'; };
            ws.onclose = () => {
                if (closed) return;
                const tail = outputDecoder.decode();
                if (tail && term) term.write(tail);
                status.textContent = '终端连接已关闭';
            };
        };

        loadXtermLocal().then(Terminal => {
            if (closed) return;
            term = new Terminal({
                cursorBlink: true,
                scrollback: 2000,
                fontSize: 14,
                fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
                theme: { background: '#000000', foreground: '#eeeeee', cursor: '#ffffff' }
            });
            term.open(terminalHost);
            if (typeof term.on === 'function') term.on('data', data => { if (ws && ws.readyState === WebSocket.OPEN) ws.send(data); });
            else if (typeof term.onData === 'function') term.onData(data => { if (ws && ws.readyState === WebSocket.OPEN) ws.send(data); });
            copyBtn.onclick = ev => {
                ev.stopPropagation();
                const text = (term.getSelection && term.getSelection()) || '';
                writeClipboard(text).then(ok => { status.textContent = ok ? '已复制终端选中文本' : '请先选中文本，再使用浏览器复制'; });
                term.focus();
            };
            pasteBtn.onclick = ev => { ev.stopPropagation(); pasteClipboard(); };
            clearBtn.onclick = ev => { ev.stopPropagation(); term.clear(); term.focus(); };
            terminalHost.addEventListener('paste', ev => {
                const text = (ev.clipboardData || window.clipboardData).getData('text');
                if (text && ws && ws.readyState === WebSocket.OPEN) { ev.preventDefault(); ws.send(text); }
            });
            connect();
        }).catch(err => {
            if (closed) return;
            status.textContent = '本地 xterm.js 加载失败：' + (err && err.message ? err.message : err);
            const retryBtn = E('button', { type: 'button', class: 'qf-terminal-action', click: ev => {
                ev.stopPropagation();
                if (closed) return;
                closeFn();
                this.openTerminal();
            } }, '重新加载终端资源');
            terminalHost.appendChild(E('div', { class: 'qf-terminal-fallback' }, [
                E('div', {}, 'xterm.js 本地资源加载失败。可直接重新加载，无需刷新整个页面。'),
                E('div', { style: 'margin-top:12px;' }, [retryBtn])
            ]));
        });

        const resizeHandler = () => { if (term && ws && ws.readyState === WebSocket.OPEN) syncTermSize(); };
        window.addEventListener('resize', resizeHandler);
        const keyHandler = ev => { if (this.isFrontDesktopWindow(dialog) && ev.key === 'Escape') { ev.preventDefault(); closeFn(); } };
        closeFn = () => {
            if (closed) return;
            closed = true;
            window.removeEventListener('resize', resizeHandler);
            document.removeEventListener('keydown', keyHandler);
            if (desktopWindow) desktopWindow.destroy();
            if (ws) ws.close();
            try { if (term && term.dispose) term.dispose(); } catch (_) {}
            overlay.remove();
        };
        document.addEventListener('keydown', keyHandler);
    },


    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
