import {buildReport, issueURL, loadSubmittedReports} from './feedback.mjs';
const form = document.getElementById('feedback-form');
const feedbackStatus = document.getElementById('feedback-status');
const preview = document.getElementById('report-preview');
const build = document.body.dataset.build;
const gameName = document.body.dataset.gameName;
const gameSlug = document.body.dataset.gameSlug;
document.getElementById('build-label').textContent = 'BUILD ' + build;
function readReport() {
  const data = Object.fromEntries(new FormData(form));
  const environment = {build, gameName, userAgent: navigator.userAgent, width: innerWidth, height: innerHeight, page: location.origin + location.pathname};
  const report = buildReport(data, environment);
  preview.value = report;
  return {data, report};
}
form.addEventListener('input', () => { readReport(); feedbackStatus.textContent = ''; });
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const {report} = readReport();
  try { await navigator.clipboard.writeText(report); feedbackStatus.textContent = 'Copied. Paste this into a chat or your GitHub report.'; }
  catch { preview.closest('details').open = true; preview.focus(); preview.select(); feedbackStatus.textContent = 'Clipboard unavailable. Select and copy the report below.'; }
});
document.getElementById('download-report').addEventListener('click', () => {
  if (!form.reportValidity()) return;
  const {report} = readReport();
  const url = URL.createObjectURL(new Blob([report], {type: 'text/plain;charset=utf-8'}));
  const link = document.createElement('a'); link.href = url; link.download = gameSlug + '-feedback-' + build + '.txt'; link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
  feedbackStatus.textContent = 'Report downloaded. It has not been submitted.';
});
document.getElementById('github-report').addEventListener('click', () => {
  if (!form.reportValidity()) return;
  const {data, report} = readReport();
  window.open(issueURL(String(data.summary), report, gameName), '_blank', 'noopener,noreferrer');
  feedbackStatus.textContent = 'GitHub opened. Review the public report and submit it there.';
});
const game = document.querySelector('[data-game-frame]');
const gameStatus = document.getElementById('game-status');
let breachLayer = null;
let breachClosing = false;
let pendingBreachContext = null;
function destroyBreachLayer() {
  if (!breachLayer) return;
  clearInterval(breachLayer.loadingTimer);
  breachLayer.remove();
  breachLayer = null;
  breachClosing = false;
}
function closeBreachLayer(message = 'RETURNING TO DOCK SERVICES') {
  if (!breachLayer || breachClosing) return;
  breachClosing = true;
  clearInterval(breachLayer.loadingTimer);
  const transition = breachLayer.querySelector('.breach-transition');
  transition.querySelector('.breach-loading-state').textContent = message;
  transition.querySelector('.breach-loading-progress').style.width = '100%';
  breachLayer.classList.remove('is-ready');
  breachLayer.classList.add('is-closing');
  setTimeout(() => {
    breachLayer?.querySelector('iframe')?.remove();
    game.hidden = false;
    game.focus();
    breachLayer?.classList.add('is-revealing');
    setTimeout(() => {
      destroyBreachLayer();
      if (pendingBreachContext) {
        const context = pendingBreachContext;
        pendingBreachContext = null;
        openBreachLayer(context);
      }
    }, 620);
  }, 380);
}
function revealBreachLayer() {
  if (!breachLayer || breachClosing) return;
  const elapsed = performance.now() - breachLayer.openedAt;
  setTimeout(() => {
    if (!breachLayer || breachClosing) return;
    clearInterval(breachLayer.loadingTimer);
    breachLayer.querySelector('.breach-loading-progress').style.width = '100%';
    breachLayer.querySelector('.breach-loading-state').textContent = 'PORT LINK ESTABLISHED';
    breachLayer.classList.add('is-ready');
    breachLayer.querySelector('iframe').focus();
  }, Math.max(0, 850 - elapsed));
}
function coverBreachLayer(detail = {}) {
  if (!breachLayer || breachClosing) return;
  clearInterval(breachLayer.loadingTimer);
  breachLayer.openedAt = performance.now();
  const transition = breachLayer.querySelector('.breach-transition');
  transition.querySelector('h3').textContent = detail.mode === 'mission' ? `${String(detail.style || 'FIELD').toUpperCase()} OPERATION` : 'SPACEPORT TRANSIT';
  transition.querySelector('.breach-loading-state').textContent = 'ASSEMBLING FIELD MAP · SYNCHRONIZING CONTACT';
  transition.querySelector('.breach-loading-progress').style.width = '12%';
  breachLayer.classList.remove('is-ready');
  let progress = 12;
  breachLayer.loadingTimer = setInterval(() => {
    progress = Math.min(92, progress + Math.max(1, Math.round((94 - progress) * .13)));
    transition.querySelector('.breach-loading-progress').style.width = progress + '%';
  }, 110);
}
function openBreachLayer(context) {
  if (breachClosing) {
    pendingBreachContext = context;
    return;
  }
  destroyBreachLayer();
  const layer = document.createElement('div');
  layer.className = 'breach-layer';
  layer.openedAt = performance.now();
  const transition = document.createElement('div');
  transition.className = 'breach-transition';
  transition.innerHTML = '<div class="breach-loading-mark">◈</div><p>NEON PRIVATEER // PORT TRANSIT</p><h3></h3><div class="breach-loading-track"><i class="breach-loading-progress"></i></div><small class="breach-loading-state">MAPPING CONCOURSE · LOCATING SERVICES</small>';
  transition.querySelector('h3').textContent = context.mode === 'spaceport' ? `${context.planetName || 'LOCAL'} SPACEPORT` : `${String(context.style || 'FIELD').toUpperCase()} OPERATION`;
  const frame = document.createElement('iframe');
  frame.className = 'breach-mission-frame';
  frame.title = 'Privateer spaceport and ground operation';
  frame.allow = 'autoplay; fullscreen';
  frame.src = './breach/game.html?privateer=' + encodeURIComponent(JSON.stringify(context));
  layer.append(frame, transition);
  document.querySelector('.game-stage').appendChild(layer);
  breachLayer = layer;
  let progress = 7;
  layer.loadingTimer = setInterval(() => {
    progress = Math.min(92, progress + Math.max(1, Math.round((94 - progress) * .13)));
    transition.querySelector('.breach-loading-progress').style.width = progress + '%';
  }, 110);
  game.hidden = true;
  gameStatus.textContent = context.mode === 'spaceport' ? 'Entering the local spaceport…' : 'Loading ground operation…';
}
function abandonBreachLayer() {
  pendingBreachContext = null;
  destroyBreachLayer();
  game.hidden = false;
}
document.getElementById('launch').addEventListener('click', () => {
  game.src = './game.html?v=' + encodeURIComponent(build); game.hidden = false; document.getElementById('launch-card').hidden = true;
  document.getElementById('close-game').hidden = false;
  gameStatus.textContent = 'Loading the game…'; game.focus();
});
document.getElementById('close-game').addEventListener('click', () => {
  abandonBreachLayer();
  game.src = 'about:blank'; game.hidden = true;
  document.getElementById('launch-card').hidden = false;
  document.getElementById('close-game').hidden = true;
  gameStatus.textContent = document.body.dataset.closedText;
});
window.addEventListener('message', (event) => {
  if (event.origin !== location.origin) return;
  if (event.source === game.contentWindow) {
    if (event.data === 'dmc-game-ready') gameStatus.textContent = document.body.dataset.readyText;
    else if (event.data === 'dmc-game-failed') gameStatus.textContent = 'The game reported an error. Reload or send a report with your browser and what happened.';
    else if (event.data?.type === 'dmc-open-breach') openBreachLayer(event.data.detail);
    return;
  }
  const breachFrame = breachLayer?.querySelector('iframe');
  if (!breachFrame || event.source !== breachFrame.contentWindow || !event.data?.type?.startsWith('dmc-privateer-')) return;
  if (event.data.type === 'dmc-privateer-loading') {
    coverBreachLayer(event.data.detail);
    gameStatus.textContent = 'Loading ground operation…';
    return;
  }
  if (event.data.type === 'dmc-privateer-ready') {
    revealBreachLayer();
    gameStatus.textContent = event.data.detail?.mode === 'spaceport' ? 'Spaceport online.' : 'Ground operation active.';
    return;
  }
  game.contentWindow.postMessage(event.data, location.origin);
  if (['dmc-privateer-service','dmc-privateer-terminal','dmc-privateer-port-result','dmc-privateer-mission-result'].includes(event.data.type)) {
    const destination = event.data.type === 'dmc-privateer-terminal' ? 'CONNECTING PHYSICAL TERMINAL' : event.data.type === 'dmc-privateer-mission-result' ? 'RETURNING TO SPACEPORT' : 'OPENING DOCK SERVICE';
    closeBreachLayer(destination);
    gameStatus.textContent = 'Transitioning from the spaceport…';
  }
});
readReport();

