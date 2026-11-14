extends CharacterBody2D
# Flying enemy: flaps left and right around where it starts, bobbing up and down.

@export var speed := 90.0
@export var hp := 2
@export var patrol_distance := 160.0  # how far it flies each way from its start
@export var bob_height := 18.0
@export var art_faces_right := true

var start := Vector2.ZERO
var dir := -1.0
var time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	start = position
	time = randf() * TAU   # so bats don't all bob in sync
	$Hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(delta: float) -> void:
	time += delta
	position.x += dir * speed * delta
	if absf(position.x - start.x) >= patrol_distance:
		position.x = start.x + signf(position.x - start.x) * patrol_distance
		dir = -dir
	position.y = start.y + sin(time * 3.0) * bob_height
	sprite.flip_h = (dir < 0.0) == art_faces_right

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		Sfx.play("boom")
		queue_free()
		return
	modulate = Color(3, 3, 3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)

func _on_hurtbox_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.die()
