import test from 'node:test';
import assert from 'node:assert/strict';
import {generateFloor,enemyBudget,planFloorPoints,floorArea,walkable} from '../neon-breach/src/dungeon.js';
import {writeFileSync} from 'node:fs';

test('population placement is unchanged by collapsing every architectural room into one',()=>{
 const world=generateFloor(31,90210),start=world.rooms[0];
 world.entry={x:start.cx,y:start.cy};world.exit=null;world.exfil=null;
 const xs=world.shapes.flatMap(s=>[s.x,s.x+s.w]),ys=world.shapes.flatMap(s=>[s.y,s.y+s.h]);
 const left=Math.min(...xs),right=Math.max(...xs),top=Math.min(...ys),bottom=Math.max(...ys);
 const single={...world,rooms:[{id:0,cx:(left+right)/2,cy:(top+bottom)/2,w:right-left,h:bottom-top,cover:world.rooms.flatMap(r=>r.cover)}]};
 assert.deepEqual(planFloorPoints(single,42),planFloorPoints(world,42),'room ids, home-room quotas and room count cannot affect global placement');
 const duplicate={...world,shapes:[...world.shapes,...world.shapes]};
 assert.equal(floorArea(duplicate),floorArea(world));
 assert.deepEqual(planFloorPoints(duplicate,42),planFloorPoints(world,42),'overlapping shape bookkeeping does not double-count floor space');
});

test('144 seeded floors spread the full population over entry, middle and distant floor space',()=>{
 const stats=[],examples=[];
 for(const floor of [1,3,7,10,11,21,31,60])for(let seed=1;seed<=18;seed++){
  const world=generateFloor(floor,seed*1319),points=planFloorPoints(world,enemyBudget(floor)),start=world.rooms[0],exit=world.rooms[world.exit];
  assert.equal(points.length,enemyBudget(floor),`full floor population ${floor}/${seed}`);
  assert.ok(points.every(p=>walkable(world,p.x,p.y,34)),'every body clears walls/cover');
  assert.ok(points.every(p=>Math.hypot(p.x-start.cx,p.y-start.cy)>=180),'small arrival protection only');
  const first=Math.min(...points.map(p=>Math.hypot(p.x-start.cx,p.y-start.cy)));
  assert.ok(first<400,`population begins near the entry, not just the exit: ${floor}/${seed}/${first}`);
  let separation=Infinity;
  for(let i=0;i<points.length;i++)for(let j=0;j<i;j++)separation=Math.min(separation,Math.hypot(points[i].x-points[j].x,points[i].y-points[j].y));
  assert.ok(separation>90,`no spawn bunches: ${floor}/${seed}/${separation}`);
  const probes=planFloorPoints(world,enemyBudget(floor)*3,{safeRadius:0});
  const gap=Math.max(...probes.map(p=>Math.min(...points.map(q=>Math.hypot(p.x-q.x,p.y-q.y)))));
  const normalizedGap=gap/Math.sqrt(floorArea(world)/points.length);
  assert.ok(normalizedGap<3,`no large vacant end of the floor: ${floor}/${seed}/${normalizedGap}`);
  const exitShare=points.filter(p=>Math.hypot(p.x-exit.cx,p.y-exit.cy)<450).length/points.length;
  if(floor>=10)assert.ok(exitShare<=.35,`exit cannot hold the population: ${floor}/${seed}/${exitShare}`);
  stats.push({floor,seed,separation,normalizedGap,exitShare});
  if(seed===7&&[1,10,31].includes(floor))examples.push({floor,seed,rooms:world.rooms.map(r=>({x:r.x,y:r.y,w:r.w,h:r.h})),start:{x:start.cx,y:start.cy},exit:{x:exit.cx,y:exit.cy},points});
 }
 console.log('GLOBAL FLOOR SPAWNS',JSON.stringify({floors:stats.length,minSeparation:Math.min(...stats.map(s=>s.separation)),worstNormalizedGap:Math.max(...stats.map(s=>s.normalizedGap)),maxExitShareFloor10Plus:Math.max(...stats.filter(s=>s.floor>=10).map(s=>s.exitShare))}));
 if(process.env.BREACH_SPAWN_REPORT)writeFileSync(process.env.BREACH_SPAWN_REPORT,JSON.stringify({stats,examples},null,2));
});
