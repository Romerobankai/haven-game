extends CharacterBody2D
# The King, the final boss. He walks toward you, then uses an attack:
#   charge  - runs across the room (bounce over him or get on a platform)
#   slam    - jumps and lands, sending spike waves along the floor both ways
#   summon  - calls bats
# Below half health he gets faster. Shoot him to win.

signal health_changed(hp: int, max_hp: int)
signal defeated

@export var max_hp := 30
@export var arena_left := 96.0     # spike waves disappear at the walls
@export var arena_right := 1056.0

const GRAVITY := 1400.0
const WALK_SPEED := 70.0
const CHARGE_SPEED := 400.0
const SLAM_JUMP := 620.0
const ATTACKS := ["charge", "slam", "charge", "summon"]
const WAVE_SCENE := preload("res://spike_wave.tscn")
const BAT_SCENE := preload("res://bat.tscn")

var hp := 0
var dir := -1.0
var state := "waiting"
var state_time := 0.0
var next_attack := 0
var left_ground := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	sprite.play("idle")

# called by the boss room when the fight begins
func start() -> void:
	health_changed.emit(hp, max_hp)
	set_state("walk")

func angry() -> bool:
	return hp * 2 <= max_hp   # below half health

func speed_mult() -> float:
	return 1.35 if angry() else 1.0

func set_state(new_state: String) -> void:
	state = new_state
	state_time = 0.0
	sprite.speed_scale = 1.0
	match new_state:
		"walk":
			sprite.play("run")
		"windup":
			sprite.play("idle")
			flash(Color(2.5, 0.6, 0.6))   # glows red right before charging
		"charge":
			sprite.play("run")
			sprite.speed_scale = 2.0
		"slam":
			velocity.y = -SLAM_JUMP
			left_ground = false
			sprite.play("idle")
		"summon":
			sprite.play("hit")
			summon_bats()
		"recover":
			sprite.play("idle")
		"dead":
			sprite.play("death")

func face_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and absf(player.global_position.x - global_position.x) > 4.0:
		dir = signf(player.global_position.x - global_position.x)

func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	state_time += delta
	match state:
		"waiting", "dead":
			velocity.x = 0.0
		"walk":
			face_player()
			velocity.x = dir * WALK_SPEED * speed_mult()
			if state_time > (1.2 if angry() else 2.0):
				var attack: String = ATTACKS[next_attack % ATTACKS.size()]
				next_attack += 1
				set_state("windup" if attack == "charge" else attack)
		"windup":
			velocity.x = 0.0
			face_player()
			if state_time > (0.4 if angry() else 0.7):
				set_state("charge")
		"charge":
			velocity.x = dir * CHARGE_SPEED * speed_mult()
			if (is_on_wall() and state_time > 0.1) or state_time > 3.0:
				set_state("recover")
		"slam":
			velocity.x = 0.0
			if not is_on_floor():
				left_ground = true
			elif left_ground and state_time > 0.15:
				slam_land()
				set_state("recover")
		"summon":
			velocity.x = 0.0
			if state_time > 0.8:
				set_state("recover")
		"recover":
			velocity.x = 0.0
			if state_time > (0.4 if angry() else 0.8):
				set_state("walk")
	move_and_slide()
	if state != "dead":
		sprite.flip_h = dir < 0.0

func slam_land() -> void:
	Sfx.play("boom")
	for side in [-1.0, 1.0]:
		var wave = WAVE_SCENE.instantiate()
		wave.direction = side
		wave.speed = 320.0 if angry() else 240.0
		wave.min_x = arena_left
		wave.max_x = arena_right
		wave.position = Vector2(global_position.x + side * 50.0, global_position.y + 54.0)
		get_parent().add_child(wave)

func summon_bats() -> void:
	var alive := get_tree().get_nodes_in_group("boss_bats").size()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var center := player.global_position.x if player else global_position.x
	for side in [-1.0, 1.0]:
		if alive >= 3:
			return
		var bat = BAT_SCENE.instantiate()
		bat.position = Vector2(clampf(center + side * 180.0, arena_left + 60.0, arena_right - 60.0), 200.0)
		bat.patrol_distance = 120.0
		bat.add_to_group("boss_bats")
		get_parent().get_node("Enemies").add_child(bat)
		alive += 1

func flash(color: Color) -> void:
	modulate = color
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)

func take_damage(amount: int) -> void:
	if state == "waiting" or state == "dead":
		return
	hp -= amount
	health_changed.emit(maxi(hp, 0), max_hp)
	flash(Color(3, 3, 3))
	if hp <= 0:
		die()

func die() -> void:
	set_state("dead")
	hurtbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	Sfx.play("boom")
	for bat in get_tree().get_nodes_in_group("boss_bats"):
		bat.queue_free()
	defeated.emit()

func _on_hurtbox_body_entered(body) -> void:
	if state != "dead" and body.is_in_group("player"):
		body.die()
