# Stage 2 monster sound tuning

- Change-side interval: 12–18 seconds; rolled once after each switch.
- New monster direction is the player’s current running direction 78% of the time.
- Left and right are sent through distinct audio buses with panning values -0.95 / +0.95, independent of map scrolling and camera position.
- Monster growls faintly immediately after a change; roars strengthen over 4 seconds.
- Roars repeat every 2.1–3.1 seconds. Jumpscare logic is unchanged.
- Headphones strongly recommended. Sound panning works for stereo audio output.

Editable constants are in scripts/view/flower_night.gd. This build was not tested in Godot.
