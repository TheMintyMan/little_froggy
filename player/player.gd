extends StaticBody3D
class_name Player

@export var movement_comp: FroggyMovementComponent
var food_eaten: int = 0
@export var leapable_height: float = 0.5
signal food_count_changed(count: int)

@export_group("Move Repeat")
## If true, holding a direction keeps moving the frog instead of requiring a fresh press each step.
@export var repeat_move: bool = true
## Seconds a direction must be held before auto-repeat kicks in.
@export var repeat_delay: float = 0.35
## Seconds between repeated moves once auto-repeat has started.
@export var repeat_interval: float = 0.15

var facing_dir: Vector2 = Vector2.ZERO
var in_house: bool = false
#var level_root: Level
#var main: Main
var home_dir
var target_pos: Vector3
var is_movement_disabled: bool = false
@onready var player_camera: Camera3D = %camera

var previous_collider: Node3D = null

# Held-direction auto-repeat (DAS) state.
var _held_dir: Vector2 = Vector2.ZERO
var _held_time: float = 0.0
var _repeating: bool = false

var action_manager = ActionManager.new({
	"move": [move, undo_move],
})

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#main = get_tree().current_scene
	facing_dir = convert_rot_dir()
	GameManager.set_player(self)
	
	print('ready')
	print("currently facing: ", facing_dir)
	await get_tree().create_timer(0.1).timeout
	emit_signal("food_count_changed", food_eaten)
	
	if GameManager.get_home():
		home_dir = Global.convert_rot_dir(GameManager.get_home().global_rotation.y+90)

func get_input_direction() -> Vector2:
	#if $Timer.time_left != 0:
		#return Vector2()
	var v = Vector2()
	if Input.is_action_just_pressed("playerDown"):
		v.y = 1
		v.x = 0
	if Input.is_action_just_pressed("playerUp"):
		v.y = -1
		v.x = 0
	if Input.is_action_just_pressed("playerRight"):
		v.x = 1
		v.y = 0
	if Input.is_action_just_pressed("playerLeft"):
		v.x = -1
		v.y= 0
	if Input.is_action_just_pressed("ability01"):
		try_pull()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	if v.x != 0 and v.y != 0:
		return Vector2()

	#if v != Vector2.ZERO:
		#$Timer.start()
	return v

## Currently held movement direction (independent of just-pressed), same priority
## order as get_input_direction so the two never disagree.
func get_held_direction() -> Vector2:
	var v = Vector2.ZERO
	if Input.is_action_pressed("playerDown"):
		v = Vector2(0, 1)
	if Input.is_action_pressed("playerUp"):
		v = Vector2(0, -1)
	if Input.is_action_pressed("playerRight"):
		v = Vector2(1, 0)
	if Input.is_action_pressed("playerLeft"):
		v = Vector2(-1, 0)
	return v

func try_move(dir: Vector2) -> void:
	Global.time_index += 1
	action_manager.do_action("move", [dir])

## Handles holding a direction down: waits repeat_delay, then fires a move
## every repeat_interval for as long as that direction stays held.
func _process_move_repeat(delta: float) -> void:
	if is_movement_disabled or not repeat_move:
		return

	var held = get_held_direction()

	if held == Vector2.ZERO or held != _held_dir:
		# Released, or the held direction just changed - restart the delay.
		# (The initial move on a fresh press is already handled by _unhandled_input.)
		_held_dir = held
		_held_time = 0.0
		_repeating = false
		return

	_held_time += delta

	if not _repeating:
		if _held_time >= repeat_delay:
			_repeating = true
			_held_time = 0.0
			try_move(held)
	elif _held_time >= repeat_interval:
		_held_time -= repeat_interval
		try_move(held)

