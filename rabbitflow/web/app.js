const $ = id => document.getElementById(id);
let state, initialized = false, streamOnline = false, feedback = '', feedbackUntil = 0;
const number = n => new Intl.NumberFormat().format(n);
const setText = (id, value) => { $(id).textContent = value; };

function notice() {
  const text = !streamOnline ? 'Live connection interrupted. Reconnecting…' :
    !state?.connected ? 'RabbitMQ is disconnected. Retrying automatically; queue metrics are stale.' :
    Date.now() < feedbackUntil ? feedback : state?.error || '';
  $('notice').hidden = !text;
  $('notice').textContent = text;
}

async function post(path, body) {
  const response = await fetch(path, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)});
  if (!response.ok) throw new Error((await response.text()).trim());
  return response.json();
}
function message(text) { feedback = text; feedbackUntil = Date.now() + 6000; notice(); }
async function action(button, fn, onError) {
  button.disabled = true;
  try { await fn(); } catch (error) { onError?.(); message(error.message); }
  finally { button.disabled = false; }
}
function producerConfig(enabled) {
  return {enabled, rate: Number($('rate').value), workMs: Number($('work-ms').value)};
}
function restorePoolForm() {
  if (!state) return;
  $('min-workers').value = state.config.min;
  $('max-workers').value = state.config.max;
  $('backlog').value = state.config.backlogPerWorker;
  $('cooldown').value = state.config.cooldownSeconds;
}
$('rate').addEventListener('input', () => setText('rate-value', $('rate').value));
$('producer-form').addEventListener('submit', event => {
  event.preventDefault();
  action($('toggle-producer'), async () => {
    await post('/api/producer', producerConfig(!state?.producer.enabled));
    message(state?.producer.enabled ? 'Producer paused. Workers will drain the queue.' : 'Producer started.');
  });
});
$('apply-producer').addEventListener('click', () => {
  if (!$('producer-form').reportValidity()) return;
  action($('apply-producer'), async () => {
    await post('/api/producer', producerConfig(state?.producer.enabled ?? false));
    message('Rate and duration applied to future events.');
  });
});
$('burst-form').addEventListener('submit', event => {
  event.preventDefault();
  action($('send-burst'), async () => {
    const result = await post('/api/burst', {count: Number($('burst-count').value)});
    message(`${number(result.queued)} events queued for publishing.`);
  });
});
$('pool-form').addEventListener('submit', event => {
  event.preventDefault();
  action(event.submitter, async () => {
    await post('/api/pool', {min: Number($('min-workers').value), max: Number($('max-workers').value),
      backlogPerWorker: Number($('backlog').value), cooldownSeconds: Number($('cooldown').value)});
    message('Pool settings applied.');
  }, restorePoolForm);
});

function render(s) {
  state = s;
  if (!initialized) {
    $('rate').value = s.producer.rate; setText('rate-value', s.producer.rate);
    $('work-ms').value = s.producer.workMs;
    $('min-workers').value = s.config.min; $('max-workers').value = s.config.max;
    $('backlog').value = s.config.backlogPerWorker; $('cooldown').value = s.config.cooldownSeconds;
    initialized = true;
  }
  const busy = s.workers.filter(w => w.busy).length;
  const retiring = s.workers.filter(w => w.retiring).length;
  const sample = s.history.at(-1);
  setText('connection', s.connected ? 'RabbitMQ connected' : 'RabbitMQ disconnected');
  $('connection-dot').classList.toggle('connected', s.connected);
  setText('producer-stage', s.producer.enabled ? `${s.producer.rate} events / sec` : s.pending ? 'Publishing burst' : 'Paused');
  setText('queue-stage', s.connected ? `${number(s.ready)} events ready` : 'Disconnected');
  setText('pool-stage', `${s.workers.length} workers · ${busy} busy`);
  setText('ready', s.connected ? number(s.ready) : '—');
  setText('worker-count', s.workers.length);
  setText('worker-limit', `/ ${s.config.max}`);
  setText('busy-label', `${busy} busy · ${s.workers.length - busy} idle${retiring ? ` · ${retiring} retiring` : ''}`);
  setText('throughput', s.connected ? (sample?.completeRate ?? 0).toFixed(1) : '—');
  setText('completed', number(s.completed));
  setText('published-label', `${number(s.published)} confirmed publishes this run`);
  setText('pool-badge', `${s.workers.length} workers`);
  setText('producer-pill', s.producer.enabled ? 'RUNNING' : 'PAUSED');
  $('producer-pill').classList.toggle('running', s.producer.enabled);
  setText('toggle-producer', s.producer.enabled ? 'Pause producer Ⅱ' : 'Start producer ↗');
  setText('burst-hint', s.pending ? `${number(s.pending)} events waiting to publish…` : 'Try 120 events and watch the pool expand.');
  $('send-burst').disabled = !s.connected || s.pending > 0;
  setText('sample-time', s.connected && sample ? `LIVE · sampled ${new Date(s.sampledAt).toLocaleTimeString()}` : 'Queue metrics unavailable');
  renderWorkers(s.workers, new Date(s.now).getTime());
  renderLogs(s.logs);
  drawChart(); notice();
}

