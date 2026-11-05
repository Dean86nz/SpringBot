class_name IntroArt
extends Control
## Bilder der Einleitung, gezeichnet im Stil des Spiels und leicht bewegt. Roboter und Objekte
## (Bäume, Teich, Büsche) sind dieselben Knoten wie im Spiel, nur klein im Bild.
##   "grey":  graue Welt mit kahlem Baum, trockenem Teich und welkem Busch, Staub weht vorbei.
##   "robot": der Roboter fährt eine Schleife, hinter ihm wächst eine grüne Spur.
##   "bloom": alles grün; Bäume, Teich und Busch erwachen nacheinander, Blumen sprießen,
##            Bienen und Schmetterlinge fliegen, Blütenblätter fallen.

const GREY := Color(0.70, 0.68, 0.64)
const GREY_DARK := Color(0.56, 0.54, 0.50)
const GREEN := Color(0.46, 0.76, 0.33)
const GREEN_DARK := Color(0.33, 0.62, 0.27)
const INK := Color(0.30, 0.36, 0.44)
const FLOWERS := [Color(1.0, 0.56, 0.69), Color(1.0, 0.85, 0.30), Color(1.0, 1.0, 0.96), Color(0.72, 0.55, 0.95), Color(0.55, 0.75, 1.0)]

var _kind := ""
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _deco: Array[Dictionary] = []       # Risse, Steinchen, Halme oder Blumen: {p, k, c, at}
var _trail := PackedVector2Array()      # grüne Spur des Roboters
var _trail_timer := 0.0
var _robot: Robot
var _objects: Array[WorldObject] = []
var _wake_at: Array[float] = []
var _petals := PetalFx.new()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_petals.capacity = 120
	_petals.fall = 60.0


func show_page(kind: String) -> void:
	_kind = kind
	_t = 0.0
	_trail.clear()
	for o in _objects:
		o.queue_free()
	_objects.clear()
	_wake_at.clear()
	if _robot:
		_robot.queue_free()
		_robot = null
	if _petals.get_parent():
		remove_child(_petals)
	_rng.seed = 7
	_deco.clear()
	var s := _area()
	match kind:
		"grey":
			for i in 26:
				_deco.append({"p": Vector2(_rng.randf() * s.x, _rng.randf() * s.y), "k": _rng.randi() % 3, "c": 0, "at": 0.0})
			_add_object("oak", Vector2(s.x * 0.22, s.y * 0.45), 1.0, 11)
			_add_object("pond", Vector2(s.x * 0.68, s.y * 0.55), 0.85, 5)
			_add_object("bush", Vector2(s.x * 0.45, s.y * 0.75), 0.9, 3)
		"robot":
			for i in 22:
				_deco.append({"p": Vector2(_rng.randf() * s.x, _rng.randf() * s.y), "k": _rng.randi() % 3, "c": 0, "at": 0.0})
			_add_object("oak", Vector2(s.x * 0.12, s.y * 0.3), 0.8, 11)
			_robot = _make_robot(Vector2(s.x * 0.5, s.y * 0.5))
		"bloom":
			for i in 70:
				_deco.append({"p": Vector2(_rng.randf() * s.x, _rng.randf() * s.y), "k": 3,
					"c": _rng.randi() % FLOWERS.size(), "at": 0.3 + _rng.randf() * 2.2})
			_add_object("oak", Vector2(s.x * 0.15, s.y * 0.42), 1.0, 11, 0.4)
			_add_object("fruit", Vector2(s.x * 0.84, s.y * 0.38), 1.1, 4, 0.9)
			_add_object("pond", Vector2(s.x * 0.66, s.y * 0.72), 0.75, 5, 1.4)
			_add_object("bush", Vector2(s.x * 0.33, s.y * 0.8), 0.9, 3, 1.8)
			_robot = _make_robot(Vector2(s.x * 0.47, s.y * 0.42))
			add_child(_petals)
	queue_redraw()


## Größe des Bildes; vor dem ersten Layout gilt die Mindestgröße.
func _area() -> Vector2:
	return size.max(custom_minimum_size)


func _add_object(kind: String, pos: Vector2, sz: float, seed: int, wake := -1.0) -> void:
	var o := WorldObject.new()
	o.setup({"kind": kind, "pos": pos, "seed": seed, "angle": 0.4, "size": sz, "quiet": false})
	add_child(o)
	_objects.append(o)
	_wake_at.append(wake)


func _make_robot(pos: Vector2) -> Robot:
	var r := Robot.new()
	r.input_enabled = false
	r.process_mode = Node.PROCESS_MODE_DISABLED   # wird hier geführt, bremst sonst ohne Eingabe
	r.position = pos
	r.scale = Vector2.ONE * 1.3
	add_child(r)
	return r


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _kind == "":
		return
	_t += delta
	var s := _area()
	match _kind:
		"robot":
			# Schleife um die Mitte, die Spur hinter dem Roboter wird grün
			var a := _t * 0.9 - PI / 2
			_robot.position = s * 0.5 + Vector2(cos(a) * s.x * 0.3, sin(a) * s.y * 0.28)
			_robot.rotation = Vector2(-sin(a) * s.x * 0.3, cos(a) * s.y * 0.28).angle()
			_trail_timer -= delta
			if _trail_timer <= 0.0 and _trail.size() < 600:
				_trail_timer = 0.03
				_trail.append(_robot.position)
		"bloom":
			for i in _objects.size():
				if _wake_at[i] >= 0.0 and _t >= _wake_at[i] and not _objects[i].awake:
					_objects[i].set_awake(true, true)
					_petals.burst(_objects[i].position, 14, Vector2(40, 160), Vector2(0.6, 1.1), Vector2(6, 10))
			_robot.rotation = sin(_t * 1.6) * 0.25
			_petals.rain(s.x, 6.0, delta)
	queue_redraw()


