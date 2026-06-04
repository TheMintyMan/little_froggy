extends Object
class_name ActionManager

var action_dict = {} # {action_name: [do_action(), undo_action()]}
var action_history = [] # [ [action_name, [parameters], time_idx], ...]
#var action_index = -1

func _init(_action_dict:Dictionary) -> void:
	action_dict = _action_dict
	
	#Global.connect("do_undo", undo_action)
	Global.do_undo.connect(undo_action)

func do_action(action_name:String, params:Array):
	action_dict[action_name][0].callv(params)
	
	#if action_index != action_history.size()-1:
		#action_history = action_history.slice(0, action_index + 1)
		
	action_history.append([action_name, params, Global.time_index])
	#action_index += 1
	

func undo_action():
	if action_history.is_empty():
	#if action_index == -1:
		return
	#action_index -= 1
	if action_history[action_history.size() - 1][2] != Global.time_index:
		return
	var historic_action = action_history.pop_back()
	
	
	var action_entry = action_dict[historic_action[0]]
	action_entry[1].callv(historic_action[1])
