// Freeform architectural floor-plan. Variable-size rooms overlap at shared
// boundaries; exposed boundaries are walls, overlapped sides are open. There
// is NO square-grid placement or network of narrow connecting door corridors.
export const ROOM_W = 1150;
export const ROOM_H = 900;
export const GAP = 0;
export const STEP_X = 0;
export const STEP_Y = 0;
export const DOOR_HALF = 0;
const CELL = 300;
export class RNG {
  constructor(seed=1){this.state=(seed>>>0)||1;}
  next(){let x=this.state;x^=x<<13;x^=x>>>17;x^=x<<5;this.state=x>>>0;return this.state/4294967296;}
  int(a,b){return a+Math.floor(this.next()*(b-a+1));}
  range(a,b){return a+(b-a)*this.next();}
  pick(a){return a[Math.floor(this.next()*a.length)];}
  chance(p){return this.next()<p;}
}
export const keyFor=(x,y)=>`${x},${y}`;
// Each stratum owns its architectural module palette and destructible props.
// Modules are free-positioned rectangles (never a grid cell). The world is the
// UNION of their shapes; any shared wall sections vanish automatically.
export const TILESETS = Object.freeze({
  sewers: {modules:['drain','elbow','junction','pump bay','overflow tunnel','sluice'],props:['pipe rack','valve','supply crate','baffle','bulkhead','filter bank'],trim:'#3b7779'},
  hq: {modules:['command hub','armory','storage','infirmary','deployment bay'],props:['supply crate','console','barricade'],trim:'#6bd6c7'},
  maintenance: {modules:['sewer intercept','pump chamber','maintenance bay','utility corridor','generator room','service junction'],props:['pipe rack','filter bank','rusted drum','supply crate','barricade','console'],trim:'#648b86'},
  dig: {modules:['dig trench','excavation gallery','artifact hall','storage bay','scaffold chamber','survey hall'],props:['supply crate','excavation bench','scaffold','display case','artifact plinth','barricade'],trim:'#a38b79'},
  ruins: {modules:['upper gallery','atrium','exhibit hall','security checkpoint','monument chamber','open promenade'],props:['display case','artifact plinth','console','barricade','supply crate'],trim:'#a8b6cf'}
});
// Four continuous ascent bands. Each new band begins at least as expansive
// as a medium map in the preceding band and expands from there. Caps avoid
// runaway geometry, agent counts, and per-frame collision checks.
export function roomCount(floor){
  if(floor<=10)return Math.min(12,3+Math.ceil(floor*.9));
  if(floor<=20)return Math.min(20,12+Math.ceil((floor-10)*.8));
  if(floor<=30)return Math.min(28,20+Math.ceil((floor-20)*.8));
  return Math.min(38,28+Math.ceil((floor-30)*.55));
}
export function enemyBudget(floor){
  if(floor<=10)return Math.round(2+floor*.84);
  if(floor<=20)return 10+Math.round((floor-10)*1.0);
  if(floor<=30)return 20+Math.round((floor-20)*1.2);
  return Math.min(62,42+Math.round((floor-31)*.90));
}
export function threat(floor,depth){return .78+floor*.095+depth*.025;}
export function strata(floor){
  if(floor<=10)return {id:'sewers',name:'SEWER NETWORK',color:'#0b2731',edge:'#287f85',width:136,guardShare:floor<6?0:.10};
  if(floor<=20)return {id:'maintenance',name:'LOWER LEVELS // MAINTENANCE',color:'#152c34',edge:'#548e87',width:174,guardShare:.49};
  if(floor<=30)return {id:'dig',name:'LOWER ARCHAEOLOGY',color:'#27242e',edge:'#aa927b',width:209,guardShare:1};
  return {id:'ruins',name:'UPPER ARCHAEOLOGY',color:'#242b3c',edge:'#b1a6c3',width:239,guardShare:1};
}
export function enemyWeights(floor){
  // Red and orange are the only zombies. They disappear completely at 21.
  if(floor<=5)return {circle:.69,square:.31,diamond:0,trapezoid:0,pentagon:0};
  if(floor<=10){
    const t=(floor-5)/5;
    return {circle:.67-.06*t,square:.33-.08*t,diamond:.025*t,trapezoid:.115*t,pentagon:0};
  }
  if(floor<=20){
    const t=(floor-11)/9;
    return {circle:.33-.14*t,square:.28-.08*t,diamond:.12+.08*t,trapezoid:.27+.14*t,pentagon:0};
  }
  if(floor<=30){
    const t=(floor-21)/9;
    return {circle:0,square:0,diamond:.29-.07*t,trapezoid:.67-.03*t,pentagon:.04+.10*t};
  }
  const t=Math.min(1,(floor-31)/19);
  return {circle:0,square:0,diamond:.13-.05*t,trapezoid:.61-.13*t,pentagon:.26+.18*t};
}
// Guard progression is independent of the body geometry. First encounters
// use revolvers, then automatic sidearms; long guns are reserved for later.
export function chooseGuardWeapon(rng,floor){
  if(floor<=10)return 'revolver';
  const r=rng.next();
  if(floor<=16)return r<.70?'revolver':'auto_pistol';
  if(floor<=20)return r<.36?'revolver':r<.80?'auto_pistol':'shotgun';
  if(floor<=25)return r<.20?'revolver':r<.49?'auto_pistol':r<.84?'shotgun':'ar';
  if(floor<=30)return r<.10?'revolver':r<.27?'auto_pistol':r<.68?'shotgun':'ar';
  return r<.08?'auto_pistol':r<.54?'shotgun':'ar';
}
export function chooseEnemy(rng,floor){
  const weights=enemyWeights(floor);let r=rng.next()*Object.values(weights).reduce((a,b)=>a+b,0);
  for(const [type,w] of Object.entries(weights))if((r-=w)<0)return type;
  return 'circle';
}
const rect=(x,y,w,h,roomId)=>({kind:'rect',x,y,w,h,roomId,minX:x,maxX:x+w,minY:y,maxY:y+h});
function buildIndex(world){
  world.buckets=new Map();
  for(const s of world.shapes){
    for(let x=Math.floor(s.minX/CELL);x<=Math.floor(s.maxX/CELL);x++)
      for(let y=Math.floor(s.minY/CELL);y<=Math.floor(s.maxY/CELL);y++){
        const k=keyFor(x,y);if(!world.buckets.has(k))world.buckets.set(k,[]);
        world.buckets.get(k).push(s);
      }
  }
}
export function floorAt(world,x,y){
  const bucket=world.buckets.get(keyFor(Math.floor(x/CELL),Math.floor(y/CELL)));
  return !!bucket&&bucket.some(s=>x>=s.minX&&x<=s.maxX&&y>=s.minY&&y<=s.maxY);
}
// Props share collision, bullets and sightlines. Destroyed props cease to
// block all three immediately, without requiring a new world import.
export function propAt(world,x,y,radius=0){
  for(const room of world.rooms){
    if(Math.abs(x-room.cx)>room.w*.70+110||Math.abs(y-room.cy)>room.h*.70+110)continue;
    for(const o of room.cover){
      if(o.hp<=0)continue;
      const dx=Math.max(Math.abs(x-o.x)-o.w/2,0),dy=Math.max(Math.abs(y-o.y)-o.h/2,0);
      if(dx*dx+dy*dy<(radius+1)**2)return o;
    }
  }
  return null;
}
export function walkable(world,x,y,radius=14){
  const a=radius*.71;
  const samples=radius?[[0,0],[radius,0],[-radius,0],[0,radius],[0,-radius],[a,a],[-a,a],[a,-a],[-a,-a]]:[[0,0]];
  for(const [dx,dy] of samples)if(!floorAt(world,x+dx,y+dy))return false;
  return propAt(world,x,y,radius)===null;
}
export function roomAt(world,x,y){
  if(!floorAt(world,x,y))return null;
  // An overlapping shared threshold belongs to the nearest room center.
  let room=null,best=Infinity;
  for(const r of world.rooms){
    if(x<r.x||x>r.x+r.w||y<r.y||y>r.y+r.h)continue;
    const d=(x-r.cx)**2+(y-r.cy)**2;if(d<best){best=d;room=r;}
  }
  return room;
}
export function randomSpot(world,room,rng,radius=24,awayFromCenter=0){
  for(let tries=0;tries<130;tries++){
    const x=rng.range(room.x+radius+18,room.x+room.w-radius-18),y=rng.range(room.y+radius+18,room.y+room.h-radius-18);
    if(Math.hypot(x-room.cx,y-room.cy)<awayFromCenter)continue;
    if(walkable(world,x,y,radius)&&roomAt(world,x,y)?.id===room.id)return {x,y};
  }
  return {x:room.cx,y:room.cy};
}
function overlap(a,b){
  const minX=Math.max(a.x,b.x),maxX=Math.min(a.x+a.w,b.x+b.w);
  const minY=Math.max(a.y,b.y),maxY=Math.min(a.y+a.h,b.y+b.h);
  return {minX,maxX,minY,maxY,w:maxX-minX,h:maxY-minY};
}
function prepareWalls(world){
  // Scan physical room-piece edges, omitting each segment covered by another
  // room. Thus a side may be completely missing, partially open, or intact.
  world.walls=[];
  const unit=19;
  for(const s of world.shapes){
    const edges=[
      {x:s.x,y:s.y,dx:1,dy:0,length:s.w,nx:0,ny:-1},
      {x:s.x+s.w,y:s.y,dx:0,dy:1,length:s.h,nx:1,ny:0},
      {x:s.x+s.w,y:s.y+s.h,dx:-1,dy:0,length:s.w,nx:0,ny:1},
      {x:s.x,y:s.y+s.h,dx:0,dy:-1,length:s.h,nx:-1,ny:0}
    ];
    for(const e of edges){
      const n=Math.max(1,Math.ceil(e.length/unit));let run=-1;
      for(let i=0;i<=n;i++){
        let exposed=false;
        if(i<n){const t=(i+.5)*e.length/n;
          exposed=!floorAt(world,e.x+e.dx*t+e.nx*5,e.y+e.dy*t+e.ny*5);
        }
        if(exposed&&run<0)run=i;
        if(!exposed&&run>=0){
          const a=run*e.length/n,b=i*e.length/n;
          if(b-a>=6)world.walls.push({x1:e.x+e.dx*a,y1:e.y+e.dy*a,x2:e.x+e.dx*b,y2:e.y+e.dy*b});
          run=-1;
        }
      }
    }
  }
}
// Cardinal shared-side grafting: the child overlaps its parent by a broad
// aperture. Early sectors follow a bent, slim spine; branching and multi-side
// merges become steadily more common as the underground complex grows.
export function generateFloor(floor,seed){
  const rng=new RNG(((seed>>>0)+Math.imul(floor,0x9e3779b9))>>>0);
  const stratum=strata(floor),kit=TILESETS[stratum.id],n=roomCount(floor);
  const early=floor<=3,small=floor<=10;
  function makeSize(){
    if(early)return {w:rng.range(310,510),h:rng.range(240,380)};
    if(floor<=10){const t=(floor-4)/6;
      return {w:rng.range(360+65*t,590+230*t),h:rng.range(265+65*t,465+165*t)};}
    if(floor<=20){const t=(floor-11)/9;
      return {w:rng.range(540+130*t,850+280*t),h:rng.range(395+100*t,735+215*t)};}
    if(floor<=30){const t=(floor-21)/9;
      return {w:rng.range(740+140*t,1210+340*t),h:rng.range(580+115*t,940+310*t)};}
    const t=Math.min(1,(floor-31)/18);
    return {w:rng.range(1000+120*t,1630+270*t),h:rng.range(740+105*t,1280+215*t)};
  }
  const rooms=[];
  function makeRoom(box,id,dir=-1){return {id,x:box.x,y:box.y,w:box.w,h:box.h,
    cx:box.x+box.w/2,cy:box.y+box.h/2,rx:box.w/2,ry:box.h/2,
    module:rng.pick(kit.modules),tileset:stratum.id,approach:dir,
    gx:id,gy:0,neighbors:[],visited:id===0,cleared:id===0,opened:true,spawned:false,
    depth:Infinity,exit:false,exfil:false,cover:[],caches:[],enemies:[],ornaments:[]};}
  rooms.push(makeRoom({...makeSize(),x:0,y:0},0));
  let previousDir=0;
  const cardinal=(parent,size,dir,depth,offset)=>{
    if(dir===0)return {x:parent.x+parent.w-depth,y:parent.cy-size.h/2+offset,...size};
    if(dir===1)return {x:parent.cx-size.w/2+offset,y:parent.y+parent.h-depth,...size};
    if(dir===2)return {x:parent.x-size.w+depth,y:parent.cy-size.h/2+offset,...size};
    return {x:parent.cx-size.w/2+offset,y:parent.y-size.h+depth,...size};
  };
  for(let i=1;i<n;i++){
    let proposed=null,chosenDir=0;
    for(let tries=0;tries<220;tries++){
      const parent=early||rng.chance(.72)?rooms[rooms.length-1]:rooms[rng.int(Math.max(0,rooms.length-7),rooms.length-1)];
      const size=makeSize();
      // Ninety-degree bends are mandatory for most early connections.
      const options=[(previousDir+1)%4,(previousDir+3)%4,previousDir,(previousDir+2)%4];
      const dir=early?options[i%2===1?0:1]:options[tries<140?rng.int(0,2):rng.int(0,3)];
      const depth=rng.range(small?84:112,small?118:Math.min(205,Math.min(parent.w,parent.h,size.w,size.h)*.38));
      const offset=rng.range(-.16,.16)*(dir%2?Math.min(parent.w,size.w):Math.min(parent.h,size.h));
      const box=cardinal(parent,size,dir,depth,offset),o=overlap(box,parent);
      if(o.w<(small?72:90)||o.h<(small?72:90))continue;
      if(rooms.some(r=>{
        if(r===parent)return false;
        const ov=overlap(box,r);
        return ov.w>0&&ov.h>0&&ov.w*ov.h>size.w*size.h*(early?.025:small?.075:.35);
      }))continue;
      const cx=box.x+size.w/2,cy=box.y+size.h/2;
      if(rooms.some(r=>Math.hypot(cx-r.cx)<Math.min(180,size.w*.32)&&Math.abs(cy-r.cy)<Math.min(150,size.h*.30)))continue;
      proposed=box;chosenDir=dir;break;
    }
    if(!proposed){ // Fallback: continue away from the outermost room.
      const parent=rooms[rooms.length-1],size=makeSize();
      chosenDir=early?(previousDir+(i%2===1?1:3))%4:previousDir;
      proposed=cardinal(parent,size,chosenDir,110,0);
    }
    rooms.push(makeRoom(proposed,i,chosenDir));previousDir=chosenDir;
  }
  const world={floor,seed,rooms,start:0,exit:0,stratum,rng,shapes:rooms.map(r=>rect(r.x,r.y,r.w,r.h,r.id)),links:[],walls:[]};
  for(let i=0;i<rooms.length;i++)for(let j=i+1;j<rooms.length;j++){
    const o=overlap(rooms[i],rooms[j]);
    if(o.w<62||o.h<62)continue;
    const via={x:(o.minX+o.maxX)/2,y:(o.minY+o.maxY)/2};
    const width=Math.min(o.w,o.h)*.5;
    world.links.push({a:i,b:j,via,width});
    rooms[i].neighbors.push(j);rooms[j].neighbors.push(i);
  }
  rooms[0].depth=0;const queue=[0];
  for(let k=0;k<queue.length;k++)for(const v of rooms[queue[k]].neighbors)if(rooms[v].depth===Infinity){rooms[v].depth=rooms[queue[k]].depth+1;queue.push(v);}
  const exit=rooms.reduce((a,b)=>a.depth>=b.depth?a:b);exit.exit=true;world.exit=exit.id;
  // Separate, optional escape route: stairs continue the sortie; EXFIL banks
  // recovered equipment at HQ. Both nodes exist at floor creation.
  const possibilities=rooms.filter(r=>r.id!==0&&r.id!==world.exit);
  world.exfil=null;
  if(possibilities.length&&rng.chance(floor===1?.38:.48)){
    const exfilRoom=rng.pick(possibilities);
    exfilRoom.exfil=true;world.exfil=exfilRoom.id;
  }
  buildIndex(world);prepareWalls(world);
  // The entire connected floor has ONE population budget. Room shapes only
  // describe architecture; they do not own spawns or spawn quotas.
  world.spawnBudget=enemyBudget(floor);
  // World props use stratum-specific modules, collision and destructible HP.
  for(const r of rooms){
    // Low floors are sparsely populated by zombies but dense in STEALTH cover.
    // Cover never crosses the center-to-opening routes, so every room stays
    // traversable even when several props form visual hiding pockets.
    // Lower archaeology rewards stealth with plentiful obstructing fixtures;
    // upper archaeology is deliberately exposed despite being the largest.
    const props=r.id===0?(floor<=10?2:0):floor<=10?rng.int(3,6):floor<=20?rng.int(3,5):floor<=30?rng.int(5,8):rng.int(0,2);
    for(let i=0;i<props;i++)for(let tries=0;tries<85;tries++){
      const pos=randomSpot(world,r,rng,26,78),w=rng.range(28,early?51:small?65:88),h=rng.range(28,early?57:small?65:82);
      if(Math.hypot(pos.x-r.cx,pos.y-r.cy)<(r.id===0?120:92)||!walkable(world,pos.x,pos.y,Math.max(w,h)*.72))continue;
      const radius=Math.max(w,h)*.5+27;
      if(world.links.some(l=>{
        if(l.a!==r.id&&l.b!==r.id)return false;
        const ax=r.cx,ay=r.cy,bx=l.via.x,by=l.via.y;
        const vx=bx-ax,vy=by-ay,t=Math.max(0,Math.min(1,((pos.x-ax)*vx+(pos.y-ay)*vy)/(vx*vx+vy*vy||1)));
        return Math.hypot(pos.x-(ax+vx*t),pos.y-(ay+vy*t))<radius+17;
      }))continue;
      if(r.cover.some(o=>Math.abs(o.x-pos.x)<(o.w+w)/2+21&&Math.abs(o.y-pos.y)<(o.h+h)/2+21))continue;
      const kind=rng.pick(kit.props),hp=['bulkhead','baffle','filter bank','barricade','scaffold'].includes(kind)?5:3;
      r.cover.push({...pos,w,h,kind,hp,maxHp:hp});
      // The physical openings and room centers must never be closed by props
      // from overlapping modules (including other rooms' cover).
      if(world.links.some(l=>!walkable(world,l.via.x,l.via.y,16))||rooms.some(a=>!walkable(world,a.cx,a.cy,17))){r.cover.pop();continue;}
      break;
    }
  }
  // Exploration should pay: at least one accessible chest per floor, and
  // more optional detours later. A third of non-start areas can contain one.
  let chestCount=0;
  for(const r of rooms.slice(1)){
    const chance=floor>=31?.84:floor>=21?.40:floor>=11?.34:Math.min(.40,.29+floor*.008);
    if(!rng.chance(chance))continue;
    const c=randomSpot(world,r,rng,22,65);
    if(!walkable(world,c.x,c.y,17))continue;
    r.caches.push({...c,opened:false,kind:'credits',value:rng.int(30,60)+floor*rng.int(5,9)+(floor>=31?rng.int(80,170):0)});
    chestCount++;
  }
  if(chestCount===0){
    const r=rooms[Math.max(1,Math.floor(n*.65))],c=randomSpot(world,r,rng,22,65);
    if(walkable(world,c.x,c.y,17))r.caches.push({...c,opened:false,kind:'credits',value:rng.int(40,65)+floor*7});
  }
  return world;
}


