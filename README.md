# Mina: Scream

用声音控制奔跑的恐怖小游戏（Godot 4.7，主题 flow state）。

## 团队快速开始

1. 安装 **Godot 4.7.2**（标准版，不要选 .NET 版）：https://godotengine.org/download
2. 用 GitHub Desktop 克隆本仓库，打开 Godot，点 **Import**，选仓库里的 `project.godot`。
3. 等右下角导入完成，按 **F5** 运行。第一次运行时 Mac 会询问麦克风权限，点允许。

**操作**：对着麦克风发声，越大声跑得越快。按 **K** 切换键盘模式：Shift 是哼歌，Ctrl 是说话，Space 是尖叫。

**开场流程**：标题 → 麦克风校准 → S0 卧室（旁白、手抖、吃药、闭眼）→ 一闪一闪亮晶晶八音盒前奏 → 从模糊到清晰进入 S1 花之路。旁白可以点击或按空格加速。

**测试者模式**（只在编辑器里按 F5 时生效）：

| 按键 | 作用 |
| --- | --- |
| 1–5 | 跳到 S1–S5 |
| 6 | 下一个存档点 |
| 7 | 无敌开/关 |
| 8 | 跳过儿歌 |
| 0 | 隐藏提示条 |

删除 `scripts/dev/` 文件夹即可整个移除测试者模式。

## 谁改哪里（避免冲突）

| 想改的东西 | 改这里 | 要动代码吗 |
| --- | --- | --- |
| 美术 | 把同名 PNG 放进 `art/`，尺寸随意。所有 key 见 `ART_MANIFEST.md` | 不用 |
| 音效、音乐 | 把同名 WAV 放进 `audio/` | 不用 |
| 文字、对白 | `data/dialogue.json` | 不用 |
| 数值（怪物速度、跳跃门槛等） | `data/balance.json` | 不用 |
| 关卡布局（障碍、眼睛、存档点位置） | `data/level.json` | 不用 |
| 儿歌歌词 | `data/song.json` | 不用 |
| 开场卧室动画（动作顺序、停留时间、旁白、特写） | `data/intro.json`（旁白文字在 `data/dialogue.json` 的 `intro_*`） | 不用 |

**规则**：开始干活前先 **Pull**；改完马上 **Commit + Push**，提交说明写清楚改了什么；同一个 `.json` 或 `.tscn` 文件不要两个人同时改。

设计和改动记录见 `NOTES.md`。最初的完整需求见 `SCREAM_SPEC.md`，其中一部分已被 `NOTES.md` 里的 R2.5 之后的改动取代。

---

## 开发说明（R1/R2 原文）

> **R2.7:** the sand-tray clinic opening was replaced by a bedroom opening (calibration screen → S0 bedroom → dream → S1). See `NOTES.md` § R2.7. The text below describes R1/R2 as they were built.

A Godot 4.4+ / GDScript / Compatibility project. R1’s warning, clinic, voice input, and flower path now lead into the full S2–S5 level, both monsters, hiding, checkpoints/respawn, speed gates, beat surges, clinic ending, and End of Chapter/Restart. Face slam, scripted scares, the world art switch, layered music, F1 debug tools, flow meter, and scream budget remain R3 work.

## Run

Open `project.godot` in Godot and press F6 on `scenes/main.tscn`, or F5. On this machine:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

First run in the editor triggers the microphone permission prompt. If denied, enable Godot in **System Settings → Privacy & Security → Microphone**. macOS exports must enable the microphone entitlement and fill **Privacy → Microphone Usage Description**; export has not been tested in R1.

Click Begin. Sample silence, say hi, and make one comfortable call. A weak call is repeated once; guards ensure useful thresholds. `Use defaults` skips sampling. Saved calibration loads on boot; every new clinic visit still calibrates as part of the story. Brush the raised patch in the middle of the sand until the running doll emerges.

Press **K** at any time for keyboard mode. In the clinic, press and release **Space** three times to use default calibration. On the path hold **Shift** to hum, **Ctrl** to talk, or **Space** to shout. Space takes priority, then Ctrl, then Shift. Release everything to coast. The tutorial advances cumulatively and has a minimum display duration. Sing at TALK for one cumulative bar at the bridge to lift it.

SETTINGS stays available on every screen and pauses the scene and music. Recalibration runs inside the paused settings overlay. Settings save to `user://settings.cfg`; calibration saves separately to `user://voice_calibration.cfg`. Negative sensitivity makes movement easier. The distortion toggle controls §3 shaders. Reduce scare intensity lowers the hearing-warning slam by 12 dB and disables its shake. Other scripted scares are deferred to R3.

## Checks

