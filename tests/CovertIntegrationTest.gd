extends SceneTree
const Career=preload("res://covert/CovertCareer.gd")
const Ground=preload("res://covert/GroundSimulation.gd")
var failures:Array[String]=[]
var checks:=0
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures.append(text);push_error("COVERT FAIL: "+text)
func _initialize() -> void:call_deferred("_run")
func advance_time(sim: RefCounted,seconds: float) -> void:
    for i in int(ceil(seconds/.02)):sim.step(.02,Vector2.ZERO,Vector2.ZERO,false)
func _run() -> void:
    # Case graphs enforce causality, direct combat skips detective busywork.
    for kind in ["track","recover","assault"]:
        var data:Dictionary=Career.default_profile();var job:Dictionary=Career.offer("port-a",kind,0)
        check(Career.accept(data,job),"accept "+kind)
        check(not Career.accept(data,job),"one active job")
        check(Career.settle(data)==0,"cannot pay incomplete case")
        var stages:Array=["rumor","tail","intel","bounty"] if kind=="track" else ["rumor","intel"] if kind=="recover" else ["assault"]
        for task in stages:
            check(Career.next_task(data.active)==task,"next objective "+task)
            check(not Career.advance(data,"invented"),"reject unrelated event")
            check(Career.advance(data,task),"real objective advances")
        check(Career.settle(data)==job.reward,"exact final payout")
        data.active=job.duplicate(true);data.active.stage=stages.size()
        check(Career.settle(data)==0,"replayed ID cannot pay twice")
        check(data.journal.size()>=stages.size()+2,"source and consequence journal")
    # Geometry/routes are full-level and independent of rendering distance.
    var ground=Ground.new();ground.new_mission("intel",2468,{"pistol":true,"armor":1})
    var path:Array=ground.route_to(ground.center(6),ground.center(2))
    check(path.size()>25,"navigation spans entire level")
    for point in path:check(ground.walkable(point),"route stays on connected floor")
    var start:Vector2=ground.state.guards[6].pos
    advance_time(ground,3)
    check(ground.state.guards[6].pos.distance_to(start)>50,"far off-camera guard remains active")
    var angle:float=ground.state.guards[0].angle;advance_time(ground,3)
    check(absf(angle_difference(angle,ground.state.guards[0].angle))>1,"post guard turns by quarters")
    ground.state.paused=true;var frozen:Dictionary=ground.snapshot();advance_time(ground,1)
    check(frozen==ground.snapshot(),"pause freezes all simulation")
    ground.state.paused=false;ground.state.drawn=false
    for pistol in [true,false]:
        ground.state.pistol=pistol;ground.state.cool=0
        check(not ground.attack(Vector2.UP),"holstered pistol and hands cannot attack")
    ground.toggle_draw();ground.state.cool=0
    check(ground.attack(Vector2.UP),"drawn hands attack")
    var restored=Ground.new();check(restored.restore(bytes_to_var(var_to_bytes(ground.snapshot()))),"serializable native mission")
    check(restored.state.paused and restored.state.pos==ground.state.pos,"restores exact position paused")
    # Listening is earned by proximity, holstering and remaining unnoticed.
    ground.new_mission("tail",10,{});ground.state.guards=[]
    advance_time(ground,7);check(not ground.state.intel,"cannot eavesdrop remotely")
    ground.state.pos=ground.center(2);ground.state.drawn=true;advance_time(ground,7)
    check(not ground.state.intel,"drawn weapon blocks covert listening")
    ground.state.drawn=false;advance_time(ground,5)
    check(not ground.state.intel,"full six seconds required")
    advance_time(ground,1.1);check(ground.state.intel,"real listening yields lead")
    ground.state.pos=ground.center(6);advance_time(ground,4)
    check(ground.state.result=="","eight second hold not five")
    ground.state.pos+=Vector2(60,0);ground.step(.02,Vector2.ZERO,Vector2.ZERO,false)
    check(ground.state.exit_hold==0,"leaving extraction circle resets hold")
    ground.state.pos=ground.center(6);advance_time(ground,8.1)
    check(ground.state.result=="extracted","full hold extracts")
    ground.new_mission("prison",15,{"pistol":true,"armor":2})
    check(not ground.state.pistol and not ground.state.drawn and ground.state.max_hp==100,"custody confiscates weapons and armor")
    check(not ground.objective_ready(),"locked prison exit")
    ground.state.pos=ground.center(3);check(ground.interact()=="badge" and ground.objective_ready(),"physical badge bypasses lock")
    ground.state.pos=ground.center(1);ground.interact();check(ground.state.pistol and ground.state.gear_recovered,"recover impounded weapon physically")
    # Wire the actual root scene: career currency, hardware toggles and isolation.
    var scene=load("res://main.tscn").instantiate();root.add_child(scene);scene.set_process(false)
    check(not scene._open_covert(),"career required")
    scene._create_new_career(1);scene.research_credits=2200;scene.bank_balance=444
    check(scene._open_covert(),"port button opens native system")
    var view=scene.covert;view.set_process(false)
    check(view.buy("pistol") and view.buy("armor"),"field equipment purchases")
    check(scene.research_credits==1600 and scene.bank_balance==444,"one real wallet, protected bank")
    check(view.accept("track"),"actual career accepts investigation")
    check(view.begin_ground("port"),"real walkable port")
    view.sim.state.pos=view.sim.state.npcs[0].pos;view.sim.state.drawn=true
    view.sim.interact();view._process(.02);check(view.current_task()=="rumor","armed contact refuses to talk")
    view.sim.state.drawn=false;view.sim.interact();view._process(.02)
    check(view.current_task()=="tail","contact advances actual job")
    view.return_to_board();check(view.begin_ground("tail"),"follow lead into on-foot mission")
    view.sim.state.drawn=true;view.sim.state.pistol=true;view.sim.state.cool=0
    var motion:=InputEventMouseMotion.new();motion.position=Vector2(245,385)
    view._input(motion);view._process(.02)
    check(view.sim.state.bullets.is_empty(),"mouse aim alone must not fire")
    view.sim.state.drawn=false
    view.sim.state.guards=[];view.sim.state.pos=view.sim.center(2);advance_time(view.sim,6.1)
    view.sim.state.pos=view.sim.center(6);advance_time(view.sim,8.1);view._process(.02)
    check(view.current_task()=="intel","extracted conversation unlocks safehouse")
    check(view.begin_ground("intel"),"safehouse mission opens")
    view.sim.state.pos=view.sim.center(2);view.sim.interact();view._process(.02)
    check(view.hack.visible and view.hack.challenge_mode,"actual Firewall minigame runs inside safehouse")
    view.hack.set_process(false)
    var challenge_before:Dictionary=view.hack.sim.snapshot()
    scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED);scene._close_covert()
    scene._load_career(1);scene._open_covert();view.set_process(false)
    check(view.sim.state.paused and not view.sim.state.hacked,"suspended safehouse cannot auto-complete")
    view._start_hack();view.hack.set_process(false)
    check(view.hack.sim.snapshot()==challenge_before,"same interrupted Firewall board restored")
    var wallet:int=scene.research_credits
    # Damage actual simulation bricks; the same clear handler used by physics resolves the terminal.
    for i in view.hack.sim.bricks.size():view.hack.sim.damage_brick(i,999)
    view.hack._settle_events()
    check(view.sim.state.hacked and not view.hack.visible,"clearing Firewall opens actual terminal")
    check(scene.research_credits==wallet,"challenge cannot mint arcade cash")
    view.sim.state.guards=[];view.sim.state.pos=view.sim.center(6);advance_time(view.sim,8.1);view._process(.02)
    check(view.current_task()=="bounty","safehouse records identify target")
    view.begin_ground("bounty");view.sim.state.guards[-1].hp=0
    view.sim.state.pos=view.sim.center(6)
    for g in view.sim.state.guards:g.hp=0
    advance_time(view.sim,8.1);view._process(.02)
    check(view.data.completed==1 and scene.research_credits==wallet+900,"full case pays once at extraction")
    wallet=scene.research_credits
    view.accept("assault");view.begin_ground("assault");view.sim.state.hp=0;view._process(.02)
    check(view.data.incarcerated and view.sim.state.kind=="prison","capture enters playable custody")
    check(not view.return_to_board(),"cannot bypass prison through retreat")
    check(view.cash==wallet and scene.bank_balance==444,"arrest cannot raid protected bank")
    scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
    check(view.sim.state.paused,"OS suspension pauses ground world")
    var saved:Dictionary=view.sim.snapshot();scene._close_covert()
    scene._create_new_career(2);scene.research_credits=987;scene._save_all_state()
    check(scene.covert_profile.active.is_empty() and not scene.covert_profile.incarcerated,"career isolation")
    scene._load_career(1);scene._open_covert();view.set_process(false)
    check(view.data.incarcerated and view.sim.state.pos==saved.pos and view.sim.state.paused,"custody and field state survive reload")
    view.sim.state.paused=false;view.sim.state.pos=view.sim.center(1);view.sim.interact()
    view.sim.state.pos=view.sim.center(3);view.sim.interact()
    for g in view.sim.state.guards:g.hp=0
    view.sim.state.pos=view.sim.center(6);advance_time(view.sim,8.1);view._process(.02)
    check(not view.data.incarcerated and view.data.gear.pistol and view.data.gear.armor==1,"escape restores recovered gear")
    check(not view.data.active.is_empty() and view.current_task()=="assault","prison preserves unfinished contract")
    scene._close_covert();scene.playing=true;scene.current_weapon="single";scene.weapon_systems_online=false
    scene.shots.clear();scene._fire_weapon();check(scene.shots.is_empty(),"OFF blocks flight projectiles")
    scene._toggle_weapon_systems();scene._fire_weapon();check(not scene.shots.is_empty(),"ON restores weapons")
    scene._toggle_weapon_systems();scene._save_run_snapshot();scene.weapon_systems_online=true
    check(scene._load_run_snapshot() and not scene.weapon_systems_online,"flight systems setting survives reload")
    check(scene.SYSTEMS_RECT.size.y>=44 and not scene.SYSTEMS_RECT.intersects(scene.PAUSE_RECT),"touch toggle target accessible")
    check(not scene._open_covert(),"cannot teleport from flight into operations")
    scene.queue_free();await process_frame;await create_timer(.1).timeout
    if failures.is_empty():print("NEON COVERT OK: %d checks, causal cases, native ground, custody, hacking, wallet, saves, flight switches"%checks);call_deferred("quit",0)
    else:print("NEON COVERT FAIL: "+str(failures));call_deferred("quit",1)
