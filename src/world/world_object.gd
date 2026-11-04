class_name WorldObject
extends Node2D
## Ein Objekt der Welt (Platzhalter-Grafik im Stil von Roboter und Bienen, wie im Stil-Vorschlag):
## tot in der grauen Welt, erwacht im Grün. Ein eigener Knoten je Objekt, damit Godot nur sichtbare
## Objekte zeichnet. Die Erwach-Animation läuft über die Skalierung des Knotens; neu gezeichnet
## wird nur einmal, beim Wechsel von tot zu lebendig (ein blühender Baum hat über 200 Kreise).
## Arten: tree, rock, pond, bush; am Wegrand log, fence, stones.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const BLOSSOM := [Color(1.0, 0.72, 0.84), Color(1.0, 0.97, 0.98)]
const FLOWERS := [Color(1.0, 0.56, 0.69), Color(1.0, 0.85, 0.30), Color(1.0, 1.0, 0.96), Color(0.72, 0.55, 0.95), Color(1.0, 0.45, 0.35), Color(0.55, 0.75, 1.0)]
const ANIM_SEC := 0.7

var kind := "tree"
var obj_seed := 0
var angle := 0.0
var awake := false
var _anim := -1.0       # läuft beim Erwachen von 0 bis ANIM_SEC, sonst < 0
var _show_alive := false
var _rng := RandomNumberGenerator.new()


func setup(d: Dictionary) -> void:
	kind = str(d["kind"])
	position = d["pos"]
	obj_seed = int(d["seed"])
	angle = float(d.get("angle", 0.0))


## Godot schaltet _process beim Eintritt in den Baum ein; gebraucht wird es nur während der Animation.
func _ready() -> void:
	set_process(_anim >= 0.0)


