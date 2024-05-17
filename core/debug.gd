extends Node

var out:
	set(value):
		out_queue.append(value)

var out_queue: Array[Variant] = []

var active: bool = true

func _process(delta):
	if not active: return
	
	while out_queue.size() > 0:
		var value = out_queue.pop_front()
		print_rich(get_debug_string(value))

func get_debug_string(value):
	var prefix = "[color=yellow][b]DEBUG[/b][/color]"
	return prefix + " " + str(value)
