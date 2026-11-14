extends Control
# "How to play": three quick comic panels shown after the story, before level 1.
# Any key or click skips the pop-in animation; the next one starts the game.

const NEXT_SCENE := "res://main.tscn"
const GOLD := Color(1, 0.84, 0.29)
const CREAM := Color(0.95, 0.93, 0.88)
const FONT := preload("res://fonts/PixelOperator8.ttf")
const BOLD := preload("res://fonts/PixelOperator8-Bold.ttf")
const BG := preload("res://sprites/castle_bg.png")
const BALL := preload("res://sprites/ball_9.png")
const BULLET := preload("res://New Piskel-1.png (1).png")
const BALL_REGION := Rect2(384, 336, 224, 208)
const BALL_SCALE := Vector2(0.1875, 0.1875)
const PANEL_SIZE := Vector2(320, 330)

var title: Label
var panels: Array[Control] = []
var footer: Label
var fade: ColorRect
var s_key: Control
var intro_tween: Tween
var shown := false
var leaving := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var bg := TextureRect.new()
	bg.texture = BG
	bg.modulate = Color(0.3, 0.3, 0.4)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	title = make_label("HOW TO PLAY", BOLD, 40, GOLD)
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0
	title.offset_bottom = 76.0

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 92.0
	row.offset_bottom = -70.0

	var move := make_panel(row, "MOVE", ["A", "D"], "or the LEFT / RIGHT\narrow keys", -2.0)
	var bounce := make_panel(row, "BIG BOUNCE!", ["S"], "Tap S right BEFORE you\nhit the ground!\n(DOWN / UP work too)", 1.5)
	var shoot := make_panel(row, "SHOOT", ["HOLD LEFT CLICK"], "Shoots wherever your\nmouse is pointing", -1.0)
	demo_move(move.get_meta("demo"))
	demo_bounce(bounce.get_meta("demo"))
	demo_shoot(shoot.get_meta("demo"))

	footer = make_label("R = restart a room          Press any key to start!", FONT, 16, CREAM)
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -52.0
	footer.offset_bottom = -24.0
	footer.modulate.a = 0.0

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_property(fade, "color:a", 0.0, 0.3)

	# comic pop-in: title, then each panel, bam bam bam
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ZERO
	for p in panels:
		p.scale = Vector2.ZERO
	intro_tween = create_tween()
	intro_tween.tween_interval(0.2)
	intro_tween.tween_property(title, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for p in panels:
		intro_tween.tween_callback(Sfx.play.bind("text"))
		intro_tween.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_callback(show_footer)

func show_footer() -> void:
	shown = true
	title.scale = Vector2.ONE
	for p in panels:
		p.scale = Vector2.ONE
	var blink := create_tween().set_loops()
	blink.tween_property(footer, "modulate:a", 1.0, 0.5)
	blink.tween_property(footer, "modulate:a", 0.3, 0.5)

func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not pressed or leaving:
		return
	get_viewport().set_input_as_handled()
	if not shown:
		intro_tween.kill()
		show_footer()
		return
	leaving = true
	Sfx.play("pickup")
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(get_tree().change_scene_to_file.bind(NEXT_SCENE))

# ---------------------------------------------------------------- building blocks

func make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# a comic panel: thick border, drop shadow, a little tilt
func make_panel(row: Control, header: String, keys: Array, caption: String, tilt: float) -> Control:
	var holder := Control.new()   # the row lays out the holder; the panel inside can tilt and pop freely
	holder.custom_minimum_size = PANEL_SIZE
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(holder)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.96)
	style.set_border_width_all(4)
	style.border_color = CREAM
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 1
	style.shadow_offset = Vector2(8, 8)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = PANEL_SIZE
	panel.pivot_offset = PANEL_SIZE / 2.0
	panel.rotation_degrees = tilt
	holder.add_child(panel)
	panels.append(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(make_label(header, BOLD, 28, GOLD))

	var keys_row := HBoxContainer.new()
	keys_row.alignment = BoxContainer.ALIGNMENT_CENTER
	keys_row.add_theme_constant_override("separation", 10)
	box.add_child(keys_row)
	for k in keys:
		var cap := make_key(k)
		keys_row.add_child(cap)
		if k == "S":
			s_key = cap

	box.add_child(make_label(caption, FONT, 16, CREAM))
	var area := Control.new()
	area.custom_minimum_size = Vector2(290, 130)
	area.clip_contents = true
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(area)
	holder.set_meta("demo", area)
	return holder

# a keyboard key drawn as a light box with a dark letter
func make_key(text: String) -> Control:
	var cap := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.set_border_width_all(3)
	style.border_color = Color(0.25, 0.22, 0.2)
	style.set_content_margin_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	cap.add_theme_stylebox_override("panel", style)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", BOLD)
	label.add_theme_font_size_override("font_size", 24 if text.length() <= 2 else 16)
	label.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(label)
	return cap

func make_ball(pos: Vector2) -> Sprite2D:
	var ball := Sprite2D.new()
	ball.texture = BALL
	ball.region_enabled = true
	ball.region_rect = BALL_REGION
	ball.scale = BALL_SCALE
	ball.position = pos
	return ball

# ---------------------------------------------------------------- little looping demos

func demo_move(area: Control) -> void:
	var ball := make_ball(Vector2(145, 70))
	area.add_child(ball)
	var t := create_tween().set_loops()
	t.tween_property(ball, "position:x", 245.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ball, "position:x", 45.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ball, "position:x", 145.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func demo_bounce(area: Control) -> void:
	var ground := ColorRect.new()
	ground.color = CREAM
	ground.position = Vector2(35, 122)
	ground.size = Vector2(220, 3)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(ground)
	var ball := make_ball(Vector2(110, 101))
	area.add_child(ball)
	var boing := make_label("BOING!", BOLD, 24, GOLD)
	area.add_child(boing)
	boing.position = Vector2(150, 30)
	boing.size = Vector2(130, 34)
	boing.pivot_offset = boing.size / 2.0
	boing.rotation_degrees = -8.0
	boing.scale = Vector2.ZERO
	var t := create_tween().set_loops()
	# two small bounces...
	for i in 2:
		t.tween_property(ball, "position:y", 62.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if i == 1:
			t.tween_callback(press_s)   # ...tap S on the way down...
		t.tween_property(ball, "position:y", 101.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# ...and BOING!
	t.tween_property(ball, "position:y", 6.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(boing, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(ball, "position:y", 101.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(boing, "scale", Vector2.ZERO, 0.2).set_delay(0.25)
	t.tween_interval(0.3)

func press_s() -> void:
	if s_key == null:
		return
	s_key.modulate = Color(2.2, 1.7, 0.5)
	create_tween().tween_property(s_key, "modulate", Color.WHITE, 0.45)

func demo_shoot(area: Control) -> void:
	area.add_child(make_ball(Vector2(55, 70)))
	var t := create_tween().set_loops()
	t.tween_callback(fire.bind(area))
	t.tween_interval(0.3)

func fire(area: Control) -> void:
	var bullet := Sprite2D.new()
	bullet.texture = BULLET
	bullet.scale = Vector2(0.75, 0.75)
	bullet.offset = Vector2(1.5, 3.5)
	bullet.position = Vector2(85, 70)
	area.add_child(bullet)
	var t := bullet.create_tween()
	t.tween_property(bullet, "position:x", 300.0, 0.45)
	t.tween_callback(bullet.queue_free)
