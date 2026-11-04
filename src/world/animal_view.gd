class_name AnimalView
extends Node2D
## Zeichnet alle Tiere in einem einzigen _draw (Platzhalter-Grafik im Stil der Objekte), von oben.
## Am Boden: Hasen und Frösche, Sprünge zeigt der Schatten, der sich ablöst. In der Luft:
## Schmetterlinge (Flügelschlag) und Vögel (Schatten weit versetzt, sie fliegen hoch).

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const WINGS := [Color(1.0, 0.85, 0.30), Color(1.0, 1.0, 0.96), Color(1.0, 0.62, 0.30), Color(0.55, 0.72, 1.0), Color(1.0, 0.62, 0.78)]
const BIRDS := [Color(0.58, 0.44, 0.32), Color(0.24, 0.30, 0.46)]
const HARES := [Color(0.64, 0.52, 0.40), Color(0.56, 0.50, 0.46)]
const FROGS := [Color(0.40, 0.68, 0.30), Color(0.52, 0.74, 0.28)]
const SIDES: Array[float] = [-1.0, 1.0]
const SIZE := [1.7, 1.3, 1.5, 1.5]   # Zeichengröße je Art (Animals.BUTTERFLY, BIRD, HARE, FROG)

var _animals: Animals
var _base := Transform2D.IDENTITY


func bind(animals: Animals) -> void:
	_animals = animals
	z_index = 4


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _animals == null:
		return
	for s in _animals.splashes:
		var t: float = s["t"] / 0.8
		for k in 2:
			var r := 4.0 + (t - k * 0.25) * 26.0
			if r > 4.0:
				draw_arc(s["pos"], r, 0, TAU, 20, Color(1, 1, 1, (1.0 - t) * 0.7), 2.0)
	# erst der Boden, dann was fliegt
	for a in _animals.list:
		if a.alpha <= 0.0:
			continue
		if a.kind == Animals.HARE:
			_hare(a)
		elif a.kind == Animals.FROG:
			_frog(a)
	for a in _animals.list:
		if a.alpha <= 0.0:
			continue
		if a.kind == Animals.BUTTERFLY:
			_butterfly(a)
		elif a.kind == Animals.BIRD:
			_bird(a)
	draw_set_transform(Vector2.ZERO)


func _fade(c: Color, a: float) -> Color:
	return Color(c, c.a * a)


## Kreise und Ovale über Disc (draw_circle und Polygone sind viel teurer).
func _dot(c: Vector2, r: float, col: Color) -> void:
	Disc.dot(self, c, r, col)


func _at(pos: Vector2, dir: float, k: float) -> void:
	_base = Transform2D(dir, Vector2.ONE * k, 0.0, pos)
	draw_set_transform_matrix(_base)


func _oval(c: Vector2, r: Vector2, col: Color, rot: float = 0.0) -> void:
	if rot == 0.0:
		draw_texture_rect(Disc.TEX, Rect2(c - r, r * 2.0), false, col)
		return
	draw_set_transform_matrix(_base * Transform2D(rot, r, 0.0, c))
	draw_texture_rect(Disc.TEX, Rect2(-1, -1, 2, 2), false, col)
	draw_set_transform_matrix(_base)


## Viereck oder Dreieck ohne Triangulierung.
func _quad(pts: PackedVector2Array, col: Color) -> void:
	draw_primitive(pts, PackedColorArray([col]), PackedVector2Array())


## Höhe eines Sprungs 0..1 (0 = am Boden).
func _lift(a: Animals.Animal) -> float:
	return sin(clampf(a.hop, 0.0, 1.0) * PI) if a.hop >= 0.0 else 0.0


# Alle Tiere schauen in lokaler Richtung +x.

func _butterfly(a: Animals.Animal) -> void:
	var al := a.alpha
	var bob := sin(a.phase * 3.1) * 4.0
	var k: float = SIZE[a.kind]
	_at(a.pos + Vector2(12, 18 + bob) * k, a.dir, k)
	_oval(Vector2.ZERO, Vector2(5, 7), _fade(SHADOW, al * 0.7))
	_at(a.pos, a.dir, k)
	var f := 0.25 + 0.75 * absf(sin(a.phase * 13.0))   # Flügel klappen auf und zu
	var col: Color = WINGS[a.look]
	for side: float in SIDES:
		_oval(Vector2(2, side * 6.0 * f), Vector2(5.5, 7.0 * f), _fade(col.darkened(0.25), al))
		_oval(Vector2(2, side * 6.0 * f), Vector2(4.2, 5.6 * f), _fade(col, al))
		_oval(Vector2(-4, side * 4.5 * f), Vector2(4.0, 4.8 * f), _fade(col.darkened(0.1), al))
		draw_line(Vector2(5, 0), Vector2(10, side * 3.0), _fade(INK, al), 1.0)
	draw_line(Vector2(-6, 0), Vector2(6, 0), _fade(INK, al), 2.5)