// A permanent, hand-arranged safehouse using the same merged-room geometry as
// the missions. This is an explorable level, not a static shop screen.
export function createHQWorld(){
  const blocks=[
    {name:'command hub',x:-285,y:-245,w:570,h:490},
    {name:'armory',x:205,y:-185,w:525,h:390},
    {name:'storage',x:-740,y:-165,w:535,h:360},
    {name:'deployment bay',x:-260,y:-665,w:530,h:500},
    {name:'infirmary',x:-235,y:180,w:495,h:405}
  ];
  const rooms=blocks.map((b,id)=>({id,x:b.x,y:b.y,w:b.w,h:b.h,cx:b.x+b.w/2,cy:b.y+b.h/2,
    rx:b.w/2,ry:b.h/2,module:b.name,tileset:'hq',approach:0,
    neighbors:[],visited:true,cleared:true,opened:true,spawned:true,depth:0,exit:false,exfil:false,
    cover:[],caches:[],enemies:[],ornaments:[]}));
  const stations=[
    {id:'shop',x:560,y:15,label:'ARMORY · PURCHASE EQUIPMENT',color:'#f9cc70'},
    {id:'storage',x:-555,y:15,label:'STORAGE · EQUIP / SECURE',color:'#75ffb0'},
    {id:'deploy',x:0,y:-495,label:'DEPLOY · ENTER THE SEWERS',color:'#5af0ff'},
    {id:'medical',x:0,y:416,label:'MEDICAL · SUPPLIES',color:'#ff88bc'}
  ];
  const world={floor:0,seed:0,rooms,start:0,exit:null,exfil:null,
    stratum:{id:'hq',name:'RESISTANCE HQ',color:'#122434',edge:'#4b9eae'},rng:new RNG(57),
    shapes:rooms.map(r=>rect(r.x,r.y,r.w,r.h,r.id)),links:[],walls:[],stations,isHQ:true};
  for(let i=0;i<rooms.length;i++)for(let j=i+1;j<rooms.length;j++){
    const o=overlap(rooms[i],rooms[j]);if(o.w<60||o.h<60)continue;
    world.links.push({a:i,b:j,via:{x:(o.minX+o.maxX)/2,y:(o.minY+o.maxY)/2},width:Math.min(o.w,o.h)*.5});
    rooms[i].neighbors.push(j);rooms[j].neighbors.push(i);
  }
  buildIndex(world);prepareWalls(world);
  // Station furniture sits behind the activation pads, never across walkways.
  const furniture=[
    {room:1,x:655,y:-100,w:62,h:44,kind:'console'},
    {room:1,x:655,y:116,w:56,h:42,kind:'supply crate'},
    {room:2,x:-680,y:-95,w:56,h:50,kind:'supply crate'},
    {room:2,x:-670,y:115,w:54,h:44,kind:'supply crate'},
    {room:3,x:-175,y:-592,w:46,h:48,kind:'console'},
    {room:4,x:175,y:505,w:44,h:44,kind:'console'}
  ];
  for(const obj of furniture)rooms[obj.room].cover.push({...obj,hp:999,maxHp:999});
  return world;
}

