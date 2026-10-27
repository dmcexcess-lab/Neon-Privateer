extends Node2D
## Shared career menu, real on-foot operations, custody and native hacking.
signal career_changed(data: Dictionary, cash: int)
signal exit_requested
const Career=preload("CovertCareer.gd")
const Ground=preload("GroundSimulation.gd")
const Hacker=preload("res://hacking/FirewallGame.gd")
const INK=Color("e0faff")
const CYAN=Color("5af0ff")
const GREEN=Color("75ffb0")
const GOLD=Color("f9cc70")
const PINK=Color("ff627f")
const DIM=Color("8ca9bf")
const VIEW=Rect2(14,145,362,480)
const STEALTH=Rect2(15,641,130,46)
const DRAW=Rect2(245,641,130,46)
const ACT=Rect2(145,718,100,54)
var data:Dictionary=Career.default_profile()
var cash:=0
var planet:=""
var port_name:=""
var phase:="BOARD"
var sim=Ground.new()
var hack:Node2D
var notice:=""
var page:=0
var keys:Dictionary={}
var sticks:Dictionary={}
var move_axis:=Vector2.ZERO
var aim_axis:=Vector2.ZERO
var mouse_aim:=Vector2.ZERO
var mouse_attack:=false
var mouse_stealth:=false
var save_clock:=0.0
var origin_kind:=""
var sound_requested:Callable
func _ready() -> void:
    hack=Hacker.new();hack.embedded=true;hack.visible=false
    hack.challenge_finished.connect(_hack_finished)
    hack.career_changed.connect(_hack_checkpoint)
    add_child(hack)
func configure(saved: Dictionary,balance: int,location: String,label: String,research: Dictionary) -> void:
    data=Career.decode(saved);cash=balance;planet=location;port_name=label;phase="BOARD";page=0
    clear_inputs();sim=Ground.new()
    if not data.ground.is_empty() and sim.restore(data.ground):phase="GROUND"
    elif data.incarcerated:begin_ground("prison")
    data["research"]=research.duplicate(true)
    if is_instance_valid(hack):hack.visible=false
func clear_inputs() -> void:
    keys.clear();sticks.clear();move_axis=Vector2.ZERO;aim_axis=Vector2.ZERO;mouse_aim=Vector2.ZERO;mouse_attack=false;mouse_stealth=false
func persist() -> void:
    data.ground=sim.snapshot() if phase=="GROUND" and not sim.state.is_empty() else {}
    career_changed.emit(data.duplicate(true),cash)
func pause_game() -> void:
    if phase=="GROUND" and not sim.state.is_empty():sim.state.paused=true
    if is_instance_valid(hack) and hack.visible:hack.pause_game()
    clear_inputs();persist()
func _notification(what: int) -> void:
    if not is_visible_in_tree():return
    if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:pause_game()
func buy(item: String) -> bool:
    if data.incarcerated or phase!="BOARD":return false
    var cost:=350 if item=="pistol" else 250
    if item not in ["pistol","armor"] or cash<cost:return false
    if (item=="pistol" and data.gear.pistol) or (item=="armor" and data.gear.armor>=3):return false
    cash-=cost
    if item=="pistol":data.gear.pistol=true
    else:data.gear.armor+=1
    notice="FIELD GEAR PURCHASED";persist();return true
func accept(kind: String) -> bool:
    if kind not in ["track","recover","assault"]:return false
    var offer:Dictionary=Career.offer(planet,kind,data.sequence);offer["port_label"]=port_name
    if not Career.accept(data,offer):return false
    notice="CONTRACT ACCEPTED // OBJECTIVE LOG UPDATED";persist();return true
func current_task() -> String:return Career.next_task(data.active)
func begin_ground(kind: String) -> bool:
    if data.incarcerated and kind!="prison":return false
    if kind!="port" and kind!="prison":
        if data.active.is_empty() or data.active.planet!=planet or kind!=current_task():return false
    var seed_number:int=int(data.active.get("seed",planet.hash()))+int(data.active.get("stage",0))*71
    sim.new_mission(kind,seed_number,data.gear);phase="GROUND";clear_inputs();persist();return true