func _bird(a: Animals.Animal) -> void:
	var col: Color = BIRDS[a.look]
	var span := 15.0 * (0.55 + 0.45 * cos(a.phase * 9.0))
	for pass_i in 2:
		var shadow := pass_i == 0
		var c := _fade(SHADOW if shadow else col, a.alpha)
		var k: float = SIZE[a.kind] * (0.85 if shadow else 1.0)
		_at(a.pos + (Vector2(40, 60) if shadow else Vector2.ZERO), a.dir, k)
		var wc := c if shadow else _fade(col.darkened(0.12), a.alpha)
		for side: float in SIDES:
			_quad(PackedVector2Array([Vector2(4, side * 2), Vector2(-2, side * (4 + span)), Vector2(-9, side * (3 + span * 0.8)), Vector2(-5, side * 2)]), wc)
		_quad(PackedVector2Array([Vector2(-8, 0), Vector2(-15, -5), Vector2(-13, 0), Vector2(-15, 5)]), c)   # Schwanz
		_oval(Vector2(0, 0), Vector2(10, 4.2), c)
		if not shadow:
			_oval(Vector2(8, 0), Vector2(4, 4), _fade(col.lightened(0.1), a.alpha))
			_quad(PackedVector2Array([Vector2(11.5, -1.5), Vector2(16, 0), Vector2(11.5, 1.5)]), _fade(Color(0.95, 0.70, 0.25), a.alpha))


func _hare(a: Animals.Animal) -> void:
	var h := _lift(a)
	var al := a.alpha
	var k: float = SIZE[a.kind]
	_at(a.pos + Vector2(4 + h * 8, 7 + h * 12) * k, a.dir, k)
	_oval(Vector2(-1, 0), Vector2(15, 9), _fade(SHADOW, al))
	_at(a.pos, a.dir, k * (1.0 + h * 0.15))
	var col: Color = HARES[a.look]
	var ink := _fade(INK, al)
	for side: float in SIDES:   # Hinterläufe, beim Sprung gestreckt
		_oval(Vector2(-8 - h * 5, side * 7), Vector2(6 + h * 3, 3), _fade(col.darkened(0.15), al))
	_oval(Vector2(-2, 0), Vector2(14, 10), ink)
	_oval(Vector2(-2, 0), Vector2(13, 9), _fade(col, al))
	_dot(Vector2(-15, 0), 3.8, _fade(Color(1, 1, 1), al))   # Blume (Schwanz)
	_dot(Vector2(10, 0), 7.5, ink)
	_dot(Vector2(10, 0), 6.5, _fade(col.lightened(0.08), al))
	for side: float in SIDES:   # lange Ohren, schräg nach hinten außen
		var rot := PI - side * 0.55
		var mid := Vector2(8, side * 3.5) + Vector2.from_angle(rot) * 8.0
		_oval(mid, Vector2(9.3, 3.8), ink, rot)
		_oval(mid, Vector2(8.5, 3.0), _fade(col.darkened(0.1), al), rot)
		_oval(mid, Vector2(5.5, 1.0), _fade(Color(0.95, 0.70, 0.72), al), rot)
		_dot(Vector2(12, side * 3.2), 1.4, _fade(Color(0.15, 0.15, 0.18), al))


func _frog(a: Animals.Animal) -> void:
	var h := _lift(a)
	var al := a.alpha
	var k: float = SIZE[a.kind]
	_at(a.pos + Vector2(3 + h * 6, 5 + h * 10) * k, a.dir, k)
	_oval(Vector2.ZERO, Vector2(9, 8), _fade(SHADOW, al))
	_at(a.pos, a.dir, k * (1.0 + h * 0.3))
	var col: Color = FROGS[a.look]
	for side: float in SIDES:
		_oval(Vector2(-6 - h * 4, side * 7), Vector2(5 + h * 3, 3), _fade(col.darkened(0.15), al))
		_oval(Vector2(5, side * 6), Vector2(3, 2), _fade(col.darkened(0.15), al))
	_oval(Vector2.ZERO, Vector2(9, 8), _fade(INK, al))
	_oval(Vector2.ZERO, Vector2(8, 7), _fade(col, al))
	_dot(Vector2(-2, 0), 3.0, _fade(col.lightened(0.15), al))
	for side: float in SIDES:
		_dot(Vector2(5, side * 3.6), 2.8, _fade(col.lightened(0.2), al))
		_dot(Vector2(5.6, side * 3.6), 1.4, _fade(Color(0.12, 0.12, 0.15), al))
