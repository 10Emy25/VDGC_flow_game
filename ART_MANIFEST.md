# R1/R2 art manifest

All textures route through ArtRegistry. Fixed slots center and preserve aspect at replacement resolutions; PNG overrides SVG. Dual and animated keys use their base `art_frames` count. R3-only assets (face closeup, flow petals and music layers) remain absent.

| Key | SVG source size | Dual | Frames | Purpose / usage |
| --- | --- | --- | --- | --- |
| `buried_runner_doll` | 300×300 (300×300/frame) | no | 1 | Clinic reveal, trance focus, ending |
| `clinic_bg` | 1920×1080 (1920×1080/frame) | no | 1 | Clinic, recalibration and ending backdrop |
| `clinic_figure` | 160×220 (160×220/frame) | no | 1 | Talk-sample figure |
| `cover_bag_cute` | 420×520 (420×520/frame) | yes | 1 | Available cover key; no placement in the specified level |
| `cover_bag_real` | 420×520 (420×520/frame) | yes | 1 | Available cover key; no placement in the specified level |
| `cover_desk_cute` | 420×520 (420×520/frame) | yes | 1 | 860 m hiding; smaller seeded decoration |
| `cover_desk_real` | 420×520 (420×520/frame) | yes | 1 | 860 m hiding; smaller seeded decoration |
| `cover_flower_big_cute` | 420×520 (420×520/frame) | yes | 1 | 600/680 m automatic hiding |
| `cover_flower_big_real` | 420×520 (420×520/frame) | yes | 1 | 600/680 m automatic hiding |
| `cover_locker_cute` | 420×520 (420×520/frame) | yes | 1 | 1000 m hiding |
| `cover_locker_real` | 420×520 (420×520/frame) | yes | 1 | 1000 m hiding |
| `fallback` | 256×256 (256×256/frame) | no | 1 | Missing-art safety fallback |
| `flower_bridge_cute` | 960×240 (960×240/frame) | yes | 1 | 88–100 m lifting bridge |
| `flower_bridge_real` | 960×240 (960×240/frame) | yes | 1 | 88–100 m lifting bridge |
| `flower_bud_cute` | 160×200 (160×200/frame) | yes | 1 | Syllable bloom start |
| `flower_bud_real` | 160×200 (160×200/frame) | yes | 1 | Syllable bloom start |
| `flower_open_cute` | 160×200 (160×200/frame) | yes | 1 | Decorative and sung flowers |
| `flower_open_real` | 160×200 (160×200/frame) | yes | 1 | Decorative and sung flowers |
| `gap_crack_cute` | 200×220 (200×220/frame) | yes | 1 | Five speed gates, 2 m logical width |
| `gap_crack_real` | 200×220 (200×220/frame) | yes | 1 | Five speed gates, 2 m logical width |
| `light_door` | 500×800 (500×800/frame) | no | 1 | 1140 m finale exit |
| `m1_face_peek` | 500×500 (500×500/frame) | real only | 1 | Left edge presence at 9.5–16 m |
| `m1_wall` | 3600×1080 (900×1080/frame) | real only | 4 | Chaser wall of overlapping faces; animated gaze ahead |
| `m2_beam` | 300×900 (300×900/frame) | real only | 1 | Additive swept sight exposure |
| `m2_eye_closed` | 600×300 (600×300/frame) | real only | 1 | Recede and finale eye closure |
| `m2_eye_open` | 600×300 (600×300/frame) | real only | 1 | Gaze and finale eye |
| `m2_hand` | 600×900 (600×900/frame) | real only | 1 | First hearing-warning slam |
| `m2_sky_crack` | 1920×440 (1920×440/frame) | real only | 1 | Warning/Gaze/Recede sky opening |
| `mina_caught_cute` | 1200×360 (300×360/frame) | yes | 4 | 1.2 s capture animation |
| `mina_caught_real` | 1200×360 (300×360/frame) | yes | 4 | 1.2 s capture animation |
| `mina_crouch_cute` | 300×360 (300×360/frame) | yes | 1 | Automatic hiding behind covers |
| `mina_crouch_real` | 300×360 (300×360/frame) | yes | 1 | Automatic hiding behind covers |
| `mina_idle_cute` | 600×360 (300×360/frame) | yes | 2 | Stationary Mina |
| `mina_idle_real` | 600×360 (300×360/frame) | yes | 2 | Stationary Mina |
| `mina_jog_cute` | 1800×360 (300×360/frame) | yes | 6 | Mina below jog cutoff |
| `mina_jog_real` | 1800×360 (300×360/frame) | yes | 6 | Mina below jog cutoff |
| `mina_run_cute` | 1800×360 (300×360/frame) | yes | 6 | Mina at running pace |
| `mina_run_real` | 1800×360 (300×360/frame) | yes | 6 | Mina at running pace |
| `mina_walk_cute` | 1800×360 (300×360/frame) | yes | 6 | Mina below walk cutoff |
| `mina_walk_real` | 1800×360 (300×360/frame) | yes | 6 | Mina below walk cutoff |
| `prop_school_item_cute` | 200×200 (200×200/frame) | yes | 1 | Seeded S2–S4 decoration |
| `prop_school_item_real` | 200×200 (200×200/frame) | yes | 1 | Seeded S2–S4 decoration |
| `run_bg_far_cute` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.2 |
| `run_bg_far_real` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.2 |
| `run_bg_mid_cute` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.5 |
| `run_bg_mid_real` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.5 |
| `run_bg_near_cute` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.8, butterflies |
| `run_bg_near_real` | 1920×1080 (1920×1080/frame) | yes | 1 | Parallax ×0.8, butterflies |
| `run_ground_cute` | 512×220 (512×220/frame) | yes | 1 | Tiled ground |
| `run_ground_real` | 512×220 (512×220/frame) | yes | 1 | Tiled ground |
| `safe_puddle` | 480×120 (480×120/frame) | no | 1 | Eight checkpoint/safe zones; clinic-window reflection |
| `sand_layer` | 1070×530 (1070×530/frame) | no | 1 | Brush-mask sand surface |
| `sandtray` | 1100×600 (1100×600/frame) | no | 1 | Clinic/recalibration/ending tray |
| `tex_grain` | 512×512 (512×512/frame) | no | 1 | PostFX grain |
| `tex_hatch` | 512×512 (512×512/frame) | no | 1 | Dual derivation |
| `tex_paper` | 512×512 (512×512/frame) | no | 1 | PostFX paper |
| `ui_beat_ring` | 500×500 (500×500/frame) | no | 1 | S5 downbeat call around Mina |
| `ui_lyrics_bar` | 1400×130 (1400×130/frame) | no | 1 | 1400×130 lyrics backing |
| `ui_panel` | 970×790 (970×790/frame) | no | 1 | Settings panel |
| `ui_panel_wide` | 1200×570 (1200×570/frame) | no | 1 | End screen backing |
| `ui_subtitle` | 1400×100 (1400×100/frame) | no | 1 | Therapist/ME backing |
| `ui_voice_marker` | 36×70 (36×70/frame) | no | 1 | Replaceable marker asset; ticks drawn by HUD |
| `ui_voice_meter` | 520×70 (520×70/frame) | no | 1 | 520×70 voice meter backing |

