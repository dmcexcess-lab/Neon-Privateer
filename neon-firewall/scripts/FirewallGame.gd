extends Node2D
## Native presentation and profile lifecycle shared with Privateer.
signal career_changed(profile: Dictionary, balance: int)
signal challenge_finished(success: bool)
var pay_brick_rewards := true
var challenge_mode := false
var challenge_settled := false
signal exit_requested
const Simulation = preload("FirewallSimulation.gd")
const W := 390.0
const H := 844.0
const CYAN := Color("5af0ff")
const PINK := Color("ff60bd")
const GOLD := Color("f9cc70")
const GREEN := Color("75ffb0")
const RED := Color("ff627f")
const MUTED := Color("8ca9bf")
const LABELS := {"width":"PADDLE ARRAY","damage":"PACKET DAMAGE","multi":"PARALLEL BALLS","lives":"RETRY BUFFER","shield":"FLOOR SHIELD","laser":"LASER INJECTOR"}
const DESCRIPTIONS := {"width":"Wider paddle (+14)","damage":"+1 damage per ball","multi":"+1 starting ball / max 7","lives":"+1 life / retry","shield":"+1 shield each level","laser":"+8 laser shots each level"}
const EFFECT_LABELS := {"wide":"WIDE PADDLE","split":"MULTIBALL","slow":"SLOW BALLS","shield":"SHIELD +1","laser":"LASER +12","life":"RETRY +1","magnet":"MAGNET +3","shrink":"PADDLE SHRINK","fast":"OVERCLOCK","reverse":"REVERSED INPUT","trace":"TRACE +20s"}
var embedded := false
var slot := 1
var profile: Dictionary = {}
var balance := 0
var sim = Simulation.new()
var phase := "TITLE"
var previous_phase := "TITLE"
var left_held := false
var right_held := false
var touch_index := -1
var ui_time := 0.0
var save_clock := 0.0
var credited_earned := 0
var credited_destroyed := 0
var cleared_stage := 0
var death_recorded := false
var confirm_new := false
var notice := ""
var notice_clock := 0.0
var particles: Array = []
var floats: Array = []
var sound_on := true
var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}
var voice_index := 0

static func default_profile() -> Dictionary:
    return {"schema":1,"research":Simulation.normalized_levels({}),"run":{},"best":1,"clears":0,"deaths":0,"bricks":0,"total_earned":0,"credited":0,"destroyed_credited":0,"cleared_stage":0,"death_recorded":false,"sound":true}

func _ready() -> void:
    if profile.is_empty():
        if embedded:configure(default_profile(),0)
        else:_load_last_slot()
    _setup_audio()
    queue_redraw()

func configure(data: Dictionary, cash: int) -> void:
    profile=default_profile().merged(data.duplicate(true),true)
    profile.research=Simulation.normalized_levels(profile.get("research",{}))
    balance=maxi(0,cash)
    credited_earned=int(profile.get("credited",0));credited_destroyed=int(profile.get("destroyed_credited",0))
    cleared_stage=int(profile.get("cleared_stage",0));death_recorded=bool(profile.get("death_recorded",false))
    sound_on=bool(profile.get("sound",true));sim=Simulation.new()
    var run:Dictionary=profile.get("run",{})
    if not run.is_empty() and not sim.restore(run):profile.run={};notice="RUN SAVE UNAVAILABLE // PROFILE PRESERVED";notice_clock=5
    phase="TITLE";confirm_new=false;left_held=false;right_held=false;touch_index=-1
    _sync_audio()
    queue_redraw()

static func decode_profile(saved: Variant) -> Dictionary:
    var data:Variant=bytes_to_var(saved) if saved is PackedByteArray else saved
    return data if data is Dictionary else default_profile()

func _slot_path(index: int) -> String:
    return "user://firewall_profile_%d.cfg" % index

func _load_last_slot() -> void:
    var cfg:=ConfigFile.new()
    if cfg.load("user://firewall_slots.cfg")==OK:slot=clampi(int(cfg.get_value("slots","last",1)),1,3)
    load_slot(slot)

