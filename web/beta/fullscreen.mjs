// Fullscreen is always initiated by a user gesture. iPhone Safari can instead
// expand the play area; a Home Screen launch supplies Safari's standalone UI.
export function createPlayView({stage, doc, orientation, changed}) {
  let expanded = false;
  const current = () => doc.fullscreenElement || doc.webkitFullscreenElement;
  function sync(value) { expanded = value; changed(value); }
  async function landscape() {
    if (!orientation?.lock) return;
    try { await orientation.lock('landscape'); } catch { /* Safari requires manual rotation. */ }
  }
  async function enter() {
    const request = stage.requestFullscreen || stage.webkitRequestFullscreen;
    if (request) {
      try { await request.call(stage); sync(true); await landscape(); return 'native'; }
      catch { /* Denial still leaves a usable viewport expansion. */ }
    }
    sync(true); await landscape(); return 'expanded';
  }
  async function exit() {
    const release = doc.exitFullscreen || doc.webkitExitFullscreen;
    try { if (current() && release) await release.call(doc); }
    finally { orientation?.unlock?.(); sync(false); }
  }
  doc.addEventListener('fullscreenchange', () => sync(current() === stage));
  doc.addEventListener('webkitfullscreenchange', () => sync(current() === stage));
  return {enter, exit, toggle: () => expanded ? exit() : enter(), get expanded() { return expanded; }};
}
