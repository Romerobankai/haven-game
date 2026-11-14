extends CharacterBody2D

const SPEED := 500.0
const LIFETIME := 3.0

var direction := Vector2.RIGHT
var bounces_left := 3
var age := 0.0

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	age += delta
	if age > LIFETIME:
		queue_free()
		return

	var hit := move_and_collide(direction * SPEED * delta)
	if hit == null:
		return

	var other := hit.get_collider() as Node
	if other and other.has_method("take_damage"):
		other.call("take_damage", 1)
		queue_free()
		return

	# bounce off the wall: v' = v - 2(v.n)n
	direction = direction.bounce(hit.get_normal())
	rotation = direction.angle()
	bounces_left -= 1
	if bounces_left < 0:
		queue_free()