func load_slot(index: int) -> void:
    if embedded or index<1 or index>3:return
    slot=index
    var cfg:=ConfigFile.new()
    if cfg.load(_slot_path(index))==OK:configure(decode_profile(cfg.get_value("profile","data",default_profile())),int(cfg.get_value("profile","credits",0)))
    else:configure(default_profile(),0)
    var slots:=ConfigFile.new();slots.set_value("slots","last",slot);slots.save("user://firewall_slots.cfg")
    persist()

func persist() -> void:
    if profile.is_empty():return
    profile.run=sim.snapshot() if not sim.bricks.is_empty() else {}
    profile.credited=credited_earned;profile.destroyed_credited=credited_destroyed
    profile.cleared_stage=cleared_stage;profile.death_recorded=death_recorded;profile.sound=sound_on
    if embedded:career_changed.emit(profile.duplicate(true),balance)
    else:
        var cfg:=ConfigFile.new();cfg.set_value("profile","data",var_to_bytes(profile));cfg.set_value("profile","credits",balance)
        var path:=_slot_path(slot)
        if cfg.save(path+".tmp")==OK:
            var result:=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
            if result!=OK:notice="SAVE FAILED // KEEP THIS TAB OPEN";notice_clock=5
        else:notice="SAVE FAILED // KEEP THIS TAB OPEN";notice_clock=5
    save_clock=0.0

func start_challenge(data: Dictionary, seed_number: int) -> void:
    challenge_mode=true;challenge_settled=false
    configure(data,0)
    if not sim.bricks.is_empty() and sim.state in ["ready","play"]:phase="PLAY"
    else:start_new_run(seed_number)
    notice="SAFEHOUSE FIREWALL // CLEAR ONE LAYER";notice_clock=4

func start_new_run(seed_number: int = 0) -> void:
    sim.new_run(profile.research,seed_number if seed_number>0 else int(Time.get_ticks_usec()%2147483646)+1)
    credited_earned=0;credited_destroyed=0;cleared_stage=0;death_recorded=false
    profile.run=sim.snapshot();phase="PLAY";confirm_new=false
    notice="HOLD THE LINE // CLICK OR SPACE TO LAUNCH" if pay_brick_rewards else "PRACTICE / NO CASH PAYOUT";notice_clock=3.0
    particles.clear();floats.clear();persist()

func resume_run() -> void:
    if sim.bricks.is_empty() or sim.state=="dead":return
    phase="SHOP" if sim.state=="clear" else "PLAY"
    confirm_new=false

func buy_research(track: String) -> bool:
    var cost:=Simulation.research_cost(track,profile.research)
    if phase!="RESEARCH" or cost<0 or balance<cost:return false
    balance-=cost;profile.research[track]=int(profile.research.get(track,0))+1
    persist();_sound("buy");return true

func buy_temporary(track: String) -> bool:
    var cost:int=sim.store_cost(track)
    if phase!="SHOP" or cost<0 or balance<cost:return false
    if not sim.buy_run_upgrade(track):return false
    balance-=cost;persist();_sound("buy");return true

func pause_game() -> void:
    if phase=="PLAY":phase="PAUSE";left_held=false;right_held=false;touch_index=-1;persist()

func _notification(what: int) -> void:
    if not is_visible_in_tree():return
    if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
        pause_game()
        if not profile.is_empty():persist()

func _process(delta: float) -> void:
    if not is_visible_in_tree():return
    ui_time+=delta;notice_clock=maxf(0,notice_clock-delta)
    for particle in particles.duplicate():
        particle.pos+=particle.vel*delta;particle.life-=delta
        if float(particle.life)<=0:particles.erase(particle)
    for label in floats.duplicate():
        label.y-=delta*24;label.life-=delta
        if float(label.life)<=0:floats.erase(label)
    if phase=="PLAY":
        if left_held!=right_held:
            var axis:float=-1.0 if left_held else 1.0
            if sim.effects.has("reverse"):axis=-axis
            sim.target_x=clampf(sim.target_x+axis*510.0*delta,Simulation.LEFT,Simulation.RIGHT)
        sim.step(delta)
        _settle_events()
        save_clock+=delta
        if save_clock>=5.0:persist()
    queue_redraw()

