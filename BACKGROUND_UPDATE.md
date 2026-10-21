# v11 — Supplied bright/nightmare scene artwork

The supplied 场景.png is preserved unchanged as art/scenes_collage.png. Two native Godot AtlasTexture resources extract the panels directly, without redrawing or re-generating the artwork:

- scene_day.tres: Rect2(120, 118, 1434, 1002), the bright upper panel.
- scene_night.tres: Rect2(116, 1276, 1433, 1001), the red nightmare lower panel.

The outer white page margins, the white divider between panels and the antialiased outer edges are excluded. The pale sky/lace inside the upper artwork is intentionally preserved.

SceneBackdrop fits each complete crop to the game viewport without letterboxing. Alternating mirrored tiles reuse the current far-background scroll rate and align their shared edge pixels. The old forest parallax overlays and ground-strip artwork are removed so they cannot obscure the supplied composition. Gameplay floor positions, props, actors, obstacles and camera calculations remain unchanged.

The bright panel remains throughout the opening Twinkle song, regardless of the old lyric-color flashes. The actual monster/face-slam reveal switches to the red panel. The listening chase and final confrontation keep those same background nodes rather than switching to another map. The daytime bedroom phone ending is separate and remains unchanged.

Tests: scene_backdrop_test checks exact crop regions, shared original texture, full viewport fill, bright opening, red monster reveal and continuity into the listening chase. Full-song, cabinet/finale and phone-ending tests remain passing.

The complete opening song, supplied chase track, original first-stage progression and latest phone/flower ending are retained.
