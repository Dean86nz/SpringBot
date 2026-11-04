extends Node2D
## Zeichnet den Stil-Vorschlag (siehe style_preview.gd). Alles von oben gesehen, im Stil
## von Roboter und Bienen: flache Farben, weiche dunkle Umrisse, Schatten nach rechts unten.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const FLOWER_COLORS := [
	Color(1.0, 0.56, 0.69), Color(1.0, 0.85, 0.30), Color(1.0, 1.0, 0.96), Color(0.72, 0.55, 0.95),
	Color(1.0, 0.45, 0.35), Color(0.55, 0.75, 1.0), Color(1.0, 0.66, 0.30),
]

var _rng := RandomNumberGenerator.new()
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_rng.seed = 7


func _draw() -> void:
	_grey_texture()
	_green_variety()
	# Tote Objekte links, erwachte rechts, jeweils in derselben Zeile
	_dead_tree(Vector2(470, 190))
	_tree_bloom(Vector2(1300, 190))
	_dry_pond(Vector2(420, 450))
	_pond(Vector2(1290, 460))
	_frog(Vector2(1395, 520))
	_wilted_bush(Vector2(470, 700))
	_bush_berries(Vector2(1300, 700))
	_rock(Vector2(450, 930), false)
	_rock(Vector2(1290, 930), true)
	_butterfly(Vector2(1640, 200), 0.4, Color(1.0, 0.62, 0.25))
	_butterfly(Vector2(1760, 290), -0.6, Color(0.55, 0.75, 1.0))
	_bird(Vector2(1660, 500), -0.5)
	_hare(Vector2(1700, 790), 2.6)
	_labels()


# --- Graue Welt: Risse, Steinchen, trockene Halme ---

func _grey_texture() -> void:
	for i in 26:
		var p := Vector2(_rng.randf_range(40, 820), _rng.randf_range(40, 1040))
		var pts := PackedVector2Array([p])
		var dir := _rng.randf() * TAU
		for k in 5:
			dir += _rng.randf_range(-0.7, 0.7)
			pts.append(pts[-1] + Vector2.from_angle(dir) * _rng.randf_range(10, 22))
		draw_polyline(pts, Color(0.48, 0.46, 0.43, 0.7), 2.0)
		if _rng.randf() < 0.5:
			var b := pts[2]
			draw_line(b, b + Vector2.from_angle(dir + 1.2) * 14.0, Color(0.48, 0.46, 0.43, 0.6), 1.5)
	for i in 60:
		var p := Vector2(_rng.randf_range(30, 840), _rng.randf_range(30, 1050))
		var r := _rng.randf_range(2.5, 6.0)
		draw_circle(p + Vector2(1.5, 2), r, SHADOW)
		draw_circle(p, r, Color(0.60, 0.58, 0.55).lerp(Color(0.78, 0.76, 0.72), _rng.randf()))
	for i in 34:
		var p := Vector2(_rng.randf_range(30, 840), _rng.randf_range(30, 1050))
		for k in 4:
			var a := -PI * 0.5 + _rng.randf_range(-0.9, 0.9)
			draw_line(p, p + Vector2.from_angle(a) * _rng.randf_range(8, 15), Color(0.62, 0.55, 0.42), 1.6)


# --- Grün: Farbflecken, Grasbüschel, Blumen; rechts außen „älteres“, üppiges Grün ---

func _green_variety() -> void:
	for i in 70:
		var p := Vector2(_rng.randf_range(920, 1900), _rng.randf_range(20, 1060))
		var tone := [Color(0.30, 0.62, 0.26, 0.20), Color(0.70, 0.88, 0.38, 0.18), Color(0.48, 0.74, 0.28, 0.20)][i % 3] as Color
		var r := _rng.randf_range(30, 70)
		for k in 3:
			draw_circle(p + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-20, 20)), r * (1.0 - k * 0.25), tone)
	for i in 260:
		var x := _rng.randf_range(920, 1900)
		var lush := clampf((x - 1450.0) / 450.0, 0.0, 1.0)   # rechts: länger grün = üppiger
		if _rng.randf() > 0.25 + lush * 0.75:
			continue
		_tuft(Vector2(x, _rng.randf_range(20, 1060)))
	for i in 300:
		var x := _rng.randf_range(920, 1900)
		var lush := clampf((x - 1450.0) / 450.0, 0.0, 1.0)
		if _rng.randf() > 0.06 + lush * 0.94:
			continue
		_flower(Vector2(x, _rng.randf_range(20, 1060)), FLOWER_COLORS[_rng.randi() % FLOWER_COLORS.size()], _rng.randf_range(5.0, 8.0))


