extends Resource
class_name StarData

var id : int

var name : String
var comp_name : String
var coords : Vector3
var rel_mass : float
var rel_diameter : float
var spectral_class : String

var missing_name : bool
var missing_coords : bool
var missing_components : bool
var missing_spectral : bool

func _init():
	missing_name = true
	missing_coords = true
	missing_components = true
	missing_spectral = true

func is_valid():
	return not missing_coords \
	and not missing_components

func print():
	if missing_name:
		print("[#%d at %s]" % [id, coords])
	else:
		print("[%s at %s]" % [name, coords])
