shader_type canvas_item;

uniform sampler2D positions_texture;

struct systemPos {
	int id;
	int ra_hr;
	int ra_min;
	float ra_sec;
	int dec_deg;
	int dec_arcmin;
	float dec_arcsec;
	float dist;
};

void fragment() {
	COLOR.a = 1.0;
    COLOR = vec4(UV.x, UV.y, 0.5, 1.0);
}