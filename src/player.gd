extends StaticBody3D

@export var leap_count: int = 1
var current_height: float = 0.0
signal leap_count_changed(count)
var facing_dir: Vector2 = Vector2.ZERO


var action_manager = ActionManager.new({
	"move": [move, undo_move]
})

func _init() -> void:
	current_height = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.register_player(self)
	var forward = -global_transform.basis.z
	if abs(forward.x) > abs(forward.z):
		facing_dir.x = sign(forward.x)
	else:
		facing_dir.y = sign(forward.z)
	
	
	print("current height: ", current_height)
	print('ready')
	print("currently facing: ", facing_dir)
	await get_tree().create_timer(0.1).timeout
	emit_signal("leap_count_changed", leap_count)

func get_input_direction() -> Vector2:
	#if $Timer.time_left != 0:
		#return Vector2()
	var v = Vector2()
	if Input.is_action_just_pressed("playerDown"):
		v.y += 1
		self.global_rotation = Vector3(0, deg_to_rad(0), 0)
	if Input.is_action_just_pressed("playerUp"):
		v.y -= 1
		self.global_rotation = Vector3(0, deg_to_rad(180), 0)
	if Input.is_action_just_pressed("playerRight"):
		v.x += 1
		self.global_rotation = Vector3(0, deg_to_rad(90), 0)
	if Input.is_action_just_pressed("playerLeft"):
		v.x -= 1
		self.global_rotation = Vector3(0, deg_to_rad(-90), 0)

		
	if v.x != 0 and v.y != 0:
		return Vector2()
		
	#if v != Vector2.ZERO:
		#$Timer.start()
	return v
	
func move(dir):
	var grid_pos = Global.get_grid_pos(self)
	var new_pos = grid_pos + dir
	
	var collider = Global.grid_check(new_pos)
	
	if collider == null:
		current_height = 0
		Global.move_to_grid_pos(self, new_pos)
		return
	
	var collider_height: int = collider.global_position.y + 1
	var height_diff: int = collider_height - current_height
	
	if collider is Food:
		collider.eaten.connect(_on_food_eaten)
		collider.eat()
	
	if collider.is_in_group("leapable"):
		try_leap(height_diff, new_pos)
	
	if collider.is_in_group("wall"):
		print('wall!')
		return
	
	if collider.is_in_group("pushable"):
		if collider.push(dir):
			Global.move_to_grid_pos(self, new_pos)

func _on_food_eaten(value: int) -> void:
	leap_count += value
	emit_signal("leap_count_changed", leap_count)
	print("yummyy, current leap count is ", leap_count)

func try_leap(height_diff: int, new_pos: Vector2) -> void:
	if height_diff == 0:
		Global.move_to_grid_pos(self, new_pos)
		return
	
	if height_diff == 1:
		if leap_count < 1:
			print("cannot leap again")
			return 
		current_height += 1
		leap_count -= 1
		Global.move_to_grid_pos(self, new_pos)
		emit_signal("leap_count_changed", leap_count)
		print("you just leaped")

func undo_move(dir):
	var grid_pos = Global.get_grid_pos(self)
	var new_pos = grid_pos - dir
	Global.move_to_grid_pos(self, new_pos)


func _physics_process(_delta: float) -> void:
	var input_direction = get_input_direction()
	if Input.is_action_just_pressed("undo"):
		Global.undo()
	
	if input_direction != Vector2.ZERO:
		Global.time_index += 1
		action_manager.do_action("move", [input_direction])
