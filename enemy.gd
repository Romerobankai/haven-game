extends CharacterBody2D
# Walking enemy: patrols back and forth, turning at walls and at platform edges.
# The slime, rat and mimic all use this script with different settings.

@export var speed := 80.0
@export var hp := 3
@export var ledge_ahead := 16.0      # how far in front to check for the edge of a platform
@export var art_faces_right := true  # which way the sprite is drawn

const GRAVITY := 1400.0
const MAX_FALL := 900.0

var dir := -1.0

@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	$Hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	# turn around at walls and at the edge of a platform
	if is_on_floor():
		ledge_check.position.x = dir * ledge_ahead
		ledge_check.force_raycast_update()
		if is_on_wall() or not ledge_check.is_colliding():
			dir = -dir

	velocity.x = dir * speed
	move_and_slide()
	sprite.flip_h = (dir < 0.0) == art_faces_right

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		Sfx.play("boom")
		queue_free()
		return
	# quick white flash when hit
	modulate = Color(3, 3, 3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)

func _on_hurtbox_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.die()
