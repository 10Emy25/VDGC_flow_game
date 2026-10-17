# Stage 2 fixes

- All six Mina running frames are separate 300x360 PNGs in art/mina_run_frame_0.png … _5.png. Runtime selects a different image every 1/11 second instead of treating SVG atlas as one character.
- Monster roar/growl now play from AudioStreamPlayer2D nodes parented to World. Their global position follows Mina in world space, with left/right offsets relative to Mina. Recycled backgrounds are visual only and never change Mina or monster audio coordinates.
- Listen with stereo headphones.
- Open scenes/flower_night.tscn and press F6.
- Engine runtime test has not been performed.
