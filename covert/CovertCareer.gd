extends RefCounted
const Guild=preload("GuildProgress.gd")
const Justice=preload("JusticeSystem.gd")
const Storyteller=preload("Storyteller.gd")
const CaseDirector=preload("CaseDirector.gd")
const NAMES := ["Mara Voss","Ivo Slate","Sera Quill","Niko Vale","Ash Renn","Len Orra"]
const JOBS := ["track","recover","assault","terminal","assassinate","investigate","station_hack","robbery","mug"]
const STEPS := {"track":["rumor","tail","intel","bounty"],"recover":["rumor","intel"],"assault":["assault"],"terminal":["intel"],"assassinate":["assassinate"],"investigate":["rumor","tail","evidence","file_charges"],"station_hack":["station_hack"],"robbery":["robbery"],"mug":["mug"]}
static func default_profile() -> Dictionary:
    return {"schema":3,"active":{},"journal":[],"prosecutions":[],"settled":{},"sequence":0,"completed":0,"arrests":0,"captures":0,"gear":{"pistol":false,"armor":0},"ground":{},"challenge":{},"captured":false,"incarcerated":false,"guilds":Guild.defaults(),"justice":Justice.defaults(),"prison_life":{},"fitness":0,"needs":Storyteller.defaults().needs,"contacts":{},"story":Storyteller.defaults().story}
static func decode(raw: Variant) -> Dictionary:
    var value:Variant=bytes_to_var(raw) if raw is PackedByteArray else raw
    var result:Dictionary=default_profile().merged(value.duplicate(true),true) if value is Dictionary else default_profile()
    result.guilds=Guild.normalize(result.guilds);result.justice=Justice.normalize(result.justice)
    Storyteller.normalize(result)
    # Old tactical detention is not a criminal conviction. Preserve the escape.
    if int(result.schema)<2:
        result.captured=bool(result.incarcerated);result.incarcerated=false
        if not result.ground.is_empty() and result.ground.get("kind","")=="prison":result.ground.kind="mission_escape"
    result.schema=3
    return result
static func offer(planet: String,kind: String,sequence: int,difficulty: int=1) -> Dictionary:
    var tier:=clampi(difficulty,1,5);var seed_number:=absi((planet+kind+str(sequence)+str(tier)).hash())
    var target:String=NAMES[seed_number%NAMES.size()]
    var criminal:bool=kind in ["station_hack","robbery","mug"]
    var base:int={"track":900,"recover":650,"assault":450,"terminal":400,"assassinate":550,"investigate":1000,"station_hack":200,"robbery":350,"mug":90}.get(kind,0)
    var base_offer:={"id":"%s:%s:%d:%d"%[planet,kind,sequence,tier],"planet":planet,"type":kind,"target":target,"stage":0,"seed":seed_number,"difficulty":tier,"guild":"" if criminal else "merc","required_rank":0 if criminal else Guild.required(tier),"criminal":criminal,"reward":base*tier}
    # Street crimes remain immediate sandbox actions. Guild, faction and pirate
    # mercenary contracts become clue-driven cases in Privateer.
    if criminal:
        base_offer["steps"]=STEPS[kind].duplicate()
        return base_offer
    var tailored:=CaseDirector.create(base_offer,tier);tailored.id=base_offer.id;tailored.type=kind;tailored.reward=base_offer.reward
    if kind=="investigate":
        tailored.steps.append("file_charges")
        tailored.sites.append({"id":"site:%d:filing"%seed_number,"planet":planet,"name":"LOCAL AUTHORITY CASE DESK","type":"authority","task":"file_charges","discovered":false,"visited":false,"seed":seed_number+9973,"station":true})
    return tailored
static func next_task(job: Dictionary) -> String:
    if job.is_empty():return "port"
    var steps:Array=job.get("steps",STEPS.get(String(job.type),[]));var stage:=int(job.stage)
    return String(steps[stage]) if stage<steps.size() else "done"
