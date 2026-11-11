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
    check(easy.steps==["rumor","tail","wiretap","target"] and easy.people.size()==1,"entry bounty asks around, tails, hacks for a clue, then resolves a target")
    check(easy.target_approach in ["space","breach"],"the final target is assigned a real space or breach encounter")
    check(easy.clues.size()==1 and easy.sites[2].lead_channels.has("illegal_terminal") and easy.sites[3].lead_channels.has("field_search"),"case dossier opens with a confidence-rated lead and multiple clue channels")
    check(easy.sites.size()==easy.steps.size() and easy.sites[0].discovered and not easy.sites[1].discovered,"case locations reveal one lead at a time")
    var itinerary:=Cases.create(base,0,["p3","p4","p5"])
    var itinerary_repeat:=Cases.create(base,0,["p3","p4","p5"])
    check(itinerary.sites[0].planet=="p2" and itinerary.sites[1].planet!="p2" and itinerary.sites[1].planet==itinerary_repeat.sites[1].planet,"case leads start at the contract world then follow a deterministic cross-world itinerary")
    check(itinerary.sites[2].planet!=itinerary.sites[1].planet and itinerary.sites[3].planet!="p2","multi-stage cases continue across reachable worlds rather than pinning every site to the contract planet")
    var local_only:=Cases.create(base,0)
    check(local_only.sites.all(func(site):return String(site.planet)=="p2"),"legacy and single-world cases remain local when no reachable itinerary is supplied")
    var hard_base:=base.duplicate(true);hard_base.id="gov-mastermind";hard_base.difficulty=5
    var hard:=Cases.create(hard_base,5)
    check(hard.people.size()>=4 and not hard.mastermind.is_empty() and hard.steps.count("breach")>=2 and hard.steps.count("wiretap")>=2 and hard.steps.has("target"),"high-rank case has multiple perpetrators, sites, bounty targets and a mastermind")
    check(float(hard.world_effect.strength)>float(easy.world_effect.strength),"complex cases carry larger real-world consequences")
    var profile:=Career.default_profile();profile.active=hard
    var first:=Cases.current_site(profile.active)
    check(Career.next_task(profile.active)=="rumor" and Career.advance(profile,"rumor") and Career.next_task(profile.active)=="stakeout" and Career.advance(profile,"stakeout"),"career advances from source-checked rumors into a tailored stakeout")
    check(bool(first.visited) and bool(Cases.current_site(profile.active).discovered),"finishing a lead marks its site and reveals the next landing")
    check(profile.active.clues.size()==3 and profile.active.clues[-1].status=="CORROBORATED" and Cases.dossier_summary(profile.active).contains("3/11 CLUES"),"each completed step becomes persistent, sourced dossier evidence")
    var target_site:Dictionary={}
    for site in profile.active.sites:
        if String(site.task) in ["target","mastermind"]:target_site=site;break
    var located_subject:Dictionary=Cases.subject_for_task(profile.active,String(target_site.get("task","target")))
    check(Career.accidental_discovery(profile,String(target_site.id),String(located_subject.get("id",""))) and Career.next_task(profile.active) in ["target","mastermind"],"player can accidentally locate the real subject ahead of the clue order")
    var exploration:=Cases.create(base,0);var wanted:String=String(exploration.people[-1].id);var target_index:int=exploration.steps.find("target")
    check(Cases.accidental_discovery(exploration,String(exploration.sites[target_index].id),"wrong-suspect") and exploration.stage==0 and exploration.clues[-1].kind=="location","exploring a location adds a sourced clue without falsely identifying the target")
    check(Cases.accidental_discovery(exploration,String(exploration.sites[target_index].id),wanted) and Career.next_task(exploration)=="target" and Cases.dossier_summary(exploration).contains("2/4 CLUES"),"verified target location can shortcut the clue chain while preserving its dossier trail")
    var tier_three:=Cases.create(base,3);var target_subject:Dictionary=Cases.subject_for_task(tier_three,"target")
    check(target_subject.role=="enforcer" and tier_three.steps.count("target")==1,"higher rank separates a recoverable bounty from the lieutenant and mastermind")
    var pirate_base:=base.duplicate(true);pirate_base.id="pirate-9";pirate_base.guild="";pirate_base.criminal=true;pirate_base.issuer_faction="";pirate_base.issuer_name="FREE CAPTAINS"
    var pirate:=Cases.create(pirate_base,2)
    check(pirate.criminal and pirate.guild=="" and pirate.issuer_name=="FREE CAPTAINS","criminal merc cases support solo pirates without guild membership")
    if failures.is_empty():print("NEON CASE DIRECTOR OK: %d checks, clue chains, alternate sites, accidental discovery and masterminds"%checks);quit(0)
    else:print("NEON CASE DIRECTOR FAIL: "+str(failures));quit(1)
