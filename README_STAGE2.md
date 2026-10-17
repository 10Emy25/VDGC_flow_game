# Stage 2 editor-visible scene

Open `scenes/flower_night.tscn` in Godot's 2D editor. The forest layers,
MinaCrouch, MinaRun, giant Flower, MonsterSilhouette, MatchLight, MatchFlame,
HUD, and Caption are now real, editable scene nodes.

`Main.show_flower_night()` instantiates this scene after the flower event,
not the previous code-generated control.

For testing, open `scenes/flower_night.tscn` and run Current Scene (F6).
The hide -> pass -> relief -> match -> night sequence runs automatically.

NOTE: Godot itself isn't installed in the creation environment, so engine
import/parsing and gameplay have not been runtime-validated.
