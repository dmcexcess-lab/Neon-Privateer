extends SceneTree
const Cases=preload("res://covert/CaseDirector.gd")
const Career=preload("res://covert/CovertCareer.gd")
var failures:Array[String]=[]
var checks:=0
func check(value:bool,message:String)->void:
    checks+=1
    if not value:failures.append(message);push_error("CASE DIRECTOR FAIL: "+message)
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var base:={"id":"gov-17","origin":"p1","destination":"p2","difficulty":1,"guild":"merc","required_rank":0,"issuer_faction":"f1","issuer_name":"HELIX AUTHORITY","reward":900}
    var easy:=Cases.create(base,0)
    check(easy.steps==["rumor","tail","breach","target"] and easy.people.size()==1,"entry case is a readable find-the-person chain")
    check(easy.sites.size()==easy.steps.size() and easy.sites[0].discovered and not easy.sites[1].discovered,"case locations reveal one lead at a time")
    var hard_base:=base.duplicate(true);hard_base.id="gov-mastermind";hard_base.difficulty=5
    var hard:=Cases.create(hard_base,5)
    check(hard.people.size()>=4 and not hard.mastermind.is_empty() and hard.steps.count("breach")>=2 and hard.steps.count("wiretap")>=2,"high-rank case has multiple perpetrators, sites and a mastermind")
    check(float(hard.world_effect.strength)>float(easy.world_effect.strength),"complex cases carry larger real-world consequences")
    var profile:=Career.default_profile();profile.active=hard
    var first:=Cases.current_site(profile.active);check(Career.next_task(profile.active)=="stakeout" and Career.advance(profile,"stakeout"),"career advances the director's tailored steps")
    check(bool(first.visited) and bool(Cases.current_site(profile.active).discovered),"finishing a lead marks its site and reveals the next landing")
    var target_site:Dictionary={}
    for site in profile.active.sites:
        if String(site.task) in ["target","mastermind"]:target_site=site;break
    check(Career.accidental_discovery(profile,String(target_site.id),String(profile.active.people[-1].id)) and Career.next_task(profile.active) in ["target","mastermind"],"player can accidentally locate the real subject ahead of the clue order")
    var pirate_base:=base.duplicate(true);pirate_base.id="pirate-9";pirate_base.guild="";pirate_base.criminal=true;pirate_base.issuer_faction="";pirate_base.issuer_name="FREE CAPTAINS"
    var pirate:=Cases.create(pirate_base,2)
    check(pirate.criminal and pirate.guild=="" and pirate.issuer_name=="FREE CAPTAINS","criminal merc cases support solo pirates without guild membership")
    if failures.is_empty():print("NEON CASE DIRECTOR OK: %d checks, clue chains, alternate sites, accidental discovery and masterminds"%checks);quit(0)
    else:print("NEON CASE DIRECTOR FAIL: "+str(failures));quit(1)
