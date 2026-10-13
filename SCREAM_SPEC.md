# Mina: Scream — Codex Spec (Godot 4 / 2D side-scroller)

Build, from an empty folder, a complete Godot 4 game: a side-scrolling horror runner where the player's **microphone volume** drives the character forward. Read this whole file before writing code. Where this spec is silent, choose the simplest implementation and log the decision in `NOTES.md`. Do not add systems this spec does not ask for.

All in-game text is English. Game jam theme: **flow state**.

---

## 0. Project setup and rules

- Godot 4.4 or newer (team uses 4.7), GDScript only, **GL Compatibility** renderer. No C#, no plugins, no downloaded assets. Run `git init` and commit after each milestone.
- Base resolution 1920×1080, stretch mode `canvas_items`, aspect `keep`. Window override 1280×720. Project name `Mina: Scream`.
- `project.godot`: `audio/driver/enable_input=true`.
- Architecture:
  - `scripts/logic/` — pure rules, no nodes, headless-testable (`run_model.gd`, `monster_director.gd`, `calibration.gd`, `level_data.gd`).
  - `scripts/view/` — scenes, drawing, input, audio playback.
  - `scripts/autoload/` — `GameState`, `ArtRegistry`, `Sfx`, `PostFX`, `VoiceInput`, `BeatClock`.
  - `data/` — `balance.json`, `level.json`, `song.json`, `dialogue.json`. **No gameplay numbers or player-facing strings in scripts.**
  - `art/`, `audio/`, `fonts/`, `shaders/`, `scenes/`, `tools/`, `tests/`.
- Deliver in three milestones, one commit each, project runnable after each:

| Milestone | Content |
| --- | --- |
| R1 Foundation + voice | Project skeleton, §3 core systems, `VoiceInput`, calibration, keyboard mode, voice→speed, inertia, side-scroll camera, voice meter, clinic (S0), flower path with song and tutorial (S1), settings panel |
| R2 Threats + level | Monster 1, Monster 2, cover/hiding, safety rules, checkpoints/respawn, speed gates, full level S2–S5 from `level.json`, ending, end screen |
| R3 Horror + polish | Face slam, all scares, cute→real art switch, music layers + `BeatClock`, scream budget, flow meter, debug panel, tests, `README.md` / `ART_MANIFEST.md` / `NOTES.md` |

---

## 1. Story (context; drives text and art)

Mina was bullied into silence. She freezes, can't speak, always feels watched — the opposite of flow. In therapy she plays with a sand tray, uncovers a small figurine of a running girl, and drifts into a dream.

- A flower path. She sings a nursery rhyme softly and walks. Pleasant, but only relaxation, not flow.
- A face slams into view: **SCREAM!!!** The dream turns into ink-scratched horror. A wall of faces chases her. She has to be loud to survive.
- Later an eye opens in the sky. Under its gaze any sound brings a giant hand down. She must hide behind cover and stay silent.
- She learns the rhythm — shout, hide, shout — until she stops thinking. The eye closes for good. She shouts on the beat into a door of light and wakes in the clinic.

Flow mapping: sky eye = self-consciousness ("everyone is watching"); chasing wall = anxiety; flower path = relaxation; dynamic difficulty = keeping the player in the flow channel; finale = action and awareness merging.

---

## 2. Scene flow

`Content warning → Clinic (calibration + sand tray) → Run level (S1–S5) → Clinic ending → End screen → Restart`

- `scenes/main.tscn` (`main.gd`) owns scene switching, the settings button (top-right, always visible) and the F1 debug panel.
- Content warning screen: dark background, centered text, one `Begin` button. Text: `This game contains psychological horror, sudden loud scares, and depictions of school bullying.\nIt uses your microphone. Grab some water. Short loud shouts work best.`
- End screen: `End of Chapter` + `Restart` (back to the clinic, skipping the content warning).

---

## 3. Core systems

### 3.1 `ArtRegistry` (every texture goes through it)

- `get_texture(key) -> Texture2D`. Lookup order: `res://art/<key>.png` → `res://art/<key>.svg` → `res://art/fallback.svg` → an in-code checkerboard. Cache results. On a miss, `push_warning` once per key; never crash.
- **Dropping a same-name PNG into `art/` must replace the placeholder with no code or scene changes, at any resolution.** Every display slot has a fixed rect; textures scale to fit keeping aspect ratio, centered (`TextureRect` with `STRETCH_KEEP_ASPECT_CENTERED`, or equivalent for sprites).
- **Animation strips:** a key may be a horizontal strip of N equal frames. N comes from `balance.json` → `art_frames` (missing = 1). A helper splits the strip into `AtlasTexture` frames. Changing frame count = edit one number.
- Scenes never reference image paths directly.

### 3.2 `Sfx`

- `play(key, volume_db=-10, pitch=1.0)`, `play_at(key, volume_db, pitch, pan)`, `loop(key, enabled, volume_db)` (keys `amb_*` and `mus_*` loop), `set_loop_volume(key, db, fade_s)`, `stop_all()`.
- Loads `res://audio/<key>.wav` (then `.ogg`). Missing file → silent + one warning. Replaceable by same-name files.