func _settle_events() -> void:
    var gain:int=maxi(0,int(sim.earned)-credited_earned)
    if challenge_mode or not pay_brick_rewards:gain=0
    balance+=gain;profile.total_earned=int(profile.total_earned)+gain;credited_earned=int(sim.earned)
    profile.bricks=int(profile.bricks)+maxi(0,int(sim.destroyed)-credited_destroyed);credited_destroyed=int(sim.destroyed)
    profile.best=maxi(int(profile.best),int(sim.stage))
    var sounds:=0
    for event in sim.events:
        var kind:=String(event.kind)
        if kind=="break":
            for i in 9:
                if particles.size()<280:
                    var angle:=float(i)*TAU/9+ui_time
                    particles.append({"pos":Vector2(float(event.x),float(event.y)),"vel":Vector2(cos(angle),sin(angle))*75.0,"life":.4+float(i%3)*.1,"color":PINK if i%2 else CYAN})
            floats.append({"x":event.x,"y":event.y,"text":"NODE" if challenge_mode or not pay_brick_rewards else "+%d" % int(event.cash),"life":.9,"color":GOLD})
        elif kind=="effect":
            notice=String(EFFECT_LABELS.get(event.effect,event.effect));notice_clock=2.2
        elif kind=="miss":notice="TRACE HIT // CREDITS SAFE";notice_clock=2.0
        if sounds<3 and kind in ["hit","break","paddle","miss","effect","clear"]:_sound(kind);sounds+=1
    sim.events.clear()
    if sim.state=="clear":
        if cleared_stage!=int(sim.stage):profile.clears=int(profile.clears)+1;cleared_stage=int(sim.stage)
        phase="SHOP";persist()
        if challenge_mode and not challenge_settled:challenge_settled=true;challenge_finished.emit(true)
    elif sim.state=="dead":
        if not death_recorded:profile.deaths=int(profile.deaths)+1;death_recorded=true
        phase="DEAD";persist()
        if challenge_mode and not challenge_settled:challenge_settled=true;challenge_finished.emit(false)

func _move_paddle(x: float) -> void:
    sim.target_x=Simulation.LEFT+Simulation.RIGHT-x if sim.effects.has("reverse") else x

func _input(event: InputEvent) -> void:
    if not is_visible_in_tree() or event.device==InputEvent.DEVICE_ID_EMULATION:return
    if event is InputEventKey:
        if event.keycode in [KEY_A,KEY_LEFT]:left_held=event.pressed
        if event.keycode in [KEY_D,KEY_RIGHT]:right_held=event.pressed
        if not event.pressed or event.echo:return
        if event.keycode in [KEY_ESCAPE,KEY_P]:
            if phase=="PLAY":pause_game()
            elif phase=="PAUSE":phase="PLAY"
        elif event.keycode==KEY_SPACE and phase=="PLAY":sim.launch();sim.fire_laser()
    elif event is InputEventMouseMotion and phase=="PLAY":_move_paddle(event.position.x)
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:_tap(event.position)
    elif event is InputEventScreenTouch:
        if event.pressed:
            if phase=="PLAY" and Rect2(18,126,354,588).has_point(event.position) and touch_index<0:touch_index=event.index;_move_paddle(event.position.x);sim.launch()
            else:_tap(event.position)
        elif touch_index==event.index:touch_index=-1
    elif event is InputEventScreenDrag and phase=="PLAY" and event.index==touch_index:_move_paddle(event.position.x)

