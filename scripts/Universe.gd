tool
extends Spatial

# tool functionality

export(float) var distance = 15.0

export(bool) var reload = false setget _on_reload
func _on_reload(_reload):
	reload = false
	reload_stars()

export(bool) var clear = false setget _on_clear
func _on_clear(_clear):
	clear = false
	clear_stars()

# functionality

func clear_stars():
	for star in $Origin.get_children():
		$Origin.remove_child(star)
		star.queue_free()

func reload_stars(_data = null):
	clear_stars()

	var coords := Vector3.ZERO
	var star_ids := Database.find_neighbors(coords, distance)
	print_debug("found %d star ID's" % star_ids.size())
	for id in star_ids:
		var star_data := Database.get_star_data(id)
		if not star_data.is_valid(): continue

		var star = preload("res://scenes/Star.tscn").instance()
		star.configure(star_data)
		$Origin.add_child(star)
		star.owner = self

		$Label.text = "%d stars" % $Origin.get_child_count()
	
	print_debug("stars reloaded")

var thread : Thread	
func reload_stars_async():
	thread = Thread.new()
	thread.start(self, "reload_stars")

# handlers

func _ready():
	if not Engine.editor_hint:
		reload_stars_async()
		# reload_stars()
