extends MovementComponent
class_name FroggyMovementComponent

var eating_close: bool = false
var eating_far: bool = false
var jumping_basic: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	super(delta)
	
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
