extends RefCounted
## Builds tailored Privateer cases from guild/faction contracts. Standalone
## games never consume this schema; it is campaign context only.

const FIRST := ["Mara","Ivo","Sera","Niko","Ash","Len","Juno","Kest","Rin","Vale","Nyx","Tarn"]
const LAST := ["Voss","Slate","Quill","Renn","Orra","Calder","Morrow","Finch","Sato","Venn","Greer","Rook"]
const SITE_TYPES := ["warehouse","safehouse","listening_post","mining_camp","orbital_annex","freighter","nightclub_backroom","relay_station"]

static func _person(seed_number: int,index: int,role: String) -> Dictionary:
    return {"id":"suspect:%d:%d"%[seed_number,index],"name":"%s %s"%[FIRST[(seed_number+index*5)%FIRST.size()],LAST[(seed_number*3+index*7)%LAST.size()]],"role":role,"status":"UNKNOWN"}

static func _steps(tier: int) -> Array[String]:
    match clampi(tier,1,5):
        1:return ["rumor","tail","wiretap","target"]
        2:return ["rumor","tail","wiretap","breach","target"]
        3:return ["rumor","tail","wiretap","eavesdrop","breach","lieutenant","target"]
        4:return ["rumor","stakeout","wiretap","tail","breach","lieutenant","eavesdrop","target","mastermind"]
        _:return ["rumor","stakeout","wiretap","tail","breach","lieutenant","wiretap","eavesdrop","breach","target","mastermind"]
    return []

static func subject_for_task(job: Dictionary, task: String="") -> Dictionary:
    var people:Array=job.get("people",[])
    if people.is_empty():return {}
    var wanted:Dictionary=people[-1]
    var task_name:=task
    var steps:Array=job.get("steps",[]);var stage:=int(job.get("stage",0))
    if task_name.is_empty() and stage>=0 and stage<steps.size():task_name=String(steps[stage])
    var wanted_role:=""
    match task_name:
        "lieutenant":wanted_role="lieutenant"
        "mastermind":wanted_role="mastermind"
        "target":wanted_role="enforcer"
    if not wanted_role.is_empty():
        for person in people:
            if String(person.get("role",""))==wanted_role:return person
    return wanted

static func _initial_clue(job: Dictionary) -> Dictionary:
    return {"id":"clue:%s:0"%String(job.get("id","case")),"kind":"last_known","source":"Contract dossier",
        "text":"%s was last tied to %s. Ask locals, compare accounts, and verify the lead before acting."%[String(job.get("target","UNKNOWN SUSPECT")),String(job.get("planet","this port"))],
        "location":String(job.get("planet","")),"confidence":0.25,"status":"UNVERIFIED","stage":0}

static func clue_text(task: String, job: Dictionary, site: Dictionary, speaker: String) -> String:
    var who:=String(subject_for_task(job,task).get("name",job.get("target","the suspect")));var place:=String(site.get("name",job.get("planet","the area")))
    match task:
        "rumor":return "%s places %s near %s; account still unverified."%[speaker,who,place]
        "tail":return "Surveillance links %s to %s and records a route to the next lead."%[who,place]
        "stakeout":return "A stakeout at %s confirms a recurring arrival window for %s."%[place,who]
        "wiretap":return "Terminal traffic at %s links the suspect to the next location."%place
        "eavesdrop":return "An overheard conversation at %s identifies a person, time, or transfer point."%place
        "breach":return "Records recovered at %s connect %s to a wider operation."%[place,who]
        "lieutenant":return "The lieutenant's trail identifies a higher-ranking organizer behind %s."%who
        "target":return "The dossier's accumulated evidence locates %s at %s."%[who,place]
        "mastermind":return "Evidence at %s identifies the network's organizer and its next move."%place
        _:return "New evidence from %s advances the case against %s."%[speaker,who]

static func dossier_summary(job: Dictionary) -> String:
    if job.is_empty():return "NO ACTIVE CASE"
    var clues:Array=job.get("clues",[]);var people:Array=job.get("people",[])
    var steps:Array=job.get("steps",[]);var stage:=int(job.get("stage",0));var next:="RESOLVED"
    if stage>=0 and stage<steps.size():next=String(steps[stage])
    var open_sites:=0
    for site in job.get("sites",[]):
        if not bool(site.get("visited",false)):open_sites+=1
    return "%s · %d/%d CLUES · %d SUSPECTS · %d LEADS · NEXT: %s"%[
        String(job.get("target","ACTIVE CASE")),clues.size(),job.get("steps",[]).size(),people.size(),open_sites,
        next]

