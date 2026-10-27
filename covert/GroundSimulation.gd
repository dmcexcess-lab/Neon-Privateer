extends RefCounted
## Native on-foot core for Privateer ports, operations and custody.
## All agents simulate the whole floor. Rendering/camera never changes awareness.
var state: Dictionary = {}
var events: Array = []
var nav_cache: Dictionary = {}
const SIZE := 900.0
const CENTERS := [150.0,450.0,750.0]
const CIRCUIT := [0,1,2,5,8,7,6,3,4,1,4,7,8,5,2,1,0,3,6,7,4,3]
func center(index: int) -> Vector2:return Vector2(CENTERS[index%3],CENTERS[index/3])
func new_mission(kind: String, seed_number: int, gear: Dictionary,difficulty: int=1) -> void:
    var tier:=clampi(difficulty,1,5)
    var random:=RandomNumberGenerator.new();random.seed=seed_number
    state={"schema":1,"kind":kind,"difficulty":tier,"robbed":false,"seed":seed_number,"pos":center(6),"facing":-PI/2,"hp":100.0+float(gear.get("armor",0))*35,"max_hp":100.0+float(gear.get("armor",0))*35,"drawn":false,"stealth":false,"pistol":bool(gear.get("pistol",false)) and kind not in ["prison","mission_escape","prison_escape"],"saved_gear":gear.duplicate(true),"gear_recovered":false,"cool":0.0,"clock":0.0,"exit_hold":0.0,"heard":0.0,"intel":false,"hacked":false,"badge":false,"alerted":false,"result":"","guards":[],"bullets":[],"npcs":[],"paused":false}
    # Spacious rooms connected through narrow cross-floor corridors.
    if kind!="port":
        for i in 4+tier*3:
            var room: int=[0,1,2,3,4,5,8][i%7]
            state.guards.append({"pos":center(room)+Vector2(random.randf_range(-50,50),random.randf_range(-50,50)),"angle":random.randf()*TAU,"hp":60.0+float(tier-1)*20,"mode":"patrol","suspicion":0.0,"route":i*3,"post":i==0,"turn":2.5,"wait":0.0,"nav":[],"nav_time":0.0,"last":center(room),"cool":0.0})
    for i in 3:
        state.npcs.append({"name":["Rook · dock runner","Sella · freight clerk","Venn · fixer"][i],"pos":center([6,4,2][i])+Vector2(40,0),"base":center([6,4,2][i]),"phase":float(i)*2})
    if kind=="tail":
        state.npcs[0].base=center(2)+Vector2(-22,0);state.npcs[1].base=center(2)+Vector2(22,0)
    if kind in ["prison","mission_escape","prison_escape"]:state.hp=100.0;state.max_hp=100.0
    if kind in ["bounty","assassinate"] and not state.guards.is_empty():state.guards[-1].pos=center(8)
    if kind=="mug":state.npcs[0].base=center(2);state.npcs[0].pos=center(2)
    events.clear();nav_cache.clear()
func restore(data: Dictionary) -> bool:
    if data.get("schema",0)!=1 or not data.get("pos") is Vector2 or not data.get("guards") is Array:return false
    state=data.duplicate(true);state.paused=true;state.bullets=[];events.clear();nav_cache.clear();return true
func snapshot() -> Dictionary:return state.duplicate(true)
func walkable(p: Vector2, radius: float = 10) -> bool:
    if p.x<30+radius or p.y<30+radius or p.x>870-radius or p.y>870-radius:return false
    for y in CENTERS:
        for x in CENTERS:
            if Rect2(x-108+radius,y-108+radius,216-2*radius,216-2*radius).has_point(p):return true
    for y in CENTERS:
        if absf(p.y-y)<36-radius and p.x>60 and p.x<840:return true
    for x in CENTERS:
        if absf(p.x-x)<36-radius and p.y>60 and p.y<840:return true
    return false
func line_clear(a: Vector2,b: Vector2) -> bool:
    var count:=maxi(1,int(a.distance_to(b)/9))
    for i in range(1,count):
        if not walkable(a.lerp(b,float(i)/count),0):return false
    return true
func move(from: Vector2,velocity: Vector2) -> Vector2:
    var p:=from
    if walkable(p+Vector2(velocity.x,0)):p.x+=velocity.x
    if walkable(p+Vector2(0,velocity.y)):p.y+=velocity.y
    return p
