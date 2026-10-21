# Nineteen Steps

The project owner supplied `Nineteen_Steps.wav` and authorized its inclusion in
Neon Driftline Classic. The WAV SHA-256 is
`76be995e81464551bd084d3e955386a0549aa4887abf2960941ef981b40e5b9b`.
This inclusion does not grant a separate licence to reuse the song elsewhere.

`nineteen_steps.ogg` is stereo 44.1 kHz Vorbis quality 4, about 2 MiB instead of
the 30 MiB WAV. Its 176.79-second duration removes the source's final 1.69 seconds
of silence below -55 dB. A 5 ms entrance fade and 20 ms tail fade prevent boundary
clicks. The original musical ending is retained; this is not a beat-matched edit.
Vorbis and Godot's stream loop introduce no extra silence or finished/play delay.

Reproduce with FFmpeg (the source WAV is intentionally not duplicated here):

```sh
ffmpeg -i Nineteen_Steps.wav \
  -af 'atrim=end=176.79,afade=t=in:d=0.005,afade=t=out:st=176.77:d=0.02' \
  -c:a libvorbis -q:a 4 -metadata title='Nineteen Steps' \
  -metadata artist='Mother Static' nineteen_steps.ogg
```

Keep `nineteen_steps.ogg.import` in Git. It enables looping at offset 0 in the
actual imported resource. Both Classic export presets include all resources.
`MusicTest.gd` is also run against the exported Web PCK; Android CI compares the
APK's imported audio bytes with the editor's imported song.
