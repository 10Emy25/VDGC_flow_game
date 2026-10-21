class_name FlowerNight
extends Control

signal night_finished

# This stage uses world coordinates. Mina is a CharacterBody2D and Camera2D follows her.
# Editable world nodes live in scenes/flower_night.tscn.
const VIEW_W: float = 1920.0
const FLOWER_X: float = 1120.0
const FEET_Y: float = 730.0
const RUN_SPEED: float = 530.0
const ESCAPE_DISTANCE: float = 20000.0
const MIN_NIGHT_SECONDS: float = 85.0
const RUN_FRAME_RATE: float = 11.0

@onready var world: Node2D = $World
@onready var mina: CharacterBody2D = $World/Mina
@onready var sprite: Sprite2D = $World/Mina/RunSprite
@onready var camera: Camera2D = $World/Mina/Camera2D
@onready var flower: Sprite2D = $World/Flower
@onready var monster: Sprite2D = $World/Monster
@onready var darkness: ColorRect = $NightOverlay/Darkness
@onready var flame: ColorRect = $NightOverlay/Flame
@onready var blackout: ColorRect = $NightOverlay/Blackout
@onready var caption: Label = $HUD/Caption
@onready var info: Label = $HUD/Info
@onready var backdrop: ColorRect = $HUD/DialogueBox

var phase: String = "approach"
var clock: float = 0.0
var travel: float = 0.0
var night_elapsed: float = 0.0
var run_animation_time: float = 0.0
var background_tiles: Array[Sprite2D] = []
var ground_tiles: Array[Sprite2D] = []
var facing: int = 1
var monster_side: int = -1
var danger: float = 0.22
var switch_clock: float = 0.0
var next_side_switch: float = 14.0
var side_change_age: float = 0.0
var next_roar_time: float = 2.4
var roar_clock: float = 0.0
var jump_clock: float = 0.0
var jump_left: float = 0.0
var air_left: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
# Eight individually supplied PNG frames, loaded without sprite-sheet slicing.
var run_frames: Array[Texture2D] = []
var roar_player: AudioStreamPlayer
var growl_player: AudioStreamPlayer
var crouch_tex: Texture2D

func _ready() -> void:
    run_frames = MinaAnimation.run_frames()
    crouch_tex = MinaAnimation.idle_frames()[0]
    rng.randomize()
    theme = GameState.ui_theme
    Sfx.stop_all()
    camera.enabled = true
    camera.make_current()
    camera.global_position = Vector2(960.0, 540.0)
    camera.position_smoothing_enabled = false
    mina.global_position = Vector2(100.0, FEET_Y - 90.0)
    sprite.hframes = 1
    sprite.vframes = 1
    sprite.frame = 0
    sprite.texture = MinaAnimation.idle_frames()[0]
    sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
    # Dedicated stereo buses: left and right are unambiguous even with camera scrolling.
    setup_monster_stereo_buses()
    roar_player = create_monster_audio("sfx_m1_roar")
    growl_player = create_monster_audio("sfx_m1_growl")
    reset_monster_rhythm()
    for child in world.get_children():
        if child is Sprite2D:
            var tile: Sprite2D = child as Sprite2D
            if tile.name.begins_with("Forest"):
                background_tiles.append(tile)
            elif tile.name.begins_with("Ground"):
                ground_tiles.append(tile)
    monster.texture = MonsterAnimation.at_time(0)
    monster.scale = Vector2.ONE * 0.59
    monster.visible = false
    # Monster is only a visual Sprite2D during the cutscene: it has no collision shape.
    darkness.visible = false
    blackout.visible = false
    flame.visible = false
    backdrop.visible = false
    info.text = "RUN TO THE FLOWER"
    caption.text = ""

