# Neon Privateer soundtrack

User-supplied songs, installed permanently in this project:

- **Do Androids Dream** — spaceport, title and docked menus. Original `Do_Androids_Dream.mp3`, 182.33 seconds, converted to 44.1kHz stereo Vorbis quality4 with brief anti-click edge fades.
- **Nineteen Steps** — spaceflight, including its pause screen. Same optimized Ogg derived from the user's `Nineteen_Steps.wav` for Classic:176.79 seconds, trailing dead silence removed. This is a separate asset/controller; Classic is unchanged.

Both actual Ogg streams loop from0 at their original musical ending. This is continuous decoder looping, not a beat-matched remix. A single autoload player at−11dB switches between contexts, remembering each position. Changing a docked submenu or pausing a flight does not replay a song. Sound effects are independent.

Web audio may require the first real click/tap/key inside the game frame. Android lifecycle handling is implemented for future exports, but this public beta is a Web launch; physical-device interruptions are not claimed tested.
