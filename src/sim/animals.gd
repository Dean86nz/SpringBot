class_name Animals
extends RefCounted
## Tiere als reine Deko (data/animals.json): Schmetterlinge, Vögel, Hasen, Frösche.
## Leben nur in der Nähe der Kamera (view, Pixel) und entstehen nur über grünem Land; ihre
## Höchstzahl wächst mit dem Grün, so kommen sie nach und nach. Keine Spielwirkung, nicht gespeichert.
## Schmetterlinge flattern umher und kehren um, wo es grau wird. Hasen hoppeln von Grün zu Grün
## und meiden Wasser und Objekte. Vögel ziehen ab und zu in kleinen Gruppen über das Bild.
## Frösche sitzen am Rand erwachter Teiche, hüpfen ein Stück oder tauchen ab (Platschen).
## Kommt der Roboter nah, fliehen Hasen und Schmetterlinge, Frösche springen ins Wasser.
## Logik ohne Darstellung (AnimalView zeichnet).

const BUTTERFLY := 0
const BIRD := 1
const HARE := 2
const FROG := 3
const POND_RIM := 72.0    # Sitzplatz der Frösche: Grasring des Teichs (world_object.gd, Radius 74)
const POND_STRETCH := 1.5 # Teiche sind in Längsrichtung gestreckt


class Animal:
	var kind := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var dir := 0.0          # Blickrichtung (Bogenmaß)
	var phase := 0.0        # für Flügelschlag und Wackeln
	var look := 0           # Farbvariante
	var wait := 0.0         # Ruhezeit bis zum nächsten Sprung
	var hop := -1.0         # Sprung läuft von 0 bis 1, sonst < 0
	var hop_sec := 0.3
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var alpha := 0.0        # ein- und ausblenden
	var leaving := false    # wird ausgeblendet und dann entfernt
	var pond := -1          # Frösche: Index in ponds
	var rim := 0.0          # Frösche: Winkel am Teichrand
	var diving := false     # Frosch springt gerade ins Wasser
	var hidden := 0.0       # Frosch unter Wasser (Sekunden)
	var age := 0.0


var list: Array[Animal] = []
## Teiche: {pos, angle, size, awake}; main.gd hält awake aktuell.
var ponds: Array[Dictionary] = []
## Was Hasen meiden: {pos, radius} (Objekte).
var avoid: Array[Dictionary] = []
## Platschen auf dem Wasser: {pos, t}
var splashes: Array[Dictionary] = []

var _grid: GroundGrid
var _cell_px := 24.0
var _cfg: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _bird_timer := 0.0


func _init(grid: GroundGrid, cell_px: float, cfg: Dictionary, rng_seed: int = 0) -> void:
	_grid = grid
	_cell_px = cell_px
	_cfg = cfg
	_rng.seed = rng_seed if rng_seed != 0 else randi()
	_bird_timer = _rand_range(_sec("bird", "every_sec"))


func clear() -> void:
	list.clear()
	splashes.clear()


func count(kind: int) -> int:
	var n := 0
	for a in list:
		if a.kind == kind and not a.leaving:
			n += 1
	return n


## view: sichtbarer Ausschnitt in Pixeln, robot: Position des Roboters.
func update(delta: float, view: Rect2, robot: Vector2) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = float(_cfg.get("spawn_check_sec", 0.5))
		_spawn(view)
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = _rand_range(_sec("bird", "every_sec"))
		_spawn_birds(view)
	var far := view.grow(float(_cfg.get("despawn_margin_px", 700.0)))
	var fade := maxf(float(_cfg.get("fade_sec", 0.6)), 0.01)
	for i in range(list.size() - 1, -1, -1):
		var a := list[i]
		a.age += delta
		a.phase += delta
		match a.kind:
			BUTTERFLY:
				_butterfly(a, delta, robot)
			BIRD:
				a.pos += a.vel * delta
			HARE:
				_hare(a, delta, robot)
			FROG:
				_frog(a, delta, robot)
		if a.leaving:
			a.alpha -= delta / fade
		elif a.hidden <= 0.0:
			a.alpha = minf(a.alpha + delta / fade, 1.0)
		var gone := not far.has_point(a.pos) or (a.leaving and a.alpha <= 0.0)
		if a.kind == FROG and (a.pond >= ponds.size() or not ponds[a.pond]["awake"]):
			gone = true
		if gone:
			list.remove_at(i)
	for i in range(splashes.size() - 1, -1, -1):
		splashes[i]["t"] += delta
		if splashes[i]["t"] > 0.8:
			splashes.remove_at(i)


