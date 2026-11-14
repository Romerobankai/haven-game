extends StaticBody2D
# The locked gate in front of the exit. With the key, its bars slide up into the wall.

var opened := false

func _ready() -> void:
	$Lock.body_entered.connect(_on_lock_body_entered)

func _on_lock_body_entered(body) -> void:
	if opened or not body.is_in_group("player"):
		return
	if body.has_key:
		open()
	else:
		get_tree().call_group("game", "show_message", "Locked. You need the key.")

func open() -> void:
	opened = true
	get_tree().call_group("game", "show_message", "The gate opens!")
	$CollisionShape2D.set_deferred("disabled", true)
	$Lock.set_deferred("monitoring", false)
	var sprite: Sprite2D = $Sprite2D
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - 96.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
