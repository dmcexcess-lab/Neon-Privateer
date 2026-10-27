extends SceneTree
var failures:Array[String]=[]
var checks:=0
func check(value: bool,message: String) -> void:
    checks+=1
    if not value:failures.append(message);push_error("FIREWALL INTEGRATION FAIL: "+message)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
    var scene=load("res://main.tscn").instantiate();root.add_child(scene);scene.set_process(false)
    check(not scene._open_firewall(),"career required")
    scene._create_new_career(1);scene.bank_balance=444;scene.research_credits=2200
    var planet:String=scene.current_planet
    var world:Dictionary=scene.political_world.duplicate(true)
    check(scene._open_firewall() and scene.firewall_open and scene.firewall.visible,"actual native game opens from dock")
    check(scene.firewall.embedded and scene.firewall.music_player==null,"embedded game cannot create overlapping standalone music")
    var view=scene.firewall
    view.set_process(false);view.phase="RESEARCH"
    check(view.buy_research("width"),"research purchase")
    check(scene.research_credits==1750 and scene.firewall_profile.research.width==1,"upgrade uses actual career cash")
    view.start_new_run(1234);view.sim.damage_brick(0,99);view._settle_events()
    var cash:int=scene.research_credits
    # Payout is live and must be flushed with its run ledger for reload safety.
    view.persist()
    check(scene.research_credits>1750 and scene.bank_balance==444,"earnings use carried cash without moving bank")
    cash=scene.research_credits
    var progress:Dictionary=view.sim.snapshot()
    scene._close_firewall()
    check(not scene.firewall_open and not view.visible and scene.hub_open and scene.current_planet==planet,"return to correct dock")
    check(scene.political_world==world,"arcade terminal does not reroll or replace political world")
    scene._create_new_career(2)
    check(scene.firewall_profile.research.width==0,"career research isolation")
    scene.research_credits=987;scene._save_all_state()
    scene._load_career(1);check(scene.research_credits==cash and scene.bank_balance==444,"exact wallet restored")
    check(scene._open_firewall(),"terminal reopens after reload")
    check(scene.firewall.sim.snapshot()==progress,"same active native run restored")
    check(scene.firewall.phase=="TITLE","reload cannot advance or award a run in the background")
    scene.firewall._settle_events();scene.firewall.persist()
    check(scene.research_credits==cash,"settling restored progress cannot duplicate cash")
    scene.firewall.resume_run();scene.firewall.sim.lives=1;scene.firewall.sim.lose_life();scene.firewall._settle_events()
    check(scene.research_credits==cash and scene.bank_balance==444,"hacking failure keeps cash and bank")
    scene._close_firewall()
    var cash_before:int=scene.research_credits
    # Hidden terminal focus notifications must never write an obsolete wallet.
    scene.research_credits+=100;scene.firewall._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(scene.research_credits==cash_before+100,"closed terminal cannot overwrite career on focus loss")
    scene._save_all_state();scene._load_career(2)
    check(scene.research_credits==987 and scene.firewall_profile.research.width==0,"second career retained")
    scene.playing=true;check(not scene._open_firewall(),"cannot open terminal during spaceflight");scene.playing=false
    scene.hub_open=true
    var terminal_rect:Rect2=scene.HUB_FIREWALL_RECT
    check(terminal_rect.size.y>=44 and terminal_rect.end.y<=scene.H,"terminal touch target fits viewport")
    scene._handle_hub_tap(terminal_rect.get_center());check(scene.firewall_open,"port button launches game")
    scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
    check(scene.firewall.phase!="PLAY","backgrounding pauses terminal")
    scene._close_firewall();scene.queue_free();await process_frame;await create_timer(.2).timeout
    if failures.is_empty():print("NEON FIREWALL INTEGRATION OK: %d checks, shared economy, career isolation, run continuity, exactly-once rewards, returns and interruptions" % checks);call_deferred("quit",0)
    else:print("NEON FIREWALL INTEGRATION FAIL: "+str(failures));call_deferred("quit",1)
