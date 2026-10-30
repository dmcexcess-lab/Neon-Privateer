extends SceneTree
const Career=preload("res://covert/CovertCareer.gd")
const Storyteller=preload("res://covert/Storyteller.gd")
var failures:Array[String]=[]
var checks:=0
func check(value:bool,message:String)->void:
    checks+=1
    if not value:failures.append(message);push_error("STORYTELLER FAIL: "+message)
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var profile:=Career.default_profile()
    check(profile.schema==3 and profile.contacts.is_empty() and profile.needs.has("social"),"new careers contain needs, contacts and story state")
    var hunger:float=profile.needs.hunger;Storyteller.on_arrival(profile)
    check(float(profile.needs.hunger)<hunger,"arrivals advance physical and social needs")
    var poor:=Storyteller.visit_venue(profile,"club",0)
    check(not poor.success and poor.cost==25,"venues require the real carried wallet")
    profile.needs.social=10;var visit:=Storyteller.visit_venue(profile,"club",100)
    check(visit.success and float(profile.needs.social)>10,"clubs materially restore social and morale needs")
    var detail:={"id":"aster:npc-3","name":"Sable Quill","planet":"aster","venue":"club","path":"romance","role":"artist","trust":1,"rumor":"A quiet manifest changed hands."}
    var contact:=Storyteller.remember_contact(profile,detail)
    for i in 7:contact=Storyteller.remember_contact(profile,detail)
    check(profile.contacts.has("aster:npc-3") and contact.meetings==8 and contact.bond=="ROMANTIC INTEREST","chosen contacts persist and deepen across meetings")
    var dossier:Dictionary
    for i in 3:dossier=Storyteller.observe_rumor(profile,{"speaker":"Sable Quill","rumor":"Lead %d"%i},"trader")
    check(dossier.guild=="" and dossier.origin=="personal" and dossier.style=="trader" and dossier.status=="ACTIONABLE","personal dossier grows from clues without a guild gate")
    check(Storyteller.dossier_summary(profile).contains("3 CLUES"),"dossier exposes objective and clue progress")
    dossier=Storyteller.observe_outcome(profile,{"outcome":"completed","style":"stealth"})
    check(dossier.status=="RESOLVED","field outcomes resolve actionable personal story threads")
    var restored:=Career.decode(var_to_bytes(profile))
    check(restored.contacts["aster:npc-3"].bond=="ROMANTIC INTEREST" and restored.story.active_dossier.status=="RESOLVED","contacts, needs and story survive career serialization")
    if failures.is_empty():print("NEON STORYTELLER OK: %d checks, needs, contacts, bonds and guild-free dossiers"%checks);quit(0)
    else:print("NEON STORYTELLER FAIL: "+str(failures));quit(1)
