import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';

test('one soundtrack source uses independent Web Audio gain for iPhone volume settings',()=>{
 const source=readFileSync(new URL('../neon-breach/src/audio.js',import.meta.url),'utf8').replace(/^export /gm,'');
 const gains=[],players=[],sources=[];let contexts=0;
 class Context {
  constructor(){contexts++;this.state='running';this.destination={};}
  createGain(){const bus={gain:{value:1},connect(target){this.target=target;return target;}};gains.push(bus);return bus;}
  createMediaElementSource(player){const node={player,connect(target){this.target=target;return target;}};sources.push(node);return node;}
 }
 class Audio {
  constructor(){players.push(this);this.paused=true;this.currentTime=17;this.volume=1;}
  play(){this.paused=false;return Promise.resolve();}pause(){this.paused=true;}
 }
 const storage=new Map();
 const sandbox={Audio,AudioContext:Context,localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)}};
 vm.runInNewContext(source+'\nglobalThis.api={unlockAudio,setAudioSettings};',sandbox);
 sandbox.api.unlockAudio();sandbox.api.unlockAudio();
 assert.equal(contexts,1);assert.equal(players.length,1);assert.equal(sources.length,1);
 assert.equal(gains.length,2);const [sfx,music]=gains;
 assert.equal(sources[0].target,music);assert.notEqual(sfx,music);
 assert.equal(players[0].volume,1,'mix gain controls volume, independent of HTMLMediaElement.volume support');
 sandbox.api.setAudioSettings({musicVolume:50,sfxVolume:25});
 assert.equal(music.gain.value,.18);assert.equal(sfx.gain.value,.25);
 sandbox.api.setAudioSettings({sfxOn:false});assert.equal(sfx.gain.value,0);assert.equal(music.gain.value,.18);
 sandbox.api.setAudioSettings({musicOn:false});assert.equal(music.gain.value,0);assert.equal(players[0].paused,true);
 sandbox.api.setAudioSettings({musicOn:true});sandbox.api.unlockAudio();assert.equal(music.gain.value,.18);
 assert.equal(players[0].currentTime,17,'settings and unlock never rewind the track');assert.equal(sources.length,1);
 const asset=readFileSync(new URL('../neon-breach/src/assets/music/Nineteen_Steps_loop.mp3',import.meta.url));
 assert.ok(asset.length>100000,'permanent soundtrack is present');
});
