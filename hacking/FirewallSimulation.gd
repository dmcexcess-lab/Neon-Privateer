extends RefCounted
## Shared native simulation: standalone Firewall and Privateer use this exact code.
const LEFT := 18.0
const RIGHT := 372.0
const TOP := 126.0
const BOTTOM := 714.0
const PADDLE_Y := 666.0
const TRACKS := ["width", "damage", "multi", "lives", "shield", "laser"]
const CAPS := {"width":6,"damage":8,"multi":3,"lives":3,"shield":3,"laser":3}
const BASE_COST := {"width":450,"damage":650,"multi":900,"lives":700,"shield":600,"laser":850}
const EFFECTS := ["wide","split","slow","shield","laser","life","magnet","shrink","fast","reverse","trace"]
var rng := RandomNumberGenerator.new()
var stage := 1
var seed_value := 1
var permanent: Dictionary = {}
var temporary: Dictionary = {}
var bricks: Array = []
var balls: Array = []
var drops: Array = []
var bolts: Array = []
var lasers: Array = []
var events: Array = []
var effects: Dictionary = {}
var state := "ready"
var paddle_x := 195.0
var target_x := 195.0
var lives := 3
var shields := 0
var laser_ammo := 0
var magnets := 0
var earned := 0
var destroyed := 0
var stage_time := 0.0
var total_time := 0.0
var trace_limit := 190.0
var accumulator := 0.0
var laser_clock := 0.0
var turret_clock := 0.0
var combo := 0
var best_combo := 0

