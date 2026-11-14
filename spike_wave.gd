extends Area2D
# A row of spikes that bursts out of the floor and slides along it (from the King's slam).

var direction := 1.0
var speed := 240.0
var min_x := 0.0
var max_x := 99999.0
var age := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.position.y = 30.0
	create_tween().tween_property(sprite, "position:y", -32.0, 0.15)

func _physics_process(delta: float) -> void:
	age += delta
	position.x += direction * speed * delta
	if position.x < min_x or position.x > max_x or age > 6.0:
		queue_free()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.die()
