extends SceneTree
const Puzzle=preload("res://covert/CasePuzzle.gd")
const Firewall=preload("res://hacking/FirewallGame.gd")
const Career=preload("res://covert/CovertCareer.gd")
var failures:Array[String]=[]
var checks:=0
func check(value: bool,message: String)->void:
    checks+=1
    if not value:failures.append(message);push_error("CASE PUZZLE FAIL: "+message)
func _initialize()->void:call_deferred("_run")
func _run()->void:
    var decoded:="NEXT LEAD: RELAY STATION 44 / Vesper"
    for type in ["substitution","word_find","sudoku"]:
        var challenge:Dictionary=Puzzle.create_for_type(type,4242,3,"FREIGHT",decoded)
        check(not challenge.get("prompt",[]).is_empty() and challenge.get("decoded_clue","")==decoded,"%s presents an encrypted lead and its eventual decoded location"%type)
        check(Puzzle.is_correct(challenge,String(challenge.answer)),"%s accepts the generated password"%type)
        check(not Puzzle.is_correct(challenge,"WRONG"),"%s rejects an incorrect password"%type)
    var case_job:Dictionary={"id":"cipher-case","seed":73,"planet":"p1","type":"bounty","target":"Sera Quill","difficulty":3,"stage":0,"steps":["rumor","wiretap","target"],"sites":[
        {"id":"site-a","planet":"p1","name":"DOCKSIDE BAR","task":"rumor","seed":17},
        {"id":"site-b","planet":"p2","name":"RELAY STATION 44","task":"wiretap","seed":29},
        {"id":"site-c","planet":"p3","name":"NIGHT ARCADE","task":"target","seed":41}]}
    var generated:Dictionary=Puzzle.create(case_job,"Vesper")
    check(generated.site_id=="site-a" and generated.decoded_clue.contains("RELAY STATION 44") and generated.decoded_clue.contains("Vesper"),"active case puzzle reveals the next actual dossier site and its planet")
    var firewall=Firewall.new();firewall.embedded=true;firewall.pay_brick_rewards=false;root.add_child(firewall);firewall.set_process(false);firewall.start_challenge(Firewall.default_profile(),17,1,"case-wiretap",true,generated)
    var settled:Array[bool]=[];firewall.challenge_finished.connect(func(success: bool):settled.append(success))
    firewall.sim.state="clear";firewall.sim.stage=1;firewall._settle_events()
    check(firewall.phase=="DECRYPT" and settled.is_empty(),"clearing Firewall reveals the attached clue puzzle before advancing the case")
    firewall.case_answer_entry.text="WRONG";firewall._submit_case_puzzle()
    check(firewall.phase=="DECRYPT" and settled.is_empty(),"wrong code keeps the puzzle open for another try")
    firewall.case_answer_entry.text=String(generated.answer);firewall._submit_case_puzzle()
    check(settled==[true] and bool(firewall.challenge_result.get("decrypted",false)) and firewall.challenge_result.get("decoded_clue","")==decoded,"solving emits a successful decrypt result with the decoded clue")
    var scene=load("res://main.tscn").instantiate();root.add_child(scene);scene.set_process(false);scene._create_new_career(1)
    var active_case:Dictionary=case_job.duplicate(true);active_case.stage=1
    scene.covert_profile.active=active_case;scene.current_planet="p2";scene.pending_case_hack_task="wiretap"
    scene.firewall.challenge_result={"difficulty":3,"reward":0,"trace":4.0,"trace_limit":40.0,"decrypted":true,
        "puzzle_type":generated.type,"ciphertext":generated.ciphertext,"decoded_clue":generated.decoded_clue}
    scene.firewall_open=true;scene.firewall.visible=true;scene.hub_open=false;scene._terminal_hack_finished(true)
    var saved_clues:Array=scene.covert_profile.active.get("clues",[])
    check(int(scene.covert_profile.active.stage)==2 and not saved_clues.is_empty() and bool(saved_clues[-1].get("encrypted",false)),"solved password advances the actual case and saves the encrypted clue trail")
    check(saved_clues[-1].get("puzzle_type","")==generated.type and saved_clues[-1].get("decoded","")==decoded,"campaign dossier retains puzzle type, ciphertext and decrypted location")
    scene.queue_free();firewall.queue_free();await process_frame
    if failures.is_empty():print("NEON CASE PUZZLES OK: %d checks, substitution, word-find, Sudoku and Firewall integration"%checks);quit(0)
    else:print("NEON CASE PUZZLES FAIL: "+str(failures));quit(1)
