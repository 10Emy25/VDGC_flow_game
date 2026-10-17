# Flower Night – gameplay update

## Added
- Increased microphone sensitivity. Default sensitivity now -5 dB with an additional -3 dB input-threshold offset; users with stored settings also benefit.
- Spatial trigger zone located around world X=438 in the existing RunView, ahead of the flower-cover / gaze area.
- Scripted hide-behind-flower interlude: Mina catches her breath, monster passes, moment of relief, blackout, match ignites.
- New FlowerNight playable scene with minimal match-light radius. Shouting/voice controls movement, A/D sets facing. Stereo monster roar cues report relative approach side and distance; the monster changes side roughly every 4.7 seconds.
- Too close = caught and restart via Enter; survive to reach the exit then return to the existing ending.

## Test
1. Import `project.godot` in Godot 4 and run.
2. Follow existing clinic and running sequence; after reaching about x=438 m, the flower cutscene should trigger.
3. Wear headphones for stereo positioning. Loud growls imply nearby monster, quiet imply distant. A/D changes heading (left/right).
4. To test without a microphone, press K to toggle existing keyboard mode; hold Shift/Ctrl/Space to simulate mic intensity.
5. Existing settings can override new defaults. You may recalibrate or adjust sensitivity in settings.

This is a playable blockout/interlude, not final hand-drawn cutscene art. No Godot engine runtime was available here for testing.
