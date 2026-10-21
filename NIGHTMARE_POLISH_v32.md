# Nightmare polish v32

- Dream Mina now uses a fixed 11 fps run cadence at all movement speeds. Movement/input balance is unchanged. Main dream sprite is 240×288 (20% smaller).
- Chase monster is 1140×1370 (roughly 27% larger), grounded with the same logical chase gap. Locker pass and finale monsters are also enlarged, while finale/legacy Mina is smaller.
- At the initial song-to-nightmare transition, camera pans left in 0.45s, holds the writhing monster for 1.1s and pans back in 0.55s. Mina and monster world positions and gameplay timers freeze during this 2.1s cinematic; monster animation continues. One shared camera offset projects scenery, props, Mina and monster. Occlusion stays enabled and follows the reveal. Gameplay resumes with the time held during the cinematic excluded from its clock.
- Eye scan: 20 fps one-time blink, 10 fps forward/reverse scan, retaining all authored holds. Beam turns off during blink; cone starts at pupil and lands at the same position used by sight detection. See EYE_TIMING_v31.md for hold durations.

Validation: headless fixed-cadence/camera/beam regression, eye frame boundary tests, Mina animation tests, director hearing/sight tests, existing cabinet-to-night/finale integration, and replay/settings/quiet-input regressions.
