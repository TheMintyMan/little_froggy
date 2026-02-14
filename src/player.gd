extends StaticBody3D
class_name Player

@export var leap_count: int = 0
@export var leapable_height: float = 0.5
signal leap_count_changed(count: int)
var facing_dir: Vector2 = Vector2.ZERO
var in_house: bool = false
var level_root: Level
var main: Main

var action_manager = ActionManager.new({
	"move": [move, undo_move],
})

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main = get_tree().current_scene
	level_root = get_tree().current_scene.get_child(1)
	level_root.register_player(self)
	facing_dir = convert_rot_dir()
	
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
	
	if Input.is_action_just_pressed("ability01"):
		try_pull()
	
	if Input.is_action_just_pressed("restart"):
		main.goto_level(main.level_index)
	
	if v.x != 0 and v.y != 0:
		return Vector2()
		
	#if v != Vector2.ZERO:
		#$Timer.start()
	return v
	
func move(dir):
	var grid_pos = Global.get_grid_pos(self)
	var new_grid_pos: Vector2 = grid_pos + dir
	var new_world_pos: Vector3 = Vector3(new_grid_pos.x, 0,new_grid_pos.y)
	
	var collider = Global.grid_check(new_grid_pos)
	var collider_food = Global.grid_check(new_grid_pos, 2)
	var home_dir = Global.convert_rot_dir(level_root.get_home().global_rotation.y+90)
	
	facing_dir = dir
	
	if in_house:
		if dir != home_dir:
			print("Frog not facing the same direction as the home", Global.convert_rot_dir(level_root.get_home().global_rotation.y))
			return
		else:
			in_house = false
			Global.move_to_grid_pos(self, new_world_pos)
			
	if collider_food is Food:
		if get_height_diff(self, collider_food, false) <= 0:
			collider_food.eat()
			on_food_eaten(1) # Arbitrary value currently
			return
		else:
			pass
	
	if collider == null:
		Global.move_to_grid_pos(self, new_world_pos)
		return

	if collider is Home:
		if dir != Vector2(home_dir.x*-1, home_dir.y*-1):
			print("Cannot enter this way")
			return
		print("The frog has entered home")
		in_house = true
		self.rotation = collider.rotation
		facing_dir = convert_rot_dir()
		Global.move_to_grid_pos(self, new_world_pos)
		level_root.check_win_condition()
		
	if collider.is_in_group("leapable"):
		try_leap(get_height_diff(self, collider), collider.position)
		
	if collider.is_in_group("wall"):
		print('wall!')
		return
	
	if collider.is_in_group("pushable"):
		if collider.push(dir):
			Global.move_to_grid_pos(self, new_world_pos)
	Global.move_to_grid_pos(self, new_world_pos)

func try_pull():
	var grid_pos : Vector2 = Global.get_grid_pos(self) + (facing_dir*2)
	var collider = Global.grid_check(grid_pos)
	print ("collider pull: ", grid_pos,", ", collider)
	if collider == null:
		return
	if collider.is_in_group("pullable"):
		collider.push(facing_dir*-1)

func on_food_eaten(value: int) -> void:
	leap_count += value 
	emit_signal("leap_count_changed", leap_count)
	print("yummyy, current leap count is ", leap_count)

## Calculates the height difference
func get_height_diff(input: Node3D, collider: Node3D, check_collision_height:bool = true) -> float:
	for child in collider.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if check_collision_height:
				if shape is BoxShape3D:
					print("height diff = ", (shape.size.y + collider.position.y) - input.global_position.y)
					return (shape.size.y + collider.position.y) - input.global_position.y
			else:
				print("height diff = ", collider.position.y - input.global_position.y)
				return(collider.position.y - input.global_position.y)
	print("no collider with BoxShape found")
			
	return 0.0

func try_leap(height_diff: float, new_pos: Vector3) -> void:
	new_pos.y = self.position.y + height_diff
	
	if height_diff <= 0:
		
		Global.move_to_grid_pos(self, new_pos)
		return
	
	if height_diff <= leapable_height:
		if leap_count < 1:
			print("cannot leap again")
			return 
		leap_count -= 1
		
		Global.move_to_grid_pos(self, new_pos)
		print(self.position.y)
		emit_signal("leap_count_changed", leap_count)
		print("you just leaped")

func undo_move(dir):
	var grid_pos = Global.get_grid_pos(self)
	var new_pos = grid_pos - dir
	Global.move_to_grid_pos(self, new_pos)
	
func convert_rot_dir() -> Vector2:
	var forward = -global_transform.basis.z
	var dir: Vector2
	if abs(forward.x) > abs(forward.z):
		dir.x = sign(forward.x)
		return dir
	else:
		dir.y = sign(forward.z)
		return dir

func _physics_process(_delta: float) -> void:
	var input_direction = get_input_direction()
	if Input.is_action_just_pressed("undo"):
		Global.undo()

	if input_direction != Vector2.ZERO:
		Global.time_index += 1
		action_manager.do_action("move", [input_direction])
