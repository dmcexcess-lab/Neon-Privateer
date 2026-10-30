import {RNG,generateFloor,createHQWorld,createSpaceportWorld,enemyBudget,chooseEnemy,chooseGuardWeapon,randomSpot,walkable,propAt,roomAt,TILESETS,planFloorPoints} from './dungeon.js';
import {VISION,canSpot,canHear,clearSight,turnToward,angleDifference,navigationPoint} from './ai.js';
import {unlockAudio,sound,step,melee,weaponShot,reloadSound,pumpSound,monsterSound,enemyFootstep,getAudioSettings,setAudioSettings} from './audio.js';

const $ = id=>document.getElementById(id);
const canvas=$('game'),ctx=canvas.getContext('2d',{alpha:false});
const C={cyan:'#5af0ff',pink:'#ff60bd',gold:'#f9cc70',green:'#75ffb0',purple:'#b999ff',red:'#ff627f',orange:'#ffa969',white:'#e3fbff',blue:'#6aa9ff'};
const TYPE={
 circle:{name:'WANDERER',hp:2,spd:29,r:17,damage:1,credits:5,color:C.red},
 square:{name:'PATROLLER',hp:2.7,spd:46,r:17,damage:1,credits:8,color:C.orange},
 diamond:{name:'SHOCK TROOP',hp:4,spd:116,r:19,damage:2,credits:15,color:C.purple},
 trapezoid:{name:'GUARD',hp:5,spd:97,r:21,damage:1,credits:20,color:C.cyan},
 pentagon:{name:'HEAVY GUARD',hp:13,spd:65,r:29,damage:2,credits:40,color:C.gold}
};
const WEAPONS={
 hands:{label:'BARE HANDS',cooldown:.32,damage:1.35,melee:true,velocity:0,pellets:0,spread:0,color:C.cyan,r:0,pierce:0},
 knife:{label:'COMBAT KNIFE',cooldown:.305,damage:2.95,melee:true,velocity:0,pellets:0,spread:0,color:C.green,r:0,pierce:0},
 revolver:{magazine:6,reload:1.75,label:'REVOLVER',cooldown:.53,damage:3.65,velocity:1250,pellets:1,spread:.018,color:C.gold,r:4,pierce:1},
 auto_pistol:{magazine:16,reload:1.45,label:'AUTO PISTOL',cooldown:.158,damage:1.0,velocity:1060,pellets:1,spread:.078,color:C.cyan,r:3,pierce:0},
 shotgun:{magazine:5,shellTime:.58,rackTime:.72,pump:.72,label:'PUMP SHOTGUN',cooldown:.12,damage:1.50,velocity:870,pellets:5,spread:.73,color:C.orange,r:4,pierce:0},
 ar:{magazine:30,reload:2.25,label:'ASSAULT RIFLE',cooldown:.115,damage:1.42,velocity:1460,pellets:1,spread:.052,color:C.purple,r:3,pierce:0}
};
const SHOP_GEAR=[
 {id:'knife',name:'COMBAT KNIFE',desc:'Single-hand silent slash; stronger and longer than fists.',cost:95},
 {id:'revolver',name:'REVOLVER',desc:'Heavy precision sidearm.',cost:330},
 {id:'auto_pistol',name:'AUTO PISTOL',desc:'Quick successive shots.',cost:450},
 {id:'shotgun',name:'PUMP SHOTGUN',desc:'Click to fire, click to pump. Five shells reload individually on empty.',cost:570},
 {id:'ar',name:'ASSAULT RIFLE',desc:'Rapid ranged rifle.',cost:770},
 {id:'map',name:'TACTICAL RADAR',desc:'Reveals the map, nearby hostiles, and their facing. M expands.',cost:230},
 {id:'armor1',name:'LIGHT ARMOR +1 HP',desc:'Adds one maximum hit point for this deployment.',cost:150},
 {id:'armor2',name:'FIELD ARMOR +2 HP',desc:'Adds two maximum hit points for this deployment.',cost:290},
 {id:'armor3',name:'HEAVY ARMOR +3 HP',desc:'Adds three maximum hit points for this deployment.',cost:440},
 {id:'medkit',name:'REPAIR KIT',desc:'Restores one hit point, including vest capacity. Carry at most five; use F or REPAIR.',cost:90}
];
const MAX_REPAIR_KITS=5;
const GEAR_IDS=SHOP_GEAR.map(g=>g.id);
const PROFILE_KEY='neon-breach.hq.v1';
const SAVE_KEY='neon-breach.save.v1';
const TRAVEL_COSTS={1:0,11:100,21:1000,31:10000};
const travelTiers=[1,11,21,31];
const cleanStash=value=>Object.fromEntries(GEAR_IDS.map(k=>[k,Math.max(0,Math.min(99,Math.floor(Number(value?.[k])||0)))]));
function loadProfile(){
  try{const raw=JSON.parse(localStorage.getItem(PROFILE_KEY)||'null');
    return {credits:Math.max(0,Math.floor(Number(raw?.credits)||0)),storage:cleanStash(raw?.storage),unlockedFloor:Math.max(1,Math.floor(Number(raw?.unlockedFloor)||1)),firstGuardFloor:[7,8].includes(raw?.firstGuardFloor)?raw.firstGuardFloor:(Math.random()<.5?7:8)};
  }catch{return {credits:0,storage:cleanStash(),unlockedFloor:1,firstGuardFloor:Math.random()<.5?7:8};}
}
function saveProfile(syncHQ=true){
  if(privateerContext)return;
  try{localStorage.setItem(PROFILE_KEY,JSON.stringify(game.profile));}catch{}
  if(syncHQ&&['HQ','HQ_PANEL','TRAVEL'].includes(game.mode))saveGame(true);
}
function emptyLoadout(){return {weapon:'hands',armor:0,map:false,medkits:0,spares:[]};}
function stash(item,count=1){if(!GEAR_IDS.includes(item))return;game.profile.storage[item]+=count;saveProfile();}
function credit(amount){const n=Math.max(0,Math.floor(amount));game.profile.credits+=n;game.runCash+=n;
  if(game.player)game.player.cash=game.profile.credits;saveProfile();updateUI();return n;}
const TAU=Math.PI*2,clamp=(n,a,b)=>Math.max(a,Math.min(b,n)),rand=(a,b)=>a+Math.random()*(b-a),distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
let SW=innerWidth,SH=innerHeight,DPR=1,zoom=1;
const camera={x:0,y:0};
const inputs={keys:new Set(),mouse:{x:SW*.65,y:SH*.5,down:false,valid:false,stealthHeld:false},move:{x:0,y:0},aim:{x:0,y:0},map:false,sneakTouch:false,shotgunTriggerHeld:false,shotgunPendingPresses:0};
let lastFrame=0,now=0,audio=null,gamepadPauseDown=false,toastTimeout=0;
let game={mode:'MENU',profile:null,loadout:null,world:null,floor:1,seed:0,player:null,activeRoom:0,enemies:[],bullets:[],pickups:[],particles:[],time:0,kills:0,runCash:0,shake:0,flashed:0,exitClock:0,upgradeLevels:{},hqStation:null,hqPanel:'shop',pausedFrom:'PLAY',monsterSoundClock:0};
let privateerContext=null;
try{
  if(typeof URLSearchParams!=='undefined'&&typeof location!=='undefined'){
    const params=new URLSearchParams(location.search),raw=params.get('privateer');
    if(raw)privateerContext=JSON.parse(raw);
  }
}catch(error){console.warn('Privateer mission context rejected',error);}
game.profile=loadProfile();game.loadout=emptyLoadout();
let bestFloor=0;try{bestFloor=Number(localStorage.getItem('neon-breach.best')||0)}catch{}
game.profile.unlockedFloor=Math.max(game.profile.unlockedFloor,Math.max(...travelTiers.filter(f=>f<=bestFloor),1));
$('bestReadout').textContent=`PERSONAL BEST // SECTOR ${String(bestFloor).padStart(2,'0')}`;

