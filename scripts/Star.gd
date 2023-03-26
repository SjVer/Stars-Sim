tool
extends CSGSphere
class_name Star

# NOTE:
# 	distance is in light-years
#	size is in solar radii

const size_scale := 1
const coords_scale := 50

var star_data := StarData.new()

# tool functionality

const exp_props = [
	"id", "name", "comp_name", "coords",
	"rel_mass", "rel_diameter", "spectral_class"
]
func _get_property_list():
	var props := []

	props.append({
		name = "Star Data",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	for p in star_data.get_property_list():
		if p["name"] in exp_props:
			props.append({
				name = p["name"],
				type = p["type"],
				usage = PROPERTY_USAGE_DEFAULT
			})
	return props

func _get(property):
	if property in exp_props:
		return star_data.get(property)
		
# functionality

func configure(data: StarData):
	star_data = data

	name = "Star #%d" % data.id
	radius = data.rel_diameter / 2.0 * size_scale
	# $Mesh.mesh.radius = radius
	# $Mesh.mesh.height = radius * 2
	# $Collider.shape.radius = radius
	translation = data.coords * coords_scale

	# see http://www.vendian.org/mncharity/dir3/starcolor/
	match data.spectral_class[0]:
		"O": material.albedo_color = Color(155, 176, 255)
		"B": material.albedo_color = Color(170, 191, 255)
		"A": material.albedo_color = Color(202, 215, 255)
		"F": material.albedo_color = Color(248, 247, 255)
		"G": material.albedo_color = Color(255, 244, 234)
		"K": material.albedo_color = Color(255, 210, 161)
		"M": material.albedo_color = Color(255, 204, 111)
		"D": material.albedo_color = Color.white
		_: printerr("unknown spectral class ", data.spectral_class)
	material.emission = material.albedo_color

# handlers

func _process(_delta):
	var cam := get_viewport().get_camera()
	var pos_3d := global_transform.origin + Vector3.UP * star_data.rel_diameter / 2
	var pos_2d := cam.unproject_position(pos_3d)

	var center_dist := pos_2d.distance_to(get_viewport().size / 2)
	if cam.is_position_behind(pos_3d) or center_dist > 200:
		$Label.hide()
		return
	else:
		$Label.show()

	var color := Color.red if star_data.id != 100 else Color.green
	color.a = 1 - center_dist / 200
	$Label.add_color_override("font_color", color)
	$Label.text = "%s (%.2f ly)" % [
		"#%d" % star_data.id if star_data.missing_name else star_data.name,
		global_transform.origin.distance_to(cam.global_transform.origin) / coords_scale
	]

	var offset = Vector2(-$Label.rect_size.x / 2, $Label.rect_size.y / 2 - 20)
	$Label.rect_position = pos_2d + offset