func _tap(pos: Vector2) -> void:
    if challenge_mode and phase=="PAUSE":
        if Rect2(28,310,334,58).has_point(pos):phase="PLAY"
        elif Rect2(28,390,334,58).has_point(pos):persist()
        elif Rect2(28,470,334,58).has_point(pos):
            if not challenge_settled:challenge_settled=true;challenge_finished.emit(false)
        return
    if phase=="PLAY":
        if Rect2(298,24,74,44).has_point(pos) or Rect2(266,754,106,52).has_point(pos):pause_game()
        elif Rect2(18,754,106,52).has_point(pos):sim.launch()
        elif Rect2(134,754,122,52).has_point(pos):sim.fire_laser()
        else:_move_paddle(pos.x);sim.launch();sim.fire_laser()
        return
    if phase=="PROFILES":
        for i in 3:
            if Rect2(28,220+i*138,334,112).has_point(pos):persist();load_slot(i+1);return
        if Rect2(28,730,334,54).has_point(pos):phase="TITLE"
        return
    if phase in ["RESEARCH","SHOP"]:
        for i in Simulation.TRACKS.size():
            if Rect2(24,208+i*65,342,58).has_point(pos):
                if phase=="RESEARCH":buy_research(Simulation.TRACKS[i])
                else:buy_temporary(Simulation.TRACKS[i])
                return
        if Rect2(24,642,342,60).has_point(pos):
            if phase=="SHOP":sim.next_stage();phase="PLAY";persist()
            else:phase="TITLE"
        elif phase=="SHOP" and Rect2(24,718,342,52).has_point(pos):phase="TITLE";persist()
        return
    if phase=="PAUSE":
        if Rect2(28,310,334,58).has_point(pos):phase="PLAY"
        elif Rect2(28,390,334,58).has_point(pos):persist();notice="GAME SAVED";notice_clock=2
        elif Rect2(28,470,334,58).has_point(pos):phase="TITLE";persist()
        return
    # Title and death share the same profile/research navigation.
    if Rect2(28,350,334,58).has_point(pos):resume_run()
    elif Rect2(28,422,334,58).has_point(pos):
        if not sim.bricks.is_empty() and sim.state in ["play","ready","clear"] and not confirm_new:confirm_new=true
        else:start_new_run()
    elif Rect2(28,494,334,58).has_point(pos):phase="RESEARCH";confirm_new=false
    elif Rect2(28,566,334,58).has_point(pos):
        persist()
        if embedded:exit_requested.emit()
        else:phase="PROFILES"
    elif Rect2(28,638,334,48).has_point(pos):sound_on=not sound_on;_sync_audio();persist()

func _setup_audio() -> void:
    for i in 6:
        var voice:=AudioStreamPlayer.new();add_child(voice);voices.append(voice)
    for key in ["hit","break","paddle","miss","effect","clear","buy"]:
        var frequency:float={"hit":680.0,"break":1050.0,"paddle":330.0,"miss":95.0,"effect":880.0,"clear":1320.0,"buy":990.0}[key]
        var duration:=.13 if key in ["clear","miss"] else .045
        var samples:=int(22050*duration)
        var data:=PackedByteArray();data.resize(samples*2)
        for i in samples:
            var t:=float(i)/22050
            var amplitude:=sin(TAU*frequency*t)*pow(1-float(i)/samples,2)*.28
            data.encode_s16(i*2,int(amplitude*32767))
        var tone:=AudioStreamWAV.new();tone.format=AudioStreamWAV.FORMAT_16_BITS;tone.mix_rate=22050;tone.data=data;tones[key]=tone
    if not embedded:
        music_player=AudioStreamPlayer.new();music_player.name="FirewallMusic";music_player.stream=load("res://assets/do_androids_dream.ogg");music_player.stream.loop=true;music_player.volume_db=-15
        add_child(music_player);music_player.play()
    _sync_audio()

func _exit_tree() -> void:
    for voice in voices:voice.stop()
    if is_instance_valid(music_player):music_player.stop()

func _sync_audio() -> void:
    if is_instance_valid(music_player):music_player.stream_paused=not sound_on

func _sound(kind: String) -> void:
    if not sound_on or voices.is_empty() or not tones.has(kind):return
    var voice:AudioStreamPlayer=voices[voice_index%voices.size()];voice_index+=1
    voice.stream=tones[kind];voice.volume_db=-12;voice.play()

func _text(value: String, pos: Vector2, size: int, color: Color = CYAN) -> void:
    draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _center(value: String, y: float, size: int, color: Color = CYAN) -> void:
    var width:=ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
    _text(value,Vector2((W-width)*.5,y),size,color)