### 3.3 Dual versions and `world_real`

- The run world has two looks: `_cute` (dream: pastel, sticker/toy feel, thick clean outlines, smiling flowers) and `_real` (nightmare: ink lines, bone white, sick yellow-green, black, red as the only saturated color, paper grain, crosshatching).
- `DualSprite` node (`@tool`, visible in editor): given a base key, loads `<key>_cute` and `<key>_real` and cross-fades by a global `GameState.world_real` (0 = cute, 1 = real). If only one exists, derive the other with `shaders/dual_derive.gdshader` (real from cute: desaturate except reds, raise contrast, add hatch texture; cute from real: lift and pastelize, soften). Keys marked "real only" in §12 skip this.
- Line wobble: in real mode, sprites jitter their UV by ≤ 1.5 px at 8 fps (hand-drawn boil). Off when `Reduce screen distortion` is on.

### 3.4 `PostFX` (full-screen, real world only)

A `CanvasLayer` + `ColorRect` shader driven by `world_real` and a `stress` value 0–1 set by the run view (stress = clamp(1 − gap/16, 0, 1) during chases; 0.6 during gazes; 0 in S1 and safe zones).

| effect | driver |
| --- | --- |
| film grain + paper texture (`tex_grain`, `tex_paper`) | always in real mode, stronger with stress |
| vignette | stress; pulses with the heartbeat layer |
| desaturation except red | stress |
| breathing UV warp | stress |
| chromatic aberration | stress > 0.5 |

`Reduce screen distortion` → only grain and vignette remain.

### 3.5 UI styles and fonts

- Two subtitle styles, both always fully legible (no blur or jitter on text, ever):
  - **System prompt** (his voice): top-center, white, sans, ALL CAPS, size 44, dark outline.
  - **Therapist**: bottom-center, soft warm white, handwritten font, size 36, on `ui_subtitle` backing.
  - **ME** (Mina): same as therapist but speaker label `ME` and cooler color.
- Fonts: `fonts/system.ttf` and `fonts/therapist.ttf`; if missing, engine default. Paths in `dialogue.json`.
- One global `Theme` built in code. A small `UIFactory` helper for labels/buttons/texture rects.

### 3.6 Settings panel

Toggle with the top-right `SETTINGS` button. Contents: `Keyboard mode` (toggle), `Recalibrate microphone` (button), `Mic sensitivity` (slider −10..+10 dB), `Show voice meter` (toggle, default on), `Reduce screen distortion` (toggle), `Reduce scare intensity` (toggle), `Close`. Opening it pauses the run (`get_tree().paused`, panel uses `PROCESS_MODE_ALWAYS`). Persist to `user://settings.cfg`.

---

## 4. Voice input

### 4.1 `VoiceInput` autoload

1. Create audio bus `Mic` with an `AudioEffectCapture` at slot 0. Bus volume −80 dB (the player must never hear themselves).
2. An `AudioStreamPlayer` plays `AudioStreamMicrophone` on bus `Mic`, autoplay, `PROCESS_MODE_ALWAYS`.
3. Every frame: read all available frames from the capture, RMS over them, convert to dBFS: `20*log10(max(rms, 1e-6))`.
4. Smooth with one-pole filters: attack 50 ms, release 150 ms. Expose `db` (smoothed).
5. If `db` stays ≤ −110 for 3 s after start, show HUD line `No microphone detected. Press K for keyboard mode.` and continue.

Public API (rules read only these):

```
var db: float                 # smoothed dBFS
var speed_target: float       # m/s, mapping in 4.3
var is_audible: bool          # db >= hum_db
var is_shouting: bool         # db >= shout_db
var level01: float            # HUD meter: clamp((db - floor_db) / (cal_shout_db - floor_db), 0, 1)
var tier: String              # "QUIET" | "HUM" | "TALK" | "SHOUT"
func set_calibration(floor_db, talk_db, cal_shout_db) -> void
```

### 4.2 Calibration (`scripts/logic/calibration.gd`, used by the clinic and the Recalibrate overlay)

- `floor_db` = 90th percentile of smoothed dB over 3 s of silence.
- `talk_db` = 70th percentile of frames above `floor_db + 6` over a 3 s window while the player says hi.
- `cal_shout_db` = peak smoothed dB over a 3 s window while the player calls out once.
- Guards, in order: if `talk_db < floor_db + 6` → `talk_db = floor_db + 10`. If `cal_shout_db < talk_db + 8` → `cal_shout_db = talk_db + 12` (and flag `retry`).
- Defaults if skipped: `floor -50`, `talk -32`, `cal_shout -14`.
- Save to `user://voice_calibration.cfg`, load on boot. Calibration still runs in every new game (it is part of the story).

### 4.3 Voice → speed (**running must not need a huge scream**)

```
hum_db   = floor_db + 6
talk_db  = calibrated
shout_db = talk_db + 0.5 * (cal_shout_db - talk_db)   # halfway between talking and the calibration call: a clearly raised voice, NOT a full scream
```

`sensitivity_db` (settings) is added to all three thresholds (negative = easier).

Piecewise linear in dB:

| dB | target speed | tier |
| --- | --- | --- |
| `< hum_db` | 0 m/s | QUIET |
| `hum_db` | 1.5 m/s | HUM |
| `talk_db` | 3.0 m/s | TALK |
| `>= shout_db` | 7.0 m/s (cap) | SHOUT |

Interpolate linearly between rows. Louder than `shout_db` gives nothing extra.

### 4.4 Movement (`scripts/logic/run_model.gd`)

- Acceleration toward a higher target: reaches it in 0.3 s (linear).
- Toward a lower target: exponential decay, half-life 1.0 s (after a 1-bar shout she coasts ≈ 9 m while the player breathes).
- **Throat guard:** after 3.0 s of continuous `is_shouting`, cap target at 5.0 m/s until the voice drops below `shout_db` for 0.5 s.
- **Instinct scream bonus:** if `is_shouting` begins within 1.5 s after a scripted scare, speed ×1.3 for 2.0 s.

### 4.5 Keyboard mode (required)

Toggle in settings or with `K`. Hold `Space` = SHOUT, `Ctrl` = TALK, `Shift` = HUM, nothing = QUIET. It writes a synthetic `db` (threshold + 1 dB) so every rule behaves identically. For development and accessibility.

---

## 5. Camera and HUD

- Side view, running left → right. **1 m = 80 px.** Mina drawn at screen x = 760, feet at y = 860. Visible: ≈ 9.5 m behind, ≈ 14.5 m ahead.
- 3 parallax layers (`run_bg_far` 0.2, `run_bg_mid` 0.5, `run_bg_near` 0.8) + `run_ground` strip, all horizontally tiled, all `DualSprite`.
- Mina's sprite by state: speed 0 → `mina_idle`; < 2.2 → `mina_walk`; < 5 → `mina_jog`; ≥ 5 → `mina_run`; hidden → `mina_crouch`; captured → `mina_caught`. Animation fps scales with speed.
- **Voice meter** (bottom-left, 520×70): bar showing `level01`, tick marks at the HUM / TALK / SHOUT thresholds with labels `HUM` `TALK` `SHOUT` under them; the current tier label highlights. Hidden if `Show voice meter` is off.
- **Lyrics bar** (top-center, 1400×130) in S1 only (§6 S1). System prompts sit just below it while it is visible.

---

## 6. Level walk-through

One bar = **2.4 s** everywhere (4/4 at 100 BPM, or 6/8 with an eighth note = 0.4 s). Total ≈ 1140 m, ≈ 7–8 min without deaths. All positions come from `data/level.json` (§11.2); do not hard-code them.

### S0 — Clinic: calibration + sand tray (≈ 60 s)

Calm, realistic, clean art: beige, grey-green, warm white, rounded shapes, no grain, no wobble, no PostFX. Only `amb_clinic` and `amb_clock`. Top-down view of a sand tray on a table (`clinic_bg`, `sandtray`).

1. Therapist: `Let's be quiet for a moment.` → 3 s silence sample. A soft ring drawn in the sand fills as the sample progresses.
2. Therapist: `Can you say hi to her?` (a small figure stands in the tray) → talk sample. The figure turns toward the player when voice is heard.
3. Therapist: `If you ever needed help, how loud would you call? Just once.` → shout sample. If the `retry` flag is set: `A little louder? It's okay.` and repeat step 3 once.
4. Therapist: `Thank you. Could you tidy the sand for me?` → **sand brush**:
   - `sand_layer` covers the tray. A mask image (≈ 535×265) records brushed areas; a shader hides sand where the mask is set. Hold left mouse and drag to brush (soft-edged radius 38 px), with sand particles and `sfx_sand`.
   - Buried under it: `buried_runner_doll` (a small running-girl figurine). The sand above it is slightly raised as a hint.
   - When 70% of the doll's rect is revealed: therapist `What did you find?`, then the **trance transition** (2.5 s): colors drain, view narrows onto the doll, `sfx_blur_in` swells, sand grains float upward, then a pastel wash fades into S1.
5. Keyboard mode: steps 1–3 show `Press Space to continue` and use defaults.

### S1 — Flower path: sing-along + volume tutorial (0–220 m, ≈ 90 s)

`world_real = 0`. Bright pastel flowers, butterflies, `mus_song` + `mus_pad`. No threats.

**Song:** `Row, Row, Row Your Boat` (public domain, 1852; "gently… life is but a dream" fits). Fully data-driven in `song.json` so the team can swap in another song.

- The melody loops (8 bars = 19.2 s). The lyrics bar shows the current line large and the next line small; each syllable highlights at its time (karaoke).
- If `is_audible` during a syllable's window, that syllable turns gold and a flower blooms at Mina's feet (`flower_bud` → `flower_open`, `sfx_bloom`). Volume only, no pitch detection.
- Movement uses 4.3. Singing at TALK is the natural pace.

**Tutorial** (gated, in order; each system prompt stays until done, min 4 s; the voice meter pulses the matching tick):

| order | prompt | done when |
| --- | --- | --- |
| 1 (at 0 m) | `HUM TO WALK.` | 2 s cumulative at ≥ HUM |
| 2 | `SING LOUDER TO JOG.` | 2 s cumulative at ≥ TALK |
| 3 | `SHOUT TO RUN.` | 1 s cumulative at SHOUT |
| 4 | `SING ALONG.` | auto-clears after 6 s |

