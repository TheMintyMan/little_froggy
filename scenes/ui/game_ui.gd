extends Control

@onready var leap_label = $Leap_Count
@onready var level = get_tree().current_scene
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	##var player = level.get_player()
	##player.leap_count_changed.connect(_on_update_leap)

func _on_update_leap(leap_count: int) -> void:
	leap_label.text = "Leaps Left: " + str(leap_count)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
