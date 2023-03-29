extends Resource
class_name StarData

var id : int
var system_data : SystemData

var name : String
var coords : Vector3
var rel_mass : float
var rel_diameter : float
var spectral_class : String
var luminocity_class : String

var missing_data := false

func get_name():
	return "%s — %s" % [
		system_data.get_name(),
		name if name else "#%d" % id
	]
