import assert from 'node:assert/strict';
import {RNG,generateFloor,roomCount,enemyBudget,threat,strata,createHQWorld,createSpaceportWorld,enemyWeights,TILESETS,chooseEnemy,chooseGuardWeapon,walkable,roomAt,floorAt,propAt} from '../neon-breach/src/dungeon.js';
let count=0,chests=0,openSides=new Set(),moreThanTwoOpen=0;
for(let floor=1;floor<=40;floor++){
  assert.ok(threat(floor,3)>threat(floor-1,3));
  for(let seed=1;seed<=38;seed++){
    const world=generateFloor(floor,seed*1319);
    assert.equal(world.rooms.length,roomCount(floor));
    assert.equal(world.rooms.filter(r=>r.exit).length,1);
    assert.ok(world.rooms.every(r=>r.depth!==Infinity),'every chamber reachable');
    assert.ok(world.rooms.every(r=>r.neighbors.every(i=>world.rooms[i].neighbors.includes(r.id))));
    assert.ok(world.shapes.every(s=>s.kind==='rect'),'rectangular chamber footprints, not box grid corridors');
    assert.ok(world.walls.length>0,'external walls are computed');
    assert.equal(world.links.length,world.rooms.reduce((n,r)=>n+r.neighbors.length,0)/2);
    assert.ok(world.rooms.every(r=>r.tileset===world.stratum.id),'tile set matches the stratum');
    assert.ok(world.rooms.every(r=>TILESETS[world.stratum.id].modules.includes(r.module)),'module from correct set');
    assert.equal(world.spawnBudget,enemyBudget(floor),'one global floor population');
    assert.ok(world.rooms.every(r=>!('quota' in r)),'architecture never owns spawn quotas');
    if(floor<=3){
      assert.ok(world.rooms.length<=6,'first floors must be compact');
      assert.ok(world.rooms.every(r=>r.w<=511&&r.h<=381),'early chambers are tight');
      const dirs=world.rooms.slice(1).map(r=>r.approach);
      assert.ok(dirs.some((d,i)=>i>0&&Math.abs(d-dirs[i-1])%2===1),'first floors should bend by ninety degrees');
    }
    for(const r of world.rooms){
      for(const o of r.cover){
        assert.ok(o.hp>0&&TILESETS[world.stratum.id].props.includes(o.kind),'props are destructible and stratum-correct');
        assert.equal(propAt(world,o.x,o.y),o,'fixture collision lookup');
      }
      assert.equal(roomAt(world,r.cx,r.cy)?.id,r.id);
      assert.ok(walkable(world,r.cx,r.cy,16),`unwalkable center ${floor}/${seed}/${r.id}`);
      for(const c of r.caches){assert.ok(walkable(world,c.x,c.y,13),'chests accessible');chests++;}
      const samples=[
        Array.from({length:7},(_,i)=>[r.x+(i+1)/8*r.w,r.y-5]),
        Array.from({length:7},(_,i)=>[r.x+(i+1)/8*r.w,r.y+r.h+5]),
        Array.from({length:7},(_,i)=>[r.x-5,r.y+(i+1)/8*r.h]),
        Array.from({length:7},(_,i)=>[r.x+r.w+5,r.y+(i+1)/8*r.h])
      ];
      const missing=samples.reduce((s,side)=>s+(side.some(([x,y])=>floorAt(world,x,y))?1:0),0);
      openSides.add(missing);if(missing>=3)moreThanTwoOpen++;
    }
    for(const l of world.links){
      const a=world.rooms[l.a],b=world.rooms[l.b];
      assert.ok(walkable(world,l.via.x,l.via.y,14),'shared overlap traversable');
      for(const [src,dst] of [[{x:a.cx,y:a.cy},l.via],[l.via,{x:b.cx,y:b.cy}]]){
        for(let i=0;i<=20;i++){
          const t=i/20,x=src.x+(dst.x-src.x)*t,y=src.y+(dst.y-src.y)*t;
          assert.ok(floorAt(world,x,y),`physical chamber connection missing: ${floor}/${seed}/${l.a}->${l.b}`);
        }
      }
    }
    count++;
  }
}
assert.ok(chests>5000&&chests<18000,'exploration chests should reward detours');
assert.equal(enemyBudget(1),3);assert.ok(enemyBudget(2)<=5);assert.ok(enemyBudget(10)<=13);assert.ok(enemyBudget(30)<=35);
assert.ok(roomCount(1)<roomCount(10)&&roomCount(10)<roomCount(20),'sectors grow gradually');
assert.ok(openSides.has(1)&&openSides.has(2)&&openSides.has(3)&&openSides.has(4),'chambers must offer 1–4 missing sides');
assert.ok(moreThanTwoOpen>30,'branches often join to form broad multi-opening halls');
assert.equal(strata(1).id,'sewers');assert.equal(strata(10).id,'sewers');
assert.equal(strata(11).id,'maintenance');assert.equal(strata(20).id,'maintenance');
assert.equal(strata(21).id,'dig');assert.equal(strata(30).id,'dig');
assert.equal(strata(31).id,'ruins');assert.equal(strata(60).id,'ruins');
assert.ok(roomCount(11)>=roomCount(7),'lower levels open no smaller than medium sewers');
assert.ok(roomCount(21)>=roomCount(16),'lower archaeology no smaller than medium maintenance');
assert.ok(roomCount(31)>roomCount(30),'upper archaeology has very large floor plans');
assert.ok(enemyBudget(45)<=62,'upper AI count must stay capped');
for(let floor=21;floor<=70;floor++){
  assert.equal(enemyWeights(floor).circle,0,'no circles from lower archaeology onward');
  assert.equal(enemyWeights(floor).square,0,'no squares from lower archaeology onward');
}
assert.ok(enemyWeights(31).pentagon>enemyWeights(21).pentagon,'heavy guards become prevalent up high');
assert.ok(enemyWeights(31).trapezoid>enemyWeights(31).diamond,'upper floor is gun-guard dominated');
const gunRng=new RNG(1717);
for(let floor=6;floor<=10;floor++)for(let i=0;i<250;i++)assert.equal(chooseGuardWeapon(gunRng,floor),'revolver');
const middleGuns=new Set(),upperGuns=new Set();
for(let i=0;i<1000;i++){
  middleGuns.add(chooseGuardWeapon(gunRng,18));upperGuns.add(chooseGuardWeapon(gunRng,38));
}
assert.deepEqual([...middleGuns].sort(),['auto_pistol','revolver','shotgun']);
assert.deepEqual([...upperGuns].sort(),['ar','auto_pistol','shotgun']);
// Confirm map-size and environmental density rules, not just tier labels.
let sewerCover=0,sewerChests=0,archCover=0,lowerChests=0,upperCover=0,upperChests=0;
for(let s=1;s<=45;s++){
  const sewer=generateFloor(9,s*211),lower=generateFloor(26,s*211),upper=generateFloor(35,s*211);
  sewerCover+=sewer.rooms.reduce((n,r)=>n+r.cover.length,0);
  sewerChests+=sewer.rooms.reduce((n,r)=>n+r.caches.length,0);
  archCover+=lower.rooms.reduce((n,r)=>n+r.cover.length,0);
  lowerChests+=lower.rooms.reduce((n,r)=>n+r.caches.length,0);
  upperCover+=upper.rooms.reduce((n,r)=>n+r.cover.length,0);
  upperChests+=upper.rooms.reduce((n,r)=>n+r.caches.length,0);
  assert.ok(upper.rooms[1].w>sewer.rooms[1].w,'upper rooms have larger footprint');
}
assert.ok(archCover>upperCover*3,'lower archaeology has plenty of stealth cover');
assert.ok(upperChests>lowerChests*2,'upper archaeology showers exploration with chests');
assert.ok(upperChests>sewerChests*3,'upper archaeology holds much more treasure than sewers');