function resize(){
  SW=innerWidth;SH=innerHeight;DPR=Math.min(devicePixelRatio||1,2);
  canvas.width=Math.round(SW*DPR);canvas.height=Math.round(SH*DPR);
  canvas.style.width=SW+'px';canvas.style.height=SH+'px';
  zoom=clamp(Math.min(SW/1080,SH/830),.62,1.25);
}
addEventListener('resize',resize);resize();
function show(id,visible){$(id).classList.toggle('hidden',!visible)}
function playSound(kind){sound(kind);}
// User interaction is mandatory before browsers permit audio playback.
// A single <audio> loop continues through menu, pause, shops and deaths.
addEventListener('pointerdown',unlockAudio,{passive:true});
addEventListener('keydown',unlockAudio,{passive:true});
function announce(text,seconds=2){$('toast').textContent=text;show('toast',true);toastTimeout=seconds;}
function hiddenScreens(){for(const id of ['menu','hq','pause','death','travel','settings'])show(id,false)}
function updateUI(){
 if(!game.player)return;
 $('floorReadout').textContent=String(game.floor).padStart(2,'0');
 $('healthReadout').textContent=`${Math.ceil(game.player.hp)} / ${game.player.maxHp}`;
 $('cashReadout').textContent=String(game.profile.credits).padStart(3,'0');
 $('medkitCount').textContent=game.player.medkits||0;$('medkitButton').disabled=!game.player.medkits||game.player.hp>=game.player.maxHp;
 const w=WEAPONS[game.player.weapon];
 $('weaponReadout').textContent=w.label+(w.magazine?` · ${game.player.magazines?.[game.player.weapon]??w.magazine}/${w.magazine}`:'')+
   (game.player.reloadClock>0?(game.player.weapon==='shotgun'?` · ${game.player.reloadStage==='rack'?'RACKING':'LOADING SHELLS'} ${Math.ceil(game.player.reloadClock*10)/10}s`:` · RELOAD ${Math.ceil(game.player.reloadClock*10)/10}s`):'')+
   (game.player.pumpClock>0?' · PUMPING':game.player.weapon==='shotgun'&&game.player.pumpNeeded?' · CLICK TO PUMP':'')+
   (game.player.weaponDrawn===false?' · HOLSTERED':' · DRAWN')+(game.player.sneaking?' · STEALTH':'')+(game.player.map?' · RADAR':'');
 $('drawButton').textContent=game.player.weaponDrawn===false?'DRAW':'HOLSTER';
 $('drawButton').setAttribute('aria-pressed',String(game.player.weaponDrawn!==false));
 const meter=$('reloadMeter');if(meter){
   const working=game.player.reloadClock>0||game.player.pumpClock>0;
   meter.classList.toggle('hidden',!working);
   meter.style.width=(working?(game.player.reloadClock>0?1-game.player.reloadClock/Math.max(.1,game.player.reloadTotal):1-game.player.pumpClock/Math.max(.1,game.player.pumpTotal))*100:0)+'%';
   meter.style.background=game.player.reloadClock>0?'#f9cc70':'#ffa969';
 }
 $('location').textContent=game.world.isSpaceport?
   `${game.world.planetName} SPACEPORT · ${game.world.actors.filter(a=>!a.down).length} LOCALS · HEAT ${game.world.crime.heat}`:
   `${game.world.stratum.name}  ·  ${game.world.rooms.filter(r=>r.visited).length}/${game.world.rooms.length} AREAS  ·  ${game.enemies.length} HOSTILES`;
}
function enterHQ(message='FIELD LOADOUT READY'){
  if(game.profile.unlockedFloor>1)saveProfile();
  hiddenScreens();
  game.mode='HQ';game.world=createHQWorld();game.enemies=[];game.bullets=[];game.pickups=[];game.particles=[];
  game.extraction=null;game.exitClock=0;game.hqStation=null;inputs.mouse.down=false;inputs.shotgunTriggerHeld=false;inputs.shotgunPendingPresses=0;inputs.map=false;inputs.move={x:0,y:0};inputs.aim={x:0,y:0};
  const l=game.loadout;
  game.player={x:0,y:0,r:16,hp:3+l.armor,maxHp:3+l.armor,cash:game.profile.credits,weapon:l.weapon,
    armorTier:l.armor,map:false,medkits:l.medkits,spares:[],magazines:initialMagazines(),reloadClock:0,reloadTotal:0,reloadWeapon:null,reloadShells:0,reloadStage:null,pumpClock:0,pumpTotal:0,pumpNeeded:false,swingHand:0,speed:235,damage:1,rate:1,armor:0,scavenging:1,stealth:1,
    sneaking:false,cool:0,invuln:0,facing:-Math.PI/2,walkCycle:0,punchTimer:0,stepClock:0};
  camera.x=0;camera.y=0;
  show('hud',false);show('location',true);show('touchUI',true);show('aimTip',false);show('hqPrompt',false);
  $('location').textContent='RESISTANCE HQ   //   SAFE ZONE   //   4 FACILITIES';
  show('hqMenuButton',true);
  $('hqSubheading').textContent=message;
  document.body?.classList.toggle('hq-mode',true);
  announce(`${message}  ·  WALK TO A STATION AND PRESS E / INTERACT`,3.7);
}
function privateerMessage(type,detail={}){
  if(!privateerContext)return;
  parent.postMessage({type,detail,requestId:privateerContext.requestId||'',planetId:privateerContext.planetId||''},location.origin);
}
function makeFieldPlayer(loadout={}){
  const weapon=WEAPONS[loadout.weapon]?loadout.weapon:'hands',armor=clamp(Number(loadout.armor)||0,0,3);
  return {x:0,y:0,r:16,hp:3+armor,maxHp:3+armor,cash:Number(loadout.cash)||0,weapon,weaponDrawn:false,
    armorTier:armor,map:!!loadout.map,medkits:clamp(Number(loadout.medkits)||0,0,MAX_REPAIR_KITS),spares:[],magazines:initialMagazines(),
    reloadClock:0,reloadTotal:0,reloadWeapon:null,reloadShells:0,reloadStage:null,pumpClock:0,pumpTotal:0,pumpNeeded:false,
    swingHand:0,speed:235,damage:1,rate:1,armor:0,scavenging:1,stealth:1,sneaking:false,cool:0,invuln:0,
    facing:-Math.PI/2,walkCycle:0,punchTimer:0,stepClock:0};
}
function enterPrivateerPort(context){
  hiddenScreens();game.world=createSpaceportWorld(context);game.mode='PORT';game.enemies=[];game.bullets=[];game.pickups=[];game.particles=[];
  game.player=makeFieldPlayer(context.loadout||{});game.hqStation=null;game.portClock=0;
  camera.x=0;camera.y=0;show('hud',true);show('location',true);show('touchUI',true);show('aimTip',true);show('hqPrompt',false);show('hqMenuButton',false);
  // A port uses the field-combat HUD and phone aim/draw controls. HQ mode
  // deliberately hides those controls, so it must not leak into this scene.
  document.body?.classList.toggle('hq-mode',false);
  $('location').textContent=`${game.world.planetName} SPACEPORT // ${game.world.faction}`;
  updateUI();
  announce('SPACEPORT ACTIVE · WALK TO SERVICES OR TALK TO LOCALS · H DRAWS / HOLSTERS',4);
  requestAnimationFrame(()=>privateerMessage('dmc-privateer-ready',{mode:'spaceport',planetName:game.world.planetName}));
}
function startPrivateerMission(spec){
  privateerContext={...privateerContext,...spec,mode:'mission'};
  game.loadout={...emptyLoadout(),...(privateerContext.loadout||{})};
  resetRun(Math.max(1,Number(privateerContext.difficulty)||1),(Number(privateerContext.seed)>>>0)||null);
  if(privateerContext.style==='hot'){
    game.detectedThisFloor=true;
    for(const enemy of game.enemies){enemy.state='alert';enemy.alertTime=999;enemy.lastKnown={x:game.player.x,y:game.player.y};}
  }
  announce(`${String(privateerContext.style||'choice').toUpperCase()} OPERATION · ${String(privateerContext.objective||privateerContext.kind||'COMPLETE OR EXTRACT').toUpperCase()}`,4);
  requestAnimationFrame(()=>privateerMessage('dmc-privateer-ready',{mode:'mission',style:privateerContext.style||'choice'}));
}
function finishPrivateerMission(outcome){
  if(privateerContext?.mode!=='mission')return false;
  const style=String(privateerContext.style||'choice'),completed=outcome==='completed';
  const clean=style!=='stealth'||!game.detectedThisFloor;
  const base=completed?40+Math.max(1,Number(privateerContext.difficulty)||1)*25:0;
  const bonus=completed&&style==='stealth'&&clean?Math.ceil(base*.75):0;
  privateerMessage('dmc-privateer-mission-result',{outcome,style,approachSucceeded:clean,kills:game.kills,
    detected:!!game.detectedThisFloor,cash:game.runCash+base+bonus,contractReward:base+bonus,objective:privateerContext.objective||''});
  return true;
}
function nearbyPortActor(){
  if(!game.world?.isSpaceport)return null;
  return game.world.actors.find(a=>!a.robbed&&!a.down&&Math.hypot(game.player.x-a.x,game.player.y-a.y)<76)||null;
}
function reportPortCrime(offense,severity,cash=0,witnessed=true){
  game.world.crime.heat+=severity*4;game.world.crime.witnessed ||= witnessed;
  for(const guard of game.world.actors.filter(a=>a.kind==='guard'&&!a.down))guard.alert=true;
  privateerMessage('dmc-privateer-crime',{offense,severity,cash,witnessed});updateUI();
}
function damagePortActor(actor,damage){
  if(!actor||actor.down)return false;
  actor.hp=Math.max(0,actor.hp-damage);actor.flash=.18;
  burst(actor.x,actor.y,actor.kind==='guard'?C.cyan:C.red,7,.35);
  if(!actor.assaultReported){actor.assaultReported=true;reportPortCrime(actor.kind==='guard'?'assault_security':'assault_civilian',actor.kind==='guard'?5:4,0,true);}
  if(actor.hp<=0){actor.down=true;announce(`${actor.name} DOWN · SECURITY RESPONSE ESCALATED`,2.5);}
  return true;
}
function interactPort(){
  if(game.mode!=='PORT')return false;
  const station=nearbyStation(),actor=nearbyPortActor();
  if(station){
    if(station.service==='terminal'){
      const terminalSeed=[...station.id].reduce((value,char)=>Math.imul(value^char.charCodeAt(0),16777619)>>>0,game.world.seed>>>0);
      privateerMessage('dmc-privateer-terminal',{terminal:station.id,hidden:!!station.hidden,seed:terminalSeed});
    }
    else if(station.service==='alley')announce('BACK ALLEY · FIND A LONE TRAVELLER · DRAW A WEAPON TO DEMAND CREDITS',3);
    else if(station.service==='venue')announce(`${station.venue} · LOCALS, RUMORS AND MISSION CONTACTS INSIDE`,3);
    else privateerMessage('dmc-privateer-service',{service:station.service});
    return true;
  }
  if(!actor)return false;
  if(actor.kind==='guard'){announce(actor.alert?'HALT · SURRENDER OR LEAVE THE PORT':'PATROL: KEEP YOUR WEAPON HOLSTERED.',2.5);return true;}
  if(game.player.weaponDrawn){
    const witnesses=game.world.actors.filter(a=>a!==actor&&!a.robbed&&Math.hypot(a.x-actor.x,a.y-actor.y)<260);
    const amount=12+game.world.rng.int(0,28);actor.robbed=true;game.world.crime.heat+=witnesses.length?18:8;game.world.crime.witnessed=!!witnesses.length;
    for(const guard of game.world.actors.filter(a=>a.kind==='guard'))guard.alert=!!witnesses.length;
    privateerMessage('dmc-privateer-crime',{offense:'street_robbery',severity:witnesses.length?3:2,cash:amount,witnessed:!!witnesses.length});
    announce(`${actor.name}: TAKE IT · +${amount} CR${witnesses.length?' · WITNESSES ALERT SECURITY':''}`,3);return true;
  }
  if(actor.mission&&!actor.offered){
    actor.offered=true;privateerMessage('dmc-privateer-mission-offer',{...actor.mission,seed:(game.world.seed^actor.id.length*7919)>>>0,contact:actor.name});
    announce(`${actor.name}: I HAVE A ${actor.mission.style.toUpperCase()} JOB. TALK AGAIN TO DEPLOY.`,3.5);
  }else if(actor.mission&&actor.offered){
    privateerMessage('dmc-privateer-loading',{mode:'mission',style:actor.mission.style});
    startPrivateerMission({...actor.mission,seed:(game.world.seed^actor.id.length*7919)>>>0,contact:actor.name,objective:actor.mission.kind});
    return true;
  }else announce(`${actor.name}: ${actor.rumor}`,4);
  privateerMessage('dmc-privateer-rumor',{speaker:actor.name,rumor:actor.rumor});return true;
}
function updatePort(dt){
  const p=game.player,control=captureInputs();
  game.portClock=(game.portClock||0)+dt;
  p.invuln=Math.max(0,p.invuln-dt);p.cool=Math.max(0,p.cool-dt);p.punchTimer=Math.max(0,p.punchTimer-dt);updateWeaponTimers(dt);
  moveWithCollisions(p,control.mx*p.speed*(p.sneaking?.62:1)*dt,control.my*p.speed*(p.sneaking?.62:1)*dt,p.r);
  discoverPortStations();
  if(Math.hypot(control.ax,control.ay)>.01)p.facing=Math.atan2(control.ay,control.ax);
  else if(Math.hypot(control.mx,control.my)>.25)p.facing=Math.atan2(control.my,control.mx);
  const queuedPress=inputs.shotgunPendingPresses>0&&p.weaponDrawn!==false;if(queuedPress)inputs.shotgunPendingPresses--;
  const triggerPress=queuedPress||(control.shoot&&!inputs.shotgunTriggerHeld);inputs.shotgunTriggerHeld=control.shoot;
  let fired=false;
  if(p.weapon==='shotgun')fired=triggerPress&&(p.cool<=0||p.pumpNeeded)?shootPlayer(p.facing):false;
  else if(control.shoot&&p.cool<=0)fired=shootPlayer(p.facing);
  if(fired==='fire'&&game.portClock-(game.world.crime.lastDischarge||-99)>1.5){game.world.crime.lastDischarge=game.portClock;reportPortCrime('weapons_discharge',2,0,true);}
  for(const actor of game.world.actors){
    if(actor.down||(actor.robbed&&actor.kind==='civilian'))continue;
    if(actor.kind==='guard'&&actor.alert)actor.target={x:p.x,y:p.y};
    const dx=actor.target.x-actor.x,dy=actor.target.y-actor.y,d=Math.hypot(dx,dy);
    if(d<18){
      const room=game.world.rooms[game.world.rng.int(0,game.world.rooms.length-1)];actor.target={x:room.cx+game.world.rng.range(-80,80),y:room.cy+game.world.rng.range(-65,65)};
    }else{
      const beforeX=actor.x,beforeY=actor.y;moveWithCollisions(actor,dx/d*actor.speed*dt,dy/d*actor.speed*dt,13);
      actor.stall=Math.hypot(actor.x-beforeX,actor.y-beforeY)<.05?(actor.stall||0)+dt:0;
      if(actor.stall>1.4){const room=game.world.rooms[game.world.rng.int(0,game.world.rooms.length-1)],spot=randomSpot(game.world,room,game.world.rng,18);actor.target=spot;actor.stall=0;}
    }
    if(actor.kind==='guard'&&actor.alert){
      actor.cool=Math.max(0,(actor.cool||0)-dt);actor.facing=Math.atan2(p.y-actor.y,p.x-actor.x);
      if(d<510&&d>70&&actor.cool<=0&&clearSight(game.world,actor.x,actor.y,p.x,p.y)){
        makeBullet(actor.x,actor.y,actor.facing,'enemy',.75,440,C.cyan,4);actor.cool=1.1;weaponShot('revolver');
      }
    }
    if(actor.kind==='guard'&&actor.alert&&Math.hypot(actor.x-p.x,actor.y-p.y)<42){
      privateerMessage('dmc-privateer-port-result',{outcome:'arrested',heat:game.world.crime.heat});actor.alert=false;announce('SECURITY DETAINED YOU · RETURNING TO LEGAL REVIEW',3);
    }
  }
  updateBullets(dt);updateParticles(dt);
  camera.x+=(p.x-camera.x)*Math.min(1,dt*8);camera.y+=(p.y-camera.y)*Math.min(1,dt*8);updateHQPrompt();
}
function nearbyStation(){
  if(!game.world?.isHQ||!game.player)return null;
  return game.world.stations.find(s=>Math.hypot(game.player.x-s.x,game.player.y-s.y)<91)||null;
}
function discoverPortStations(){
  if(!game.world?.isSpaceport||!game.player)return false;
  let found=false;
  for(const station of game.world.stations){
    if(!station.hidden||station.discovered||Math.hypot(game.player.x-station.x,game.player.y-station.y)>135)continue;
    station.discovered=true;found=true;
    announce(`HIDDEN ACCESS NODE FOUND · ${station.label}`,2.6);
  }
  return found;
}
function updateHQPrompt(){
  const station=nearbyStation();
  const actor=game.world?.isSpaceport?nearbyPortActor():null,key=station?.id||actor?.id||null;
  if(key===game.hqStation)return;
  game.hqStation=key;
  show('hqPrompt',!!station||!!actor);
  if(station)$('hqInteractButton').textContent=`INTERACT · ${station.label}`;
  else if(actor)$('hqInteractButton').textContent=`TALK · ${actor.name}${game.player.weaponDrawn&&actor.kind==='civilian'?' · ROB':''}`;
}
function openHQPanel(kind){
  if(game.mode!=='HQ')return false;
  game.hqPanel=kind;
  game.mode='HQ_PANEL';inputs.move={x:0,y:0};inputs.aim={x:0,y:0};inputs.mouse.down=false;
  show('hqPrompt',false);show('hq',true);show('touchUI',false);
  $('hqHeading').textContent=kind==='storage'?'EQUIPMENT STORAGE':kind==='medical'?'FIELD MEDICAL':'RESISTANCE ARMORY';
  $('hqSection').textContent=kind==='storage'?'STORED INVENTORY  //  EQUIP OR SECURE YOUR GEAR':
    kind==='medical'?'REPAIR KITS  //  PURCHASE SUPPLIES':'WEAPONS, ARMOR & FIELD GEAR  //  PURCHASE INTO STORAGE';
  $('hqSubheading').textContent=kind==='storage'?'STASHED EQUIPMENT SURVIVES DEATH. EQUIPPED GEAR IS AT RISK.':
    kind==='medical'?'SUPPLIES AND REPAIR KITS ARE SAVED IN HQ STORAGE.':'PURCHASED EQUIPMENT IS SENT TO YOUR STORAGE LOCKER.';
  renderHQ();return true;
}
function closeHQPanel(){
  if(game.mode!=='HQ_PANEL')return;
  game.mode='HQ';show('hq',false);show('touchUI',true);game.hqStation=null;updateHQPrompt();
}
function interactHQ(){
  if(game.mode==='PORT')return interactPort();
  if(game.mode!=='HQ')return false;
  const station=nearbyStation();if(!station)return false;
  if(station.id==='deploy')openTravel();
  else openHQPanel(station.id);
  return true;
}
function ownedOnField(id){const l=game.loadout;
  return id==='map'?Number(l.map):id==='medkit'?l.medkits:
   id.startsWith('armor')?Number(l.armor===Number(id.slice(-1))):Number(l.weapon===id);
}
function storeField(id){const l=game.loadout;if(!ownedOnField(id))return;
  if(id==='map')l.map=false;
  else if(id==='medkit')l.medkits--;
  else if(id.startsWith('armor'))l.armor=0;
  else l.weapon='hands';
  stash(id);renderHQ();
}
function equipFromStash(id){const l=game.loadout;if((game.profile.storage[id]||0)<=0)return false;
  if(id==='map'){if(l.map)return false;l.map=true;}
  else if(id==='medkit'){if(l.medkits>=MAX_REPAIR_KITS)return false;l.medkits++;}
  else if(id.startsWith('armor')){
    if(l.armor)stash('armor'+l.armor);
    l.armor=Number(id.slice(-1));
  }else{
    if(l.weapon!=='hands')stash(l.weapon);
    l.weapon=id;
  }
  game.profile.storage[id]--;saveProfile();renderHQ();return true;
}
function purchase(id){const g=SHOP_GEAR.find(g=>g.id===id);if(!g||game.profile.credits<g.cost)return false;
  game.profile.credits-=g.cost;stash(id);playSound('buy');renderHQ();return true;
}
function renderHQ(){
  const l=game.loadout;
  $('hqCredits').innerHTML=`${game.profile.credits} <small>CR</small>`;
  $('hqLoadout').textContent=`FIELD: ${WEAPONS[l.weapon].label} · ${l.armor?`ARMOR +${l.armor}`:'NO ARMOR'} · ${l.map?'RADAR':'NO RADAR'} · ${l.medkits} REPAIR KITS    //    STASHED GEAR SAFE`;
  const root=$('hqItems');root.replaceChildren();
  for(const g of SHOP_GEAR){
    if(game.hqPanel==='medical'&&g.id!=='medkit')continue;
    const el=document.createElement('article');el.className='shop-card';
    const tag=document.createElement('span');tag.className='tag';tag.textContent=`IN STORAGE ${game.profile.storage[g.id]} · FIELD ${ownedOnField(g.id)}`;
    const h=document.createElement('h3');h.textContent=g.name;
    const desc=document.createElement('p');desc.textContent=g.desc;
    const actions=document.createElement('div');actions.className='hq-actions';
    const buy=document.createElement('button');buy.textContent=`BUY ${g.cost} CR`;buy.disabled=game.profile.credits<g.cost;
    buy.addEventListener('click',()=>purchase(g.id));if(game.hqPanel!=='storage')actions.appendChild(buy);
    const equip=document.createElement('button');equip.textContent='EQUIP';
    equip.disabled=!game.profile.storage[g.id]||(g.id==='map'&&l.map)||(g.id==='medkit'&&l.medkits>=MAX_REPAIR_KITS);
    equip.addEventListener('click',()=>equipFromStash(g.id));if(game.hqPanel==='storage')actions.appendChild(equip);
    if(game.hqPanel==='storage'&&ownedOnField(g.id)){
      const store=document.createElement('button');store.textContent='STORE';
      store.addEventListener('click',()=>storeField(g.id));actions.appendChild(store);
    }
    el.append(tag,h,desc,actions);root.appendChild(el);
  }
}
function openTravel(){
  if(game.mode!=='HQ')return false;
  game.mode='TRAVEL';inputs.move={x:0,y:0};inputs.mouse.down=false;
  show('travel',true);show('touchUI',false);show('hqPrompt',false);
  renderTravel();return true;
}
function closeTravel(){if(game.mode!=='TRAVEL')return;show('travel',false);game.mode='HQ';show('touchUI',true);updateHQPrompt();}
function renderTravel(){
  const root=$('travelOptions');root.replaceChildren();
  for(const floor of travelTiers){
    const cost=TRAVEL_COSTS[floor],unlocked=game.profile.unlockedFloor>=floor,affordable=game.profile.credits>=cost;
    const el=document.createElement('button');el.className='travel-choice';
    el.textContent=`SECTOR ${String(floor).padStart(2,'0')}  ·  ${cost?cost+' CR':'FREE'}  ·  ${!unlocked?'LOCKED / REACH SECTOR '+floor:!affordable?'INSUFFICIENT CREDITS':'DEPLOY'}`;
    el.disabled=!unlocked||!affordable;
    el.addEventListener('click',()=>fastTravel(floor));root.appendChild(el);
  }
  $('travelWallet').textContent=`BANK ${game.profile.credits} CR · DEEPEST SECTOR ${game.profile.unlockedFloor}`;
}
function fastTravel(floor){
  const cost=TRAVEL_COSTS[floor];
  if(game.mode!=='TRAVEL'||cost===undefined||game.profile.unlockedFloor<floor||game.profile.credits<cost)return false;
  game.profile.credits-=cost;saveProfile();show('travel',false);
  resetRun(floor);saveGame();
  return true;
}
function initialMagazines(){return Object.fromEntries(Object.entries(WEAPONS).filter(([,w])=>w.magazine).map(([id,w])=>[id,w.magazine]));}
function resetRun(startFloor=1,runSeed=null){
  inputs.sneakTouch=false;inputs.shotgunTriggerHeld=false;inputs.shotgunPendingPresses=0;$('sneakButton').classList.toggle('active',false);
  const l=game.loadout;
  game.floor=startFloor;game.seed=runSeed===null?(Math.random()*0xffffffff)>>>0:runSeed;game.kills=0;game.runCash=0;game.time=0;
  game.upgradeLevels={};
  game.player={x:0,y:0,r:16,hp:3+l.armor,maxHp:3+l.armor,cash:game.profile.credits,weapon:l.weapon,
    armorTier:l.armor,map:l.map,medkits:l.medkits,spares:[...l.spares],magazines:initialMagazines(),reloadClock:0,reloadTotal:0,reloadWeapon:null,reloadShells:0,reloadStage:null,pumpClock:0,pumpTotal:0,pumpNeeded:false,swingHand:0,speed:230,damage:1,rate:1,armor:0,scavenging:1,stealth:1,
    sneaking:false,cool:0,invuln:0,facing:0,walkCycle:0,punchTimer:0,stepClock:0};
  beginFloor();hiddenScreens();show('hqPrompt',false);document.body?.classList.toggle('hq-mode',false);
  game.mode='PLAY';show('hud',true);show('location',true);show('touchUI',true);show('aimTip',true);
  announce(`SECTOR ${String(game.floor).padStart(2,'0')} // ${game.world.stratum.name} · FIND STAIRS OR EXFIL`,2.5);updateUI();playSound('start');
  show('hqMenuButton',false);
}
function beginFloor(){
  game.world=generateFloor(game.floor,game.seed);
  if(game.floor>game.profile.unlockedFloor){game.profile.unlockedFloor=game.floor;saveProfile();}
  if(game.floor>bestFloor){bestFloor=game.floor;try{localStorage.setItem('neon-breach.best',String(bestFloor))}catch{};
    $('bestReadout').textContent=`PERSONAL BEST // SECTOR ${String(bestFloor).padStart(2,'0')}`;}
  game.monsterSoundClock=3+Math.random()*4;game.enemyFootBudget=0;
  game.enemies=[];game.bullets=[];game.pickups=[];game.particles=[];game.exitClock=0;game.extraction=null;game.floorClearPaid=false;game.detectedThisFloor=false;
  const start=game.world.rooms[0];game.player.x=start.cx;game.player.y=start.cy;
  game.player.cool=0;game.player.invuln=1.15;game.activeRoom=0;
  // Populate the whole floor at once. Only a small arrival bubble is safe;
  // crossing an architectural boundary never creates or confines an enemy.
  for(const room of game.world.rooms){room.spawned=true;room.enemies=[];}
  spawnFloorEnemies();
  finalizeGuardRoster();
  camera.x=game.player.x;camera.y=game.player.y;game.shake=0;
  updateUI();
}
function enterRoom(r){
  if(game.activeRoom===r.id)return;
  game.activeRoom=r.id;
  const firstVisit=!r.visited;
  r.visited=true;
  if(firstVisit)announce(r.exit?'STAIRWAY LOCATED':r.exfil?'OPTIONAL EXFIL LOCATED':'AREA DISCOVERED  //  STAY ALERT',1.2);
  updateUI();
}
function spawnFloorEnemies(){
  const floor=game.floor,rng=game.world.rng;
  const positions=planFloorPoints(game.world,game.world.spawnBudget);
  game.world.spawnSites=positions;
  const count=positions.length;
  for(let k=0;k<count;k++){
    const type=chooseEnemy(rng,floor),def=TYPE[type],pos=positions[k];
    const room=roomAt(game.world,pos.x,pos.y);
    const hpScale=1+(floor-1)*.058+room.depth*.012;
    const guardWeapon=type==='trapezoid'?chooseGuardWeapon(rng,floor):type==='diamond'?'knife':null;
    const e={id:Math.random(),room:room.id,homeRoom:room.id,type,x:pos.x,y:pos.y,r:def.r,
      weapon:guardWeapon,hp:def.hp*hpScale,maxHp:def.hp*hpScale,spd:def.spd*(1+Math.min(type==='circle'||type==='square'?.10:.32,(floor-1)*.012)),
      angle:rand(0,TAU),cool:rand(.4,2),charge:rand(1,3),contact:0,flash:0,
      orbit:Math.random()<.5?1:-1,step:rand(0,TAU),dashTime:0,dashX:0,dashY:0,
      state:'idle',alertTime:0,searchTime:0,sees:false,suspicion:0,perceptionClock:rand(.02,.23),
      anchor:{x:pos.x,y:pos.y},patrol:{x:pos.x,y:pos.y},patrolClock:0,lastKnown:null,
      route:[],routeIndex:0,stareClock:0,stareAngle:0,lookIndex:0,lookClock:0,searchNodes:[],searchIndex:0,hadSight:false};
    game.enemies.push(e);room.enemies.push(e);
  }
}
function recordAlert(e){
  // A question mark is recoverable. Any full alert forfeits this floor's
  // bonus immediately, even if sight breaks or the enemy dies this frame.
  if(e.state==='alert')game.detectedThisFloor=true;
}
function alertEnemy(e,x,y,duration=6,state='alert'){
  e.lastKnown={x,y};
  e.alertTime=Math.max(e.alertTime,duration);
  e.searchTime=0;
  if(e.state!=='alert'||state==='alert')e.state=state;
  recordAlert(e);
  e.perceptionClock=Math.min(e.perceptionClock,.03);
}
function emitNoise(x,y,volume=1){
  // Audible running is a location clue, including for zombies; walls still
  // block sight and hearing never grants the ability to shoot through them.
  for(const e of game.enemies){
    if(e.state==='alert'||!canHear(e,x,y,volume))continue;
    const duration=e.type==='circle'?2.5:e.type==='square'?1.5:e.type==='pentagon'?6.5:e.type==='trapezoid'?5.5:3;
    alertEnemy(e,x,y,duration,'investigate');
  }
}
function playerDamage(amount){
  const p=game.player;if(!['PLAY','PORT'].includes(game.mode)||p.invuln>0)return;
  p.invuln=.86;
  if(Math.random()<p.armor){announce('ARMOR DEFLECTED',.8);playSound('hit');return;}
  if(game.mode==='PLAY')game.detectedThisFloor=true;p.hp=Math.max(0,p.hp-amount);game.shake=12;game.flashed=.27;
  playSound('hurt');burst(p.x,p.y,C.red,12);updateUI();
  if(p.hp<=0)die();
}
function die(){
  game.extraction=null;game.exitClock=0;
  if(game.mode==='PORT'){
    privateerMessage('dmc-privateer-port-result',{outcome:'hospitalized',heat:game.world.crime.heat});
    game.player.hp=game.player.maxHp;game.player.invuln=2;game.bullets=[];announce('PORT SECURITY DROPPED YOU · EMERGENCY EXTRACTION',3);return;
  }
  finishPrivateerMission('captured');
  game.mode='DEAD';show('death',true);show('touchUI',false);show('aimTip',false);
  game.loadout=emptyLoadout();saveProfile();
  saveGame(true);
  $('deathStats').textContent=`SECTOR ${String(game.floor).padStart(2,'0')}  ·  ${game.kills} KILLS  ·  ${game.runCash} CR BANKED  ·  ${game.profile.credits} CR SAFE`;
  game.shake=0;inputs.mouse.down=false;
  if(game.floor>bestFloor){bestFloor=game.floor;try{localStorage.setItem('neon-breach.best',String(bestFloor))}catch{}}
  $('bestReadout').textContent=`PERSONAL BEST // SECTOR ${String(bestFloor).padStart(2,'0')}`;
}
function recoverGear(){
  const p=game.player;
  if(p.weapon!=='hands')stash(p.weapon);
  if(p.armorTier)stash('armor'+p.armorTier);
  if(p.map)stash('map');
  if(p.medkits)stash('medkit',p.medkits);
  for(const item of p.spares||[])stash(item);
  game.loadout=emptyLoadout();saveProfile();
}
function exfil(){
  game.extraction=null;game.exitClock=0;
  if(finishPrivateerMission('extracted'))return;
  recoverGear();playSound('start');enterHQ(`EXFIL SUCCESS // GEAR RECOVERED // ${game.profile.credits} CREDITS SAFE`);saveGame(true);
}
function nextFloor(){
  if(finishPrivateerMission('completed'))return;
  for(const e of game.enemies)recordAlert(e);
  const clear=floorAdvanceAward(game.floor,game.world.rooms.length),stealth=game.detectedThisFloor?0:stealthAward(game.floor);
  credit(clear+stealth);game.floor++;beginFloor();game.mode='PLAY';
  announce(`SECTOR COMPLETE +${clear} CR${stealth?' // NO ALERTS +'+stealth+' CR BONUS':''} // LEVEL ${game.floor}`,3);playSound('door');saveGame();
}
function useMedkit(){
  const p=game.player;if(game.mode!=='PLAY'||!p||p.medkits<=0||p.hp>=p.maxHp)return false;
  p.medkits--;p.hp=Math.min(p.maxHp,p.hp+1);announce('REPAIR KIT USED // +1 HP',1.4);playSound('pickup');updateUI();return true;
}
function togglePause(){
  if(game.mode==='PLAY'||game.mode==='HQ'){
    game.pausedFrom=game.mode;$('quitButton').disabled=game.pausedFrom!=='PLAY';game.mode='PAUSE';show('pause',true);show('touchUI',false);inputs.mouse.down=false;inputs.mouse.stealthHeld=false;
  }else if(game.mode==='PAUSE'){
    game.mode=game.pausedFrom||'PLAY';show('pause',false);show('touchUI',true);
  }
}
function returnToTitle(){
  if(game.mode==='TRAVEL')closeTravel();
  if(game.mode==='SETTINGS')closeSettings();
  if(game.mode==='HQ_PANEL')closeHQPanel();
  if(game.mode==='PLAY'||game.mode==='HQ'||game.mode==='PAUSE')saveGame();
  game.mode='MENU';hiddenScreens();show('menu',true);show('hud',false);show('touchUI',false);
  show('location',false);show('hqPrompt',false);show('hqMenuButton',false);
  document.body?.classList.toggle('hq-mode',false);
  $('loadButton').disabled=!hasSave();
}
function hasSave(){try{return !!JSON.parse(localStorage.getItem(SAVE_KEY)||'null')?.version;}catch{return false;}}
function saveGame(forceHQ=false){
  if(privateerContext)return false;
  const mode=forceHQ?'HQ':game.mode==='SETTINGS'?(settingsReturn==='PAUSE'?game.pausedFrom:'HQ'):game.mode==='PAUSE'?game.pausedFrom:game.mode;
  const inMission=mode==='PLAY';
  const slot={version:1,profile:structuredCloneSafe(game.profile),loadout:structuredCloneSafe(game.loadout),
    best:bestFloor,savedAt:new Date().toISOString(),mode:inMission?'PLAY':'HQ'};
  if(inMission&&game.player&&game.world&&!game.world.isHQ){
    slot.run={floor:game.floor,seed:game.seed,kills:game.kills,runCash:game.runCash,time:game.time,
      player:structuredCloneSafe(game.player),enemies:game.enemies.map(({navigation,coverPlan,...enemy})=>structuredCloneSafe(enemy)),
      pickups:structuredCloneSafe(game.pickups),
      rooms:game.world.rooms.map(r=>({visited:r.visited,cleared:r.cleared,cover:structuredCloneSafe(r.cover),caches:structuredCloneSafe(r.caches)})),
      rngState:game.world.rng.state,floorClearPaid:!!game.floorClearPaid,detectedThisFloor:!!game.detectedThisFloor,extraction:game.extraction?{...game.extraction}:null,
      bullets:game.bullets.map(b=>({...b,hitIds:[...(b.hitIds||[])]}))};
  }
  try{localStorage.setItem(SAVE_KEY,JSON.stringify(slot));$('loadButton').disabled=false;return true;}catch{return false;}
}
function structuredCloneSafe(o){return JSON.parse(JSON.stringify(o));}
function loadGame(){
  let slot=null;try{slot=JSON.parse(localStorage.getItem(SAVE_KEY)||'null');}catch{}
  if(!slot||slot.version!==1){enterHQ('NO SAVE SLOT // USING HQ AUTOSAVE');return false;}
  game.profile={credits:Math.max(0,Math.floor(Number(slot.profile?.credits)||0)),
    unlockedFloor:Math.max(1,Math.floor(Number(slot.profile?.unlockedFloor)||1)),
    firstGuardFloor:[7,8].includes(slot.profile?.firstGuardFloor)?slot.profile.firstGuardFloor:game.profile.firstGuardFloor,
    storage:cleanStash(slot.profile?.storage)};
  game.loadout={...emptyLoadout(),...slot.loadout};
  bestFloor=Math.max(bestFloor,Number(slot.best)||0);
  try{localStorage.setItem('neon-breach.best',String(bestFloor));}catch{}
  $('bestReadout').textContent=`PERSONAL BEST // SECTOR ${String(bestFloor).padStart(2,'0')}`;
  saveProfile(false);
  if(slot.mode==='PLAY'&&slot.run){
    try{
      const r=slot.run;game.floor=r.floor;game.seed=r.seed;game.kills=r.kills;game.runCash=r.runCash;game.time=r.time;
      game.world=generateFloor(r.floor,r.seed);game.world.rng.state=r.rngState;
      for(let i=0;i<game.world.rooms.length;i++){
        const room=game.world.rooms[i],old=r.rooms?.[i];if(!old)continue;
        room.visited=!!old.visited;room.cleared=!!old.cleared;room.cover=old.cover;room.caches=old.caches;room.spawned=true;
      }
      game.enemies=r.enemies||[];game.pickups=r.pickups||[];
      game.bullets=(r.bullets||[]).map(b=>({...b,hitIds:new Set(b.hitIds||[])}));game.particles=[];
      game.extraction=r.extraction?{...r.extraction}:null;game.floorClearPaid=!!r.floorClearPaid;game.detectedThisFloor=!!r.detectedThisFloor;
      for(const e of game.enemies)recordAlert(e);
      for(const room of game.world.rooms)room.enemies=game.enemies.filter(e=>e.homeRoom===room.id);
      restoreFloorPatrols();
      game.player={...r.player,magazines:{...initialMagazines(),...r.player.magazines},reloadClock:r.player.reloadClock||0,pumpClock:r.player.pumpClock||0,
        pumpNeeded:!!r.player.pumpNeeded,reloadShells:r.player.reloadShells||0,reloadStage:r.player.reloadStage||null};
      // Import legacy v0.9 automatic shotgun reloads as a five-shell sequence.
      if(game.player.reloadWeapon==='shotgun'&&game.player.reloadClock>0&&!('reloadShells' in r.player)){
        const oldFraction=Math.max(0,Math.min(1,1-game.player.reloadClock/Math.max(.01,game.player.reloadTotal)));
        const w=WEAPONS.shotgun;
        game.player.reloadTotal=w.magazine*w.shellTime+w.rackTime;
        game.player.reloadClock=game.player.reloadTotal*(1-oldFraction);
        game.player.reloadShells=Math.min(w.magazine,Math.floor((game.player.reloadTotal-game.player.reloadClock)/w.shellTime));
        game.player.reloadStage=game.player.reloadShells===w.magazine?'rack':'loading';
        game.player.magazines.shotgun=game.player.reloadShells;
      }
      // Old v0.9 saves used an automatic pump timer. Convert it into a required click.
      if(game.player.weapon==='shotgun'&&game.player.pumpClock>0&&game.player.reloadClock===0){
        game.player.pumpClock=0;game.player.pumpNeeded=game.player.magazines.shotgun>0;
      }
      game.player.maxHp=3+(game.player.armorTier||0);game.player.hp=Math.min(game.player.hp,game.player.maxHp);
      game.player.medkits=Math.min(MAX_REPAIR_KITS,game.player.medkits||0);
      inputs.shotgunTriggerHeld=false;inputs.shotgunPendingPresses=0;
      game.player.invuln=Math.max(.7,game.player.invuln||0);game.exitClock=0;game.shake=0;
      game.activeRoom=roomAt(game.world,game.player.x,game.player.y)?.id||0;
      game.monsterSoundClock=4;
      camera.x=game.player.x;camera.y=game.player.y;
      hiddenScreens();show('hud',true);show('location',true);show('touchUI',true);show('hqMenuButton',false);
      document.body?.classList.toggle('hq-mode',false);
      game.mode='PLAY';updateUI();announce('OPERATION RESTORED // MISSION SAVE LOADED',2);return true;
    }catch(err){console.warn('Mission snapshot failed, restoring HQ instead',err);}
  }
  enterHQ('SAVED GAME LOADED // WELCOME BACK');return true;
}
function newGame(){
  if(!confirm('Start a new game? All credits, stored equipment, and unlocks will be reset.'))return false;
  game.profile={credits:0,storage:cleanStash(),unlockedFloor:1,firstGuardFloor:Math.random()<.5?7:8};game.loadout=emptyLoadout();bestFloor=0;
  try{localStorage.setItem('neon-breach.best','0');localStorage.setItem(SAVE_KEY,'');}catch{}
  saveProfile();$('bestReadout').textContent='PERSONAL BEST // SECTOR 00';
  enterHQ('NEW OPERATOR // SECTOR 01 AVAILABLE');saveGame(true);return true;
}
let settingsReturn='MENU';
function openSettings(){
  settingsReturn=game.mode==='PAUSE'?'PAUSE':'MENU';
  show('settings',true);const s=getAudioSettings();
  for(const k of ['musicOn','sfxOn'])$(k).checked=s[k];
  for(const k of ['musicVolume','sfxVolume']){$(k).value=s[k];$(k+'Value').textContent=s[k]+'%';}
  game.mode='SETTINGS';
}
function closeSettings(){show('settings',false);game.mode=settingsReturn;}

