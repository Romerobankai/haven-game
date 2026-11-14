extends "res://intro.gd"
# The ending screen: the same typewriter as the intro, with different words,
# then a big "Thank you, Hack Club!" pops in.

const ENDING := "The King is defeated.\n\n" \
	+ "The curse fades... your arms and legs come back...\n" \
	+ "...and you are human again.\n\n" \
	+ "You really did\n" \
	+ "[b][color=#ffd54a]bounce back[/color][/b]."

const THANKS := "Thank you, Hack Club!"
const HACK_CLUB_RED := Color("ec3750")

var thanks: Label
var thanked := false

func _init() -> void:
	story_text = ENDING
	next_scene = "res://menu.tscn"   # back to the main menu
	morph_word = "human again"       # the ball turns back into the knight here
	reverse = true

func _ready() -> void:
	super()
	thanks = Label.new()
	thanks.text = THANKS
	thanks.add_theme_font_override("font", load("res://fonts/PixelOperator8-Bold.ttf"))
	thanks.add_theme_font_size_override("font_size", 32)
	thanks.add_theme_color_override("font_color", HACK_CLUB_RED)
	thanks.add_theme_color_override("font_outline_color", Color.BLACK)
	thanks.add_theme_constant_override("outline_size", 8)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# centred near the bottom, between the story and "press any key"
	thanks.anchor_left = 0.5
	thanks.anchor_right = 0.5
	thanks.anchor_top = 1.0
	thanks.anchor_bottom = 1.0
	thanks.offset_left = -400.0
	thanks.offset_right = 400.0
	thanks.offset_top = -150.0
	thanks.offset_bottom = -100.0
	thanks.pivot_offset = Vector2(400, 25)
	thanks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thanks.modulate.a = 0.0
	add_child(thanks)

func finish() -> void:
	super()
	if thanked:
		return
	thanked = true
	# pop in after the story, then gently pulse
	thanks.scale = Vector2(0.4, 0.4)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(Sfx.play.bind("pickup"))
	tween.tween_property(thanks, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(thanks, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(pulse)

func pulse() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(thanks, "scale", Vector2(1.06, 1.06), 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(thanks, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
