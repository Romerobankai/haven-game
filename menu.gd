extends Control
# Main menu: Play, Settings (music, sound effects, fullscreen) and Quit.

const FIRST_SCENE := "res://intro.tscn"
const SKY_WIDTH := 1280.0   # castle_bg.png drawn at 4x
const SKY_SPEED := 14.0     # background drift, pixels per second

@onready var main_buttons: Control = $MainButtons
@onready var settings_panel: Control = $SettingsPanel
@onready var play_button: Button = $MainButtons/Play
@onready var music_slider: HSlider = $SettingsPanel/Box/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/Box/SfxSlider
@onready var fullscreen_check: CheckButton = $SettingsPanel/Box/Fullscreen
@onready var title: Control = $Title
@onready var sky: TextureRect = $Sky
@onready var fade: ColorRect = $Fade

var time := 0.0
var leaving := false

func _ready() -> void:
	play_button.pressed.connect(play)
	$MainButtons/Settings.pressed.connect(open_settings)
	$MainButtons/Quit.pressed.connect(get_tree().quit)
	$SettingsPanel/Box/Back.pressed.connect(close_settings)

	# show the saved settings, then update them live as the player changes them
	music_slider.value = Sfx.music_volume * 100.0
	sfx_slider.value = Sfx.sfx_volume * 100.0
	fullscreen_check.button_pressed = Sfx.fullscreen
	music_slider.value_changed.connect(func(v: float): Sfx.set_music_volume(v / 100.0))
	sfx_slider.value_changed.connect(func(v: float): Sfx.set_sfx_volume(v / 100.0))
	sfx_slider.drag_ended.connect(func(_changed: bool): Sfx.play("pickup"))   # hear the new volume
	fullscreen_check.toggled.connect(Sfx.set_fullscreen)

	# a little blip whenever you move between buttons
	for b in [play_button, $MainButtons/Settings, $MainButtons/Quit, $SettingsPanel/Box/Back]:
		b.focus_entered.connect(Sfx.play.bind("text"))
		b.mouse_entered.connect(b.grab_focus)

	settings_panel.hide()
	play_button.grab_focus.call_deferred()

	# fade in, and let the title float gently
	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)
	var float_tween := create_tween().set_loops()
	float_tween.tween_property(title, "position:y", title.position.y - 8.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(title, "position:y", title.position.y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	time += delta
	sky.position.x = -fposmod(time * SKY_SPEED, SKY_WIDTH)

func play() -> void:
	if leaving:
		return
	leaving = true
	Sfx.play("pickup")
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	tween.tween_callback(get_tree().change_scene_to_file.bind(FIRST_SCENE))

func open_settings() -> void:
	main_buttons.hide()
	settings_panel.show()
	music_slider.grab_focus()

func close_settings() -> void:
	Sfx.save_settings()
	settings_panel.hide()
	main_buttons.show()
	play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	# Esc goes back from the settings
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		close_settings()
		get_viewport().set_input_as_handled()
