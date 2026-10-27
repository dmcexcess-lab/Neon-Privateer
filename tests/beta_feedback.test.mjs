import test from 'node:test';
import assert from 'node:assert/strict';
import {buildReport, issueURL, loadSubmittedReports, submittedReportsText} from '../web/beta/feedback.mjs';
const env = {build:'test123',userAgent:'Test browser',width:390,height:844,page:'https://example.org/beta/'};
test('copyable report retains multiline steps and optional diagnostics',()=>{
 const values = {kind:'Bug',impact:'Blocks play',summary:'Port stuck',steps:'Open port\nTap market',actual:'Nothing',diagnostics:true};
 const text = buildReport(values,env);
 assert.match(text,/Open port\nTap market/);
 assert.match(text,/Build: test123/);
 assert.match(text,/Browser: Test browser/);
 assert.match(text,/Expected\n\(not supplied\)/);
 assert.doesNotMatch(buildReport({...values,diagnostics:false},env),/Test browser|390 × 844|https:\/\/example/);
});
test('GitHub transport escapes user text and labels reports; full report stays intact',()=>{
 const report='A & B # ? <script>\n'+ 'x'.repeat(7000);
 const url=new URL(issueURL('Music & flight?',report));
 assert.equal(url.origin,'https://github.com');
 assert.equal(url.searchParams.get('title'),'[Beta] Music & flight?');
 assert.equal(url.searchParams.get('labels'),'beta-feedback');
 assert.match(url.searchParams.get('body'),/Report shortened/);
 assert.equal(report.length,7019);
});
test('each game produces its own report heading and public issue title',()=>{
 for (const gameName of ['Neon Privateer','Neon Driftline Classic','Neon Breach','Neon Firewall']) {
  const report=buildReport({summary:'Controls',actual:'Stopped responding'},{...env,gameName});
  assert.equal(report.split('\n')[0],`# ${gameName} beta feedback`);
  const url=new URL(issueURL('Controls',report,gameName));
  assert.equal(url.searchParams.get('title'),`[${gameName}] Controls`);
  assert.equal(url.searchParams.get('body'),report);
  assert.equal(url.searchParams.get('labels'),'beta-feedback');
 }
});

test('submitted report export separates games and excludes pull requests',()=>{
 const issues=[{number:1,title:'[Neon Breach] Controls',state:'closed',html_url:'https://github.com/example/1',body:'# Neon Breach beta feedback\nDetails'},
 {number:2,title:'[Beta] Old title',state:'open',html_url:'https://github.com/example/2',body:'# Neon Privateer beta feedback\nOlder report'},
 {number:3,title:'[Neon Breach] PR',body:'ignored',pull_request:{}}];
 const breach=submittedReportsText(issues,'Neon Breach','test-date');
 assert.match(breach,/Reports: 1/); assert.match(breach,/Status: closed/);
 assert.doesNotMatch(breach,/Older report|ignored/);
 assert.match(submittedReportsText(issues,'Neon Privateer','test-date'),/Older report/);
 assert.match(submittedReportsText(issues,'Neon Driftline Classic','test-date'),/No submitted reports/);
});
test('public report download paginates, omits credentials and handles API failure',async()=>{
 const calls=[];
 const fetcher=async(url,options)=>{calls.push({url:String(url),options});return {ok:true,json:async()=>calls.length===1?Array.from({length:100},(_,i)=>({number:i,body:'# Neon Breach beta feedback',title:'Report',state:'open'})):[]};};
 const text=await loadSubmittedReports(fetcher,'Neon Breach','test-date');
 assert.match(text,/Reports: 100/); assert.equal(calls.length,2);
 assert.equal(new URL(calls[1].url).searchParams.get('page'),'2');
 assert.equal(calls[0].options.credentials,'omit');
 await assert.rejects(loadSubmittedReports(async()=>({ok:false}),'Neon Breach','test-date'),/unavailable/);
});
