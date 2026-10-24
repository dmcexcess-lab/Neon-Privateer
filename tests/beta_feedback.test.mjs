import test from 'node:test';
import assert from 'node:assert/strict';
import {buildReport, issueURL} from '../web/beta/feedback.mjs';
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
