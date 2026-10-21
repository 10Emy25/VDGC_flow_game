# Open eye: one blink, then scanning

Original PNG artwork is preserved; each frame uses the same crop and scale as the opening/closing animation.

Blink: 20 fps. Files 1–4 close the eye, so playback is 1,2,3,4,3,2 and then the open scanning frame. File 1 is held for the annotated total of 3 frames (0.15s); each other appearance lasts 1 frame (0.05s). The complete blink takes 0.4s and plays once per gaze.

Scanning: 10 fps; frames 1–9 and then 8–2 loop until the game starts closing the eye. Hold counts, read from the source filenames: 4,1,9,2,1,1,1,1,6. Thus frames 1/3/4/9 last 0.4/0.9/0.2/0.6 seconds; other frames last 0.1s. The forward pass takes 2.6s. The reverse pass retains the same per-frame holds; one full round trip takes 4.2s.

The new gaze sequence replaces the former open-eye vibration loop. Gameplay phase timing remains unchanged. The beam stays off during the blink. Its origin follows the pupil in the aligned artwork, and its landing position and actual sight detection share the same scan sample. Closing interrupts the gaze sequence immediately and uses the existing reverse opening frames. Game time drives playback, so pausing freezes it.
