import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {performance} from 'node:perf_hooks';

const html=readFileSync(new URL('../neon-breach/index.html',import.meta.url),'utf8');
const source=html.match(/<script type="module">([\s\S]*?)<\/script>/)?.[1];
assert.ok(source,'standalone game module is available');
const makeElement=()=>({
  style:{},disabled:false,textContent:'',innerHTML:'',classList:{add(){},remove(){},toggle(){}},
  addEventListener(){},removeEventListener(){},setPointerCapture(){},append(){},appendChild(){},replaceChildren(){},
  getContext(){return new Proxy({}, {get:()=>()=>{}})},
  getBoundingClientRect(){return {left:0,top:0,width:120,height:120}},
  querySelector(){return makeElement()}
});
const elements=new Map(),storage=new Map();
let musicInstances=0;
// Reproducible headings, pauses and spawn offsets for traversal regressions.
let randomSeed=0x1234abcd;
const seededMath=Object.create(Math);
seededMath.random=()=>{randomSeed=(Math.imul(randomSeed,1664525)+1013904223)>>>0;return randomSeed/4294967296;};
const document={
  body:makeElement(),hidden:false,addEventListener(){},createElement:makeElement,
  getElementById(id){if(!elements.has(id))elements.set(id,makeElement());return elements.get(id);}
};
const sandbox={
  Math:seededMath,
  console,document,localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,String(v))},navigator:{getGamepads(){return []}},
  innerWidth:1080,innerHeight:830,devicePixelRatio:1,performance,
  addEventListener(){},requestAnimationFrame(){},
  Audio:class{constructor(){musicInstances++;this.paused=true;this.currentTime=0;}addEventListener(){} play(){this.paused=false;return Promise.resolve()} pause(){this.paused=true;}},
};
vm.runInNewContext(source+`
;globalThis.__breach={game,generateFloor,beginFloor,updateEnemies,emitNoise,
  canSpot,patrolIntent,prepareSearch,TYPE,SHOP_GEAR,VISION,enemyBudget,roomCount,
  initializeBehavior,buildPostRoute,chooseCircleWander,roomAt,walkable,RNG,propAt,navigationPoint,
  updateExtraction,EXTRACTION,killEnemy,floorClearAward,floorAdvanceAward,stealthAward,
  enterHQ,resetRun,saveGame,loadGame,startReload,shootPlayer,updateWeaponTimers,WEAPONS,
  useMedkit,equipFromStash,collectPickup,damageFurniture,fastTravel,openTravel,nextFloor,
  getAudioSettings,setAudioSettings,unlockAudio,rangedCoverIntent,strata,clearSight,update,togglePause,purchase};
`,vm.createContext(sandbox),{timeout:15000,filename:'neon-breach-module.js'});
const b=sandbox.__breach;

test('everything costs twice the original price except the unchanged knife',()=>{
  const baseline={knife:95,revolver:165,auto_pistol:225,shotgun:285,ar:385,map:115,
    armor1:75,armor2:145,armor3:220,medkit:45};
  assert.equal(b.SHOP_GEAR.length,Object.keys(baseline).length);
  for(const gear of b.SHOP_GEAR)assert.equal(gear.cost,(gear.id==='knife'?baseline[gear.id]:baseline[gear.id]*2),gear.id);
});

function openWorld(){
  const room={id:0,cx:0,cy:0,x:-3500,y:-3500,w:7000,h:7000,neighbors:[],cover:[]};
  const floor={x:-3500,y:-3500,w:7000,h:7000,minX:-3500,minY:-3500,maxX:3500,maxY:3500};
  const buckets=new Map();
  for(let x=-12;x<=12;x++)for(let y=-12;y<=12;y++)buckets.set(x+','+y,[floor]);
  return {rooms:[room],buckets,links:[],walls:[],shapes:[floor],rng:new b.RNG(9)};
}
function zombie(x,type='circle'){
  const speed=b.TYPE[type].spd;
  return {
    type,x,y:0,r:17,spd:speed,room:0,homeRoom:0,angle:0,step:0,flash:0,contact:0,cool:99,charge:99,
    dashTime:0,orbit:1,state:'alert',sees:true,hadSight:true,suspicion:1,perceptionClock:0,
    lastKnown:{x:x+180,y:0},alertTime:10,searchTime:0,searchNodes:[],searchIndex:0,
    anchor:{x,y:0},patrol:{x,y:0},route:[{x,y:0}],routeIndex:0,stareClock:0,stareAngle:0,
    isWalking:true,atPost:true
  };
}

