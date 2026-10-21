# v12 — Illustrated OVERFLOW title menu

The supplied 开场1.png is displayed intact as the game's first screen, scaled to the viewport. Transparent interactive regions are aligned over the text already drawn into the artwork; no duplicate labels or new illustrated buttons are added.

- New: stops the menu music and opens the original content-warning screen, then the existing Begin → calibration → bedroom → game sequence.
- Setting: opens the existing settings panel. Closing it returns to the same title screen. Menu music continues while settings are open.
- Quit: closes the game.
- Speaker icon: mutes/unmutes the menu music without changing its playback position.

The supplied 比较梦核.m4a is locally decoded to audio/mus_title.wav for Godot compatibility. It loops on the menu at a low volume. No replacement track or generated music is used. The original M4A is not modified.

The title artwork is preserved byte for byte as art/title_menu.png. All visible illustrated regions remain on screen. Hit areas track the same proportional scaling as the image; pointer hover, keyboard focus and Enter activation are supported.

Global debug text, microphone warnings and the old corner settings button are hidden on this title screen. The in-game settings shortcut remains available during normal play.

Checks: title_menu_test verifies initial view, art hit regions, menu audio duration, New routing, settings pause/close, audio mute and Quit signal. Opening-song, scene-background and phone-ending checks remain passing.

The full opening song, supplied chase track, split bright/horror scene artwork, original first-stage gameplay and flower-sticker nightmare ending from previous versions remain included.
