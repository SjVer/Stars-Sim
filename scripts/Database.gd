tool
extends Node

var sql = SQLiteWrapper.new()
const print_errs := false

func _init():
	sql.set_path("res://isdb")
	assert(sql.open_db())

func calculate_coords(
	ra_h: float, ra_m: float, ra_s: float,
	dec_d: float, dec_m: float, dec_s: float,
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

func find_neighbors(coords: Vector3, distance: float) -> PoolIntArray:
	# get all positions
	sql.query("""
		SELECT RA_hr, RA_min, RA_sec, Dec_deg, Dec_arcmin,
		Dec_arcsec, Distance, OwnerID FROM Positions
		ORDER BY Distance
	""")

	# find close stars
	var star_ids := PoolIntArray()
	for d in sql.query_result:
		var id : int = d["OwnerID"].to_int()

		# filter out invalid stars
		if id % 100 != 0:
			continue

		var star_coords := calculate_coords(
			d["RA_hr"].to_float(),
			d["RA_min"].to_float(),
			d["RA_sec"].to_float(),
			d["Dec_deg"].to_float(),
			d["Dec_arcmin"].to_float(),
			d["Dec_arcsec"].to_float(),
			d["Distance"].to_float()
		)

		if coords.distance_to(star_coords) <= distance:
			star_ids.push_back(id)

	return star_ids

func try_single_query(query: String, default):
	if not sql.query(query):
		return default
	elif sql.query_result.size() == 0:
		return default
	else:
		return sql.query_result[0]

const m_per_ly := 9460700000000000.0
const solar_radius := 695700000.0
func calculate_rel_diameter(arcsecs: float, distance: float) -> float:
	# see https://en.wikipedia.org/wiki/Angular_diameter_distance
	return (
		(arcsecs * (distance * m_per_ly))
			/ 206265
			/ (2 * solar_radius)
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
		
		data.missing_components = false
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