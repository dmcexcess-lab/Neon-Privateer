# Neon Quartet — soundtrack assignment

The four user-defined Neon songs have distinct standalone and Privateer roles:

| Song | Standalone role | Privateer role | Recording state |
| --- | --- | --- | --- |
| Nineteen Steps | Neon Breach | Normal playlist, track 1 | Installed |
| Neon Cathedral 1986 | Neon Driftline Classic | Normal playlist, track 2 | Installed |
| Do Androids Dream | Neon Firewall | Normal playlist, track 3 | Installed |
| J-Space | None | Prison only, continuous loop | Installed |

Normal Privateer gameplay plays **Nineteen Steps → Neon Cathedral 1986 → Do Androids Dream → repeat** through title, dock, flight, Breach ground missions and embedded Firewall. A single persistent streaming player advances at each real track ending, without resetting on menus or gameplay transitions.

An actual sentence changes context to J-Space only, including prison escape sorties while the inmate is still incarcerated. Normal playlist position is remembered and resumes on release. No other quartet recording leaks into prison. Only the J-Space stream itself loops; the three normal tracks finish naturally.

On the standalone games, Breach uses the Nineteen Steps MP3, Classic uses the installed Neon Cathedral Ogg, and Firewall plays a separate actual copy of Do Androids Dream. All sound effects remain independent.

The user-supplied recordings are installed at these exact paths:

- `assets/audio/neon_cathedral.ogg` — Privateer playlist
- `neon-driftline-classic/assets/audio/neon_cathedral.ogg` — Classic standalone
- `assets/audio/j_space.ogg` — Privateer prison

The four files remain real compressed music, not replacement arrangements. Web Audio may require a first real click/tap/key in the game frame. Android suspension/audio-focus handling keeps a track position; actual physical-device behavior remains to be verified.