func _cell(p: Vector2) -> Vector2i:return Vector2i(roundi(p.x/30),roundi(p.y/30))
func route_to(a: Vector2,b: Vector2) -> Array:
    # BFS on traversable cells handles the corridors rather than running at walls.
    var start:=_cell(a);var finish:=_cell(b);var key:=str(start)+":"+str(finish)
    if nav_cache.has(key):return nav_cache[key].duplicate()
    var todo:Array[Vector2i]=[start];var parent:Dictionary={start:start};var head:=0
    while head<todo.size():
        var cell:Vector2i=todo[head];head+=1
        if cell==finish:break
        for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var next:Vector2i=cell+d
            if not parent.has(next) and walkable(Vector2(next)*30):parent[next]=cell;todo.append(next)
    var path:Array=[]
    if parent.has(finish):
        var cell:=finish
        while cell!=start:path.push_front(Vector2(cell)*30);cell=parent[cell]
    if nav_cache.size()>300:nav_cache.clear()
    nav_cache[key]=path.duplicate();return path
func toggle_draw() -> void:
    state.drawn=not state.drawn;state.cool=.2
func attack(direction: Vector2) -> bool:
    if state.is_empty() or not state.drawn or float(state.cool)>0 or state.paused or not String(state.result).is_empty() or state.kind=="port":return false
    state.cool=.3 if state.pistol else .55
    var aim:=direction.normalized();state.facing=aim.angle()
    events.append({"kind":"shot" if state.pistol else "punch"})
    if state.pistol:state.bullets.append({"pos":state.pos+aim*16,"vel":aim*480,"life":1.8,"owner":"player"})
    else:
        for guard in state.guards:
            if guard.hp>0 and state.pos.distance_to(guard.pos)<54 and aim.dot((guard.pos-state.pos).normalized())>.45:
                guard.hp-=35;guard.mode="alert";state.alerted=true
    return true
func near_marker() -> String:
    if state.kind=="port":
        for npc in state.npcs:
            if state.pos.distance_to(npc.pos)<65:return "contact"
        return ""
    if state.kind in ["prison","mission_escape","prison_escape"]:
        if state.pos.distance_to(center(3))<65 and not state.badge:return "badge"
        if state.pos.distance_to(center(1))<65 and not state.gear_recovered:return "locker"
    if state.pos.distance_to(center(2))<65 and not state.hacked and state.kind in ["intel","evidence","station_hack","robbery","prison","mission_escape","prison_escape"]:return "terminal"
    if state.kind=="mug" and not state.get("robbed",false) and state.pos.distance_to(state.npcs[0].pos)<65:return "victim"
    return ""
func interact() -> String:
    var marker:=near_marker()
    if marker=="badge":state.badge=true;events.append({"kind":"badge"})
    elif marker=="locker":state.gear_recovered=true;state.pistol=bool(state.saved_gear.get("pistol",false));events.append({"kind":"locker"})
    elif marker=="terminal":events.append({"kind":"hack"})
    elif marker=="victim" and state.drawn:
        state.robbed=true;state.alerted=true;events.append({"kind":"civilian_robbed"})
        for g in state.guards:g.mode="alert";g.last=state.pos
    elif marker=="contact":events.append({"kind":"rumor" if not state.drawn else "lower_weapon"})
    return marker
func hack_result(success: bool) -> void:
    if success:state.hacked=true;state.intel=true
    state.paused=false
func objective_ready() -> bool:
    match String(state.kind):
        "port":return true
        "tail":return state.intel
        "intel","evidence","station_hack","robbery":return state.hacked
        "mug":return state.get("robbed",false)
        "prison","mission_escape","prison_escape":return state.badge or state.hacked
        "bounty","assassinate":return float(state.guards[-1].hp)<=0
        "assault":
            for g in state.guards:
                if g.hp>0:return false
            return true
    return false
