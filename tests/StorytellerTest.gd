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
    var detail:={"id":"aster:npc-3","name":"Sable Quill","planet":"aster","venue":"club","path":"romance","role":"artist","trust":1,"rumor":"A quiet manifest changed hands.","appearance":{"seed":197,"skin":2,"top":6,"coat":4,"hair":3,"hat":1,"build":2}}
    var contact:=Storyteller.remember_contact(profile,detail)
    var changed_look:=detail.duplicate(true);changed_look.appearance={"seed":999,"skin":5,"top":1,"coat":1,"hair":7,"hat":5,"build":0}
    contact=Storyteller.remember_contact(profile,changed_look)
    for i in 6:contact=Storyteller.remember_contact(profile,detail)
    check(profile.contacts.has("aster:npc-3") and contact.meetings==8 and contact.bond=="ROMANTIC INTEREST","chosen contacts persist and deepen across meetings")
    check(contact.appearance.seed==197 and contact.appearance.skin==2 and contact.appearance.hat==1,"an established contact keeps their first saved appearance")
    var dossier:Dictionary
    for i in 3:dossier=Storyteller.observe_rumor(profile,{"speaker":"Sable Quill","speakerId":"aster:npc-3","rumor":"Lead %d"%i},"trader")
    check(dossier.guild=="" and dossier.origin=="personal" and dossier.style=="trader" and dossier.status=="ACTIONABLE","personal dossier grows from clues without a guild gate")
    check(Storyteller.dossier_summary(profile).contains("3 CLUES"),"dossier exposes objective and clue progress")
    var dossier_id:=String(dossier.id);var clue_count:int=dossier.clues.size();var progress:=int(dossier.progress)
    dossier=Storyteller.observe_outcome(profile,{"outcome":"completed","style":"stealth","contact":"Unrelated Fixer","contactId":"elsewhere:npc-9","objective":"shipyard sabotage"})
    check(dossier.status=="ACTIONABLE" and dossier.clues.size()==clue_count and int(dossier.progress)==progress,"unrelated completed jobs cannot advance or resolve a personal dossier")
    dossier=Storyteller.observe_rumor(profile,{"speaker":"Dock Witness","speakerId":"aster:npc-8","rumor":"Fourth corroborating lead"},"trader")
    dossier=Storyteller.observe_rumor(profile,{"speaker":"Cafe Witness","speakerId":"aster:npc-11","rumor":"Fifth corroborating lead"},"trader")
    check(String(dossier.id)==dossier_id and dossier.clues.size()==5 and dossier.status=="ACTIONABLE","an unresolved dossier remains active after four clues instead of being replaced")
    dossier=Storyteller.observe_outcome(profile,{"outcome":"completed","style":"stealth","contact":"Sable Quill","contactId":"aster:npc-3","objective":"evidence theft"})
    check(dossier.status=="RESOLVED","a completed operation linked to a named dossier contact resolves an actionable personal story")
    var objective_profile:=Career.default_profile();var objective_dossier:Dictionary
    for i in 3:objective_dossier=Storyteller.observe_rumor(objective_profile,{"speaker":"Rook Vale","speakerId":"lumen:npc-2","rumor":"Cargo lead %d"%i},"trader")
    objective_dossier=Storyteller.observe_outcome(objective_profile,{"outcome":"completed","style":"choice","contact":"Independent Hauler","contactId":"lumen:npc-14","objective":"cargo recovery"})
    check(objective_dossier.status=="RESOLVED","an operation matching the dossier's authored objective can resolve the thread")
    var restored:=Career.decode(var_to_bytes(profile))
    check(restored.contacts["aster:npc-3"].bond=="ROMANTIC INTEREST" and restored.contacts["aster:npc-3"].appearance.seed==197 and restored.story.active_dossier.status=="RESOLVED","contact appearance, needs and story survive career serialization")
    if failures.is_empty():print("NEON STORYTELLER OK: %d checks, needs, contacts, bonds and guild-free dossiers"%checks);quit(0)
    else:print("NEON STORYTELLER FAIL: "+str(failures));quit(1)
