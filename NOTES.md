# R1 decisions and verification

## Scope

Only the section 0 R1 row is implemented. §3 services include ArtRegistry (PNG/SVG/fallback/cache/strips), Sfx (replaceable audio, pan, loops, fades), editor-visible DualSprite, derivation/wobble, PostFX, font fallback, global theme/UIFactory, and persistent settings. R1 never sets the world to real during gameplay. The visual tour temporarily exercises the §3 real and reduced-distortion shaders.

S1 ends at the `r1_end` event (220 m), with a clearly labeled milestone screen and return-to-clinic button. Song cut, face slam, S1 foreshadow flash, and all other scares are deferred to R3's “all scares” row. Threats, checkpoints, gates, hiding, S2–S5, and the actual ending are R2. `monster_director.gd` and its tests arrive with R2. BeatClock provides song timing now; layered music and flow/scream-budget systems are deferred. Only assets consumed by R1 are generated. Lightweight documentation and scoped tests are delivered now to make this milestone reviewable; the full R3 docs/tests remain future work.

## Implementation choices

- Nearest-rank calibration percentiles. Every frame contributes a smoothed dB sample during the timed windows. Keyboard mode or skipping uses the specified defaults. Switching modes clears the current window. A weak call retries once; a second weak call uses guarded thresholds.
- A missing microphone notice appears globally after three seconds of ≤ −110 dB. Capture is always processed while settings is open. The Mic bus is both −80 dB and muted, so input is never monitored through speakers.
- In headless/Dummy audio runs there is no hardware capture or playback; RMS stays at the silent floor, Sfx still resolves resources, and BeatClock uses its specified timer fallback. This also avoids pending audio playbacks at immediate headless shutdown.
- Acceleration is linear from the current speed to a newly higher target over 0.3 s. Deceleration tends exponentially toward a lower target with the specified half-life. Trapezoidal integration tracks distance. The throat guard changes the target, preserving the same coasting rule. The instinct bonus API is implemented and tested but no R1 scene triggers a scare.
- The side-scroll camera is expressed as a screen-space world offset (`x * px_per_m − player_screen_x`); fixed Mina/HUD slots and tiled parallax need no Camera2D. The bridge holds Mina at its data-defined edge and accumulates TALK time there without decreasing between attempts.
- The mask is 535×265. Stroke interpolation prevents gaps on fast drags; feathered stamps accumulate. Doll coverage averages mask strength over its fixed rectangle. The trance shader desaturates and approaches the doll for 2.5 s, with floating sand and a pastel wash.
- Music-box melody is original synthesis from `song.json`; loops are periodic and include soft harmonics/delays. Lyrics share the exact data timeline and use integer units to avoid drift at boundaries. `word_ends` is optional presentation metadata; text is still wholly in song data. Each audible syllable blooms once per loop.
- Cute/real placeholder strips share recognizable silhouettes but differ in palette and hatching. Character feet align to the fixed slot bottom. Missing fonts use Godot's default, as allowed. HUD/subtitle canvas layers remain above PostFX and trance, so text never warps. The DualSprite scene has an editor-only preview blend and a local ArtRegistry instance when runtime autoloads are unavailable. Art cache refreshes on restart/reimport after dropping replacement files.
- No plugins, downloaded assets, C#, or later-milestone game systems.

## Verification

Godot 4.7.2 at `/Applications/Godot.app/Contents/MacOS/Godot` was used for headless import, four suites, main-scene smoke run, and a render-capable tour on the Apple M4 Compatibility renderer. Final headless totals: voice_test 52, run_model_test 26, r1_scene_test 40, art_registry_test 13 — 131 passed, 0 failed, plus the main-scene smoke check. The render tour captured 11 views with no errors. The DualSprite tool scene also loaded in a headless editor run without errors. Checked mapping anchors/midpoints/cap, sensitivity, keyboard priorities/values, RMS and smoothing, percentiles/guards/defaults, acceleration/decay/coasting, throat guard, instinct timing, tutorial gates, song boundaries and WAV duration, keyboard clinic, reveal mask/trance, pause and in-pause recalibration, persistence, missing mic, blooms, bridge blocking/lifting, boundary/replay, PNG priority/new aspect, data strip count, and dual derivation/blending.

Viewport captures are temporary QA artifacts under `/tmp/mina-r1-tour`, not shipped game resources. They cover warning, calibration, partially brushed sand, mid-trance, flower path, settings, karaoke, partial bridge, real service preview, reduced distortion, and the R1 completion screen.

## Manual checks still needed

1. Open `project.godot`, run, allow mic access, and finish all three calibration windows. Verify the figure turns for the talk sample and a quiet call repeats only once. Check `Use defaults` and Recalibrate microphone.
2. Brush the raised center patch with slow and fast mouse drags. Confirm sand sound/particles, 70% reveal, the doll approach, and the 2.5 s transition.
3. Hum, speak, and raise your voice comfortably. Confirm walking/jogging/running, meter thresholds/highlighting, cap above SHOUT, and coasting after release. Hold SHOUT past three seconds, then breathe for at least half a second to reset the guard.
4. Test K and Shift/Ctrl/Space without a mic. Complete prompts in order, stand still, sing for golden syllables/flowers, and lift/cross the bridge with cumulative TALK. Reach 220 m and replay.
5. Open settings mid-run: movement/song should pause while mic capture/recalibration keeps working. Change sensitivity and meter visibility, close/reopen, then relaunch to confirm persistence. Resize the window and check fixed-slot aspect/layout.
6. Listen for melody/lyric synchronization and seamless loops on real audio hardware. Confirm no microphone monitoring. Add a different-size same-name PNG and restart to inspect its actual appearance; automated slot/priority checks pass, but arbitrary production art needs visual review.

Not verified: live microphone permission/capture quality, real-room calibration and comfort, speaker/headphone mix and perception of timing/panning, live mouse feel, arbitrary resize/device combinations, and macOS export entitlements. Scare-reduction behavior has no gameplay effect until scares are built. Headless assertions and rendered snapshots do not substitute for those checks.
