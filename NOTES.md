# R2 decisions, differences, and verification

## Delivered

Full `level.json` event list and a node-free `LevelModel` shared by the view and tests. Monster 1 spawns in S2, rubber-bands, pauses at checkpoints, and follows the gaze safety rules. Monster 2 has Tell/Warning/Gaze/Recede phases, swept sight exposure, continuous hearing, warning slam and capture. Covers automatically crouch Mina behind their art. All eight checkpoints restore position/section, flow snapshot slot, seen flags, and custom gap; capture/fade/respawn timers and invulnerability are implemented. Gates jump or stumble/climb. S5 closes the eye, clamps the wall gap, calls on downbeats, surges without changing time scale, and reaches the clinic ending, End of Chapter, and Restart.

R1 calibration, voice/keyboard mapping, throat guard, inertia, song/karaoke/blooms, ordered tutorial, bridge, settings, persistence, and replaceable asset services remain covered by regressions. The old R1 completion screen is replaced by level continuation as required. A button focus-release ordering bug discovered by testing Begin/Restart through their signals was fixed; focus now releases before scene replacement. Text remains above world shaders and shakes. Small label backings keep the voice meter and ME label legible against threat art.

## Differences from the full spec / interpretations

1. **Milestone boundary:** R3’s face slam, song cut before “dream,” SHH flash, cute→real switch, scripted eye/hold-breath/false-safe scares, strong-scare budget, layered music, flow meter, scream budget, and F1 debug panel are intentionally not built. Their level metadata is retained. S2 begins mechanically at 220 m without the face slam or instinct trigger; the world remains cute, while monsters use their real-only art. The existing pad supplies music after S1 rather than the future section-specific layers. Finale color-return changes are present but only visibly matter once R3 sets `world_real`. R2 includes the eye’s mechanical hearing-warning slam and the required threat cues.
2. **Contradictory chase tuning:** exact stated speeds/rubber-band/safe-zone values are preserved. S2/S3 near-gap speed is 3.8×0.75 = 2.85 m/s, below TALK’s 3 m/s; continuous talking therefore settles near a 4 m gap until a gate or another interruption. CP1 also supplies a safe-zone hold. The requested TALK-only capture within 15 seconds cannot coexist with those rules. The test’s TALK-only run is caught at the 520 m gate about 103 seconds after S2 starts. No hidden chase tuning was added.
3. **Contradictory Tell timing:** an arbitrary x crossing cannot both start a full Tell bar on a boundary and start Warning on the very next bar. Normal Tell begins at the crossing and fills the remainder of that bar; Warning starts on the next boundary. Warning, Gaze, and Recede start at bar boundaries; Idle resumes after the specified half-bar Recede. Safety is evaluated immediately before Gaze activation, delays once by one bar, then shortens/skips. Safe zones and respawn protection defer an unstarted sequence.
4. **Warning-slam hearing interval:** hearing is suspended during the specified one-second slam, then a new continuous 0.25 s interval can capture even if the sound was held throughout. This gives the warning its visible duration; the spec does not define a hearing debounce during the animation. Silent frames always reset the continuous timer. The R3 hold-breath hearing-reset hook is available and tested, but no hold-breath scare is played yet.
5. **Unspecified presentation choices:** the automatic climb after a 1.5 s stumble takes 0.6 s (data-driven); gate animation continues to read the same voice/throat rules. The finale eye closes over three bars. Four accepted hits force the door/flash even if extremely short onsets have supplied less than 60 m total travel; ordinary movement can finish sooner, as specified. UI progress/cover/call labels are in dialogue data. The R1 camera remains a screen-space world offset. Art/audio are original generated placeholders and missing fonts use the allowed engine default.

## Verification

Godot 4.7.2 at `/Applications/Godot.app/Contents/MacOS/Godot`: headless import, R1 regressions, director/unit integration tests, eight complete fake-voice runs, scene tests with keyboard events, and main-scene smoke check. Final totals: voice_test 52, run_model_test 34, r1_scene_test 40, art_registry_test 13, monster_director_test 51, level_model_test 40, playthrough 43, r2_scene_test 25 — 298 passed, 0 failed, plus the main-scene smoke check. The Compatibility tour captured 16 R2 views without console errors. All eight rhythmic runs reached the door without capture, crossed all four gazes/five gates, and used about 80.5–82.4 seconds of shouting. Test strategy follows 1 shout bar / 1.5 quiet bars, with cover approach, gate approach/reset, and finale onset adjustments. This is a simulated voice strategy, not a claim about a real player’s reaction time or microphone noise.

Rendered Compatibility tour saves to `/tmp/mina-r2-tour` (or `user://tour` / `TOUR_DIR` when rerun). It covers 16 R2 views. The retained R1 tour captured 11 views without console errors, covering calibration, brushing/trance, lyrics, bridge, settings, and core shaders. Tour placement helpers are test-only. Rendering uses Dummy audio so it never records live mic input; this cannot verify an audible mix. Existing user settings/calibration files are preserved/restored by tests.

## Hand tests / remaining limits

Play through with K/Shift/Ctrl/Space and then a microphone. Check quiet coasting into cover, beam exposure when not hidden, a first sound warning then a second capture, checkpoint restoration (including CP6’s 15 m gap), settings pause/recalibration during threats, jump versus stumble, ring timing, eye closure, ending lines and Restart. Repeat the R1 clinic, calibration retry/defaults, brush, karaoke and bridge checks. Verify sound perspective/levels, beat-call latency, seamless loops, and that input is never monitored. Resize the window and drop a differently sized PNG to inspect its appearance.

Not verified: live microphone permission/capture/calibration quality, vocal comfort, human ability to time cover stops and beat onsets, audible mixing/panning and device latency, arbitrary display/input configurations, or macOS export entitlements. Test timing and the spec’s total-playtime estimates are not a human playtest. Godot’s pre-existing editor normalization of `project.godot` was left untouched and excluded from the R2 commit.

---

The following records the previously committed R1 milestone; its scope statements are historical.

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