func _rumor() -> void:
    var speaker:="Dock contact"
    for npc in sim.state.npcs:
        if sim.state.pos.distance_to(npc.pos)<65:speaker=String(npc.name).split(" · ")[0];break
    if not data.active.is_empty() and data.active.planet==planet and Career.advance(data,"rumor",speaker):
        notice="LEAD RECORDED // CHECK OBJECTIVES";persist()
    else:notice="ROOK: 'Buy your own drinks. The contract board is still hiring.'"
func resolve_ground(result: String) -> void:
    if phase!="GROUND" or sim.state.is_empty():return
    var kind:=String(sim.state.kind)
    if result=="caught":
        data.arrests+=1;data.incarcerated=true;data.challenge={}
        Career.add_entry(data,"ARREST: compound security confiscated field gear. Escape detention or pay the release fine from carried cash; bank funds are protected.")
        # Failed escape restarts custody, not the contract; equipment remains impounded.
        if kind!="prison":data["impounded"]=data.gear.duplicate(true)
        data.gear={"pistol":false,"armor":0}
        var held:Dictionary=data.get("impounded",{"pistol":false,"armor":0})
        sim.new_mission("prison",int(sim.state.seed)+113,held)
        notice="DETAINED // BADGE DESK WEST, GEAR NORTH, EXIT SOUTHWEST";clear_inputs();persist();return
    if result!="extracted":return
    if kind=="prison":
        data.incarcerated=false
        if sim.state.gear_recovered:data.gear=data.get("impounded",data.gear).duplicate(true)
        data.erase("impounded");Career.add_entry(data,"ESCAPED DETENTION. "+("Equipment recovered." if sim.state.gear_recovered else "Impounded equipment left behind."))
        notice="ESCAPED // CONTRACT LEADS RETAINED"
    elif not data.active.is_empty() and data.active.planet==planet and Career.advance(data,kind):
        var reward:=Career.settle(data);cash+=reward
        notice="CONTRACT PAID: %d CR"%reward if reward>0 else "LEAD SECURED // NEXT OBJECTIVE AVAILABLE"
    data.ground={};data.challenge={};phase="BOARD";sim=Ground.new();clear_inputs();persist()
func pay_release() -> bool:
    if not data.incarcerated or cash<300:return false
    cash-=300;data.incarcerated=false;data.gear=data.get("impounded",data.gear).duplicate(true);data.erase("impounded")
    Career.add_entry(data,"RELEASE FINE: 300 CR paid from carried cash; equipment returned.")
    data.challenge={};sim=Ground.new();phase="BOARD";clear_inputs();persist();return true
func _start_hack() -> void:
    if sim.state.is_empty() or sim.state.kind not in ["intel","prison"]:return
    sim.state.paused=true;clear_inputs()
    var profile:Dictionary=data.challenge.duplicate(true)
    if profile.is_empty():profile=Hacker.default_profile();profile.research=data.get("research",{}).duplicate(true)
    hack.visible=true;hack.start_challenge(profile,int(sim.state.seed));persist()
func _hack_checkpoint(profile: Dictionary,_balance: int) -> void:
    if not is_visible_in_tree() or not hack.visible:return
    data.challenge=profile.duplicate(true);persist()
func _hack_finished(success: bool) -> void:
    hack.visible=false;data.challenge={};sim.hack_result(success);clear_inputs()
    notice="TERMINAL OPEN // EXTRACT TO SECURE RECORDS" if success else "FIREWALL HELD // YOU CAN RETRY OR RETREAT"
    persist();queue_redraw()
func return_to_board() -> bool:
    if phase!="GROUND" or data.incarcerated:return false
    if sim.state.kind!="port":Career.add_entry(data,"RETREATED: no extraction, no new lead, no payout. Contract remains active.")
    phase="BOARD";sim=Ground.new();data.challenge={};clear_inputs();persist();return true
func _process(delta: float) -> void:
    if not is_visible_in_tree():return
    if is_instance_valid(hack) and hack.visible:return
    if phase=="GROUND" and not sim.state.is_empty():
        var keyboard:=Vector2(float(keys.get(KEY_D,false))-float(keys.get(KEY_A,false)),float(keys.get(KEY_S,false))-float(keys.get(KEY_W,false)))
        var movement:Vector2=move_axis if move_axis.length()>.1 else keyboard
        var toggle:bool=bool(sim.state.stealth)
        sim.state.stealth=toggle or mouse_stealth or bool(keys.get(KEY_SHIFT,false))
        sim.step(delta,movement,aim_axis if aim_axis.length()>.2 else mouse_aim,mouse_attack or aim_axis.length()>.22)
        sim.state.stealth=toggle
        var pending:Array=sim.events.duplicate();sim.events.clear()
        for event in pending:
            match String(event.kind):
                "rumor":_rumor()
                "lower_weapon":notice="CONTACT: HOLSTER YOUR WEAPON FIRST"
                "hack":_start_hack()
                "caught","extracted":resolve_ground(event.kind)
                "shot","punch":
                    if sound_requested.is_valid():sound_requested.call(event.kind)
        save_clock+=delta
        if save_clock>=4:save_clock=0;persist()
    queue_redraw()