function quitRun(){
  // Deliberate abort has the same field-gear risk as death, never a credit penalty.
  game.loadout=emptyLoadout();saveProfile();
  inputs.sneakTouch=false;$('sneakButton').classList.toggle('active',false);
  enterHQ('MISSION ABORTED // DEPLOYED EQUIPMENT LOST // CREDITS SAFE');
}

function captureInputs(){
  let mx=0,my=0,ax=0,ay=0,shoot=false;
  const wasSneaking=game.player.sneaking;
  const sneakHeld=inputs.mouse.stealthHeld||inputs.keys.has('ShiftLeft')||inputs.keys.has('ShiftRight')||inputs.sneakTouch;
  game.player.sneaking=sneakHeld;
  const k=inputs.keys;
  if(k.has('KeyA')||k.has('ArrowLeft'))mx--;
  if(k.has('KeyD')||k.has('ArrowRight'))mx++;
  if(k.has('KeyW')||k.has('ArrowUp'))my--;
  if(k.has('KeyS')||k.has('ArrowDown'))my++;
  mx+=inputs.move.x;my+=inputs.move.y;
  if(Math.hypot(inputs.aim.x,inputs.aim.y)>.22){ax=inputs.aim.x;ay=inputs.aim.y;shoot=true;}
  else if(inputs.mouse.valid){
    const screenPlayer={x:SW/2+(game.player.x-camera.x)*zoom,y:SH/2+(game.player.y-camera.y)*zoom};
    const dx=inputs.mouse.x-screenPlayer.x,dy=inputs.mouse.y-screenPlayer.y;
    if(Math.hypot(dx,dy)>12){ax=dx;ay=dy;}
    shoot=inputs.mouse.down||k.has('Space');
  }
  // Space attacks along the last facing even before mouse motion.
  if(k.has('Space'))shoot=true;
  const pads=navigator.getGamepads?.()||[];
  for(const gp of pads)if(gp){
    const px=gp.axes[0]||0,py=gp.axes[1]||0,rx=gp.axes[2]||0,ry=gp.axes[3]||0;
    if(Math.hypot(px,py)>.19){mx=px;my=py;}
    if(Math.hypot(rx,ry)>.24){ax=rx;ay=ry;shoot=true;}
    if(gp.buttons[7]?.pressed)shoot=true;
    game.player.sneaking=!!gp.buttons[10]?.pressed||sneakHeld;
    const pausePressed=!!gp.buttons[9]?.pressed;
    if(pausePressed&&!gamepadPauseDown)togglePause();gamepadPauseDown=pausePressed;
    break;
  }
  const m=Math.hypot(mx,my);if(m>1){mx/=m;my/=m;}
  const a=Math.hypot(ax,ay);if(a>.05){ax/=a;ay/=a;}
  else{ax=Math.cos(game.player.facing);ay=Math.sin(game.player.facing);}
  if(game.player.sneaking!==wasSneaking)updateUI();
  return {mx,my,ax,ay,shoot:shoot&&game.player.weaponDrawn!==false};
}
function moveWithCollisions(obj,dx,dy,r,locked=null){
  const x=obj.x+dx,y=obj.y+dy;
  if(walkable(game.world,x,obj.y,r,locked))obj.x=x;
  if(walkable(game.world,obj.x,y,r,locked))obj.y=y;
}
function makeBullet(x,y,angle,source,damage,speed,color,r,pierce=0){
  game.bullets.push({x:x+Math.cos(angle)*24,y:y+Math.sin(angle)*24,px:x,py:y,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed,source,damage,color,r,pierce,life:source==='player'?1.2:3,hitIds:new Set()});
}
function damageFurniture(prop,damage,x=prop.x,y=prop.y){
  if(!prop||prop.hp<=0)return false;
  prop.hp=Math.max(0,prop.hp-damage);
  const color=TILESETS[game.world.stratum.id].trim;
  burst(x,y,color,prop.hp<=0?12:3,prop.hp<=0?.9:.35);
  if(prop.hp<=0){
    game.world.navigationRevision=(game.world.navigationRevision||0)+1;
    floating('DESTROYED',prop.x,prop.y,C.gold);
    if(!game.world.isHQ&&Math.random()<.005){
      const kinds=['chest','weapon','equipment','med'];makePickup(kinds[Math.floor(Math.random()*kinds.length)],prop.x,prop.y,1);
    }
    playSound('kill');
  }else playSound('hit');
  return true;
}
function punchFurniture(p,angle,reach,arc,damage){
  let best=null,dist=Infinity;
  for(const room of game.world.rooms){
    if(Math.abs(room.cx-p.x)>room.w*.7+reach+100||Math.abs(room.cy-p.y)>room.h*.7+reach+100)continue;
    for(const o of room.cover){
      if(o.hp<=0)continue;
      const dx=o.x-p.x,dy=o.y-p.y,d=Math.hypot(dx,dy);
      if(d>p.r+reach+Math.max(o.w,o.h)*.47||Math.abs(angleDifference(Math.atan2(dy,dx),angle))>arc)continue;
      if(d<dist){dist=d;best=o;}
    }
  }
  if(best)damageFurniture(best,damage,best.x,best.y);
  return !!best;
}
// No manual reload action exists: this function accepts EMPTY magazines only.
// Reserve ammunition is unlimited, and weapons reload immediately after the final shot.
function startReload(){
  const p=game.player;if(!['PLAY','PORT'].includes(game.mode)||!p)return false;
  const w=WEAPONS[p.weapon];
  if(!w.magazine||p.reloadClock>0||p.magazines?.[p.weapon]!==0)return false;
  p.reloadWeapon=p.weapon;p.pumpClock=0;p.pumpNeeded=false;
  p.reloadShells=0;p.reloadStage='loading';
  p.reloadTotal=p.weapon==='shotgun'?w.magazine*w.shellTime+w.rackTime:w.reload;
  p.reloadClock=p.reloadTotal;
  p.cool=Math.max(p.cool,.08);
  reloadSound(p.weapon,'start');updateUI();return true;
}
function updateWeaponTimers(dt){
  const p=game.player;if(!p)return;
  if(p.reloadClock>0){
    const weapon=p.reloadWeapon;
    const w=WEAPONS[weapon];
    if(!w){p.reloadClock=0;p.reloadWeapon=null;return;}
    p.reloadClock=Math.max(0,p.reloadClock-dt);
    if(weapon==='revolver'){
      const inserted=Math.min(w.magazine,Math.floor((p.reloadTotal-p.reloadClock)/w.reload*w.magazine));
      for(let i=p.reloadShells||0;i<inserted;i++)reloadSound('revolver','shell');
      p.reloadShells=inserted;p.magazines.revolver=inserted;
    }
    if(weapon==='shotgun'){
      // Each shell arrives as its own timed reload step in the tube.
      const elapsed=p.reloadTotal-p.reloadClock;
      const inserted=Math.min(w.magazine,Math.floor((elapsed+0.00001)/w.shellTime));
      for(let i=p.reloadShells||0;i<inserted;i++)reloadSound('shotgun','shell');
      p.reloadShells=inserted;
      p.magazines.shotgun=inserted;
      // The final rack/chamber action is part of RELOAD, never a sixth input.
      if(inserted===w.magazine&&p.reloadStage!=='rack'){
        p.reloadStage='rack';pumpSound();
      }
    }
    if(p.reloadClock===0){
      p.magazines[weapon]=w.magazine;
      reloadSound(weapon,'finish');
      p.reloadWeapon=null;p.reloadStage=null;p.pumpNeeded=false;updateUI();
    }
  }
  if(p.pumpClock>0){
    p.pumpClock=Math.max(0,p.pumpClock-dt);
    if(p.pumpClock===0)updateUI();
  }
}
function toggleWeaponDraw(){
  if(!['PLAY','PORT'].includes(game.mode)||!game.player)return false;
  game.player.weaponDrawn=game.player.weaponDrawn===false;
  inputs.mouse.down=false;inputs.aim={x:0,y:0};inputs.keys.delete('Space');
  inputs.shotgunPendingPresses=0;inputs.shotgunTriggerHeld=false;
  updateUI();return true;
}
function shootPlayer(angle){
  const p=game.player,w=WEAPONS[p.weapon];
  if(p.weaponDrawn===false)return false;
  if(w.magazine){
    if(p.reloadClock>0||p.pumpClock>0)return false;
    p.magazines??=initialMagazines();
    if(p.weapon==='shotgun'&&p.pumpNeeded){
      // Shotgun: second click is the player's deliberate pump, NOT another shot.
      p.pumpClock=w.pump;p.pumpTotal=w.pump;p.pumpNeeded=false;
      p.cool=.08;p.punchTimer=w.pump;
      pumpSound();updateUI();return 'pump';
    }
    if(p.magazines[p.weapon]<=0){startReload();return false;}
    p.magazines[p.weapon]--;
  }
  p.cool=w.cooldown/p.rate;
  updateUI();
  if(w.melee){
    // Hands and knife BOTH alternate arms, with faster independent strikes.
    // The knife uses the same close-quarter targeting/stealth logic, amplified.
    if(p.weapon==='hands')p.swingHand=(p.swingHand+1)%2;
    else p.swingHand=1; // Knife stays in the right hand, one-handed like the original punch.
    p.punchTimer=w.cooldown*.75;
    const reach=p.weapon==='knife'?70:45,arc=p.weapon==='knife'?1.05:.92;
    const portTargets=game.mode==='PORT'?game.world.actors.filter(actor=>!actor.down&&Math.hypot(actor.x-p.x,actor.y-p.y)<actor.r+p.r+reach&&
      Math.abs(angleDifference(Math.atan2(actor.y-p.y,actor.x-p.x),angle))<arc&&clearSight(game.world,p.x,p.y,actor.x,actor.y)):[];
    if(portTargets.length){
      portTargets.sort((a,b)=>distance(p,a)-distance(p,b));damagePortActor(portTargets[0],w.damage*p.damage);melee(p.weapon,p.swingHand===0);return 'melee';
    }
    const hits=game.enemies.filter(e=>{
      const d=Math.hypot(e.x-p.x,e.y-p.y);
      return d<e.r+p.r+reach && Math.abs(angleDifference(Math.atan2(e.y-p.y,e.x-p.x),angle))<arc
        && clearSight(game.world,p.x,p.y,e.x,e.y);
    }).sort((a,b)=>distance(p,a)-distance(p,b));
    if(hits.length){
      const e=hits[0];
      const behind=Math.abs(angleDifference(Math.atan2(p.y-e.y,p.x-e.x),e.angle))>2.25;
      const takedown=p.sneaking&&behind&&e.state!=='alert'&&e.type!=='pentagon';
      const hit=w.damage*p.damage*(takedown?(p.weapon==='knife'?3.6:4):1);
      e.hp-=hit;e.flash=.16;
      burst(e.x,e.y,TYPE[e.type].color,p.weapon==='knife'?8:5,.3);
      if(e.hp<=0)killEnemy(e);
      else alertEnemy(e,p.x,p.y,5.2,'alert');
      if(takedown)floating('SILENT STRIKE',e.x,e.y,C.green);
      else emitNoise(p.x,p.y,p.weapon==='knife'?.17:.26);
    }else{
      const broken=punchFurniture(p,angle,reach,arc,w.damage*p.damage);
      if(broken)emitNoise(p.x,p.y,p.weapon==='knife'?.16:.22);
      else if(!p.sneaking)emitNoise(p.x,p.y,.13);
    }
    melee(p.weapon,p.swingHand===0);return;
  }
  for(let i=0;i<w.pellets;i++){
    const a=angle+(w.pellets===1?rand(-w.spread,w.spread):rand(-w.spread/2,w.spread/2));
    makeBullet(p.x,p.y,a,'player',w.damage*p.damage,w.velocity,w.color,w.r,w.pierce);
  }
  burst(p.x+Math.cos(angle)*26,p.y+Math.sin(angle)*26,w.color,p.weapon==='shotgun'?8:3,.23);
  emitNoise(p.x,p.y,p.weapon==='shotgun'?1.45:p.weapon==='ar'?1.28:1);
  weaponShot(p.weapon);
  if(w.magazine){
    if(p.magazines[p.weapon]===0)startReload();
    else if(p.weapon==='shotgun')p.pumpNeeded=true;
  }
  updateUI();
  return 'fire';
}
// Guard fire cadence, projectile patterns and muzzle graphics use the same
// per-enemy weapon assigned on spawning (no phantom rifles on diamonds).
function shootEnemy(e,angle,spread=0){
  const gun=e.type==='trapezoid'?(e.weapon||'revolver'):'heavy';
  const config={
    revolver:{count:1,cone:0,damage:1.15,velocity:420,radius:5},
    auto_pistol:{count:1,cone:.045,damage:.85,velocity:430,radius:4},
    shotgun:{count:5,cone:.64,damage:.43,velocity:350,radius:4},
    ar:{count:1,cone:.035,damage:.88,velocity:470,radius:4},
    heavy:{count:3,cone:.52,damage:2,velocity:345,radius:6}
  }[gun];
  for(let i=0;i<config.count;i++){
    const variation=config.count===1?0:(i/(config.count-1)-.5)*config.cone;
    makeBullet(e.x,e.y,angle+spread+variation,'enemy',config.damage,config.velocity,TYPE[e.type].color,config.radius);
  }
  burst(e.x+Math.cos(angle)*26,e.y+Math.sin(angle)*26,TYPE[e.type].color,gun==='shotgun'?5:2,.18);
}
function guardFireCooldown(e){
  if(e.type==='pentagon')return 2.25;
  return {revolver:1.70,auto_pistol:.56,shotgun:2.30,ar:.32}[e.weapon||'revolver'];
}
// An NPC never learns the player's exact position without sight or a noise.
// Patrol nodes, staring periods, and search points are precomputed per NPC;
// no enemy AI is created when a player walks into a new area.
function validPost(e,x,y){return walkable(game.world,x,y,e.r+3);}
function floorPatrolCircuit(){
  const world=game.world;
  if(world.patrolCircuit)return world.patrolCircuit;
  const points=planFloorPoints(world,Math.max(16,world.rooms.length*2),{safeRadius:0});
  // Include tiny architectural branches too; the positions remain one global
  // circuit, with no NPC home-room limits or room-entry triggers.
  for(const r of world.rooms)if(!points.some(p=>roomAt(world,p.x,p.y)?.id===r.id))points.push({x:r.cx,y:r.cy});
  const remaining=points.map(p=>({...p,room:roomAt(world,p.x,p.y)?.id})),circuit=[remaining.shift()];
  while(remaining.length){
    const last=circuit[circuit.length-1];let closest=0;
    for(let i=1;i<remaining.length;i++)if(distance(last,remaining[i])<distance(last,remaining[closest]))closest=i;
    circuit.push(remaining.splice(closest,1)[0]);
  }
  world.patrolCircuit=circuit;return circuit;
}
function buildPostRoute(e){
  const circuit=floorPatrolCircuit();let phase=0;
  for(let i=1;i<circuit.length;i++)if(distance(e,circuit[i])<distance(e,circuit[phase]))phase=i;
  const direction=e.orbit<0?-1:1,n=circuit.length;
  return Array.from({length:n},(_,i)=>({...circuit[(phase+i*direction+n)%n]}));
}
function restoreFloorPatrols(){
  for(const e of game.enemies){
    if(e.routeVersion===2)continue;
    e.route=e.duty==='post'?[{...e.anchor,room:e.homeRoom}]:buildPostRoute(e);
    e.routeIndex=0;e.patrol=e.route[0];e.routeVersion=2;delete e.navigation;
  }
}
function initializeBehavior(e){
  if(!e.anchor)e.anchor={x:e.x,y:e.y};
  if(!e.duty)e.duty='patrol';
  e.route=e.duty==='post'?[{...e.anchor,room:e.homeRoom}]:buildPostRoute(e);
  e.routeVersion=2;e.routeIndex=0;e.patrol=e.route[0];e.searchNodes=[];e.searchIndex=0;
  e.stareClock=e.type==='circle'?rand(1.2,2.8):rand(2.5,4);
  e.stareAngle=e.angle;e.lookIndex=0;e.lookClock=rand(.7,1.1);
  e.hadSight=false;e.isWalking=false;e.atPost=true;
}
function chooseCircleWander(e){
  const points=floorPatrolCircuit().filter(p=>validPost(e,p.x,p.y));
  const farthest=Math.max(...points.map(p=>distance(e,p)),0);
  const distant=points.filter(p=>distance(e,p)>=Math.min(280,farthest*.6));
  const choices=distant.length?distant:points;
  e.stareClock=0;e.patrol={...choices[Math.floor(Math.random()*choices.length)]};e.isWalking=true;
}
function finishPost(e){
  if(e.type==='circle'){
    e.stareClock=rand(1.2,2.8);e.stareAngle=rand(0,TAU);
    e.patrol={x:e.x,y:e.y};e.isWalking=false;
  }else{
    e.routeIndex=(e.routeIndex+1)%e.route.length;e.patrol=e.route[e.routeIndex];
    e.atPost=false;e.stareClock=0;
  }
}
function patrolIntent(e,dt){
  if(!e.route)initializeBehavior(e);
  const at=Math.hypot(e.x-e.patrol.x,e.y-e.patrol.y)<18;
  if(e.duty==='post'){
    if(!at)return {target:e.patrol,speed:e.spd*.48,look:Math.atan2(e.patrol.y-e.y,e.patrol.x-e.x)};
    e.stareClock-=dt;
    if(e.stareClock<=0){e.stareAngle+=e.orbit*Math.PI/2;e.stareClock=rand(2.5,4);}
    return {target:e.patrol,speed:0,look:e.stareAngle};
  }
  if(e.type==='circle'){
    if(e.isWalking){
      if(at)finishPost(e);
      else return {target:e.patrol,speed:e.spd*.50,look:Math.atan2(e.patrol.y-e.y,e.patrol.x-e.x)};
    }
    e.stareClock=Math.max(0,(e.stareClock||0)-dt);
    if(e.stareClock>0)return {target:{x:e.x,y:e.y},speed:0,look:e.stareAngle};
    chooseCircleWander(e);
  }else if(at){
    if(!e.atPost){
      e.atPost=true;e.stareClock=rand(2.5,4.5);e.stareAngle=e.angle;
      e.lookClock=rand(.65,1.1);
    }
    e.stareClock-=dt;e.lookClock-=dt;
    if(e.lookClock<=0){
      e.stareAngle+=(Math.random()<.5?-1:1)*Math.PI/2;e.lookClock=rand(.7,1.1);
    }
    if(e.stareClock>0)return {target:e.patrol,speed:0,look:e.stareAngle};
    finishPost(e);
  }
  return {target:e.patrol,speed:e.spd*(e.type==='square'?.53:e.type==='pentagon'?.32:.48),
    look:Math.atan2(e.patrol.y-e.y,e.patrol.x-e.x)};
}
function prepareSearch(e){
  if(e.type==='circle'){forgetWanderer(e);return;}
  const point=e.lastKnown||{x:e.x,y:e.y},nodes=[{...point}];
  if(e.type==='square'){
    e.searchTime=1.25; // Check the last position once; no extended search.
  }else{
    const a=Math.atan2(point.y-e.y,point.x-e.x),distances=[100,155,80,120];
    for(let i=0;i<distances.length;i++){
      const d=distances[i],angle=a+[Math.PI*.50,-Math.PI*.65,Math.PI,Math.PI*.22][i];
      const x=point.x+Math.cos(angle)*d,y=point.y+Math.sin(angle)*d;
      if(walkable(game.world,x,y,e.r+3))nodes.push({x,y});
    }
    // Dense sewer cover can obstruct the preferred search offsets. Human
    // guards still inspect several *reachable* positions rather than giving
    // up when the first set of points is behind furniture.
    if(nodes.length<2){
      for(const distance of [48,85,125]){
        for(let i=0;i<8;i++){
          const a=i*Math.PI/4,x=e.x+Math.cos(a)*distance,y=e.y+Math.sin(a)*distance;
          if(walkable(game.world,x,y,e.r+3)&&nodes.every(n=>Math.hypot(n.x-x,n.y-y)>24))nodes.push({x,y});
          if(nodes.length>=3)break;
        }
        if(nodes.length>=3)break;
      }
    }
    e.searchTime=e.type==='pentagon'?14:e.type==='trapezoid'?11:4.5;
  }
  e.searchNodes=nodes;e.searchIndex=0;e.state='search';e.alertTime=0;
}
function updateEnemies(dt){
  const p=game.player,world=game.world;
  // All enemies keep simulating; collision neighbors use a local spatial index.
  const separationGrid=new Map(),cellSize=96;
  for(const actor of game.enemies){
    const key=`${Math.floor(actor.x/cellSize)},${Math.floor(actor.y/cellSize)}`;
    if(!separationGrid.has(key))separationGrid.set(key,[]);
    separationGrid.get(key).push(actor);
  }
  for(const e of game.enemies){
    const dist=Math.max(1,Math.hypot(p.x-e.x,p.y-e.y));
    recordAlert(e);
    e.flash=Math.max(0,e.flash-dt);e.contact=Math.max(0,e.contact-dt);
    e.cool-=dt;e.charge-=dt;e.dashTime=Math.max(0,e.dashTime-dt);
    e.step+=dt*(e.type==='diamond'?8:2.4);
    // All enemies stay simulated for accurate full-floor radar tracking.
    if(!e.route)initializeBehavior(e);
    e.perceptionClock-=dt;
    if(e.perceptionClock<=0||(e.type==='circle'&&(e.state==='alert'||e.hadSight))){
      e.perceptionClock=rand(.13,.24);
      e.sees=canSpot(world,e,p);
      if(e.sees&&dist<e.r+p.r+33)alertEnemy(e,p.x,p.y,5.5,'alert');
    }
    // Zombies never retain supernatural knowledge of a player behind a wall.
    const alarm=!!game.extraction;
    if(!alarm&&e.hadSight&&!e.sees&&e.state==='alert'){
      if(e.type==='circle')forgetWanderer(e);
      else prepareSearch(e);
    }
    e.hadSight=!!e.sees;
    e.suspicion=clamp((e.suspicion||0)+(e.sees?dt*(p.sneaking?.65:5.4):-dt*(e.type==='circle'?1.8:.9)),0,1);
    if(e.sees&&e.suspicion>=1)alertEnemy(e,p.x,p.y,e.type==='circle'?1.0:6.0,'alert');
    else if(e.sees&&e.suspicion>.35&&e.state==='idle')e.state='suspicious';
    if(e.state==='suspicious'&&!e.sees&&e.suspicion<.1)e.state='idle';
    if(e.sees&&e.state==='alert'){e.lastKnown={x:p.x,y:p.y};game.detectedThisFloor=true;}
    let target=null,look=null,speed=e.spd;
    if(e.state==='alert'){
      if(alarm){target={x:p.x,y:p.y};look=Math.atan2(p.y-e.y,p.x-e.x);}
      else if(!e.sees&&e.type==='circle')forgetWanderer(e);
      else if(e.sees){target={x:p.x,y:p.y};look=Math.atan2(p.y-e.y,p.x-e.x);}
      else if(e.type==='square'||e.type==='trapezoid'||e.type==='pentagon'||e.type==='diamond'){
        prepareSearch(e);
      }
    }
    if(e.state==='investigate'){
      if(e.lastKnown){target=e.lastKnown;look=Math.atan2(target.y-e.y,target.x-e.x);}
      if(!target||Math.hypot(e.x-target.x,e.y-target.y)<30||e.alertTime<=0){
        prepareSearch(e);target=null;
      }else e.alertTime=Math.max(0,e.alertTime-dt);
    }
    if(e.state==='search'){
      e.searchTime-=dt;
      if(e.searchTime<=0||e.searchIndex>=e.searchNodes.length){
        e.state='idle';e.lastKnown=null;e.alertTime=0;
        e.searchNodes=[];e.searchIndex=0;e.patrol=e.route[e.routeIndex];
        e.stareClock=e.type==='square'?.5:1.4;
      }else{
        target=e.searchNodes[e.searchIndex];
        if(Math.hypot(target.x-e.x,target.y-e.y)<32){
          e.searchIndex++;
          target=e.searchNodes[e.searchIndex]||null;
        }
        if(target)look=Math.atan2(target.y-e.y,target.x-e.x);
      }
    }
    if(!target){
      const idle=patrolIntent(e,dt);target=idle.target;speed=idle.speed;look=idle.look;
    }
    // Pursuit is a distinct gait, markedly faster than wandering/patrol.
    if(e.state==='alert'&&(e.sees||alarm)&&(e.type==='circle'||e.type==='square'))speed*=e.type==='circle'?2.25:1.68;
    const cover=rangedCoverIntent(e,dt);
    if(cover){target=cover;speed=e.spd*.85;}
    const nav=navigationPoint(world,e,target);
    let dx=nav.x-e.x,dy=nav.y-e.y;
    const len=Math.hypot(dx,dy),bearing=Math.atan2(dy,dx);
    const pdx=(p.x-e.x)/dist,pdy=(p.y-e.y)/dist;
    let mx=0,my=0;
    if(len>14){mx=dx/len;my=dy/len;}
    if(e.state==='alert'&&e.sees){
      if(e.type==='diamond'){
        mx=pdx+Math.cos(e.step)*.68;my=pdy+Math.sin(e.step)*.68;
        if(e.charge<=0&&dist<530){e.dashTime=.30;e.dashX=pdx;e.dashY=pdy;e.charge=rand(2.0,3.1);burst(e.x,e.y,C.purple,9);}
        if(e.dashTime>0){mx=e.dashX;my=e.dashY;speed*=3.4;}
      }else if(e.type==='trapezoid'||e.type==='pentagon'){
        const preferred=e.type==='pentagon'?260:300;
        if(!cover&&dist<preferred-40){mx=-pdx;my=-pdy;speed*=.6;}
        else if(!cover&&dist<preferred+60){mx=-pdy*e.orbit;my=pdx*e.orbit;speed*=.72;}
      }
    }
    const face=e.sees&&e.state==='alert'?Math.atan2(pdy,pdx):speed>0&&len>14?bearing:look??bearing;
    e.angle=turnToward(e.angle,face,VISION[e.type].turn*dt);
    if(e.sees&&e.state==='alert'&&e.cool<=0&&dist<(e.type==='pentagon'?780:740)
      &&Math.abs(angleDifference(Math.atan2(pdy,pdx),e.angle))<.24&&canSpot(world,e,p)){
      if(e.type==='trapezoid'||e.type==='pentagon'){
        shootEnemy(e,e.angle);
        e.cool=guardFireCooldown(e)*rand(.83,1.17)/Math.min(1.65,1+(game.floor-1)*.03);
      }
    }
    const mag=Math.hypot(mx,my)||1;
    const ox=e.x,oy=e.y;
    if(speed>0)moveWithCollisions(e,mx/mag*speed*dt,my/mag*speed*dt,e.r+1);
    if(speed>0&&Math.hypot(e.x-ox,e.y-oy)<speed*dt*.16&&Math.hypot(mx,my)>.1){
      const tx=-my*e.orbit,ty=mx*e.orbit;
      moveWithCollisions(e,tx*speed*dt,ty*speed*dt,e.r+1);
      if(Math.hypot(e.x-ox,e.y-oy)<speed*dt*.16)e.orbit*=-1;
    }
    e.footClock=(e.footClock||0)-dt;
    if(Math.hypot(e.x-ox,e.y-oy)>1&&dist<460&&e.footClock<=0&&(game.enemyFootBudget||0)<=0){
      enemyFootstep(e.type,1-dist/620);e.footClock=e.type==='circle'?.85:e.type==='square'?.62:.47;game.enemyFootBudget=.18;
    }
    const currentRoom=roomAt(world,e.x,e.y);if(currentRoom)e.room=currentRoom.id;
    const knifeReach=e.type==='diamond'?31:5;
    const facingHit=e.type!=='diamond'||(e.state==='alert'&&Math.abs(angleDifference(Math.atan2(p.y-e.y,p.x-e.x),e.angle))<.78&&clearSight(world,e.x,e.y,p.x,p.y));
    if(dist<e.r+p.r+knifeReach&&e.contact<=0&&facingHit){
      playerDamage(TYPE[e.type].damage);e.contact=e.type==='diamond'?.95:.68;
      if(e.type==='diamond')melee('knife',false);
      alertEnemy(e,p.x,p.y,6.2);
    }
    // Separate only from actors in nearby grid cells, not the whole floor.
    const gx=Math.floor(e.x/cellSize),gy=Math.floor(e.y/cellSize);
    for(let yy=gy-1;yy<=gy+1;yy++)for(let xx=gx-1;xx<=gx+1;xx++){
      const nearby=separationGrid.get(`${xx},${yy}`);
      if(!nearby)continue;
      for(const o of nearby)if(o!==e&&Math.abs(o.x-e.x)<75&&Math.abs(o.y-e.y)<75){
        const sep=Math.hypot(e.x-o.x,e.y-o.y),required=e.r+o.r+6;
        if(sep>1&&sep<required){
          const nx=e.x+(e.x-o.x)/sep*Math.min(4,required-sep),ny=e.y+(e.y-o.y)/sep*Math.min(4,required-sep);
          if(walkable(world,nx,ny,e.r+1)){e.x=nx;e.y=ny;}
        }
      }
    }
  }
}
function updateBullets(dt){
  const remain=[];
  for(const b of game.bullets){
    b.life-=dt;if(b.life<=0)continue;
    const startX=b.x,startY=b.y;
    const steps=Math.max(1,Math.ceil(Math.hypot(b.vx*dt,b.vy*dt)/16));
    let destroyed=false;
    for(let step=0;step<steps&&!destroyed;step++){
      b.px=b.x;b.py=b.y;b.x+=b.vx*dt/steps;b.y+=b.vy*dt/steps;
      const furniture=propAt(game.world,b.x,b.y,b.r*.45);
      if(furniture){damageFurniture(furniture,b.damage,b.x,b.y);destroyed=true;break;}
      if(!walkable(game.world,b.x,b.y,b.r*.45)){burst(b.x,b.y,b.color,2,.18);destroyed=true;break;}
      if(b.source==='enemy'){
        const p=game.player;
        if(Math.hypot(b.x-p.x,b.y-p.y)<p.r+b.r){playerDamage(b.damage);burst(b.x,b.y,b.color,4);destroyed=true;}
      }else{
        if(game.mode==='PORT')for(const actor of game.world.actors){
          if(actor.down||b.hitIds.has(actor.id))continue;
          if(Math.hypot(b.x-actor.x,b.y-actor.y)<actor.r+b.r){
            b.hitIds.add(actor.id);damagePortActor(actor,b.damage);
            if(b.pierce>0)b.pierce--;else destroyed=true;
            break;
          }
        }
        if(destroyed)break;
        for(const e of game.enemies){
          if(b.hitIds.has(e.id))continue;
          if(Math.hypot(b.x-e.x,b.y-e.y)<e.r+b.r){
            b.hitIds.add(e.id);e.hp-=b.damage;e.flash=.14;
            alertEnemy(e,game.player.x,game.player.y,6.5);
            burst(b.x,b.y,e.type==='circle'?C.red:TYPE[e.type].color,3,.4);
            if(e.hp<=0)killEnemy(e);
            if(b.pierce>0)b.pierce--;
            else destroyed=true;
            break;
          }
        }
      }
    }
    if(!destroyed)remain.push(b);
  }
  game.bullets=remain;
}
function killEnemy(e){
  const i=game.enemies.indexOf(e);if(i<0)return;
  recordAlert(e);
  game.enemies.splice(i,1);
  const room=game.world.rooms[e.homeRoom];
  room.enemies=room.enemies.filter(o=>o!==e);
  game.kills++;burst(e.x,e.y,TYPE[e.type].color,e.type==='pentagon'?23:10);
  playSound('kill');
  const reward=Math.round(TYPE[e.type].credits*(1+(game.floor-1)*.12));
  credit(reward);floating(`+${reward} CR`,e.x,e.y,C.gold);
  // Creatures award credits only; physical supplies come from furniture/chests.
  // Architectural rooms do not become safe when their original spawns die.
  // Every enemy remains free to move through the whole floor.
  if(!game.enemies.length&&!game.floorClearPaid){
    for(const r of game.world.rooms)r.cleared=true;
    game.floorClearPaid=true;const bonus=floorClearAward(game.floor,game.world.rooms.length);
    credit(bonus);announce(`ALL HOSTILES CLEARED // +${bonus} CR BONUS`,2.5);
  }
  updateUI();
}
function makePickup(kind,x,y,value){
  const pos={x:x+rand(-9,9),y:y+rand(-9,9),kind,value,life:24,bob:rand(0,TAU)};
  game.pickups.push(pos);
}
function collectPickup(pickup){
  const p=game.player;
  if(pickup.kind==='credits'){
    const amount=Math.ceil(pickup.value*p.scavenging);credit(amount);
    floating(`+${amount} CR`,pickup.x,pickup.y,C.gold);
  }else if(pickup.kind==='med'){
    if(p.medkits>=MAX_REPAIR_KITS)return false;
    p.medkits++;floating('+1 REPAIR KIT',pickup.x,pickup.y,C.green);
  }else if(pickup.kind==='chest'){
    credit(4+game.floor*2);floating('RARE CREDIT CACHE',pickup.x,pickup.y,C.gold);
  }else if(pickup.kind==='equipment'){
    if(!p.map)p.map=true;else p.spares.push('armor1');
    floating('RARE EQUIPMENT',pickup.x,pickup.y,C.cyan);
  }else if(pickup.kind==='weapon'){
    const pool=['knife','revolver','auto_pistol','shotgun','ar'].filter(w=>w!==p.weapon);
    if(p.weapon!=='hands')p.spares.push(p.weapon);
    p.weapon=pool[Math.floor(Math.random()*pool.length)]||'auto_pistol';
    p.magazines??=initialMagazines();p.magazines[p.weapon]=WEAPONS[p.weapon].magazine??0;
    p.reloadClock=0;p.reloadWeapon=null;p.reloadShells=0;p.reloadStage=null;
    p.pumpClock=0;p.pumpNeeded=false;inputs.shotgunTriggerHeld=false;inputs.shotgunPendingPresses=0;
    announce(`RARE WEAPON FOUND  //  ${WEAPONS[p.weapon].label}`,3.2);playSound('rare');
  }
  if(pickup.kind!=='weapon')playSound('pickup');
  burst(pickup.x,pickup.y,pickup.kind==='credits'?C.gold:pickup.kind==='med'?C.green:C.purple,10);
  updateUI();return true;
}
function updatePickups(dt){
  const p=game.player;
  for(const room of game.world.rooms)if(room.visited)for(const c of room.caches)if(!c.opened&&Math.hypot(p.x-c.x,p.y-c.y)<28){
    c.opened=true;
    makePickup(c.kind,c.x,c.y,c.kind==='credits'?c.value:1);
    burst(c.x,c.y,C.gold,9);playSound('pickup');
  }
  for(let i=game.pickups.length-1;i>=0;i--){
    const v=game.pickups[i];v.life-=dt;v.bob+=dt*4;
    if(v.life<=0){game.pickups.splice(i,1);continue;}
    const dist=Math.hypot(p.x-v.x,p.y-v.y);
    if(dist<70){v.x+=(p.x-v.x)*dt*3.5;v.y+=(p.y-v.y)*dt*3.5;}
    if(dist<25){if(collectPickup(v))game.pickups.splice(i,1);}
  }
}
function particle(x,y,color,speed=140,life=rand(.22,.60)){
 const a=rand(0,TAU),m=typeof speed==='number'?speed:140;
 game.particles.push({x,y,vx:Math.cos(a)*rand(m*.4,m),vy:Math.sin(a)*rand(m*.4,m),life,full:life,color,r:rand(1.5,4)});
 if(game.particles.length>320)game.particles.splice(0,game.particles.length-320);
}
function burst(x,y,color,count=8,mult=1){for(let i=0;i<count;i++)particle(x,y,color,rand(60,260)*mult,rand(.18,.7));}
function floating(text,x,y,color){game.particles.push({x,y,vx:0,vy:-45,life:1.0,full:1.0,color,text,r:0});}
function updateParticles(dt){for(let i=game.particles.length-1;i>=0;i--){const p=game.particles[i];p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vx*=Math.pow(.94,dt*60);p.vy*=Math.pow(.94,dt*60);if(p.life<=0)game.particles.splice(i,1);}}
function update(dt){
  if(game.mode==='PLAY')game.time+=dt;
  game.enemyFootBudget=Math.max(0,(game.enemyFootBudget||0)-dt);
  if(toastTimeout>0){toastTimeout-=dt;if(toastTimeout<=0)show('toast',false);}
  game.shake=Math.max(0,game.shake-dt*40);game.flashed=Math.max(0,game.flashed-dt);
  if(game.mode==='PORT'){updatePort(dt);return;}
  if(game.mode==='HQ'){
    if(!game.world?.isHQ)return;
    const p=game.player,control=captureInputs();
    moveWithCollisions(p,control.mx*p.speed*dt,control.my*p.speed*dt,p.r);
    p.walkCycle+=Math.hypot(control.mx,control.my)*dt*12;
    if(Math.hypot(control.mx,control.my)>.35){
      p.facing=Math.atan2(control.my,control.mx);p.stepClock+=dt;
      if(p.stepClock>.42){p.stepClock=0;step(false,(p.footSide=(p.footSide||0)^1));}
    }else p.stepClock=0;
    camera.x+=(p.x-camera.x)*Math.min(1,dt*8);
    camera.y+=(p.y-camera.y)*Math.min(1,dt*8);
    updateHQPrompt();return;
  }
  if(game.mode!=='PLAY'||!game.world)return;
  const p=game.player,control=captureInputs();
  p.invuln=Math.max(0,p.invuln-dt);p.cool=Math.max(0,p.cool-dt);updateWeaponTimers(dt);
  if(p.reloadClock>0){p.reloadHUDClock=(p.reloadHUDClock||0)+dt;
    if(p.reloadHUDClock>.22){p.reloadHUDClock=0;updateUI();}}
  const moveMag=Math.hypot(control.mx,control.my);
  moveWithCollisions(p,control.mx*p.speed*(p.sneaking?.56:1)*dt,control.my*p.speed*(p.sneaking?.56:1)*dt,p.r);
  p.punchTimer=Math.max(0,p.punchTimer-dt);
  if(moveMag>.3){p.stepClock+=dt;if(p.stepClock>(p.sneaking?.53:.35)){p.stepClock=0;p.footSide=(p.footSide||0)^1;step(p.sneaking,p.footSide);if(!p.sneaking)emitNoise(p.x,p.y,1.12);}}else p.stepClock=Math.min(p.stepClock,.20);
  p.moving=moveMag>.3;p.walkCycle+=moveMag*dt*12;
  if(Math.hypot(control.ax,control.ay)>.01)p.facing=Math.atan2(control.ay,control.ax);
  // Shotgun actions are edge-triggered: hold-to-fire cannot silently auto-pump.
  // The right stick must recenter before the next fire/pump action.
  // Pointer/keyboard events are queued so rapid clicks between render frames
  // are not lost. Sticks/gamepads also generate their own rising edges.
  const queuedPress=inputs.shotgunPendingPresses>0&&p.weaponDrawn!==false;
  if(queuedPress)inputs.shotgunPendingPresses--;
  const triggerPress=queuedPress||(control.shoot&&!inputs.shotgunTriggerHeld);
  inputs.shotgunTriggerHeld=control.shoot;
  if(p.weapon==='shotgun'){
    if(triggerPress&&(p.cool<=0||p.pumpNeeded))shootPlayer(p.facing);
  }else if(control.shoot&&p.cool<=0)shootPlayer(p.facing);
  // Room discovery affects HUD/map only. No doors, spawns, or collisions.
  const room=roomAt(game.world,p.x,p.y);
  if(room&&room.id!==game.activeRoom)enterRoom(room);
  if(updateExtraction(dt))return;
  updateEnemies(dt);updateBullets(dt);updatePickups(dt);updateParticles(dt);
  if(game.mode!=='PLAY')return;
  game.monsterSoundClock-=dt;
  if(game.monsterSoundClock<=0){
    const nearby=game.enemies.filter(e=>Math.hypot(e.x-p.x,e.y-p.y)<720);
    if(nearby.length){const e=nearby[Math.floor(Math.random()*nearby.length)];monsterSound(e.type,1-Math.hypot(e.x-p.x,e.y-p.y)/1000);}
    game.monsterSoundClock=3.8+Math.random()*5.5;
  }
  const exit=game.world.rooms[game.world.exit];
  if(!game.extraction&&Math.hypot(p.x-exit.cx,p.y-exit.cy)<56){
    game.exitClock+=dt;if(game.exitClock>.75)nextFloor();
  }else game.exitClock=0;
  const smooth=Math.min(1,dt*8);camera.x+=(p.x-camera.x)*smooth;camera.y+=(p.y-camera.y)*smooth;
}