func _process(delta: float) -> void:
    clock += delta
    if monster.visible: monster.texture = MonsterAnimation.at_time(clock, GameState.balance.level_view.m1_fps)
    if phase == "approach":
        # Automatically bring Mina to the flower in this editable scene.
        move_mina(RUN_SPEED, delta)
        animate_feet(delta)
        camera.global_position.x = maxf(960.0, mina.global_position.x)
        if mina.global_position.x >= FLOWER_X - 90.0:
            set_phase("hide")
            camera.global_position.x = 960.0
    elif phase == "hide":
        camera.global_position = Vector2(960.0, 540.0)
        sprite.texture = crouch_tex
        sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
        sprite.hframes = 1
        sprite.frame = 0
        sprite.rotation = 0.0
        mina.global_position = mina.global_position.move_toward(Vector2(FLOWER_X - 65.0, FEET_Y - 90.0), delta * 340.0)
        caption.text = "(panting...)"
        backdrop.visible = true
        if clock >= 2.0:
            set_phase("monster_pass")
    elif phase == "monster_pass":
        # A visual monster crosses from left to right; no physics/collision this whole scene.
        monster.visible = true
        monster.global_position = Vector2(lerpf(-300.0, 2250.0, minf(clock / 3.2, 1.0)), 510.0)
        sprite.texture = crouch_tex
        sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
        sprite.hframes = 1
        sprite.frame = 0
        caption.text = ""
        if clock >= 3.3:
            monster.visible = false
            set_phase("emerge")
    elif phase == "emerge":
        sprite.texture = MinaAnimation.idle_frames()[0]
        sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
        mina.global_position = mina.global_position.move_toward(Vector2(FLOWER_X + 195.0, FEET_Y - 90.0), delta * 210.0)
        sprite.rotation = 0.0
        caption.text = "(huff... huff...)"
        if clock >= 2.4:
            set_phase("dialogue")
    elif phase == "dialogue":
        caption.text = "I should be safe now..?"
        if clock >= 2.0:
            set_phase("bang")
    elif phase == "bang":
        caption.text = "BANG!"
        darkness.visible = true
        blackout.visible = true
        flame.visible = false
        if clock >= 1.0:
            set_phase("match")
    elif phase == "match":
        caption.text = "...A match. I need light."
        blackout.visible = false
        flame.visible = true
        darkness.color = Color.WHITE
        if clock >= 1.2:
            set_phase("night")
            camera.position = Vector2(0.0, -100.0)
            camera.position_smoothing_enabled = true
            camera.position_smoothing_speed = 5.0
            Sfx.loop("amb_clock", true, -24.0)
    elif phase == "night":
        update_night(delta)
    elif phase == "caught":
        caption.text = "IT FOUND YOU.   PRESS ENTER TO TRY AGAIN."
    elif phase == "won":
        caption.text = "YOU MADE IT."
        if clock >= 2.5:
            Sfx.stop_all()
            night_finished.emit()
    update_infinite_map()
    if phase == "night":
        # HUD is screen-space, the camera follows actual Mina world position.
        flame.position = Vector2(1050.0 if facing > 0 else 850.0, 475.0 + sin(clock * 12.0) * 4.0)
    queue_redraw()

func set_phase(next_phase: String) -> void:
    phase = next_phase
    clock = 0.0
    if phase == "monster_pass":
        monster.visible = true
        play_monster_sound(roar_player, -2.0, 0.85)
    elif phase == "bang":
        Sfx.play("sfx_beat_call", -1.0)
    elif phase == "night":
        night_elapsed = 0.0
        caption.text = "SCREAM = SPEED    A / D = DIRECTION    LISTEN!"
        backdrop.visible = false
        info.text = "ESCAPE THE DARK"
        camera.position_smoothing_enabled = true
    elif phase == "caught":
        Sfx.play("sfx_capture", 0.0)

func move_mina(speed: float, delta: float) -> void:
    mina.velocity = Vector2(speed, 0.0)
    mina.move_and_slide()

func animate_feet(delta: float) -> void:
    # Keep the supplied frames whole and use the same display scale for all eight.
    sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
    sprite.hframes = 1
    sprite.vframes = 1
    run_animation_time += delta
    sprite.texture = run_frames[int(run_animation_time * RUN_FRAME_RATE) % run_frames.size()]
    sprite.frame = 0
    sprite.position.y = 0.0
    sprite.rotation = 0.0

func setup_monster_stereo_buses() -> void:
    # AudioEffectPanner ensures strong directional sound on headphones.
    for side_name in ["MonsterLeft", "MonsterRight"]:
        if AudioServer.get_bus_index(side_name) >= 0:
            continue
        var bus_index: int = AudioServer.bus_count
        AudioServer.add_bus(bus_index)
        AudioServer.set_bus_name(bus_index, side_name)
        AudioServer.set_bus_send(bus_index, "Master")
        var panner: AudioEffectPanner = AudioEffectPanner.new()
        panner.pan = -0.95 if side_name == "MonsterLeft" else 0.95
        AudioServer.add_bus_effect(bus_index, panner)

func create_monster_audio(key: String) -> AudioStreamPlayer:
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.name = "MonsterStereo_" + key
    player.stream = Sfx.get_stream(key)
    player.bus = "MonsterLeft"
    add_child(player)
    return player

func reset_monster_rhythm() -> void:
    switch_clock = 0.0
    side_change_age = 0.0
    roar_clock = 0.0
    next_side_switch = rng.randf_range(12.0, 18.0)
    next_roar_time = 2.6

func update_monster_audio_positions() -> void:
    # Stereo is controlled by buses, NOT sprite/camera coordinates.
    # Keep this function for compatibility with the rest of the stage.
    pass

func play_monster_sound(player: AudioStreamPlayer, volume_db: float, pitch: float) -> void:
    if not is_instance_valid(player) or player.stream == null:
        return
    if player == roar_player:
        player.stream = Sfx.next_monster_roar()
    elif is_instance_valid(roar_player):
        roar_player.stop()
    player.bus = "MonsterLeft" if monster_side < 0 else "MonsterRight"
    player.volume_db = volume_db
    player.pitch_scale = pitch
    player.play()

