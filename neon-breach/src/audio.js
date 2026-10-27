// Self-contained synthesized sound design + continuous, looping Nineteen Steps.
// Audio is unlocked only after a real input gesture (mobile/desktop browser policy).
const TRACK_URL='assets/music/Nineteen_Steps_loop.mp3';
let context=null,noiseBuffer=null,music=null,musicMuted=false,sfxBus=null;
const SETTINGS_KEY='neon-breach.audio.v1';
const defaults={musicOn:true,sfxOn:true,musicVolume:65,sfxVolume:80};
let settings={...defaults};
try{settings={...defaults,...JSON.parse(localStorage.getItem(SETTINGS_KEY)||'null')};}catch{}
const level=n=>Math.max(0,Math.min(100,Number(n)||0))/100;
function applySettings(){
  if(music){music.volume=settings.musicOn?level(settings.musicVolume)*.36:0;
    if(!settings.musicOn)music.pause();else if(music.paused)music.play().catch(()=>{});
  }
  if(sfxBus)sfxBus.gain.value=settings.sfxOn?level(settings.sfxVolume):0;
}
export function getAudioSettings(){return {...settings};}
export function setAudioSettings(next){
  settings={...settings,...next};
  for(const key of ['musicVolume','sfxVolume'])settings[key]=Math.round(Math.max(0,Math.min(100,Number(settings[key])||0)));
  for(const key of ['musicOn','sfxOn'])settings[key]=!!settings[key];
  try{localStorage.setItem(SETTINGS_KEY,JSON.stringify(settings));}catch{}
  applySettings();return getAudioSettings();
}
function destination(){return sfxBus||engine()?.destination;}

