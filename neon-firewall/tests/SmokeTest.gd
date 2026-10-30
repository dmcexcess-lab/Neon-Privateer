extends SceneTree
const Simulation=preload("../scripts/FirewallSimulation.gd")
const Game=preload("../scripts/FirewallGame.gd")
var failures:Array[String]=[]
var checks:=0
func check(value: bool, message: String) -> void:
    checks+=1
    if not value:failures.append(message);push_error("FIREWALL FAIL: "+message)
func _initialize() -> void:call_deferred("_run")
func brick(x: float,y: float,kind: String="normal",hp: int=1) -> Dictionary:
    return {"x":x,"base_x":x,"y":y,"w":40.0,"h":23.0,"hp":hp,"max_hp":hp,"kind":kind,"active":true,"phase":0.0,"row":0,"reward":"shield","cache_cash":50}
func scenario():
    var s=Simulation.new();s.new_run({},7);s.bricks=[brick(100,200),brick(280,180)];s.launch();s.events.clear();return s
func _run() -> void:
    var totals:Dictionary={}
    var kinds:Dictionary={}
    for level in [1,4,8,16,40]:
        var cells:=0
        for seed_number in 80:
            var a=Simulation.new();a.new_run({},seed_number+1);a.stage=level;a.generate_stage()
            var b=Simulation.new();b.new_run({},seed_number+1);b.stage=level;b.generate_stage()
            check(a.bricks==b.bricks,"deterministic procedural stage")
            check(a.remaining()>10 and a.bricks.size()<=120,"bounded mobile-sized generated population")
            cells+=a.bricks.size()
            for node in a.bricks:
                kinds[node.kind]=true
                check(float(node.x)>=Simulation.LEFT and float(node.x)+float(node.w)<=Simulation.RIGHT,"brick horizontal fit")
                check(float(node.y)>=Simulation.TOP and float(node.y)+float(node.h)<Simulation.PADDLE_Y-90,"brick vertical fit")
            if level>=4:check(a.relay_alive() and a.bricks.any(func(n):return n.kind=="locked"),"relay/lock puzzle present")
        totals[level]=cells
    check(int(totals[40])>int(totals[1])*2,"later layouts grow in size/density")
    for kind in ["armor","cache","blast","prism","relay","locked","phase","moving","steel","turret"]:check(kinds.has(kind),"generated feature "+kind)
    var easy=Simulation.new();easy.new_challenge({},5150,1)
    var hard=Simulation.new();hard.new_challenge({},5150,5)
    check(easy.security_rating()==1 and hard.security_rating()==9,"terminal difficulty drives effective network security")
    var easy_hp:int=0
    var hard_hp:int=0
    for node in easy.bricks:easy_hp+=int(node.max_hp)
    for node in hard.bricks:hard_hp+=int(node.max_hp)
    check(hard.bricks.size()>easy.bricks.size() and hard_hp>easy_hp,"hard intrusions contain denser, tougher networks")
    check(hard.trace_limit<easy.trace_limit and hard.ball_speed()>easy.ball_speed(),"hard intrusions trace faster and run faster")
    var caught=Simulation.new();caught.new_challenge({},991,4);caught.launch();caught.stage_time=caught.trace_limit-.001;caught.step(.02)
    check(caught.detected and caught.state=="dead" and caught.events.any(func(event):return event.kind=="detected"),"completed trace attributes the intrusion")
    var locked_trace=Simulation.new();locked_trace.new_challenge({},812,3)
    var locked_index:int=locked_trace.bricks.find_custom(func(node):return node.kind=="locked")
    var before_trace:float=locked_trace.stage_time;locked_trace.damage_brick(locked_index,99)
    check(locked_index>=0 and locked_trace.stage_time>before_trace,"attacking a locked firewall raises trace")
    var s=scenario();s.bricks[0]=brick(100,200,"armor",3)
    s.balls=[{"x":120.0,"y":239.0,"dx":0.0,"dy":-1.0,"r":6.0,"held":false,"spread":0.0}]
    s.step(.05);check(s.bricks[0].hp==2 and s.balls[0].dy>0,"real ball damage and bounce")
    s.permanent.damage=2;s.balls[0].y=239;s.balls[0].dy=-1;s.step(.05)
    check(not s.bricks[0].active and s.earned>0,"damage research actually breaks tougher bricks")
    var money:int=s.earned;s.damage_brick(0,99);check(s.earned==money,"destroyed brick cannot pay twice")
    s=scenario();s.bricks=[brick(100,200,"relay"),brick(150,200,"locked"),brick(280,180,"steel")]
    s.damage_brick(1,50);check(s.bricks[1].hp==1,"locked brick rejects hits before relay")
    s.damage_brick(0,1);s.damage_brick(1,1);check(s.state=="clear","relay unlock and steel not mandatory for completion")
    money=s.earned;s.damage_brick(1,5);check(s.earned==money,"level-clear payout is once-only")
    s=scenario();s.bricks=[brick(100,200,"blast"),brick(180,200,"blast"),brick(260,200)]
    s.damage_brick(0,1);check(s.remaining()==0,"explosive chain reaches beyond first blast radius")
    s=scenario();s.bricks[0]=brick(100,200,"cache",2)
    s.damage_brick(0,1);check(s.drops.is_empty(),"hidden payload waits for armored cache to break")
    s.damage_brick(0,1);check(s.drops.size()==1 and s.earned>=50,"cache contains a real drop and cash")
    s=scenario();s.apply_effect("split");check(s.balls.size()==3,"multiball adds independent balls")
    for i in 20:s.apply_effect("split")
    check(s.balls.size()==12,"multiball remains performance bounded")
    var width:float=s.paddle_width();s.apply_effect("shrink");check(s.paddle_width()<width,"anti-bonus shrinks paddle")
    var speed:float=s.ball_speed();s.apply_effect("fast");check(s.ball_speed()>speed,"anti-bonus overclocks balls")
    s.effects.clear();s.apply_effect("slow");check(s.ball_speed()<speed,"slow pickup modifies actual speed")
    for ball in s.balls:ball.held=true
    for i in 130:s.step(.1)
    check(not s.effects.has("slow"),"temporary effects expire")
    s=scenario();s.apply_effect("laser");check(s.fire_laser() and s.lasers.size()==2 and s.laser_ammo==11,"laser powerup creates real projectiles")
    s=scenario();s.shields=1;s.balls[0].x=20;s.balls[0].y=715;s.balls[0].dy=1;s.step(.01)
    check(s.shields==0 and s.lives==3 and s.balls[0].dy<0,"floor shield saves a falling ball")
    s=scenario();s.balls[0].x=20;s.balls[0].y=715;s.balls[0].dy=1;s.step(.01)
    check(s.lives==2 and s.state=="ready","last ball loss costs one life and waits for relaunch")
    s=scenario();s.permanent.multi=2;s._serve();s.launch();s.balls[0].y=720;s.step(.01)
    check(s.lives==3 and s.balls.size()==2,"losing one multiball does not cost a life")
    s=scenario();s.shields=0;s.magnets=1;s.balls[0].x=s.paddle_x;s.balls[0].y=654;s.balls[0].dy=1;s.step(.04)
    check(s.balls[0].held and s.magnets==0,"magnet catches on paddle");s.launch();check(not s.balls[0].held,"launch releases magnetic catch")
    s=scenario();s.stage=12;s.generate_stage();s.launch()
    for i in 80:s.target_x=180+sin(i*.1)*100;s.step(.016)
    var restored=Simulation.new();check(restored.restore(s.snapshot()),"snapshot can restore")
    for i in 200:
        s.target_x=180+sin(i*.1)*100;restored.target_x=s.target_x;s.step(.016);restored.step(.016)
    check(s.snapshot()==restored.snapshot(),"save/load preserves future physics and RNG")
    check(not restored.restore({"schema":999}),"bad run snapshot rejected")
    var game=Game.new();game.embedded=true;game.configure(Game.default_profile(),5000);root.add_child(game)
    check(game.music_player==null,"embedded game never starts a second music player")
    game.open_dealer();check(game.buy_research("width"),"research can be purchased through the dealer")
    var permanent:int=game.profile.research.width;var cash:int=game.balance
    game.start_new_run(99);game.sim.damage_brick(0,99);game._settle_events()
    check(game.balance>cash,"destroyed nodes pay the persistent wallet")
    cash=game.balance;game.sim.lives=1;game.sim.lose_life();game._settle_events()
    check(game.phase=="DEAD" and game.balance==cash,"death retains every earned credit")
    check(game.profile.research.width==permanent,"death retains permanent research")
    game.start_new_run(100);game.sim.state="clear";game.phase="SHOP"
    check(game.buy_temporary("damage") and game.sim.rank("damage")==1,"between-level store applies real run upgrade")
    cash=game.balance;game.start_new_run(101)
    check(game.sim.rank("damage")==0 and game.sim.rank("width")==permanent and game.balance==cash,"new run resets temporary upgrades only")
    game.sim.launch();game.sim.step(.1);game.pause_game();var snap:Dictionary=game.sim.snapshot();game._process(10)
    check(game.sim.snapshot()==snap,"pause freezes simulation")
    var challenge_game=Game.new();challenge_game.embedded=true;challenge_game.configure(Game.default_profile(),3200);root.add_child(challenge_game)
    challenge_game.start_challenge(challenge_game.profile,7001,1,"public",false);var easy_reward:=challenge_game.challenge_max_reward()
    check(challenge_game.balance==3200,"starting a Privateer intrusion preserves the linked career wallet")
    challenge_game.start_challenge(challenge_game.profile,7002,5,"hidden",true);var hard_reward:=challenge_game.challenge_max_reward()
    check(hard_reward>easy_reward*8,"reward scales sharply with security difficulty and concealed-terminal risk")
    challenge_game.sim.state="clear";challenge_game._settle_events()
    check(challenge_game.challenge_result.success and int(challenge_game.challenge_result.reward)>=challenge_game.challenge_base_reward(),"successful intrusion reports a difficulty-scaled payout")
    # Isolated user data directory supplied by the test runner.
    var stored=Game.new();stored.embedded=false;root.add_child(stored);stored.load_slot(3)
    check(stored.music_player != null and stored.music_player.stream is AudioStreamOggVorbis and stored.music_player.stream.get_length() > 170.0,
        "standalone Firewall must play the real Do Androids Dream recording")

    stored.configure(Game.default_profile(),777);stored.phase="RESEARCH";stored.buy_research("width");stored.start_new_run(123);stored.persist()
    var expected:int=stored.balance;var expected_run:Dictionary=stored.sim.snapshot()
    stored.load_slot(2);check(stored.balance==0,"empty profile is isolated")
    stored.load_slot(3);check(stored.balance==expected and stored.profile.research.width==1,"credits/research load from chosen profile")
    check(stored.sim.snapshot()==expected_run and stored.phase=="TITLE","active run restores awaiting deliberate resume")
    game.queue_free();challenge_game.queue_free();stored.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
    if failures.is_empty():print("NEON FIREWALL OK: %d checks, 400 generated boards, physics, powerups, progression, profiles and lifecycle" % checks);call_deferred("quit",0)
    else:print("NEON FIREWALL FAIL: "+str(failures));call_deferred("quit",1)