```sh
python3 tools/run_tests.py
```

This uses the specified Godot executable, imports with `--headless --editor --import`, then runs `voice_test`, `run_model_test`, `r1_scene_test`, and `art_registry_test` using `--headless --scene`. It exits on engine errors, failed assertions, or timeouts, and smoke-tests the main scene. R2 adds `monster_director_test`, `level_model_test`, `playthrough` (eight distinct rhythm phases), and `r2_scene_test` (real logical/physical keyboard events and scene transitions). Set `GODOT` to another executable if needed. Tests preserve and restore existing settings/calibration files. The runner creates and removes two temporary art fixtures to verify PNG priority, strip frames, fixed slots, and deriving a missing dual version. The Dummy audio driver uses silent capture and the clock's timer fallback; hardware capture and audible playback require manual testing.

A render-capable R1 tour (no microphone/audio hardware required) captures warning, calibration, sand brushing, trance, S1, settings, karaoke, bridge, core real visuals, reduced distortion, and the milestone screen:

```sh
TOUR_DIR=/tmp/mina-r1-tour /Applications/Godot.app/Contents/MacOS/Godot --path . --audio-driver Dummy --scene res://tests/r1_tour.tscn
```

Without `TOUR_DIR`, images go to `user://tour/`. This is a scoped R1 tour, not the full §15 R3 tour.

## R2 level controls

Mina continues beyond 220 m. Alternate a short shout with quiet coasting. At **FIND COVER**, release your voice early enough to coast into the large flower, desk, or locker. Hiding is automatic inside ±0.8 m of the object once speed falls below 0.5 m/s. Stay silent during the eye’s gaze: hidden players are still heard. First sound gives a warning slam; another quarter-second of sound after the one-second slam captures. An exposed Mina can also be caught by the moving beam.

Safe puddles save a checkpoint and freeze the wall; after leaving, it waits six seconds. Capture holds for 1.2 s, fades for 0.5 s, and respawns with three seconds of invulnerability. Gates auto-jump at ≥6 m/s; otherwise Mina stumbles and automatically climbs across. In S5 the eye closes for good and the wall cannot catch. Begin a shout −0.3..+0.6 s around each ring/call to surge. Four hits finish; normal movement can also reach the light door. The ending holds the therapist’s line for two seconds and Mina’s ME line for three, then Restart returns to calibration.

Rendered R2 tour:

```sh
TOUR_DIR=/tmp/mina-r2-tour /Applications/Godot.app/Contents/MacOS/Godot --path . --audio-driver Dummy --scene res://tests/r2_tour.tscn
```

It captures 16 views: chase, hidden gaze/Recede, warning slam, capture/fade/respawn, jump/stumble, safe zone, Warning, finale, white flash, both ending lines, and end screen. This uses test-only fixture placement, not a shipped checkpoint-jump/debug UI. See `NOTES.md` for the chase-tuning and Tell-timing conflicts in the spec.

## Edit and replace

- `data/balance.json`: voice thresholds/defaults, filtering, movement, throat guard, tutorial timing, settings defaults, fixed display slots, and strip frame counts. Original future-milestone balance values are retained as inert data.
- `data/level.json`: the full specified ordered S1–S5 event list, including all checkpoint/cover/gate/gaze positions and the door. R3 scare events are present but not played yet.
- `data/song.json`: syllables, durations, notes, and optional `word_ends` indices to join multi-syllable words. Regenerate `mus_song.wav` after editing it.
- `data/dialogue.json`: all shipped player-facing strings and both font paths.
- Drop a same-key PNG into `art/`, reimport/restart, and it takes priority over SVG. Every slot keeps its fixed rectangle, preserves aspect, and centers the texture. Animation files are horizontal strips; set the base key's count in `art_frames`. Cute/real keys end in `_cute` / `_real`. A missing counterpart uses the derive shader.
- Replace `audio/<key>.wav` or `.ogg` (WAV takes priority). `amb_*` / `mus_*` loop. Missing audio is silent with one warning per key. Keep song audio duration aligned with its data. §3 Sfx pan/fade APIs are available for later scenes.
- Add `fonts/system.ttf` and `fonts/therapist.ttf`, or edit the paths. Missing fonts use the engine default. No fonts or third-party assets are downloaded.

`python3 tools/generate_resources.py` fills missing R1/R2 placeholders. `--refresh-placeholders` regenerates SVGs/WAVs; it never modifies data, overwrites a PNG, or replaces an SVG whose key has a PNG. Back up hand-edited SVG/WAV assets before requesting a refresh.

See `ART_MANIFEST.md` for shipped slots and `NOTES.md` for decisions, verification, and manual checks.
