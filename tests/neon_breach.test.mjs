import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {performance} from 'node:perf_hooks';

const html=readFileSync(new URL('../neon-breach/index.html',import.meta.url),'utf8');
const css=readFileSync(new URL('../neon-breach/src/style.css',import.meta.url),'utf8');
const source=html.match(/<script type="module">([\s\S]*?)<\/script>/)?.[1];
assert.ok(source,'standalone game module is available');
const eventTarget=()=>{
  const listeners=new Map();
  return {
    addEventListener(type,handler){if(!listeners.has(type))listeners.set(type,[]);listeners.get(type).push(handler);},
    dispatch(type,event={}){for(const handler of listeners.get(type)||[])handler(event);},
    removeEventListener(type,handler){listeners.set(type,(listeners.get(type)||[]).filter(fn=>fn!==handler));}
  };
};
const makeElement=()=>({
  ...eventTarget(),
  style:{},disabled:false,textContent:'',innerHTML:'',scrollTop:0,classList:{add(){},remove(){},toggle(){}},
  setAttribute(){},setPointerCapture(){},append(){},appendChild(){},replaceChildren(){},focus(){},
  getContext(){return new Proxy({}, {get:()=>()=>{}})},
  getBoundingClientRect(){return {left:0,top:0,width:120,height:120}},
  querySelector(){return makeElement()}
});
const elements=new Map(),storage=new Map();
const privateerMessages=[];
const testFailures=[];
let musicInstances=0;
// Reproducible headings, pauses and spawn offsets for traversal regressions.
let randomSeed=0x1234abcd;
const seededMath=Object.create(Math);
seededMath.random=()=>{randomSeed=(Math.imul(randomSeed,1664525)+1013904223)>>>0;return randomSeed/4294967296;};
const document={
  ...eventTarget(),body:makeElement(),hidden:false,createElement:makeElement,
  getElementById(id){if(!elements.has(id))elements.set(id,makeElement());return elements.get(id);}
};
const sandbox={
  ...eventTarget(),
  Math:seededMath,
  console,document,localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,String(v))},navigator:{getGamepads(){return []}},
  parent:{postMessage(message){privateerMessages.push(message)}},location:{origin:'http://localhost',search:''},URLSearchParams,
  innerWidth:1080,innerHeight:830,devicePixelRatio:1,performance,
  requestAnimationFrame(){},
  Audio:class{constructor(){musicInstances++;this.paused=true;this.currentTime=0;}addEventListener(){} play(){this.paused=false;return Promise.resolve()} pause(){this.paused=true;}},
};
vm.runInNewContext(source+`
;globalThis.__breach={game,generateFloor,beginFloor,updateEnemies,emitNoise,alertEnemy,
  canSpot,patrolIntent,prepareSearch,TYPE,SHOP_GEAR,VISION,enemyBudget,roomCount,
  initializeBehavior,buildPostRoute,floorPatrolCircuit,restoreFloorPatrols,planFloorPoints,chooseCircleWander,roomAt,walkable,RNG,propAt,navigationPoint,
  updateExtraction,updateCaseObjective,EXTRACTION,killEnemy,floorClearAward,floorAdvanceAward,stealthAward,
  enterHQ,resetRun,saveGame,loadGame,startReload,shootPlayer,updateWeaponTimers,WEAPONS,
  toggleWeaponDraw,useMedkit,equipFromStash,collectPickup,damageFurniture,fastTravel,openTravel,nextFloor,
  getAudioSettings,setAudioSettings,unlockAudio,rangedCoverIntent,strata,clearSight,update,togglePause,purchase,captureInputs,inputs,
  startPrivateerMission,finishPrivateerMission,enterPrivateerPort,updatePort,damagePortActor,reportPortCrime,updateBullets,makeBullet,
  discoverPortStations,nearbyStation,nearbyPortActor,interactPort,
  advanceOpeningCall,openingCallActive(){return openingCall.active;},
  setPrivateerContext(value){privateerContext=value}};
`,vm.createContext(sandbox),{timeout:15000,filename:'neon-breach-module.js'});
const b=sandbox.__breach;