static func create(contract: Dictionary,merc_rank: int=0,reachable_planets: Array=[] ) -> Dictionary:
    var tier:=clampi(maxi(int(contract.get("difficulty",1)),merc_rank),1,5)
    var case_planet:=String(contract.get("destination",contract.get("planet",contract.get("origin",""))))
    # Contract IDs are integers in current saves but older fixtures may carry a
    # StringName-like value. str() provides one stable hashing boundary for all.
    var seed_number:=absi(str(contract.get("id","1")).hash()+case_planet.hash())
    var criminal:=bool(contract.get("criminal",false)) or bool(contract.get("smuggling",false))
    var roles:Array[String]=["courier"]
    if tier>=2:roles.append("enforcer")
    if tier>=3:roles.append("lieutenant")
    if tier>=4:roles.append("mastermind")
    var people:Array=[]
    for i in roles.size():people.append(_person(seed_number,i,roles[i]))
    var steps:=_steps(tier);var sites:Array=[]
    var other_worlds:Array[String]=[]
    for world in reachable_planets:
        var world_id:=String(world)
        if not world_id.is_empty() and world_id!=case_planet and not other_worlds.has(world_id):other_worlds.append(world_id)
    # Keep the first lead at the contract destination, then seed a persistent
    # itinerary across reachable worlds. Modulo cycling supports small systems.
    for i in steps.size():
        var task:=steps[i];var site_type:=str(SITE_TYPES[(seed_number+i*3)%SITE_TYPES.size()])
        var site_planet:=case_planet if i==0 or other_worlds.is_empty() else other_worlds[posmod(seed_number+i-1,other_worlds.size())]
        sites.append({"id":"site:%d:%d"%[seed_number,i],"planet":site_planet,
            "name":"%s %s"%[site_type.replace("_"," ").to_upper(),str(11+(seed_number+i*17)%88)],"type":site_type,"task":task,
            "discovered":i==0,"visited":false,"seed":seed_number+i*7919,"station":site_type in ["orbital_annex","freighter","relay_station"]})
    var result:Dictionary={"id":"case:%s"%str(contract.get("id",seed_number)),"planet":case_planet,
        "type":"criminal_merc" if criminal else "faction_case","target":str(people[-1].name),"people":people,"steps":steps,"sites":sites,"stage":0,
        "difficulty":tier,"guild":str(contract.get("guild","")),"required_rank":int(contract.get("required_rank",0)),"criminal":criminal,"target_approach":"space" if seed_number%2==0 else "breach",
        "reward":0,"seed":seed_number,"issuer_faction":str(contract.get("issuer_faction","")),"issuer_name":str(contract.get("issuer_name","INDEPENDENT CLIENT")),
        "mastermind":people[-1] if tier>=4 else {},"world_effect":{"strength":.015*tier,"relation":2+tier,"destabilize":.01*maxi(0,tier-2)},
        "journal_origin":"Contract converted to a multi-stage Privateer case."}
    result.clues=[_initial_clue(result)]
    result.evidence=[]
    for site in result.sites:
        site["lead_channels"]=["local_contacts","rumor_network","field_search"]
        if String(site.task)=="wiretap":site.lead_channels.append("illegal_terminal")
        if String(site.task) in ["tail","stakeout","eavesdrop"]:site.lead_channels.append("surveillance")
    return result

static func current_site(job: Dictionary) -> Dictionary:
    if job.is_empty():return {}
    var stage:=int(job.get("stage",0));var sites:Array=job.get("sites",[])
    return sites[stage] if stage>=0 and stage<sites.size() else {}

static func reveal_current(job: Dictionary) -> Dictionary:
    var site:=current_site(job)
    if not site.is_empty():site.discovered=true
    return site

static func accidental_discovery(job: Dictionary,site_id: String,person_id: String="") -> bool:
    if job.is_empty():return false
    var sites:Array=job.get("sites",[]);var found:=-1
    for i in sites.size():
        if String(sites[i].get("id",""))==site_id:found=i;break
    if found<0:return false
    var site:Dictionary=sites[found]
    var clues:Array=job.get("clues",[])
    var clue_id:="clue:%s:location:%d"%[String(job.get("id","case")),found]
    var already_recorded:=false
    for clue in clues:
        if String(clue.get("id",""))==clue_id:already_recorded=true;break
    if not already_recorded:
        clues.append({"id":clue_id,"kind":"location","source":"Exploration / unmarked landing","text":"An independently discovered location at %s contains a lead linked to %s."%[String(site.get("name","unknown site")),String(job.get("target","the suspect"))],
            "location":String(site.get("planet","")),"site_id":site_id,"confidence":0.65,"status":"ACTIONABLE","stage":found})
    site.visited=true;site.discovered=true;job.clues=clues
    var steps:Array=job.get("steps",[]);var found_task:=String(steps[found]) if found<steps.size() else ""
    var found_subject:=subject_for_task(job,found_task)
    if found_task in ["target","mastermind"] and not person_id.is_empty() and person_id!=String(found_subject.get("id","")):return true
    if found>=int(job.get("stage",0)):job.stage=found
    sites[found].discovered=true
    return true