## Höchstzahl einer Art beim jetzigen Grün (0 unter min_coverage, max ab full_coverage).
func cap(kind_name: String) -> int:
	var c: Dictionary = _cfg.get(kind_name, {})
	var lo := float(c.get("min_coverage", 0.0))
	var hi := maxf(float(c.get("full_coverage", 1.0)), lo + 0.001)
	var cov := _grid.coverage()
	if cov < lo:
		return 0
	return ceili(float(c.get("max", 0)) * clampf((cov - lo) / (hi - lo), 0.0, 1.0))


func _spawn(view: Rect2) -> void:
	var near := view.grow(float(_cfg.get("view_margin_px", 200.0)))
	if count(BUTTERFLY) < cap("butterfly"):
		var p := _green_spot(near, false)
		if p.x >= 0.0:
			var a := _add(BUTTERFLY, p)
			a.dir = _rng.randf() * TAU
			a.look = _rng.randi() % 5
	if count(HARE) < cap("hare"):
		# Hasen kommen von außerhalb des Bildes herein
		var p := _green_spot(near, true, view)
		if p.x >= 0.0 and _free(p):
			var a := _add(HARE, p)
			a.dir = _rng.randf() * TAU
			a.wait = _rng.randf_range(0.2, 1.0)
			a.look = _rng.randi() % 2
	_spawn_frogs(near)


func _spawn_frogs(near: Rect2) -> void:
	var per := int((_cfg.get("frog", {}) as Dictionary).get("per_pond", 2))
	for k in ponds.size():
		var pd := ponds[k]
		if not pd["awake"] or not near.has_point(pd["pos"]):
			continue
		var have := 0
		for a in list:
			if a.kind == FROG and a.pond == k:
				have += 1
		for n in per - have:
			var a := _add(FROG, Vector2.ZERO)
			a.pond = k
			a.rim = _rng.randf() * TAU
			a.pos = rim_point(pd, a.rim, POND_RIM)
			a.dir = (a.pos - pd["pos"]).angle() + PI   # schaut aufs Wasser
			a.wait = _rand_range(_sec("frog", "rest_sec"))
			a.look = _rng.randi() % 2


func _spawn_birds(view: Rect2) -> void:
	if _grid.coverage() < float((_cfg.get("bird", {}) as Dictionary).get("min_coverage", 0.1)):
		return
	if not _grid.is_green(Vector2i(view.get_center() / _cell_px)):
		return
	var flock: Array = (_cfg.get("bird", {}) as Dictionary).get("flock", [1, 3])
	var n := _rng.randi_range(int(flock[0]), int(flock[1]))
	var heading := Vector2.from_angle(_rng.randf() * TAU)
	var r := view.size.length() * 0.5 + 120.0
	var start := view.get_center() - heading * r + heading.orthogonal() * _rng.randf_range(-0.35, 0.35) * view.size.y
	var speed := float((_cfg.get("bird", {}) as Dictionary).get("speed", 220.0))
	var look := _rng.randi() % 2
	for i in n:
		var side := heading.orthogonal() * (i - (n - 1) * 0.5) * 42.0
		var a := _add(BIRD, start - heading * absf(i - (n - 1) * 0.5) * 36.0 + side)
		a.vel = heading * speed * _rng.randf_range(0.95, 1.05)
		a.dir = heading.angle()
		a.phase = _rng.randf() * 3.0
		a.alpha = 1.0
		a.look = look


func _add(kind: int, p: Vector2) -> Animal:
	var a := Animal.new()
	a.kind = kind
	a.pos = p
	a.phase = _rng.randf() * 10.0
	list.append(a)
	return a


## Zufälliger grüner Punkt in area (outside_of: nur außerhalb dieses Rechtecks). x < 0: keiner gefunden.
func _green_spot(area: Rect2, outside: bool, outside_of: Rect2 = Rect2()) -> Vector2:
	for k in 8:
		var p := area.position + Vector2(_rng.randf(), _rng.randf()) * area.size
		if outside and outside_of.has_point(p):
			continue
		if _grid.is_green(Vector2i(p / _cell_px)):
			return p
	return Vector2(-1, -1)


func _free(p: Vector2) -> bool:
	if not _grid.is_green(Vector2i(p / _cell_px)):
		return false
	for o in avoid:
		if p.distance_to(o["pos"]) < float(o["radius"]) + 12.0:
			return false
	return true


# --- Verhalten ---

