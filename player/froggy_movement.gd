extends MovementComponent
class_name FroggyMovementComponent

var eating_close: bool = false
var eating_far: bool = false
var jumping_basic: bool = false
var turning: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	super(delta)
	
## Rotate the frog over time to face a cardinal grid direction (Vector2).
func turn_to_dir(dir: Vector2):
	if dir == Vector2.ZERO:
		return
	turning = true
	set_turn(atan2(dir.x, dir.y))
	await get_tree().create_timer(_rotation_duration).timeout
	turning = false

func jump_basic():
	anim_tree["parameters/conditions/jumping_basic"] = true
	await get_tree().create_timer(0.2).timeout
	anim_tree["parameters/conditions/jumping_basic"] = false
	jumping_basic = true

func eat_close():
	#anim_tree["parameters/conditions/Idle"] = false
	anim_tree["parameters/conditions/eating_close"] = true
	await get_tree().create_timer(0.2).timeout
	anim_tree["parameters/conditions/eating_close"] = false
	eating_close = true
	
func eat_far():
	#anim_tree["parameters/conditions/Idle"] = false
	anim_tree["parameters/conditions/eating_far"] = true
	await get_tree().create_timer(0.2).timeout
	anim_tree["parameters/conditions/eating_far"] = false
	eating_far = true
