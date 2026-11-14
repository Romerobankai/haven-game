extends "res://main.gd"
# The final room: the fight against the King.

const FIGHT_DELAY := 2.0   # seconds before the King starts attacking

@onready var king = $King
@onready var boss_bar: Control = $UI/BossBar
@onready var health: ProgressBar = $UI/BossBar/Health

func _ready() -> void:
	super()
	show_message("THE KING\nShoot him to break the curse!", 3.0)
	boss_bar.hide()
	king.health_changed.connect(_on_king_health)
	king.defeated.connect(_on_king_defeated)
	get_tree().create_timer(FIGHT_DELAY).timeout.connect(start_fight)

func start_fight() -> void:
	boss_bar.show()
	king.start()

func _on_king_health(hp: int, max_hp: int) -> void:
	health.max_value = max_hp
	health.value = hp

func _on_king_defeated() -> void:
	show_message("The King is defeated!", 3.0)
	go_to_next_scene(2.5)