test('forward sight detects moving player far away and still rewards stealth/cover',()=>{
  const world=openWorld(),e=zombie(0),player={x:360,y:0,r:16,sneaking:false,moving:true,stealth:1};
  assert.ok(b.VISION.circle.range>=400);
  assert.equal(b.canSpot(world,e,player),true,'running in front is visible at 360 units');
  player.sneaking=true;
  assert.equal(b.canSpot(world,e,player),false,'sneaking drastically shortens recognition');
  player.sneaking=false;player.x=-180;
  assert.equal(b.canSpot(world,e,player),false,'zombie does not see directly behind');
});

test('footsteps attract distant zombies and pursuit is faster than patrolling',()=>{
  const e=zombie(0);
  b.game.world=openWorld();
  b.game.enemies=[e];b.game.mode='PLAY';b.game.floor=5;b.game.player={
    x:165,y:0,r:16,sneaking:false,moving:true,stealth:1,hp:10,maxHp:10,invuln:99
  };
  const patrolSpeed=b.patrolIntent({...e,state:'idle',isWalking:true,patrol:{x:200,y:0}},.02).speed;
  b.updateEnemies(.1);
  const chaseDistance=e.x;
  assert.ok(chaseDistance>patrolSpeed*.1*2,'pursuit materially exceeds idle patrol speed');
  e.state='idle';e.x=0;e.perceptionClock=999;
  b.emitNoise(190,0,1.12);
  assert.equal(e.state,'investigate','running now attracts red zombies');
  const yellow=zombie(0,'square');yellow.state='idle';
  b.game.enemies=[yellow];b.emitNoise(190,0,1.12);
  assert.equal(yellow.state,'investigate','yellow patrollers check footsteps');
});

test('red wanderers forget instantly when line of sight breaks, regardless of timer',()=>{
  const e=zombie(0,'circle');
  b.game.world=openWorld();b.game.enemies=[e];b.game.mode='PLAY';b.game.floor=5;
  b.game.player={x:165,y:0,r:16,sneaking:false,moving:true,stealth:1,hp:10,maxHp:10,invuln:99};
  b.updateEnemies(.08);
  assert.equal(e.sees,true);
  b.game.player.x=-165;e.perceptionClock=999;
  b.updateEnemies(.016);
  assert.equal(e.state,'idle');assert.equal(e.lastKnown,null);
  assert.equal(e.suspicion,0);assert.equal(e.sees,false);
  b.emitNoise(-165,0,1.5);
  assert.equal(e.state,'investigate','new audible movement is a fresh clue');
});

test('zombies detect non-stealth movement far ahead but not through cover',()=>{
  const world=openWorld(),e=zombie(0),p={x:850,y:0,r:16,sneaking:false,moving:true,stealth:1};
  assert.equal(b.canSpot(world,e,p),true);
  p.sneaking=true;assert.equal(b.canSpot(world,e,p),false);
  p.sneaking=false;world.rooms[0].cover=[{x:400,y:0,w:50,h:100,hp:4}];
  assert.equal(b.canSpot(world,e,p),false,'stronger awareness still respects occlusion');
  world.rooms[0].cover=[];e.state='idle';b.game.enemies=[e];b.game.extraction=null;
  b.emitNoise(600,0,1.12);assert.equal(e.state,'investigate');
  assert.equal(e.lastKnown.x,600);
});

function generatedScenario(floor=15){
  b.game.floor=floor;b.game.seed=0xBEEF1234;b.game.mode='PLAY';
  b.game.player={x:0,y:0,r:16,hp:100,maxHp:100,invuln:999,weapon:'hands',
    armorTier:0,medkits:0,spares:[],map:true,sneaking:false,moving:false,stealth:1};
  b.beginFloor();
}