func _panel(rect: Rect2, color: Color = CYAN, fill: Color = Color("0e1c2b")) -> void:
    draw_rect(rect.grow(3),Color(color,.055));draw_rect(rect,fill);draw_rect(rect,Color(color,.65),false,1.5)
    for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:draw_circle(corner,2,color)

func _button(rect: Rect2, label: String, enabled: bool = true, color: Color = CYAN) -> void:
    _panel(rect,color if enabled else MUTED,Color("132b3a") if enabled else Color("0b1520"))
    var size:=16 if label.length()<31 else 12
    var width:=ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
    _text(label,Vector2(rect.get_center().x-width*.5,rect.get_center().y+size*.35),size,color if enabled else MUTED)

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H),Color("080b14"))
    for x in range(0,391,26):draw_line(Vector2(x,0),Vector2(x,H),Color("102131"),1)
    for y in range(-26,870,26):draw_line(Vector2(0,y+fmod(ui_time*8,26)),Vector2(W,y+fmod(ui_time*8,26)),Color("102131"),1)
    if phase in ["PLAY","PAUSE"]:
        _draw_board()
        if phase=="PAUSE":
            draw_rect(Rect2(0,0,W,H),Color(0.02,.03,.06,.90))
            _center("CONNECTION PAUSED",236,25)
            _center("CREDITS SAFE: %d" % balance,272,17,GOLD)
            _button(Rect2(28,310,334,58),"RESUME")
            _button(Rect2(28,390,334,58),"SAVE GAME")
            _button(Rect2(28,470,334,58),"ABORT HACK / RETURN TO FIELD" if challenge_mode else "SAVE / MAIN MENU")
            if notice_clock>0:_center(notice,600,12,GREEN)
        return
    if phase=="PROFILES":_draw_profiles();return
    if phase in ["RESEARCH","SHOP"]:_draw_upgrades();return
    _center("DMC ODDWORKS // NEON ARCADE",48,10,MUTED)
    _center("NEON",117,48)
    _center("FIREWALL",177,48,PINK)
    _center("PRACTICE / RESEARCH SUPPORTS FIELD HACKS" if not pay_brick_rewards else "BREAK THE WALL. KEEP THE CREDITS.",216,11,MUTED)
    _panel(Rect2(28,239,334,86),GOLD)
    _center("CREDITS %07d" % balance,269,22,GOLD)
    _center("%s   BEST L%d   CLEARS %d" % ["CAREER LINK" if embedded else "PROFILE %d" % slot,int(profile.get("best",1)),int(profile.get("clears",0))],297,12,MUTED)
    var can_continue:bool=not sim.bricks.is_empty() and sim.state!="dead"
    _button(Rect2(28,350,334,58),"CONTINUE / LOAD SAVE",can_continue)
    _button(Rect2(28,422,334,58),"CONFIRM NEW RUN? CREDITS SAFE" if confirm_new else "NEW RUN",true,PINK)
    _button(Rect2(28,494,334,58),"PERMANENT RESEARCH")
    _button(Rect2(28,566,334,58),"SAVE / RETURN TO PORT" if embedded else "SAVE / LOAD PROFILES")
    _button(Rect2(28,638,334,48),("TERMINAL SFX " if embedded else "SOUND ")+("ON" if sound_on else "OFF"),true,MUTED)
    if phase=="DEAD":_center("TRACE COMPLETE // CREDITS KEPT",724,15,RED)
    else:_center("MOVE: MOUSE / DRAG / A-D / ARROWS",724,10,MUTED)
    _center("CLICK / SPACE LAUNCHES. SPACE ALSO FIRES LASERS.",747,9,MUTED)
    _center("P / ESC PAUSES. AUTOSAVE + MANUAL SAVE.",769,9,MUTED)
    if notice_clock>0:_center(notice,808,9,GREEN)

