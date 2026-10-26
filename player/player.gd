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

@export_group("Gap Jump")
## How many gap tiles (water or empty) in a row the frog can jump over.
## Wider than that, it lands in the gap and drowns or falls.
@export var gap_jump_tiles: int = 1
## A gap jump takes this many times longer than a normal hop.
@export var gap_jump_duration_scale: float = 1.6
## Arc height of a gap jump.
@export var gap_jump_height: float = 0.9
## Seconds the frog sits in the water before the level resets.
@export var drown_reset_delay: float = 0.6

@export_group("Tongue")
## How many tiles ahead the tongue reaches for food and pullables.
@export var pull_reach: int = 2

@export_group("Falling")
## Seconds the frog falls (as a rigid body) before the level resets.
@export var fall_duration: float = 2.0
## How fast the frog tumbles forward while falling.
@export var fall_tumble_speed: float = 3.0

var facing_dir: Vector2 = Vector2.ZERO
var in_house: bool = false
#var level_root: Level
#var main: Main
var home_dir
var target_pos: Vector3
var is_movement_disabled: bool = false
@onready var player_camera: Camera3D = %camera

var previous_collider: Node3D = null

# Where the frog was before each move, so undo can put it back however far it went.
var _undo_positions: Array[Vector3] = []

# Rigid body the frog follows while falling off an edge
var _fall_body: RigidBody3D = null

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
		v.y = -1
		v.x = 0
	if Input.is_action_just_pressed("playerUp"):
		v.y = 1
		v.x = 0
	if Input.is_action_just_pressed("playerRight"):
		v.x = -1
		v.y = 0
	if Input.is_action_just_pressed("playerLeft"):
		v.x = 1
		v.y= 0
	if Input.is_action_just_pressed("ability01"):
		try_pull()
	if Input.is_action_just_pressed("restart"):
		restart_level()

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
		v = Vector2(0, -1)
	if Input.is_action_pressed("playerUp"):
		v = Vector2(0, 1)
	if Input.is_action_pressed("playerRight"):
		v = Vector2(-1, 0)
	if Input.is_action_pressed("playerLeft"):
		v = Vector2(1, 0)
	return v

func try_move(dir: Vector2) -> void:
	if movement_comp.is_moving():
		# Later to add it to the queue if it's already moving
		# For now, don't do anything while moving (and don't record an undo step)
		return
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
	# Saved first so every "move" in the undo history has a position to go back to
	_undo_positions.append(global_position)

	movement_comp.turn_to_dir(dir)

	var grid_pos = Global.get_grid_pos(self)
	var new_grid_pos: Vector2 = grid_pos + dir
	var new_world_pos: Vector3 = Vector3(new_grid_pos.x, 0,new_grid_pos.y)

	# Look far enough ahead to see past the widest gap the frog can jump over
	var tiles = scan_tiles(dir, gap_jump_tiles + 1)
	var collider = tiles[0]["ground"]
	var collider_02 = tiles[0]["object"]
	var is_gap_jump = is_gap(collider)

	facing_dir = dir

	movement_comp.jump_basic()

	unhit_previous()
	if not is_gap_jump:
		hit_collider(collider)

	if in_house:
		if dir != home_dir:
			print("Frog not facing the same direction as the home", Global.convert_rot_dir(GameManager.get_home().global_rotation.y))
			return
		else:
			in_house = false
			target_pos = new_world_pos
			movement_comp.set_move(new_world_pos)

	if is_gap_jump:
		gap_jump(dir, tiles)
		return

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
	
	# A puzzle is started by pulling it, so the frog can't walk onto it
	if collider_02 is PuzzleSelect:
		return

	if collider_02 is Home:
		if not try_enter_home(collider_02, dir, new_world_pos):
			return
		new_world_pos.y = self.position.y

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

## Shoots the tongue out tile by tile, up to pull_reach. The first thing it reaches decides
## what happens: food is eaten, a puzzle starts, a pullable gets pulled one tile closer, a wall or anything
## sticking up above the frog stops it.
func try_pull():
	var tiles = scan_tiles(facing_dir, pull_reach, false)
	var stop_dist := 0

	for i in tiles.size():
		var dist = i + 1
		var ground = tiles[i]["ground"]
		var object = tiles[i]["object"]

		if ground != null and ground.is_in_group("pullable"):
			stop_dist = dist
			# Already right in front, nothing to pull
			if dist > 1:
				ground.push(facing_dir*-1)
			break

		if object is PuzzleSelect:
			stop_dist = dist
			object.start_puzzle()
			break

		if object != null and object.is_in_group("food") and get_height_diff(self, object, false) <= 0:
			stop_dist = dist
			object.eat()
			on_food_eaten(object.get_food_value()) # Arbitrary value currently
			break

		if blocks_tongue(ground):
			stop_dist = dist
			break

	# anim: eat_close if the tongue stopped on the tile right in front
	if stop_dist == 1:
		movement_comp.eat_close()
	else:
		movement_comp.eat_far()

