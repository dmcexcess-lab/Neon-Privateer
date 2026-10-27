# Neon Privateer: career RPG and justice direction

The career is the game. Spaceflight/Driftline, Breach ground play and Firewall brick-breaking are ways to carry out its objectives. Their scores cannot replace the persistent career state, objective journal, guild standing or legal consequences.

## Starting out and earning a living

New careers start with zero credits, no banked funds, no cargo, no field equipment, no purchased upgrades and only the basic ship and initial fuel. Existing saves keep their assets. A no-deposit ENTRY COURIER job is always offered within the basic ship's jump range. It carries the client's cargo, rather than requiring the player to buy stock. Its 160-credit payment starts equipment progression. The ship board paginates instead of hiding older job types to make room for it.

Income paths:

- Missions: delivery and transportation, mercenary combat, on-foot and space assassination, tracking, terminal infiltration and investigation that ends with filing an evidence package/bringing charges.
- Trading: cargo price differences, commodity indices/investing and faction currencies.
- Crime: deliberately raiding owned crates in space, faction-illegal black-market transactions, station-terminal hacking, vault robbery and citizen robbery.

Legal grey goods remain legal where that faction permits them. Black-market purchases/sales create charges when they violate the local item-level law. Ordinary legal trading and unowned salvage do not become crimes just because they make money.

## Guild progression and difficulty

Trader standing comes from legal delivery and transport jobs. Merc standing comes from authorized mercenary, tracking and investigative jobs, including licensed space hits. Basic jobs are available without rank. Rank thresholds are 0, 30, 100, 240 and 500 XP; completed tier-one jobs grant 10 XP, once per job ID. Higher field-job tiers require correspondingly higher rank. Ship jobs use route difficulty to determine required rank. Criminal proceeds grant no legitimate guild standing. NETWORK Firewall practice does not manufacture career cash; mission objectives and criminal hacks pay on completion/extraction. Purchased research still supports actual terminal challenges. Standalone Firewall keeps its own arcade earnings.

Field tiers change actual guard count, durability and pressure, as well as pay: tier one currently has seven guards, tier five nineteen. Higher ship-job difficulty already changes route risk and bounty boss archetype/strength. Upgrades and equipment must be earned and purchased; standing is not a free loadout.

## Mission capture is not a sentence

Getting caught on an operation means a tactical captivity/escape sequence in the Breach engine. Recover field equipment, find a badge or hack a terminal, and extract. This has no prison sentence clock and no court-fine shortcut. Existing criminal charges remain pending independently. Legacy saves from the first integration migrate their old "prison" field scene into mission captivity, without inventing a conviction.

## Crime and justice

Owned-crate theft, contraband discovery, illegal trade and station crimes create persistent jurisdiction-specific cases. Crate targeting defaults to IGNORE; explicitly enabling RAID permits attacking owned cargo. Weapons ON/OFF remains a separate flight control.

A police scan that finds contraband confiscates it, then presents the actual choice: pay the assessed fine from carried cash, or serve a sentence. It never silently partially debits the wallet. SURRENDER during police contact also opens outstanding-case review. A court decision interrupts and snapshots the flight; fine payment or eventual release returns to that same flight paused, rather than teleporting to a new port. Bank funds remain protected. Finishing a sentence cannot be bypassed by reloading the career or leaving the operations menu.

Fine payment or lawful release discharges the covered cases. Reputation is not reset to friendship. Other jurisdictions' cases remain outstanding. Time actually spent serving a sentence advances overdue ship-contract deadlines and the existing economy in bounded monthly steps. A new global needs/calendar layer is not implied by this prison clock.

## Prison life minigame

Serving time is an accelerated routine simulation, not an escape arena. One real second represents one prison hour; one 24-hour prison day represents 30 days of the legal sentence. Thus several prison days can represent months or years. The rate is centralized in PrisonLife, not scattered through UI code.

During the term the player can eat, sleep, train, work, check in, and socialize with named inmates. The avatar moves between activity areas and inmates follow daily schedules. Food, energy, morale, fitness, work pay, relationships and conduct persist. Activities take accelerated play time; selecting them cannot instantly award their result. Training is retained after release. Work wages are paid once on lawful release. Consistent good behavior can earn at most 20% remission.

Prison time pauses when the game is backgrounded, paused or closed. Restoring starts paused. Waiting in an active prison still serves time; there is no requirement to grind activities just to make the sentence count down.

Temporary escape opportunities can arise on the daily schedule. Taking one launches a real Breach escape sortie. The routine clock stops while attempting it. Failure returns to the living simulation, adds 30 days, and loses good behavior; it does not reset time already served. Success leaves the unserved portion and a new escape charge outstanding. It does not count as lawful release or award prison wages. Gear must be recovered during escape.

## Order of further work

First stabilize, balance and broaden these economic, mission, guild and justice loops. Expand native ground layouts, mission targets, evidence links, prison schedules and meaningful consequences before claiming a finished campaign.

Then add the whole-career Sims-style needs system: needs outside custody, schedules, homes/ship life, rest and resources. Prison currently has local needs only.

After those rules are reliable, add the AI storyteller to direct faction actions and situations. It must propose events through validated simulation actions; the canonical simulation owns inventories, money, crimes, ranks, objectives and saves. The storyteller must not fabricate completed missions or silently overwrite facts. No model API, paid generation or autonomous online storyteller is enabled in the current build.
