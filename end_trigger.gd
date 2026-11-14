extends Area2D
# The door at the far end of the room. Touching it makes the key appear.

var used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	get_tree().call_group("game", "spawn_key")