static func objective(job: Dictionary) -> String:
    if job.is_empty():return "Choose work or crime. Start with courier work from ship CONTRACTS if you have no equipment."
    var who:=String(job.target)
    match next_task(job):
        "rumor":return "Ask a dock contact about %s. Approach an NPC and interact with your weapon holstered."%who
        "tail":return "Listen at the northeast meeting for 6 seconds, unseen and holstered. Extract with the lead."
        "stakeout":return "Land at the marked site and watch the location without approaching or drawing a weapon."
        "eavesdrop":return "Shadow the meeting and remain close enough to hear it without being made."
        "wiretap":return "Land at the marked relay and defeat its contextual Firewall to install the wiretap."
        "breach":return "Land away from the main starport, enter the named safehouse and recover its records."
        "lieutenant":return "Find the identified lieutenant at the marked hideout and secure the next link."
        "target":return "The dossier has located %s. Land at the marked site and apprehend or eliminate the target."%who
        "mastermind":return "The organization points to %s. Breach the final site and resolve the mastermind."%who
        "intel","evidence":return "Reach the northeast terminal on foot, defeat its Firewall, then extract the records."
        "bounty":return "The manifest identifies %s in the southeast room. Dead or alive. Secure the target and extract."%who
        "assassinate":return "On-foot assassination: eliminate %s in the southeast room, then extract. This is a mercenary contract, not an investigation."%who
        "assault":return "Known compound: defeat every hostile and extract. No detective work required."
        "file_charges":return "Witness lead and terminal records secured. File the evidence package with the local authority to bring charges against %s."%who
        "station_hack":return "CRIME: infiltrate the station terminal, steal account data through Firewall, then extract. Authorities can fine or imprison you."
        "robbery":return "CRIME: break the northeast vault terminal and extract the stolen credits. This creates a robbery charge."
        "mug":return "CRIME: approach the northeast citizen with a drawn weapon, interact to rob them, then extract. This creates a robbery charge."
    return "Contract complete."
static func add_entry(data: Dictionary,text: String) -> void:
    data.journal.push_front(text)
    if data.journal.size()>80:data.journal.resize(80)
static func blocker(data: Dictionary,job: Dictionary) -> String:
    if not data.active.is_empty():return "Finish or abandon your active job first."
    if data.incarcerated or data.captured:return "Resolve custody first."
    var guild:=String(job.get("guild","merc"));var required:=int(job.get("required_rank",0))
    if not guild.is_empty() and Guild.rank(data.guilds,guild)<required:return "%s GUILD RANK %d REQUIRED"%[guild.to_upper(),required]
    return ""
static func accept(data: Dictionary,job: Dictionary) -> bool:
    if not blocker(data,job).is_empty():return false
    data.active=job.duplicate(true);add_entry(data,"%s TIER %d: %s / %d CR. %s"%["CRIME" if job.get("criminal",false) else "CONTRACT",job.get("difficulty",1),job.target,job.reward,objective(job)])
    return true
static func advance(data: Dictionary,task: String,speaker: String="Dock contact") -> bool:
    if data.active.is_empty() or next_task(data.active)!=task:return false
    var job:Dictionary=data.active
    match task:
        "rumor":add_entry(data,"%s: 'Ask the freight runner. %s pays for sealed crates and never collects them personally.'"%[speaker,job.target])
        "tail":add_entry(data,"OVERHEARD: 'The northeast safehouse keeps the payment manifest. %s's location is in the terminal.'"%job.target)
        "stakeout":add_entry(data,"STAKEOUT: movement pattern recorded without alerting the site.")
        "wiretap":add_entry(data,"WIRETAP: encrypted traffic captured and linked to the next location.")
        "eavesdrop":add_entry(data,"EAVESDROP: the meeting exposed a name and a transfer point.")
        "breach":add_entry(data,"SAFEHOUSE BREACHED: records and physical evidence secured.")
        "lieutenant":add_entry(data,"LIEUTENANT IDENTIFIED: the organization now points upward.")
        "target":add_entry(data,"TARGET RESOLVED: %s located through the completed clue chain."%job.target)
        "mastermind":add_entry(data,"MASTERMIND RESOLVED: %s's network is broken."%job.target)
        "intel","evidence":add_entry(data,"RECORDS EXTRACTED: identified %s and preserved the payment manifest."%job.target)
        "file_charges":add_entry(data,"CHARGES FILED: witness account and recovered manifest submitted against %s."%job.target)
        _:add_entry(data,"EXTRACTED: %s / %s objective confirmed."%[task,job.target])
    var site:=CaseDirector.current_site(job)
    if not site.is_empty():site.visited=true
    job.stage+=1;CaseDirector.reveal_current(job);return true
static func accidental_discovery(data: Dictionary,site_id: String,person_id: String="") -> bool:
    if data.active.is_empty() or not CaseDirector.accidental_discovery(data.active,site_id,person_id):return false
    add_entry(data,"ACCIDENTAL DISCOVERY: the target was found before the planned clue chain finished.")
    return true
static func finished(job: Dictionary) -> bool:return not job.is_empty() and next_task(job)=="done"
static func settle(data: Dictionary) -> int:
    var job:Dictionary=data.active
    if not finished(job) or data.settled.has(job.id):return 0
    var payment:=int(job.reward)
    data.settled[job.id]=payment;data.completed+=1;data.sequence+=1
    var guild:=String(job.get("guild","merc"))
    if not guild.is_empty():Guild.award(data.guilds,String(job.id),guild,int(job.get("difficulty",1)))
    add_entry(data,"PAID %d CR: %s / %s. %s"%[payment,job.type,job.target,"No guild credit for crime." if guild.is_empty() else "Guild standing earned."]);data.active={}
    return payment