function resetDrawing(){ctx.setTransform(DPR,0,0,DPR,0,0);ctx.clearRect(0,0,SW,SH);}
function line(x1,y1,x2,y2,color,width=2,blur=0){
  ctx.strokeStyle=color;ctx.lineWidth=width;ctx.shadowColor=color;ctx.shadowBlur=blur;
  ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.shadowBlur=0;
}
function path(points,fill,stroke,width=2,blur=0){
  ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();
  ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=width;ctx.shadowBlur=blur;ctx.shadowColor=stroke;ctx.stroke();ctx.shadowBlur=0;}
}
function glowCircle(x,y,r,color,fill='#0b2236',width=2,blur=12){ctx.beginPath();ctx.arc(x,y,r,0,TAU);ctx.fillStyle=fill;ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.shadowColor=color;ctx.shadowBlur=blur;ctx.stroke();ctx.shadowBlur=0;}
function drawBackground(){
  ctx.fillStyle='#050b14';ctx.fillRect(0,0,SW,SH);
  const time=performance.now()/1000;
  for(let i=0;i<68;i++){
    const x=((i*239.73+Math.sin(i)*172+time*(i%3+1)*.4)%SW+SW)%SW;
    const y=((i*417.21+Math.cos(i*11)*300)%SH+SH)%SH;
    ctx.fillStyle=`rgba(56,157,185,${.11+(i%5)*.03})`;ctx.fillRect(x,y,i%7===0?2:1,i%7===0?2:1);
  }
}
function drawCorridors(){
  const w=game.world,edge=w.stratum.edge;
  // Render a true architectural UNION: touching chambers blend seamlessly;
  // only the outside perimeter carries walls. Internal open edges disappear.
  const viewX=SW/(zoom*2)+110,viewY=SH/(zoom*2)+110;
  for(const s of w.shapes){
    if(s.maxX<camera.x-viewX||s.minX>camera.x+viewX||s.maxY<camera.y-viewY||s.minY>camera.y+viewY)continue;
    ctx.fillStyle=w.stratum.color;ctx.fillRect(s.x,s.y,s.w,s.h);
  }
  ctx.save();ctx.lineCap='square';ctx.lineJoin='miter';
  ctx.strokeStyle=edge;ctx.lineWidth=7;ctx.shadowColor=edge;ctx.shadowBlur=12;
  ctx.beginPath();
  for(const wall of w.walls){
    if(Math.max(wall.x1,wall.x2)<camera.x-viewX||Math.min(wall.x1,wall.x2)>camera.x+viewX||Math.max(wall.y1,wall.y2)<camera.y-viewY||Math.min(wall.y1,wall.y2)>camera.y+viewY)continue;
    ctx.moveTo(wall.x1,wall.y1);ctx.lineTo(wall.x2,wall.y2);
  }
  ctx.stroke();ctx.restore();
}
function drawRoom(room){
  const x=room.cx,y=room.cy,style=room.tileset;
  const kit=TILESETS[style];
  // Themed TILE MODULES sit inside the union of all chamber footprints.
  // Module outlines do not reintroduce walls where two rooms merge.
  ctx.save();ctx.globalAlpha=.36;
  const ink=kit.trim;
  if(style==='sewers'){
    // Storm drains, running channels and segmented pipe ducts.
    const laneY=y+(room.module==='elbow'?-room.h*.15:room.h*.16);
    line(room.x+42,laneY,room.x+room.w-42,laneY,ink,2);
    line(room.x+42,laneY+12,room.x+room.w-42,laneY+12,ink,1);
    for(let d=56;d<room.w-45;d+=82)line(room.x+d,laneY,room.x+d+16,laneY+12,ink,1);
  }else if(style==='foundations'){
    for(let d=65;d<room.w-35;d+=120)line(room.x+d,room.y+26,room.x+d-26,room.y+53,ink,2);
    line(room.x+28,room.y+75,room.x+room.w-28,room.y+75,ink,1);
  }else if(style==='dig'){
    for(let d=55;d<room.w-45;d+=118){line(room.x+d,room.y+40,room.x+d+28,room.y+40,ink,3);line(room.x+d+14,room.y+28,room.x+d+14,room.y+52,ink,1);}
  }else if(style==='ruins'){
    ctx.strokeStyle=ink;ctx.lineWidth=1.5;ctx.strokeRect(x-room.w*.17,y-room.h*.19,room.w*.34,room.h*.38);
    line(x-room.w*.17,y,x+room.w*.17,y,ink,1);
  }else if(style==='hq'){
    for(let d=36;d<room.w-25;d+=80){
      ctx.fillStyle='#336579';ctx.fillRect(room.x+d,room.y+24,32,6);
      ctx.strokeStyle='#368f95';ctx.strokeRect(room.x+d,room.y+room.h-32,30,5);
    }
    line(room.x+30,room.y+85,room.x+room.w-30,room.y+85,ink,1);
    line(room.x+30,room.y+room.h-85,room.x+room.w-30,room.y+room.h-85,ink,1);
  }else{
    const spacing=100;
    for(let d=50;d<room.w-32;d+=spacing){ctx.fillStyle=ink;ctx.fillRect(room.x+d,room.y+27,37,5);}
    line(room.x+38,room.y+83,room.x+room.w-38,room.y+83,ink,1);
  }
  ctx.restore();
  ctx.textAlign='center';ctx.font='700 12px ui-monospace,monospace';
  ctx.fillStyle=room.visited?'#668d9a':'#42616d';
  ctx.fillText(room.tileset==='hq'?room.module.toUpperCase():`${room.module.toUpperCase()} ${String(room.id+1).padStart(2,'0')}`,x,y-room.h*.30);
  for(const o of room.cover){
    if(o.hp<=0)continue;
    const px=o.x-o.w/2,py=o.y-o.h/2;
    const casing=style==='sewers'?'#0f3439':style==='security'?'#173846':'#292b39';
    ctx.save();ctx.fillStyle=casing;ctx.strokeStyle=ink;ctx.lineWidth=2.5;
    ctx.shadowColor=ink;ctx.shadowBlur=5;
    ctx.fillRect(px,py,o.w,o.h);ctx.strokeRect(px,py,o.w,o.h);ctx.shadowBlur=0;
    const f=o.kind;
    if(f==='interior wall'){
      ctx.fillStyle='#101d29';ctx.fillRect(px,py,o.w,o.h);
      ctx.strokeStyle=ink;ctx.lineWidth=2;ctx.strokeRect(px,py,o.w,o.h);
      if(o.w>o.h)line(px+8,o.y,px+o.w-8,o.y,ink,1);
      else line(o.x,py+8,o.x,py+o.h-8,ink,1);
    }else if(f==='rusted drum'||f==='valve'||f==='artifact plinth'){
      ctx.beginPath();ctx.ellipse(o.x,o.y,o.w*.30,o.h*.29,0,0,TAU);ctx.stroke();
      line(o.x-7,o.y,o.x+7,o.y,ink,1);
    }else if(f==='console'||f==='display case'){
      ctx.strokeRect(px+7,py+6,o.w-14,o.h*.34);
      ctx.fillStyle=ink;ctx.fillRect(px+9,py+o.h*.66,5,4);
    }else if(f==='pipe rack'||f==='scaffold'||f==='excavation bench'){
      for(let i=0;i<3;i++)line(px+7,py+9+i*(o.h-18)/2,px+o.w-7,py+9+i*(o.h-18)/2,ink,1.7);
    }else{
      line(px+7,py+7,px+o.w-7,py+o.h-7,ink,1.5);
      line(px+o.w-7,py+7,px+7,py+o.h-7,ink,1.5);
    }
    // A chipped edge visually communicates damage taken.
    if(o.hp<o.maxHp){ctx.strokeStyle='#efba7a';line(px+5,py+4,px+12,py+11,'#efba7a',2);}
    ctx.restore();
  }
  for(const chest of room.caches)if(!chest.opened){
    ctx.globalAlpha=.76+Math.sin(now*2+chest.x)*.2;
    path([[chest.x-15,chest.y-11],[chest.x+15,chest.y-11],[chest.x+15,chest.y+11],[chest.x-15,chest.y+11]],'#483921',C.gold,3,14);
    line(chest.x-7,chest.y,chest.x+7,chest.y,C.gold,2);ctx.globalAlpha=1;
  }
  if(room.exit){
    const pulse=Math.sin(now*3)*5;
    glowCircle(x,y,47+pulse,C.green,'#122e35',4,22);
    glowCircle(x,y,29,C.cyan,'#071827',3,12);
    ctx.fillStyle='#abffdc';ctx.font='900 15px ui-monospace,monospace';ctx.fillText('UP',x,y+5);
    ctx.font='700 12px ui-monospace,monospace';ctx.fillText('STAIRS / NEXT SECTOR',x,y+84);
  }
  if(room.exfil){
    const pulse=Math.sin(now*3)*4;
    const active=game.extraction?.room===room.id;
    ctx.save();ctx.setLineDash([10,7]);
    glowCircle(x,y,EXTRACTION.holdRadius,active?C.red:C.gold,'#27271d33',active?4:2,8);
    ctx.restore();
    glowCircle(x,y,41+pulse,C.gold,'#27271d',3,18);
    ctx.fillStyle=C.gold;ctx.font='900 14px ui-monospace,monospace';ctx.fillText(active?`${game.extraction.remaining}s`:'EXFIL',x,y+4);
    ctx.font='700 12px ui-monospace,monospace';ctx.fillText(active?'HOLD THE RING // ALL HOSTILES ALERT':'ENTER MARKER // HOLD 8s TO EXFIL',x,y+132);
  }
}
function drawPortStructureFloors(){
  if(!game.world?.isSpaceport)return;
  for(const venue of game.world.structures||[]){
    ctx.save();ctx.fillStyle='#07141dcc';ctx.fillRect(venue.x+12,venue.y+12,venue.w-24,venue.h-24);
    ctx.strokeStyle=venue.color;ctx.lineWidth=1.5;ctx.setLineDash([8,7]);ctx.globalAlpha=.5;ctx.strokeRect(venue.x+14,venue.y+14,venue.w-28,venue.h-28);ctx.setLineDash([]);
    ctx.globalAlpha=1;ctx.fillStyle=venue.color;ctx.textAlign='center';ctx.font='900 14px ui-monospace,monospace';ctx.fillText(venue.name,venue.x+venue.w/2,venue.y+38);
    ctx.font='700 10px ui-monospace,monospace';ctx.fillText(`${venue.kind.toUpperCase()} · PUBLIC INTERIOR`,venue.x+venue.w/2,venue.y+56);ctx.restore();
  }
}
function drawHQStations(){
  const p=game.player;
  for(const station of game.world.stations){
    const distanceToPlayer=Math.hypot(p.x-station.x,p.y-station.y),near=distanceToPlayer<91;
    if(station.hidden&&!station.discovered){
      if(distanceToPlayer>250)continue;
      ctx.save();ctx.translate(station.x,station.y);ctx.globalAlpha=.22+.16*Math.sin(now*5+station.x);
      ctx.fillStyle=station.color;ctx.shadowColor=station.color;ctx.shadowBlur=9;ctx.fillRect(-5,-9,10,18);ctx.restore();continue;
    }
    ctx.save();ctx.translate(station.x,station.y);
    const pulse=2*Math.sin(now*2.9+station.y);
    ctx.strokeStyle=station.color;ctx.lineWidth=near?4:2.5;
    ctx.shadowColor=station.color;ctx.shadowBlur=near?22:9;
    ctx.strokeRect(-45-pulse/2,-32-pulse/2,90+pulse,64+pulse);ctx.shadowBlur=0;
    ctx.fillStyle='#0b2731';ctx.fillRect(-36,-24,72,48);
    ctx.fillStyle=station.color;ctx.textAlign='center';ctx.font='900 15px ui-monospace,monospace';
    ctx.fillText(station.short||({shop:'BUY',storage:'STASH',deploy:'DEPLOY',medical:'MED'})[station.id]||station.id.toUpperCase(),0,5);
    ctx.font='700 11px ui-monospace,monospace';ctx.fillText(station.label,0,64);
    if(near){ctx.fillStyle='#f0ffff';ctx.fillText('PRESS E / INTERACT',0,85);}
    ctx.restore();
  }
  if(game.world.isSpaceport)return;
  // Signage visible from HQ's central spawn points toward every facility.
  const signs=[[-170,0,'◀ STORAGE',C.green],[175,0,'ARMORY ▶',C.gold],[0,-115,'▲ DEPLOY',C.cyan],[0,138,'▼ MEDICAL','#ff88bc']];
  ctx.textAlign='center';ctx.font='900 16px ui-monospace,monospace';
  for(const [x,y,label,color] of signs){ctx.fillStyle=color;ctx.fillText(label,x,y);}
}
function drawPortActors(){
  if(!game.world?.isSpaceport)return;
  for(const actor of game.world.actors){
    if(actor.down||(actor.robbed&&actor.kind==='civilian'))continue;
    const guard=actor.kind==='guard',color=actor.flash>0?'#ffffff':guard?(actor.alert?C.red:C.cyan):C.green;actor.flash=Math.max(0,(actor.flash||0)-.025);
    ctx.save();ctx.translate(actor.x,actor.y);ctx.fillStyle=guard?'#17384c':'#163c34';ctx.strokeStyle=color;ctx.lineWidth=2.5;
    ctx.beginPath();ctx.arc(0,0,guard?16:13,0,TAU);ctx.fill();ctx.stroke();ctx.fillStyle=color;ctx.font='800 10px ui-monospace,monospace';ctx.textAlign='center';ctx.fillText(guard?'SEC':'NPC',0,4);
    if(actor.alert){ctx.fillStyle=C.red;ctx.font='900 18px ui-monospace,monospace';ctx.fillText('!',0,-24);}
    if(actor.hp<actor.maxHp){ctx.fillStyle='#241c2b';ctx.fillRect(-18,-25,36,3);ctx.fillStyle=color;ctx.fillRect(-18,-25,36*clamp(actor.hp/actor.maxHp,0,1),3);}ctx.restore();
  }
}
function drawHQDirectory(){
  const size=Math.min(144,SW*.38),x=SW-size-12,y=SW<600?20:22;
  const minX=Math.min(...game.world.rooms.map(r=>r.x))-70,minY=Math.min(...game.world.rooms.map(r=>r.y))-70;
  const maxX=Math.max(...game.world.rooms.map(r=>r.x+r.w))+70,maxY=Math.max(...game.world.rooms.map(r=>r.y+r.h))+70;
  const worldW=maxX-minX,worldH=maxY-minY,scale=(size-18)/Math.max(worldW,worldH);
  ctx.save();ctx.fillStyle='rgba(5,18,31,.91)';ctx.fillRect(x-5,y-5,size+10,size*worldH/worldW+36);
  ctx.strokeStyle='#397b88';ctx.lineWidth=1;ctx.strokeRect(x-5,y-5,size+10,size*worldH/worldW+36);
  ctx.textAlign='left';ctx.fillStyle='#75c9d7';ctx.font='800 10px ui-monospace,monospace';ctx.fillText(game.world.isSpaceport?'SPACEPORT DIRECTORY':'HQ DIRECTORY',x+2,y+9);
  const X=(wx)=>x+9+(wx-minX)*scale,Y=(wy)=>y+18+(wy-minY)*scale;
  for(const r of game.world.rooms){ctx.fillStyle='#163b4a';ctx.fillRect(X(r.x),Y(r.y),r.w*scale,r.h*scale);}
  for(const venue of game.world.structures||[]){ctx.strokeStyle=venue.color;ctx.lineWidth=1;ctx.strokeRect(X(venue.x),Y(venue.y),venue.w*scale,venue.h*scale);}
  for(const s of game.world.stations){if(s.hidden&&!s.discovered)continue;ctx.fillStyle=s.color;ctx.fillRect(X(s.x)-3,Y(s.y)-3,6,6);}
  ctx.fillStyle=C.cyan;ctx.beginPath();ctx.arc(X(game.player.x),Y(game.player.y),4.5,0,TAU);ctx.fill();ctx.restore();
}
function drawAwareness(e){
  const range=VISION[e.type].range;
  if(Math.abs(e.x-camera.x)>(SW/zoom)*.7+range||Math.abs(e.y-camera.y)>(SH/zoom)*.7+range)return;
  // Idle guards project a subdued forward detection arc. Hostile units get
  // a bright alert ring. Cover physically blocks spotting, not just graphics.
  if(e.type==='trapezoid'||e.type==='pentagon'||e.type==='diamond'){
    const span=VISION[e.type].halfAngle;
    const radius=Math.min(range,400);
    ctx.beginPath();ctx.moveTo(e.x,e.y);
    ctx.arc(e.x,e.y,radius,e.angle-span,e.angle+span);ctx.closePath();
    ctx.fillStyle=e.state==='alert'?'rgba(255,98,127,.07)':'rgba(92,193,236,.032)';ctx.fill();
    ctx.strokeStyle=e.state==='alert'?'rgba(255,98,127,.26)':'rgba(78,166,205,.13)';ctx.lineWidth=1;ctx.stroke();
  }
}
function drawEnemy(e){
  const t=TYPE[e.type],f=e.flash>0;
  ctx.save();ctx.translate(e.x,e.y);ctx.rotate(e.angle+Math.PI/2);
  const color=f?'#ffffff':t.color;
  if(e.type==='circle')glowCircle(0,0,e.r,color,'#412135',3,12);
  else if(e.type==='square')path([[-e.r,-e.r],[e.r,-e.r],[e.r,e.r],[-e.r,e.r]],'#3d2732',color,3,13);
  else if(e.type==='diamond')path([[0,-e.r*1.3],[e.r,0],[0,e.r*1.3],[-e.r,0]],'#30234d',color,3,18);
  else if(e.type==='trapezoid')path([[-e.r*.72,-e.r],[e.r*.72,-e.r],[e.r*1.25,e.r],[-e.r*1.25,e.r]],'#17384c',color,3,14);
  else path(Array.from({length:5},(_,i)=>[Math.cos(-Math.PI/2+i*TAU/5)*e.r,Math.sin(-Math.PI/2+i*TAU/5)*e.r]),'#493b2b',color,4,20);
  if(e.type==='trapezoid'){
    // The guard is visibly armed with the weapon actually used by the AI.
    const gun=e.weapon||'revolver';
    const length=gun==='ar'?e.r*1.9:gun==='shotgun'?e.r*1.75:e.r*1.18;
    const barrelColor=gun==='ar'?C.purple:gun==='shotgun'?C.orange:gun==='auto_pistol'?C.cyan:C.gold;
    line(-e.r*.45,-e.r*.35,-e.r*.45,-e.r*.98,color,3,8);
    line(e.r*.45,-e.r*.35,e.r*.45,-e.r*.98,color,3,8);
    line(0,-e.r*.62,0,-length,barrelColor,gun==='shotgun'?6:4,10);
    line(-5,-length*.82,5,-length*.82,barrelColor,2,5);
  }else if(e.type==='pentagon'){
    line(-e.r*.32,-e.r*.62,-e.r*.32,-e.r*1.35,color,5,12);
    line(e.r*.32,-e.r*.62,e.r*.32,-e.r*1.35,color,5,12);
  }else if(e.type==='diamond'){
    // Two visible hands, plus a real short knife in the right glove.
    const leftX=-e.r*1.12,rightX=e.r*1.12,handY=-e.r*.68;
    line(-e.r*.60,-e.r*.24,leftX,handY,color,4,9);
    line(e.r*.60,-e.r*.24,rightX,handY,color,4,9);
    glowCircle(leftX,handY,4.3,C.purple,'#39244e',2,5);
    glowCircle(rightX,handY,4.3,C.purple,'#39244e',2,5);
    line(rightX,handY-1,rightX-3,handY-e.r*.74,'#e9f9ff',3,8);
    line(rightX-3,handY-e.r*.74,rightX-3.5,handY-e.r*.90,'#ffffff',1,6);
  }else{
    // Zombie eye markings clearly establish where it is looking.
    glowCircle(-e.r*.31,-e.r*.42,3.3,'#e7feff','#e7feff',1,1);
    glowCircle(e.r*.31,-e.r*.42,3.3,'#e7feff','#e7feff',1,1);
  }
  ctx.restore();
  if(e.state==='alert'||e.state==='investigate'||e.state==='suspicious'){
    ctx.textAlign='center';ctx.font='bold 17px ui-monospace,monospace';
    ctx.fillStyle=e.state==='alert'?C.red:C.gold;
    ctx.fillText(e.state==='alert'?'!':'?',e.x,e.y-e.r-23);
  }
  if(e.hp<e.maxHp){ctx.fillStyle='#241c2b';ctx.fillRect(e.x-25,e.y-e.r-16,50,4);ctx.fillStyle=t.color;ctx.fillRect(e.x-25,e.y-e.r-16,50*clamp(e.hp/e.maxHp,0,1),4);}
}
function drawPlayer(){
  const p=game.player;if(!p)return;
  if(p.invuln>0 && Math.floor(p.invuln*13)%2===0)ctx.globalAlpha=.53;
  ctx.save();ctx.translate(p.x,p.y);ctx.rotate(p.facing+Math.PI/2);
  glowCircle(0,0,18,C.cyan,'#153b4f',3,14);
  path([[0,-23],[14,11],[0,7],[-14,11]],'#2c6275',C.cyan,2.5,12);
  if(p.weaponDrawn===false){
    glowCircle(-13,8,4,C.cyan,'#165267',1,2);glowCircle(13,8,4,C.cyan,'#165267',1,2);
  }else if(WEAPONS[p.weapon].melee){
    const swing=p.punchTimer>0?18:0;
    const left=p.weapon==='hands'&&p.swingHand===0;
    const glove=p.weapon==='knife'?C.green:C.cyan;
    glowCircle(-11,-18-(left?swing:0),5,glove,'#165267',2,5);
    glowCircle(11,-18-(!left?swing:0),5,glove,'#165267',2,5);
    if(p.weapon==='knife'){
      const handX=left?-11:11;
      line(handX,-22-(swing||0),handX*1.32,-38-(swing||0),'#d3fff1',3,8);
    }
  }else{
    const busy=p.reloadClock>0;
    const pump=p.pumpClock>0;
    const chambering=busy&&p.reloadWeapon==='shotgun'&&p.reloadStage==='rack';
    const phase=chambering?1-p.reloadClock/Math.max(.1,WEAPONS.shotgun.rackTime):busy?1-p.reloadClock/Math.max(.1,p.reloadTotal):pump?1-p.pumpClock/Math.max(.1,p.pumpTotal):0;
    const slide=chambering?Math.sin(phase*Math.PI)*12:busy?Math.sin(phase*Math.PI)*5:pump?Math.sin(phase*Math.PI)*12:0;
    line(0,-13,slide*.55,-30+slide,WEAPONS[p.weapon].color,5,12);
    if(busy){
      ctx.strokeStyle=C.gold;ctx.lineWidth=3;ctx.beginPath();ctx.arc(0,0,30,-Math.PI/2,-Math.PI/2+TAU*phase);ctx.stroke();
      glowCircle(12,-16+slide,4,C.gold,'#70513b',1,4);
      if(p.reloadWeapon==='shotgun'&&!chambering){
        // One illuminated shell marker per inserted round.
        for(let i=0;i<(p.reloadShells||0);i++)glowCircle(-18+i*7,11,2.6,C.gold,'#8f612c',1,3);
      }
      if(chambering)line(9,-16,9,-26+slide,C.orange,3,5);
    }else if(pump){line(9,-16,9,-26+slide,C.orange,3,5);}
    else if(p.weapon==='shotgun'&&p.pumpNeeded){line(9,-16,9,-25,C.orange,3,3);}
  }
  ctx.restore();ctx.globalAlpha=1;
  if(p.sneaking){ctx.strokeStyle='rgba(130,255,185,.28)';ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y,25,0,TAU);ctx.stroke();}
  ctx.strokeStyle='#4fd6ee44';ctx.lineWidth=1;ctx.beginPath();ctx.arc(p.x,p.y,29+Math.sin(now*4)*1.5,0,TAU);ctx.stroke();
}
function drawBullets(){
  for(const b of game.bullets){
    line(b.x-b.vx*.014,b.y-b.vy*.014,b.x,b.y,b.color,b.r*1.3,10);
    ctx.fillStyle=b.color;ctx.beginPath();ctx.arc(b.x,b.y,b.r,0,TAU);ctx.fill();
  }
}
function drawPickups(){
  for(const p of game.pickups){
    const color=p.kind==='credits'?C.gold:p.kind==='med'?C.green:C.purple;
    ctx.save();ctx.translate(p.x,p.y+Math.sin(p.bob)*4);
    if(p.kind==='med'){
      ctx.fillStyle='#112f2b';ctx.strokeStyle=color;ctx.lineWidth=2;ctx.shadowBlur=11;ctx.shadowColor=color;ctx.fillRect(-12,-12,24,24);ctx.strokeRect(-12,-12,24,24);ctx.shadowBlur=0;line(-7,0,7,0,color,3);line(0,-7,0,7,color,3);
    }else if(p.kind==='weapon'){
      path([[0,-16],[15,0],[0,16],[-15,0]],'#261b44',color,3,20);
    }else{
      glowCircle(0,0,9,color,'#53462a',2,12);line(-3,-1,4,-1,color,2);
    }
    ctx.restore();
  }
}
function drawParticles(){for(const p of game.particles){ctx.globalAlpha=clamp(p.life/p.full,0,1);ctx.fillStyle=p.color;if(p.text){ctx.textAlign='center';ctx.font='900 18px ui-monospace,monospace';ctx.fillText(p.text,p.x,p.y);}else{ctx.fillRect(p.x-p.r/2,p.y-p.r/2,p.r,p.r);}ctx.globalAlpha=1;}}
function drawMap(expanded=false){
  if(!game.world)return;
  const w=game.world,p=game.player,rs=w.rooms;
  const size=expanded?Math.min(SW*.86,SH*.79,630):Math.min(SW<600?137:202,SW*.40);
  const x=expanded?(SW-size)/2:SW-size-12,y=expanded?(SH-size)/2:SW<600?114:82;
  const pad=13,inner=size-pad*2;
  const minX=expanded?Math.min(...rs.map(r=>r.x))-120:p.x-960;
  const maxX=expanded?Math.max(...rs.map(r=>r.x+r.w))+120:p.x+960;
  const minY=expanded?Math.min(...rs.map(r=>r.y))-120:p.y-960;
  const maxY=expanded?Math.max(...rs.map(r=>r.y+r.h))+120:p.y+960;
  const scale=inner/Math.max(maxX-minX,maxY-minY);
  const ox=x+pad+(inner-(maxX-minX)*scale)/2,oy=y+pad+(inner-(maxY-minY)*scale)/2;
  const pos=(px,py)=>[ox+(px-minX)*scale,oy+(py-minY)*scale];
  ctx.save();
  ctx.fillStyle='rgba(3,12,23,.94)';ctx.fillRect(x-6,y-25,size+12,size+31);
  ctx.strokeStyle=w.stratum.edge;ctx.lineWidth=1.5;ctx.strokeRect(x-6,y-25,size+12,size+31);
  ctx.font=`800 ${expanded?12:10}px ui-monospace,monospace`;ctx.fillStyle='#a0e7e8';ctx.textAlign='left';
  ctx.fillText(expanded?`${w.stratum.name} · RED=HOSTILES`:'RADAR · HOSTILES',x+3,y-9);
  ctx.beginPath();ctx.rect(x,y,size,size);ctx.clip();
  for(const r of rs){const [rx,ry]=pos(r.x,r.y);
    ctx.fillStyle=r.visited?'#14394b':'#102331';ctx.fillRect(rx,ry,r.w*scale,r.h*scale);
  }
  ctx.strokeStyle='#507989';ctx.lineWidth=expanded?2:1.2;ctx.beginPath();
  for(const e of w.walls){const [ax,ay]=pos(e.x1,e.y1),[bx,by]=pos(e.x2,e.y2);ctx.moveTo(ax,ay);ctx.lineTo(bx,by);}
  ctx.stroke();
  const exit=rs[w.exit],ex=pos(exit.cx,exit.cy);
  ctx.strokeStyle=C.green;ctx.lineWidth=2;ctx.beginPath();ctx.arc(ex[0],ex[1],expanded?7:4,0,TAU);ctx.stroke();
  if(w.exfil!=null){const r=rs[w.exfil],loc=pos(r.cx,r.cy);
    ctx.strokeStyle=C.gold;ctx.lineWidth=2;ctx.strokeRect(loc[0]-5,loc[1]-5,10,10);
  }
  // Enemy positions are ALWAYS shown, even when unalerted, so players can
  // plan stealth routes without having to enter a hostile line of sight.
  for(const e of game.enemies){
    const [mx,my]=pos(e.x,e.y);
    if(mx<x-3||my<y-3||mx>x+size+3||my>y+size+3)continue;
    const r=expanded?3.8:3.1;
    ctx.fillStyle=TYPE[e.type].color;
    ctx.beginPath();ctx.arc(mx,my,r,0,TAU);ctx.fill();
    if(true){
      ctx.strokeStyle=e.state==='alert'?C.red:'rgba(255,255,255,.63)';ctx.lineWidth=1;
      ctx.beginPath();ctx.moveTo(mx,my);
      ctx.lineTo(mx+Math.cos(e.angle)*r*2.7,my+Math.sin(e.angle)*r*2.7);ctx.stroke();
    }
  }
  const [px,py]=pos(p.x,p.y);
  ctx.fillStyle=C.cyan;ctx.beginPath();ctx.arc(px,py,expanded?6:5,0,TAU);ctx.fill();
  ctx.strokeStyle='#e4ffff';ctx.lineWidth=2;
  ctx.beginPath();ctx.moveTo(px,py);ctx.lineTo(px+Math.cos(p.facing)*13,py+Math.sin(p.facing)*13);ctx.stroke();
  ctx.restore();
}
function render(){
  resetDrawing();drawBackground();
  if(!game.world)return;
  ctx.save();
  const shakeX=game.shake?rand(-game.shake,game.shake):0,shakeY=game.shake?rand(-game.shake,game.shake):0;
  ctx.translate(SW/2+shakeX,SH/2+shakeY);ctx.scale(zoom,zoom);ctx.translate(-camera.x,-camera.y);
  drawCorridors();
  drawPortStructureFloors();
  for(const room of game.world.rooms){
    const sx=(room.x-camera.x)*zoom+SW/2,sy=(room.y-camera.y)*zoom+SH/2;
    if(sx>SW+300||sy>SH+300||sx+room.w*zoom< -300||sy+room.h*zoom < -300)continue;
    drawRoom(room);
  }
  if(game.world.isHQ){drawHQStations();drawPortActors();}
  else drawPickups();
  const visibleEnemies=game.enemies.filter(e=>Math.abs(e.x-camera.x)<SW/(zoom*2)+350&&Math.abs(e.y-camera.y)<SH/(zoom*2)+350);
  for(const e of visibleEnemies)drawAwareness(e);
  for(const e of visibleEnemies)drawEnemy(e);
  drawBullets();drawPlayer();drawParticles();
  ctx.restore();
  if(game.world.isHQ)drawHQDirectory();
  else if(game.player?.map)drawMap(inputs.map);
  if(game.flashed>0){ctx.fillStyle=`rgba(255,43,107,${game.flashed*.42})`;ctx.fillRect(0,0,SW,SH);}
  if(inputs.map&&game.player?.map&&game.mode==='PLAY'){ctx.font='800 12px ui-monospace,monospace';ctx.textAlign='center';ctx.fillStyle='#90dce5';ctx.fillText('PRESS M TO CLOSE · FIELD RADAR ACTIVE',SW/2,SH*.87);}
  // Low health atmospheric warning, without hiding gameplay.
  if(game.player.hp/game.player.maxHp<=.3){ctx.strokeStyle=`rgba(250,70,105,${.12+Math.sin(now*5)*.08})`;ctx.lineWidth=18;ctx.strokeRect(0,0,SW,SH);}
}
function frame(ts){
  const dt=Math.min((ts-lastFrame)/1000||0,.034);lastFrame=ts;now=ts/1000;
  update(dt);render();requestAnimationFrame(frame);
}