static func normalized_levels(value: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key in TRACKS:
        result[key] = clampi(int(value.get(key, 0)), 0, int(CAPS[key]))
    return result

static func research_cost(track: String, levels: Dictionary) -> int:
    if not CAPS.has(track) or int(levels.get(track,0)) >= int(CAPS[track]):
        return -1
    return int(round(float(BASE_COST[track]) * pow(1.85, int(levels.get(track,0)))))

func store_cost(track: String) -> int:
    if not CAPS.has(track) or int(temporary.get(track,0)) >= int(CAPS[track]):
        return -1
    return int(round(float(BASE_COST[track]) * .15 * pow(1.45,int(temporary.get(track,0)))))

func rank(track: String) -> int:
    return int(permanent.get(track,0)) + int(temporary.get(track,0))

func paddle_width() -> float:
    return clampf(76.0 + rank("width")*14.0 + (38.0 if effects.has("wide") else 0.0) - (32.0 if effects.has("shrink") else 0.0), 40.0, 270.0)

func ball_damage() -> int:
    return 1 + rank("damage")

func ball_speed() -> float:
    var speed := minf(520.0, 320.0 + (stage-1)*13.0)
    if effects.has("slow"): speed *= .72
    if effects.has("fast"): speed *= 1.38
    return speed

func new_run(levels: Dictionary, seed_number: int) -> void:
    permanent = normalized_levels(levels)
    temporary = normalized_levels({})
    stage = 1
    seed_value = maxi(1,seed_number)
    earned = 0
    destroyed = 0
    total_time = 0.0
    best_combo = 0
    lives = 3 + rank("lives")
    generate_stage()

func generate_stage() -> void:
    rng.seed = seed_value + stage*7919
    bricks.clear();balls.clear();drops.clear();bolts.clear();lasers.clear();events.clear();effects.clear()
    state = "ready"
    stage_time = 0.0
    accumulator = 0.0
    turret_clock = 3.5
    laser_clock = 0.0
    combo = 0
    paddle_x = 195.0;target_x = paddle_x
    shields = rank("shield")
    laser_ammo = rank("laser")*8
    magnets = 0
    trace_limit = 190.0 + minf(80.0,stage*4.0)
    var columns := mini(10,7+int((stage-1)/4))
    var rows := mini(12,4+int((stage-1)/2))
    var width := (RIGHT-LEFT-28.0-(columns-1)*5.0)/columns
    var layout := rng.randi_range(0,3)
    for row in rows:
        for col in columns:
            # Mirrored cutouts make legible patterns, not arbitrary missing cells.
            var mirror := mini(col,columns-1-col)
            if row>0 and ((layout==0 and (row+mirror)%5==0) or (layout==1 and row%3==1 and mirror%3==0) or (layout==2 and row==2 and mirror<2)):
                continue
            var kind := "normal"
            var roll := rng.randf()
            if roll<.08:kind="cache"
            elif roll<.20:kind="armor"
            elif stage>=2 and roll<.27:kind="blast"
            elif stage>=3 and roll<.32:kind="prism"
            elif stage>=4 and roll<.45:kind="locked"
            elif stage>=5 and roll<.51:kind="phase"
            elif stage>=7 and roll<.56 and row>0:kind="steel"
            elif stage>=8 and roll<.60:kind="turret"
            if stage>=6 and row==rows-2:kind="moving"
            var hp_value := 1+mini(7,int((stage-1)/3))
            if kind=="armor" or kind=="cache":hp_value+=1+int(stage/5)
            if row==0 and col==int(columns/2) and stage>=4:kind="relay";hp_value=1+int(stage/4)
            bricks.append({"x":LEFT+14+col*(width+5),"base_x":LEFT+14+col*(width+5),"y":160.0+row*29.0,"w":width,"h":23.0,"hp":hp_value,"max_hp":hp_value,"kind":kind,"active":true,"phase":rng.randf_range(0,TAU),"reward":EFFECTS[rng.randi_range(0,EFFECTS.size()-1)],"cache_cash":rng.randi_range(25,85)+stage*4,"row":row})
    # Every run introduces actual caches, and relays always have reachable targets.
    if not bricks.is_empty():bricks.back().kind="cache"
    if bricks.size()>1:bricks[-2].kind="cache"
    if stage>=4:
        bricks[0].kind="relay"
        bricks.back().kind="locked"
    _serve()

func _serve() -> void:
    balls.clear()
    for i in mini(7,1+rank("multi")):
        balls.append({"x":paddle_x,"y":PADDLE_Y-15.0,"dx":0.0,"dy":-1.0,"r":6.0,"held":true,"spread":(i-(mini(7,1+rank("multi"))-1)*.5)*.30})
    state="ready"

func launch() -> void:
    if state not in ["ready","play"]:return
    for ball in balls:
        if bool(ball.held):
            ball.held=false
            ball.dx=sin(float(ball.spread)+.18)
            ball.dy=-sqrt(1.0-float(ball.dx)*float(ball.dx))
    state="play"

func remaining() -> int:
    var count:=0
    for brick in bricks:
        if bool(brick.active) and String(brick.kind)!="steel":count+=1
    return count

func relay_alive() -> bool:
    for brick in bricks:
        if bool(brick.active) and String(brick.kind)=="relay":return true
    return false

func brick_solid(brick: Dictionary) -> bool:
    return bool(brick.active) and (String(brick.kind)!="phase" or fmod(stage_time+float(brick.phase),2.8)<1.9)

func damage_brick(index: int, amount: int, chain: bool = false) -> void:
    if index<0 or index>=bricks.size():return
    var brick: Dictionary=bricks[index]
    if not bool(brick.active):return
    if String(brick.kind)=="steel" or (String(brick.kind)=="locked" and relay_alive()):
        events.append({"kind":"blocked","x":float(brick.x)+float(brick.w)*.5,"y":brick.y});return
    brick.hp=int(brick.hp)-amount
    events.append({"kind":"hit","x":float(brick.x)+float(brick.w)*.5,"y":brick.y})
    if int(brick.hp)>0:return
    brick.active=false
    destroyed+=1;combo+=1;best_combo=maxi(best_combo,combo)
    var cash:=5+int(brick.max_hp)*2+int(stage*.5)+mini(10,int(combo/5))
    if String(brick.kind)=="cache":cash+=int(brick.cache_cash)
    earned+=cash
    events.append({"kind":"break","x":float(brick.x)+float(brick.w)*.5,"y":brick.y,"cash":cash})
    if String(brick.kind)=="cache" or rng.randf()<.15:
        drops.append({"x":float(brick.x)+float(brick.w)*.5,"y":float(brick.y)+12,"kind":brick.reward})
    if String(brick.kind)=="prism":apply_effect("split")
    if String(brick.kind)=="blast":
        var center:=Vector2(float(brick.x)+float(brick.w)*.5,float(brick.y)+12)
        for i in bricks.size():
            var other:Dictionary=bricks[i]
            if bool(other.active) and center.distance_to(Vector2(float(other.x)+float(other.w)*.5,float(other.y)+12))<105:
                damage_brick(i,ball_damage()+2,true)
    if remaining()==0 and state not in ["clear","dead"]:
        earned+=100+stage*30
        state="clear"
        events.append({"kind":"clear","cash":100+stage*30})

func apply_effect(kind: String) -> void:
    events.append({"kind":"effect","effect":kind})
    match kind:
        "split":
            var original:Array=balls.duplicate(true)
            for ball in original:
                if balls.size()>=12:break
                for side in [-1,1]:
                    if balls.size()>=12:break
                    var copy:Dictionary=ball.duplicate(true)
                    var direction:=Vector2(float(ball.dx),float(ball.dy)).rotated(side*.38)
                    copy.dx=direction.x;copy.dy=direction.y;copy.held=false
                    if absf(float(copy.dy))<.25:copy.dy=-.55
                    var normalized:=Vector2(float(copy.dx),float(copy.dy)).normalized()
                    copy.dx=normalized.x;copy.dy=normalized.y
                    balls.append(copy)
        "life":lives=mini(12,lives+1)
        "shield":shields=mini(8,shields+1)
        "laser":laser_ammo=mini(80,laser_ammo+12)
        "magnet":magnets=mini(8,magnets+3)
        "trace":stage_time+=20.0
        _:effects[kind]=12.0

func buy_run_upgrade(track: String) -> bool:
    if state!="clear" or store_cost(track)<0:return false
    temporary[track]=int(temporary.get(track,0))+1
    if track=="lives":lives=mini(12,lives+1)
    return true

func next_stage() -> bool:
    if state!="clear":return false
    stage+=1;generate_stage();return true

func fire_laser() -> bool:
    if state!="play" or laser_ammo<=0 or laser_clock>0:return false
    laser_ammo-=1;laser_clock=.22
    for side in [-1,1]:lasers.append({"x":paddle_x+side*(paddle_width()*.5-5),"y":PADDLE_Y-14.0})
    return true

func lose_life() -> void:
    if state not in ["play","ready"]:return
    lives-=1;combo=0
    effects.clear();bolts.clear();drops.clear();lasers.clear()
    events.append({"kind":"miss"})
    if lives<=0:state="dead";balls.clear()
    else:_serve()

func step(delta: float) -> void:
    if state not in ["play","ready"]:return
    accumulator+=clampf(delta,0,.1)
    while accumulator>=1.0/240.0:
        accumulator-=1.0/240.0
        _tick(1.0/240.0)
        if state not in ["play","ready"]:break

func _tick(dt: float) -> void:
    var half:=paddle_width()*.5
    paddle_x=clampf(move_toward(paddle_x,target_x,960.0*dt),LEFT+half,RIGHT-half)
    if state=="ready":
        for ball in balls:ball.x=paddle_x;ball.y=PADDLE_Y-15.0
        return
    stage_time+=dt;total_time+=dt
    if stage_time>=trace_limit:lose_life();stage_time=maxf(0.0,trace_limit-35.0);return
    laser_clock=maxf(0,laser_clock-dt)
    for key in effects.keys():
        effects[key]=float(effects[key])-dt
        if float(effects[key])<=0:effects.erase(key)
    for brick in bricks:
        if String(brick.kind)=="moving":brick.x=float(brick.base_x)+sin(stage_time*1.4+float(brick.row))*12.0
    var alive:Array=[]
    var original_balls:Array=balls.duplicate()
    for ball in original_balls:
        if bool(ball.held):ball.x=paddle_x;ball.y=PADDLE_Y-15;alive.append(ball);continue
        var previous:=Vector2(float(ball.x),float(ball.y))
        ball.x=float(ball.x)+float(ball.dx)*ball_speed()*dt;ball.y=float(ball.y)+float(ball.dy)*ball_speed()*dt
        var radius:=float(ball.r)
        if float(ball.x)<LEFT+radius:ball.x=LEFT+radius;ball.dx=absf(float(ball.dx))
        if float(ball.x)>RIGHT-radius:ball.x=RIGHT-radius;ball.dx=-absf(float(ball.dx))
        if float(ball.y)<TOP+radius:ball.y=TOP+radius;ball.dy=absf(float(ball.dy))
        if float(ball.dy)>0 and float(ball.y)+radius>=PADDLE_Y and previous.y<=PADDLE_Y and absf(float(ball.x)-paddle_x)<=half+radius:
            ball.y=PADDLE_Y-radius-1
            ball.dx=clampf((float(ball.x)-paddle_x)/half,-1,1)*.88
            if absf(float(ball.dx))<.10:ball.dx=.10 if rng.randf()>.5 else -.10
            ball.dy=-sqrt(1.0-float(ball.dx)*float(ball.dx));combo=0
            if magnets>0:ball.held=true;ball.spread=0.0;magnets-=1
            events.append({"kind":"paddle"})
        if float(ball.y)>BOTTOM:
            if shields>0:shields-=1;ball.y=BOTTOM-radius;ball.dy=-absf(float(ball.dy));events.append({"kind":"shield"})
            else:continue
        for i in bricks.size():
            var brick:Dictionary=bricks[i]
            if not brick_solid(brick):continue
            var rect:=Rect2(float(brick.x),float(brick.y),float(brick.w),float(brick.h)).grow(radius)
            if not rect.has_point(Vector2(float(ball.x),float(ball.y))):continue
            if previous.y<=rect.position.y:ball.y=rect.position.y-.1;ball.dy=-absf(float(ball.dy))
            elif previous.y>=rect.end.y:ball.y=rect.end.y+.1;ball.dy=absf(float(ball.dy))
            elif previous.x<=rect.position.x:ball.x=rect.position.x-.1;ball.dx=-absf(float(ball.dx))
            else:ball.x=rect.end.x+.1;ball.dx=absf(float(ball.dx))
            damage_brick(i,ball_damage());break
        alive.append(ball)
    # Effects can add balls during collisions; retain those new balls as well.
    for ball in balls:
        if not original_balls.has(ball):alive.append(ball)
    balls=alive
    if state!="play":return
    if balls.is_empty():lose_life();return
    for drop in drops.duplicate():
        drop.y=float(drop.y)+160.0*dt
        if absf(float(drop.y)-PADDLE_Y)<12 and absf(float(drop.x)-paddle_x)<half+9:
            apply_effect(String(drop.kind));drops.erase(drop)
        elif float(drop.y)>BOTTOM+24:drops.erase(drop)
    for laser in lasers.duplicate():
        laser.y=float(laser.y)-780.0*dt
        var consumed:=false
        for i in bricks.size():
            var brick:Dictionary=bricks[i]
            if brick_solid(brick) and Rect2(float(brick.x),float(brick.y),float(brick.w),float(brick.h)).grow(3).has_point(Vector2(float(laser.x),float(laser.y))):
                damage_brick(i,ball_damage());consumed=true;break
        if consumed or float(laser.y)<TOP:lasers.erase(laser)
    turret_clock-=dt
    if turret_clock<=0:
        turret_clock=maxf(1.4,3.5-stage*.06)
        var turrets:Array=bricks.filter(func(brick):return bool(brick.active) and String(brick.kind)=="turret")
        if not turrets.is_empty():
            var turret:Dictionary=turrets[rng.randi_range(0,turrets.size()-1)]
            bolts.append({"x":float(turret.x)+float(turret.w)*.5,"y":float(turret.y)+24})
    for bolt in bolts.duplicate():
        bolt.y=float(bolt.y)+(180.0+mini(stage,20)*5)*dt
        if absf(float(bolt.y)-PADDLE_Y)<10 and absf(float(bolt.x)-paddle_x)<half:
            bolts.erase(bolt)
            if shields>0:shields-=1
            else:lose_life();return
        elif float(bolt.y)>BOTTOM:bolts.erase(bolt)

func snapshot() -> Dictionary:
    return {"schema":1,"stage":stage,"seed":seed_value,"permanent":permanent.duplicate(true),"temporary":temporary.duplicate(true),"bricks":bricks.duplicate(true),"balls":balls.duplicate(true),"drops":drops.duplicate(true),"bolts":bolts.duplicate(true),"lasers":lasers.duplicate(true),"effects":effects.duplicate(true),"state":state,"paddle_x":paddle_x,"target_x":target_x,"lives":lives,"shields":shields,"laser_ammo":laser_ammo,"magnets":magnets,"earned":earned,"destroyed":destroyed,"stage_time":stage_time,"total_time":total_time,"trace_limit":trace_limit,"accumulator":accumulator,"laser_clock":laser_clock,"turret_clock":turret_clock,"combo":combo,"best_combo":best_combo,"rng_state":rng.state}

func restore(data: Dictionary) -> bool:
    if int(data.get("schema",0))!=1 or not data.get("bricks",null) is Array or not data.get("balls",null) is Array:return false
    if data.get("state","") not in ["ready","play","clear","dead"]:return false
    for key in ["stage","lives","shields","laser_ammo","magnets","earned","destroyed","combo","best_combo"]:set(key,int(data.get(key,0)))
    seed_value=int(data.get("seed",1))
    permanent=normalized_levels(data.get("permanent",{}));temporary=normalized_levels(data.get("temporary",{}))
    for key in ["bricks","balls","drops","bolts","lasers"]:set(key,data.get(key,[]).duplicate(true))
    effects=data.get("effects",{}).duplicate(true)
    for key in ["paddle_x","target_x","stage_time","total_time","trace_limit","accumulator","laser_clock","turret_clock"]:set(key,float(data.get(key,0)))
    state=String(data.state);rng.seed=seed_value+stage*7919;rng.state=int(data.get("rng_state",rng.state));events.clear()
    return true
