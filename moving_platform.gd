extends AnimatableBody2D
# A platform that glides back and forth forever.
# Change how far it goes (travel) and how long one trip takes (duration) in the Inspector.

@export var travel := Vector2(160, 0)   # how far from its start it moves (x = sideways, y = up/down)
@export var duration := 2.5             # seconds for one trip

func _ready() -> void:
	var start := position
	var tween := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", start + travel, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
