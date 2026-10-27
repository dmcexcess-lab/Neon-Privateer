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
document.getElementById('launch').addEventListener('click', () => {
  game.src = './game.html?v=' + encodeURIComponent(build); game.hidden = false; document.getElementById('launch-card').hidden = true;
  document.getElementById('close-game').hidden = false;
  gameStatus.textContent = 'Loading the game…'; game.focus();
});
document.getElementById('close-game').addEventListener('click', () => {
  game.src = 'about:blank'; game.hidden = true;
  document.getElementById('launch-card').hidden = false;
  document.getElementById('close-game').hidden = true;
  gameStatus.textContent = document.body.dataset.closedText;
});
window.addEventListener('message', (event) => {
  if (event.origin !== location.origin || event.source !== game.contentWindow) return;
  if (event.data === 'dmc-game-ready') gameStatus.textContent = document.body.dataset.readyText;
  if (event.data === 'dmc-game-failed') gameStatus.textContent = 'The game reported an error. Reload or send a report with your browser and what happened.';
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
