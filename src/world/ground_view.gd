class_name GroundView
extends Node2D
## Zeichnet den Boden: eine Maske (1 Pixel je Zelle, weich gefiltert) entscheidet im Shader
## zwischen grauem und grünem Boden. Rauschen im Shader macht die Grenze organisch.
## Prinzip aus Scrap Empire (DirtView). Die Maske wird höchstens 30× pro Sekunde hochgeladen.

const SHADER := """
shader_type canvas_item;
uniform sampler2D mask : filter_linear, repeat_disable;
uniform vec2 map_size;
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// Hash ohne sin(): auf GPUs mit geringer Genauigkeit stabil (sonst harte Kanten im Rauschen)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = local_pos;
	float m = texture(mask, p / map_size).r;
	float big = vnoise(p / 46.0);
	float small = vnoise(p / 9.0);
	float v = m + (big * 0.6 + small * 0.4 - 0.5) * 0.55;
	float g = smoothstep(0.44, 0.56, v);
	// Trocken: helles, warmes Grau mit Flecken – trist, aber nie dunkel
	vec3 dry = mix(vec3(0.66, 0.64, 0.60), vec3(0.77, 0.75, 0.70), big) + (small - 0.5) * 0.07;
	// Grün: saftig, mit helleren Flecken
	vec3 lush = mix(vec3(0.40, 0.72, 0.30), vec3(0.56, 0.84, 0.36), big) + (small - 0.5) * 0.09;
	vec3 col = mix(dry, lush, g);
	// Heller gelbgrüner Saum an der Wachstumsgrenze
	float rim = smoothstep(0.30, 0.50, v) - smoothstep(0.50, 0.72, v);
	col = mix(col, vec3(0.82, 0.92, 0.48), rim * 0.55);
	COLOR = vec4(col, 1.0);
}
"""
const UPLOAD_SECONDS := 1.0 / 30.0
const BORDER_COLOR := Color(0.50, 0.54, 0.60)

var _grid: GroundGrid
var _size_px := Vector2.ZERO
var _img: Image
var _tex: ImageTexture
var _timer := 0.0


func bind(grid: GroundGrid, cell_px: float) -> void:
	_grid = grid
	_size_px = Vector2(grid.width, grid.height) * cell_px
	_img = Image.create_from_data(grid.width, grid.height, false, Image.FORMAT_R8, grid.cells)
	_tex = ImageTexture.create_from_image(_img)
	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("mask", _tex)
	mat.set_shader_parameter("map_size", _size_px)
	material = mat
	grid.take_dirty()
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, _size_px), Color.WHITE)


func _process(delta: float) -> void:
	if _grid == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if _grid.take_dirty().has_area():
		_timer = UPLOAD_SECONDS
		# Ganze Maske neu setzen: bei 320×240 sind das 77 KB, billiger als Pixel einzeln zu schreiben.
		_img.set_data(_grid.width, _grid.height, false, Image.FORMAT_R8, _grid.cells)
		_tex.update(_img)
