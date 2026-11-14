extends Node
# Sound effects, music and the player's settings.
# This is an autoload called "Sfx", so any script can do Sfx.play("laser").
# It lives outside the levels, so sounds and music keep playing when a level restarts.

const MUSIC := preload("res://music/time_for_adventure.mp3")
const MUSIC_DB := -12.0   # music volume in decibels at 100%, kept below the sound effects

const SOUND_FILES := {
	"laser": "res://sfx/laser.wav",    # gun shot
	"hit": "res://sfx/hit.wav",        # you get hit
	"explo": "res://sfx/explo.wav",    # you die
	"pickup": "res://sfx/pickup.wav",  # you pick up the key
	"boom": "res://sfx/boom.wav",      # an enemy dies
	"text": "res://sfx/text.wav",      # one letter of story text (the typewriter blip)
}

# loudness of each sound in decibels: 0 = as recorded, -6 = about half as loud
const VOLUME_DB := {
	"laser": -8.0,
	"hit": 0.0,
	"explo": 0.0,
	"pickup": 0.0,
	"boom": -2.0,
	"text": -6.0,
}

const VOICES := 12   # how many sounds can play at once
const SETTINGS_PATH := "user://settings.cfg"

# settings, changed from the Settings menu and remembered between launches
var music_volume := 1.0   # 0.0 to 1.0
var sfx_volume := 1.0     # 0.0 to 1.0
var fullscreen := false

var sounds := {}   # loaded when the game starts; a sound that isn't imported yet is just skipped
var players: Array[AudioStreamPlayer] = []
var next := 0
var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	for key in SOUND_FILES:
		var file: String = SOUND_FILES[key]
		if ResourceLoader.exists(file):
			sounds[key] = load(file)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

	# background music, looping forever from the moment the game starts
	var music: AudioStreamMP3 = MUSIC
	music.loop = true
	music_player = AudioStreamPlayer.new()
	music_player.stream = music
	add_child(music_player)
	set_music_volume(music_volume)
	music_player.play()
	apply_fullscreen()

func play(sound: String) -> void:
	if not sounds.has(sound):
		return
	var p := players[next]
	next = (next + 1) % VOICES
	p.stream = sounds[sound]
	p.volume_db = VOLUME_DB.get(sound, 0.0) + to_db(sfx_volume)
	# small random pitch so rapid shots don't sound identical
	p.pitch_scale = randf_range(0.93, 1.07) if sound == "laser" else 1.0
	p.play()

# ---------------------------------------------------------------- settings

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	music_player.volume_db = MUSIC_DB + to_db(music_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_fullscreen()

func apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	fullscreen = cfg.get_value("display", "fullscreen", false)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)

# 0..1 slider value -> decibels (0 means silent)
func to_db(linear: float) -> float:
	return -80.0 if linear <= 0.001 else linear_to_db(linear)
