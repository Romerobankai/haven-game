extends Node2D
# Script for every level scene (main.tscn = level 1, level_2.tscn, level_3.tscn).

@export var level_number := 1
@export var next_scene := "res://level_2.tscn"   # where the exit door leads
@export var level_name := ""

const LEVEL_COUNT := 3
const SKY_WIDTH := 1280.0      # castle_bg.png is 320 px wide, drawn at 4x
const SKY_SCROLL := 0.3        # background moves slower than the level

@onready var message: Label = $UI/Message
@onready var sky: TextureRect = get_node_or_null("Background/Sky")   # castle levels only
@onready var level: TileMapLayer = $Level
@onready var fade: ColorRect = get_node_or_null("UI/Fade")
@onready var key_icon: Node2D = get_node_or_null("UI/KeyIcon")

const FADE_TIME := 0.4
const PAN_TIME := 0.8          # camera glide to the key and back
const SHOW_KEY_TIME := 1.4     # how long the camera stays on the key

var message_tween: Tween

func _ready() -> void:
	add_to_group("game")
	fit_camera_to_level()
	show_message("Level %d of %d: %s\nReach the door at the far end!" % [level_number, LEVEL_COUNT, level_name], 3.5)
	if key_icon:
		key_icon.hide()
	# fade in from black as you come through the door
	if fade:
		fade.color.a = 1.0
		create_tween().tween_property(fade, "color:a", 0.0, FADE_TIME)

# keep the camera inside the painted tiles, so new tiles automatically extend it
func fit_camera_to_level() -> void:
	var cam: Camera2D = $Player/Camera2D
	var cell := Vector2(level.tile_set.tile_size) * level.scale
	var used := level.get_used_rect()
	cam.limit_left = int(used.position.x * cell.x)
	cam.limit_top = int(used.position.y * cell.y)
	cam.limit_right = int(used.end.x * cell.x)
	cam.limit_bottom = int(used.end.y * cell.y)

func show_message(text: String, seconds: float = 2.5) -> void:
	message.text = text
	message.show()
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(seconds)
	message_tween.tween_callback(message.hide)

# called by the door at the far end: freeze, glide the camera to where the key appears, then back
func spawn_key() -> void:
	var key = get_node_or_null("Key")
	if key == null:
		return
	var player = $Player
	var cam: Camera2D = player.get_node("Camera2D")
	player.freeze(true)
	$Enemies.process_mode = Node.PROCESS_MODE_DISABLED
	show_message("A key appeared! Grab it on your way back.", 4.0)
	var start := cam.global_position
	cam.top_level = true            # let the camera leave the ball for a moment
	cam.global_position = start
	var tween := create_tween()
	tween.tween_property(cam, "global_position", key.global_position, PAN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(key.appear)
	tween.tween_interval(SHOW_KEY_TIME)
	tween.tween_property(cam, "global_position", player.global_position, PAN_TIME * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(end_key_cutscene)

func end_key_cutscene() -> void:
	var player = $Player
	var cam: Camera2D = player.get_node("Camera2D")
	cam.top_level = false
	cam.position = Vector2.ZERO
	player.freeze(false)
	$Enemies.process_mode = Node.PROCESS_MODE_INHERIT

# called by the key when you grab it: the key icon pops up in the corner
func key_collected() -> void:
	show_message("Got the key! Big-bounce (S) up to the locked gate.", 3.5)
	if key_icon:
		key_icon.show()
		key_icon.scale = Vector2.ZERO
		create_tween().tween_property(key_icon, "scale", Vector2(3, 3), 0.4).set_delay(0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# called by the exit door: the ball goes through, the screen fades, the next room starts
func level_complete() -> void:
	if next_scene.ends_with("boss.tscn"):
		show_message("The King awaits...", 2.0)
	else:
		show_message("On to the next room...", 2.0)
	go_to_next_scene(0.5)

func go_to_next_scene(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	if fade:
		tween.tween_property(fade, "color:a", 1.0, FADE_TIME)
	tween.tween_callback(get_tree().change_scene_to_file.bind(next_scene))

func _process(_delta: float) -> void:
	# simple parallax: slide the tiled background with the camera
	var cam := get_viewport().get_camera_2d()
	if cam and sky:
		sky.position.x = -fposmod(cam.get_screen_center_position().x * SKY_SCROLL, SKY_WIDTH)

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event and key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
		get_tree().reload_current_scene()
