export const ISSUE_BASE = 'https://github.com/dmcexcess-lab/Neon-Privateer/issues/new';
export function buildReport(values, environment) {
  const part = (key) => String(values[key] || '').trim() || '(not supplied)';
  const lines = [`# ${environment.gameName || 'Neon Privateer'} beta feedback`, '', `Build: ${environment.build}`, `Type: ${part('kind')}`, `Impact: ${part('impact')}`, '', `## ${part('summary')}`, '', '### Steps / context', part('steps'), '', '### Expected', part('expected'), '', '### Actual', part('actual'), '', '### Device / browser', part('device')];
  if (values.diagnostics) lines.push('', '### Browser details (tester chose to include)', `Browser: ${environment.userAgent}`, `Window: ${environment.width} × ${environment.height}`, `Page: ${environment.page}`);
  return lines.join('\n');
}
export function issueURL(summary, report, gameName) {
  // Keep the transport short; the complete local report is never truncated.
  const body = report.length > 6000 ? report.slice(0, 5700) + '\n\n[Report shortened for URL transport. Paste the complete copied/downloaded report here.]' : report;
  return ISSUE_BASE + '?' + new URLSearchParams({title: (gameName ? '[' + gameName + '] ' : '[Beta] ') + summary.trim().slice(0, 120), labels: 'beta-feedback', template: 'beta-feedback.md', body}).toString();
}
