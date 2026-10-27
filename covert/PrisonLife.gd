extends RefCounted
## Local prison routine. The later whole-career needs/storyteller layer is separate.
const LEGAL_DAYS_PER_GAME_DAY := 30.0
const SECONDS_PER_HOUR := 1.0
const ACTIVITIES := {"eat":1.0,"train":3.0,"work":4.0,"socialize":2.0,"sleep":8.0,"check_in":1.0}
var data:Dictionary={}
var events:Array=[]
func start(sentence: Dictionary,seed_number: int) -> void:
    data={"schema":1,"position":Vector2(195,300),"destination":Vector2(195,300),"sentence":sentence.duplicate(true),"hours":0.0,"served_days":0.0,"added_days":0.0,"remission":0.0,"conduct":0.0,"hunger":75.0,"energy":80.0,"morale":55.0,"fitness":0,"wages":0,"relations":{"Dax":0,"Loa":0,"Brin":0},"activity":"","remaining":0.0,"duration":0.0,"paused":false,"escape_active":false,"escape_until":0.0,"opportunity_day":-1,"seed":seed_number,"released":false,"talk_to":"Dax","notice":"Intake complete. Attend check-in, eat, work, train or talk while serving your sentence."}
    events.clear()
func restore(saved: Dictionary) -> bool:
    if saved.get("schema",0)!=1 or not saved.get("sentence") is Dictionary:return false
    data=saved.duplicate(true);data.paused=true;events.clear();return true
func remaining_days() -> float:
    if data.is_empty():return 0
    return maxf(0,float(data.sentence.days)+float(data.added_days)-float(data.served_days)-float(data.remission))
func act(activity: String,npc: String="Dax") -> bool:
    if data.is_empty() or data.paused or data.escape_active or data.released or not String(data.activity).is_empty() or not ACTIVITIES.has(activity):return false
    if activity in ["train","work"] and data.energy<15:data.notice="Too exhausted. Eat or sleep first.";return false
    if activity=="socialize" and not data.relations.has(npc):return false
    data.destination={"eat":Vector2(85,260),"train":Vector2(300,270),"work":Vector2(195,335),"socialize":Vector2(90+int(data.relations.keys().find(npc))*80,280),"sleep":Vector2(75,180),"check_in":Vector2(100,335)}[activity]
    if activity=="socialize":data.destination=inmate_position(int(data.relations.keys().find(npc)),float(data.hours))
    data.activity=activity;data.duration=ACTIVITIES[activity];data.remaining=data.duration;data.talk_to=npc;return true
static func inmate_position(index: int,hours: float) -> Vector2:
    var hour:=fmod(hours,24)
    return Vector2(65+index*106,180) if hour<6 or hour>21 else Vector2(70+index*35,260) if hour<9 else Vector2(265+index*25,270) if hour<15 else Vector2(100+index*50,335)
func can_escape() -> bool:
    return not data.is_empty() and not data.paused and not data.escape_active and not data.released and String(data.activity).is_empty() and float(data.escape_until)>float(data.hours)
func begin_escape() -> bool:
    if not can_escape():return false
    data.escape_active=true;data.notice="Laundry gate is unguarded. An escape attempt will be a real Breach sortie.";return true
func failed_escape() -> void:
    data.escape_active=false;data.conduct=0.0;data.added_days+=30.0;data.escape_until=0.0;data.paused=true
    data.notice="Recaptured: 30 days added, good behavior lost. Your sentence continues; this was not a release.";events.clear()
func step(delta: float) -> void:
    if data.is_empty() or data.paused or data.escape_active or data.released:return
    var hours:=clampf(delta,0,.25)/SECONDS_PER_HOUR
    data.position=Vector2(data.get("position",Vector2(195,300))).move_toward(Vector2(data.get("destination",Vector2(195,300))),hours*200)
    data.hours+=hours;data.served_days+=hours*LEGAL_DAYS_PER_GAME_DAY/24.0
    data.hunger=maxf(0,data.hunger-hours*2);data.energy=maxf(0,data.energy-hours*.7)
    data.morale=clampf(data.morale+hours*(.3 if data.hunger>25 and data.energy>20 else -.7),0,100)
    # Earned remission is capped, and cannot instantly finish a newly imposed term.
    var cap:=float(data.sentence.days)*.2
    if data.conduct>=3:data.remission=minf(cap,float(data.remission)+hours*.2)
    if not String(data.activity).is_empty():
        data.remaining=maxf(0,data.remaining-hours)
        if data.remaining<=0:_finish_activity()
    var day:=int(floor(float(data.hours)/24))
    if day>int(data.opportunity_day):
        data.opportunity_day=day
        if day>0 and (int(data.seed)+day)%3==0:
            data.escape_until=data.hours+8;data.notice="Loa: 'Laundry gate is open until the next shift.' Escape opportunity available for eight prison hours."
    if remaining_days()<=0:
        data.released=true;events.append({"kind":"served"})
func _finish_activity() -> void:
    var activity:=String(data.activity);data.activity=""
    match activity:
        "eat":data.hunger=minf(100,data.hunger+55);data.notice="Meal finished."
        "sleep":data.energy=minf(100,data.energy+75);data.notice="Rested."
        "train":data.fitness+=1;data.energy=maxf(0,data.energy-12);data.notice="Training completed. Fitness earned for release."
        "work":data.wages+=5;data.conduct+=1;data.energy=maxf(0,data.energy-10);data.notice="Shift completed: 5 credits payable on lawful release; good behavior improved."
        "check_in":data.conduct+=2;data.notice="Check-in recorded. Consistent good behavior earns up to 20% remission."
        "socialize":
            data.relations[data.talk_to]+=1;data.morale=minf(100,data.morale+16)
            data.notice="%s: '%s'"%[data.talk_to,{"Dax":"The yard is quiet after breakfast. Better than staring at your bunk.","Loa":"Keep an eye on the laundry roster. Shifts leave gaps.","Brin":"Work your shifts and check in. They do count it."}[data.talk_to]]
