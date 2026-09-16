extends Node3D

signal pressed
signal released

var pressed_count = 0

func on_pressed():
	emit_signal("pressed")

func on_released():
	emit_signal("released")

func _on_area_3d_area_entered(_area: Area3D) -> void:
	if pressed_count == 0:
		on_pressed()
	pressed_count += 1

func _on_area_3d_area_exited(_area: Area3D) -> void:
	pressed_count -= 1
	assert(pressed_count >= 0)
	
	if pressed_count == 0:
		on_released()
