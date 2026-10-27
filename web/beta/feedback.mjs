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

export function submittedReportsText(issues, gameName, generatedAt) {
  const reports = issues.filter(item => !item.pull_request &&
    (String(item.body || '').startsWith(`# ${gameName} beta feedback`) ||
     String(item.title || '').startsWith(`[${gameName}]`)));
  const lines = [`# ${gameName} — submitted feedback`, `Exported: ${generatedAt}`,
    'Source: public GitHub beta-feedback issues (open and closed).',
    `Reports: ${reports.length}`, ''];
  if (!reports.length) lines.push('No submitted reports for this game yet. Local copies and downloads are not automatically submitted.');
  for (const item of reports) lines.push(`## #${item.number}: ${item.title}`, `Status: ${item.state}`,
    `URL: ${item.html_url}`, '', String(item.body || '(No report text)'), '', '---', '');
  return lines.join('\n');
}

export async function loadSubmittedReports(fetcher, gameName, generatedAt) {
  const issues = [];
  for (let page = 1; ; page++) {
    const url = 'https://api.github.com/repos/dmcexcess-lab/Neon-Privateer/issues?' +
      new URLSearchParams({labels:'beta-feedback',state:'all',per_page:'100',page:String(page)});
    const response = await fetcher(url, {credentials:'omit', headers:{Accept:'application/vnd.github+json'}});
    if (!response.ok) throw new Error('Feedback export unavailable. Open the public feedback inbox and try again later.');
    const batch = await response.json();
    if (!Array.isArray(batch)) throw new Error('Unexpected feedback response.');
    issues.push(...batch);
    if (batch.length < 100) return submittedReportsText(issues, gameName, generatedAt);
  }
}
