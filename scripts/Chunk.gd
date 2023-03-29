extends Spatial
class_name Chunk

const abs_size := Constants.chunk_size * Constants.distance_scale

var loaded := false
var chunk_pos : Vector3
var star_count := 0

func load_stars():
	loaded = false
	var system_datas = Database.find_systems_in_chunk(chunk_pos)
	for system_data in system_datas:
		# TODO: returns first component only
		var star_data : StarData = Database.get_star_data(system_data)
		if star_data.missing_data:
			continue

		var star = preload("res://scenes/Star.tscn").instance()
		star.configure(star_data, translation)
		add_child(star)
		star.owner = self

		star_count += 1
	loaded = true

func _process(_delta):
	if OS.is_debug_build():
		var color := Color.green
		if not loaded: color = Color.yellow
		if not visible: color = Color.blue

		DebugDraw.draw_box(
			translation,
			Vector3.ONE * abs_size,
			color.darkened(0.5)
		)