func _tuft(p: Vector2) -> void:
	var c := Color(0.28, 0.58, 0.22).lerp(Color(0.55, 0.80, 0.30), _rng.randf())
	for k in 5:
		var a := -PI * 0.5 + (k - 2) * 0.35 + _rng.randf_range(-0.1, 0.1)
		draw_line(p, p + Vector2.from_angle(a) * _rng.randf_range(12, 22), c, 3.0)


func _flower(p: Vector2, c: Color, s: float) -> void:
	for k in 5:
		draw_circle(p + Vector2.from_angle(k * TAU / 5.0) * s * 0.9, s * 0.75, c)
	draw_circle(p, s * 0.55, Color(1.0, 0.85, 0.30) if c.b < 0.9 or c.r < 0.9 else Color(1.0, 0.75, 0.25))


# --- Bäume ---

func _dead_tree(p: Vector2) -> void:
	_shadow(p, 70.0)
	draw_circle(p, 14.0, Color(0.50, 0.42, 0.34))
	var bark := Color(0.48, 0.40, 0.32)
	for k in 7:
		var a := k * TAU / 7.0 + 0.3
		var tip := p + Vector2.from_angle(a) * 62.0
		draw_line(p, tip, bark, 6.0)
		draw_line(p.lerp(tip, 0.6), p.lerp(tip, 0.6) + Vector2.from_angle(a + 0.7) * 22.0, bark, 3.5)
		draw_line(tip, tip + Vector2.from_angle(a - 0.5) * 14.0, bark, 2.5)
	draw_arc(p, 14.0, 0, TAU, 24, INK, 3.0)


func _tree_bloom(p: Vector2) -> void:
	_shadow(p, 80.0)
	for k in 9:
		var q := p + Vector2.from_angle(k * TAU / 9.0) * 46.0
		draw_circle(q, 34.0, Color(0.36, 0.66, 0.30))
	draw_circle(p, 50.0, Color(0.44, 0.74, 0.34))
	for k in 9:
		draw_arc(p + Vector2.from_angle(k * TAU / 9.0) * 46.0, 34.0, k * TAU / 9.0 - 1.3, k * TAU / 9.0 + 1.3, 12, INK, 3.0)
	for i in 34:
		var q := p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0, 70)
		_flower(q, Color(1.0, 0.72, 0.84) if i % 3 else Color(1.0, 0.97, 0.98), 4.5)


# --- Teiche ---

func _dry_pond(p: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(1.5, 1.0))
	draw_circle(Vector2.ZERO, 70.0, Color(0.58, 0.52, 0.44))
	draw_circle(Vector2.ZERO, 58.0, Color(0.68, 0.61, 0.50))
	draw_arc(Vector2.ZERO, 70.0, 0, TAU, 40, Color(0.46, 0.40, 0.34), 3.0)
	draw_set_transform(Vector2.ZERO)
	for i in 9:
		var a := _rng.randf() * TAU
		var q := p + Vector2(cos(a) * 20, sin(a) * 12)
		draw_line(q, q + Vector2(cos(a) * 55, sin(a) * 34), Color(0.50, 0.44, 0.36), 2.0)


func _pond(p: Vector2) -> void:
	draw_set_transform(p, 0.0, Vector2(1.5, 1.0))
	draw_circle(Vector2.ZERO, 74.0, Color(0.62, 0.78, 0.42))
	draw_circle(Vector2.ZERO, 66.0, Color(0.40, 0.68, 0.88))
	draw_circle(Vector2(-14, -12), 40.0, Color(0.52, 0.78, 0.94))
	draw_arc(Vector2.ZERO, 66.0, 0, TAU, 40, INK, 3.0)
	draw_set_transform(Vector2.ZERO)
	for q in [Vector2(-50, 10), Vector2(30, -25), Vector2(55, 20), Vector2(-15, 30)]:
		draw_circle(p + q, 14.0, Color(0.36, 0.66, 0.30))
		draw_colored_polygon(PackedVector2Array([p + q, p + q + Vector2(16, -5), p + q + Vector2(16, 5)]), Color(0.40, 0.68, 0.88))
	_flower(p + Vector2(-50, 10), Color(1.0, 0.62, 0.78), 5.0)
	_flower(p + Vector2(55, 20), Color(1.0, 0.97, 0.98), 5.0)


