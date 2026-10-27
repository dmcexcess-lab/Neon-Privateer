// Awareness and graph navigation operate on physical organic geometry, not doors.
import {roomAt,walkable} from './dungeon.js';
export const VISION=Object.freeze({
  circle:{range:420,halfAngle:Math.PI*.36,hearing:600,turn:1.9},
  square:{range:820,halfAngle:Math.PI*.48,hearing:680,turn:2.05},
  diamond:{range:610,halfAngle:Math.PI*.42,hearing:640,turn:3.15},
  trapezoid:{range:700,halfAngle:Math.PI*.37,hearing:790,turn:2.55},
  pentagon:{range:790,halfAngle:Math.PI*.41,hearing:850,turn:1.5}
});
export const angleDifference=(a,b)=>Math.atan2(Math.sin(a-b),Math.cos(a-b));
export function turnToward(a,b,s){return a+Math.max(-s,Math.min(s,angleDifference(b,a)));}
export function clearSight(world,x1,y1,x2,y2){
  const dist=Math.hypot(x2-x1,y2-y1),steps=Math.max(1,Math.ceil(dist/23));
  for(let i=1;i<steps;i++){
    const t=i/steps;
    if(!walkable(world,x1+(x2-x1)*t,y1+(y2-y1)*t,0))return false;
  }
  return true;
}
export function canSpot(world,e,player){
  const rule=VISION[e.type];if(!rule)return false;
  const dx=player.x-e.x,dy=player.y-e.y,dist=Math.hypot(dx,dy);
  // Sneaking makes you harder to recognize, not invisible; near contact
  // defeats stealth. Stealth upgrades reduce the effective recognition range.
  const conceal=player.sneaking?Math.max(.25,.38*(player.stealth||1)):1;
  const effectiveRange=Math.max(82,rule.range*conceal*(!player.sneaking&&player.moving?1.18:1));
  if(dist>effectiveRange||dist<.1)return false;
  const bearing=Math.atan2(dy,dx);
  if(dist>e.r+player.r+28&&Math.abs(angleDifference(bearing,e.angle))>rule.halfAngle)return false;
  return clearSight(world,e.x,e.y,player.x,player.y);
}
export function canHear(e,x,y,scale=1){
  const rule=VISION[e.type];return !!rule&&Math.hypot(e.x-x,e.y-y)<=rule.hearing*scale;
}
export function findRoomPath(world,start,goal){
  if(start==null||goal==null)return [];
  if(start===goal)return [start];
  const queue=[start],prev=new Map([[start,null]]);
  for(let i=0;i<queue.length;i++){
    const id=queue[i];
    for(const n of world.rooms[id].neighbors){
      if(prev.has(n))continue;prev.set(n,id);queue.push(n);
      if(n===goal){const result=[goal];let v=id;while(v!=null){result.push(v);v=prev.get(v);}return result.reverse();}
    }
  }
  return [];
}
export function navigationPoint(world,e,target){
  const current=roomAt(world,e.x,e.y),destination=roomAt(world,target.x,target.y);
  if(current)e.room=current.id;
  if(!destination)return target;
  // Keep the entire doorway/center chain until traversed. Recomputing from
  // nearest room every frame can skip an opening at overlapping corners.
  if(!e.navigation||e.navigation.world!==world||e.navigation.room!==destination.id){
    const route=findRoomPath(world,e.room,destination.id),points=[];
    if(route.length>1){
      const first=world.rooms[route[0]];points.push({x:first.cx,y:first.cy});
      for(let i=1;i<route.length;i++){
        const link=world.links.find(l=>(l.a===route[i-1]&&l.b===route[i])||(l.b===route[i-1]&&l.a===route[i]));
        if(link)points.push({...link.via});
        const next=world.rooms[route[i]];points.push({x:next.cx,y:next.cy});
      }
    }
    e.navigation={world,room:destination.id,points};
  }
  const points=e.navigation.points;
  while(points.length&&Math.hypot(e.x-points[0].x,e.y-points[0].y)<20)points.shift();
  return avoidCover(world,e,points[0]||target);
}

