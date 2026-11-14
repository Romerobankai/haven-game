extends CharacterBody2D

const SPEED := 220.0
const GRAVITY := 1400.0
const MAX_FALL := 900.0
const BOUNCE := 650.0          # normal bounce, about 150 px high
const BOUNCE_HIGH := 820.0     # timed bounce, about 240 px high
const TIMING_WINDOW := 0.15    # seconds before landing that S still counts
const DEATH_Y := 1200.0        # falling below this restarts the level

const BULLET_SCENE := preload("res://bullet.tscn")
const FIRE_GAP := 0.2          # seconds between shots
const RECOIL := 120.0          # shooting down slows your fall (but can't lift you higher)

const HIT_PAUSE := 0.3         # after getting hit: red flash, then explode
const RESTART_DELAY := 0.5     # after exploding: wait, then restart the level

var has_key := false
var big_bounce_timer := 0.0
var fire_cooldown := 0.0
var dead := false

@onready var gun: Node2D = $Gun
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_scale: Vector2 = sprite.scale

func _ready() -> void:
	add_to_group("player")
	# pop out of the entrance door
	sprite.scale = Vector2.ZERO
	create_tween().tween_property(sprite, "scale", sprite_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	# pressing S opens a short window
	if Input.is_action_just_pressed("bounce_high"):
		big_bounce_timer = TIMING_WINDOW
	big_bounce_timer -= delta

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = Input.get_axis("move_left", "move_right") * SPEED
	move_and_slide()

	# never rest on the floor: every landing launches the ball again
	if is_on_floor():
		if big_bounce_timer > 0.0:
			velocity.y = -BOUNCE_HIGH
			big_bounce_timer = 0.0
		else:
			velocity.y = -BOUNCE

	# fell out of the world
	if global_position.y > DEATH_Y:
		die(false)

func _process(delta: float) -> void:
	var mouse := get_global_mouse_position()
	gun.look_at(mouse)

	fire_cooldown -= delta
	if Input.is_action_pressed("shoot") and fire_cooldown <= 0.0:
		fire_cooldown = FIRE_GAP
		shoot((mouse - global_position).normalized())

func shoot(dir: Vector2) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = dir
	bullet.global_position = global_position + dir * 30.0
	get_tree().current_scene.add_child(bullet)
	Sfx.play("laser")
	# recoil: shooting downward slows your fall, so you can hover across gaps
	if dir.y > 0.0:
		velocity.y = minf(velocity.y, -RECOIL * dir.y)

# was_hit: true for enemies and spikes, false for falling into a pit
func die(was_hit := true) -> void:
	if dead:
		return
	dead = true
	set_physics_process(false)
	set_process(false)
	if was_hit:
		Sfx.play("hit")
		modulate = Color(2.5, 0.5, 0.5)   # flash red
		get_tree().create_timer(HIT_PAUSE).timeout.connect(explode)
	else:
		explode()

func explode() -> void:
	Sfx.play("explo")
	hide()
	get_tree().create_timer(RESTART_DELAY).timeout.connect(restart_level)

func restart_level() -> void:
	get_tree().reload_current_scene()

func win() -> void:
	set_physics_process(false)
	set_process(false)

# hold still during a cutscene (like the camera showing the key)
func freeze(on: bool) -> void:
	if dead:
		return
	set_physics_process(not on)
	set_process(not on)

# shrink into the exit door
func enter_door(door_position: Vector2) -> void:
	win()
	gun.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "global_position", door_position + Vector2(0, 24), 0.35)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.35)