test('first human guard holds a rotating post; other tours span every room',()=>{
  generatedScenario(30);
  const guards=b.game.enemies.filter(e=>!['circle','square'].includes(e.type));
  assert.ok(guards.length>1);assert.equal(guards[0].duty,'post');
  for(const guard of guards.slice(1)){
    assert.equal(guard.duty,'patrol');
    const rooms=new Set(guard.route.map(p=>p.room));
    assert.equal(rooms.size,b.game.world.rooms.length,'tour includes the whole connected floor');
    const fixed=JSON.stringify(guard.route);
    for(let n=0;n<guard.route.length+2;n++){
      guard.x=guard.patrol.x;guard.y=guard.patrol.y;b.patrolIntent(guard,20);
    }
    assert.equal(JSON.stringify(guard.route),fixed,'tour repeats without randomizing its stops');
  }
  for(const direction of [-1,1]){
    const e={...guards[0],orbit:direction,stareClock:0,stareAngle:0};
    e.x=e.patrol.x;e.y=e.patrol.y;
    const intent=b.patrolIntent(e,.02);
    assert.equal(intent.speed,0);assert.equal(intent.look,direction*Math.PI/2);
    const next=b.patrolIntent(e,e.stareClock+.01);
    assert.equal(next.look,direction*Math.PI,'quarter turn, same chosen direction');
  }
});

test('random walks choose a different room and patrollers really cross room boundaries',()=>{
  generatedScenario(6);
  const e=b.game.enemies.find(e=>e.type==='circle')||b.game.enemies[0];
  for(let i=0;i<20;i++){
    const home=b.roomAt(b.game.world,e.x,e.y).id;b.chooseCircleWander(e);
    assert.notEqual(b.roomAt(b.game.world,e.patrol.x,e.patrol.y).id,home);
    assert.equal(b.walkable(b.game.world,e.patrol.x,e.patrol.y,e.r+3),true);
  }
  e.type='square';e.duty='patrol';e.state='idle';b.initializeBehavior(e);
  b.game.enemies=[e];b.game.player.x=-1e6;b.game.player.y=-1e6;
  const seen=new Set([e.room]);
  for(let n=0;n<9000;n++){b.updateEnemies(.1);seen.add(e.room);}
  assert.equal(seen.size,b.game.world.rooms.length,'actual traversal '+JSON.stringify({seen:[...seen],pos:[e.x,e.y],patrol:e.patrol,index:e.routeIndex,nav:b.navigationPoint(b.game.world,e,e.patrol),cover:b.game.world.rooms.flatMap(r=>r.cover).filter(p=>Math.hypot(p.x-e.x,p.y-e.y)<250),route:e.route}));
});

test('exfil alarms the entire floor, cancels outside the ring, and requires eight seconds',()=>{
  generatedScenario(15);
  // Optional exfil is probabilistic; explicitly designate a room for this scenario.
  b.game.world.exfil=1;b.game.world.rooms[1].exfil=true;
  const room=b.game.world.rooms[b.game.world.exfil];assert.ok(room);
  Object.assign(b.game.player,{x:room.cx,y:room.cy});
  b.updateExtraction(.1);
  assert.ok(b.game.enemies.every(e=>e.state==='alert'&&e.lastKnown.x===room.cx));
  const remote=b.game.enemies.find(e=>Math.hypot(e.x-room.cx,e.y-room.cy)>1000);
  assert.ok(remote,'test includes an enemy far outside the old local simulation range');
  b.updateEnemies(.1);assert.equal(remote.state,'alert','alarm overrides loss of sight');
  b.game.player.x=room.cx+b.EXTRACTION.holdRadius+1;b.updateExtraction(.1);
  assert.equal(b.game.extraction,null);
  b.game.player.x=room.cx+70;b.updateExtraction(.1);assert.equal(b.game.extraction,null,'outer ring does not restart');
  b.game.player.x=room.cx;b.updateExtraction(5);assert.equal(b.game.mode,'PLAY');
  assert.equal(b.game.extraction.remaining,3);
  b.game.mode='PAUSE';b.updateExtraction(30);assert.equal(b.game.extraction.remaining,3);
  b.game.mode='PLAY';b.updateExtraction(2.99);assert.equal(b.game.mode,'PLAY');
  assert.equal(b.updateExtraction(.02),true);assert.equal(b.game.mode,'HQ');
  assert.equal(b.game.extraction,null);
});

test('last hostile pays a smaller clear bonus once, independent of stairs',()=>{
  generatedScenario(6);
  const enemies=[...b.game.enemies],start=b.game.profile.credits;
  const kills=enemies.reduce((sum,e)=>sum+Math.round(b.TYPE[e.type].credits*(1+(b.game.floor-1)*.12)),0);
  const bonus=b.floorClearAward(b.game.floor,b.game.world.rooms.length);
  assert.ok(bonus>0&&bonus<b.floorAdvanceAward(b.game.floor,b.game.world.rooms.length));
  for(const enemy of enemies)b.killEnemy(enemy);
  assert.equal(b.game.profile.credits-start,kills+bonus);
  b.killEnemy(enemies.at(-1));assert.equal(b.game.profile.credits-start,kills+bonus);
  assert.equal(b.game.floorClearPaid,true);
});

