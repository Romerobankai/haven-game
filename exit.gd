extends Area2D
# The door to the next room (behind the locked gate).

var used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	body.enter_door(global_position)
	get_tree().call_group("game", "level_complete")