## True if this tile's ground stops the tongue: a wall, or a floor sticking up above the frog.
## Water and empty tiles don't, so the tongue reaches across them.
func blocks_tongue(ground: Node3D) -> bool:
	if ground == null or is_water(ground):
		return false
	if ground.is_in_group("floor"):
		return get_height_diff(self, ground) > 0.05
	return true

func tile_at(grid_pos: Vector2) -> Dictionary:
	return {
		"ground": Global.grid_check(grid_pos),
		"object": Global.grid_check(grid_pos, 2),
	}
	
## Tiles from the frog outward along dir, up to max_dist. Stops after the first (non-water) wall
## unless stop_at_walls is false, in which case the caller decides what blocks it.
func scan_tiles(dir: Vector2, max_dist: int, stop_at_walls: bool = true) -> Array[Dictionary]:
	var tiles: Array[Dictionary]= []
	var grid_pos = Global.get_grid_pos(self)
	for i in max_dist:
		grid_pos += dir
		var tile = tile_at(grid_pos)
		tiles.append(tile)
		# Water is in the wall group too, but the frog can see (and jump) past it
		if stop_at_walls and tile["ground"] != null and tile["ground"].is_in_group("wall") and not is_water(tile["ground"]):
			break
	return tiles

func is_water(collider: Node3D) -> bool:
	return collider != null and collider.is_in_group("water")

## True for tiles the frog has to jump over: water, or no ground at all.
func is_gap(collider: Node3D) -> bool:
	return is_water(collider) or is_void(collider)

## Jumps over up to gap_jump_tiles of gap (water and/or empty tiles) and lands on the tile after it.
## Wider than that, the frog lands in the gap: water drowns it, empty tiles make it fall.
func gap_jump(dir: Vector2, tiles: Array[Dictionary]) -> void:
	var gap_count := 0
	while gap_count < tiles.size() and is_gap(tiles[gap_count]["ground"]):
		gap_count += 1

	var grid_pos = Global.get_grid_pos(self)

	if gap_count >= tiles.size():
		# Too wide, the frog jumps as far as it can and lands in the gap
		var far_grid_pos: Vector2 = grid_pos + dir * tiles.size()
		var far_ground: Node3D = tiles[-1]["ground"]
		if is_water(far_ground):
			drown(Vector3(far_grid_pos.x, far_ground.global_position.y, far_grid_pos.y))
		else:
			fall_off(dir, Vector3(far_grid_pos.x, 0, far_grid_pos.y), gap_jump_duration_scale, gap_jump_height)
		return

	var landing_grid_pos: Vector2 = grid_pos + dir * (gap_count + 1)
	var landing_pos: Vector3 = Vector3(landing_grid_pos.x, 0, landing_grid_pos.y)
	var ground: Node3D = tiles[gap_count]["ground"]
	var object: Node3D = tiles[gap_count]["object"]

	if object is Home:
		try_enter_home(object as Home, dir, landing_pos, gap_jump_duration_scale, gap_jump_height)
		return

	if ground != null:
		if not ground.is_in_group("floor"):
			print("nowhere to land across the gap")
			return
		# Leaping down across a gap is fine, leaping up isn't
		var height_diff = get_height_diff(self, ground)
		if height_diff > 0.05:
			print("too high to leap across the gap: ", height_diff)
			return
		landing_pos.y = self.position.y + height_diff

	hit_collider(ground)

	if object is Food:
		(object as Food).eat()
		on_food_eaten(1)

	target_pos = landing_pos
	movement_comp.set_move(landing_pos, gap_jump_duration_scale, gap_jump_height)

func drown(water_pos: Vector3) -> void:
	print("The frog fell in the water")
	movement_disable()
	target_pos = water_pos
	movement_comp.set_move(water_pos, gap_jump_duration_scale, gap_jump_height)
	while movement_comp.is_moving():
		await get_tree().process_frame
	await get_tree().create_timer(drown_reset_delay).timeout
	restart_level()

