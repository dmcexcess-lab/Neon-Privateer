import test from 'node:test';
import assert from 'node:assert/strict';
import {createPlayView} from '../web/beta/fullscreen.mjs';
function fixture(){
 const listeners={},states=[],stage={};let locks=0,unlocks=0;
 const doc={addEventListener:(k,fn)=>listeners[k]=fn,exitFullscreen:async()=>{doc.fullscreenElement=null;listeners.fullscreenchange();}};
 const orientation={lock:async mode=>{assert.equal(mode,'landscape');locks++;},unlock:()=>unlocks++};
 const view=createPlayView({stage,doc,orientation,changed:value=>states.push(value)});
 return {stage,doc,orientation,view,listeners,states,get locks(){return locks},get unlocks(){return unlocks}};
}
test('native fullscreen keeps the same game and unlocks on explicit exit',async()=>{
 const f=fixture();f.stage.requestFullscreen=async()=>{f.doc.fullscreenElement=f.stage;f.listeners.fullscreenchange();};
 assert.equal(f.view.expanded,false);assert.equal(f.states.length,0,'never enters without a gesture');
 assert.equal(await f.view.enter(),'native');assert.equal(f.view.expanded,true);assert.equal(f.locks,1);
 await f.view.exit();assert.equal(f.view.expanded,false);assert.equal(f.unlocks,1);
});
test('iPhone without Element fullscreen expands the viewport even without rotation lock',async()=>{
 const f=fixture();f.orientation.lock=async()=>{throw Error('not supported')};
 assert.equal(await f.view.enter(),'expanded');assert.equal(f.view.expanded,true);
 await f.view.toggle();assert.equal(f.view.expanded,false);
});
test('fullscreen denial falls back to a usable play area',async()=>{
 const f=fixture();f.stage.requestFullscreen=async()=>{throw Error('not allowed')};
 assert.equal(await f.view.enter(),'expanded');assert.equal(f.view.expanded,true);
});
test('Safari prefixed fullscreen and browser initiated exit are respected',async()=>{
 const f=fixture();f.stage.webkitRequestFullscreen=async()=>{f.doc.webkitFullscreenElement=f.stage;f.listeners.webkitfullscreenchange();};
 await f.view.enter();assert.equal(f.view.expanded,true);
 f.doc.webkitFullscreenElement=null;f.listeners.webkitfullscreenchange();assert.equal(f.view.expanded,false);
});
