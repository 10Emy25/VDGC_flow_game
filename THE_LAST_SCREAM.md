# Flowstate — v6: original opening and first stage restored

Open this package's project.godot in Godot 4.7 and press F5. Play normally from the beginning. No shortcut is required.

## Restored from the user's original ZIP

- Original warning, calibration, bedroom movie and dream handoff.
- Original first-stage level data, song timing, rhythm/voice movement, song-ending face slam, chase sections, covers, gates and planks.
- Original decorative flowers and their positions. All artificially inserted flower landmarks are removed.
- Original late cover_locker event and its artwork. The locker is not relocated to 520m or any other early point.

The first stage's existing song-ending event can shift later encounters by an offset. The new trigger follows the actual locker event dictionary, so it remains aligned with the cabinet after that original shift. It does not assume a fixed world coordinate.

The only replaced original handoff is the old early 438m flower-night trigger. The player now continues through the original first-stage gameplay to the original late cabinet.

## New content begins only at that cabinet

When Mina approaches the cabinet, an Area2D overlap starts the film. The cabinet is already visible. Camera projection continues following until the cabinet reaches screen center, then locks. Mina hides behind it, a monster passes, she emerges and looks around, and black conceals the camera returning to follow. Stage two then begins with its existing listening guidance, directional sound and jump scares.

The final encounter retains the same map and the slower v5 sequence: sustained monster roars, Mina's automatic scream, a second blackout, player-driven light using the scream bar, a slowly typed invitation, then converging taunts and their matched replies. The daytime best-friend-message ending remains.

## Verification

- Byte comparison with the original archive confirms the original map, balance, intro data, bedroom/calibration scripts, movement/level/monster models and bedroom background are restored exactly.
- Main-view warning/calibration/bedroom entry methods match the original code.
- RunView's original song, rendering and event-handler methods match the original; only continuation observation and handoff hooks are added.
- locker_normal_play_test uses the original playthrough policy from the starting position, with no teleport or shortcut. Until cabinet activation it compares movement, status, section and event positions against an independent original LevelModel every frame. It confirms the original song/slam and all intervening sections run before the cabinet film and S2.
- last_scream_integration checks that the trigger follows the cabinet when the original song ending shifts its position, then checks camera locking, stage two and the same-map finale.

Visual pacing and real microphone/headphone playback still need a local playtest. Vocal performances remain synthesized placeholders.

Optional editor shortcuts remain N (cabinet preview), 9 (finale preview), K (keyboard voice simulation). They are not part of normal progression.