## Sofort (beim Laden) oder mit Animation.
func set_awake(on: bool, animate: bool) -> void:
	if awake == on:
		return
	awake = on
	_anim = 0.0 if animate and on else -1.0
	_show_alive = on and _anim < 0.0
	scale = Vector2.ONE
	set_process(_anim >= 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _anim < 0.0:
		set_process(false)
		return
	_anim += delta
	var t := minf(_anim / ANIM_SEC, 1.0)
	if t < 0.25:
		scale = Vector2.ONE * (1.0 - t * 0.8)          # das Tote zieht sich kurz zusammen
	else:
		if not _show_alive:
			_show_alive = true
			queue_redraw()
		var u := (t - 0.25) / 0.75
		scale = Vector2.ONE * (0.8 + 0.2 * (1.0 - pow(1.0 - u, 3.0)) + sin(u * PI) * 0.12)   # das Lebende ploppt auf
	if _anim >= ANIM_SEC:
		_anim = -1.0
		scale = Vector2.ONE
		set_process(false)


func _draw() -> void:
	var alive := _show_alive
	_rng.seed = obj_seed
	match kind:
		"tree":
			if alive:
				_tree_alive()
			else:
				_tree_dead()
		"rock":
			_rock(alive)
		"pond":
			if alive:
				_pond_alive()
			else:
				_pond_dry()
		"bush":
			if alive:
				_bush_alive()
			else:
				_bush_wilted()
		"log":
			_log(alive)
		"fence":
			_fence(alive)
		"stones":
			_stones(alive)
	draw_set_transform(Vector2.ZERO)


# --- Hilfen: alles in lokalen Koordinaten ---

func _tf(offset: Vector2 = Vector2.ZERO, rot: float = 0.0, sc: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(offset, rot, sc)


func _shadow(r: float, sc: Vector2 = Vector2(1.0, 0.8)) -> void:
	_tf(Vector2(8, 12), 0.0, sc)
	draw_circle(Vector2.ZERO, r, SHADOW)
	_tf()


func _flower(p: Vector2, c: Color, s: float) -> void:
	for k in 5:
		draw_circle(p + Vector2.from_angle(k * TAU / 5.0) * s * 0.9, s * 0.75, c)
	draw_circle(p, s * 0.55, Color(1.0, 0.82, 0.28))


func _ellipse(c: Vector2, r: Vector2, rot: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		pts.append(c + Vector2(cos(k * TAU / n) * r.x, sin(k * TAU / n) * r.y).rotated(rot))
	return pts


# --- Bäume ---

func _tree_dead() -> void:
	_shadow(66.0)
	_tf()
	var bark := Color(0.48, 0.40, 0.32)
	var a0 := _rng.randf() * TAU
	for k in 7:
		var a := a0 + k * TAU / 7.0 + _rng.randf_range(-0.2, 0.2)
		var tip := Vector2.from_angle(a) * _rng.randf_range(50.0, 64.0)
		draw_line(Vector2.ZERO, tip, bark, 6.0)
		var mid := tip * 0.6
		draw_line(mid, mid + Vector2.from_angle(a + 0.7) * 20.0, bark, 3.5)
		draw_line(tip, tip + Vector2.from_angle(a - 0.5) * 13.0, bark, 2.5)
	draw_circle(Vector2.ZERO, 14.0, Color(0.50, 0.42, 0.34))
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 24, INK, 3.0)


func _tree_alive() -> void:
	_shadow(76.0)
	_tf()
	var a0 := _rng.randf() * TAU
	for k in 9:
		draw_circle(Vector2.from_angle(a0 + k * TAU / 9.0) * 44.0, 32.0, Color(0.36, 0.66, 0.30))
	draw_circle(Vector2.ZERO, 48.0, Color(0.44, 0.74, 0.34))
	for k in 9:
		var a := a0 + k * TAU / 9.0
		draw_arc(Vector2.from_angle(a) * 44.0, 32.0, a - 1.3, a + 1.3, 12, INK, 3.0)
	var blossom: Color = BLOSSOM[_rng.randi() % 2]
	for i in 30:
		var q := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, 66.0)
		_flower(q, blossom if i % 3 else Color(1.0, 0.97, 0.98), 4.5)


# --- Felsen ---

func _rock(moss: bool) -> void:
	var pts := PackedVector2Array()
	var a0 := _rng.randf() * TAU
	var stretch := Vector2(_rng.randf_range(54, 62), _rng.randf_range(40, 48))
	for k in 9:
		pts.append(Vector2.from_angle(a0 + k * TAU / 9.0) * stretch * (0.85 + 0.15 * sin(k * 2.3 + obj_seed % 7)))
	var sh := PackedVector2Array()
	for q in pts:
		sh.append(q + Vector2(6, 9))
	_tf()
	draw_colored_polygon(sh, SHADOW)
	draw_colored_polygon(pts, Color(0.66, 0.66, 0.68))
	draw_circle(Vector2(-12, -10), 20.0, Color(0.76, 0.76, 0.78))
	pts.append(pts[0])
	draw_polyline(pts, INK, 3.0)
	if moss:
		for i in 14:
			var q := Vector2(_rng.randf_range(-38, 28), _rng.randf_range(-28, 8))
			draw_circle(q, _rng.randf_range(7, 13), Color(0.42, 0.70, 0.30).lerp(Color(0.60, 0.82, 0.36), _rng.randf()))
		_flower(Vector2(10, -14), Color(1.0, 1.0, 0.96), 4.0)


# --- Teiche ---

func _pond_dry() -> void:
	_tf(Vector2.ZERO, angle, Vector2(1.5, 1.0))
	draw_circle(Vector2.ZERO, 70.0, Color(0.58, 0.52, 0.44))
	draw_circle(Vector2.ZERO, 58.0, Color(0.68, 0.61, 0.50))
	draw_arc(Vector2.ZERO, 70.0, 0, TAU, 40, Color(0.46, 0.40, 0.34), 3.0)
	_tf(Vector2.ZERO, angle)
	for i in 9:
		var a := _rng.randf() * TAU
		var q := Vector2(cos(a) * 20, sin(a) * 12)
		draw_line(q, q + Vector2(cos(a) * 55, sin(a) * 34), Color(0.50, 0.44, 0.36), 2.0)


func _pond_alive() -> void:
	_tf(Vector2.ZERO, angle, Vector2(1.5, 1.0))
	draw_circle(Vector2.ZERO, 74.0, Color(0.62, 0.78, 0.42))
	draw_circle(Vector2.ZERO, 66.0, Color(0.40, 0.68, 0.88))
	draw_circle(Vector2(-14, -12), 40.0, Color(0.52, 0.78, 0.94))
	draw_arc(Vector2.ZERO, 66.0, 0, TAU, 40, INK, 3.0)
	_tf(Vector2.ZERO, angle)
	for i in 4:
		var q := Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-32, 32))
		draw_circle(q, 14.0, Color(0.36, 0.66, 0.30))
		draw_colored_polygon(PackedVector2Array([q, q + Vector2(16, -5), q + Vector2(16, 5)]), Color(0.40, 0.68, 0.88))
		if i % 2 == 0:
			_flower(q, Color(1.0, 0.62, 0.78) if i == 0 else Color(1.0, 0.97, 0.98), 5.0)


# --- Büsche ---

