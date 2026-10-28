# Neon Cathedral 1986

The project owner supplied `Neon_Cathedral_1986.mp3` and authorized its inclusion
in Neon Driftline Classic.
This inclusion does not grant a separate licence to reuse the song elsewhere.

`neon_cathedral.ogg` is an optimized stereo Vorbis conversion with short
entrance and tail fades to prevent boundary clicks. The original musical ending
is retained; this is not a beat-matched edit.
Vorbis and Godot's stream loop introduce no extra silence or finished/play delay.

Reproduce with FFmpeg (the source MP3 is intentionally not duplicated here):

```sh
ffmpeg -i Neon_Cathedral_1986.mp3 \
  -af 'afade=t=in:d=0.015,afade=t=out:st=276.29:d=0.03' \
  -c:a libvorbis -q:a 4 -metadata title='Neon Cathedral 1986' \
  -metadata artist='Mother Static' neon_cathedral.ogg
```

Keep `neon_cathedral.ogg.import` in Git. It enables looping at offset 0 in the
actual imported resource. Both Classic export presets include all resources.
`MusicTest.gd` is also run against the exported Web PCK; Android CI compares the
APK's imported audio bytes with the editor's imported song.
