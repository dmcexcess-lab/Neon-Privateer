extends RefCounted
## Persistent personal-story layer. It reacts to play instead of assigning a
## mandatory campaign or requiring guild membership.

const NEED_KEYS := ["hunger", "energy", "morale", "social"]

static func defaults() -> Dictionary:
    return {
        "needs":{"hunger":82.0,"energy":84.0,"morale":62.0,"social":55.0},
        "contacts":{},
        "story":{"sequence":0,"active_dossier":{},"history":[]}
    }

static func normalize(profile: Dictionary) -> void:
    var base:=defaults()
    if not profile.get("needs",null) is Dictionary:profile.needs=base.needs
    if not profile.get("contacts",null) is Dictionary:profile.contacts={}
    if not profile.get("story",null) is Dictionary:profile.story=base.story
    for key in NEED_KEYS:profile.needs[key]=clampf(float(profile.needs.get(key,base.needs[key])),0.0,100.0)
    profile.story=base.story.merged(profile.story,true)
    if not profile.story.get("history",null) is Array:profile.story.history=[]
    if not profile.story.get("active_dossier",null) is Dictionary:profile.story.active_dossier={}

static func on_arrival(profile: Dictionary) -> void:
    normalize(profile)
    profile.needs.hunger=maxf(0.0,float(profile.needs.hunger)-5.0)
    profile.needs.energy=maxf(0.0,float(profile.needs.energy)-4.0)
    profile.needs.social=maxf(0.0,float(profile.needs.social)-3.0)
    if float(profile.needs.hunger)<25.0 or float(profile.needs.energy)<25.0:
        profile.needs.morale=maxf(0.0,float(profile.needs.morale)-4.0)

static func visit_venue(profile: Dictionary, kind: String, available_cash: int) -> Dictionary:
    normalize(profile)
    var offers:Dictionary={
        "cafe":{"cost":12,"hunger":32.0,"energy":6.0,"morale":5.0},
        "bar":{"cost":15,"morale":18.0,"social":14.0,"energy":-4.0},
        "club":{"cost":25,"morale":26.0,"social":22.0,"energy":-10.0},
        "lodge":{"cost":30,"energy":44.0,"hunger":8.0,"morale":8.0},
        "market":{"cost":0,"morale":3.0,"social":3.0}
    }
    var offer:Dictionary=offers.get(kind,{"cost":0})
    var cost:=int(offer.get("cost",0))
    if available_cash<cost:return {"success":false,"cost":cost,"summary":"%s NEEDS %d CR"%[kind.to_upper(),cost]}
    for key in NEED_KEYS:
        profile.needs[key]=clampf(float(profile.needs[key])+float(offer.get(key,0.0)),0.0,100.0)
    return {"success":true,"cost":cost,"summary":"%s · HUNGER %d · ENERGY %d · MORALE %d · SOCIAL %d"%[kind.to_upper(),int(profile.needs.hunger),int(profile.needs.energy),int(profile.needs.morale),int(profile.needs.social)]}

static func _bond_label(path: String, trust: int) -> String:
    if trust<3:return "CONTACT"
    if trust<7:return "FRIEND"
    if trust<12:return "BUSINESS PARTNER" if path=="business" else "ROMANTIC INTEREST" if path=="romance" else "CLOSE FRIEND"
    return "PARTNER" if path in ["business","romance"] else "CONFIDANT"

static func remember_contact(profile: Dictionary, detail: Dictionary) -> Dictionary:
    normalize(profile)
    var id:=String(detail.get("id",""))
    if id.is_empty():return {}
    var existing:Dictionary=profile.contacts.get(id,{})
    var path:=String(existing.get("path",detail.get("path","friendship")))
    if path not in ["friendship","business","romance"]:path="friendship"
    var trust:=clampi(int(existing.get("trust",0))+clampi(int(detail.get("trust",1)),0,2),0,20)
    var contact:Dictionary={
        "id":id,"name":String(existing.get("name",detail.get("name","UNKNOWN CONTACT"))),
        "planet":String(existing.get("planet",detail.get("planet",""))),
        "venue":String(existing.get("venue",detail.get("venue","bar"))),
        "path":path,"trust":trust,"meetings":int(existing.get("meetings",0))+1,
        "bond":_bond_label(path,trust),"last_rumor":String(detail.get("rumor",existing.get("last_rumor",""))),
        "role":String(existing.get("role",detail.get("role","local")))
    }
    profile.contacts[id]=contact
    profile.needs.social=minf(100.0,float(profile.needs.social)+6.0)
    profile.needs.morale=minf(100.0,float(profile.needs.morale)+(5.0 if trust>=3 else 2.0))
    return contact

static func observe_rumor(profile: Dictionary, detail: Dictionary, play_style: String) -> Dictionary:
    normalize(profile)
    var story:Dictionary=profile.story
    var dossier:Dictionary=story.active_dossier
    var speaker:=String(detail.get("speaker","A local contact"))
    var rumor:=String(detail.get("rumor","An uncertain lead is circulating through the port."))
    if dossier.is_empty() or int(dossier.get("clues",[]).size())>=4:
        story.sequence=int(story.sequence)+1
        var objective:="Trace the cargo through two ports and identify who profits." if play_style=="trader" else "Identify the patrol leak without drawing faction attention." if play_style=="pirate" else "Compare local accounts and find the person connecting them."
        dossier={"id":"personal:%d"%int(story.sequence),"title":"THE %s THREAD"%speaker.to_upper(),"source":speaker,
            "origin":"personal","guild":"","style":play_style,"clues":[],"objective":objective,"progress":0,"status":"OPEN"}
        story.active_dossier=dossier
    var clue:="%s: %s"%[speaker,rumor]
    if not dossier.clues.has(clue):dossier.clues.append(clue);dossier.progress=int(dossier.progress)+1
    if dossier.clues.size()>=3:dossier.status="ACTIONABLE"
    story.active_dossier=dossier
    story.history.push_front({"dossier":dossier.id,"clue":clue})
    if story.history.size()>40:story.history.resize(40)
    return dossier

static func dossier_summary(profile: Dictionary) -> String:
    normalize(profile)
    var dossier:Dictionary=profile.story.active_dossier
    if dossier.is_empty():return "NO PERSONAL DOSSIER · TALK TO PEOPLE IN BARS, CLUBS, CAFES AND PORT STREETS"
    return "%s · %s · %d CLUES · %s"%[String(dossier.title),String(dossier.status),int(dossier.clues.size()),String(dossier.objective)]

static func observe_outcome(profile: Dictionary, detail: Dictionary) -> Dictionary:
    normalize(profile)
    var dossier:Dictionary=profile.story.active_dossier
    if dossier.is_empty():return {}
    var outcome:=String(detail.get("outcome","returned"))
    var clue:="FIELD OUTCOME: %s operation %s"%[String(detail.get("style","choice")).to_upper(),outcome.to_upper()]
    if not dossier.clues.has(clue):dossier.clues.append(clue)
    dossier.progress=int(dossier.get("progress",0))+1
    if outcome=="completed" and dossier.clues.size()>=3:
        dossier.status="RESOLVED"
        profile.story.history.push_front({"dossier":dossier.id,"resolution":clue})
    elif dossier.clues.size()>=3:dossier.status="ACTIONABLE"
    profile.story.active_dossier=dossier
    return dossier