test('short yellow checks versus extended guard investigations',()=>{
  b.game.world=openWorld();
  const search=type=>{
    const e=zombie(0,type);e.lastKnown={x:150,y:0};
    b.prepareSearch(e);return e;
  };
  const red=search('circle'),yellow=search('square');
  const shock=search('diamond'),guard=search('trapezoid'),heavy=search('pentagon');
  assert.equal(red.state,'idle');assert.equal(red.lastKnown,null);
  assert.equal(yellow.state,'search');assert.equal(yellow.searchNodes.length,1);
  assert.ok(yellow.searchTime<=1.5);
  assert.ok(shock.searchTime>yellow.searchTime);
  assert.ok(guard.searchTime>shock.searchTime);
  assert.ok(heavy.searchTime>guard.searchTime);
  assert.ok(guard.searchNodes.length>yellow.searchNodes.length);
});

test('out-of-range enemies do not sleep: radar-visible units keep moving',()=>{
  const e=zombie(2500,'square');
  e.state='investigate';e.hadSight=false;e.sees=false;e.lastKnown={x:2700,y:0};
  e.perceptionClock=999;
  b.game.world=openWorld();
  b.game.enemies=[e];b.game.mode='PLAY';b.game.player={
    x:0,y:0,r:16,sneaking:false,moving:false,stealth:1,hp:10,maxHp:10,invuln:99
  };
  b.updateEnemies(.25);
  assert.ok(e.x>2500,'distant enemy still navigates even beyond old 1650 cutoff');
});

test('archaeology and maximum generated floors sustain full-range AI',()=>{
  const stats=[];
  for(const floor of [15,30,60]){
    b.game.floor=floor;b.game.seed=0xBEEF1234;b.game.mode='PLAY';
    b.game.player={x:0,y:0,r:16,hp:100,maxHp:100,invuln:999,
      sneaking:false,moving:false,stealth:1,weapon:'hands',map:true};
    b.beginFloor();
    assert.equal(b.game.world.rooms.length,b.roomCount(floor));
    assert.ok(b.game.enemies.length<=b.enemyBudget(floor),'floor-wide enemy budget');
    const start=performance.now(),durations=[];
    for(let i=0;i<120;i++){
      const t=performance.now();b.updateEnemies(1/60);
      durations.push(performance.now()-t);
    }
    const elapsed=performance.now()-start;
    durations.sort((a,c)=>a-c);
    const p95=durations[Math.floor(.95*(durations.length-1))];
    const avg=elapsed/120;
    const stat={floor,rooms:b.game.world.rooms.length,enemies:b.game.enemies.length,
      avg_ms:+avg.toFixed(3),p95_ms:+p95.toFixed(3)};
    stats.push(stat);
    assert.ok(avg<16.7,'average AI tick fits the 60 Hz budget: '+JSON.stringify(stat));
    assert.ok(p95<45,'95th percentile AI tick remains bounded: '+JSON.stringify(stat));
  }
  console.log('NEON BREACH AI STRESS '+JSON.stringify(stats));
});


test('all four ascent bands and first guard encounters match the recovered brief',()=>{
  const bands={1:'sewers',10:'sewers',11:'maintenance',20:'maintenance',21:'dig',30:'dig',31:'ruins',60:'ruins'};
  for(const [floor,id] of Object.entries(bands))assert.equal(b.strata(Number(floor)).id,id);
  b.game.profile.firstGuardFloor=8;
  for(const floor of [6,7,8,9,10,21,31]){
    generatedScenario(floor);const humans=b.game.enemies.filter(e=>!['circle','square'].includes(e.type));
    if(floor<8)assert.equal(humans.length,0);
    if(floor===8||floor===9){assert.equal(humans.length,1);assert.equal(humans[0].type,'diamond');assert.equal(humans[0].weapon,'knife');assert.equal(humans[0].duty,'post');}
    if(floor===10)assert.deepEqual(Array.from(humans,e=>e.type),['diamond','diamond','diamond','trapezoid']);
    if(floor===10)assert.deepEqual(Array.from(humans.slice(1),e=>e.duty),['patrol','patrol','patrol']);
    if(floor>=21)assert.equal(humans.length,b.game.enemies.length,'archaeology has no zombies');
  }
});

