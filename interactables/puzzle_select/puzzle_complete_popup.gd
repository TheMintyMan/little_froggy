extends CanvasLayer
class_name PuzzleCompletePopup

## How long the text takes to fade in, how long it stays on screen, and how long it takes to fade out.
@export var fade_in_time: float = 0.4
@export var hold_time: float = 1.5
@export var fade_out_time: float = 0.6

@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.modulate.a = 0.0

	# Fades in, holds, fades out, then removes itself
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(hold_time)
	tween.tween_property(label, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(queue_free)