func _bush_wilted() -> void:
	_shadow(44.0)
	_tf()
	for k in 6:
		var q := Vector2.from_angle(k * TAU / 6.0 + obj_seed % 5) * 21.0
		draw_circle(q, 21.0, Color(0.58, 0.55, 0.40))
		draw_arc(q, 21.0, 0, TAU, 20, Color(0.45, 0.42, 0.32), 2.0)
	draw_circle(Vector2.ZERO, 19.0, Color(0.62, 0.58, 0.42))


func _bush_alive() -> void:
	_shadow(48.0)
	_tf()
	for k in 6:
		var a := k * TAU / 6.0 + obj_seed % 5
		var q := Vector2.from_angle(a) * 23.0
		draw_circle(q, 24.0, Color(0.30, 0.60, 0.28))
		draw_arc(q, 24.0, a - 1.4, a + 1.4, 12, INK, 3.0)
	draw_circle(Vector2.ZERO, 25.0, Color(0.38, 0.68, 0.32))
	for i in 16:
		var q := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5, 38)
		draw_circle(q, 4.5, Color(0.88, 0.18, 0.30))
		draw_circle(q + Vector2(-1.3, -1.3), 1.4, Color(1, 1, 1, 0.8))


# --- Wegrand: Baumstamm, Zaun, Steine ---

func _log(alive: bool) -> void:
	_tf(Vector2(5, 8), angle)
	draw_rect(Rect2(-34, -11, 68, 22), SHADOW)
	_tf(Vector2.ZERO, angle)
	var wood := Color(0.62, 0.50, 0.38) if alive else Color(0.55, 0.50, 0.45)
	draw_rect(Rect2(-34, -11, 68, 22), wood)
	draw_line(Vector2(-30, -4), Vector2(26, -4), wood.darkened(0.2), 2.0)
	draw_line(Vector2(-26, 4), Vector2(30, 4), wood.darkened(0.2), 2.0)
	draw_rect(Rect2(-34, -11, 68, 22), INK, false, 2.5)
	draw_circle(Vector2(34, 0), 11.0, wood.lightened(0.2))
	draw_arc(Vector2(34, 0), 11.0, 0, TAU, 16, INK, 2.5)
	draw_arc(Vector2(34, 0), 5.0, 0, TAU, 12, wood.darkened(0.25), 1.5)
	if alive:
		for i in 6:
			draw_circle(Vector2(_rng.randf_range(-28, 20), _rng.randf_range(-9, 6)), _rng.randf_range(4, 7), Color(0.42, 0.70, 0.30))
		for i in 2:
			var m := Vector2(_rng.randf_range(-20, 10), -13.0)
			draw_circle(m, 5.0, Color(0.92, 0.30, 0.28))
			draw_circle(m + Vector2(-1.5, -1.5), 1.3, Color(1, 1, 1))


func _fence(alive: bool) -> void:
	_tf(Vector2.ZERO, angle)
	var wood := Color(0.70, 0.54, 0.36) if alive else Color(0.58, 0.55, 0.50)
	for y in [-4.0, 4.0]:
		draw_line(Vector2(-40, y + 6), Vector2(40, y + 6), SHADOW, 4.0)
		draw_line(Vector2(-40, y), Vector2(40, y), wood, 4.0)
	for x in [-38.0, 0.0, 38.0]:
		draw_circle(Vector2(x, 0), 6.0, wood.darkened(0.15))
		draw_arc(Vector2(x, 0), 6.0, 0, TAU, 12, INK, 2.0)
	if not alive:
		draw_line(Vector2(12, -6), Vector2(24, 6), wood.darkened(0.3), 2.0)   # gebrochene Latte
	else:
		for i in 7:
			var q := Vector2(_rng.randf_range(-36, 36), _rng.randf_range(-6, 6))
			draw_circle(q, 4.0, Color(0.36, 0.66, 0.30))
			if i % 2 == 0:
				_flower(q, FLOWERS[_rng.randi() % FLOWERS.size()], 3.5)


func _stones(moss: bool) -> void:
	_tf()
	for i in 3:
		var q := Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-12, 12))
		var r := _rng.randf_range(8, 14)
		draw_circle(q + Vector2(3, 4), r, SHADOW)
		draw_circle(q, r, Color(0.64, 0.64, 0.66).lerp(Color(0.74, 0.74, 0.76), _rng.randf()))
		draw_arc(q, r, 0, TAU, 16, INK, 2.0)
		if moss:
			draw_circle(q + Vector2(-r * 0.3, -r * 0.3), r * 0.5, Color(0.44, 0.72, 0.30))
	if moss:
		_flower(Vector2(_rng.randf_range(-10, 10), 14), FLOWERS[_rng.randi() % FLOWERS.size()], 3.5)