func step(dt: float, movement: Vector2, aim: Vector2, trigger: bool) -> void:
    if state.is_empty() or state.paused or not String(state.result).is_empty():return
    dt=minf(dt,.035);state.clock+=dt;state.cool=maxf(0,state.cool-dt)
    var stride:=movement.limit_length()* (72 if state.stealth else 140)*dt
    state.pos=move(state.pos,stride)
    if aim.length()>.2:state.facing=aim.angle()
    elif stride.length()>.01:state.facing=stride.angle()
    if trigger:attack(aim if aim.length()>.2 else Vector2.from_angle(state.facing))
    for npc in state.npcs:
        npc.phase+=dt*.55;npc.pos=npc.base+Vector2(cos(npc.phase)*38,sin(npc.phase)*24)
    if state.kind=="tail":
        var listening: bool=state.pos.distance_to(center(2))<95 and not state.drawn and not state.alerted and line_clear(state.pos,center(2))
        state.heard=minf(6,state.heard+dt) if listening else maxf(0,state.heard-dt*.5)
        if state.heard>=6 and not state.intel:state.intel=true;events.append({"kind":"intel"})
    for g in state.guards:
        if g.hp<=0:continue
        g.cool=maxf(0,g.cool-dt);g.nav_time-=dt
        var distance:float=g.pos.distance_to(state.pos)
        var difference:float=absf(angle_difference(g.angle,(state.pos-g.pos).angle()))
        var sees:bool=distance<(240 if state.drawn else 185) and difference<(.72 if not state.stealth else .48) and line_clear(g.pos,state.pos)
        var hears:bool=movement.length()>.25 and not state.stealth and distance<125
        if sees:g.suspicion=minf(1,g.suspicion+dt*(2.2 if not state.stealth else .85));g.last=state.pos
        elif hears:g.suspicion=minf(.85,g.suspicion+dt);g.last=state.pos
        else:g.suspicion=maxf(0,g.suspicion-dt*.12)
        if g.suspicion>=1:g.mode="alert";state.alerted=true
        elif g.suspicion>.25 and g.mode!="alert":g.mode="search"
        elif g.suspicion<.08 and g.mode=="search":g.mode="patrol"
        if state.exit_hold>0:g.mode="alert";g.last=state.pos
        if g.mode=="alert" and sees and distance<210 and g.cool<=0:
            g.cool=1.2;state.bullets.append({"pos":g.pos,"vel":(state.pos-g.pos).normalized()*215,"life":2.0,"owner":"guard"})
        var destination:Vector2=g.last if g.mode in ["alert","search"] else center(CIRCUIT[int(g.route)%CIRCUIT.size()])
        if g.post and g.mode=="patrol":
            g.turn-=dt
            if g.turn<=0:g.angle+=PI/2;g.turn=2.5
            continue
        if g.pos.distance_to(destination)<20:
            if g.mode=="patrol":
                g.wait+=dt
                if g.wait>1.8:g.route+=1;g.wait=0;g.nav=[]
                else:g.angle+=dt*.9
            continue
        if g.nav_time<=0 or g.nav.is_empty():g.nav=route_to(g.pos,destination);g.nav_time=.6
        if not g.nav.is_empty():
            var point:Vector2=g.nav[0];var dir:Vector2=point-g.pos
            if dir.length()<12:g.nav.pop_front()
            else:g.angle=dir.angle();g.pos=move(g.pos,dir.normalized()*(105 if g.mode=="alert" else 65+8*int(state.get("difficulty",1)-1))*dt)
    var keep:Array=[]
    for b in state.bullets:
        b.life-=dt
        # Substeps prevent thin-wall and actor tunnelling.
        var hit:=false
        for sub in 3:
            b.pos+=b.vel*dt/3
            if not walkable(b.pos,0):hit=true;break
            if b.owner=="guard" and b.pos.distance_to(state.pos)<14:state.hp-=15+3*int(state.get("difficulty",1)-1);hit=true;break
            if b.owner=="player":
                for g in state.guards:
                    if g.hp>0 and b.pos.distance_to(g.pos)<17:g.hp-=30;g.mode="alert";g.last=state.pos;state.alerted=true;hit=true;break
            if hit:break
        if not hit and b.life>0:keep.append(b)
    state.bullets=keep
    if state.hp<=0:state.result="caught";events.append({"kind":"caught"});return
    var inside:bool=state.pos.distance_to(center(6))<44
    if state.kind!="port" and objective_ready() and inside:
        state.exit_hold+=dt
        for g in state.guards:
            if g.hp>0:g.mode="alert";g.last=state.pos
        if state.exit_hold>=8:state.result="extracted";events.append({"kind":"extracted"})
    else:state.exit_hold=0.0