// Privateer spaceports use the real Breach geometry and navigation rather than
// the small native 3x3 imitation. A planet seed always recreates the same port.
export function createSpaceportWorld({seed=1,planetId='port',planetName='SPACEPORT',archetype='INDUSTRIAL',faction='LOCAL AUTHORITY'}={}){
  const rng=new RNG((Number(seed)>>>0)||1);
  const profile={
    LUSH:{id:'sewers',color:'#123b37',edge:'#75ffb0'},
    VOLCANIC:{id:'dig',color:'#3b211d',edge:'#ff8a62'},
    FROZEN:{id:'maintenance',color:'#142e3f',edge:'#79dcff'},
    INDUSTRIAL:{id:'hq',color:'#202c37',edge:'#f9cc70'}
  }[String(archetype).toUpperCase()]||{id:'hq',color:'#202c37',edge:'#5af0ff'};
  const jitter=()=>rng.range(-38,38);
  const blocks=[
    {name:'landing concourse',x:-310+jitter(),y:-250+jitter(),w:620,h:500},
    {name:'market arcade',x:225+jitter(),y:-205+jitter(),w:555,h:420},
    {name:'administration',x:-770+jitter(),y:-195+jitter(),w:545,h:390},
    {name:'transit spine',x:-270+jitter(),y:-700+jitter(),w:550,h:520},
    {name:'service quarter',x:-250+jitter(),y:190+jitter(),w:520,h:430},
    {name:'back alleys',x:205+jitter(),y:190+jitter(),w:540,h:410}
  ];
  const rooms=blocks.map((b,id)=>({id,x:b.x,y:b.y,w:b.w,h:b.h,cx:b.x+b.w/2,cy:b.y+b.h/2,
    rx:b.w/2,ry:b.h/2,module:b.name,tileset:profile.id,approach:0,neighbors:[],visited:true,
    cleared:true,opened:true,spawned:true,depth:0,exit:false,exfil:false,cover:[],caches:[],enemies:[],ornaments:[]}));
  const stations=[
    {id:'return',service:'return',x:0,y:-540,label:'LANDING PAD · RETURN TO SHIP',short:'SHIP',color:'#5af0ff'},
    {id:'trade',service:'trade',x:520,y:-35,label:'COMMODITY EXCHANGE',short:'TRADE',color:'#75ffb0'},
    {id:'bank',service:'bank',x:-560,y:-25,label:'BANK & CURRENCY DESK',short:'BANK',color:'#f9cc70'},
    {id:'contracts',service:'contracts',x:-80,y:430,label:'CONTRACT & GUILD BOARD',short:'JOBS',color:'#b999ff'},
    {id:'terminal',service:'terminal',x:340,y:330,label:'RESTRICTED NETWORK TERMINAL',short:'HACK',color:'#ff60bd'},
    {id:'alley',service:'alley',x:620,y:430,label:'UNWATCHED BACK ALLEY',short:'ALLEY',color:'#ff627f'}
  ];
  const names=['Mara','Kest','Ivo','Sable','Rin','Juno','Vale','Tarn','Orr','Nyx'];
  const rumors=[
    'A freighter is paying double for medicine before departure.',
    'Customs changes shifts soon. The maintenance route will be thinly watched.',
    'A courier vanished after mentioning an unregistered cargo locker.',
    'The guild board is holding a quiet job for someone who can avoid alarms.',
    'A local captain wants armed help and does not care who notices.',
    'Someone is buying restricted tech through the service quarter.'
  ];
  const actors=[];
  for(let i=0;i<7;i++){
    const room=rooms[rng.int(0,rooms.length-1)];
    actors.push({id:`npc-${i}`,kind:'civilian',name:names[rng.int(0,names.length-1)],x:room.cx+jitter(),y:room.cy+jitter(),
      home:{x:room.cx,y:room.cy},target:{x:room.cx+jitter(),y:room.cy+jitter()},speed:rng.range(23,38),
      rumor:rumors[rng.int(0,rumors.length-1)],mission:i<3?{
        style:['stealth','hot','choice'][i],kind:['evidence theft','raid','recovery'][i],difficulty:rng.int(1,4)
      }:null});
  }
  for(let i=0;i<3;i++){
    const room=rooms[(i*2+1)%rooms.length];
    actors.push({id:`guard-${i}`,kind:'guard',name:`${faction} PATROL ${i+1}`,x:room.cx,y:room.cy,
      home:{x:room.cx,y:room.cy},target:{x:rooms[(i*2+3)%rooms.length].cx,y:rooms[(i*2+3)%rooms.length].cy},speed:48,alert:false});
  }
  const world={floor:0,seed:Number(seed)||1,planetId,planetName,faction,rooms,start:0,exit:null,exfil:null,
    stratum:{id:profile.id,name:`${planetName} SPACEPORT`,color:profile.color,edge:profile.edge},rng,
    shapes:rooms.map(r=>rect(r.x,r.y,r.w,r.h,r.id)),links:[],walls:[],stations,actors,isHQ:true,isSpaceport:true,crime:{heat:0,witnessed:false}};
  for(let i=0;i<rooms.length;i++)for(let j=i+1;j<rooms.length;j++){
    const o=overlap(rooms[i],rooms[j]);if(o.w<60||o.h<60)continue;
    world.links.push({a:i,b:j,via:{x:(o.minX+o.maxX)/2,y:(o.minY+o.maxY)/2},width:Math.min(o.w,o.h)*.5});
    rooms[i].neighbors.push(j);rooms[j].neighbors.push(i);
  }
  buildIndex(world);prepareWalls(world);
  const furniture=[
    {room:1,x:690,y:-120,w:60,h:44,kind:'market kiosk'},
    {room:2,x:-690,y:105,w:54,h:46,kind:'customs desk'},
    {room:4,x:155,y:515,w:48,h:42,kind:'console'},
    {room:5,x:690,y:265,w:62,h:52,kind:'supply crate'}
  ];
  for(const obj of furniture)rooms[obj.room].cover.push({...obj,hp:999,maxHp:999});
  return world;
}

