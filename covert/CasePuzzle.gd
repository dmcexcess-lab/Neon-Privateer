extends RefCounted
## Small, deterministic codebreaking challenges attached to Privateer case leads.

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CaseDirector=preload("CaseDirector.gd")
const WORDS := ["DOCK", "RELAY", "ORBIT", "VAULT", "FREIGHT", "CIPHER", "NEXUS"]
const TYPES := ["substitution", "word_find", "sudoku"]

static func create(job: Dictionary, planet_label: String="") -> Dictionary:
    var site:Dictionary=CaseDirector.current_site(job)
    var sites:Array=job.get("sites",[])
    var next_stage:=int(job.get("stage",0))+1
    var next_site:Dictionary=sites[next_stage] if next_stage>=0 and next_stage<sites.size() else site
    var code:=String(WORDS[posmod(int(site.get("seed",job.get("seed",1))),WORDS.size())])
    var destination:=planet_label if not planet_label.is_empty() else String(next_site.get("planet",job.get("planet","UNKNOWN WORLD")))
    var decoded:="NEXT LEAD: %s / %s"%[String(next_site.get("name","FIELD CONTACT")),destination]
    var seed_number:=int(site.get("seed",job.get("seed",1)))+int(job.get("difficulty",1))*101
    var puzzle:=create_for_type(TYPES[posmod(seed_number,TYPES.size())],seed_number,int(job.get("difficulty",1)),code,decoded)
    puzzle["site_id"]=String(site.get("id",""))
    return puzzle

static func create_for_type(type: String,seed_number: int,difficulty: int,code: String,decoded_clue: String) -> Dictionary:
    var tier:=clampi(difficulty,1,5)
    match type:
        "substitution":
            var shift:=posmod(seed_number,25)+1
            return {"type":type,"difficulty":tier,"answer":code,"decoded_clue":decoded_clue,
                "ciphertext":_shift(code,shift),"shift":shift,
                "prompt":["SUBSTITUTION CIPHER","Decode the intercepted passphrase.","Alphabet shift: %d"%shift,"Enter the plaintext code word."]}
        "word_find":
            var generated:=_word_grid(code,seed_number,tier)
            var bank:Array=[code]
            for word in ["DOCK","RELAY","ORBIT","VAULT","FREIGHT","CIPHER","NEXUS"]:
                if word!=code and bank.size()<4:bank.append(word)
            return {"type":type,"difficulty":tier,"answer":code,"decoded_clue":decoded_clue,
                "grid":generated.grid,"word_bank":bank,"ciphertext":" ".join(generated.grid),
                "prompt":["WORD FIND / DECRYPTION GRID","Find one embedded password; enter it.","WORD BANK: "+" / ".join(bank)]+generated.grid}
        "sudoku":
            var generated:=_sudoku(seed_number,tier)
            return {"type":type,"difficulty":tier,"answer":generated.answer,"decoded_clue":decoded_clue,
                "grid":generated.grid,"ciphertext":" / ".join(generated.grid),
                "prompt":["4x4 SUDOKU / ACCESS CODE","Complete the blanks in reading order.","Rows: left to right; then top to bottom."]+generated.grid}
    return {}

static func is_correct(puzzle: Dictionary,attempt: String) -> bool:
    var expected:=String(puzzle.get("answer","" )).strip_edges().to_upper().replace(" ","").replace(",","")
    var supplied:=attempt.strip_edges().to_upper().replace(" ","").replace(",","")
    return not expected.is_empty() and supplied==expected

static func _shift(value: String,amount: int) -> String:
    var result:=""
    for i in value.length():
        var character:=value.substr(i,1);var index:=ALPHABET.find(character)
        result+=ALPHABET.substr(posmod(index+amount,ALPHABET.length()),1) if index>=0 else character
    return result

static func _word_grid(code: String,seed_number: int,difficulty: int) -> Dictionary:
    var size:=maxi(7+mini(3,difficulty),code.length())
    var rng:=RandomNumberGenerator.new();rng.seed=absi(seed_number)+1
    var rows:Array=[]
    for y in size:
        var row:PackedStringArray=[]
        for x in size:row.append(ALPHABET.substr(rng.randi_range(0,25),1))
        rows.append(row)
    var horizontal:=posmod(seed_number,2)==0
    var reverse:=posmod(seed_number,4)>=2
    if horizontal:
        var y:=rng.randi_range(0,size-1);var start:=rng.randi_range(0,size-code.length())
        for i in code.length():rows[y][start+i]=code.substr(code.length()-1-i if reverse else i,1)
    else:
        var x:=rng.randi_range(0,size-1);var start:=rng.randi_range(0,size-code.length())
        for i in code.length():rows[start+i][x]=code.substr(code.length()-1-i if reverse else i,1)
    var grid:Array=[]
    for row in rows:grid.append(" ".join(row))
    return {"grid":grid}

static func _sudoku(seed_number: int,difficulty: int) -> Dictionary:
    var rows:Array=[];var missing:Array=[];var complete:Array=[]
    for row in 4:
        var values:Array=[]
        for column in 4:values.append(String.num_int64(posmod(row*2+int(row/2)+column,4)+1))
        complete.append(values)
    var indices:Array=[]
    for index in 16:indices.append(index)
    var rng:=RandomNumberGenerator.new();rng.seed=absi(seed_number)+17
    for i in range(indices.size()-1,0,-1):
        var j:=rng.randi_range(0,i);var swap=indices[i];indices[i]=indices[j];indices[j]=swap
    var blank_count:=mini(8,2+difficulty);var blanks:Array[int]=[]
    for i in blank_count:blanks.append(int(indices[i]))
    blanks.sort()
    for index in blanks:
        var row:=int(index/4);var column:=index%4
        missing.append(String(complete[row][column]));complete[row][column]="_"
    for row in complete:rows.append(" ".join(row))
    return {"grid":rows,"answer":"".join(missing)}