func move(dir):
	if movement_comp.is_moving():
		# Later to add it to the queue if it's already moving
		# For now, don't do anything while moving
		return
	
	movement_comp.turn_to_dir(dir)

	var grid_pos = Global.get_grid_pos(self)
	var new_grid_pos: Vector2 = grid_pos + dir
	var new_world_pos: Vector3 = Vector3(new_grid_pos.x, 0,new_grid_pos.y)
	
	var collider = Global.grid_check(new_grid_pos)
	var collider_02 = Global.grid_check(new_grid_pos, 2)
	
	facing_dir = dir
	
	movement_comp.jump_basic()
	
	if previous_collider != null:
		if previous_collider.has_method("un_hit"):
			#print(self.name, " is unhitting")
			previous_collider.un_hit(self)
			previous_collider = null
		if previous_collider.get_parent().has_method("un_hit"):
			#print(self.name, " is unhitting")
			previous_collider.get_parent().un_hit(self)
			previous_collider = null
			
	if collider != null:
		previous_collider = collider
		if collider.has_method("hit"):
			#print(self.name, " has hit something")
			collider.hit(self)
		if collider.get_parent().has_method("hit"):
			print(self.name, " has hit something")
			collider.get_parent().hit(self)
	
	if in_house:
		if dir != home_dir:
			print("Frog not facing the same direction as the home", Global.convert_rot_dir(GameManager.get_home().global_rotation.y))
			return
		else:
			in_house = false
			target_pos = new_world_pos
			movement_comp.set_move(new_world_pos)
	
	if collider_02 is Food:
		if collider != null:
			if collider.is_in_group("floor"):
				try_leap(get_height_diff(self, collider), new_world_pos)
				collider_02.eat()
				on_food_eaten(1)
			else:
				return
		#if self.position.y != 0:
			#return
		if get_height_diff(self, collider_02, false) <=0:
			collider_02.eat()
			on_food_eaten(1)
			movement_comp.set_move(new_world_pos)
		movement_comp.set_move(new_world_pos)
		return
	
	if collider_02 is Home:
		if get_height_diff(self, collider_02, false) <= 0:
			new_world_pos.y = self.position.y
			if dir != Vector2(home_dir.x*-1, home_dir.y*-1):
				print("Cannot enter this way")
				return
			print("The frog has entered home")
			self.rotation = collider_02.rotation
			facing_dir = convert_rot_dir()
			target_pos = new_world_pos
			movement_comp.set_move(new_world_pos)
			in_house = true
			#GameManager.check_win_condition()
		else:
			return
	
	if collider == null:
		target_pos = new_world_pos
		movement_comp.set_move(new_world_pos)
		return

	if collider.is_in_group("floor"):
		try_leap(get_height_diff(self, collider), new_world_pos)
		return

	if collider.is_in_group("wall"):
		print('wall!')
		return
	
	if collider.is_in_group("pushable"):
		if collider.push(dir):
			target_pos = new_world_pos
			movement_comp.set_move(new_world_pos)
	target_pos = new_world_pos
	movement_comp.set_move(new_world_pos)

func try_pull():
	var grid_pos_01 : Vector2 = Global.get_grid_pos(self) + (facing_dir)
	var grid_pos_02 : Vector2 = Global.get_grid_pos(self) + (facing_dir*2)
	var collider_01_01 = Global.grid_check(grid_pos_01)
	var collider_01_02 = Global.grid_check(grid_pos_02)
	var collider_02_01 = Global.grid_check(grid_pos_01, 2)
	var collider_02_02 = Global.grid_check(grid_pos_02, 2)
	
	print ("collider pull far: ", grid_pos_02,", ", collider_01_02)
	
	# anim check
	if collider_01_01 == null and collider_02_01 == null:
		if collider_01_02 == null and collider_02_02 == null:
			movement_comp.eat_far()
			return
	# checks for the far blocks
	if collider_01_02 != null:
		if collider_01_02.is_in_group("pullable"):
			movement_comp.eat_far()
			collider_01_02.push(facing_dir*-1)
			return
		if collider_01_02.is_in_group("wall"):
			movement_comp.eat_close()
	if collider_02_02 != null:
		if collider_02_02.is_in_group("food"):
			movement_comp.eat_far()
			if get_height_diff(self, collider_02_02, false) <= 0:
				collider_02_02.eat()
				on_food_eaten(1) # Arbitrary value currently
				return
	# checks for the close blocks
	if collider_01_01 != null:
		if collider_01_01.is_in_group("pullable"):
			movement_comp.eat_close()
			return
	if collider_02_01 != null:
		if collider_02_01.is_in_group("food"):
			movement_comp.eat_close()
			if get_height_diff(self, collider_02_01, false) <= 0:
				collider_02_01.eat()
				on_food_eaten(1) # Arbitrary value currently
				return

func on_food_eaten(value: int) -> void:
	food_eaten += value 
	emit_signal("food_count_changed", food_eaten)
	print("yummyy, current food count is ", food_eaten)

## Calculates the height difference
func get_height_diff(input: Node3D, collider: Node3D, check_collision_height:bool = true) -> float:
	if check_collision_height == false:
		print("height diff = ", collider.global_position.y - input.global_position.y)
		return(collider.global_position.y - input.global_position.y)
	for child in collider.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if check_collision_height:
				if shape is BoxShape3D:
					print("height diff = ", (shape.size.y + collider.global_position.y) - input.global_position.y)
					return (shape.size.y + collider.global_position.y) - input.global_position.y
				
	print("no collider with BoxShape found")
			
	return 0.0

func try_leap(height_diff: float, new_pos: Vector3) -> void:
	# Leaping down any height is fine; leaping up is capped at leapable_height.
	if height_diff > leapable_height:
		print("too high to leap: ", height_diff)
		return

	new_pos.y = self.position.y + height_diff
	target_pos = new_pos
	movement_comp.set_move(new_pos)

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

func movement_disable():
	is_movement_disabled = true
	
func movement_enable():
	is_movement_disabled = false

func texture_swap():
	pass

func _physics_process(delta: float) -> void:
	_process_move_repeat(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if !is_movement_disabled:
		var input_direction = get_input_direction()

		if Input.is_action_just_pressed("undo"):
			Global.undo()
		if input_direction != Vector2.ZERO:
			try_move(input_direction)