func _input(event: InputEvent) -> void:
    if not is_visible_in_tree() or (is_instance_valid(hack) and hack.visible):return
    if event.device==InputEvent.DEVICE_ID_EMULATION:return
    if event is InputEventKey:
        keys[event.keycode]=event.pressed
        if event.pressed and not event.echo and phase=="GROUND":
            if event.keycode in [KEY_ESCAPE,KEY_P]:sim.state.paused=not sim.state.paused;clear_inputs();persist()
            elif event.keycode==KEY_H and not sim.state.paused:sim.toggle_draw()
            elif event.keycode==KEY_C and not sim.state.paused:sim.state.stealth=not sim.state.stealth
            elif event.keycode==KEY_E and not sim.state.paused:sim.interact()
            elif event.keycode==KEY_SPACE and not sim.state.paused:sim.attack(Vector2.from_angle(sim.state.facing))
    elif event is InputEventScreenTouch:
        if event.pressed:
            if phase=="GROUND" and not sim.state.paused and event.position.distance_to(Vector2(85,748))<62:sticks[event.index]="move";_stick("move",event.position)
            elif phase=="GROUND" and not sim.state.paused and event.position.distance_to(Vector2(305,748))<62:sticks[event.index]="aim";_stick("aim",event.position)
            else:_tap(event.position)
        elif sticks.has(event.index):
            if sticks[event.index]=="move":move_axis=Vector2.ZERO
            else:aim_axis=Vector2.ZERO
            sticks.erase(event.index)
    elif event is InputEventScreenDrag and sticks.has(event.index):_stick(sticks[event.index],event.position)
    elif event is InputEventMouseMotion and phase=="GROUND":mouse_aim=(event.position-Vector2(195,385)).normalized()
    elif event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_RIGHT:mouse_stealth=event.pressed
        if event.button_index==MOUSE_BUTTON_LEFT:
            if event.pressed:
                if phase=="GROUND" and not sim.state.paused and VIEW.has_point(event.position):mouse_attack=true
                else:_tap(event.position)
            else:mouse_attack=false
func _stick(which: String,pos: Vector2) -> void:
    var vector:Vector2=(pos-(Vector2(85,748) if which=="move" else Vector2(305,748)))/48
    if which=="move":move_axis=vector.limit_length()
    else:aim_axis=vector.limit_length()
func _tap(p: Vector2) -> void:
    if phase=="GROUND":
        if sim.state.paused:
            if Rect2(28,300,334,54).has_point(p):sim.state.paused=false;clear_inputs()
            elif Rect2(28,370,334,54).has_point(p):persist();notice="CAREER SAVED"
            elif Rect2(28,440,334,54).has_point(p):
                if data.incarcerated:pay_release()
                else:return_to_board()
        elif Rect2(290,20,86,46).has_point(p):sim.state.paused=true;clear_inputs();persist()
        elif STEALTH.has_point(p):sim.state.stealth=not sim.state.stealth
        elif DRAW.has_point(p):sim.toggle_draw()
        elif ACT.has_point(p):sim.interact()
        return
    if Rect2(14,20,90,46).has_point(p):persist();exit_requested.emit();return
    if phase=="JOURNAL":
        if Rect2(20,740,160,52).has_point(p):page=maxi(0,page-1)
        elif Rect2(210,740,160,52).has_point(p):page+=1
        elif Rect2(20,85,350,48).has_point(p):phase="BOARD"
        return
    if Rect2(250,20,126,46).has_point(p):phase="JOURNAL";page=0;return
    if Rect2(20,170,350,52).has_point(p):begin_ground("port");return
    if data.active.is_empty():
        for i in 3:
            if Rect2(20,245+i*86,350,74).has_point(p):accept(["track","recover","assault"][i]);return
    elif Rect2(20,395,350,54).has_point(p):
        var task:=current_task();begin_ground("port" if task=="rumor" else task);return
    if Rect2(20,535,350,52).has_point(p):buy("pistol")
    elif Rect2(20,599,350,52).has_point(p):buy("armor")