test('three base hits, six with best vest, one-hit repairs and five-kit carry cap',()=>{
  b.enterHQ();b.game.loadout.armor=3;b.resetRun();assert.equal(b.game.player.maxHp,6);
  b.game.player.hp=2;b.game.player.medkits=2;assert.equal(b.useMedkit(),true);assert.equal(b.game.player.hp,3);
  b.game.player.medkits=5;assert.equal(b.collectPickup({kind:'med',x:0,y:0}),false);
  b.enterHQ();b.game.loadout.medkits=5;b.game.profile.storage.medkit=4;assert.equal(b.equipFromStash('medkit'),false);
  b.game.loadout.armor=0;b.resetRun();assert.equal(b.game.player.maxHp,3);
});

test('shotgun requires separate pump clicks and reloads five individual shells on empty',()=>{
  b.enterHQ();b.game.loadout.weapon='shotgun';b.resetRun();const p=b.game.player;
  assert.equal(b.WEAPONS.shotgun.pellets,5);
  for(let shot=0;shot<5;shot++){
    const old=b.game.bullets.length;b.shootPlayer(0);assert.equal(b.game.bullets.length-old,5);
    if(shot<4){assert.equal(p.pumpNeeded,true);assert.equal(p.magazines.shotgun,4-shot);
      const count=b.game.bullets.length;b.shootPlayer(0);assert.equal(b.game.bullets.length,count,'pump does not shoot');
      assert.ok(p.pumpClock>0);b.updateWeaponTimers(1);
    }
  }
  assert.ok(p.reloadClock>0);assert.equal(p.magazines.shotgun,0);
  b.updateWeaponTimers(.59);assert.equal(p.magazines.shotgun,1);
  b.updateWeaponTimers(2.32);assert.equal(p.magazines.shotgun,5);assert.equal(p.reloadStage,'rack');
  b.updateWeaponTimers(1);assert.equal(p.reloadClock,0);assert.equal(p.pumpNeeded,false);
  assert.equal(b.startReload(),false,'cannot reload a nonempty gun');
});

test('revolver loads rounds in sequence; AR reloads its magazine on empty',()=>{
  for(const gun of ['revolver','ar','auto_pistol']){
    b.enterHQ();b.game.loadout.weapon=gun;b.resetRun();const p=b.game.player,w=b.WEAPONS[gun];
    for(let i=0;i<w.magazine;i++)b.shootPlayer(0);
    assert.ok(p.reloadClock>0);b.updateWeaponTimers(w.reload/2+.001);
    assert.equal(p.magazines[gun],gun==='revolver'?3:0);
    b.updateWeaponTimers(w.reload);assert.equal(p.magazines[gun],w.magazine);
  }
});

test('mission save serializes navigation safely and restores equipment, world, bullets and alarm',()=>{
  b.enterHQ();b.game.loadout.weapon='shotgun';b.resetRun(30);const p=b.game.player;
  b.game.profile.credits=987;b.game.world.rooms[1].visited=true;
  if(b.game.world.rooms[1].cover.length)b.game.world.rooms[1].cover[0].hp=0;
  b.game.floorClearPaid=true;b.game.detectedThisFloor=true;b.game.extraction={elapsed:2.5,remaining:6,room:1};
  const enemy=b.game.enemies[0];enemy.x+=7;enemy.navigation={world:b.game.world,points:[{x:1,y:2}]};
  b.shootPlayer(0);p.magazines.shotgun=0;b.startReload();b.updateWeaponTimers(.7);
  b.game.bullets[0].hitIds.add(123);const expected={x:enemy.x,count:b.game.enemies.length,clock:p.reloadClock};
  assert.equal(b.saveGame(),true);const slot=JSON.parse(storage.get('neon-breach.save.v1'));
  assert.equal(slot.run.enemies[0].navigation,undefined);assert.equal(slot.run.bullets[0].hitIds[0],123);
  b.enterHQ();b.game.profile.credits=1;assert.equal(b.loadGame(),true);
  assert.equal(b.game.mode,'PLAY');assert.equal(b.game.floor,30);assert.equal(b.game.profile.credits,987);
  assert.equal(b.game.enemies.length,expected.count);assert.equal(b.game.enemies[0].x,expected.x);
  assert.equal(b.game.player.reloadClock,expected.clock);assert.ok(b.game.bullets[0].hitIds.has(123));
  assert.equal(b.game.extraction.elapsed,2.5);assert.equal(b.game.floorClearPaid,true);assert.equal(b.game.detectedThisFloor,true);
  assert.equal(b.game.world.rooms[1].visited,true);
});

