# Neon Quartet — soundtrack assignment

The four user-defined Neon songs have distinct standalone and Privateer roles:

| Song | Standalone role | Privateer role | Recording state |
| --- | --- | --- | --- |
| Nineteen Steps | Neon Breach | Normal playlist, track 1 | Installed |
| Neon Cathedral | Neon Driftline Classic | Normal playlist, track 2 | Awaiting user audio |
| Do Androids Dream | Neon Firewall | Normal playlist, track 3 | Installed |
| J-Space | None | Prison only, continuous loop | Awaiting user audio |

Normal Privateer gameplay plays **Nineteen Steps → Neon Cathedral → Do Androids Dream → repeat** through title, dock, flight, Breach ground missions and embedded Firewall. A single persistent streaming player advances at each real track ending, without resetting on menus or gameplay transitions. Missing recordings are omitted from the normal playlist, never synthesized. For now that leaves Nineteen Steps and Do Androids Dream alternating.

An actual sentence changes context to J-Space only, including prison escape sorties while the inmate is still incarcerated. Normal playlist position is remembered and resumes on release. Without an actual J-Space recording, prison is temporarily silent; no other quartet recording leaks into prison. Only the J-Space stream itself loops; the three normal tracks finish naturally.

On the standalone games, Breach's existing Nineteen Steps MP3 remains in its audio engine. Classic selects Neon Cathedral if its real Ogg exists, otherwise retains its preexisting Nineteen Steps recording. Firewall now plays a separate actual copy of Do Androids Dream, with no changes to its embedded Privateer mode. All sound effects remain independent.

Install the missing user-supplied recordings at these exact paths (stereo Ogg Vorbis, 44.1 kHz recommended):

- `assets/audio/neon_cathedral.ogg` — Privateer playlist
- `neon-driftline-classic/assets/audio/neon_cathedral.ogg` — Classic standalone
- `assets/audio/j_space.ogg` — Privateer prison

The existing Nineteen Steps and Do Androids Dream files were converted from the user's supplied recordings. They remain real compressed music, not replacement arrangements. Web Audio may require a first real click/tap/key in the game frame. Android suspension/audio-focus handling keeps a track position; actual physical-device behavior remains to be verified.

Until the two missing recordings are supplied, this is a **partial audio rollout** rather than confirmation that all four songs are audible.
