# Flowstate — v7: flower-sticker nightmare ending

Open project.godot in Godot 4.7 and play normally. The original opening and first-stage map/logic restored in v6 remain unchanged. The existing late-cabinet transition, listening chase and voice confrontation remain intact.

## New final story

After the confrontation's whiteout:

1. Mina wakes with a start in daylight, exhales, and says “It is just a dream..”.
2. The phone rings. She reaches for it and picks it up.
3. Her best friend sends “Mina...I am really worried”, followed by “pls call me”.
4. The player must choose OK or ... . There is no timeout or automatic choice.
5. OK sends the message “OK”. Choosing ... sends nothing. In either case, the friend sends a cute flower sticker one second later.
6. The sticker remains friendly and small for three seconds. It then escapes the phone frame and slowly grows to fill the screen over ten seconds. Its cartoon face gradually stretches into a pale, hollow ghost face as the room darkens and dissonant horror music rises.
7. The ghost face holds briefly, then cuts to black. Play again returns to the original calibration/opening flow after explicit player input.

No external messages or calls are sent; this is in-game fictional dialogue.

## Implementation

- dream_message_ending.gd owns the wake-up sequence, timed messages, real button branches, sticker movement and final fade.
- flower_sticker.gd draws a vector flower whose face morphs continuously. No duplicate character or full sprite-strip display is used.
- last_scream.gd hands the whiteout to the new ending; the original battle preceding it is preserved.
- mus_flower_nightmare.wav is an original procedural dissonant drone. The spoken dream line uses a synthesized placeholder voice.
- The existing Reduce Scares option suppresses the slight final face tremble.

## Verification

- dream_message_ending_test exercises both real button handlers, rejects a second selection, proves the choice cannot auto-advance, checks the one-second sticker delay, friendly hold, gradual scale/morph and replay signal.
- last_scream_test verifies the confrontation still flows into the new wake-up sequence.
- last_scream_integration verifies the late cabinet, camera sequence, second stage and same-map finale remain connected.
- Core restored opening/first-stage files were byte-compared to the delivered v6 ZIP and remain unchanged.

Graphical timing and audio mix still require a local editor playtest. The new ending has not been pushed to GitHub as part of this local edit.