## True if there's no ground here and this level lets the frog fall off edges.
func is_void(collider: Node3D) -> bool:
	if collider != null:
		return false
	var level = GameManager.get_level()
	return level == null or level.can_fall_off

## Hops out over the edge, then hands the frog over to a rigid body so it falls, and resets the level.
func fall_off(dir: Vector2, world_pos: Vector3, duration_scale: float = 1.0, jump_height: float = -1.0) -> void:
	print("The frog fell off the edge")
	movement_disable()
	world_pos.y = self.position.y
	target_pos = world_pos
	movement_comp.set_move(world_pos, duration_scale, jump_height)
	while movement_comp.is_moving():
		await get_tree().process_frame

	# The player is a StaticBody3D, so a rigid body with the same shape does the falling
	# and the player copies its transform every physics frame (see _physics_process)
	var body := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = $CollisionShape3D.shape
	shape.transform = $CollisionShape3D.transform
	body.add_child(shape)
	get_parent().add_child(body)
	body.global_transform = global_transform
	body.add_collision_exception_with(self)
	var forward = Vector3(dir.x, 0, dir.y)
	body.linear_velocity = forward
	body.angular_velocity = Vector3.UP.cross(forward) * fall_tumble_speed
	_fall_body = body

	await get_tree().create_timer(fall_duration).timeout
	restart_level()

## Moves the frog into home if it's coming in from the open side. Returns false if it can't get in.
func try_enter_home(home: Home, dir: Vector2, world_pos: Vector3, duration_scale: float = 1.0, jump_height: float = -1.0) -> bool:
	if get_height_diff(self, home, false) > 0:
		return false
	if dir != Vector2(home_dir.x*-1, home_dir.y*-1):
		print("Cannot enter this way")
		return false
	print("The frog has entered home")
	world_pos.y = self.position.y
	self.rotation = home.rotation
	facing_dir = convert_rot_dir()
	target_pos = world_pos
	movement_comp.set_move(world_pos, duration_scale, jump_height)
	in_house = true
	#GameManager.check_win_condition()
	return true

func hit_collider(collider: Node3D) -> void:
	if collider == null:
		return
	previous_collider = collider
	if collider.has_method("hit"):
		#print(self.name, " has hit something")
		collider.hit(self)
	if collider.get_parent().has_method("hit"):
		print(self.name, " has hit something")
		collider.get_parent().hit(self)

func unhit_previous() -> void:
	if not is_instance_valid(previous_collider):
		previous_collider = null
		return
	if previous_collider.has_method("un_hit"):
		#print(self.name, " is unhitting")
		previous_collider.un_hit(self)
	if previous_collider.get_parent().has_method("un_hit"):
		#print(self.name, " is unhitting")
		previous_collider.get_parent().un_hit(self)
	previous_collider = null

func restart_level() -> void:
	get_tree().reload_current_scene()

func on_food_eaten(value: int) -> void:
	food_eaten += value 
	emit_signal("food_count_changed", food_eaten)
	print("yummyy, current food count is ", food_eaten)

## Sets the food counter back to zero (used when a puzzle starts)
func reset_food_count() -> void:
	food_eaten = 0
	emit_signal("food_count_changed", food_eaten)

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
					# The box is centred on its CollisionShape3D, so its top is half its (scaled) height above that
					var top = child.global_position.y + shape.size.y * 0.5 * child.global_transform.basis.get_scale().y
					print("height diff = ", top - input.global_position.y)
					return top - input.global_position.y
				
	print("no collider with BoxShape found")
			
	return 0.0

## True if the collider's top is level with the player (the same height try_leap would put the player at)
func is_same_height(collider: Node3D) -> bool:
	return absf(get_height_diff(self, collider, false)) < 0.05

func try_leap(height_diff: float, new_pos: Vector3) -> void:
	# Leaping down any height is fine; leaping up is capped at leapable_height.
	if height_diff > leapable_height:
		print("too high to leap: ", height_diff)
		return

	new_pos.y = self.position.y + height_diff
	target_pos = new_pos
	movement_comp.set_move(new_pos)

func undo_move(_dir):
	if _undo_positions.is_empty():
		return
	movement_comp.stop_move()
	Global.move_to_grid_pos(self, _undo_positions.pop_back())
	
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
	if _fall_body != null:
		global_transform = _fall_body.global_transform
		return
	_process_move_repeat(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if !is_movement_disabled:
		var input_direction = get_input_direction()

		if Input.is_action_just_pressed("undo"):
			Global.undo()
		if input_direction != Vector2.ZERO:
			try_move(input_direction)