Generated by `tools/generate_resources.py`; no text is baked into textures. Backgrounds, ground, hatch/grain/paper tile. `tools/write_manifest.py` refreshes this document without changing game data or resources.

## Audio

Original synthesis, replaceable by same-name WAV then OGG. Ambience/music loop; effects are one-shot.

| Key | WAV duration | Loop |
| --- | --- | --- |
| `amb_clinic` | 9.60 s | yes |
| `amb_clock` | 2.40 s | yes |
| `amb_m1_breath` | 9.60 s | yes |
| `amb_m1_sand` | 9.60 s | yes |
| `amb_m2_light` | 9.60 s | yes |
| `mus_pad` | 9.60 s | yes |
| `mus_song` | 19.20 s | yes |
| `sfx_all_clear` | 1.20 s | no |
| `sfx_beat_call` | 0.60 s | no |
| `sfx_bloom` | 1.50 s | no |
| `sfx_blur_in` | 2.50 s | no |
| `sfx_bridge` | 2.40 s | no |
| `sfx_capture` | 1.20 s | no |
| `sfx_door` | 1.00 s | no |
| `sfx_jump` | 0.60 s | no |
| `sfx_m1_roar` | 1.20 s | no |
| `sfx_m2_crack` | 0.80 s | no |
| `sfx_m2_grab` | 1.20 s | no |
| `sfx_m2_slam` | 1.00 s | no |
| `sfx_safe` | 1.20 s | no |
| `sfx_sand` | 0.35 s | no |
| `sfx_stumble` | 1.00 s | no |

## R2.5 additions

| key | size | dual | frames | used for |
| --- | --- | --- | --- | --- |
| `m1_face_closeup` | 1920×1080 | real only | 1 | face slam at the song cut |
| `face_wall` | 360×760 | real only | 1 | face-wall obstacle (shout or ram to break) |
| `plank` | 800×140 | yes | 1 | narrow plank over a pit (don't shout) |

Audio: `mus_song` (Twinkle + changed verse + Rosie, 67.2 s, generated from `song.json`), `mus_drums`, `mus_heart`, `sfx_face_slam`, `sfx_m1_growl`, `sfx_wall_break`.
