extends Spatial
class_name Chunk

const abs_size := Constants.chunk_size * Constants.distance_scale

var loaded := false
var chunk_pos : Vector3
var star_count := 0

func load_stars():
	var star_ids := Database.find_stars_in_chunk(chunk_pos)
	for id in star_ids:
		var star_data := Database.get_star_data(id)
		if not star_data.is_valid(): continue

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