function traversableSegment(world,a,b,radius){
  const steps=Math.max(1,Math.ceil(Math.hypot(b.x-a.x,b.y-a.y)/20));
  for(let i=1;i<=steps;i++)if(!walkable(world,a.x+(b.x-a.x)*i/steps,a.y+(b.y-a.y)*i/steps,radius))return false;
  return true;
}
// Short local A* legs route around furniture. The floor graph still handles
// long journeys through the architecture; neither layer confines an NPC to a
// home room. Paths live in the already transient navigation cache.
export function findLocalPath(world,start,goal,radius){
  const cell=32,pad=144;
  const bounds={left:Math.floor((Math.min(start.x,goal.x)-pad)/cell),right:Math.ceil((Math.max(start.x,goal.x)+pad)/cell),
    top:Math.floor((Math.min(start.y,goal.y)-pad)/cell),bottom:Math.ceil((Math.max(start.y,goal.y)+pad)/cell)};
  const nodes=new Map(),heap=[];
  function node(x,y){
    const key=x+','+y;if(nodes.has(key))return nodes.get(key);
    const n={x:x*cell,y:y*cell,gx:x,gy:y,key,cost:Infinity,closed:false,parent:null};
    n.open=x>=bounds.left&&x<=bounds.right&&y>=bounds.top&&y<=bounds.bottom&&walkable(world,n.x,n.y,radius);
    nodes.set(key,n);return n;
  }
  function push(n,score){
    let i=heap.length;heap.push({n,score});
    while(i){const parent=(i-1)>>1;if(heap[parent].score<=score)break;heap[i]=heap[parent];i=parent;}heap[i]={n,score};
  }
  function pop(){
    const first=heap[0],last=heap.pop();if(!heap.length)return first.n;
    let i=0;heap[0]=last;
    while(i*2+1<heap.length){let j=i*2+1;if(j+1<heap.length&&heap[j+1].score<heap[j].score)j++;
      if(heap[j].score>=last.score)break;heap[i]=heap[j];i=j;}heap[i]=last;return first.n;
  }
  const ends=new Set(),sx=Math.round(start.x/cell),sy=Math.round(start.y/cell),gx=Math.round(goal.x/cell),gy=Math.round(goal.y/cell);
  for(let y=-1;y<=1;y++)for(let x=-1;x<=1;x++){
    const first=node(sx+x,sy+y),last=node(gx+x,gy+y);
    if(first.open&&traversableSegment(world,start,first,radius)){first.cost=Math.hypot(first.x-start.x,first.y-start.y);push(first,first.cost+Math.hypot(first.x-goal.x,first.y-goal.y));}
    if(last.open&&traversableSegment(world,last,goal,radius))ends.add(last.key);
  }
  let found=null,expanded=0;
  while(heap.length&&expanded++<6000){
    const current=pop();if(current.closed)continue;current.closed=true;
    if(ends.has(current.key)){found=current;break;}
    for(let y=-1;y<=1;y++)for(let x=-1;x<=1;x++){
      if(!x&&!y)continue;const next=node(current.gx+x,current.gy+y);
      if(!next.open||next.closed)continue;
      if(x&&y&&(!node(current.gx+x,current.gy).open||!node(current.gx,current.gy+y).open))continue;
      if(!walkable(world,(current.x+next.x)/2,(current.y+next.y)/2,radius))continue;
      const cost=current.cost+Math.hypot(x,y)*cell;
      if(cost>=next.cost)continue;next.cost=cost;next.parent=current;push(next,cost+Math.hypot(next.x-goal.x,next.y-goal.y));
    }
  }
  if(!found)return [];
  const raw=[{...goal}];for(let n=found;n;n=n.parent)raw.push({x:n.x,y:n.y});raw.reverse();
  const result=[];let from=start,index=0;
  while(index<raw.length){
    let next=raw.length-1;while(next>index&&!traversableSegment(world,from,raw[next],radius))next--;
    result.push(raw[next]);from=raw[next];index=next+1;
  }
  return result;
}
function avoidCover(world,e,goal){
  const cache=e.navigation,radius=e.r+2;
  if(!cache)return goal;
  if(cache.localGoal&&Math.hypot(goal.x-cache.localGoal.x,goal.y-cache.localGoal.y)<24&&cache.revision===(world.navigationRevision||0)){
    const points=cache.localPoints;
    while(points?.length&&Math.hypot(e.x-points[0].x,e.y-points[0].y)<14)points.shift();
    return points?.[0]||goal;
  }
  cache.localGoal={...goal};cache.revision=world.navigationRevision||0;
  cache.localPoints=traversableSegment(world,e,goal,radius)?[]:findLocalPath(world,e,goal,radius);
  return cache.localPoints[0]||goal;
}
