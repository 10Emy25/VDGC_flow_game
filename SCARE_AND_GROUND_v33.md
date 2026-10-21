# v33: scare audio and monster grounding

All former sfx_face_slam playback sites now use the exact sfx_title_laugh recording used on the horror title screen. The second-stage visual jump scare plays only that laugh, at normal pitch, panned toward its side; directional chase roar cues remain unchanged. The locker blackout starts the laugh; handover into NightContinuation no longer triggers a duplicate sound 0.65 seconds later. Settings remain free of laughter.

The monster chase and cabinet pass now use the collage foreground ground line at y=1000, rather than Mina's more distant path at y=860. Their rendering compensates the common 17-pixel transparent bottom margin. Monster size, horizontal chase gap, speed, triggers and camera path remain unchanged. The lower grounding is retained throughout the left-pan reveal and return.
