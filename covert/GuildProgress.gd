extends RefCounted
const THRESHOLDS := [0,30,100,240,500]
const TITLES := ["UNLICENSED","ASSOCIATE","OPERATOR","VETERAN","MASTER"]
static func defaults() -> Dictionary:return {"trader":0,"merc":0,"paid_jobs":{}}
static func normalize(value: Dictionary) -> Dictionary:return defaults().merged(value.duplicate(true),true)
static func rank(data: Dictionary,guild: String) -> int:
    var result:=0
    for i in THRESHOLDS.size():
        if int(data.get(guild,0))>=THRESHOLDS[i]:result=i
    return result
static func required(difficulty: int) -> int:return clampi(difficulty-1,0,4)
static func award(data: Dictionary,id: String,guild: String,difficulty: int) -> int:
    if data.paid_jobs.has(id) or guild not in ["trader","merc"]:return 0
    var gain:=10*clampi(difficulty,1,5);data.paid_jobs[id]=true;data[guild]=int(data.get(guild,0))+gain;return gain
