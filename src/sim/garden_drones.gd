class_name GardenDrones
extends RefCounted
## Gärtner-Drohnen (Helfer ab der Großstadt): Jede Drohne startet an der Ladestation (dock), sucht sich
## ein Rechteck mit viel Grau (einen Innenhof, ein Dach, eine Brache) und fliegt darüber feste Runden:
## Rechteck für Rechteck von außen nach innen, wie beim Rasenmähen, und sprüht dabei Grün. Über Straßen,
## Häuser und Wasser fliegt sie einfach hinweg; dürre Stellen begrünt sie auch. Danach zurück zum Laden.
## Ist nichts Graues mehr da, schwebt sie gemächlich um die Station und lädt öfter.
## Reine Logik, Positionen in Weltpixeln; gezeichnet von DroneView. Neue Grünflecken stehen in blooms.

enum State { CHARGE, FLY, MOW }

class Drone:
	var pos := Vector2.ZERO
	var target := Vector2.ZERO
	var state := State.CHARGE
	var rest := 0.0
	var path := PackedVector2Array()   # Runden über dem Rechteck (Ecken), leer = Heimflug oder Schweben
	var idx := 0
	var carry := 0.0
	var dir := Vector2.RIGHT
	var idle := false


var drones: Array[Drone] = []
var dock := Vector2.ZERO
var cell_px := 24.0
var speed_px := 280.0
var area_cells := 8.0          # halbe Seitenlänge des Rechtecks
var spray_cells := 1.8         # Radius des Sprühkreises
var charge_sec := 5.0
var range_cells := Vector2(15, 60)
var tries := 12
var blooms := PackedVector2Array()
var mist: Array[Vector3] = []   # Sprühnebel: x, y, Zeitpunkt (für die Darstellung)
var time := 0.0
const MIST_SEC := 0.6


func configure(cfg: Dictionary, p_dock: Vector2, p_cell_px: float) -> void:
	dock = p_dock
	cell_px = p_cell_px
	speed_px = float(cfg.get("speed_px", speed_px))
	area_cells = float(cfg.get("area_cells", area_cells))
	spray_cells = float(cfg.get("spray_cells", spray_cells))
	charge_sec = float(cfg.get("charge_sec", charge_sec))
	var r: Array = cfg.get("range_cells", [range_cells.x, range_cells.y])
	range_cells = Vector2(r[0], r[1])
	tries = int(cfg.get("target_tries", tries))


## Passt die Zahl der Drohnen an; neue starten nacheinander an der Station.
func set_count(n: int) -> void:
	while drones.size() < n:
		var d := Drone.new()
		d.pos = dock
		d.target = dock
		d.rest = 0.7 * drones.size()
		drones.append(d)
	if drones.size() > n:
		drones.resize(n)


## Ein Bild. Gibt die Zahl frisch begrünter Zellen zurück.
func update(delta: float, grid: GroundGrid, rng: RandomNumberGenerator, speed_factor: float = 1.0) -> int:
	time += delta
	while not mist.is_empty() and time - mist[0].z > MIST_SEC:
		mist.pop_front()
	var added := 0
	for d in drones:
		var step := speed_px * speed_factor * delta * (0.5 if d.idle else 1.0)
		match d.state:
			State.CHARGE:
				d.rest -= delta
				if d.rest <= 0.0:
					_plan(d, grid, rng)
			State.FLY:
				if _move(d, step):
					if not d.path.is_empty():
						d.state = State.MOW
						d.idx = 1
						d.carry = 0.0
					elif d.pos.distance_to(dock) < 2.0:
						d.state = State.CHARGE
						d.rest = charge_sec * (2.0 if d.idle else 1.0) * rng.randf_range(0.85, 1.15)
					else:
						_plan(d, grid, rng)
			State.MOW:
				added += _mow(d, step, grid, rng)
	return added


func _move(d: Drone, step: float) -> bool:
	var to := d.target - d.pos
	if to.length() <= step:
		d.pos = d.target
		return true
	d.dir = to.normalized()
	d.pos += d.dir * step
	return false


## Runden fliegen und sprühen: alle paar Pixel ein Sprühkreis; am Ende zurück zur Station.
func _mow(d: Drone, step: float, grid: GroundGrid, rng: RandomNumberGenerator) -> int:
	var added := 0
	var left := step
	while left > 0.0 and d.idx < d.path.size():
		d.target = d.path[d.idx]
		var to := d.target - d.pos
		var s := minf(left, to.length())
		var reached := s >= to.length()
		if to.length() > 0.0:
			d.dir = to.normalized()
		d.pos = d.target if reached else d.pos + d.dir * s
		left -= s
		d.carry += s
		var every := maxf(0.6, spray_cells * 0.8) * cell_px
		while d.carry >= every:
			d.carry -= every
			var n := grid.paint_circle(d.pos / cell_px, spray_cells)
			added += n
			if n > 0 and rng.randf() < 0.25:
				blooms.append(d.pos)
			mist.append(Vector3(d.pos.x, d.pos.y, time))
		if reached:
			d.idx += 1
	if d.idx >= d.path.size():
		d.path = PackedVector2Array()
		d.target = dock
		d.state = State.FLY
	return added


## Nächstes Rechteck: einige zufällige Mitten (in Reichweite oder an der Grenze des Grüns), die mit dem
## meisten Grau gewinnt; daraus die Runden von außen nach innen. Nichts Graues: Schweben um die Station.
func _plan(d: Drone, grid: GroundGrid, rng: RandomNumberGenerator) -> void:
	var h := area_cells * cell_px
	var best := 0
	var best_c := Vector2.ZERO
	for t in tries:
		var c: Vector2
		if t % 2 == 1 and not grid.frontier.is_empty():
			var i := grid.frontier[rng.randi_range(0, grid.frontier.size() - 1)]
			c = (Vector2(i % grid.width, i / grid.width) + Vector2(0.5, 0.5)) * cell_px
		else:
			c = d.pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(range_cells.x, range_cells.y) * cell_px
		c = c.clamp(Vector2.ONE * h, Vector2(grid.width, grid.height) * cell_px - Vector2.ONE * h)
		var score := _grey_in(grid, c, h)
		if score > best:
			best = score
			best_c = c
	if best == 0:
		d.idle = true
		d.path = PackedVector2Array()
		if d.pos.distance_to(dock) > 2.0 and rng.randf() < 0.4:
			d.target = dock
		else:
			d.target = dock + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, 9.0) * cell_px
		d.state = State.FLY
		return
	d.idle = false
	d.path = rounds(best_c, h, spray_cells * cell_px * 1.7)
	d.target = d.path[0]
	d.state = State.FLY


## Runden über einem Quadrat (Mitte c, halbe Seite h), jede Runde um step enger, zum Schluss die Mitte.
static func rounds(c: Vector2, h: float, step: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k := h
	while k > step * 0.5:
		pts.append_array([c + Vector2(-k, -k), c + Vector2(k, -k), c + Vector2(k, k), c + Vector2(-k, k), c + Vector2(-k, -k + step)])
		k -= step
	pts.append(c)
	return pts


## Graue Zellen im Quadrat (Stichproben alle zwei Zellen).
func _grey_in(grid: GroundGrid, c: Vector2, h: float) -> int:
	var n := 0
	var s := cell_px * 2.0
	var y := -h
	while y <= h:
		var x := -h
		while x <= h:
			if grid.is_open(Vector2i((c + Vector2(x, y)) / cell_px)):
				n += 1
			x += s
		y += s
	return n
