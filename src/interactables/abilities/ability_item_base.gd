extends Food
class_name AbilityItem

@export var ability_component : AbilityComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

func give_ability()->Node:
	return ability_component