test('checkpoint travel requires discovery and charges exactly once per deployment',()=>{
  b.enterHQ();b.game.profile.credits=999;b.game.profile.unlockedFloor=1;b.openTravel();
  assert.equal(b.fastTravel(11),false);assert.equal(b.game.profile.credits,999);
  b.game.profile.unlockedFloor=11;assert.equal(b.fastTravel(11),true);assert.equal(b.game.floor,11);assert.equal(b.game.profile.credits,899);
  assert.equal(b.fastTravel(11),false);assert.equal(b.game.profile.credits,899);
  assert.equal(b.game.profile.unlockedFloor,11);
});

test('creatures never drop supplies and furniture rare loot only rolls once',()=>{
  generatedScenario(5);b.game.pickups=[];const original=seededMath.random;seededMath.random=()=>0;
  try{
    for(const e of [...b.game.enemies])b.killEnemy(e);assert.equal(b.game.pickups.length,0);
    const prop={x:0,y:0,w:30,h:30,hp:1};b.damageFurniture(prop,5);assert.equal(b.game.pickups.length,1);
    b.damageFurniture(prop,5);assert.equal(b.game.pickups.length,1,'destroyed prop cannot roll twice');
  }finally{seededMath.random=original;}
});

test('music/SFX settings persist independently without duplicate music players',()=>{
  b.unlockAudio();b.unlockAudio();assert.equal(musicInstances,1);
  b.setAudioSettings({musicOn:false,musicVolume:30,sfxOn:false,sfxVolume:20});
  assert.equal(JSON.parse(storage.get('neon-breach.audio.v1')).musicVolume,30);
  b.enterHQ();b.resetRun();b.setAudioSettings({musicOn:true});b.unlockAudio();
  assert.equal(musicInstances,1);assert.equal(b.getAudioSettings().sfxOn,false);
});

test('completion awards encourage unseen exits more than combat clears',()=>{
  for(const floor of [1,10,31,60]){
    const advance=b.floorAdvanceAward(floor,30),clear=b.floorClearAward(floor,30);
    assert.ok(clear<advance);assert.ok(b.stealthAward(floor)>advance+clear);
    assert.ok(advance<35+floor*18+30*5,'completion credits reduced versus old build');
  }
});


test('ranged guards shelter behind physical cover then peek toward the last observed position',()=>{
  b.game.world=openWorld();b.game.world.rooms[0].cover=[{x:200,y:0,w:60,h:80,hp:4}];b.game.extraction=null;
  const e={type:'trapezoid',state:'alert',x:400,y:0,r:21,lastKnown:{x:0,y:0}};
  const shelter=b.rangedCoverIntent(e,.1);assert.ok(shelter,'reachable cover selected');
  assert.equal(b.clearSight(b.game.world,0,0,shelter.x,shelter.y),false);
  const peek=b.rangedCoverIntent(e,1.3);assert.notDeepEqual(peek,shelter);
  assert.equal(b.clearSight(b.game.world,0,0,peek.x,peek.y),true,'peek opens a real firing line');
  e.type='diamond';assert.equal(b.rangedCoverIntent(e,.1),null,'melee troops do not impersonate ranged guards');
});

test('HQ autosave keeps purchases and equipped inventory together',()=>{
  b.enterHQ();b.game.profile.credits=2000;b.game.profile.storage.knife=1;
  assert.equal(b.equipFromStash('knife'),true);assert.equal(b.purchase('medkit'),true);
  const slot=JSON.parse(storage.get('neon-breach.save.v1'));
  assert.equal(slot.mode,'HQ');assert.equal(slot.loadout.weapon,'knife');assert.equal(slot.profile.storage.knife,0);
  assert.equal(slot.profile.credits,1910);assert.equal(slot.profile.storage.medkit,b.game.profile.storage.medkit);
  assert.equal(b.loadGame(),true);assert.equal(b.game.profile.credits,1910);assert.equal(b.game.loadout.weapon,'knife');
});

test('pause freezes the mission clock and weapon reload timers',()=>{
  b.enterHQ();b.game.loadout.weapon='revolver';b.resetRun();b.game.player.magazines.revolver=0;b.startReload();
  const clock=b.game.player.reloadClock,time=b.game.time;b.togglePause();b.update(1);
  assert.equal(b.game.time,time);assert.equal(b.game.player.reloadClock,clock);
});