func _draw() -> void:
	var s := _area()
	var green := _kind == "bloom"
	draw_rect(Rect2(Vector2.ZERO, s), GREEN if green else GREY)
	# große, weiche Flecken für etwas Tiefe
	_rng.seed = 3
	for i in 9:
		var c := Vector2(_rng.randf() * s.x, _rng.randf() * s.y)
		Disc.dot(self, c, _rng.randf_range(120, 220), (GREEN_DARK if green else GREY_DARK) * Color(1, 1, 1, 0.12))
	for d in _deco:
		_deco_item(d)
	if _kind == "robot":
		for p in _trail:
			Disc.dot(self, p, 62.0, GREEN_DARK)
		for p in _trail:
			Disc.dot(self, p, 54.0, GREEN)
		# frische Grasbüschel auf der Spur
		for i in range(0, _trail.size(), 6):
			var q := _trail[i] + Vector2(sin(i * 1.7), cos(i * 2.3)) * 30.0
			for k in 3:
				draw_line(q, q + Vector2.from_angle(-PI / 2 + (k - 1) * 0.4) * 9.0, GREEN_DARK, 2.0)
	if _kind == "grey":
		# Staub weht langsam von links nach rechts
		for i in 14:
			var x := fmod(i * 97.0 + _t * (30.0 + i * 3.0), s.x + 40.0) - 20.0
			var y := fmod(i * 53.0, s.y) + sin(_t * 1.3 + i) * 10.0
			Disc.dot(self, Vector2(x, y), 3.0, Color(0.85, 0.83, 0.78, 0.6))
	if green:
		_bees_and_butterflies(s)


func _deco_item(d: Dictionary) -> void:
	var p: Vector2 = d["p"]
	match int(d["k"]):
		0:   # Riss
			draw_line(p, p + Vector2(10, 6), GREY_DARK, 2.0)
			draw_line(p + Vector2(10, 6), p + Vector2(16, -2), GREY_DARK, 2.0)
		1:   # Steinchen
			Disc.dot(self, p, 4.0, Color(0.78, 0.76, 0.72))
		2:   # trockener Halm
			for k in 3:
				draw_line(p, p + Vector2.from_angle(-PI / 2 + (k - 1) * 0.45) * 10.0, Color(0.62, 0.55, 0.42), 2.0)
		3:   # Blume, wächst ab "at"
			var g := clampf((_t - float(d["at"])) / 0.35, 0.0, 1.0)
			if g <= 0.0:
				return
			var r := 6.0 * (g * (1.0 + 0.25 * sin(g * PI)))
			var col: Color = FLOWERS[int(d["c"])]
			for k in 5:
				Disc.dot(self, p + Vector2.from_angle(k * TAU / 5.0) * r * 0.9, r * 0.75, col)
			Disc.dot(self, p, r * 0.5, Color(1.0, 0.82, 0.28))


func _bees_and_butterflies(s: Vector2) -> void:
	for i in 3:
		var a := _t * (1.1 + i * 0.3) + i * 2.0
		var p := Vector2(s.x * (0.3 + 0.2 * i) + cos(a) * 70.0, s.y * 0.35 + sin(a * 2.0) * 40.0)
		var dir := Vector2(-sin(a), 2.0 * cos(a * 2.0)).angle()
		draw_set_transform(p, dir, Vector2.ONE)
		for side in [-1.0, 1.0]:
			Disc.dot(self, Vector2(-2, side * 7.0 * (0.6 + 0.4 * absf(sin(_t * 30.0)))), 5.0, Color(1, 1, 1, 0.75))
		Disc.dot(self, Vector2.ZERO, 7.0, Color(1.0, 0.82, 0.25))
		draw_line(Vector2(-3, -6), Vector2(-3, 6), INK, 2.5)
		draw_line(Vector2(2, -6), Vector2(2, 6), INK, 2.5)
		draw_set_transform(Vector2.ZERO)
	for i in 2:
		var a := _t * 0.7 + i * 3.0
		var p := Vector2(s.x * (0.25 + 0.5 * i) + sin(a) * 90.0, s.y * (0.6 - 0.3 * i) + cos(a * 1.3) * 50.0)
		var f := 0.3 + 0.7 * absf(sin(_t * 9.0 + i))
		var col: Color = [Color(1.0, 0.62, 0.30), Color(0.55, 0.72, 1.0)][i]
		for side in [-1.0, 1.0]:
			draw_set_transform(p + Vector2(side * 6.0 * f, 0), 0.0, Vector2(f, 1.0))
			Disc.dot(self, Vector2.ZERO, 7.0, col)
			draw_set_transform(Vector2.ZERO)
		draw_line(p + Vector2(0, -6), p + Vector2(0, 6), INK, 2.0)