func update_infinite_map() -> void:
    # Recycle tiles around camera / Mina; works in either direction indefinitely.
    var center_x: float = mina.global_position.x
    if phase != "night" and phase != "caught" and phase != "won":
        center_x = 960.0
    # Each far/mid image is 1920px wide. Reuse *all* existing tiles.
    var far_tiles: Array[Sprite2D] = []
    var mid_tiles: Array[Sprite2D] = []
    for tile in background_tiles:
        if tile.name.begins_with("ForestFar"):
            far_tiles.append(tile)
        elif tile.name.begins_with("ForestMid"):
            mid_tiles.append(tile)
    # One tile behind + one ahead is enough; extra tiles are placed further away.
    # Using the same offset for far and mid prevents gaps.
    var first_index: int = int(floor((center_x - 1920.0) / 1920.0))
    for i in range(far_tiles.size()):
        far_tiles[i].position = Vector2(float(first_index + i) * 1920.0, 0.0)
    for i in range(mid_tiles.size()):
        mid_tiles[i].position = Vector2(float(first_index + i) * 1920.0, 0.0)
    var first_ground: int = int(floor((center_x - 1024.0) / 512.0))
    for i in range(ground_tiles.size()):
        ground_tiles[i].position = Vector2(float(first_ground + i) * 512.0, 670.0)

func update_night(delta: float) -> void:
    night_elapsed += delta
    var vocal: float = clampf(VoiceInput.level01 * 1.7, 0.0, 1.0)
    var movement: float = 0.0
    if VoiceInput.is_audible or vocal > 0.035:
        movement = 125.0 + 680.0 * vocal
    mina.velocity = Vector2(float(facing) * movement, 0.0)
    mina.move_and_slide()
    sprite.flip_h = facing < 0
    if movement > 15.0:
        animate_feet(delta)
    else:
        sprite.texture = MinaAnimation.idle_frames()[0]
        sprite.scale = Vector2.ONE * (216.0 / MinaAnimation.RUN_REGION.size.y)
        sprite.hframes = 1
        sprite.frame = 0
        sprite.position.y = lerpf(sprite.position.y, 0.0, 0.2)
        sprite.rotation = lerpf(sprite.rotation, 0.0, 0.2)
    # Audio sources must use the exact same world-space origin as Mina.
    update_monster_audio_positions()
    travel += movement * delta
    var correct: bool = facing != monster_side
    if movement > 0.0:
        danger += delta * (-0.085 if correct else 0.12) * (0.5 + vocal)
    danger += 0.035 * delta
    danger = clampf(danger, 0.0, 1.0)
    switch_clock += delta
    side_change_age += delta
    roar_clock += delta
    jump_clock += delta
    # Choose the next interval ONCE per switch, not every frame.
    if switch_clock >= next_side_switch:
        switch_clock = 0.0
        side_change_age = 0.0
        next_side_switch = rng.randf_range(12.0, 18.0)
        # Most surprises come from the direction Mina is currently fleeing toward.
        monster_side = facing if rng.randf() < 0.78 else -facing
        # First sound on the new side is distant. It gets louder over a few seconds.
        roar_clock = 0.0
        next_roar_time = 0.6
        play_monster_sound(growl_player, -20.0, 0.86)
    if roar_clock >= next_roar_time:
        roar_clock = 0.0
        next_roar_time = rng.randf_range(2.1, 3.1)
        var approach: float = clampf(side_change_age / 4.0, 0.0, 1.0)
        # Distance and urgency conveyed by loudness; never swap channels mid-roar.
        var roar_db: float = -22.0 + 15.0 * approach + 8.0 * danger
        play_monster_sound(roar_player, roar_db, 0.92 + 0.13 * danger)
    if jump_clock > 7.0:
        jump_clock = 0.0
        if rng.randf() < 0.7:
            jump_left = 0.25
            play_monster_sound(growl_player, 2.0, 1.1)
    jump_left = maxf(0.0, jump_left - delta)
    monster.visible = jump_left > 0.0
    if monster.visible:
        monster.global_position = mina.global_position + Vector2(float(monster_side) * 460.0, -65.0)
    var progress: float = minf(minf(travel / ESCAPE_DISTANCE, night_elapsed / MIN_NIGHT_SECONDS), 1.0)
    info.text = "ESCAPE %d%%    DANGER %d%%    TIME %ds" % [int(progress * 100.0), int(danger * 100.0), int(night_elapsed)]
    caption.text = "SCREAM to run / A-D to turn / LISTEN for the roar!"
    if danger >= 1.0:
        set_phase("caught")
    elif travel >= ESCAPE_DISTANCE and night_elapsed >= MIN_NIGHT_SECONDS:
        set_phase("won")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo:
        return
    if phase == "night":
        if key.physical_keycode == KEY_A:
            facing = -1
        elif key.physical_keycode == KEY_D:
            facing = 1
    elif phase == "caught" and key.physical_keycode == KEY_ENTER:
        mina.global_position = Vector2(FLOWER_X + 195.0, FEET_Y - 90.0)
        travel = 0.0
        night_elapsed = 0.0
        danger = 0.22
        facing = 1
        monster_side = -1
        reset_monster_rhythm()
        set_phase("night")
