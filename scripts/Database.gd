tool
extends Node

# NOTE:
# 	the following can be used for table migration:
#	```sql
#	UPDATE system_positions
#	SET
#	  new_col 	= (SELECT CAST(p.OldCOl AS NEW_TYPE) FROM OldTable p WHERE CAST(p.OwnerID AS INTEGER) = id),
#	  ...
#	WHERE id IN (SELECT CAST(p.OwnerID AS INTEGER) FROM Positions p)
#	```

var sql = SQLiteWrapper.new()
var mutex := Mutex.new()

const print_errs := true

func _init():
	sql.set_path("res://isdb_new")
	assert(sql.open_db())

func calculate_coords(
	ra_h: int, ra_m: int, ra_s: float,
	dec_d: int, dec_m: int, dec_s: float,
	dist: float
) -> Vector3:
	var a := ra_h * 15 + ra_m * 0.25 + ra_s * 0.004166
	var dec_sign := 1 if dec_d >= 0 else -1
	var b := (abs(dec_d) + (dec_m / 60) + (dec_s / 3600)) * dec_sign

	return Vector3(
		dist * cos(b) * cos(a),
		dist * cos(b) * sin(a),
		dist * sin(b)
	)

func is_inside(vmin: Vector3, vmax: Vector3, v: Vector3) -> bool:
	return vmin.x <= v.x and vmax.x > v.x \
	   and vmin.y <= v.y and vmax.y > v.y \
	   and vmin.z <= v.z and vmax.z > v.z

func find_stars_in_chunk(chunk_pos: Vector3) -> PoolIntArray:
	var chunk_min_coord := chunk_pos * Constants.chunk_size
	var chunk_max_coord := (chunk_pos + Vector3.ONE) * Constants.chunk_size

	# get all positions
	mutex.lock()
	sql.query("""
		SELECT ra_hr, ra_min, ra_sec, dec_deg, dec_arcmin,
		dec_arcsec, distance, id FROM system_positions
	""")
	var data = sql.query_result
	mutex.unlock()

	# find close stars
	var star_ids := PoolIntArray()
	for d in data:
		var id : int = d["id"]

		# filter out invalid stars
		if id % 100 != 0:
			continue
			
		var star_coords := calculate_coords(
			d["ra_hr"],
			d["ra_min"],
			d["ra_sec"],
			d["dec_deg"],
			d["dec_arcmin"],
			d["dec_arcsec"],
			d["distance"]
		)

		if is_inside(chunk_min_coord, chunk_max_coord, star_coords):
			star_ids.push_back(id)
	
	return star_ids

func try_single_query(query: String, default):
	mutex.lock()

	var result = default
	if sql.query(query) and sql.query_result.size():
		result = sql.query_result[0]

	mutex.unlock()
	return result

func calculate_rel_diameter(arcsecs: float, distance: float) -> float:
	# see https://en.wikipedia.org/wiki/Angular_diameter_distance
	return (
		(arcsecs * (distance * Constants.m_per_ly))
			/ 206265
			/ (2 * Constants.solar_radius)
	)

func get_star_data(id: int) -> StarData:
	var data := StarData.new()
	data.id = id

	# name
	var name_data = try_single_query("""
		SELECT Name FROM ProperNames
		WHERE (OwnerID / 100) = %d AND IsSystemName = \"True\"
	""" % (id / 100), null)
	if name_data:
		data.name = name_data["Name"]
		data.missing_name = false
	elif print_errs:
		printerr("No name for system #%d" % id)
	
	# coordinates
	var pos_data = try_single_query("""
		SELECT RA_hr, RA_min, RA_sec, Dec_deg, Dec_arcmin,
		Dec_arcsec, Distance FROM Positions WHERE OwnerID=\"%d\"
	""" % id, null)
	if pos_data:
		data.coords = calculate_coords(
			pos_data["RA_hr"].to_float(),
			pos_data["RA_min"].to_float(),
			pos_data["RA_sec"].to_float(),
			pos_data["Dec_deg"].to_float(),
			pos_data["Dec_arcmin"].to_float(),
			pos_data["Dec_arcsec"].to_float(),
			pos_data["Distance"].to_float()
		)
		data.missing_coords = false
	elif print_errs:
		printerr("No coordinates for system #d", id)

	# components
	# TODO: One system might have more components
	#		we're ignoring those now!
	var comp_data = try_single_query("""
		SELECT * FROM Components WHERE
		CAST(ID as INTEGER) > %d AND CAST(ID as INTEGER) <= %d
	""" % [id, id + 9], null)
	if comp_data:
		data.comp_name = comp_data["Name"]
		data.rel_mass = comp_data["Mass"].to_float()

		if comp_data["IsDiameterArcsec"] == "True":
			data.rel_diameter = calculate_rel_diameter(
				comp_data["Diameter"].to_float(),
				pos_data["Distance"].to_float()
			)
		else:
			data.rel_diameter = comp_data["Diameter"].to_float()

		# temporary
		if data.missing_name:
			data.name = "#%d %s" % [id, data.comp_name]
			data.missing_name = false
		
		data.missing_components = data.rel_diameter <= 0
	elif print_errs:
		printerr("No components for star #%d" % id)

	# spectral data
	var spec_id = comp_data["ID"] if comp_data else id
	var spec_data = try_single_query("""
		SELECT SpectralClass FROM Spectra
		WHERE OwnerID = \"%s\"
	""" % spec_id, null)
	if spec_data:
		data.spectral_class = spec_data["SpectralClass"]
		data.missing_spectral = false
	elif print_errs:
		printerr("No spectral data for star #%d (#%s)" % id)

	return data
