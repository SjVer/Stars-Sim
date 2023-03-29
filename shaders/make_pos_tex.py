import sqlite3 as sql
import struct
from PIL import Image

"""
TEXTURE STRUCTURE:
	per system:

"""

TEXTURE_FILE = "system_positions.png"
FIELDS = "id, ra_hr, ra_min, ra_sec, dec_deg, dec_arcmin, dec_arcsec, distance"
PIXELS_PER_ROW = 8

def encode():
	conn = sql.connect("../isdb_new.db")
	conn.row_factory = sql.Row
	rows = conn.execute(f"SELECT {FIELDS} FROM system_positions").fetchall()

	data = bytes()
	for row in rows:
		row_data = bytes()
		row_data += struct.pack("i", row["id"])
		row_data += struct.pack("i", row["ra_hr"])
		row_data += struct.pack("i", row["ra_min"])
		row_data += struct.pack("f", row["ra_sec"])
		row_data += struct.pack("i", row["dec_deg"])
		row_data += struct.pack("i", row["dec_arcmin"])
		row_data += struct.pack("f", row["dec_arcsec"])
		row_data += struct.pack("f", row["distance"])

		assert len(row_data) == 4 * PIXELS_PER_ROW
		data += row_data

	img = Image.frombytes("RGBA", (len(rows), PIXELS_PER_ROW), data, "raw")
	img.save(TEXTURE_FILE)

def decode():
	img = Image.open(TEXTURE_FILE)
	data = img.tobytes()

	for i in range(img.width):
		row_data = data[i * 4 * PIXELS_PER_ROW: (i + 1) * 4 * PIXELS_PER_ROW]
		row = {
			"id": 			struct.unpack("i", row_data[0*4: 0*4+4])[0],
			"ra_hr": 		struct.unpack("i", row_data[1*4: 1*4+4])[0],
			"ra_min": 		struct.unpack("i", row_data[2*4: 2*4+4])[0],
			"ra_sec": 		struct.unpack("f", row_data[3*4: 3*4+4])[0],
			"dec_deg": 		struct.unpack("i", row_data[4*4: 4*4+4])[0],
			"dec_arcmin": 	struct.unpack("i", row_data[5*4: 5*4+4])[0],
			"dec_arcsec": 	struct.unpack("f", row_data[6*4: 6*4+4])[0],
			"distance": 	struct.unpack("f", row_data[7*4: 7*4+4])[0],
		}
		print(row)

		# assert len(row_data) == 4 * PIXELS_PER_ROW
		# data += row_data

if __name__ == "__main__":
	encode()
	# decode()