document.getElementById('download-submitted').addEventListener('click', async (event) => {
  const button = event.currentTarget;
  button.disabled = true;
  feedbackStatus.textContent = 'Reading submitted public reports…';
  try {
    const text = await loadSubmittedReports(fetch, gameName, new Date().toISOString());
    const url = URL.createObjectURL(new Blob([text], {type:'text/plain;charset=utf-8'}));
    const link = document.createElement('a');
    link.href = url; link.download = gameSlug + '-submitted-feedback.txt'; link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    feedbackStatus.textContent = 'Submitted reports downloaded. Local reports appear here only after the tester submits them via GitHub.';
  } catch (error) {
    feedbackStatus.textContent = error.message;
  } finally { button.disabled = false; }
});

// Keep the same iframe alive when enlarging or rotating; no reload/save reset.
import {createPlayView} from './fullscreen.mjs';
const stage = document.querySelector('.game-stage');
const fullButton = document.getElementById('fullscreen-game');
const playView = createPlayView({stage, doc: document, orientation: screen.orientation,
  changed(expanded) {
    stage.classList.toggle('expanded-play', expanded);
    document.body.classList.toggle('playing-expanded', expanded);
    fullButton.setAttribute('aria-pressed', String(expanded));
    fullButton.textContent = expanded ? 'Exit full screen' : 'Full screen';
  }
});
fullButton.addEventListener('click', async () => {
  const mode = await playView.toggle();
  if (mode === 'expanded') gameStatus.textContent = 'Play area expanded. On iPhone: Share → Add to Home Screen → Open as Web App for a screen without Safari toolbars. Rotate the phone sideways for Breach.';
});
document.getElementById('exit-fullscreen').addEventListener('click', () => playView.exit());
document.addEventListener('keydown', event => { if (event.key === 'Escape' && playView.expanded) playView.exit(); });