func _draw_profiles() -> void:
    _center("SAVE / LOAD PROFILES",105,26)
    _center("Separate credits, research and active runs",145,12,MUTED)
    for i in 3:
        var cfg:=ConfigFile.new();var exists:=cfg.load(_slot_path(i+1))==OK
        var data:Dictionary=decode_profile(cfg.get_value("profile","data",{})) if exists else {}
        var rect:=Rect2(28,220+i*138,334,112);_panel(rect,PINK if i+1==slot else CYAN)
        _text("PROFILE %d%s" % [i+1," / ACTIVE" if i+1==slot else ""],rect.position+Vector2(16,30),20)
        _text("%d CR / BEST L%d" % [int(cfg.get_value("profile","credits",0)),int(data.get("best",1))] if exists else "EMPTY // CREATE PROFILE",rect.position+Vector2(16,64),15,GOLD)
        _text("TAP TO LOAD" if exists else "Starts with no credits or research",rect.position+Vector2(16,91),11,MUTED)
    _button(Rect2(28,730,334,54),"BACK")

func _draw_upgrades() -> void:
    var research:=phase=="RESEARCH"
    _center("PERMANENT RESEARCH" if research else "LEVEL %d DECRYPTED" % sim.stage,58,25,CYAN if research else GREEN)
    _center("CREDITS %07d" % balance,98,22,GOLD)
    _center("Applied to your next NEW RUN" if research else "RUN STORE // lasts until this run ends",133,11,MUTED)
    _center("Research survives death and new runs" if research else "Permanent research + run upgrades stack",156,10,MUTED)
    for i in Simulation.TRACKS.size():
        var track:String=Simulation.TRACKS[i]
        var levels:Dictionary=profile.research if research else sim.temporary
        var cost:int=Simulation.research_cost(track,levels) if research else sim.store_cost(track)
        var rect:=Rect2(24,208+i*65,342,58);_panel(rect,CYAN if research else PINK)
        _text("%s  %d/%d" % [LABELS[track],int(levels.get(track,0)),int(Simulation.CAPS[track])],rect.position+Vector2(10,22),13)
        _text(DESCRIPTIONS[track],rect.position+Vector2(10,45),10,MUTED)
        _text("MAX" if cost<0 else "%d CR" % cost,rect.position+Vector2(258,36),12,GREEN if cost<0 or balance>=cost else RED)
    _button(Rect2(24,642,342,60),"BACK" if research else "CONNECT TO LEVEL %d" % (sim.stage+1),true,GREEN)
    if not research:_button(Rect2(24,718,342,52),"SAVE / MAIN MENU")
    _center("DEATH KEEPS CREDITS AND PERMANENT RESEARCH",807,9,MUTED)

