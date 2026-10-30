extends SceneTree
const Career=preload("res://covert/CovertCareer.gd")
const Justice=preload("res://covert/JusticeSystem.gd")
const Guild=preload("res://covert/GuildProgress.gd")
const Prison=preload("res://covert/PrisonLife.gd")
const Ground=preload("res://covert/GroundSimulation.gd")
var failures:Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:failures.append(message);push_error("JUSTICE FAIL: "+message)
func _initialize() -> void:call_deferred("_run")
func advance_life(life: RefCounted,seconds: float) -> void:
    for i in int(ceil(seconds*4)):life.step(.25)
func _run() -> void:
    var legacy:Dictionary=Career.default_profile();legacy.schema=1;legacy.incarcerated=true
    legacy.ground={"kind":"prison"}
    var migrated:Dictionary=Career.decode(legacy)
    check(migrated.captured and not migrated.incarcerated and migrated.justice.sentence.is_empty() and migrated.ground.kind=="mission_escape","legacy captivity is not an invented conviction")
    var g:=Guild.defaults()
    check(Guild.rank(g,"merc")==0,"unranked beginning")
    for i in 3:Guild.award(g,str(i),"merc",1)
    check(Guild.rank(g,"merc")==1 and g.merc==30,"three basic jobs earn associate rank")
    check(Guild.award(g,"1","merc",5)==0 and g.merc==30,"job XP is idempotent")
    var profile:=Career.default_profile();var hard:=Career.offer("test","assassinate",0,5)
    check(not Career.accept(profile,hard),"hard merc work gated")
    profile.guilds.merc=500;check(Career.accept(profile,hard),"qualified merc accepts higher pay tier")
    check(hard.reward>Career.offer("test","assassinate",0,1).reward,"higher difficulty pays more")
    profile=Career.default_profile();check(Career.accept(profile,Career.offer("test","mug",0,5)),"crime requires risk, not guild membership")
    for kind in Career.JOBS:
        profile=Career.default_profile();var job:=Career.offer("test",kind,5,1)
        check(Career.accept(profile,job),"begin job "+kind)
        for task in job.steps:check(Career.advance(profile,task),"causal stage "+kind+":"+task)
        check(Career.settle(profile)==job.reward,"correct reward "+kind)
        check(profile.guilds.merc==(0 if job.criminal else 10),"crime cannot award legitimate guild XP")
    var easy=Ground.new();var tough=Ground.new();easy.new_mission("assault",1,{},1);tough.new_mission("assault",1,{},5)
    check(easy.state.guards.size()==7 and tough.state.guards.size()==19,"tier affects real guard budget")
    check(tough.state.guards[0].hp>easy.state.guards[0].hp,"tier affects actual enemy durability")
    var law:=Justice.defaults();Justice.record(law,"A","container_theft",1);Justice.record(law,"B","terminal_intrusion",2)
    check(Justice.assessment(law,"A").fine==75 and Justice.assessment(law,"B").days==60,"jurisdiction-specific cases")
    var before:Dictionary=law.duplicate(true)
    check(Justice.pay(law,"A",74)==-1 and before==law,"no partial auto-debit or free pardon")
    check(Justice.pay(law,"A",75)==75 and Justice.assessment(law,"B").days==60,"fine resolves only that authority")
    var term:=Justice.sentence(law,"B")
    check(term.days==60 and law.forced_faction=="B" and Justice.pay(law,"B",9999)==-1,"sentence persists instead of becoming an instant fine")
    var life=Prison.new();life.start(term,2)
    check(not life.data.released and life.remaining_days()==60,"no instant sentence completion")
    check(life.act("train"),"training starts")
    advance_life(life,2);check(life.data.fitness==0 and life.data.remaining>0,"activities take real accelerated play time")
    advance_life(life,1);check(life.data.fitness==1,"training earns fitness")
    life.act("socialize","Loa");advance_life(life,2)
    check(life.data.relations.Loa==1,"actual social interaction recorded")
    life.act("work");advance_life(life,4);life.act("check_in");advance_life(life,1)
    check(life.data.wages==5 and life.data.conduct>=3,"work and good conduct accrue")
    life.data.paused=true;var hours:float=life.data.hours;advance_life(life,10)
    check(life.data.hours==hours,"pause cannot consume sentence")
    var restored=Prison.new();check(restored.restore(bytes_to_var(var_to_bytes(life.data))) and restored.data.paused,"prison routine restores paused")
    check(restored.data.fitness==1 and restored.data.relations.Loa==1 and restored.data.wages==5,"routine rewards and relationships persist")
    life.data.paused=false;advance_life(life,14.1)
    check(life.can_escape(),"scheduled escape opportunity appears")
    check(life.begin_escape(),"escape starts actual field transition")
    hours=life.data.hours;advance_life(life,5);check(life.data.hours==hours,"escape sortie cannot also serve prison time")
    var remaining:float=life.remaining_days();life.failed_escape()
    check(life.remaining_days()>=remaining+29.9 and life.data.conduct==0 and life.data.paused,"failed escape extends sentence without resetting served time")
    life.data.paused=false
    for i in 2000:
        life.step(.25)
        if life.data.released:break
    check(life.data.released and life.remaining_days()==0,"full accelerated term finishes")
    check(life.data.remission<=float(term.days)*.2,"good behavior credit bounded")
    Justice.release(law,life.data.served_days);check(Justice.assessment(law,"B").days==0 and law.served==1,"lawful completion discharges case")
    Justice.record(law,"B","robbery",4);Justice.sentence(law,"B");Justice.escape(law,80)
    check(Justice.assessment(law,"B").days==260 and law.escapes==1,"escape keeps unserved term plus new warrant")
    # Root scene: starting resources, route contracts, real crime hooks and custody UI.
    var scene=load("res://main.tscn").instantiate();root.add_child(scene);scene.set_process(false)
    scene._create_new_career(1)
    check(scene.research_credits==0 and scene.bank_balance==0 and scene.starting_weapon=="none" and scene.research_damage==0,"actual new career starts with only basic ship")
    check(not scene.covert_profile.gear.pistol and scene.covert_profile.guilds.trader==0,"no free field gear or guild rank")
    var starter:=-1
    for i in scene.contract_board.size():
        if scene.contract_board[i].get("starter",false):starter=i
    check(starter>=0,"new zero-cash pilot has a starter job")
    if starter>=0:
        var local_destination:String=scene.contract_board[starter].destination
        var single_profile:Dictionary={"destination":local_destination,"destination_faction":"","destination_state":"UNCONTROLLED"}
        check(not scene._best_passenger_profile([single_profile],"").is_empty(),"direct-only routes still offer transportation")
    check(scene._accept_contract(starter) and scene.research_credits==0,"courier has no deposit or equipment charge")
    scene.destination_planet=scene.active_contract.destination;scene.route_active=true;scene.score=0
    scene._arrive_at_destination()
    check(scene.research_credits==160 and scene.covert_profile.guilds.trader==10,"courier earns actual cash and Trader XP")
    check(scene._complete_contract_if_ready()==0 and scene.covert_profile.guilds.trader==10,"completed route cannot award twice")
    var hard_contract:Dictionary=scene.contract_board[0].duplicate(true);hard_contract.guild="trader";hard_contract.required_rank=4
    check(not scene._contract_blocker(hard_contract).is_empty(),"ship contracts obey rank gates")
    check(not scene._player_can_damage_hazard({"kind":1,"owner_faction":"f00"}),"owned crates ignored by default")
    scene.raid_owned_crates=true;check(scene._player_can_damage_hazard({"kind":1,"owner_faction":"f00"}),"explicit raid enables theft targeting")
    var faction:=String(scene.political_world.factions[0].id)
    scene._record_faction_crime(faction,12,0,"container_theft",false)
    check(Justice.assessment(scene.covert_profile.justice,faction).days==30,"real crate-theft hook creates legal case")
    scene.research_credits=10000;scene.bank_balance=333
    var illegal:=""
    for good in scene.PoliticalWorld.RESTRICTED_COMMODITIES:
        if not scene.PoliticalWorld.faction_commodity_legal(scene.political_world,faction,good):illegal=good;break
    scene.cargo[illegal]=1;scene.police_scan_active=true;scene.police_scan_faction_id=faction
    scene.playing=true;scene.encounter_active=true;scene.encounter_mode="police";scene.encounter_faction_id=faction
    var scan:Dictionary=scene._complete_police_scan()
    check(scan.justice_pending and scan.fine==0 and scene.research_credits==10000,"police detection requires real fine-or-jail decision")
    scene._process(0);var view=scene.covert;view.set_process(false)
    check(scene.covert_open and view.phase=="JUSTICE" and not view.data.captured,"law capture opens court, not tactical detention")
    var bill:Dictionary=Justice.assessment(view.data.justice,faction)
    check(view.pay_release() and scene.research_credits==10000-int(bill.fine) and scene.bank_balance==333,"court fine debits only carried cash")
    check(Justice.pending(scene.covert_profile.justice,faction).is_empty(),"fine actually clears assessed cases")
    scene._close_covert();check(scene.playing and scene.run_paused,"fine returns to paused flight")
    scene.covert_profile.gear={"pistol":true,"armor":1}
    scene._record_faction_crime(faction,8,20,"terminal_intrusion",false)
    scene.covert_profile.justice.forced_faction=faction;scene._process(0);view.set_process(false)
    check(view.serve_sentence() and view.phase=="PRISON" and view.data.incarcerated and not view.data.captured,"judicial sentence starts life simulation")
    check(not view.begin_ground("prison_escape"),"escape requires an actual opportunity, not just a method call")
    check(not view.pay_release() and not view.data.gear.pistol,"cannot skip selected sentence; equipment impounded")
    view.prison.act("work")
    for i in 16:view._process(.25)
    view.prison.act("train")
    for i in 12:view._process(.25)
    check(view.prison.data.wages==5 and view.prison.data.fitness==1,"view runs timed activities")
    var served_hours:float=view.prison.data.hours
    scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED);view._process(.25)
    check(view.prison.data.hours==served_hours,"OS suspension pauses sentence")
    scene._save_all_state();scene._close_covert();scene._load_career(1);scene._process(0);view.set_process(false)
    check(view.phase=="PRISON" and view.prison.data.paused and view.prison.data.hours==served_hours,"reload cannot bypass sentence into space")
    check(not view.begin_ground("port") and not view.accept("assault"),"convict cannot launch outside work")
    view.prison.data.paused=false
    for i in 2500:
        view._process(.25)
        if not view.data.incarcerated:break
    check(not view.data.incarcerated and view.data.justice.served==1 and view.data.gear.pistol,"served term lawfully releases and returns equipment")
    check(view.data.fitness==1 and view.cash==10000-int(bill.fine)+5 and scene.bank_balance==333,"training and earned wages settle once; bank protected")
    var wallet:int=view.cash;view._release_sentence();check(view.cash==wallet,"release cannot pay wages twice")
    scene._close_covert();scene.playing=false;scene.route_active=false;scene.run_paused=false;scene.hub_open=true
    scene._open_covert();view.set_process(false)
    check(view.accept("investigate"),"investigation offered to novice merc")
    check(not view.file_charges(),"charges require actual evidence stages")
    var filing_steps:Array=view.data.active.steps.duplicate()
    filing_steps.pop_back()
    for task in filing_steps:Career.advance(view.data,task)
    check(view.file_charges() and view.data.prosecutions.size()==1 and view.data.prosecutions[0].status=="charges_filed","filing creates a persistent prosecution record")
    wallet=view.cash;check(not view.file_charges() and view.cash==wallet,"same prosecution cannot pay twice")
    view.accept("mug");view.begin_ground("mug")
    view.sim.state.pos=view.sim.state.npcs[0].pos;view.sim.state.drawn=true
    var crimes_before:int=view.data.justice.cases.size();view.sim.interact();view._process(.01)
    check(view.sim.state.robbed and view.data.justice.cases.size()==crimes_before+1,"physical citizen robbery reports actual crime once")
    view.sim.interact();view._process(.01);check(view.data.justice.cases.size()==crimes_before+1,"same victim cannot duplicate charges")
    view.sim.state.hp=0;view._process(.01)
    check(view.data.captured and not view.data.incarcerated and view.phase=="GROUND" and view.sim.state.kind=="mission_escape","mission capture stays a Breach escape, no new prison term")
    check(view.data.justice.sentence.is_empty() and not view.pay_release(),"tactical capture offers no court fine shortcut")
    scene._save_all_state();scene._close_covert();scene._create_new_career(2)
    check(scene.covert_profile.justice.cases.is_empty() and scene.covert_profile.guilds.trader==0,"justice and ranks isolated by career")
    scene.queue_free();await process_frame;await create_timer(.1).timeout
    if failures.is_empty():print("NEON JUSTICE OK: %d checks, zero start, guild gates, crime, fine-or-sentence, accelerated prison life, save continuity, separate mission captivity"%checks);call_deferred("quit",0)
    else:print("NEON JUSTICE FAIL: "+str(failures));call_deferred("quit",1)
