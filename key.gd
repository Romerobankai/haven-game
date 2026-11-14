extends Area2D
# The key for this room's locked door. It stays hidden until you touch the door at the far end,
# then it pops into view (the camera shows you where). Touch it to pick it up.

var picked := false
var idle_tween: Tween

func _ready() -> void:
	add_to_group("key")
	body_entered.connect(_on_body_entered)
	hide()
	set_deferred("monitoring", false)

# spin in with a flash
func appear() -> void:
	show()
	scale = Vector2.ZERO
	rotation = -PI
	modulate = Color(3, 3, 3)
	Sfx.play("pickup")
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.8)
	tween.chain().tween_callback(start_idle)

# bob up and down and glow, waiting to be picked up
func start_idle() -> void:
	set_deferred("monitoring", true)
	idle_tween = create_tween().set_loops()
	idle_tween.tween_property(self, "position:y", position.y - 8.0, 0.5).set_trans(Tween.TRANS_SINE)
	idle_tween.parallel().tween_property(self, "modulate", Color(1.6, 1.5, 1.1), 0.5)
	idle_tween.tween_property(self, "position:y", position.y, 0.5).set_trans(Tween.TRANS_SINE)
	idle_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.5)

# jump up, spin, flash, then fly into the ball
func _on_body_entered(body) -> void:
	if picked or not body.is_in_group("player"):
		return
	picked = true
	set_deferred("monitoring", false)
	body.has_key = true
	Sfx.play("pickup")
	if idle_tween:
		idle_tween.kill()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 50.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(self, "rotation", TAU, 0.45)
	tween.parallel().tween_property(self, "modulate", Color(3, 3, 3), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	tween.tween_property(self, "global_position", body.global_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
	get_tree().call_group("game", "key_collected")
