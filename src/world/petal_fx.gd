class_name PetalFx
extends Node2D
## Blütenblätter als Partikel: fester Vorrat, alle in einem einzigen _draw.
## Ist der Vorrat voll, ersetzt ein neues Blatt das älteste. Rein kosmetisch.

const COLORS := [
	Color(1.0, 0.72, 0.84), Color(1.0, 0.90, 0.42), Color(1.0, 1.0, 0.95), Color(0.70, 0.92, 0.52),
]

const RIM := 6

var capacity := 400
var colors: Array = COLORS   # Farbauswahl je Blatt (Staub nutzt Brauntöne)
var fall := 0.0   # Zug nach unten (Pixel/s²), für langsam fallenden Blätterregen
var _rim := PackedVector2Array()     # Einheitskreis, RIM Punkte
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()    # Restzeit, <= 0 = frei
var _max := PackedFloat32Array()
var _size := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _col := PackedColorArray()
var _next := 0
var _alive := 0


func _ready() -> void:
	# Packed-Arrays sind Werte: jedes einzeln anlegen, nicht über eine Schleife
	_pos.resize(capacity)
	_vel.resize(capacity)
	_life.resize(capacity)
	_max.resize(capacity)
	_size.resize(capacity)
	_rot.resize(capacity)
	_spin.resize(capacity)
	_col.resize(capacity)
	for r in RIM:
		_rim.append(Vector2.from_angle(r * TAU / RIM))


## count Blätter bei p, fliegen mit speed (min, max) in alle Richtungen
## (oder in einem Kegel um dir, wenn dir nicht null ist).
func burst(p: Vector2, count: int, speed := Vector2(40, 160), life := Vector2(0.6, 1.2), size := Vector2(5, 9), dir := Vector2.ZERO, spread := PI) -> void:
	for n in count:
		var i := _next
		_next = (_next + 1) % capacity
		if _life[i] <= 0.0:
			_alive += 1
		var ang := randf() * TAU if dir == Vector2.ZERO else dir.angle() + randf_range(-spread, spread)
		_pos[i] = p
		_vel[i] = Vector2.from_angle(ang) * randf_range(speed.x, speed.y)
		_life[i] = randf_range(life.x, life.y)
		_max[i] = _life[i]
		_size[i] = randf_range(size.x, size.y)
		_rot[i] = randf() * TAU
		_spin[i] = randf_range(-6.0, 6.0)
		_col[i] = colors[randi() % colors.size()]
	queue_redraw()


func _process(delta: float) -> void:
	if _alive == 0:
		return
	var damp := exp(-2.5 * delta)
	for i in capacity:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			_alive -= 1
			continue
		_pos[i] += _vel[i] * delta
		_vel[i] = _vel[i] * damp + Vector2(0.0, fall * delta)
		_rot[i] += _spin[i] * delta
	queue_redraw()


## Alle Blätter als ein einziges Dreiecksnetz (je Blatt ein Fächer aus RIM Dreiecken),
## ein Zeichenaufruf statt einem je Blatt.
func _draw() -> void:
	if _alive == 0:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	pts.resize(_alive * (RIM + 1))
	cols.resize(pts.size())
	idx.resize(_alive * RIM * 3)
	var v := 0
	var k := 0
	for i in capacity:
		if _life[i] <= 0.0 or v + RIM + 1 > pts.size():
			continue
		var t := _life[i] / _max[i]
		var c := _col[i]
		c.a = minf(1.0, t * 2.5)
		var s := _size[i] * (0.6 + 0.4 * t)
		var ax := Vector2.from_angle(_rot[i]) * s
		var ay := ax.orthogonal() * 0.55
		pts[v] = _pos[i]
		cols[v] = c
		for r in RIM:
			pts[v + 1 + r] = _pos[i] + ax * _rim[r].x + ay * _rim[r].y
			cols[v + 1 + r] = c
			idx[k] = v
			idx[k + 1] = v + 1 + r
			idx[k + 2] = v + 1 + (r + 1) % RIM
			k += 3
		v += RIM + 1
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)


## Blätterregen für Menüs: Blätter fallen langsam von oben über die ganze Breite.
## Jedes Bild aufrufen; rate = Blätter pro Sekunde.
func rain(width: float, rate: float, delta: float) -> void:
	if randf() < rate * delta:
		burst(Vector2(randf() * width, -20.0), 1, Vector2(20, 60), Vector2(14, 20), Vector2(8, 14), Vector2.DOWN, 1.2)
