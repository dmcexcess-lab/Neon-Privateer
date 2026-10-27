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
  addEventListener(){},removeEventListener(){},setPointerCapture(){},appendChild(){},replaceChildren(){},
  getContext(){return new Proxy({}, {get:()=>()=>{}})},
  getBoundingClientRect(){return {left:0,top:0,width:120,height:120}},
  querySelector(){return makeElement()}
});
const elements=new Map();
const document={
  body:makeElement(),hidden:false,addEventListener(){},createElement:makeElement,
  getElementById(id){if(!elements.has(id))elements.set(id,makeElement());return elements.get(id);}
};
const sandbox={
  document,localStorage:{getItem(){return null},setItem(){}},navigator:{getGamepads(){return []}},
  innerWidth:1080,innerHeight:830,devicePixelRatio:1,performance,
  addEventListener(){},requestAnimationFrame(){},
  Audio:class{addEventListener(){} play(){return Promise.resolve()} pause(){}},
};
vm.runInNewContext(source+`
;globalThis.__breach={game,generateFloor,beginFloor,updateEnemies,emitNoise,
  canSpot,patrolIntent,prepareSearch,TYPE,SHOP_GEAR,VISION,enemyBudget,roomCount};
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
  return {rooms:[room],buckets,links:[],walls:[],shapes:[floor]};
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
  assert.equal(e.state,'idle','red wanderers ignore noise-only clues');
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
  assert.equal(e.state,'idle','red never resumes a search from sound');
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
  const e=zombie(2500);
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