# --- Büsche ---

func _wilted_bush(p: Vector2) -> void:
	_shadow(p, 46.0)
	for k in 6:
		var q := p + Vector2.from_angle(k * TAU / 6.0) * 22.0
		draw_circle(q, 22.0, Color(0.58, 0.55, 0.40))
		draw_arc(q, 22.0, 0, TAU, 20, Color(0.45, 0.42, 0.32), 2.0)
	draw_circle(p, 20.0, Color(0.62, 0.58, 0.42))


func _bush_berries(p: Vector2) -> void:
	_shadow(p, 50.0)
	for k in 6:
		var q := p + Vector2.from_angle(k * TAU / 6.0) * 24.0
		draw_circle(q, 25.0, Color(0.30, 0.60, 0.28))
		draw_arc(q, 25.0, k * TAU / 6.0 - 1.4, k * TAU / 6.0 + 1.4, 12, INK, 3.0)
	draw_circle(p, 26.0, Color(0.38, 0.68, 0.32))
	for i in 16:
		var q := p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5, 40)
		draw_circle(q, 4.5, Color(0.88, 0.18, 0.30))
		draw_circle(q + Vector2(-1.3, -1.3), 1.4, Color(1, 1, 1, 0.8))


# --- Felsen ---

func _rock(p: Vector2, moss: bool) -> void:
	var pts := PackedVector2Array()
	for k in 9:
		pts.append(p + Vector2.from_angle(k * TAU / 9.0) * Vector2(66, 48) * (0.85 + 0.15 * sin(k * 2.3)))
	var sh := PackedVector2Array()
	for q in pts:
		sh.append(q + Vector2(6, 9))
	draw_colored_polygon(sh, SHADOW)
	draw_colored_polygon(pts, Color(0.66, 0.66, 0.68))
	draw_circle(p + Vector2(-14, -12), 22.0, Color(0.76, 0.76, 0.78))
	pts.append(pts[0])
	draw_polyline(pts, INK, 3.0)
	if moss:
		for i in 14:
			var q := p + Vector2(_rng.randf_range(-40, 30), _rng.randf_range(-30, 8))
			draw_circle(q, _rng.randf_range(7, 13), Color(0.42, 0.70, 0.30).lerp(Color(0.60, 0.82, 0.36), _rng.randf()))
		_flower(p + Vector2(10, -16), Color(1.0, 1.0, 0.96), 4.0)


# --- Tiere (ANIMAL = Größe im Verhältnis zum Roboter) ---

const ANIMAL := 1.7


func _tf(p: Vector2, a: float, sc: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(p, a, sc * ANIMAL)


func _butterfly(p: Vector2, a: float, c: Color) -> void:
	_tf(p + Vector2(14, 24), a)
	draw_circle(Vector2.ZERO, 9.0, SHADOW)
	_tf(p, a)
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(-4, 9 * s), 9.0, c)
		draw_circle(Vector2(6, 7 * s), 6.5, c.lightened(0.3))
		draw_circle(Vector2(-4, 9 * s), 3.0, Color(1, 1, 1, 0.7))
	draw_line(Vector2(-10, 0), Vector2(10, 0), INK, 3.0)
	draw_set_transform(Vector2.ZERO)


func _bird(p: Vector2, a: float) -> void:
	_tf(p + Vector2(26, 44), a)
	draw_circle(Vector2.ZERO, 12.0, SHADOW)
	_tf(p, a)
	for s in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(4, 0), Vector2(-8, 26 * s), Vector2(-14, 20 * s), Vector2(-6, 0)]), Color(0.45, 0.62, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-22, -6), Vector2(-22, 6)]), Color(0.40, 0.55, 0.78))
	_tf(p, a, Vector2(1.6, 1.0))
	draw_circle(Vector2.ZERO, 8.0, Color(0.55, 0.72, 0.92))
	_tf(p, a)
	draw_circle(Vector2(10, 0), 6.5, Color(0.55, 0.72, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(15, -2.5), Vector2(22, 0), Vector2(15, 2.5)]), Color(1.0, 0.70, 0.25))
	draw_circle(Vector2(12, -3), 1.6, INK)
	draw_circle(Vector2(12, 3), 1.6, INK)
	draw_set_transform(Vector2.ZERO)


