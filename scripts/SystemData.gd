extends Resource
class_name SystemData

var id : int
var name : String
var coords : Vector3
var distance : float
var system_data : SystemData

func get_name() -> String:
	return name if name else "#%d" % id