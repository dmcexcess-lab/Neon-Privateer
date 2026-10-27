// Awareness and graph navigation operate on physical organic geometry, not doors.
import {roomAt,walkable} from './dungeon.js';
export const VISION=Object.freeze({
  circle:{range:760,halfAngle:Math.PI*.48,hearing:600,turn:1.9},
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
  return points[0]||target;
}