// Blue-noise-style placement over the UNION of all walkable floor pieces.
// A global candidate lattice plus farthest-point sampling avoids random
// bunches in one end of the map. No rooms are selected or given a quota.
export function planFloorPoints(world,count,{radius=34,safeRadius=180}={}){
  count=Math.max(0,Math.floor(count));if(!count)return [];
  const origin=world.rooms[world.start||0];
  const start=world.entry||{x:origin.cx,y:origin.cy};
  const area=floorArea(world);
  const seed=(world.seed||0)^Math.imul(world.floor||1,0x45d9f3b)^Math.imul(count,0x27d4eb2d);
  let pool=[];
  for(let attempt=0;attempt<3;attempt++){
    const rng=new RNG(seed),step=Math.max(35,Math.sqrt(area/(count*32))/(2**attempt));
    const offsetX=rng.range(0,step),offsetY=rng.range(0,step),seen=new Set();pool=[];
    for(const shape of world.shapes){
      for(let y=Math.ceil((shape.y-offsetY)/step)*step+offsetY;y<shape.y+shape.h;y+=step){
        for(let x=Math.ceil((shape.x-offsetX)/step)*step+offsetX;x<shape.x+shape.w;x+=step){
          const ix=Math.round((x-offsetX)/step),iy=Math.round((y-offsetY)/step),key=ix+','+iy;
          if(seen.has(key))continue;seen.add(key);
          const cellRng=new RNG(seed^Math.imul(ix,0x1f123bb5)^Math.imul(iy,0x5f356495));
          const point={x:x+cellRng.range(-step*.22,step*.22),y:y+cellRng.range(-step*.22,step*.22)};
          if(Math.hypot(point.x-start.x,point.y-start.y)<safeRadius||!walkable(world,point.x,point.y,radius))continue;
          if(safeRadius>0&&[world.exit,world.exfil].some(id=>id!=null&&Math.hypot(point.x-world.rooms[id].cx,point.y-world.rooms[id].cy)<112))continue;
          pool.push({...point,nearest:Infinity,used:false});
        }
      }
    }
    if(pool.length>=count)break;
  }
  pool.sort((a,b)=>a.x-b.x||a.y-b.y);
  const selected=[];
  // Guarantee an early-floor presence outside the arrival bubble, then fill
  // the largest remaining gaps, whether they lie near the entry, middle or end.
  let next=pool.reduce((best,p)=>!best||Math.hypot(p.x-start.x,p.y-start.y)<Math.hypot(best.x-start.x,best.y-start.y)?p:best,null);
  while(next&&selected.length<count){
    selected.push({x:next.x,y:next.y});next.used=true;const last=next;next=null;
    for(const p of pool){
      if(p.used)continue;
      p.nearest=Math.min(p.nearest,(p.x-last.x)**2+(p.y-last.y)**2);
      if(!next||p.nearest>next.nearest)next=p;
    }
  }
  return selected;
}

// Exact union area keeps placement independent of how the same floor is split
// into overlapping architectural pieces (including duplicated room shapes).
export function floorArea(world){
  const xs=[...new Set(world.shapes.flatMap(r=>[r.x,r.x+r.w]))].sort((a,b)=>a-b);let area=0;
  for(let i=1;i<xs.length;i++){
    const left=xs[i-1],right=xs[i],intervals=world.shapes.filter(r=>r.x<right&&r.x+r.w>left).map(r=>[r.y,r.y+r.h]).sort((a,b)=>a[0]-b[0]);
    let low=null,high=0,length=0;
    for(const [a,b] of intervals){if(low===null){low=a;high=b;}else if(a<=high)high=Math.max(high,b);else{length+=high-low;low=a;high=b;}}
    if(low!==null)length+=high-low;area+=(right-left)*length;
  }
  return area;
}
