extends CharacterBody2D

const SPEED := 220.0
const GRAVITY := 1400.0
const MAX_FALL := 900.0
const BOUNCE := 650.0          # normal bounce, about 150 px high
const BOUNCE_HIGH := 820.0     # timed bounce, about 240 px high
const TIMING_WINDOW := 0.15    # seconds before landing that S still counts

var has_key := false
var big_bounce_timer := 0.0

func _ready() -> void:
	add_to_group("player")

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
	if global_position.y > 3000.0:
		get_tree().reload_current_scene.call_deferred()                                                                                                                                                                                                                                                                                                                                                                                                         