No time pressure in S1; standing still is fine.

- **Flower bridge** (88–100 m) over a gap: Mina stops at 88 m. The bridge lifts in proportion while the player holds ≥ TALK; fully up after 1 bar cumulative (`sfx_bridge`). Then she can cross.
- **Foreshadow:** at SHOUT in S1 after the tutorial, flash one frame of the full real look (≤ 1 per 3 s) and show prompt `SHH.` for 1 s. No penalty.

**The face slam (≈ 215–220 m):**

1. After crossing 215 m, at the start of the next `life is but a dream.` line, the song plays `life is but a` and **cuts before `dream.`** Lyrics freeze. 0.6 s of total silence; she keeps moving with voice.
2. `m1_face_closeup` fills the screen instantly, scales 1.0→1.15 over 0.4 s, `sfx_face_slam` at full volume, screen shake 24 px for 0.3 s.
3. Big red centered `SCREAM!!!` (size 140, shaking) for 1.6 s.
4. Under the face the world switches to real (`world_real = 1`) in one frame; face fades out over 0.3 s.
5. Monster 1 spawns 10 m behind; frozen for its first 1.5 s. Chase music starts. Counts as a scripted scare (instinct bonus applies).
6. `Reduce scare intensity`: face fades in over 0.8 s, −12 dB, no shake.

Checkpoint CP1 is just after; respawns never replay the slam.

### S2 — Chase (220–560 m, ≈ 75 s)

Monster 1 only. `mus_pad` + `mus_drums` + `mus_heart`; the drums alternate a "shout bar" (accented) and a "breathe bar" (sparse) to teach rhythm.

- Therapist at 230 m: `Now. Run.`
- Safe zone CP2 at 400 m; therapist at 410 m: `Breathe. Then go again.`
- Speed gates at 470 m and 520 m.

### S3 — The eye opens (560–820 m, ≈ 70 s)

Monster 1 + first **two** gazes of Monster 2 (Monster 2 stays rare for now; all data-driven).

- Safe zone CP3 at 560 m.
- 590 m: **scripted first gaze** (2 bars), cover `cover_flower_big` at 600 m. Monster 1 **frozen** for the whole gaze + 2 s. Therapist: `Hide. Stay still. Don't make a sound.`
- 670 m: normal gaze (2 bars), cover at 680 m, full safety rules.
- Safe zone CP4 at 700 m. Speed gate at 760 m.

### S4 — Both (820–1080 m, ≈ 70 s)

Darkest look, heavy vignette. Music: `mus_heart` + `amb_tinnitus` only. Monster 1 faster (§11.1).

- Safe zone CP5 at 820 m. Gaze (3 bars) at 850 m, cover `cover_desk` at 860 m. Speed gate at 900 m.
- Safe zone CP6 at 960 m. Gaze (3 bars) at 990 m with the **hold-your-breath** scare, cover `cover_locker` at 1000 m. Speed gate at 1050 m.

### S5 — Finale: flow (1080–1140 m, ≈ 30 s)

- CP7 at 1080 m. The eye opens once, looks, slowly closes (no gaze rules). Therapist: `You don't have to look for it anymore.` It never returns.
- `light_door` at 1140 m. Monster 1 follows at 3.0 m/s but **cannot catch** (gap clamped ≥ 3 m).
- All music layers + `mus_flow`. On beat 1 of every bar `sfx_beat_call` plays and `ui_beat_ring` pulses around Mina. If `is_shouting` begins within **−0.3 s to +0.6 s** of that downbeat → **surge**: +12 m over 0.5 s, `world_real` −0.25 (colors return), parallax/particles 20% slower (never change `Engine.time_scale`). Missed calls repeat. **4 hits** reach the door. Normal movement still works.
- 4th hit: white flash 1 s, all audio cuts → ending.

### Ending — Clinic

Clinic art, `amb_clock`. Therapist: `You weren't scared of being heard.` 2 s pause. `ME`: `...He took my things.` Hold 3 s → End screen.

---

## 7. Level objects

### 7.1 Checkpoint / safe zone

- `safe_puddle` on the ground (reflects a clinic window), soft light.
- Zone = x ± 3 m. Inside: Monster 1 held at gap ≥ 12 m and does not move; no gaze starts; music softens; `sfx_safe` on entry. After leaving, Monster 1 waits `hold_s` (6 s) then `sfx_m1_roar` and resumes.
- Entering saves the checkpoint: x, flow meter, flags of scripted scares already played.

### 7.2 Respawn