## Hase von oben: Körper, Kopf vorne, lange Ohren nach hinten angelegt, weißes Schwänzchen.
func _hare(p: Vector2, a: float) -> void:
	var fur := Color(0.80, 0.68, 0.54)
	_tf(p + Vector2(6, 9), a, Vector2(1.4, 1.0))
	draw_circle(Vector2.ZERO, 15.0, SHADOW)
	_tf(p, a)
	for s in [-1.0, 1.0]:
		draw_colored_polygon(_ellipse(Vector2(4, 7 * s), Vector2(15, 4.5), 0.25 * s), fur.darkened(0.08))
		draw_colored_polygon(_ellipse(Vector2(4, 7 * s), Vector2(11, 2.2), 0.25 * s), Color(1.0, 0.76, 0.80))
	draw_colored_polygon(_ellipse(Vector2(-12, 0), Vector2(17, 13), 0.0), fur)
	draw_circle(Vector2(14, 0), 9.0, fur)
	draw_circle(Vector2(-29, 0), 5.0, Color(1, 1, 1))
	draw_circle(Vector2(18, -4.5), 1.8, INK)
	draw_circle(Vector2(18, 4.5), 1.8, INK)
	draw_circle(Vector2(23, 0), 1.8, Color(0.85, 0.5, 0.55))
	draw_set_transform(Vector2.ZERO)


func _frog(p: Vector2) -> void:
	var g := Color(0.45, 0.78, 0.30)
	_tf(p + Vector2(5, 7), 0.0)
	draw_circle(Vector2.ZERO, 12.0, SHADOW)
	_tf(p, 0.0)
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(-8, 11 * s), 5.0, g.darkened(0.15))
		draw_circle(Vector2(8, 10 * s), 4.0, g.darkened(0.15))
	draw_circle(Vector2.ZERO, 11.0, g)
	draw_arc(Vector2.ZERO, 11.0, 0, TAU, 20, INK, 2.0)
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(6, 6 * s), 4.0, Color(1, 1, 1))
		draw_circle(Vector2(7, 6 * s), 2.0, INK)
	draw_set_transform(Vector2.ZERO)


func _ellipse(c: Vector2, r: Vector2, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 16:
		pts.append(c + (Vector2(cos(k * TAU / 16.0) * r.x, sin(k * TAU / 16.0) * r.y)).rotated(rot))
	return pts


func _shadow(p: Vector2, r: float) -> void:
	draw_set_transform(p + Vector2(8, 12), 0.0, Vector2(1.0, 0.8))
	draw_circle(Vector2.ZERO, r, SHADOW)
	draw_set_transform(Vector2.ZERO)


# --- Beschriftung ---

func _labels() -> void:
	_label(Vector2(40, 40), "Graue Welt: Risse, Steinchen, trockene Halme", 24)
	_label(Vector2(940, 40), "Grün: Farbflecken, Grasbüschel, bunte Blumen", 24)
	_label(Vector2(1480, 1040), "länger grün → üppiger und bunter →", 22)
	_label(Vector2(560, 120), "kahler Baum", 20)
	_label(Vector2(1395, 110), "blühender Baum", 20)
	_label(Vector2(560, 390), "trockener Teich", 20)
	_label(Vector2(1430, 385), "Teich mit Seerosen + Frosch", 20)
	_label(Vector2(560, 660), "verwelkter Busch", 20)
	_label(Vector2(1370, 650), "Busch mit Beeren", 20)
	_label(Vector2(560, 900), "kahler Fels", 20)
	_label(Vector2(1380, 880), "Fels mit Moos", 20)
	_label(Vector2(1660, 140), "Schmetterlinge", 20)
	_label(Vector2(1720, 450), "Vogel", 20)
	_label(Vector2(1750, 720), "Hase", 20)
	_label(Vector2(890, 900), "Roboter (Größenvergleich)", 20)
	_label(Vector2(870, 560), "→", 64)


func _label(p: Vector2, text: String, size: int) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_rect(Rect2(p + Vector2(-8, -size - 2), Vector2(w + 16, size + 14)), Color(1, 1, 1, 0.72))
	draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