func _butterfly(a: Animal, delta: float, robot: Vector2) -> void:
	var c: Dictionary = _cfg.get("butterfly", {})
	a.dir += _rng.randf_range(-1.0, 1.0) * float(c.get("turn", 2.5)) * delta * 3.0
	var away := a.pos - robot
	if away.length() < float(c.get("flee_px", 90.0)):
		a.dir = lerp_angle(a.dir, away.angle(), minf(delta * 6.0, 1.0))
	var speed := float(c.get("speed", 55.0)) * (0.7 + 0.3 * sin(a.phase * 2.3))
	var step := Vector2.from_angle(a.dir) * speed * delta
	# umkehren, wo es vorne grau wird (bleibt über dem Grün)
	if not _grid.is_green(Vector2i((a.pos + step * 30.0) / _cell_px)):
		a.dir += PI * delta * 2.0
	a.pos += step


func _hare(a: Animal, delta: float, robot: Vector2) -> void:
	var c: Dictionary = _cfg.get("hare", {})
	var scared := a.pos.distance_to(robot) < float(c.get("flee_px", 190.0))
	if a.hop >= 0.0:
		a.hop += delta / a.hop_sec
		a.pos = a.from.lerp(a.to, minf(a.hop, 1.0))
		if a.hop >= 1.0:
			a.hop = -1.0
			a.wait = 0.05 if scared else _rand_range(_sec("hare", "rest_sec"))
		return
	a.wait -= delta
	if a.wait > 0.0 and not scared:
		return
	var hop: Array = c.get("hop_px", [36, 70])
	for k in 6:
		var ang := (a.pos - robot).angle() + _rng.randf_range(-0.7, 0.7) if scared else a.dir + _rng.randf_range(-1.2, 1.2)
		var t := a.pos + Vector2.from_angle(ang) * _rng.randf_range(float(hop[0]), float(hop[1])) * (1.3 if scared else 1.0)
		if _free(t) and _grid.is_walkable(Vector2i(t / _cell_px)):
			a.from = a.pos
			a.to = t
			a.dir = ang
			a.hop = 0.0
			a.hop_sec = float(c.get("hop_sec", 0.32)) * (0.8 if scared else 1.0)
			return
	a.wait = 0.5
	if not _grid.is_green(Vector2i(a.pos / _cell_px)):
		a.leaving = true


func _frog(a: Animal, delta: float, robot: Vector2) -> void:
	if a.pond >= ponds.size():
		return
	var pd := ponds[a.pond]
	var c: Dictionary = _cfg.get("frog", {})
	if a.hidden > 0.0:
		a.hidden -= delta
		if a.hidden <= 0.0:
			# taucht an einer anderen Stelle des Ufers wieder auf
			a.rim = _rng.randf() * TAU
			a.pos = rim_point(pd, a.rim, POND_RIM)
			a.dir = (a.pos - pd["pos"]).angle() + PI
			a.alpha = 0.0
			a.wait = _rand_range(_sec("frog", "rest_sec"))
		return
	if a.hop >= 0.0:
		a.hop += delta / a.hop_sec
		a.pos = a.from.lerp(a.to, minf(a.hop, 1.0))
		if a.hop >= 1.0:
			a.hop = -1.0
			a.wait = _rand_range(_sec("frog", "rest_sec"))
			if a.diving:
				a.diving = false
				a.hidden = _rand_range(_sec("frog", "hidden_sec"))
				a.alpha = 0.0
				splashes.append({"pos": a.pos, "t": 0.0})
		return
	a.wait -= delta
	var scared := a.pos.distance_to(robot) < float(c.get("dive_px", 130.0))
	if a.wait > 0.0 and not scared:
		return
	a.from = a.pos
	a.hop = 0.0
	a.hop_sec = float(c.get("hop_sec", 0.4))
	if scared or _rng.randf() < 0.4:
		a.diving = true
		a.to = rim_point(pd, a.rim + _rng.randf_range(-0.3, 0.3), POND_RIM * _rng.randf_range(0.35, 0.6))
	else:
		a.rim += _rng.randf_range(0.25, 0.6) * (1.0 if _rng.randf() < 0.5 else -1.0)
		a.to = rim_point(pd, a.rim, POND_RIM)
	a.dir = (a.to - a.from).angle()


## Punkt auf dem (gestreckten, gedrehten) Teichrand im Abstand r (vor Streckung und Größe).
static func rim_point(pd: Dictionary, theta: float, r: float) -> Vector2:
	var local := Vector2(cos(theta) * POND_STRETCH, sin(theta)) * r * float(pd.get("size", 1.0))
	return Vector2(pd["pos"]) + local.rotated(float(pd.get("angle", 0.0)))


func _sec(kind_name: String, key: String) -> Array:
	return (_cfg.get(kind_name, {}) as Dictionary).get(key, [1.0, 2.0])


func _rand_range(r: Array) -> float:
	return _rng.randf_range(float(r[0]), float(r[1]))