Capture: `mina_caught` + `sfx_capture` 1.2 s → fade to black 0.5 s → last checkpoint. 3 s invulnerability. Monster 1 gap = 12 m (or the checkpoint's `respawn_gap`). No scare within 10 s of a respawn.

### 7.3 Cover

- Large foreground objects (`cover_flower_big`, `cover_desk`, `cover_locker`, `cover_bag`).
- Zone = x ± 0.8 m. **Hidden** = in the zone and speed < 0.5 m/s → `mina_crouch`, drawn behind the cover. No button.

### 7.4 Speed gate

- `gap_crack` in the ground, 2 m wide.
- Edge reached at ≥ 6.0 m/s → auto jump (0.6 s arc), `sfx_jump`.
- Below → stumble: speed 0 for 1.5 s, `sfx_stumble`, then she climbs across. Never a death by itself.

---

## 8. Monsters and safety rules

### 8.1 Monster 1 — the wall of faces (chaser)

- Tracked as `gap` (m) behind Mina; captured at `gap <= 0`.
- Speed: base per section (§11.1). Rubber band: `gap > 18` → 6.0 m/s; `gap < 4` → base × 0.75 (looks most violent here, quietly holds back).
- Look: **Junji Ito–inspired body horror** — a towering wall of sand packed with human faces; dense ink crosshatching; faces stretched, overlapping, some upside-down; eyes too wide; mouths opened too far. Faces turn to track Mina. Do not copy any specific existing character or panel.
- Off-screen presence (gap 9.5–16 m): left screen edge darkens; `m1_face_peek` faces slide in from the edge.
- Audio: `amb_m1_breath` + `amb_m1_sand` loops; volume −40 dB at 16 m → −6 dB at 2 m. `sfx_m1_roar` when it resumes full speed.

### 8.2 Monster 2 — the eye in the sky (silence)

Gaze state machine, every phase starting on a bar boundary (`BeatClock`):

| phase | length | behavior |
| --- | --- | --- |
| Tell | the bar before Warning | drums drop out |
| Warning | 1 bar | `sfx_m2_crack`, `m2_sky_crack` opens, shadow over the top 40% of the screen |
| Gaze | 2 or 3 bars (level data) | `m2_eye_open` above Mina; sight + hearing active; `amb_m2_light` |
| Recede | ½ bar | `m2_eye_closed`, `sfx_all_clear` |

- **Sight:** `m2_beam` sweeps the ground ±10 m around Mina at 4 m/s, back and forth. Beam over a **non-hidden** Mina for 0.8 s cumulative in this gaze → capture.
- **Hearing:** `db >= hum_db` for 0.25 s continuous = heard (hidden or not). First time in a gaze → **warning slam**: `m2_hand` slams the ground 2 m behind Mina, `sfx_m2_slam`, shake 16 px, 1.0 s. Second time in the same gaze → capture (`sfx_m2_grab`).
- Trigger: passing a `gaze` event x schedules Warning at the next bar start, subject to §8.3. On load, validate that a cover exists ≤ 12 m after each gaze trigger; warn in the console if not.

### 8.3 Safety rules (`monster_director.gd`)

1. During Gaze, Monster 1 slows to 0.8 m/s (it fears the eye too). The player hears it crawling closer while she must stay silent.
2. A gaze may start only if `gap >= 0.8 * gaze_seconds + 4`. Otherwise delay 1 bar. Still not → shorten to `floor((gap - 4) / 0.8 / bar_s)` bars (min 1); if that is < 1, skip the gaze.
3. After Recede, Monster 1 stays at 0.8 m/s for 1.5 s, then `sfx_m1_roar` and full speed (the intended "scream now" moment).
4. No two captures within 3 s; respawn invulnerability 3 s.
5. A gaze with `scripted_first`: Monster 1 speed 0 for the whole gaze + 2 s.

Reference math (bar 2.4 s, base 3.8 / 4.2 m/s): talking only (3 m/s) is caught in ≈ 12 s / 8 s from 10 m. Shout 1 bar / rest 1.5 bars ≈ 4.35 m/s average (barely gains). Shout 1 bar / rest 1 bar ≈ 5.2 m/s (gains clearly). Keep this relationship when tuning.

---

## 9. Scares

| id | where | what | strength |
| --- | --- | --- | --- |
| `s1_flash` | S1, shouting after tutorial | 1-frame real flash + `SHH.` | weak |
| `face_slam` | 215–220 m | §6 face slam | strong |
| `eye_first` | first gaze | sky tears open slowly, music detunes, eye opens | medium |
| `roar_after_gaze` | every gaze end | §8.3 rule 3 | medium |
| `hold_breath` | gaze with `"scare":"hold_breath"` | mid-gaze, a face (`m1_face_peek`) slides out from the side of the cover to almost touch Mina, holds 1.5 s, slides back. **Silent.** Resets the hearing count (screaming here gives a fresh warning, not a capture) | strong |
| `false_safe` | checkpoint with `"scare":"false_safe"`; disabled by default | puddle shows the therapist, then a hand reaches out and withdraws; harmless | medium |

Rules: max 4 strong scares per run; ≥ 45 s between scripted scares; none within 10 s of a respawn; never replay a seen scripted scare after respawn; no flashing faster than 3 Hz. `Reduce scare intensity` → strong scares fade in, −12 dB, no shake. Toggles in `balance.json` → `scares`.

---

## 10. Music, BeatClock, flow meter, scream budget

### 10.1 `BeatClock` autoload

- Bar = `bar_s`. Source of truth: playback position of the master loop (`get_playback_position() + AudioServer.get_time_since_last_mix()`); own timer when no music plays.
- Signals `bar_started(index)`, `beat(index_in_bar)`; `time_to_next_bar()`.
- Music layers, started together and kept in sync: `mus_song` (8 bars), `mus_pad`, `mus_drums`, `mus_heart`, `mus_flow` (4 bars each). Fade layers by section: S1 song+pad; S2–S3 pad+drums+heart; S4 heart + `amb_tinnitus`; S5 all + flow.

### 10.2 Flow meter (R3, build last)

- 0–100, drawn as `ui_flow_petal` petals around the voice meter.
- Each bar +4 if the player did the right thing (moving during chase bars; hidden and silent during gaze bars). Warning slam −15, stumble −10, capture → checkpoint value.
- ≥ 30: drum accent layer. ≥ 60: `mus_flow` in, monster audio −30%, `world_real` −0.2. ≥ 90: vignette opens, SHOUT speed ×1.1.

### 10.3 Scream budget (vocal health)

- Track `is_shouting` seconds per section. Budgets: S2 30, S3 22, S4 22, S5 6 (≈ 80 s total).
- Over budget × 1.2 → Monster 1 base −0.3 m/s for the rest of that section, and the next safe zone `hold_s` = 10. Invisible to the player.

---

## 11. Data files

### 11.1 `data/balance.json`

```json
{
  "bar_s": 2.4,
  "px_per_m": 80,
  "player_screen_x": 760,
  "calibration_defaults": {"floor_db": -50, "talk_db": -32, "cal_shout_db": -14},
  "hum_offset_db": 6,
  "shout_fraction": 0.5,
  "speeds": {"hum": 1.5, "talk": 3.0, "shout": 7.0},
  "accel_s": 0.3,
  "decel_half_life_s": 1.0,
  "throat_guard": {"after_s": 3.0, "cap": 5.0, "reset_s": 0.5},
  "instinct_bonus": {"window_s": 1.5, "mult": 1.3, "duration_s": 2.0},
  "speed_gate": {"min_speed": 6.0, "stumble_s": 1.5, "width_m": 2},
  "m1": {
    "base_speed": {"S2": 3.8, "S3": 3.8, "S4": 4.2, "S5": 3.0},
    "spawn_gap": 10, "spawn_grace_s": 1.5, "respawn_gap": 12,
    "far_gap": 18, "far_speed": 6.0, "near_gap": 4, "near_mult": 0.75,
    "gaze_speed": 0.8, "post_gaze_slow_s": 1.5
  },
  "m2": {
    "warning_bars": 1, "recede_bars": 0.5,
    "beam_half_range_m": 10, "beam_speed": 4.0, "sight_s": 0.8,
    "hear_s": 0.25, "slam_offset_m": 2.0,
    "max_cover_distance_m": 12, "safety_margin_m": 4
  },
  "safe_zone": {"half_width_m": 3, "hold_s": 6, "hold_s_over_budget": 10},
  "cover_half_width_m": 0.8, "hide_speed": 0.5,
  "respawn": {"invuln_s": 3, "no_scare_s": 10, "capture_anim_s": 1.2},
  "finale": {"window_early_s": 0.3, "window_late_s": 0.6, "surge_m": 12, "hits": 4, "min_gap": 3},
  "scream_budget_s": {"S2": 30, "S3": 22, "S4": 22, "S5": 6},
  "flow": {"per_bar": 4, "slam": -15, "stumble": -10},
  "scares": {"s1_flash": true, "face_slam": true, "eye_first": true, "roar_after_gaze": true, "hold_breath": true, "false_safe": false},
  "strong_scare_limit": 4, "scare_min_gap_s": 45,
  "sand": {"brush_radius_px": 38, "reveal_target": 0.7, "transition_s": 2.5},
  "art_frames": {"mina_idle": 2, "mina_walk": 6, "mina_jog": 6, "mina_run": 6, "mina_crouch": 1, "mina_caught": 4, "m1_wall": 4}
}
```

### 11.2 `data/level.json`

Ordered events by x (m). Types: `section`, `checkpoint`, `tutorial`, `bridge`, `song_cut`, `face_slam`, `subtitle`, `gate`, `gaze`, `cover`, `finale`, `door`.

```json
{"events": [
  {"x": 0,    "type": "section", "id": "S1"},
  {"x": 0,    "type": "checkpoint", "id": "CP0"},
  {"x": 0,    "type": "tutorial"},
  {"x": 88,   "type": "bridge", "length_m": 12},
  {"x": 215,  "type": "song_cut"},
  {"x": 220,  "type": "face_slam"},
  {"x": 220,  "type": "section", "id": "S2"},
  {"x": 222,  "type": "checkpoint", "id": "CP1"},
  {"x": 230,  "type": "subtitle", "voice": "therapist", "key": "now_run"},
  {"x": 400,  "type": "checkpoint", "id": "CP2"},
  {"x": 410,  "type": "subtitle", "voice": "therapist", "key": "breathe"},
  {"x": 470,  "type": "gate"},
  {"x": 520,  "type": "gate"},
  {"x": 560,  "type": "section", "id": "S3"},
  {"x": 560,  "type": "checkpoint", "id": "CP3"},
  {"x": 590,  "type": "gaze", "bars": 2, "scripted_first": true, "subtitle": "hide_still"},
  {"x": 600,  "type": "cover", "art": "cover_flower_big"},
  {"x": 670,  "type": "gaze", "bars": 2},
  {"x": 680,  "type": "cover", "art": "cover_flower_big"},
  {"x": 700,  "type": "checkpoint", "id": "CP4"},
  {"x": 760,  "type": "gate"},
  {"x": 820,  "type": "section", "id": "S4"},
  {"x": 820,  "type": "checkpoint", "id": "CP5"},
  {"x": 850,  "type": "gaze", "bars": 3},
  {"x": 860,  "type": "cover", "art": "cover_desk"},
  {"x": 900,  "type": "gate"},
  {"x": 960,  "type": "checkpoint", "id": "CP6", "respawn_gap": 15, "scare": "false_safe"},
  {"x": 990,  "type": "gaze", "bars": 3, "scare": "hold_breath"},
  {"x": 1000, "type": "cover", "art": "cover_locker"},
  {"x": 1050, "type": "gate"},
  {"x": 1080, "type": "section", "id": "S5"},
  {"x": 1080, "type": "checkpoint", "id": "CP7"},
  {"x": 1080, "type": "finale"},
  {"x": 1140, "type": "door"}
]}
```

Decorative props (flowers in S1; withered flowers, scattered school items, desks in S2–S4) are placed procedurally from a seeded RNG per section, not in this file.

### 11.3 `data/song.json`

1 unit = 0.4 s (an eighth note in 6/8; 6 units = 1 bar). Notes drive the placeholder melody synth.

```json
{
  "title": "Row, Row, Row Your Boat",
  "unit_s": 0.4,
  "lines": [
    {"syllables": [["Row,",3,"C4"],["row,",3,"C4"],["row",2,"C4"],["your",1,"D4"],["boat,",3,"E4"]]},
    {"syllables": [["gent",2,"E4"],["ly",1,"D4"],["down",2,"E4"],["the",1,"F4"],["stream.",6,"G4"]]},
    {"syllables": [["Mer",1,"C5"],["ri",1,"C5"],["ly,",1,"C5"],["mer",1,"G4"],["ri",1,"G4"],["ly,",1,"G4"],["mer",1,"E4"],["ri",1,"E4"],["ly,",1,"E4"],["mer",1,"C4"],["ri",1,"C4"],["ly,",1,"C4"]]},
    {"syllables": [["life",2,"G4"],["is",1,"F4"],["but",2,"E4"],["a",1,"D4"],["dream.",6,"C4"]]}
  ]
}
```

Syllable = `[text, length_units, note]`; its sing window = its start to its end. `song_cut` stops before the last `dream.`. `mus_song` must be generated from this file so audio and lyrics match.

### 11.4 `data/dialogue.json`

Every player-facing string in this spec (prompts, subtitles, content warning, settings labels, HUD warnings, end screen) plus font paths. No string literals in scripts.

---

## 12. Art (all replaceable)

- Placeholders generated by `tools/generate_resources.py` as SVG into `art/`. It must **never overwrite** an existing PNG, and never touch `data/`. Keep generator sources in `tools/`.
- Quality bar for placeholders: recognizable silhouette, outline, ≥ 2 shading levels, texture or hatching; no flat boxes; **no baked text** (all text is `Label`). Cute and real versions must be clearly different at a glance.
- Write `ART_MANIFEST.md`: every key, purpose, size, where used, dual or not, frame count.

| key | size | dual | frames | notes |
| --- | --- | --- | --- | --- |
| `fallback` | 256×256 | no | 1 | generic placeholder |
| `clinic_bg` | 1920×1080 | no | 1 | top-down table, warm clinic |
| `sandtray` | 1100×600 | no | 1 | wooden tray |
| `sand_layer` | 1070×530 | no | 1 | sand surface covering the tray |
| `clinic_figure` | 160×220 | no | 1 | small figure for the talk sample |
| `buried_runner_doll` | 300×300 | no | 1 | running-girl figurine |
| `mina_idle` `mina_walk` `mina_jog` `mina_run` `mina_crouch` `mina_caught` | 300×360 per frame | yes | from `art_frames` | |
| `run_bg_far` `run_bg_mid` `run_bg_near` | 1920×1080, horizontally tileable | yes | 1 | parallax |
| `run_ground` | 512×220, tileable | yes | 1 | |
| `flower_bud` `flower_open` | 160×200 | yes | 1 | withered in real |
| `flower_bridge` | 960×240 | yes | 1 | |
| `cover_flower_big` `cover_desk` `cover_locker` `cover_bag` | 420×520 | yes | 1 | |
| `gap_crack` | 200×220 | yes | 1 | |
| `prop_school_item` | 200×200 | yes | 1 | decoration in S2–S4 |
| `safe_puddle` | 480×120 | no | 1 | reflects a clinic window |
| `light_door` | 500×800 | no | 1 | |
| `m1_wall` | 900×1080 per frame | real only | from `art_frames` | wall of faces |
| `m1_face_peek` | 500×500 | real only | 1 | |
| `m1_face_closeup` | 1920×1080 | real only | 1 | face slam |
| `m2_sky_crack` | 1920×440 | real only | 1 | |
| `m2_eye_open` `m2_eye_closed` | 600×300 | real only | 1 | |
| `m2_beam` | 300×900 | real only | 1 | additive |
| `m2_hand` | 600×900 | real only | 1 | |
| `tex_grain` `tex_paper` `tex_hatch` | 512×512, tileable | no | 1 | PostFX / derive shader |
| `ui_voice_meter` `ui_voice_marker` `ui_lyrics_bar` `ui_flow_petal` `ui_beat_ring` `ui_subtitle` `ui_panel` | by slot | no | 1 | |

---

## 13. Audio (all replaceable)

Generate placeholder WAVs with a script in `tools/` into `audio/` (atmospheric: low drones, reverb pulses, noise sweeps — not single beeps). `amb_*` and `mus_*` loop seamlessly.

- Music (bar 2.4 s): `mus_song` (from `song.json`, music-box timbre, 19.2 s), `mus_pad`, `mus_drums` (shout bar / breathe bar), `mus_heart`, `mus_flow` (9.6 s each).
- Clinic: `amb_clinic`, `amb_clock`, `sfx_sand`, `sfx_blur_in`.
- Monsters: `sfx_face_slam`, `sfx_m1_roar`, `amb_m1_breath`, `amb_m1_sand`, `sfx_m2_crack`, `amb_m2_light`, `sfx_m2_slam`, `sfx_m2_grab`, `sfx_all_clear`.
- World: `sfx_bloom`, `sfx_bridge`, `sfx_jump`, `sfx_stumble`, `sfx_safe`, `sfx_door`, `sfx_beat_call`, `sfx_capture`, `amb_tinnitus`.

---

## 14. Debug panel (F1)

Live: `db`, tier, thresholds, speed, x, section, Monster 1 gap, Monster 2 phase, shouting seconds (total + per section), flow meter. Buttons: jump to any checkpoint, god mode (no captures), force gaze now, force face slam, set `world_real` slider.

---

## 15. Tests

Headless: `godot --headless --path . --scene res://tests/<name>.tscn`; each prints pass/fail counts and exits non-zero on failure.

- `voice_test`: 4.3 mapping (exact anchors, midpoints, cap), calibration guards and defaults, sensitivity offset, throat guard, keyboard mode values.
- `run_model_test`: accel/decay timing, speed gate jump vs stumble, instinct bonus window.
- `monster_director_test`: rubber band; gaze start rule, delay, shortening, skip; gaze speed and post-gaze slow; hearing (first slam, second capture, `hold_breath` reset); sight 0.8 s; no double capture within 3 s; safe zone hold.
- `playthrough`: 8× simulation with a fake voice source:
  - `talk_only` → captured in S2 within 15 s of the face slam.
  - `shout_40` (1 bar shout / 1.5 bars quiet; silent and hidden during gazes) → reaches the door.
  - `loud_in_gaze` (shouts while hidden in a gaze) → one slam, then capture.
  - `shout_40` total shouting ≤ 90 s.
- `tour.tscn` (with display): drive real input and screenshot calibration, S1 with lyrics, bridge, face slam, chase, hidden gaze, warning slam, speed gate, safe zone, finale, ending. Save to `user://tour/` or `$TOUR_DIR`.
- A check that a different-size same-name PNG in `art/` overrides the SVG and keeps layout.

---

## 16. Acceptance checklist

- [ ] Opens and runs: content warning → clinic calibration → sand tray → S1 → … → ending → End screen → Restart. No console errors.
- [ ] Humming moves Mina slowly; normal talking jogs; a raised voice (not a full scream) reaches max speed; louder gives nothing extra.
- [ ] Calibration works with a mic; keyboard mode works without one.
- [ ] S1 tutorial prompts appear in order and clear correctly; lyrics highlight in time; sung syllables turn gold and bloom flowers; the bridge rises with voice.
- [ ] Song cuts before "dream"; face slam + `SCREAM!!!`; art switches to real; chase starts; respawn never replays it.
- [ ] Talking alone gets you caught; rhythmic shouting escapes.
- [ ] Gazes follow bar timing; hidden + silent is always safe; first sound = slam, second = capture; the beam catches a non-hidden player.
- [ ] Safety rules hold; no double capture; finale cannot fail; 4 on-beat shouts reach the door; ending lines play.
- [ ] Respawn returns to the last safe zone with the correct gap.
- [ ] Every texture key is replaceable by dropping a PNG of a different size; layout holds; strip frame counts come from data.
- [ ] All text from `dialogue.json`, numbers from `balance.json`, layout from `level.json`, lyrics from `song.json`.
- [ ] Settings all work and persist; `Reduce screen distortion` and `Reduce scare intensity` behave as specified.
- [ ] `README.md` (run, mic permission, keyboard mode, F1, editing data, replacing art/audio/fonts), `ART_MANIFEST.md`, `NOTES.md` (decisions, what was not verified) present.

## 17. macOS (put in README)

- First run in the editor triggers the microphone permission prompt; if denied, enable Godot in System Settings → Privacy & Security → Microphone.
- macOS export: enable the microphone entitlement and fill `Privacy > Microphone Usage Description`, otherwise the exported game hears silence.
