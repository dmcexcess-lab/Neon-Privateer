extends RefCounted
## Actual legal cases. Tactical capture is deliberately absent from this model.
static func defaults() -> Dictionary:
    return {"schema":1,"cases":[],"next_id":1,"sentence":{},"forced_faction":"","served":0,"fines_paid":0,"escapes":0,"time_served_days":0.0}
static func normalize(value: Dictionary) -> Dictionary:return defaults().merged(value.duplicate(true),true)
static func record(data: Dictionary,faction: String,offense: String,severity: int=1,fine: int=-1) -> Dictionary:
    if faction.is_empty():return {}
    var id:=int(data.next_id);data.next_id=id+1
    var weight:=clampi(severity,1,8)
    var entry:={"id":id,"faction":faction,"offense":offense,"fine":fine if fine>=0 else 75*weight,"days":30*weight,"status":"pending"}
    data.cases.append(entry);return entry
static func pending(data: Dictionary,faction: String) -> Array:
    return data.cases.filter(func(c):return c.status=="pending" and c.faction==faction)
static func assessment(data: Dictionary,faction: String) -> Dictionary:
    var summary:={"fine":0,"days":0,"ids":[],"faction":faction}
    for c in pending(data,faction):summary.fine+=int(c.fine);summary.days+=int(c.days);summary.ids.append(c.id)
    return summary
static func pay(data: Dictionary,faction: String,wallet: int) -> int:
    var bill:=assessment(data,faction)
    if bill.ids.is_empty() or wallet<int(bill.fine):return -1
    for c in data.cases:
        if bill.ids.has(c.id):c.status="fine_paid"
    data.fines_paid+=bill.fine
    if data.forced_faction==faction:data.forced_faction=""
    return bill.fine
static func sentence(data: Dictionary,faction: String) -> Dictionary:
    if not data.sentence.is_empty():return {}
    var bill:=assessment(data,faction)
    if bill.ids.is_empty():return {}
    for c in data.cases:
        if bill.ids.has(c.id):c.status="serving"
    data.forced_faction=faction
    data.sentence={"faction":faction,"ids":bill.ids.duplicate(),"days":bill.days}
    return data.sentence.duplicate(true)
static func release(data: Dictionary,actual_days: float=0.0) -> String:
    if data.sentence.is_empty():return ""
    var faction:=String(data.sentence.faction)
    for c in data.cases:
        if data.sentence.ids.has(c.id) and c.status=="serving":c.status="served"
    data.time_served_days+=maxf(0,actual_days)
    data.sentence={};data.served+=1;data.forced_faction="";return faction
static func escape(data: Dictionary,remaining_days: float=-1,actual_days: float=0.0) -> String:
    if data.sentence.is_empty():return ""
    var faction:=String(data.sentence.faction)
    for c in data.cases:
        if data.sentence.ids.has(c.id) and c.status=="serving":
            c.status="pending"
            if remaining_days>=0:c.days=maxi(1,int(ceil(float(c.days)*remaining_days/maxf(1,float(data.sentence.days)))))
    data.time_served_days+=maxf(0,actual_days)
    data.sentence={};data.forced_faction="";data.escapes+=1
    record(data,faction,"prison_escape",6)
    return faction
