extends Resource
class_name SystemData

var id : int
var name : String
var coords : Vector3

func print():
	print("[system %s at %s]" % [name, coords])