test('starport conversations wrap, preserve dossier line breaks and stay inside the viewport',()=>{
  assert.match(css,/#toast\{[^}]*max-width:min\(680px,calc\(100vw - 28px\)\)/);
  assert.match(css,/#toast\{[^}]*white-space:pre-line/);
  assert.match(css,/#toast\{[^}]*overflow-wrap:anywhere/);
});

test('spaceport security uses armored cyber-police gear rather than civilian hats',()=>{
  const renderer=source.slice(source.indexOf('function drawPortActors'),source.indexOf('function drawHQDirectory'));
  assert.match(renderer,/Broad armored shoulders and a plated, clearly marked police vest/);
  assert.match(renderer,/ctx\.fillRect\(-8,-10,16,12\)/,'armored chest plate reads separately from the uniform');
  assert.match(renderer,/Angular riot helmet, side comms and a broad illuminated face shield/);
  assert.match(renderer,/ctx\.fillRect\(-14,-28,4,9\);ctx\.fillRect\(10,-28,4,9\)/,'helmet has visible radio/ear modules');
  assert.match(renderer,/actor\.alert\?'POLICE · ALERT':'POLICE'/,'guards carry a readable police marking above the sprite');
  assert.match(renderer,/if\(!guard\)\{\s*const hat=ap\.hat/,'random civilian hats stay confined to civilians');
});

test('full spaceports support armed play and guards react to gunfire',()=>{
  const context={mode:'spaceport',requestId:'port-test',seed:731,planetId:'p-port',planetName:'Test Port',archetype:'INDUSTRIAL',faction:'Test Security',loadout:{weapon:'auto_pistol'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  assert.equal(b.game.mode,'PORT');assert.equal(b.game.player.weapon,'auto_pistol');
  const civilian=b.game.world.actors.find(actor=>actor.kind==='civilian');
  civilian.x=b.game.player.x+50;civilian.y=b.game.player.y;civilian.hp=2;
  const guards=b.game.world.actors.filter(actor=>actor.kind==='guard');
  guards.forEach((guard,index)=>{guard.alert=false;guard.x=b.game.player.x+(index===0?220:2500+index*500);guard.y=b.game.player.y;guard.facing=Math.PI;});
  b.makeBullet(b.game.player.x,b.game.player.y,0,'player',.75,440,'#fff',4);
  b.updateBullets(.05);
  assert.ok(civilian.hp<2,'player bullet damages a civilian inside the persistent port');
  assert.ok(guards[0].alert,'a nearby patrol hears the shot and responds');
  assert.ok(guards.slice(1).every(guard=>!guard.alert),'distant patrols do not receive a map-wide alert: '+JSON.stringify(guards.map(guard=>({x:guard.x,alert:guard.alert}))));
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-crime'&&message.detail.offense==='assault_civilian'),'the full game receives the port crime');
  b.setPrivateerContext(null);
});

test('port crime detection checks line of sight and lets nearby civilians report locally',()=>{
  const guard=(id,x,y,facing=0)=>({id,kind:'guard',x,y,facing,target:{x:x+100,y},alert:false,down:false});
  const civilian=(id,x,y)=>({id,kind:'civilian',x,y,down:false,robbed:false});
  b.game.player={x:0,y:0,hp:10,maxHp:10,weapon:'hands'};
  b.game.world={...openWorld(),isSpaceport:true,planetName:'TEST',actors:[guard('visible',200,0,Math.PI),guard('distant',1700,0,Math.PI)],crime:{heat:0,witnessed:false}};
  let response=b.reportPortCrime('test_visible',1);
  assert.equal(response.respondingGuards,1,'only the officer with nearby unobstructed sight reacts');
  assert.equal(b.game.world.actors[0].alert,true);assert.equal(b.game.world.actors[1].alert,false);

  const blocked={...openWorld(),isSpaceport:true,planetName:'TEST',actors:[guard('blocked',200,0,Math.PI)],crime:{heat:0,witnessed:false}};
  blocked.rooms[0].cover.push({x:100,y:0,w:70,h:90,hp:999,maxHp:999});
  b.game.world=blocked;response=b.reportPortCrime('test_occluded',1);
  assert.equal(response.witnessed,false,'a solid interior wall blocks the guard sightline');
  assert.equal(blocked.actors[0].alert,false,'an occluded nearby patrol stays on its routine');

  const local=guard('local_radio',720,0),remote=guard('remote_radio',1900,0);
  b.game.world={...openWorld(),isSpaceport:true,planetName:'TEST',actors:[civilian('witness',60,0),local,remote],crime:{heat:0,witnessed:false}};
  response=b.reportPortCrime('test_crowd_witness',1);
  assert.equal(response.witnessCount,1,'a nearby unobstructed civilian witnesses the offense');
  assert.equal(local.alert,true,'a local officer receives the witness report');
  assert.equal(remote.alert,false,'a distant patrol remains unaware');
});

test('first bounty opens with a one-shot call, auto-accepts, and teaches ask-around, tail, hack, and hideout clues',()=>{
  const context={mode:'spaceport',requestId:'opening-adventure',seed:73,arrivalSeed:1901,planetId:'opening-port',planetName:'New Dawn',faction:'Port Authority',firstAdventure:{active:true,step:'READY',contactName:'Mara Voss'},loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  const mara=b.game.world.actors.find(actor=>actor.openingContact),kest=b.game.world.actors.find(actor=>actor.openingSubject);
  assert.ok(mara&&kest);assert.equal(mara.name,'Mara Voss');assert.equal(kest.name,'Kest Arden');
  assert.equal(b.openingCallActive(),true,'first normal port landing plays the authored phone call');
  b.game.player.x=mara.x;b.game.player.y=mara.y;b.interactPort();
  assert.equal(privateerMessages.some(message=>message.type==='dmc-privateer-rumor'),false,'the cinematic blocks port actions until answered');
  const clock=b.game.portClock;b.updatePort(.4);assert.equal(b.game.portClock,clock,'the port scene waits under the dialogue');
  for(let i=0;i<4;i++)b.advanceOpeningCall();
  assert.equal(b.openingCallActive(),false);assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-opening-call'&&message.detail.accepted),'the call ends with an automatic bounty acceptance');
  b.game.player.x=mara.x;b.game.player.y=mara.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-rumor'&&message.detail.openingAdventure),'opening contact delivers the authored job');
  kest.target={x:kest.x,y:kest.y};kest.speed=0;
  b.game.player.x=kest.x+70;b.game.player.y=kest.y;
  b.inputs.sneakTouch=true;
  assert.equal(b.nearbyPortActor(),kest,'opening lead makes the named runner the interactable subject');b.interactPort();
  assert.equal(kest.listenProgress||0,0,'dialogue alone cannot fabricate an eavesdrop clue');
  b.game.player.x=kest.x+150;
  for(let i=0;i<170;i++)b.updatePort(.034);
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-rumor'&&message.detail.subjectObserved),'a sustained sneaking listen yields the manifest lead');
  assert.equal(b.game.world.caseContext.task,'wiretap','eavesdropping advances the live objective toward an illegal terminal');
  b.game.world.activeContract=true;const terminal=b.game.world.stations.find(station=>station.service==='terminal');
  const guards=b.game.world.actors.filter(actor=>actor.kind==='guard');
  guards.forEach((guard,index)=>{guard.alert=false;guard.x=index===0?terminal.x+60:terminal.x+2500+index*400;guard.y=terminal.y;guard.facing=Math.PI;});
  b.game.player.x=terminal.x;b.game.player.y=terminal.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-crime'&&message.detail.offense==='unauthorized_terminal_access'&&message.detail.witnessed),'illegal shortcut during the legal contract raises witnessed law response');
  assert.equal(guards[0].alert,true,'the nearby officer at the terminal responds');
  assert.ok(guards.slice(1).every(guard=>!guard.alert),'distant officers do not teleport into the response');
  b.setPrivateerContext(null);
});

test('visible illegal spaceport terminals reroll by arrival and launch distinct hacks',()=>{
  const context={mode:'spaceport',requestId:'illegal-terminal-test',seed:881,arrivalSeed:77101,planetId:'p-illegal',planetName:'Relay Port',archetype:'FROZEN',faction:'Relay Security',loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  const firstArrival=b.game.world.stations.filter(station=>station.service==='terminal'&&station.id!=='terminal').map(station=>[station.id,station.x,station.y]);
  const terminal=b.game.world.stations.find(station=>station.service==='terminal'&&station.id!=='terminal');
  assert.ok(firstArrival.length>=4&&firstArrival.length<=7);
  assert.ok(b.game.world.stations.filter(station=>station.service==='terminal').every(station=>station.illegal&&!station.hidden&&station.discovered),'illegal terminals are visible from arrival');
  b.game.player.x=terminal.x;b.game.player.y=terminal.y;
  assert.equal(b.nearbyStation(),terminal);assert.equal(b.interactPort(),true);
  const message=privateerMessages.at(-1);
  assert.equal(message.type,'dmc-privateer-terminal');assert.equal(message.detail.terminal,terminal.id);assert.equal(message.detail.hidden,false);assert.equal(message.detail.illegal,true);
  assert.ok(message.detail.difficulty>=1&&message.detail.difficulty<=5,'terminal reports its randomized security difficulty');
  assert.equal(typeof message.detail.seed,'number','every illegal terminal receives its own deterministic hack seed');
  const nextContext={...context,arrivalSeed:77102};b.enterPrivateerPort(nextContext);
  assert.notDeepEqual(b.game.world.stations.filter(station=>station.service==='terminal'&&station.id!=='terminal').map(station=>[station.id,station.x,station.y]),firstArrival,'a new landing rerolls visible illegal terminals');
  b.setPrivateerContext(null);
});

test('starport dealers, needs and chosen NPC contacts are physical and persistent',()=>{
  const contact={'p-social:npc-8':{name:'Dax Morrow',trust:5,bond:'FRIEND',path:'friendship',venue:'bar',role:'regular'}};
  const context={mode:'spaceport',requestId:'social-test',seed:532,arrivalSeed:9081,planetId:'p-social',planetName:'Social Port',archetype:'LUSH',faction:'Port Union',contacts:contact,needs:{hunger:18,energy:20,morale:40,social:22},story:{active_dossier:{title:'THE DAX THREAD',status:'OPEN',clues:['one'],objective:'Find the missing ship.'}},loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  assert.ok(b.game.player.speed<200,'unmet hunger and energy have a real movement consequence');
  const known=b.game.world.actors.find(actor=>actor.contactId==='p-social:npc-8');
  assert.equal(known.connected,true);assert.equal(known.name,'Dax Morrow');assert.equal(known.speed,0,'saved contacts return to their known venue instead of becoming disposable crowds');
  b.game.player.x=known.x;b.game.player.y=known.y;b.interactPort();
  const contactMessage=privateerMessages.filter(message=>message.type==='dmc-privateer-contact'&&message.detail.id===known.contactId).at(-1);
  assert.ok(contactMessage,'talking exchanges persistent contact information');
  assert.deepEqual(contactMessage.detail.appearance,known.appearance,'contact save payload includes the distinctive NPC appearance');
  const dealer=b.game.world.stations.find(station=>station.service==='firewall_dealer');b.game.player.x=dealer.x;b.game.player.y=dealer.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-service'&&message.detail.service==='firewall_dealer'),'hacking hardware is bought through a physical dealer');
  const guildhall=b.game.world.structures.find(building=>building.service==='contracts');
  const guildDoor=b.game.world.stations.find(station=>station.building===guildhall.id);b.game.player.x=guildDoor.x;b.game.player.y=guildDoor.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-service'&&message.detail.service==='contracts'),'the guild menu opens from its building entrance');
  const venue=b.game.world.stations.find(station=>station.service==='venue'&&station.venueKind==='club');b.game.player.x=venue.x;b.game.player.y=venue.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-venue'&&message.detail.kind==='club'),`clubs feed the needs and relationship layer: ${JSON.stringify(privateerMessages.slice(-4))}`);
  assert.equal(b.game.world.stations.some(station=>station.service==='dossier'),false,'the journal is not a physical port location');
  elements.get('dossierButton').dispatch('click');
  assert.ok(b.game.dossierOpen&&privateerMessages.some(message=>message.type==='dmc-privateer-dossier'),'the player HUD button opens personal clue dossiers');
  elements.get('dossierDone').dispatch('click');
  b.enterPrivateerPort({...context,arrivalSeed:9082,contacts:{...contact,[known.contactId]:{...contact[known.contactId],appearance:contactMessage.detail.appearance}}});
  assert.deepEqual(b.game.world.actors.find(actor=>actor.contactId===known.contactId).appearance,known.appearance,'revisited known contact retains their original appearance');
  b.setPrivateerContext(null);
});

test('active cases use illegal port terminals for wiretaps and named off-port landings for field operations',()=>{
  const site={id:'site:44:1',name:'ORBITAL ANNEX 44',type:'orbital_annex',task:'tail',seed:9981,station:true,discovered:true};
  const accidentalSite={id:'site:44:8',name:'SAFEHOUSE 91',type:'safehouse',task:'mastermind',seed:771,discovered:false};
  const context={mode:'spaceport',requestId:'case-site-test',seed:885,arrivalSeed:2001,planetId:'p-case',planetName:'Case Port',faction:'Case Authority',caseContext:{id:'case:44',task:'tail',difficulty:4,target:'Sera Quill',site,accidentalSite,accidentalPerson:'suspect:44:3'},loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  const landing=b.game.world.stations.find(station=>station.service==='case_site');
  assert.ok(landing&&landing.label.includes('ORBITAL ANNEX 44'),'case creates an actual landing distinct from the main starport');
  const unknown=b.game.world.stations.find(station=>station.accidental);b.game.player.x=unknown.x;b.game.player.y=unknown.y;b.interactPort();
  assert.ok(unknown&&!unknown.hidden&&unknown.discovered,'unmarked off-port landing signals stay visible rather than using hidden nodes');
  assert.ok(privateerMessages.some(item=>item.type==='dmc-privateer-case-discovery'&&item.detail.site===accidentalSite.id),'exploration can uncover the real target before the planned clue chain');
  b.game.player.x=landing.x;b.game.player.y=landing.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-loading'&&message.detail.mode==='case-site'),'tail landing launches a tailored field operation in the larger career');
  const wiretapContext={...context,caseContext:{...context.caseContext,task:'wiretap',site:{},difficulty:4,clues:[{kind:'wiretap',status:'VERIFIED',text:'Terminal traffic captured',encrypted:true,puzzle_type:'word_find',ciphertext:'R E L A Y',decoded:'NEXT LEAD: RELAY STATION 44 / Vesper'}]}};
  b.enterPrivateerPort(wiretapContext);assert.equal(b.game.world.stations.some(station=>station.service==='case_site'&&!station.accidental),false,'wiretaps are done at the visible terminals in the regular port');
  elements.get('dossierButton').dispatch('click');
  assert.match(elements.get('dossierContent').innerHTML,/DECRYPTED VIA WORD FIND · NEXT LEAD: RELAY STATION 44 \/ Vesper/,'decoded clue and puzzle type appear in the full dossier opened from the player HUD');
  elements.get('dossierDone').dispatch('click');
  const terminal=b.game.world.stations.find(station=>station.service==='terminal');b.game.player.x=terminal.x;b.game.player.y=terminal.y;b.interactPort();
  assert.ok(privateerMessages.some(message=>message.type==='dmc-privateer-terminal'&&message.detail.illegal),'the clue uses a visible illegal terminal rather than a detached hack node');
  const audioSite={...site,id:'site:44:2',task:'eavesdrop'};
  const audioContext={...context,caseContext:{...context.caseContext,task:'eavesdrop',site:audioSite}};
  b.enterPrivateerPort(audioContext);const audioLanding=b.game.world.stations.find(station=>station.service==='case_site'&&!station.accidental);
  b.game.player.x=audioLanding.x;b.game.player.y=audioLanding.y;b.interactPort();
  assert.equal(b.game.caseTask,'eavesdrop','eavesdropping is a real surveillance operation, not another hack');
  b.setPrivateerContext(null);
});

test('spaceport exploration can surface multiple case-linked intermediate leads',()=>{
  const first={id:'explore:77:1',name:'LISTENING POST 27',task:'tail',linked_site_id:'site:77:1'};
  const second={id:'explore:77:2',name:'RELAY STATION 62',task:'wiretap',linked_site_id:'site:77:2'};
  const context={mode:'spaceport',requestId:'exploration-leads',seed:777,arrivalSeed:5,planetId:'p-leads',planetName:'Lead Port',caseContext:{id:'case:77',task:'rumor',difficulty:3,target:'Ivo Slate',accidentalSites:[{site:first,person:''},{site:second,person:''}]},loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  const leads=b.game.world.stations.filter(station=>station.service==='case_site'&&station.accidental);
  assert.equal(leads.length,2,'the port presents multiple independent exploration locations together');
  assert.notDeepEqual(leads.map(station=>[station.x,station.y])[0],leads.map(station=>[station.x,station.y])[1],'each lead has its own map location');
  for(const lead of leads){b.game.player.x=lead.x;b.game.player.y=lead.y;b.interactPort();}
  const discovered=privateerMessages.filter(message=>message.type==='dmc-privateer-case-discovery').slice(-2).map(message=>message.detail.site);
  assert.deepEqual(discovered,[first.id,second.id],'visiting each location returns its own linked clue to the main career');
  b.setPrivateerContext(null);
});

test('Privateer dossier browses every clue with source, confidence, location and linked records',()=>{
  const clues=Array.from({length:6},(_,index)=>({id:`clue-${index}`,kind:index?'wiretap':'rumor',status:index?'VERIFIED':'UNVERIFIED',text:`Lead record ${index+1}`,source:`Contact ${index+1}`,confidence:index?.95:.25,location:`Planet ${index+1}`,site_id:`site-${index+1}`,subject_id:'suspect-a',encrypted:index===5,puzzle_type:'word_find',decoded:'Relay Station'}));
  Object.assign(clues[0],{side_lead:true,related_task:'wiretap',related_location:'Relay Station 2',related_site_id:clues[1].site_id});
  const evidence=clues.slice(1).map((clue,index)=>({id:`evidence-${index+1}`,kind:'wiretap',site_id:clue.site_id,source:clue.source,verified:true}));
  const context={mode:'spaceport',requestId:'dossier-browser',seed:601,arrivalSeed:601,planetId:'p-dossier',planetName:'Dossier Port',caseContext:{id:'case-dossier',target:'Sera Quill',task:'wiretap',difficulty:4,dossierSummary:'6 clues · 2 suspects · next wiretap',objective:'Visit Relay Station',leadPlanetName:'Vesper',clues,suspects:[{id:'suspect-a',name:'Sera Quill',role:'Target',status:'SUSPECTED'}],evidence},loadout:{weapon:'hands'}};
  b.setPrivateerContext(context);b.enterPrivateerPort(context);
  assert.equal(b.game.world.stations.some(item=>item.service==='dossier'),false,'there is no physical dossier station');
  assert.match(html,/id="dossierButton"[^>]*>JOURNAL</,'the HUD contains a labeled, player-clickable journal button');
  elements.get('dossierButton').dispatch('click');
  const panel=elements.get('caseDossier'),content=elements.get('dossierContent').innerHTML;
  assert.equal(b.game.dossierOpen,true,'opening the HUD journal pauses port simulation');
  assert.equal((content.match(/id="dossier-clue-/g)||[]).length,6,'the entire clue history is shown rather than only the latest four');
  assert.match(content,/SOURCE · Contact 1 · LOCATION · Planet 1/);
  assert.match(content,/CONFIDENCE · 95%/);
  assert.match(content,/href="#dossier-person-suspect-a"/,'clues link to a persistent suspect record');
  assert.match(content,/href="#dossier-evidence-evidence-1"/,'clues link to preserved evidence');
  assert.match(content,/href="#dossier-location-site-6"/,'clue locations link to the known-location index');
  assert.match(content,/FOLLOW-UP LEAD · wiretap · Relay Station 2/,'exploration clue names the intermediate step and location it points toward');
  assert.match(content,/href="#dossier-clue-clue-1">FOLLOW-UP · wiretap/,'when the follow-up is later recorded, the dossier links both clues');
  assert.match(content,/DECRYPTED VIA WORD FIND · Relay Station/);
  assert.match(css,/\.dossier-content\{[^}]*overflow:auto/,'dossier body has independent scrolling');
  assert.match(html,/id="caseDossier"[^>]*role="dialog"/);
  elements.get('dossierDone').dispatch('click');assert.equal(b.game.dossierOpen,false,'return control closes the dossier');
  assert.equal(panel!==undefined,true);b.setPrivateerContext(null);
});

test('Privateer mission approaches have distinct rules and contract rewards',()=>{
  b.setPrivateerContext({mode:'spaceport',requestId:'test',planetId:'p-test',loadout:{weapon:'hands'}});
  b.startPrivateerMission({style:'hot',difficulty:1,seed:919,objective:'raid'});
  assert.equal(b.game.detectedThisFloor,true,'hot missions begin fully alerted');
  assert.ok(b.game.enemies.length>0&&b.game.enemies.every(enemy=>enemy.state==='alert'));
  b.game.runCash=7;b.finishPrivateerMission('completed');
  let result=privateerMessages.at(-1).detail;
  assert.equal(result.style,'hot');assert.equal(result.contractReward,65);assert.equal(result.cash,72);

  b.setPrivateerContext({mode:'spaceport',requestId:'test',planetId:'p-test',loadout:{weapon:'hands'}});
  b.startPrivateerMission({style:'stealth',difficulty:1,seed:919,objective:'evidence theft'});
  assert.equal(b.game.detectedThisFloor,false,'stealth missions begin quiet');
  b.finishPrivateerMission('completed');result=privateerMessages.at(-1).detail;
  assert.equal(result.approachSucceeded,true);assert.equal(result.contractReward,114,'clean stealth completion earns a bonus');
  b.setPrivateerContext(null);
});

test('case field objectives require actual tailing, stakeout, and target completion',()=>{
  b.setPrivateerContext({mode:'spaceport',requestId:'case-objective-test',planetId:'p-case',loadout:{weapon:'hands'}});
  b.startPrivateerMission({style:'stealth',caseTask:'tail',contact:'Mara Voss',difficulty:2,seed:912});
  assert.ok(b.game.caseSubject?.caseSubject,'tail mission marks a moving subject in the Breach map');
  const beforeTail=privateerMessages.length;b.finishPrivateerMission('completed');
  assert.equal(privateerMessages.length,beforeTail,'tail cannot complete before observing the moving subject');
  b.game.player.x=b.game.caseSubject.x+200;b.game.player.y=b.game.caseSubject.y;b.game.player.sneaking=true;b.game.detectedThisFloor=false;b.game.mode='PLAY';
  b.updateCaseObjective(10);assert.equal(b.game.caseProgress,10,'tailing accrues only while close, sneaking, and undetected');
  b.finishPrivateerMission('completed');assert.equal(privateerMessages.at(-1).detail.caseTask,'tail','completed tail reports its correct dossier step');

  b.startPrivateerMission({style:'stealth',caseTask:'stakeout',contact:'Ivo Slate',difficulty:2,seed:914});
  b.game.player.x=b.game.caseSubject.x+400;b.game.player.y=b.game.caseSubject.y;b.game.player.sneaking=true;b.game.player.moving=false;b.game.detectedThisFloor=false;b.game.mode='PLAY';
  b.updateCaseObjective(8);assert.equal(b.game.caseProgress,8,'stakeout requires a still, distant, concealed observation window');
  b.finishPrivateerMission('completed');assert.equal(privateerMessages.at(-1).detail.caseTask,'stakeout','stakeout advances only after the observation window');

  b.startPrivateerMission({style:'stealth',caseTask:'eavesdrop',contact:'Kest Arden',difficulty:2,seed:915});
  const beforeEavesdrop=privateerMessages.length;b.finishPrivateerMission('completed');
  assert.equal(privateerMessages.length,beforeEavesdrop,'eavesdropping cannot complete before listening in the field');
  b.game.player.x=b.game.caseSubject.x+100;b.game.player.y=b.game.caseSubject.y;b.game.player.sneaking=true;b.game.detectedThisFloor=false;b.game.mode='PLAY';
  b.updateCaseObjective(6);assert.equal(b.game.caseProgress,6,'eavesdropping requires close, concealed listening');
  b.finishPrivateerMission('completed');assert.equal(privateerMessages.at(-1).detail.caseTask,'eavesdrop','the overheard lead advances the dossier');

  b.startPrivateerMission({style:'hot',caseTask:'mastermind',contact:'Sera Quill',difficulty:3,seed:913});
  const before=privateerMessages.length;b.finishPrivateerMission('completed');
  assert.equal(privateerMessages.length,before,'exfil cannot complete a mastermind task before locating its marked subject');
  b.killEnemy(b.game.caseSubject);b.finishPrivateerMission('completed');
  assert.equal(privateerMessages.at(-1).detail.caseTask,'mastermind','defeating the named case subject unlocks completion');
  b.setPrivateerContext(null);
});

test('everything costs twice the original price except the unchanged knife',()=>{
  const baseline={knife:95,revolver:165,auto_pistol:225,shotgun:285,ar:385,map:115,
    armor1:75,armor2:145,armor3:220,medkit:45};
  assert.equal(b.SHOP_GEAR.length,Object.keys(baseline).length);
  for(const gear of b.SHOP_GEAR)assert.equal(gear.cost,(gear.id==='knife'?baseline[gear.id]:baseline[gear.id]*2),gear.id);
});

function openWorld(){
  const room={id:0,cx:0,cy:0,x:-3500,y:-3500,w:7000,h:7000,neighbors:[],cover:[]};
  const floor={x:-3500,y:-3500,w:7000,h:7000,minX:-3500,minY:-3500,maxX:3500,maxY:3500};
  const buckets=new Map();
  for(let x=-12;x<=12;x++)for(let y=-12;y<=12;y++)buckets.set(x+','+y,[floor]);
  return {rooms:[room],buckets,links:[],walls:[],shapes:[floor],rng:new b.RNG(9)};
}
function zombie(x,type='circle'){
  const speed=b.TYPE[type].spd;
  return {
    type,x,y:0,r:17,spd:speed,room:0,homeRoom:0,angle:0,step:0,flash:0,contact:0,cool:99,charge:99,
    dashTime:0,orbit:1,state:'alert',sees:true,hadSight:true,suspicion:1,perceptionClock:0,
    lastKnown:{x:x+180,y:0},alertTime:10,searchTime:0,searchNodes:[],searchIndex:0,
    anchor:{x,y:0},patrol:{x,y:0},route:[{x,y:0}],routeIndex:0,stareClock:0,stareAngle:0,
    isWalking:true,atPost:true
  };
}

test('forward sight detects moving player far away and still rewards stealth/cover',()=>{
  const world=openWorld(),e=zombie(0),player={x:360,y:0,r:16,sneaking:false,moving:true,stealth:1};
  assert.ok(b.VISION.circle.range>=400);
  assert.equal(b.canSpot(world,e,player),true,'running in front is visible at 360 units');
  player.sneaking=true;
  assert.equal(b.canSpot(world,e,player),false,'sneaking drastically shortens recognition');
  player.sneaking=false;player.x=-180;
  assert.equal(b.canSpot(world,e,player),false,'zombie does not see directly behind');
});

test('footsteps attract distant zombies and pursuit is faster than patrolling',()=>{
  const e=zombie(0);
  b.game.world=openWorld();
  b.game.enemies=[e];b.game.mode='PLAY';b.game.floor=5;b.game.player={
    x:165,y:0,r:16,sneaking:false,moving:true,stealth:1,hp:10,maxHp:10,invuln:99
  };
  const patrolSpeed=b.patrolIntent({...e,state:'idle',isWalking:true,patrol:{x:200,y:0}},.02).speed;
  b.updateEnemies(.1);
  const chaseDistance=e.x;
  assert.ok(chaseDistance>patrolSpeed*.1*2,'pursuit materially exceeds idle patrol speed');
  e.state='idle';e.x=0;e.perceptionClock=999;
  b.emitNoise(190,0,1.12);
  assert.equal(e.state,'investigate','running now attracts red zombies');
  const yellow=zombie(0,'square');yellow.state='idle';
  b.game.enemies=[yellow];b.emitNoise(190,0,1.12);
  assert.equal(yellow.state,'investigate','yellow patrollers check footsteps');
});

test('red wanderers forget instantly when line of sight breaks, regardless of timer',()=>{
  const e=zombie(0,'circle');
  b.game.world=openWorld();b.game.enemies=[e];b.game.mode='PLAY';b.game.floor=5;
  b.game.player={x:165,y:0,r:16,sneaking:false,moving:true,stealth:1,hp:10,maxHp:10,invuln:99};
  b.updateEnemies(.08);
  assert.equal(e.sees,true);
  assert.equal(b.game.detectedThisFloor,true);
  b.game.player.x=-165;e.perceptionClock=999;
  b.updateEnemies(.016);
  assert.equal(e.state,'idle');assert.equal(e.lastKnown,null);
  assert.equal(e.suspicion,0);assert.equal(e.sees,false);
  assert.equal(b.game.detectedThisFloor,true,'losing sight cannot restore the cash bonus');
  b.emitNoise(-165,0,1.5);
  assert.equal(e.state,'investigate','new audible movement is a fresh clue');
});

test('red sight is reduced while yellow sight, hearing and cover rules remain intact',()=>{
  const world=openWorld(),e=zombie(0),p={x:850,y:0,r:16,sneaking:false,moving:true,stealth:1};
  assert.equal(b.canSpot(world,e,p),false,'red no longer sees a runner at the old extreme range');
  assert.equal(b.canSpot(world,zombie(0,'square'),p),true,'yellow retains its longer forward range');
  p.x=490;assert.equal(b.canSpot(world,e,p),true,'red can still recognize a nearby runner');
  p.x=510;assert.equal(b.canSpot(world,e,p),false,'running does not restore the old huge range');
  p.x=350;
  p.sneaking=true;assert.equal(b.canSpot(world,e,p),false);
  p.sneaking=false;p.x=100;p.y=250;
  assert.equal(b.canSpot(world,e,p),false,'red no longer has almost a full forward hemisphere');
  p.x=350;p.y=0;world.rooms[0].cover=[{x:175,y:0,w:50,h:100,hp:4}];
  assert.equal(b.canSpot(world,e,p),false,'stronger awareness still respects occlusion');
  world.rooms[0].cover=[];e.state='idle';b.game.enemies=[e];b.game.extraction=null;
  b.emitNoise(600,0,1.12);assert.equal(e.state,'investigate');
  assert.equal(e.lastKnown.x,600);
});

function generatedScenario(floor=15){
  b.game.floor=floor;b.game.seed=0xBEEF1234;b.game.mode='PLAY';
  b.game.player={x:0,y:0,r:16,hp:100,maxHp:100,invuln:999,weapon:'hands',
    armorTier:0,medkits:0,spares:[],map:true,sneaking:false,moving:false,stealth:1};
  b.beginFloor();
}

function mouseEvent(button){return {button,clientX:600,clientY:400,preventDefault(){this.defaultPrevented=true;}};}

test('holding right-click sneaks while left attack works independently in either button order',()=>{
  const canvas=elements.get('game');generatedScenario(5);
  for(const first of [2,0]){
    b.inputs.keys.clear();b.inputs.sneakTouch=false;b.inputs.mouse.down=false;b.inputs.mouse.stealthHeld=false;
    const presses=b.inputs.shotgunPendingPresses;
    const right=mouseEvent(2),left=mouseEvent(0);
    canvas.dispatch('mousedown',first===2?right:left);
    let control=b.captureInputs();
    assert.equal(b.game.player.sneaking,first===2);assert.equal(control.shoot,first===0);
    canvas.dispatch('mousedown',first===2?left:right);
    control=b.captureInputs();assert.equal(b.game.player.sneaking,true);assert.equal(control.shoot,true);
    assert.equal(b.inputs.shotgunPendingPresses,presses+1,'right button must not fire or pump the shotgun');
    sandbox.dispatch('mouseup',first===2?right:left);
    control=b.captureInputs();
    assert.equal(b.game.player.sneaking,first===0);assert.equal(control.shoot,first===2);
    sandbox.dispatch('mouseup',first===2?left:right);
    control=b.captureInputs();assert.equal(b.game.player.sneaking,false);assert.equal(control.shoot,false);
    assert.equal(right.defaultPrevented,true);
  }
  const menu=mouseEvent(2);canvas.dispatch('contextmenu',menu);assert.equal(menu.defaultPrevented,true);
});

test('right-click stealth releases on pause, lost focus, hidden tab and pointer cancellation',()=>{
  const canvas=elements.get('game');
  for(const interruption of ['pause','blur','visibilitychange','pointercancel']){
    generatedScenario(5);b.inputs.sneakTouch=false;b.inputs.keys.clear();
    canvas.dispatch('mousedown',mouseEvent(2));canvas.dispatch('mousedown',mouseEvent(0));
    b.captureInputs();assert.equal(b.game.player.sneaking,true);
    if(interruption==='pause')b.togglePause();
    else if(interruption==='visibilitychange'){document.hidden=true;document.dispatch(interruption);document.hidden=false;}
    else sandbox.dispatch(interruption);
    const control=b.captureInputs();assert.equal(b.game.player.sneaking,false,interruption);assert.equal(control.shoot,false,interruption);
    if(b.game.mode==='PAUSE')b.togglePause();
  }
});

test('idle gamepad preserves right-click stealth and existing Shift/C/touch alternatives',()=>{
  generatedScenario(5);const canvas=elements.get('game'),original=sandbox.navigator.getGamepads;
  sandbox.navigator.getGamepads=()=>[{axes:[0,0,0,0],buttons:[]}];
  try{
    b.inputs.sneakTouch=false;b.inputs.keys.clear();canvas.dispatch('mousedown',mouseEvent(2));
    b.captureInputs();assert.equal(b.game.player.sneaking,true);
    sandbox.dispatch('mouseup',mouseEvent(2));b.captureInputs();assert.equal(b.game.player.sneaking,false);
    sandbox.dispatch('keydown',{code:'ShiftLeft'});b.captureInputs();assert.equal(b.game.player.sneaking,true);
    sandbox.dispatch('keyup',{code:'ShiftLeft'});b.captureInputs();assert.equal(b.game.player.sneaking,false);
    sandbox.dispatch('keydown',{code:'KeyC'});b.captureInputs();assert.equal(b.game.player.sneaking,true);
    sandbox.dispatch('keydown',{code:'KeyC'});b.captureInputs();assert.equal(b.game.player.sneaking,false);
    elements.get('sneakButton').dispatch('click');b.captureInputs();assert.equal(b.game.player.sneaking,true);
    elements.get('sneakButton').dispatch('click');b.captureInputs();assert.equal(b.game.player.sneaking,false);
    sandbox.navigator.getGamepads=()=>[{axes:[0,0,0,0],buttons:Array.from({length:11},(_,i)=>({pressed:i===10}))}];
    b.captureInputs();assert.equal(b.game.player.sneaking,true,'L3 still sneaks');
  }finally{sandbox.navigator.getGamepads=original;}
});

test('first human guard holds a rotating post; other tours span every room',()=>{
  generatedScenario(30);
  const guards=b.game.enemies.filter(e=>!['circle','square'].includes(e.type));
  assert.ok(guards.length>1);assert.equal(guards[0].duty,'post');
  for(const guard of guards.slice(1)){
    assert.equal(guard.duty,'patrol');
    const rooms=new Set(guard.route.map(p=>p.room));
    assert.equal(rooms.size,b.game.world.rooms.length,'tour includes the whole connected floor');
    const fixed=JSON.stringify(guard.route);
    for(let n=0;n<guard.route.length+2;n++){
      guard.x=guard.patrol.x;guard.y=guard.patrol.y;b.patrolIntent(guard,20);
    }
    assert.equal(JSON.stringify(guard.route),fixed,'tour repeats without randomizing its stops');
  }
  for(const direction of [-1,1]){
    const e={...guards[0],orbit:direction,stareClock:0,stareAngle:0};
    e.x=e.patrol.x;e.y=e.patrol.y;
    const intent=b.patrolIntent(e,.02);
    assert.equal(intent.speed,0);assert.equal(intent.look,direction*Math.PI/2);
    const next=b.patrolIntent(e,e.stareClock+.01);
    assert.equal(next.look,direction*Math.PI,'quarter turn, same chosen direction');
  }
});

test('random walks use distant floor positions and patrollers cross the entire map',()=>{
  generatedScenario(6);
  const e=b.game.enemies.find(e=>e.type==='circle')||b.game.enemies[0];
  for(let i=0;i<20;i++){
    b.chooseCircleWander(e);
    assert.ok(Math.hypot(e.patrol.x-e.x,e.patrol.y-e.y)>=280,'global wander destination is not a local spawn circle');
    assert.equal(b.walkable(b.game.world,e.patrol.x,e.patrol.y,e.r+3),true);
  }
  e.type='square';e.duty='patrol';e.state='idle';b.initializeBehavior(e);
  b.game.enemies=[e];b.game.player.x=-1e6;b.game.player.y=-1e6;
  const seen=new Set([e.room]);
  for(let n=0;n<9000;n++){b.updateEnemies(.1);seen.add(e.room);}
  assert.equal(seen.size,b.game.world.rooms.length,'actual traversal '+JSON.stringify({seen:[...seen],pos:[e.x,e.y],patrol:e.patrol,index:e.routeIndex,nav:b.navigationPoint(b.game.world,e,e.patrol),cover:b.game.world.rooms.flatMap(r=>r.cover).filter(p=>Math.hypot(p.x-e.x,p.y-e.y)<250),route:e.route}));
});

test('exfil alarms the entire floor, cancels outside the ring, and requires eight seconds',()=>{
  generatedScenario(15);
  // Optional exfil is probabilistic; explicitly designate a room for this scenario.
  b.game.world.exfil=1;b.game.world.rooms[1].exfil=true;
  const room=b.game.world.rooms[b.game.world.exfil];assert.ok(room);
  Object.assign(b.game.player,{x:room.cx,y:room.cy});
  b.updateExtraction(.1);
  assert.ok(b.game.enemies.every(e=>e.state==='alert'&&e.lastKnown.x===room.cx));
  const remote=b.game.enemies.find(e=>Math.hypot(e.x-room.cx,e.y-room.cy)>1000);
  assert.ok(remote,'test includes an enemy far outside the old local simulation range');
  b.updateEnemies(.1);assert.equal(remote.state,'alert','alarm overrides loss of sight');
  b.game.player.x=room.cx+b.EXTRACTION.holdRadius+1;b.updateExtraction(.1);
  assert.equal(b.game.extraction,null);
  b.game.player.x=room.cx+70;b.updateExtraction(.1);assert.equal(b.game.extraction,null,'outer ring does not restart');
  b.game.player.x=room.cx;b.updateExtraction(5);assert.equal(b.game.mode,'PLAY');
  assert.equal(b.game.extraction.remaining,3);
  b.game.mode='PAUSE';b.updateExtraction(30);assert.equal(b.game.extraction.remaining,3);
  b.game.mode='PLAY';b.updateExtraction(2.99);assert.equal(b.game.mode,'PLAY');
  assert.equal(b.updateExtraction(.02),true);assert.equal(b.game.mode,'HQ');
  assert.equal(b.game.extraction,null);
});

test('last hostile pays a smaller clear bonus once, independent of stairs',()=>{
  let previous=0;
  for(const floor of [1,6,30]){
    generatedScenario(floor);
    const enemies=[...b.game.enemies],start=b.game.profile.credits;
    const kills=enemies.reduce((sum,e)=>sum+Math.round(b.TYPE[e.type].credits*(1+(b.game.floor-1)*.12)),0);
    const bonus=b.floorClearAward(b.game.floor,b.game.world.rooms.length);
    assert.ok(bonus>0&&bonus<b.floorAdvanceAward(b.game.floor,b.game.world.rooms.length));
    assert.ok(bonus>previous,'clear bonus grows with sector depth');previous=bonus;
    for(const enemy of enemies)b.killEnemy(enemy);
    assert.equal(b.game.profile.credits-start,kills+bonus);
    b.killEnemy(enemies.at(-1));assert.equal(b.game.profile.credits-start,kills+bonus);
    assert.equal(b.game.floorClearPaid,true);
  }
});

test('visible suspicion and noise investigations keep the large completion bonus eligible',()=>{
  generatedScenario(5);b.game.world={...openWorld(),stratum:b.game.world.stratum};b.game.extraction=null;
  const e=zombie(0);Object.assign(e,{state:'idle',sees:false,hadSight:false,suspicion:0});
  b.game.enemies=[e];Object.assign(b.game.player,{x:200,y:0});
  b.updateEnemies(.08);
  assert.equal(e.state,'suspicious','partial recognition shows a question mark');
  assert.equal(b.game.detectedThisFloor,false);
  b.emitNoise(e.x,e.y,1);assert.equal(e.state,'investigate','footsteps also show a question mark');
  assert.equal(b.game.detectedThisFloor,false);
  const credits=b.game.profile.credits,award=b.floorAdvanceAward(5,1)+b.stealthAward(5);
  b.nextFloor();assert.equal(b.game.profile.credits-credits,award);
  assert.equal(b.game.detectedThisFloor,false,'new floor starts eligible');
});

test('question-mark eligibility survives saving and loading an active investigation',()=>{
  generatedScenario(9);b.emitNoise(b.game.enemies[0].x,b.game.enemies[0].y,1);
  assert.ok(b.game.enemies.some(e=>e.state==='investigate'));
  assert.equal(b.game.detectedThisFloor,false);assert.equal(b.saveGame(),true);
  b.enterHQ();b.game.detectedThisFloor=true;assert.equal(b.loadGame(),true);
  assert.equal(b.game.detectedThisFloor,false);
  const credits=b.game.profile.credits,award=b.floorAdvanceAward(9,1)+b.stealthAward(9);
  b.nextFloor();assert.equal(b.game.profile.credits-credits,award);
});

test('instant full alert forfeits bonus even if the enemy dies before its next AI update',()=>{
  generatedScenario(9);const e=b.game.enemies[0];
  b.alertEnemy(e,b.game.player.x,b.game.player.y);
  assert.equal(b.game.detectedThisFloor,true,'record full alert at the transition');
  b.killEnemy(e);assert.equal(b.game.detectedThisFloor,true);
  assert.equal(b.saveGame(),true);b.enterHQ();b.game.detectedThisFloor=false;
  assert.equal(b.loadGame(),true);assert.equal(b.game.detectedThisFloor,true);
  const credits=b.game.profile.credits;
  b.nextFloor();assert.equal(b.game.profile.credits-credits,b.floorAdvanceAward(9,1));
  assert.equal(b.game.detectedThisFloor,false,'a later floor can earn its own bonus');
});

test('an existing saved full alert counts even when an older save missed its history flag',()=>{
  generatedScenario(9);b.game.enemies[0].state='alert';assert.equal(b.saveGame(),true);
  const slot=JSON.parse(storage.get('neon-breach.save.v1'));slot.run.detectedThisFloor=false;
  storage.set('neon-breach.save.v1',JSON.stringify(slot));b.enterHQ();
  assert.equal(b.loadGame(),true);assert.equal(b.game.detectedThisFloor,true);
});

test('short yellow checks versus extended guard investigations',()=>{
  b.game.world=openWorld();
  const search=type=>{
    const e=zombie(0,type);e.lastKnown={x:150,y:0};
    b.prepareSearch(e);return e;
  };
  const red=search('circle'),yellow=search('square');
  const shock=search('diamond'),guard=search('trapezoid'),heavy=search('pentagon');
  assert.equal(red.state,'idle');assert.equal(red.lastKnown,null);
  assert.equal(yellow.state,'search');assert.equal(yellow.searchNodes.length,1);
  assert.ok(yellow.searchTime<=1.5);
  assert.ok(shock.searchTime>yellow.searchTime);
  assert.ok(guard.searchTime>shock.searchTime);
  assert.ok(heavy.searchTime>guard.searchTime);
  assert.ok(guard.searchNodes.length>yellow.searchNodes.length);
});

test('out-of-range enemies do not sleep: radar-visible units keep moving',()=>{
  const e=zombie(2500,'square');
  e.state='investigate';e.hadSight=false;e.sees=false;e.lastKnown={x:2700,y:0};
  e.perceptionClock=999;
  b.game.world=openWorld();
  b.game.enemies=[e];b.game.mode='PLAY';b.game.player={
    x:0,y:0,r:16,sneaking:false,moving:false,stealth:1,hp:10,maxHp:10,invuln:99
  };
  b.updateEnemies(.25);
  assert.ok(e.x>2500,'distant enemy still navigates even beyond old 1650 cutoff');
});

test('archaeology and maximum generated floors sustain full-range AI',()=>{
  const stats=[];
  for(const floor of [15,30,60]){
    b.game.floor=floor;b.game.seed=0xBEEF1234;b.game.mode='PLAY';
    b.game.player={x:0,y:0,r:16,hp:100,maxHp:100,invuln:999,
      sneaking:false,moving:false,stealth:1,weapon:'hands',map:true};
    b.beginFloor();
    assert.equal(b.game.world.rooms.length,b.roomCount(floor));
    assert.ok(b.game.enemies.length<=b.enemyBudget(floor),'floor-wide enemy budget');
    const start=performance.now(),durations=[];
    for(let i=0;i<120;i++){
      const t=performance.now();b.updateEnemies(1/60);
      durations.push(performance.now()-t);
    }
    const elapsed=performance.now()-start;
    durations.sort((a,c)=>a-c);
    const p95=durations[Math.floor(.95*(durations.length-1))];
    const avg=elapsed/120;
    const stat={floor,rooms:b.game.world.rooms.length,enemies:b.game.enemies.length,
      avg_ms:+avg.toFixed(3),p95_ms:+p95.toFixed(3)};
    stats.push(stat);
    assert.ok(avg<16.7,'average AI tick fits the 60 Hz budget: '+JSON.stringify(stat));
    assert.ok(p95<45,'95th percentile AI tick remains bounded: '+JSON.stringify(stat));
  }
  console.log('NEON BREACH AI STRESS '+JSON.stringify(stats));
});


test('all four ascent bands and first guard encounters match the recovered brief',()=>{
  const bands={1:'sewers',10:'sewers',11:'maintenance',20:'maintenance',21:'dig',30:'dig',31:'ruins',60:'ruins'};
  for(const [floor,id] of Object.entries(bands))assert.equal(b.strata(Number(floor)).id,id);
  b.game.profile.firstGuardFloor=8;
  for(const floor of [6,7,8,9,10,21,31]){
    generatedScenario(floor);const humans=b.game.enemies.filter(e=>!['circle','square'].includes(e.type));
    if(floor<8)assert.equal(humans.length,0);
    if(floor===8||floor===9){assert.equal(humans.length,1);assert.equal(humans[0].type,'diamond');assert.equal(humans[0].weapon,'knife');assert.equal(humans[0].duty,'post');}
    if(floor===10)assert.deepEqual(Array.from(humans,e=>e.type),['diamond','diamond','diamond','trapezoid']);
    if(floor===10)assert.deepEqual(Array.from(humans.slice(1),e=>e.duty),['patrol','patrol','patrol']);
    if(floor>=21)assert.equal(humans.length,b.game.enemies.length,'archaeology has no zombies');
  }
});

test('three base hits, six with best vest, one-hit repairs and five-kit carry cap',()=>{
  b.enterHQ();b.game.loadout.armor=3;b.resetRun();assert.equal(b.game.player.maxHp,6);
  b.game.player.hp=2;b.game.player.medkits=2;assert.equal(b.useMedkit(),true);assert.equal(b.game.player.hp,3);
  b.game.player.medkits=5;assert.equal(b.collectPickup({kind:'med',x:0,y:0}),false);
  b.enterHQ();b.game.loadout.medkits=5;b.game.profile.storage.medkit=4;assert.equal(b.equipFromStash('medkit'),false);
  b.game.loadout.armor=0;b.resetRun();assert.equal(b.game.player.maxHp,3);
});

test('shotgun requires separate pump clicks and reloads five individual shells on empty',()=>{
  b.enterHQ();b.game.loadout.weapon='shotgun';b.resetRun();const p=b.game.player;
  assert.equal(b.WEAPONS.shotgun.pellets,5);
  for(let shot=0;shot<5;shot++){
    const old=b.game.bullets.length;b.shootPlayer(0);assert.equal(b.game.bullets.length-old,5);
    if(shot<4){assert.equal(p.pumpNeeded,true);assert.equal(p.magazines.shotgun,4-shot);
      const count=b.game.bullets.length;b.shootPlayer(0);assert.equal(b.game.bullets.length,count,'pump does not shoot');
      assert.ok(p.pumpClock>0);b.updateWeaponTimers(1);
    }
  }
  assert.ok(p.reloadClock>0);assert.equal(p.magazines.shotgun,0);
  b.updateWeaponTimers(.59);assert.equal(p.magazines.shotgun,1);
  b.updateWeaponTimers(2.32);assert.equal(p.magazines.shotgun,5);assert.equal(p.reloadStage,'rack');
  b.updateWeaponTimers(1);assert.equal(p.reloadClock,0);assert.equal(p.pumpNeeded,false);
  assert.equal(b.startReload(),false,'cannot reload a nonempty gun');
});

test('revolver loads rounds in sequence; AR reloads its magazine on empty',()=>{
  for(const gun of ['revolver','ar','auto_pistol']){
    b.enterHQ();b.game.loadout.weapon=gun;b.resetRun();const p=b.game.player,w=b.WEAPONS[gun];
    for(let i=0;i<w.magazine;i++)b.shootPlayer(0);
    assert.ok(p.reloadClock>0);b.updateWeaponTimers(w.reload/2+.001);
    assert.equal(p.magazines[gun],gun==='revolver'?3:0);
    b.updateWeaponTimers(w.reload);assert.equal(p.magazines[gun],w.magazine);
  }
});

test('mission save serializes navigation safely and restores equipment, world, bullets and alarm',()=>{
  b.enterHQ();b.game.loadout.weapon='shotgun';b.resetRun(30);const p=b.game.player;
  b.game.profile.credits=987;b.game.world.rooms[1].visited=true;
  if(b.game.world.rooms[1].cover.length)b.game.world.rooms[1].cover[0].hp=0;
  b.game.floorClearPaid=true;b.game.detectedThisFloor=true;b.game.extraction={elapsed:2.5,remaining:6,room:1};
  const enemy=b.game.enemies[0];enemy.x+=7;enemy.navigation={world:b.game.world,points:[{x:1,y:2}]};
  b.shootPlayer(0);p.magazines.shotgun=0;b.startReload();b.updateWeaponTimers(.7);
  b.game.bullets[0].hitIds.add(123);const expected={x:enemy.x,count:b.game.enemies.length,clock:p.reloadClock};
  assert.equal(b.saveGame(),true);const slot=JSON.parse(storage.get('neon-breach.save.v1'));
  assert.equal(slot.run.enemies[0].navigation,undefined);assert.equal(slot.run.bullets[0].hitIds[0],123);
  b.enterHQ();b.game.profile.credits=1;assert.equal(b.loadGame(),true);
  assert.equal(b.game.mode,'PLAY');assert.equal(b.game.floor,30);assert.equal(b.game.profile.credits,987);
  assert.equal(b.game.enemies.length,expected.count);assert.equal(b.game.enemies[0].x,expected.x);
  assert.equal(b.game.player.reloadClock,expected.clock);assert.ok(b.game.bullets[0].hitIds.has(123));
  assert.equal(b.game.extraction.elapsed,2.5);assert.equal(b.game.floorClearPaid,true);assert.equal(b.game.detectedThisFloor,true);
  assert.equal(b.game.world.rooms[1].visited,true);
});

test('checkpoint travel requires discovery and charges exactly once per deployment',()=>{
  b.enterHQ();b.game.profile.credits=999;b.game.profile.unlockedFloor=1;b.openTravel();
  assert.equal(b.fastTravel(11),false);assert.equal(b.game.profile.credits,999);
  b.game.profile.unlockedFloor=11;assert.equal(b.fastTravel(11),true);assert.equal(b.game.floor,11);assert.equal(b.game.profile.credits,899);
  assert.equal(b.fastTravel(11),false);assert.equal(b.game.profile.credits,899);
  assert.equal(b.game.profile.unlockedFloor,11);
});

test('creatures never drop supplies and furniture rare loot only rolls once',()=>{
  generatedScenario(5);b.game.pickups=[];const original=seededMath.random;seededMath.random=()=>0;
  try{
    for(const e of [...b.game.enemies])b.killEnemy(e);assert.equal(b.game.pickups.length,0);
    const prop={x:0,y:0,w:30,h:30,hp:1};b.damageFurniture(prop,5);assert.equal(b.game.pickups.length,1);
    b.damageFurniture(prop,5);assert.equal(b.game.pickups.length,1,'destroyed prop cannot roll twice');
  }finally{seededMath.random=original;}
});

test('music/SFX settings persist independently without duplicate music players',()=>{
  b.unlockAudio();b.unlockAudio();assert.equal(musicInstances,1);
  b.setAudioSettings({musicOn:false,musicVolume:30,sfxOn:false,sfxVolume:20});
  assert.equal(JSON.parse(storage.get('neon-breach.audio.v1')).musicVolume,30);
  b.enterHQ();b.resetRun();b.setAudioSettings({musicOn:true});b.unlockAudio();
  assert.equal(musicInstances,1);assert.equal(b.getAudioSettings().sfxOn,false);
});

test('level-scaled no-alerts awards substantially exceed the smaller combat clear bonus',()=>{
  let previousClear=0,previousStealth=0;
  for(const floor of [1,10,31,60]){
    const advance=b.floorAdvanceAward(floor,30),clear=b.floorClearAward(floor,30);
    assert.ok(clear<advance);assert.ok(b.stealthAward(floor)>advance+clear);
    assert.ok(clear>previousClear);assert.ok(b.stealthAward(floor)>previousStealth);
    previousClear=clear;previousStealth=b.stealthAward(floor);
    assert.ok(advance<35+floor*18+30*5,'completion credits reduced versus old build');
  }
});


test('ranged guards shelter behind physical cover then peek toward the last observed position',()=>{
  b.game.world=openWorld();b.game.world.rooms[0].cover=[{x:200,y:0,w:60,h:80,hp:4}];b.game.extraction=null;
  const e={type:'trapezoid',state:'alert',x:400,y:0,r:21,lastKnown:{x:0,y:0}};
  const shelter=b.rangedCoverIntent(e,.1);assert.ok(shelter,'reachable cover selected');
  assert.equal(b.clearSight(b.game.world,0,0,shelter.x,shelter.y),false);
  const peek=b.rangedCoverIntent(e,1.3);assert.notDeepEqual(peek,shelter);
  assert.equal(b.clearSight(b.game.world,0,0,peek.x,peek.y),true,'peek opens a real firing line');
  e.type='diamond';assert.equal(b.rangedCoverIntent(e,.1),null,'melee troops do not impersonate ranged guards');
});

test('HQ autosave keeps purchases and equipped inventory together',()=>{
  b.enterHQ();b.game.profile.credits=2000;b.game.profile.storage.knife=1;
  assert.equal(b.equipFromStash('knife'),true);assert.equal(b.purchase('medkit'),true);
  const slot=JSON.parse(storage.get('neon-breach.save.v1'));
  assert.equal(slot.mode,'HQ');assert.equal(slot.loadout.weapon,'knife');assert.equal(slot.profile.storage.knife,0);
  assert.equal(slot.profile.credits,1910);assert.equal(slot.profile.storage.medkit,b.game.profile.storage.medkit);
  assert.equal(b.loadGame(),true);assert.equal(b.game.profile.credits,1910);assert.equal(b.game.loadout.weapon,'knife');
});

test('pause freezes the mission clock and weapon reload timers',()=>{
  b.enterHQ();b.game.loadout.weapon='revolver';b.resetRun();b.game.player.magazines.revolver=0;b.startReload();
  const clock=b.game.player.reloadClock,time=b.game.time;b.togglePause();b.update(1);
  assert.equal(b.game.time,time);assert.equal(b.game.player.reloadClock,clock);
});


test('rare field equipment stays at risk until recovered, not teleported to HQ storage',()=>{
  b.enterHQ();b.resetRun();const count=b.game.profile.storage.armor1;
  b.game.player.map=true;b.collectPickup({kind:'equipment',x:0,y:0});
  assert.equal(b.game.profile.storage.armor1,count);assert.ok(b.game.player.spares.includes('armor1'));
});


test('mobile patrols start at different phases across the whole-floor circuit',()=>{
  generatedScenario(31);const roaming=b.game.enemies.filter(e=>e.duty==='patrol');
  const phases=new Set(roaming.map(e=>Math.round(e.patrol.x)+','+Math.round(e.patrol.y)));
  assert.ok(phases.size>=roaming.length*.55,'patrollers do not all march to one first stop');
  assert.ok(b.game.enemies.every(e=>e.routeVersion===2));
  const guard=roaming.find(e=>e.type==='trapezoid')||roaming[0];b.game.enemies=[guard];
  b.game.player.x=-1e6;b.game.player.y=-1e6;const seen=new Set([guard.room]);
  for(let step=0;step<30000&&seen.size<b.game.world.rooms.length;step++){b.updateEnemies(.2);seen.add(guard.room);}
  assert.equal(seen.size,b.game.world.rooms.length,'a guard physically reaches every region of upper archaeology');
});

test('legacy saves gain global patrols without moving actors or resetting their search',()=>{
  generatedScenario(15);const e=b.game.enemies.find(e=>e.duty==='patrol');
  const position=[e.x,e.y];e.routeVersion=1;e.route=[{x:e.x,y:e.y,room:e.room}];
  e.state='search';e.searchTime=5;e.lastKnown={x:123,y:456};
  b.restoreFloorPatrols();assert.equal(e.routeVersion,2);assert.deepEqual([e.x,e.y],position);
  assert.equal(e.state,'search');assert.equal(e.searchTime,5);assert.equal(e.lastKnown.x,123);
  assert.equal(new Set(e.route.map(p=>p.room)).size,b.game.world.rooms.length);
  e.routeIndex=3;b.restoreFloorPatrols();assert.equal(e.routeIndex,3,'current save keeps its patrol phase');
});


test('holstered hands and firearms cannot attack through any input or buffered shotgun press',()=>{
  b.resetRun();b.game.mode='PLAY';
  for(const weapon of ['hands','knife','revolver','shotgun']){
    const p=b.game.player;p.weapon=weapon;p.weaponDrawn=true;p.cool=0;
    b.inputs.shotgunPendingPresses=3;b.inputs.mouse.down=true;b.inputs.keys.add('Space');
    assert.equal(b.toggleWeaponDraw(),true);assert.equal(p.weaponDrawn,false);
    assert.equal(b.inputs.shotgunPendingPresses,0);
    b.inputs.aim={x:1,y:0};b.inputs.mouse.down=true;b.inputs.keys.add('Space');
    assert.equal(b.captureInputs().shoot,false);assert.equal(b.shootPlayer(0),false);
    const shots=b.game.bullets.length;b.update(.016);assert.equal(b.game.bullets.length,shots);
    assert.equal(b.toggleWeaponDraw(),true);assert.equal(p.weaponDrawn,true);
    b.inputs.aim={x:1,y:0};assert.equal(b.captureInputs().shoot,true);
    b.toggleWeaponDraw();b.saveGame();b.loadGame();assert.equal(b.game.player.weaponDrawn,false);
    b.game.mode='PLAY';
  }
  b.inputs.aim={x:0,y:0};b.inputs.mouse.down=false;b.inputs.keys.clear();
});


test('draw button gates gamepad trigger and legacy saves remain drawn',()=>{
  b.resetRun();b.game.mode='PLAY';const p=b.game.player;
  delete p.weaponDrawn;
  sandbox.navigator.getGamepads=()=>[{axes:[0,0,1,0],buttons:Array.from({length:11},(_,i)=>({pressed:i===7}))}];
  assert.equal(b.captureInputs().shoot,true);
  elements.get('drawButton').dispatch('click');
  assert.equal(p.weaponDrawn,false);assert.equal(b.captureInputs().shoot,false);
  elements.get('drawButton').dispatch('click');
  assert.equal(p.weaponDrawn,true);assert.equal(b.captureInputs().shoot,true);
  sandbox.navigator.getGamepads=()=>[];
});
