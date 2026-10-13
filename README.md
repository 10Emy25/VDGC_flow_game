# Mina: Scream — R1

A Godot 4.4+ / GDScript / Compatibility project. This milestone contains the content warning, clinic calibration and sand tray, and the flower path (0–220 m). At 220 m a milestone screen offers a return to the clinic. Monsters, the face slam, later level sections, ending, F1 debug tools, flow meter, and scream budget belong to R2/R3.

## Run

Open `project.godot` in Godot and press F6 on `scenes/main.tscn`, or F5. On this machine:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

First run in the editor triggers the microphone permission prompt. If denied, enable Godot in **System Settings → Privacy & Security → Microphone**. macOS exports must enable the microphone entitlement and fill **Privacy → Microphone Usage Description**; export has not been tested in R1.

Click Begin. Sample silence, say hi, and make one comfortable call. A weak call is repeated once; guards ensure useful thresholds. `Use defaults` skips sampling. Saved calibration loads on boot; every new clinic visit still calibrates as part of the story. Brush the raised patch in the middle of the sand until the running doll emerges.

Press **K** at any time for keyboard mode. In the clinic, press and release **Space** three times to use default calibration. On the path hold **Shift** to hum, **Ctrl** to talk, or **Space** to shout. Space takes priority, then Ctrl, then Shift. Release everything to coast. The tutorial advances cumulatively and has a minimum display duration. Sing at TALK for one cumulative bar at the bridge to lift it.

SETTINGS stays available on every screen and pauses the scene and music. Recalibration runs inside the paused settings overlay. Settings save to `user://settings.cfg`; calibration saves separately to `user://voice_calibration.cfg`. Negative sensitivity makes movement easier. The distortion toggle controls §3 shaders; scare intensity is stored for later milestones because R1 contains no scares.

## Checks

```sh
python3 tools/run_tests.py
```

This uses the specified Godot executable, imports with `--headless --editor --import`, then runs `voice_test`, `run_model_test`, `r1_scene_test`, and `art_registry_test` using `--headless --scene`. It exits on engine errors, failed assertions, or timeouts, and smoke-tests the main scene. Set `GODOT` to another executable if needed. Tests preserve and restore existing settings/calibration files. The runner creates and removes two temporary art fixtures to verify PNG priority, strip frames, fixed slots, and deriving a missing dual version. The Dummy audio driver uses silent capture and the clock's timer fallback; hardware capture and audible playback require manual testing.

A render-capable R1 tour (no microphone/audio hardware required) captures warning, calibration, sand brushing, trance, S1, settings, karaoke, bridge, core real visuals, reduced distortion, and the milestone screen:

```sh
TOUR_DIR=/tmp/mina-r1-tour /Applications/Godot.app/Contents/MacOS/Godot --path . --audio-driver Dummy --scene res://tests/r1_tour.tscn
```

Without `TOUR_DIR`, images go to `user://tour/`. This is a scoped R1 tour, not the full §15 R3 tour.

## Edit and replace

- `data/balance.json`: voice thresholds/defaults, filtering, movement, throat guard, tutorial timing, settings defaults, fixed display slots, and strip frame counts. Original future-milestone balance values are retained as inert data.
- `data/level.json`: the S1 section, tutorial, bridge position/length, and R1 boundary. R2 will extend the event list.
- `data/song.json`: syllables, durations, notes, and optional `word_ends` indices to join multi-syllable words. Regenerate `mus_song.wav` after editing it.
- `data/dialogue.json`: all shipped player-facing strings and both font paths.
- Drop a same-key PNG into `art/`, reimport/restart, and it takes priority over SVG. Every slot keeps its fixed rectangle, preserves aspect, and centers the texture. Animation files are horizontal strips; set the base key's count in `art_frames`. Cute/real keys end in `_cute` / `_real`. A missing counterpart uses the derive shader.
- Replace `audio/<key>.wav` or `.ogg` (WAV takes priority). `amb_*` / `mus_*` loop. Missing audio is silent with one warning per key. Keep song audio duration aligned with its data. §3 Sfx pan/fade APIs are available for later scenes.
- Add `fonts/system.ttf` and `fonts/therapist.ttf`, or edit the paths. Missing fonts use the engine default. No fonts or third-party assets are downloaded.

`python3 tools/generate_resources.py` fills missing R1 placeholders. `--refresh-placeholders` regenerates SVGs/WAVs; it never modifies data, overwrites a PNG, or replaces an SVG whose key has a PNG. Back up hand-edited SVG/WAV assets before requesting a refresh.

See `ART_MANIFEST.md` for shipped slots and `NOTES.md` for decisions, verification, and manual checks.
