extends Area2D
# Kills the player on touch. Used for spikes, and for water / lava pits.

@export var counts_as_hit := true   # spikes: hit sound + red flash. Water/lava: straight to the explosion.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.die(counts_as_hit)