function attachStick(element,target){
  let pointer=null;
  const knob=element.querySelector('.stick-knob');
  function move(e){
    const rect=element.querySelector('.stick-base').getBoundingClientRect();
    const cx=rect.left+rect.width/2,cy=rect.top+rect.height/2;
    const dx=e.clientX-cx,dy=e.clientY-cy,len=Math.hypot(dx,dy),max=43;
    const vx=len<7?0:dx/Math.max(len,max),vy=len<7?0:dy/Math.max(len,max);
    inputs[target]={x:vx,y:vy};knob.style.transform=`translate(${vx*max}px,${vy*max}px)`;
  }
  element.addEventListener('pointerdown',e=>{if(!['PLAY','HQ','PORT'].includes(game.mode)||pointer!==null)return;pointer=e.pointerId;element.setPointerCapture(pointer);move(e);e.preventDefault();});
  element.addEventListener('pointermove',e=>{if(pointer===e.pointerId){move(e);e.preventDefault();}});
  function release(e){if(pointer!==e.pointerId)return;pointer=null;inputs[target]={x:0,y:0};knob.style.transform='translate(0,0)';}
  element.addEventListener('pointerup',release);element.addEventListener('pointercancel',release);element.addEventListener('lostpointercapture',e=>{if(pointer===e.pointerId)release(e);});
}
attachStick($('moveStick'),'move');attachStick($('aimStick'),'aim');
canvas.addEventListener('pointermove',e=>{if(e.pointerType==='mouse'){inputs.mouse.x=e.clientX;inputs.mouse.y=e.clientY;inputs.mouse.valid=true;}});
// Mouse events report each button separately, including left/right chords;
// pointerup only fires when the final mouse button is released.
canvas.addEventListener('mousedown',e=>{
  if(!['PLAY','PORT'].includes(game.mode)||(e.button!==0&&e.button!==2))return;
  if(e.button===2){e.preventDefault();inputs.mouse.stealthHeld=true;}
  else{inputs.shotgunPendingPresses++;inputs.mouse.down=true;}
  inputs.mouse.x=e.clientX;inputs.mouse.y=e.clientY;inputs.mouse.valid=true;
});
canvas.addEventListener('contextmenu',e=>e.preventDefault());
addEventListener('mouseup',e=>{
  if(e.button===0)inputs.mouse.down=false;
  if(e.button===2)inputs.mouse.stealthHeld=false;
});
addEventListener('pointercancel',()=>{inputs.mouse.down=false;inputs.mouse.stealthHeld=false;});
addEventListener('blur',()=>{inputs.keys.clear();inputs.mouse.down=false;inputs.mouse.stealthHeld=false;inputs.move={x:0,y:0};inputs.aim={x:0,y:0};inputs.shotgunPendingPresses=0;inputs.shotgunTriggerHeld=false;if(game.mode==='PLAY')togglePause();});
document.addEventListener('visibilitychange',()=>{if(document.hidden){inputs.mouse.down=false;inputs.mouse.stealthHeld=false;if(game.mode==='PLAY')togglePause();if(['HQ','PLAY','PAUSE','HQ_PANEL','TRAVEL','SETTINGS'].includes(game.mode))saveGame();}});
addEventListener('pagehide',()=>{if(['HQ','PLAY','PAUSE','HQ_PANEL','TRAVEL','SETTINGS'].includes(game.mode))saveGame();});
addEventListener('keydown',e=>{
  if(['Space','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code))e.preventDefault();
  if(!e.repeat&&game.mode==='HQ_PANEL'&&(e.code==='Escape'||e.code==='KeyE')){closeHQPanel();return;}
  if(!e.repeat&&['HQ','PORT'].includes(game.mode)&&e.code==='KeyE'){interactHQ();return;}
  if(!e.repeat&&game.mode==='TRAVEL'&&e.code==='Escape'){closeTravel();return;}
  if(!e.repeat&&game.mode==='SETTINGS'&&e.code==='Escape'){closeSettings();return;}
  if(!e.repeat&&game.mode==='HQ'&&e.code==='Escape'){togglePause();return;}
  if(!e.repeat&&game.mode==='PORT'&&e.code==='KeyH'){toggleWeaponDraw();game.hqStation=null;updateHQPrompt();announce(game.player.weaponDrawn?'WEAPON DRAWN · SECURITY MAY REACT':'WEAPON HOLSTERED',1.6);return;}
  if(!e.repeat&&(e.code==='Escape'||e.code==='KeyP')){if(game.mode==='PLAY'||game.mode==='PAUSE')togglePause();return;}
  if(!e.repeat&&e.code==='KeyM'&&game.mode==='PLAY'&&game.player?.map){inputs.map=!inputs.map;return;}
  if(!e.repeat&&e.code==='KeyH'&&game.mode==='PLAY'){toggleWeaponDraw();return;}
  if(!e.repeat&&e.code==='KeyF'&&game.mode==='PLAY'){useMedkit();return;}
  if(!e.repeat&&e.code==='Space'&&['PLAY','PORT'].includes(game.mode))inputs.shotgunPendingPresses++;
  if(!e.repeat&&e.code==='KeyC'&&game.mode==='PLAY'){inputs.sneakTouch=!inputs.sneakTouch;document.getElementById('sneakButton').classList.toggle('active',!!inputs.sneakTouch);return;}
  inputs.keys.add(e.code);
});
addEventListener('keyup',e=>inputs.keys.delete(e.code));
$('startButton').addEventListener('click',()=>{if(hasSave())loadGame();else enterHQ();});
$('newButton').addEventListener('click',newGame);
$('loadButton').disabled=!hasSave();
$('loadButton').addEventListener('click',loadGame);
$('pauseLoadButton').addEventListener('click',loadGame);
$('menuSettingsButton').addEventListener('click',openSettings);
$('retryButton').addEventListener('click',()=>enterHQ('OPERATOR RECOVERED // CREDITS SAFE // REEQUIP AT HQ'));
$('hqCloseButton').addEventListener('click',closeHQPanel);
$('hqInteractButton').addEventListener('click',interactHQ);
$('pauseButton').addEventListener('click',togglePause);
$('resumeButton').addEventListener('click',togglePause);
$('saveButton').addEventListener('click',()=>announce(saveGame()?'GAME SAVED':'SAVE FAILED // BROWSER STORAGE UNAVAILABLE',2));
$('pauseSettingsButton').addEventListener('click',openSettings);
$('returnTitleButton').addEventListener('click',returnToTitle);
$('hqMenuButton').addEventListener('click',togglePause);
$('travelCloseButton').addEventListener('click',closeTravel);
$('settingsCloseButton').addEventListener('click',closeSettings);
for(const k of ['musicOn','sfxOn','musicVolume','sfxVolume'])$(k).addEventListener('input',e=>{
  const val=(k==='musicOn'||k==='sfxOn')?!!e.target.checked:Number(e.target.value);
  setAudioSettings({[k]:val});if(k.endsWith('Volume'))$(k+'Value').textContent=val+'%';
});
$('quitButton').addEventListener('click',quitRun);
$('titleButton').addEventListener('click',returnToTitle);
$('drawButton').addEventListener('click',toggleWeaponDraw);
$('sneakButton').addEventListener('click',()=>{inputs.sneakTouch=!inputs.sneakTouch;$('sneakButton').classList.toggle('active',!!inputs.sneakTouch);});
$('medkitButton').addEventListener('click',useMedkit);
requestAnimationFrame(frame);

if(privateerContext){
  if(privateerContext.mode==='spaceport')enterPrivateerPort(privateerContext);
  else if(privateerContext.mode==='mission')startPrivateerMission(privateerContext);
}

function forgetWanderer(e){
  e.state='idle';e.alertTime=0;e.searchTime=0;e.lastKnown=null;
  e.searchNodes=[];e.searchIndex=0;e.suspicion=0;e.sees=false;e.hadSight=false;
  e.isWalking=false;e.patrol={x:e.x,y:e.y};
  e.stareAngle=e.angle;e.stareClock=rand(1.6,3);
}

function updateExtraction(dt){
  if(game.mode!=='PLAY')return false;
  const room=game.world.exfil==null?null:game.world.rooms[game.world.exfil];
  if(!room){game.extraction=null;return false;}
  const p=game.player,dist=Math.hypot(p.x-room.cx,p.y-room.cy);
  if(game.extraction&&dist>EXTRACTION.holdRadius){
    game.extraction=null;
    announce('EXFIL CANCELLED // RETURN TO THE INNER MARKER TO RETRY',2);
    return false;
  }
  if(!game.extraction&&dist<EXTRACTION.triggerRadius){
    game.extraction={elapsed:0,room:room.id,remaining:EXTRACTION.seconds};
    announce('EXFIL ALARM // HOLD THE RING FOR 8 SECONDS',2.2);
  }
  if(!game.extraction)return false;
  for(const e of game.enemies)alertEnemy(e,p.x,p.y,EXTRACTION.seconds+1,'alert');
  game.extraction.elapsed+=dt;
  game.extraction.remaining=Math.max(0,Math.ceil(EXTRACTION.seconds-game.extraction.elapsed));
  if(game.extraction.elapsed>=EXTRACTION.seconds){exfil();return true;}
  return false;
}

const EXTRACTION=Object.freeze({seconds:8,triggerRadius:56,holdRadius:100});

const floorAdvanceAward=(floor,rooms)=>Math.round(8+floor*3);

const floorClearAward=(floor,rooms)=>Math.max(3,Math.round(floorAdvanceAward(floor,rooms)*.35));

const isGuard=e=>!['circle','square'].includes(e.type);

const stealthAward=floor=>floorAdvanceAward(floor,0)*3;
function finalizeGuardRoster(){
  const first=game.profile.firstGuardFloor||7,early=game.floor<=10;
  for(let i=0;i<game.enemies.length;i++){
    const e=game.enemies[i];let type=e.type;
    if(early){
      const humanCount=game.floor<first?0:game.floor<10?1:4;
      type=i<humanCount?(i===3?'trapezoid':'diamond'):['circle','square'].includes(type)?type:'square';
    }
    if(type!==e.type){const d=TYPE[type];e.type=type;e.hp=e.maxHp=d.hp*(1+(game.floor-1)*.058);e.r=d.r;e.spd=d.spd;}
    e.weapon=e.type==='diamond'?'knife':e.type==='trapezoid'?chooseGuardWeapon(game.world.rng,game.floor):null;
  }
  let humans=0;for(const e of game.enemies){e.duty=isGuard(e)&&humans++===0?'post':'patrol';initializeBehavior(e);}
}

function rangedCoverIntent(e,dt){
  if(e.type!=='trapezoid'||!e.lastKnown||!['alert','search'].includes(e.state)||game.extraction)return null;
  e.coverClock=(e.coverClock||0)-dt;
  if(!e.coverPlan||e.coverClock<=0){
    e.coverPlan=null;e.coverClock=3;
    const seen=e.lastKnown,candidates=[];
    for(const room of game.world.rooms)for(const prop of room.cover){
      if(prop.hp<=0||Math.hypot(prop.x-e.x,prop.y-e.y)>420)continue;
      const dx=prop.x-seen.x,dy=prop.y-seen.y,len=Math.hypot(dx,dy)||1,nx=dx/len,ny=dy/len;
      const radius=Math.hypot(prop.w,prop.h)/2+e.r+12;
      const shelter={x:prop.x+nx*radius,y:prop.y+ny*radius};
      if(!walkable(game.world,shelter.x,shelter.y,e.r+2)||clearSight(game.world,seen.x,seen.y,shelter.x,shelter.y))continue;
      for(const side of [-1,1]){
        const peek={x:shelter.x-ny*radius*1.5*side,y:shelter.y+nx*radius*1.5*side};
        if(walkable(game.world,peek.x,peek.y,e.r+2)&&clearSight(game.world,peek.x,peek.y,seen.x,seen.y)){
          candidates.push({shelter,peek,score:Math.hypot(shelter.x-e.x,shelter.y-e.y)});break;
        }
      }
    }
    candidates.sort((a,b)=>a.score-b.score);e.coverPlan=candidates[0]||null;e.coverPhase=0;
  }
  if(!e.coverPlan)return null;
  e.coverPhase=(e.coverPhase||0)+dt;
  return e.coverPhase%3<1.2?e.coverPlan.shelter:e.coverPlan.peek;
}