func _draw_board() -> void:
    _text("FIREWALL / %02d" % sim.stage,Vector2(18,40),21)
    _text("%07d CR" % balance,Vector2(18,66),17,GOLD)
    _button(Rect2(298,24,74,44),"PAUSE")
    _text("RETRY %d  SHIELD %d  DMG %d  BALLS %d" % [sim.lives,sim.shields,sim.ball_damage(),sim.balls.size()],Vector2(18,94),11,MUTED)
    var remaining_time:float=maxf(0,sim.trace_limit-sim.stage_time)
    _text("TRACE",Vector2(18,117),9,RED)
    draw_rect(Rect2(67,108,252,5),Color("3b263c"));draw_rect(Rect2(67,108,252*remaining_time/sim.trace_limit,5),PINK)
    _text("%ds" % int(ceil(remaining_time)),Vector2(330,116),10,MUTED)
    _panel(Rect2(Simulation.LEFT,Simulation.TOP,Simulation.RIGHT-Simulation.LEFT,Simulation.BOTTOM-Simulation.TOP),Color("244859"),Color(0.02,.045,.07,.85))
    var locked:bool=sim.relay_alive()
    for brick in sim.bricks:
        if not bool(brick.active):continue
        var kind:=String(brick.kind)
        var color:Color={"normal":CYAN,"armor":PINK,"cache":GOLD,"blast":Color("ff9c60"),"prism":Color("b999ff"),"relay":GREEN,"locked":RED if locked else CYAN,"phase":Color("b999ff"),"moving":CYAN,"steel":MUTED,"turret":RED}.get(kind,CYAN)
        var rect:=Rect2(float(brick.x),float(brick.y),float(brick.w),float(brick.h))
        if not sim.brick_solid(brick):color.a=.22
        draw_rect(rect.grow(2),Color(color,.08));draw_rect(rect,Color(color,.16));draw_rect(rect,color,false,1.3)
        var marker:String={"cache":"?","blast":"+","prism":"Y","relay":"O","locked":"#" if locked else "-","phase":"~","moving":"=","steel":"X","turret":"v"}.get(kind,"")
        if not marker.is_empty():_text(marker,rect.position+Vector2(rect.size.x*.5-4,16),13,color)
        if kind!="steel":
            var ratio:=clampf(float(brick.hp)/float(brick.max_hp),0,1)
            draw_line(rect.position+Vector2(3,rect.size.y-3),rect.position+Vector2(3+(rect.size.x-6)*ratio,rect.size.y-3),color,2)
            if int(brick.max_hp)>1:_text(str(int(brick.hp)),rect.position+Vector2(3,10),8,color)
    if sim.shields>0:draw_line(Vector2(20,706),Vector2(370,706),GREEN,2)
    var paddle:=Rect2(sim.paddle_x-sim.paddle_width()*.5,Simulation.PADDLE_Y,sim.paddle_width(),11)
    _panel(paddle,PINK if sim.effects.has("reverse") else CYAN,Color("225569"))
    if sim.laser_ammo>0:
        for side in [-1,1]:draw_rect(Rect2(sim.paddle_x+side*(sim.paddle_width()*.5-5)-2,Simulation.PADDLE_Y-8,4,9),PINK)
    for ball in sim.balls:
        var pos:=Vector2(float(ball.x),float(ball.y));draw_circle(pos,11,Color(CYAN,.09));draw_circle(pos,7,CYAN);draw_circle(pos,3,Color.WHITE)
        if not bool(ball.held):draw_line(pos,pos-Vector2(float(ball.dx),float(ball.dy))*17,Color(CYAN,.24),4)
    for drop in sim.drops:
        var bad:bool=String(drop.kind) in ["shrink","fast","reverse","trace"]
        var color:Color=RED if bad else GREEN
        var pos:=Vector2(float(drop.x),float(drop.y));draw_circle(pos,10,Color(color,.20));draw_arc(pos,10,0,TAU,16,color,1.5)
        _text("!" if bad else "+",pos+Vector2(-4,4),13,color)
    for bolt in sim.bolts:draw_line(Vector2(float(bolt.x),float(bolt.y)-5),Vector2(float(bolt.x),float(bolt.y)+5),RED,3)
    for laser in sim.lasers:draw_line(Vector2(float(laser.x),float(laser.y)),Vector2(float(laser.x),float(laser.y)-12),PINK,2)
    for particle in particles:draw_circle(particle.pos,1.8,Color(particle.color,clampf(float(particle.life)*2,0,1)))
    for label in floats:_text(label.text,Vector2(float(label.x),float(label.y)),11,Color(label.color,clampf(float(label.life)*2,0,1)))
    if sim.state=="ready":_center("CLICK / SPACE / TAP TO LAUNCH",551,13,GREEN)
    _text("%d NODES  /  %d LASER  /  %d MAGNET" % [sim.remaining(),sim.laser_ammo,sim.magnets],Vector2(18,738),11,MUTED)
    _button(Rect2(18,754,106,52),"LAUNCH")
    _button(Rect2(134,754,122,52),"LASER %d" % sim.laser_ammo,sim.laser_ammo>0,PINK)
    _button(Rect2(266,754,106,52),"PAUSE")
    if notice_clock>0:_center(notice,829,11,GOLD)
    else:
        var labels:Array=[]
        for key in sim.effects:labels.append("%s %ds" % [String(key).to_upper(),int(ceil(float(sim.effects[key])))])
        _center(" / ".join(labels).left(53) if not labels.is_empty() else "GREEN + BONUS / RED ! HAZARD // RELAYS UNLOCK #",829,9,MUTED)