func _label(text: String,pos: Vector2,size: int=14,color: Color=INK) -> void:draw_string(ThemeDB.fallback_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _wrap(text: String,pos: Vector2,width: float=330,size: int=14,color: Color=DIM) -> float:
    var line:="";var y:=pos.y
    for word in text.split(" "):
        if ThemeDB.fallback_font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not line.is_empty():_label(line,Vector2(pos.x,y),size,color);y+=size+6;line=""
        line+=word+" "
    if not line.is_empty():_label(line,Vector2(pos.x,y),size,color);y+=size+6
    return y
func _button(rect: Rect2,text: String,color: Color=CYAN) -> void:
    draw_rect(rect,Color("122634"));draw_rect(rect,color,false,1.5)
    _label(text,rect.position+Vector2(12,rect.size.y*.5+5),14,color)
func _draw() -> void:
    if not is_visible_in_tree() or (is_instance_valid(hack) and hack.visible):return
    draw_rect(Rect2(0,0,390,844),Color("080e19"))
    if phase=="GROUND":_draw_ground();return
    _button(Rect2(14,20,90,46),"DOCK")
    _label("PORT OPERATIONS",Vector2(20,109),23,CYAN)
    if phase=="JOURNAL":
        _button(Rect2(20,85,350,48),"OBJECTIVES / RETURN")
        var y:=165.0
        for i in range(page*4,mini(page*4+4,data.journal.size())):
            y=_wrap(data.journal[i],Vector2(20,y),345,14,INK)+22
        if data.journal.is_empty():_wrap("No entries yet. Accept a contract or visit the port.",Vector2(20,175))
        _button(Rect2(20,740,160,52),"NEWER")
        _button(Rect2(210,740,160,52),"OLDER")
        return
    _button(Rect2(250,20,126,46),"JOURNAL")
    _label(port_name.left(32),Vector2(20,140),15,DIM)
    _button(Rect2(20,170,350,52),"WALK PORT / CONTACTS")
    if data.active.is_empty():
        var labels:=["TRACK BOUNTY // 900 CR","RECOVER RECORDS // 650 CR","RAIDER SWEEP // 450 CR"]
        for i in 3:_button(Rect2(20,245+i*86,350,74),labels[i],GREEN)
    else:
        _label("%s / %s"%[String(data.active.type).to_upper(),data.active.target],Vector2(20,250),17,GOLD)
        _wrap(Career.objective(data.active),Vector2(20,282),346,14,INK)
        var local:bool=data.active.planet==planet
        _button(Rect2(20,395,350,54),"FOLLOW LEAD: "+current_task().to_upper() if local else "RETURN TO CONTRACT'S ORIGIN PORT",GREEN if local else DIM)
        if not local:_wrap("Travel to %s using the ship map; this lead is tied to that port."%data.active.get("port_label",data.active.planet),Vector2(20,477),345,12)
    _button(Rect2(20,535,350,52),"PULSE PISTOL / "+("OWNED" if data.gear.pistol else "350 CR"),GOLD)
    _button(Rect2(20,599,350,52),"ARMOR %d/3 / 250 CR"%data.gear.armor,GOLD)
    _label("CASH %d / CLOSED %d / ARRESTS %d"%[cash,data.completed,data.arrests],Vector2(20,691),12,GREEN)
    _wrap(notice,Vector2(20,730),345,13,GOLD)
    _wrap("Your investigation, ship travel and field work share one career. Combat jobs skip the clue chain.",Vector2(20,790),345,12)
func _map(p: Vector2) -> Vector2:return p-Vector2(sim.state.pos)+VIEW.get_center()
func _draw_ground() -> void:
    var s:Dictionary=sim.state
    _label("BREACH / "+String(s.kind).to_upper(),Vector2(15,43),20,CYAN)
    _button(Rect2(290,20,86,46),"PAUSE")
    _label("HP %d / %s / %s"%[s.hp,"PISTOL" if s.pistol else "HANDS","DRAWN" if s.drawn else "HOLSTERED"],Vector2(15,86),13,GOLD)
    var tip:="PORT: WALK TO A CONTACT / INTERACT"
    match String(s.kind):
        "tail":tip="NE ROOM: LISTEN %.1f / 6s UNSEEN"%s.heard
        "intel":tip="NE TERMINAL: "+("OPEN / EXTRACT SW" if s.hacked else "HACK / THEN EXTRACT SW")
        "bounty":tip="SE TARGET / DEAD OR ALIVE / EXTRACT SW"
        "assault":tip="DEFEAT ALL HOSTILES / EXTRACT SW"
        "prison":tip="WEST BADGE / NORTH GEAR / SW EXIT"
    _label(tip,Vector2(15,113),11,GREEN)
    if s.exit_hold>0:_label("HOLD EXTRACTION %.1f / 8s // ALARM"%s.exit_hold,Vector2(15,136),12,PINK)
    draw_set_transform(Vector2.ZERO)
    # Clip the procedural level using a subcanvas-like transform and explicit masks.
    for y in Ground.CENTERS:
        draw_rect(Rect2(_map(Vector2(60,y-36)),Vector2(780,72)),Color("102b3b"))
    for x in Ground.CENTERS:
        draw_rect(Rect2(_map(Vector2(x-36,60)),Vector2(72,780)),Color("102b3b"))
    for i in 9:
        var origin:=sim.center(i)-Vector2(108,108)
        var r:=Rect2(_map(origin),Vector2(216,216))
        draw_rect(r,Color("122a39"))
        for grid in range(18,216,30):
            draw_line(r.position+Vector2(grid,0),r.position+Vector2(grid,216),Color("193644"),1)
            draw_line(r.position+Vector2(0,grid),r.position+Vector2(216,grid),Color("193644"),1)
        # Physical door gaps match the simulation's connecting corridors.
        for side in 4:
            var start:=r.position+Vector2(0 if side<2 else 216,0 if side%2==0 else 216)
            var end:=r.position+Vector2(216 if side<2 else 0,0 if side%2==0 else 216)
            if side>=2:
                start=r.position+Vector2(0 if side==2 else 216,0)
                end=start+Vector2(0,216)
            var outer:bool=(side==0 and i<3) or (side==1 and i>=6) or (side==2 and i%3==0) or (side==3 and i%3==2)
            if outer:draw_line(start,end,CYAN.darkened(.5),2)
            else:
                draw_line(start,start.lerp(end,1.0/3),CYAN.darkened(.5),2)
                draw_line(start.lerp(end,2.0/3),end,CYAN.darkened(.5),2)
                draw_circle(start.lerp(end,1.0/3),3,CYAN)
                draw_circle(start.lerp(end,2.0/3),3,CYAN)
        var names:=["RECORDS ANNEX","IMPOUND / STORES","COMMS SUITE","SECURITY DESK","CONCOURSE","EAST GATE","ARRIVALS","FREIGHT","QUARTERS"]
        _label(names[i],r.position+Vector2(12,28),11,CYAN.darkened(.25))
        for stripe in 4:
            draw_line(r.position+Vector2(12+stripe*8,198),r.position+Vector2(16+stripe*8,190),GOLD.darkened(.55),2)
    var exit:=_map(sim.center(6));draw_arc(exit,44,0,TAU,40,GREEN,2)
    _label("EXIT / 8s",exit+Vector2(-32,-51),12,GREEN)
    if s.kind in ["intel","prison"]:
        var t:=_map(sim.center(2));draw_rect(Rect2(t-Vector2(14,14),Vector2(28,28)),GREEN if s.hacked else GOLD);_label("TERMINAL",t+Vector2(-30,-24),11,GOLD)
    if s.kind=="tail":_label("MEETING",_map(sim.center(2))+Vector2(-25,-45),12,GOLD)
    if s.kind=="prison":
        for item in [{"p":sim.center(3),"t":"BADGE"},{"p":sim.center(1),"t":"GEAR"}]:
            var pos:=_map(item.p);draw_circle(pos,12,GOLD);_label(item.t,pos+Vector2(-25,-22),12,GOLD)
    if s.kind in ["port","tail"]:
        for npc in s.npcs:
            var p:=_map(npc.pos);draw_circle(p,12,GREEN)
            if s.kind=="port":_label(String(npc.name).split(" · ")[0],p+Vector2(-22,-20),11,GREEN)
    for i in s.guards.size():
        var g:Dictionary=s.guards[i];var pos:=_map(g.pos)
        var color:=DIM if g.hp<=0 else PINK if g.mode=="alert" else GOLD
        draw_circle(pos,12,color);draw_line(pos,pos+Vector2.from_angle(g.angle)*25,color,2)
        if g.hp>0:_label("!" if g.mode=="alert" else "?" if g.mode=="search" else "",pos+Vector2(-3,-18),18,color)
        if s.kind=="bounty" and i==s.guards.size()-1:_label("TARGET",pos+Vector2(-23,-32),12,GOLD)
    for b in s.bullets:draw_circle(_map(b.pos),3,PINK if b.owner=="guard" else CYAN)
    draw_circle(VIEW.get_center(),12,GREEN if s.stealth else CYAN)
    if s.drawn:draw_line(VIEW.get_center(),VIEW.get_center()+Vector2.from_angle(s.facing)*25,GOLD,4)
    # Masks keep world geometry outside the play window out of the HUD/controls.
    for r in [Rect2(0,0,390,145),Rect2(0,625,390,219),Rect2(0,145,14,480),Rect2(376,145,14,480)]:draw_rect(r,Color("080e19"))
    _label("BREACH / "+String(s.kind).to_upper(),Vector2(15,43),20,CYAN);_button(Rect2(290,20,86,46),"PAUSE")
    _label("HP %d / %s / %s"%[s.hp,"PISTOL" if s.pistol else "HANDS","DRAWN" if s.drawn else "HOLSTERED"],Vector2(15,86),13,GOLD)
    _label(tip,Vector2(15,113),11,GREEN)
    if s.exit_hold>0:_label("HOLD %.1f / 8s // ALL GUARDS ALERT"%s.exit_hold,Vector2(15,136),12,PINK)
    # Whole-floor radar is informational; agents continue simulating off camera.
    draw_rect(Rect2(296,151,74,74),Color("08111e"))
    for index in 9:
        draw_rect(Rect2(Vector2(300,155)+(sim.center(index)-Vector2(105,105))/900*66,Vector2(15,15)),CYAN.darkened(.8))
    for g in s.guards:
        if g.hp>0:draw_circle(Vector2(300,155)+Vector2(g.pos)/900*66,2,PINK)
    draw_circle(Vector2(300,155)+Vector2(s.pos)/900*66,3,CYAN)
    draw_circle(Vector2(300,155)+sim.center(6)/900*66,2,GREEN)
    _button(STEALTH,"STEALTH "+("ON" if s.stealth else "OFF"),GREEN)
    _button(DRAW,"HOLSTER [H]" if s.drawn else "DRAW [H]",PINK)
    for pair in [{"p":Vector2(85,748),"axis":move_axis,"label":"MOVE"},{"p":Vector2(305,748),"axis":aim_axis,"label":"AIM / ATTACK"}]:
        draw_arc(pair.p,51,0,TAU,40,CYAN,2);draw_circle(pair.p+pair.axis*32,16,CYAN.darkened(.5));_label(pair.label,pair.p+Vector2(-36,68),11,DIM)
    var marker:=sim.near_marker()
    _button(ACT,"TALK [E]" if marker=="contact" else "USE [E]",GOLD)
    if not notice.is_empty():_wrap(notice,Vector2(15,619),350,11,GOLD)
    if s.paused:
        draw_rect(Rect2(0,0,390,844),Color(0,0,.02,.92))
        _label("FIELD PAUSED",Vector2(28,220),28,CYAN)
        _wrap("Progress saves with your career. Backgrounding pauses patrols, gunfire and extraction.",Vector2(28,250),330,14)
        _button(Rect2(28,300,334,54),"RESUME")
        _button(Rect2(28,370,334,54),"SAVE CAREER")
        _button(Rect2(28,440,334,54),"PAY RELEASE FINE / 300 CR" if data.incarcerated else "LEAVE / RETREAT TO PORT",GOLD)
        _wrap("Recover gear in the north room; take the badge from the west desk or hack the northeast terminal. Reach the southwest exit and hold for 8 seconds." if data.incarcerated else "WASD / move. Right mouse / hold stealth. H / draw. E / interact. Mouse or right stick attacks only when drawn.",Vector2(28,550),330,14,INK)