const r1=new RNG(314),r20=new RNG(314);let earlyGuards=0,lateGuards=0,earlyZ=0,lateZ=0;
for(let i=0;i<10000;i++){
  const a=chooseEnemy(r1,1),b=chooseEnemy(r20,20);
  if(a==='trapezoid'||a==='pentagon')earlyGuards++;
  if(b==='trapezoid'||b==='pentagon')lateGuards++;
  if(a==='circle'||a==='square')earlyZ++;
  if(b==='circle'||b==='square')lateZ++;
}
assert.equal(earlyGuards,0);assert.equal(earlyZ,10000);
for(let floor=1;floor<=5;floor++){
  const weights=enemyWeights(floor);assert.equal(weights.diamond+weights.trapezoid+weights.pentagon,0,'human enemies absent until sector 6');
}
assert.ok(enemyWeights(6).trapezoid>0&&enemyWeights(6).trapezoid<.04,'guards enter slowly on floor six');
let lowCover=0;
for(let f=1;f<=3;f++)for(let seed=1;seed<=50;seed++){
 const w=generateFloor(f,seed*73);
 lowCover+=w.rooms.reduce((n,r)=>n+r.cover.length,0);
 assert.ok(w.rooms.some(r=>r.cover.length>=2),'early sewers contain line-of-sight cover');
}
assert.ok(lowCover>=650,'opening floors have significantly more hiding obstacles');
const hq=createHQWorld();assert.equal(hq.rooms.length,5);
assert.equal(hq.stations.length,4);assert.equal(hq.exit,null);
assert.ok(hq.rooms.every(r=>r.visited&&r.tileset==='hq'));
for(const station of hq.stations)assert.ok(walkable(hq,station.x,station.y,16),`${station.id} must be reachable`);
for(const connection of hq.links)assert.ok(walkable(hq,connection.via.x,connection.via.y,18),'HQ corridors must stay open');
const port=createSpaceportWorld({seed:7123,planetId:'p-17',planetName:'Glass Harbor',archetype:'FROZEN',faction:'Orchid Compact'});
const samePort=createSpaceportWorld({seed:7123,planetId:'p-17',planetName:'Glass Harbor',archetype:'FROZEN',faction:'Orchid Compact'});
assert.equal(port.isSpaceport,true);assert.equal(port.rooms.length,9);assert.equal(port.stations.length,13);
assert.equal(port.actors.filter(a=>a.kind==='civilian').length,18);assert.equal(port.actors.filter(a=>a.kind==='guard').length,6);
assert.deepEqual(port.rooms.map(r=>[r.x,r.y,r.w,r.h]),samePort.rooms.map(r=>[r.x,r.y,r.w,r.h]),'planet seed recreates the same port');
assert.deepEqual(port.actors.map(a=>[a.kind,a.name,a.x,a.y,a.rumor]),samePort.actors.map(a=>[a.kind,a.name,a.x,a.y,a.rumor]),'NPC population and rumors are deterministic');
assert.ok(port.stations.some(s=>s.service==='terminal')&&port.stations.some(s=>s.service==='alley'),'port includes physical hacking and robbery locations');
assert.ok(port.stations.some(s=>s.service==='upgrades')&&port.stations.some(s=>s.service==='careers'),'physical port replaces upgrade and career menu entries');
assert.deepEqual(port.actors.filter(a=>a.mission).map(a=>a.mission.style),['stealth','hot','choice','stealth','hot','choice'],'spontaneous missions expose every approach throughout the port');
assert.deepEqual(port.structures.map(s=>s.kind),['cafe','market','bar','club','lodge'],'spaceport contains several public buildings');
assert.equal(port.stations.filter(s=>s.service==='venue').length,port.structures.length,'each public building has a physical venue interaction');
const bounds={minX:Math.min(...port.rooms.map(r=>r.x)),maxX:Math.max(...port.rooms.map(r=>r.x+r.w)),minY:Math.min(...port.rooms.map(r=>r.y)),maxY:Math.max(...port.rooms.map(r=>r.y+r.h))};
assert.ok(bounds.maxX-bounds.minX>3200&&bounds.maxY-bounds.minY>2900,'spaceport is a full urban map, not a small menu room');
const reached=new Set([0]),frontier=[0];
while(frontier.length)for(const neighbor of port.rooms[frontier.shift()].neighbors)if(!reached.has(neighbor)){reached.add(neighbor);frontier.push(neighbor);}
assert.equal(reached.size,port.rooms.length,'every district connects to the rest of the port');
for(const structure of port.structures){
  const walls=port.rooms[structure.room].cover.filter(o=>o.structural);
  assert.ok(walls.length>=5,`${structure.name} has its own interior walls`);
  assert.ok(!walkable(port,walls[0].x,walls[0].y,5),`${structure.name} walls block movement and shots`);
  const cx=structure.x+structure.w/2,cy=structure.y+structure.h/2;
  const doorway=structure.door==='north'?[cx,structure.y+8]:structure.door==='south'?[cx,structure.y+structure.h-8]:structure.door==='west'?[structure.x+8,cy]:[structure.x+structure.w-8,cy];
  assert.ok(walkable(port,doorway[0],doorway[1],5),`${structure.name} doorway remains open`);
}
for(const station of port.stations)assert.ok(walkable(port,station.x,station.y,16),`${station.id} spaceport service must be reachable`);
for(const connection of port.links)assert.ok(walkable(port,connection.via.x,connection.via.y,18),'spaceport corridors must stay open');
assert.ok(lateGuards>=3700 && lateZ>=3000 && lateZ<=4400,`lower maintenance should mix zombies and guards: ${lateGuards}, ${lateZ}`);
console.log(`PASS: ${count} merged modular floors across all four strata, 1–4 open sides ${[...openSides]}, ${chests} exploration chests; gradual 3–${enemyBudget(20)} enemy budgets`);
