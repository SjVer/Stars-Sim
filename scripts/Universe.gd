extends Spatial

const unload_timeout := 10

# variables

var loaded_chunks := {}
var unready_chunks := {}
var unloaded_chunks := {}
var unloaded_chunks_epochs := {}

var star_count := 0

# functionality

func update_chunks():
	var chunk_pos : Vector3 = ($Player.translation / Chunk.abs_size).floor()
	
	var loaded_to_keep := []
	for x in [chunk_pos.x, chunk_pos.x - 1, chunk_pos.x + 1]:
		for y in [chunk_pos.y, chunk_pos.y - 1, chunk_pos.y + 1]:
			for z in [chunk_pos.z, chunk_pos.z - 1, chunk_pos.z + 1]:
				# keep existings chunks and generate new ones
				var pos := Vector3(x, y, z)
				if loaded_chunks.has(pos):
					loaded_to_keep.append(pos)
				elif not unready_chunks.has(pos):
					add_chunk(pos)

	# remove unused chunks
	for pos in loaded_chunks:
		if not pos in loaded_to_keep \
		and not pos in unready_chunks:
			# chunk is not within render distance and
			# it isn't being loaded but it does exist
			var chunk : Chunk = loaded_chunks[pos]
			loaded_chunks.erase(pos)
			star_count -= chunk.star_count

			# keep it around just in case
			unloaded_chunks[pos] = chunk
			unloaded_chunks_epochs[pos] = OS.get_ticks_msec()

	# remove old unloaded chunks
	var msec = OS.get_ticks_msec()
	for pos in unloaded_chunks:
		if (msec - unloaded_chunks_epochs[pos]) / 1000 > unload_timeout:
			var chunk : Chunk = unloaded_chunks[pos]
			unloaded_chunks.erase(pos)
			unloaded_chunks_epochs.erase(pos)
			chunk.queue_free()

func add_chunk(pos: Vector3):
	if unloaded_chunks.has(pos):
		load_done(pos, false, unloaded_chunks[pos])
	else:
		var thread := Thread.new()
		assert(thread.start(self, "load_chunk", pos, 0) == OK)
		unready_chunks[pos] = thread

func load_chunk(pos: Vector3):
	# no need to load bc Chunk has no children by default
	var chunk := Chunk.new()
	chunk.translation = pos * Chunk.abs_size
	chunk.chunk_pos = pos

	chunk.load_stars()
	call_deferred("load_done", pos, true, chunk)

func load_done(pos: Vector3, is_new: bool, chunk: Chunk):
	if is_new:
		unready_chunks[pos].wait_to_finish()
		unready_chunks.erase(pos)
		$Origin.add_child(chunk)
		chunk.owner = self
	else:
		unloaded_chunks_epochs.erase(pos)
		unloaded_chunks.erase(pos)

	loaded_chunks[pos] = chunk
	star_count += chunk.star_count

# handlers

func _process(_delta):
	# if $Player.translation.length() > 10:
	# 	$Origin.translation = -$Player.translation
	# 	$Player.translation = Vector3.ZERO

	$Label.text = "%d/27 chunks\n%d stars" % [$Origin.get_child_count(), star_count]
	update_chunks()

func _input(_event):
	if Input.is_action_pressed("quit"):
		print("quitting")
		OS.kill(OS.get_process_id())
