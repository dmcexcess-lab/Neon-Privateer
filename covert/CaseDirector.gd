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
        1:return ["rumor","tail","breach","target"]
        2:return ["rumor","wiretap","tail","breach","target"]
        3:return ["stakeout","wiretap","eavesdrop","breach","target"]
        4:return ["rumor","stakeout","wiretap","tail","breach","lieutenant","eavesdrop","mastermind"]
        _:return ["stakeout","wiretap","tail","breach","lieutenant","wiretap","eavesdrop","breach","mastermind"]
    return []

static func create(contract: Dictionary,merc_rank: int=0) -> Dictionary:
    var tier:=clampi(maxi(int(contract.get("difficulty",1)),merc_rank),1,5)
    var case_planet:=String(contract.get("destination",contract.get("planet",contract.get("origin",""))))
    # Contract IDs are integers in current saves but older fixtures may carry a
    # StringName-like value. str() provides one stable hashing boundary for all.
    var seed_number:=absi(str(contract.get("id","1")).hash()+case_planet.hash())
    var criminal:=bool(contract.get("criminal",false)) or bool(contract.get("smuggling",false))
    var roles:Array[String]=["courier"]
    if tier>=2:roles.append("enforcer")
    if tier>=4:roles.append("lieutenant")
    if tier>=4:roles.append("mastermind")
    var people:Array=[]
    for i in roles.size():people.append(_person(seed_number,i,roles[i]))
    var steps:=_steps(tier);var sites:Array=[]
    for i in steps.size():
        var task:=steps[i];var site_type:=str(SITE_TYPES[(seed_number+i*3)%SITE_TYPES.size()])
        sites.append({"id":"site:%d:%d"%[seed_number,i],"planet":case_planet,
            "name":"%s %s"%[site_type.replace("_"," ").to_upper(),str(11+(seed_number+i*17)%88)],"type":site_type,"task":task,
            "discovered":i==0,"visited":false,"seed":seed_number+i*7919,"station":site_type in ["orbital_annex","freighter","relay_station"]})
    return {"id":"case:%s"%str(contract.get("id",seed_number)),"planet":case_planet,
        "type":"criminal_merc" if criminal else "faction_case","target":str(people[-1].name),"people":people,"steps":steps,"sites":sites,"stage":0,
        "difficulty":tier,"guild":str(contract.get("guild","")),"required_rank":int(contract.get("required_rank",0)),"criminal":criminal,
        "reward":0,"seed":seed_number,"issuer_faction":str(contract.get("issuer_faction","")),"issuer_name":str(contract.get("issuer_name","INDEPENDENT CLIENT")),
        "mastermind":people[-1] if tier>=4 else {},"world_effect":{"strength":.015*tier,"relation":2+tier,"destabilize":.01*maxi(0,tier-2)},
        "journal_origin":"Contract converted to a multi-stage Privateer case."}

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
    var people:Array=job.get("people",[])
    var wanted:Dictionary=people[-1] if not people.is_empty() else {}
    if not person_id.is_empty() and person_id!=String(wanted.get("id","")):return false
    var sites:Array=job.get("sites",[]);var found:=-1
    for i in sites.size():
        if String(sites[i].get("id",""))==site_id:found=i;break
    if found<0:return false
    var steps:Array=job.get("steps",[]);var target_stage:=-1
    for i in steps.size():
        if String(steps[i]) in ["target","mastermind"]:target_stage=i;break
    if target_stage<0:return false
    job.stage=mini(found,target_stage) if found>=int(job.get("stage",0)) else int(job.get("stage",0))
    if found==target_stage:job.stage=target_stage
    sites[found].discovered=true
    return true