function element(tag, cls, text) {
  const node = document.createElement(tag); node.className = cls;
  if (text !== undefined) node.textContent = text;
  return node;
}
function renderWorkers(workers, now) {
  const root = $('workers');
  const ids = new Set(workers.map(w => String(w.id)));
  for (const child of [...root.children]) if (!ids.has(child.dataset.id)) child.remove();
  for (const w of workers) {
    let tile = root.querySelector(`[data-id="${w.id}"]`);
    if (!tile) {
      tile = element('div', 'worker'); tile.dataset.id = w.id;
      const head = element('div', 'worker-head');
      head.append(element('span', '', `W-${String(w.id).padStart(2, '0')}`), element('i', ''));
      const progress = element('progress', 'worker-progress'); progress.max = 100;
      progress.setAttribute('aria-label', `Worker ${w.id} event progress`);
      tile.append(head, element('span', 'worker-kind'), progress); root.append(tile);
    }
    tile.className = `worker${w.busy ? ' busy' : ''}${w.retiring ? ' retiring' : ''}`;
    tile.querySelector('.worker-kind').textContent = w.retiring ? 'Finishing & retiring' : w.busy ? w.kind : 'Waiting for events';
    tile.querySelector('progress').value = w.busy ? Math.max(0, Math.min(100, (now - new Date(w.startedAt).getTime()) / w.workMs * 100)) : 0;
    tile.title = w.busy ? `Event ${w.eventId} · ${w.workMs} ms` : `${w.completed} events completed`;
  }
  if (!workers.length && !root.children.length) root.append(element('p', 'empty', 'Workers will appear when RabbitMQ connects.'));
}
let lastLogKey;
function renderLogs(logs) {
  const key = `${logs[0]?.time}:${logs[0]?.message}`;
  if (key === lastLogKey) return; lastLogKey = key;
  const root = $('activity'); root.replaceChildren();
  for (const log of logs) {
    const row = element('div', 'log-row');
    row.append(element('time', 'log-time', new Date(log.time).toLocaleTimeString([], {hour12: false})),
      element('span', `log-kind ${log.kind === 'error' ? 'error' : ''}`, log.kind),
      element('span', 'log-message', log.message)); root.append(row);
  }
}

function drawChart() {
  const canvas = $('chart'), bounds = canvas.getBoundingClientRect(), dpr = window.devicePixelRatio || 1;
  canvas.width = Math.round(bounds.width * dpr); canvas.height = Math.round(bounds.height * dpr);
  const ctx = canvas.getContext('2d'); ctx.scale(dpr, dpr);
  const w = bounds.width, h = bounds.height, left = 27, right = w - 26, top = 12, bottom = h - 12;
  const samples = state?.history ?? [], maxQueue = Math.max(20, ...samples.map(s => s.ready)), maxWorkers = state?.config.max ?? 16;
  ctx.font = '9px ui-monospace, monospace'; ctx.lineWidth = 1;
  for (let i = 0; i <= 4; i++) {
    const y = top + (bottom - top) * i / 4;
    ctx.strokeStyle = '#e9ede3'; ctx.setLineDash([3, 5]); ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(right, y); ctx.stroke();
    ctx.fillStyle = '#b7a28c'; ctx.textAlign = 'right'; ctx.fillText(Math.round(maxQueue * (1 - i / 4)), left - 7, y + 3);
    ctx.fillStyle = '#92a789'; ctx.textAlign = 'left'; ctx.fillText(Math.round(maxWorkers * (1 - i / 4)), right + 7, y + 3);
  }
  ctx.setLineDash([]);
  const now = state ? new Date(state.now).getTime() : Date.now();
  const x = s => left + Math.max(0, Math.min(1, (new Date(s.time).getTime() - (now - 60000)) / 60000)) * (right - left);
  for (const [field, max, color] of [['ready', maxQueue, '#d58a4a'], ['workers', maxWorkers, '#598963']]) {
    if (!samples.length) continue;
    ctx.beginPath(); samples.forEach((s, i) => {
      const y = bottom - Math.min(1, s[field] / max) * (bottom - top);
      if (i === 0) ctx.moveTo(x(s), y); else ctx.lineTo(x(s), y);
    });
    ctx.strokeStyle = color; ctx.lineWidth = 1.8; ctx.stroke();
    if (field === 'ready') {
      ctx.lineTo(x(samples.at(-1)), bottom); ctx.lineTo(x(samples[0]), bottom); ctx.closePath();
      const gradient = ctx.createLinearGradient(0, top, 0, bottom);
      gradient.addColorStop(0, '#d58a4a25'); gradient.addColorStop(1, '#d58a4a03'); ctx.fillStyle = gradient; ctx.fill();
    }
  }
  $('chart-empty').hidden = Boolean(state?.published || state?.ready || state?.completed);
  $('chart-empty').style.display = $('chart-empty').hidden ? 'none' : 'grid';
}
new ResizeObserver(drawChart).observe($('chart').parentElement);
const events = new EventSource('/api/events');
events.onmessage = event => { streamOnline = true; render(JSON.parse(event.data)); };
events.onerror = () => { streamOnline = false; setText('connection', 'Live connection lost'); $('connection-dot').classList.remove('connected'); notice(); };
