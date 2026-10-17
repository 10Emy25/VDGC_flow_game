# Stage 2 — Flower + Night chase (editable scene)

Open `res://scenes/flower_night.tscn` in the editor, then F6 to play directly.

The stage now contains a CharacterBody2D Mina (world-position movement),
Camera2D, background/ground tiling sprites, flower, monster Sprite2D,
CanvasLayer for match darkness and HUD.

Sequence: automatic approach -> flower hide -> monster crosses left to right
(with no colliders) -> Mina emerges -> pant + "I should be safe now..?"
-> BANG and full blackout (1 second) -> match light -> night chase.

Night controls: mic voice level = movement speed, A/D = movement direction.
Stereo roars indicate which side monster is on; monster flips sides.
Occasional monster flashes/jumpscares while running. Enter restarts on capture.

Godot engine runtime has not been tested in this environment.