function engine(){
  if(context)return context;
  const Cls=globalThis.AudioContext||globalThis.webkitAudioContext;
  if(!Cls)return null;
  context=new Cls();sfxBus=context.createGain();sfxBus.gain.value=settings.sfxOn?level(settings.sfxVolume):0;sfxBus.connect(context.destination);return context;
}
function noise(){
  const ac=engine();if(!ac)return null;
  if(!noiseBuffer){
    const len=Math.round(ac.sampleRate*.8);
    noiseBuffer=ac.createBuffer(1,len,ac.sampleRate);
    const data=noiseBuffer.getChannelData(0);
    for(let i=0;i<len;i++)data[i]=Math.random()*2-1;
  }
  return noiseBuffer;
}
function tone(f0,f1,duration,volume=.1,type='sine',delay=0){
  const ac=engine();if(!ac)return;
  const t=ac.currentTime+delay,osc=ac.createOscillator(),g=ac.createGain();
  osc.type=type;osc.frequency.setValueAtTime(Math.max(20,f0),t);
  osc.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t+duration);
  g.gain.setValueAtTime(.0001,t);
  g.gain.exponentialRampToValueAtTime(Math.max(.0002,volume),t+.004);
  g.gain.exponentialRampToValueAtTime(.0001,t+duration);
  osc.connect(g).connect(destination());osc.start(t);osc.stop(t+duration+.005);
}
function burstNoise(duration=.08,volume=.08,frequency=1100,filterType='bandpass',delay=0){
  const ac=engine();if(!ac)return;
  const t=ac.currentTime+delay,src=ac.createBufferSource(),f=ac.createBiquadFilter(),g=ac.createGain();
  src.buffer=noise();f.type=filterType;f.frequency.value=frequency;f.Q.value=.8;
  g.gain.setValueAtTime(Math.max(.0002,volume),t);
  g.gain.exponentialRampToValueAtTime(.0001,t+duration);
  src.connect(f).connect(g).connect(destination());src.start(t);src.stop(t+duration+.003);
}
export function unlockAudio(){
  try{
    const ac=engine();if(ac&&ac.state==='suspended')ac.resume().catch(()=>{});
    if(!music&&typeof Audio!=='undefined'){
      music=new Audio(TRACK_URL);music.loop=true;music.volume=level(settings.musicVolume)*.36;music.preload='auto';
    }
    if(music&&!musicMuted&&settings.musicOn&&music.paused)music.play().catch(()=>{});
  }catch{}
}
export function toggleMusic(){
  musicMuted=!musicMuted;
  if(music){if(musicMuted)music.pause();else unlockAudio();}
  return !musicMuted;
}
export function sound(kind){
  if(!settings.sfxOn||!engine())return;
  if(kind==='step')return step(false,0);
  const tones={pickup:[700,1250,.14,.07],hit:[300,65,.12,.065],kill:[260,80,.14,.06],door:[230,690,.26,.06],buy:[520,960,.14,.08],hurt:[160,42,.24,.13],rare:[440,1430,.33,.09],start:[290,660,.28,.06]};
  const v=tones[kind]||[340,160,.1,.04];tone(...v);
}
export function step(sneaking=false,foot=0){
  if(!settings.sfxOn)return;
  // Alternating shoe impacts: low ground thump and textured grit/cloth.
  const volume=sneaking?.011:.044;
  tone(125+(foot?17:0),54,.075,volume*.8,'sine');
  burstNoise(sneaking?.045:.075,volume, sneaking?510:270,'lowpass');
}
export function melee(which='hands',left=false){
  if(!settings.sfxOn)return;
  if(which==='knife'){
    burstNoise(.12,.08,2600,'highpass');
    tone(left?790:850,160,.14,.035,'triangle');
    burstNoise(.045,.045,700,'lowpass',.09);
  }else{
    tone(left?225:270,70,.13,.055,'triangle');
    burstNoise(.080,.042,left?360:490,'lowpass');
    burstNoise(.048,.022,1100,'bandpass',.08);
  }
}
export function weaponShot(which){
  if(!settings.sfxOn)return;
  switch(which){
    case 'revolver': // deep metallic crack and long decaying report
      burstNoise(.26,.19,1900,'bandpass');
      tone(175,57,.28,.17,'sawtooth');
      tone(2100,450,.085,.045,'square');break;
    case 'auto_pistol': // short, snappy slide and muzzle snap
      burstNoise(.095,.14,2600,'highpass');
      tone(410,125,.10,.085,'square');
      tone(2900,950,.045,.022,'triangle',.035);break;
    case 'shotgun': // booming wide blast; pump is a separate animation/sound event
      burstNoise(.38,.23,790,'lowpass');
      burstNoise(.13,.17,2300,'highpass');
      tone(135,34,.31,.18,'sawtooth');
      break;
    case 'ar': // compact high-frequency crack, cycling bolt, bass body
      burstNoise(.082,.16,1900,'bandpass');
      tone(290,90,.11,.09,'sawtooth');
      burstNoise(.040,.06,3900,'highpass',.055);break;
    default: tone(390,130,.1,.06,'square');break;
  }
}
// Reload clacks and mechanism travel are synthesized separately for each gun.
export function reloadSound(which,phase='start'){
  if(!settings.sfxOn)return;
  const shotgun=which==='shotgun',ar=which==='ar',revolver=which==='revolver';
  if(shotgun&&phase==='shell'){
    // Distinct metallic feed click, one occurrence for EACH loaded shell.
    burstNoise(.055,.050,1050,'bandpass');
    tone(710,310,.095,.039,'triangle');return;
  }
  if(phase==='start'){
    burstNoise(.07,.065,shotgun?780:2000,'bandpass');
    tone(revolver?830:shotgun?450:ar?1150:1300,160,.11,.042,'triangle');
  }else{
    burstNoise(.07,.09,shotgun?900:ar?2400:1750,'bandpass');
    tone(shotgun?660:ar?1600:960,230,.095,.051,'square');
    burstNoise(.04,.043,1250,'highpass',.09);
  }
}
export function pumpSound(){
  if(!settings.sfxOn)return;
  // Two mechanical movements, timed to the actual pump cycling animation.
  burstNoise(.065,.11,1200,'bandpass');tone(960,260,.085,.060,'square');
  burstNoise(.06,.08,920,'bandpass',.16);tone(520,150,.055,.043,'triangle',.17);
}
export function enemyFootstep(type,intensity=.3){
  if(!settings.sfxOn)return;
  const zed=type==='circle'||type==='square',volume=Math.min(.040,Math.max(.004,intensity*.035));
  tone(zed?85:145,zed?40:75,.078,volume,zed?'triangle':'sine');
  burstNoise(zed?.080:.045,volume*.8,zed?400:900,zed?'lowpass':'bandpass');
}
export function monsterSound(type,intensity=.45){
  if(!settings.sfxOn)return;
  const g=Math.min(.07,Math.max(.007,intensity*.052));
  if(type==='circle'||type==='square'){
    tone(type==='circle'?74:103, type==='circle'?48:68,.36,g,'sawtooth');
    burstNoise(.24,g*.38,type==='circle'?260:420,'lowpass');
  }else if(type==='diamond'){
    tone(240,118,.18,g,'triangle');burstNoise(.10,g*.6,1300,'bandpass');
  }else{
    tone(type==='pentagon'?105:180,70,.13,g*.7,'square');burstNoise(.09,g,820,'bandpass');
  }
}
export function musicStatus(){return {ready:!!music,muted:musicMuted,paused:music?.paused??true};}
