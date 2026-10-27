extends RefCounted
## Case graph and settlement are data, independent of any minigame view.
const NAMES := ["Mara Voss","Ivo Slate","Sera Quill","Niko Vale","Ash Renn","Len Orra"]
static func default_profile() -> Dictionary:
    return {"schema":1,"active":{},"journal":[],"settled":{},"sequence":0,"completed":0,"arrests":0,"gear":{"pistol":false,"armor":0},"ground":{},"challenge":{},"incarcerated":false}
static func decode(raw: Variant) -> Dictionary:
    var value:Variant=bytes_to_var(raw) if raw is PackedByteArray else raw
    return default_profile().merged(value.duplicate(true),true) if value is Dictionary else default_profile()
static func offer(planet: String,kind: String,sequence: int) -> Dictionary:
    var seed_number:=absi((planet+kind+str(sequence)).hash())
    var target:String=NAMES[seed_number%NAMES.size()]
    return {"id":"%s:%s:%d"%[planet,kind,sequence],"planet":planet,"type":kind,"target":target,"stage":0,"seed":seed_number,"reward":900 if kind=="track" else 650 if kind=="recover" else 450}
static func next_task(job: Dictionary) -> String:
    if job.is_empty():return "port"
    if job.type=="assault":return "assault"
    match int(job.stage):
        0:return "rumor"
        1:return "tail" if job.type=="track" else "intel"
        2:return "intel" if job.type=="track" else "done"
        3:return "bounty"
    return "done"
static func objective(job: Dictionary) -> String:
    if job.is_empty():return "Choose a contract. Walk the port for contacts; buy field gear before deploying."
    var who:=String(job.target)
    match next_task(job):
        "rumor":return "Ask a dock contact about %s. Approach an NPC in the port and interact, with your weapon holstered."%who
        "tail":return "A runner handles %s's freight. Listen to the meeting in the northeast room for 6 seconds, unseen and holstered. Extract with the lead."%who
        "intel":return "Search the northeast safehouse terminal. Break its Firewall and hold extraction for 8 seconds to bring the records home."
        "bounty":return "The safehouse manifest identifies %s in the southeast room. Bounty is dead or alive. Secure the target, then extract."%who
        "assault":return "Known raider compound. No investigation needed: defeat all seven hostiles, then hold extraction for 8 seconds."
    return "Contract complete."
static func add_entry(data: Dictionary,text: String) -> void:
    data.journal.push_front(text)
    if data.journal.size()>80:data.journal.resize(80)
static func accept(data: Dictionary,job: Dictionary) -> bool:
    if not data.active.is_empty() or data.incarcerated:return false
    data.active=job.duplicate(true);add_entry(data,"CONTRACT: %s / %s / %d CR. %s"%[job.type,job.target,job.reward,objective(job)])
    return true
static func advance(data: Dictionary,task: String,speaker: String="Dock contact") -> bool:
    if data.active.is_empty() or next_task(data.active)!=task:return false
    var job:Dictionary=data.active
    match task:
        "rumor":add_entry(data,"%s: 'Ask the freight runner. %s pays for sealed crates and never collects them personally.'"%[speaker,job.target])
        "tail":add_entry(data,"OVERHEARD: 'The northeast safehouse keeps the payment manifest. %s's room number is in the terminal, not on the crates.'"%job.target)
        "intel":add_entry(data,"MANIFEST RECOVERED: %s uses the southeast room. Records secured at extraction."%job.target)
        "bounty":add_entry(data,"TARGET SECURED: %s. Extracted from the compound."%job.target)
        "assault":add_entry(data,"COMPOUND CLEARED: all hostiles defeated; extraction confirmed.")
    job.stage+=1
    return true
static func finished(job: Dictionary) -> bool:
    return not job.is_empty() and ((job.type=="track" and job.stage>=4) or (job.type=="recover" and job.stage>=2) or (job.type=="assault" and job.stage>=1))
static func settle(data: Dictionary) -> int:
    var job:Dictionary=data.active
    if not finished(job) or data.settled.has(job.id):return 0
    var payment:=int(job.reward)
    data.settled[job.id]=payment;data.completed+=1;data.sequence+=1
    add_entry(data,"PAID %d CR: %s / %s. Contract closed."%[payment,job.type,job.target]);data.active={}
    return payment
