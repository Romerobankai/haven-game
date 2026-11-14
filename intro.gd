extends Control

# The story, typed out one letter at a time.
# [b]...[/b] makes text bold, [color=...]...[/color] colours it.
const STORY := "Long ago, you were a knight who served the King.\n\n" \
	+ "But one night, the King cast a curse on you...\n" \
	+ "...and turned you into a ball.\n\n" \
	+ "To turn back into a human, you must\n" \
	+ "[b][color=#ffd54a]bounce back[/color][/b]."

const CHARS_PER_SECOND := 28.0
const PAUSE_DOTS := 0.25     # between the dots of "..."
const PAUSE_COMMA := 0.2
const PAUSE_SENTENCE := 0.6  # after . ! ?
const PAUSE_LINE := 0.35     # after a line break

const GAME_SCENE := "res://controls.tscn"   # the quick how-to-play screen, then level 1
const KNIGHT_SCALE := Vector2(4, 4)
const BALL_SCALE := Vector2(0.25, 0.25)

@onready var story: RichTextLabel = $Story
@onready var prompt: Label = $Prompt
@onready var picture: Control = $Picture
@onready var knight: AnimatedSprite2D = $Picture/Knight
@onready var arrow: Label = $Picture/Arrow
@onready var ball: Sprite2D = $Picture/Ball

var story_text := STORY       # ending.gd swaps these for the ending screen
var next_scene := GAME_SCENE
var morph_word := "ball"      # the picture changes when this word has been typed
var reverse := false          # ending: ball -> knight instead of knight -> ball

var shown := 0
var wait := 0.5              # short pause before the first letter
var done := false
var plain := ""              # the story without [b] tags, to look up each letter
var morph_at := -1
var morphed := false

func _ready() -> void:
	story.text = "[center]" + story_text + "[/center]"
	story.visible_characters = 0
	plain = story.get_parsed_text()
	var i := plain.find(morph_word)
	morph_at = i + morph_word.length() if i >= 0 else -1
	prompt.hide()
	setup_picture()

# before: knight (or the ball, in the ending) on the left; arrow and the other one hidden
func setup_picture() -> void:
	arrow.modulate.a = 0.0
	var first: Node2D = knight
	var second: Node2D = ball
	if reverse:
		first = ball
		second = knight
	first.position.x = -170.0
	second.position.x = 170.0
	second.scale = Vector2.ZERO
	knight.play("idle")
	first.modulate.a = 0.0
	create_tween().tween_property(first, "modulate:a", 1.0, 0.6)
	# (in the ending the ball just sits still)

func morph() -> void:
	if morphed:
		return
	morphed = true
	# white flash, then the arrow and the new form appear
	picture.modulate = Color(3, 3, 3)
	create_tween().tween_property(picture, "modulate", Color.WHITE, 0.4)
	create_tween().tween_property(arrow, "modulate:a", 1.0, 0.3)
	if reverse:
		knight.modulate.a = 1.0
		create_tween().tween_property(knight, "scale", KNIGHT_SCALE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ball.modulate = Color(0.6, 0.6, 0.7, 0.8)
	else:
		knight.play("curse")
		create_tween().tween_property(knight, "modulate", Color(0.6, 0.6, 0.7, 0.8), 0.6)
		var pop := create_tween()
		pop.tween_property(ball, "scale", BALL_SCALE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_callback(bounce.bind(ball))

func bounce(node: Node2D) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(node, "position:y", -40.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _process(delta: float) -> void:
	if done:
		return
	wait -= delta
	while wait <= 0.0 and not done:
		shown += 1
		story.visible_characters = shown
		if not plain[shown - 1] in " \n":
			Sfx.play("text")   # blip for every letter, like RPG dialogue
		if morph_at >= 0 and shown >= morph_at:
			morph()
		if shown >= story.get_total_character_count():
			finish()
			return
		wait += 1.0 / CHARS_PER_SECOND + pause_after(shown - 1)

# extra pause after some characters, so it reads like someone typing
func pause_after(i: int) -> float:
	var ch := plain[i]
	var next := plain[i + 1] if i + 1 < plain.length() else ""
	if ch == "." and next == ".":
		return PAUSE_DOTS
	if ch in ".!?":
		return PAUSE_SENTENCE
	if ch == ",":
		return PAUSE_COMMA
	if ch == "\n":
		return PAUSE_LINE
	return 0.0

func finish() -> void:
	done = true
	story.visible_characters = -1
	morph()
	prompt.show()
	# blink the "press any key" text
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.25, 0.6)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.6)

func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not done:
		finish()                 # first press skips the typing
	else:
		get_tree().change_scene_to_file(next_scene)
