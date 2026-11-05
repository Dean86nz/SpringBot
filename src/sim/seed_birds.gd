class_name SeedBirds
extends RefCounted
## Samenvögel (Helfer ab der Region Felder und Vorort): Schwärme fliegen vom Vogelhäuschen (nest) weit
## hinaus und säen im Flug einen geraden Streifen Grün. Den Streifen wählen sie so, dass er möglichst
## viel graues Land kreuzt (einige Versuche, der beste gewinnt). Nach ein paar Streifen kehren sie heim
## und rasten kurz. Ist alles grün, ziehen sie gemächliche Runden um das Häuschen und rasten öfter.
## Reine Logik, Positionen in Weltpixeln; gezeichnet von BirdView. Fertige Saat-Orte stehen in blooms
## (für Blütenblätter), fallende Samen in seeds (Weltpixel und Zeitpunkt, für die Darstellung).

enum State { REST, FLY, SOW }

class Flock:
	var pos := Vector2.ZERO
	var target := Vector2.ZERO
	var dir := Vector2.RIGHT     # Flugrichtung (auch beim Säen)
	var sow_dir := Vector2.RIGHT # Richtung des geplanten Streifens
	var state := State.REST
	var rest := 0.0
	var sow_left := 0.0          # Pixel Streifen, die noch zu säen sind
	var carry := 0.0             # Pixel seit dem letzten Samen
	var trips := 0               # Streifen seit dem letzten Besuch im Häuschen
	var idle := false            # nichts mehr zu säen: Runden um das Häuschen


var flocks: Array[Flock] = []
var nest := Vector2.ZERO
var cell_px := 24.0
var speed_px := 320.0
var strip_cells := 30.0
var width_cells := 1.6          # Halbbreite des Streifens (Radius der Samenkreise)
var rest_sec := 4.0
var range_cells := Vector2(20, 70)   # so weit liegt der nächste Streifen
var trips_home := 3
var tries := 10
var flock_size := 5             # Vögel je Schwarm (nur Darstellung)
var blooms := PackedVector2Array()
var seeds: Array[Vector3] = []  # x, y, Zeitpunkt (time) des Abwurfs
var time := 0.0
const SEED_SEC := 0.5


func configure(cfg: Dictionary, p_nest: Vector2, p_cell_px: float) -> void:
	nest = p_nest
	cell_px = p_cell_px
	speed_px = float(cfg.get("speed_px", speed_px))
	strip_cells = float(cfg.get("strip_cells", strip_cells))
	width_cells = float(cfg.get("width_cells", width_cells))
	rest_sec = float(cfg.get("rest_sec", rest_sec))
	var r: Array = cfg.get("range_cells", [range_cells.x, range_cells.y])
	range_cells = Vector2(r[0], r[1])
	trips_home = int(cfg.get("trips_home", trips_home))
	tries = int(cfg.get("target_tries", tries))
	flock_size = int(cfg.get("flock_size", flock_size))


## Passt die Zahl der Schwärme an; neue starten (nacheinander) im Häuschen.
func set_count(n: int) -> void:
	while flocks.size() < n:
		var f := Flock.new()
		f.pos = nest
		f.target = nest
		f.rest = 0.6 * flocks.size()
		flocks.append(f)
	if flocks.size() > n:
		flocks.resize(n)


## Ein Bild. Gibt die Zahl frisch begrünter Zellen zurück.
func update(delta: float, grid: GroundGrid, rng: RandomNumberGenerator, speed_factor: float = 1.0) -> int:
	time += delta
	while not seeds.is_empty() and time - seeds[0].z > SEED_SEC:
		seeds.pop_front()
	var added := 0
	for f in flocks:
		match f.state:
			State.REST:
				f.rest -= delta
				if f.rest <= 0.0:
					_plan(f, grid, rng)
			State.FLY:
				var spd := speed_px * speed_factor * (0.55 if f.idle else 1.0)
				if _fly(f, spd * delta):
					_arrived(f, grid, rng)
			State.SOW:
				added += _sow(f, speed_px * speed_factor * delta, grid, rng)
	return added


## Ein Stück Richtung Ziel; true, wenn angekommen. Die Richtung dreht sanft (Kurven statt Ecken).
func _fly(f: Flock, step: float) -> bool:
	var to := f.target - f.pos
	if to.length() <= step:
		f.pos = f.target
		return true
	var want := to.normalized()
	f.dir = f.dir.slerp(want, minf(1.0, step / 60.0)).normalized() if f.dir.dot(want) > -0.95 else want
	if to.length() < step * 12.0:
		f.dir = want   # kurz vor dem Ziel: geradewegs hin (kein Kreisen ums Ziel)
	# nie vom Ziel wegfliegen: Mindestanteil Richtung Ziel
	var d := (f.dir * 0.6 + want * 0.4).normalized()
	f.pos += d * step
	return false


func _arrived(f: Flock, grid: GroundGrid, rng: RandomNumberGenerator) -> void:
	if f.sow_left > 0.0:
		f.state = State.SOW
		f.dir = f.sow_dir
		return
	if f.pos.distance_to(nest) < 2.0:
		f.state = State.REST
		f.trips = 0
		f.rest = rest_sec * (2.5 if f.idle else 1.0) * rng.randf_range(0.8, 1.2)
		return
	_plan(f, grid, rng)


## Säen: geradeaus, alle paar Pixel ein Samenkreis. Am Ende des Streifens (oder am Kartenrand) weiter.
func _sow(f: Flock, step: float, grid: GroundGrid, rng: RandomNumberGenerator) -> int:
	var added := 0
	f.pos += f.dir * step
	f.sow_left -= step
	f.carry += step
	var every := maxf(0.6, width_cells * 0.7) * cell_px
	while f.carry >= every:
		f.carry -= every
		var at := f.pos - f.dir * f.carry
		var jitter := f.dir.orthogonal() * rng.randf_range(-0.4, 0.4) * width_cells * cell_px
		var n := grid.paint_circle((at + jitter) / cell_px, width_cells)
		added += n
		seeds.append(Vector3(at.x + jitter.x, at.y + jitter.y, time))
		if n > 0 and rng.randf() < 0.3:
			blooms.append(at)
	var c := Vector2i(f.pos / cell_px)
	if f.sow_left <= 0.0 or not grid.in_bounds(c):
		f.sow_left = 0.0
		f.trips += 1
		if f.trips >= trips_home:
			_go_home(f)
		else:
			_plan(f, grid, rng)
	return added


func _go_home(f: Flock) -> void:
	f.target = nest
	f.state = State.FLY


## Nächster Streifen: einige zufällige Anfänge (in Reichweite oder an der Grenze des Grüns) und Richtungen,
## der mit dem meisten grauen Land gewinnt. Nichts Graues mehr: eine gemächliche Runde ums Häuschen.
func _plan(f: Flock, grid: GroundGrid, rng: RandomNumberGenerator) -> void:
	var len_px := strip_cells * cell_px
	var best := 0
	var best_start := Vector2.ZERO
	var best_dir := Vector2.RIGHT
	for t in tries:
		var start: Vector2
		if t % 2 == 1 and not grid.frontier.is_empty():
			var i := grid.frontier[rng.randi_range(0, grid.frontier.size() - 1)]
			start = (Vector2(i % grid.width, i / grid.width) + Vector2(0.5, 0.5)) * cell_px
		else:
			start = f.pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(range_cells.x, range_cells.y) * cell_px
		start = start.clamp(Vector2.ONE * cell_px, Vector2(grid.width - 1, grid.height - 1) * cell_px)
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var score := _grey_along(grid, start, dir, len_px)
		if score > best:
			best = score
			best_start = start
			best_dir = dir
	if best == 0:
		f.idle = true
		f.sow_left = 0.0
		if f.pos.distance_to(nest) > 2.0 and rng.randf() < 0.35:
			_go_home(f)
		else:
			f.target = nest + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6.0, 18.0) * cell_px
			f.state = State.FLY
		return
	f.idle = false
	f.target = best_start
	f.sow_left = len_px
	f.carry = 0.0
	f.sow_dir = best_dir
	f.state = State.FLY


## Graue Zellen entlang eines Streifens (alle zwei Zellen eine Probe).
func _grey_along(grid: GroundGrid, start: Vector2, dir: Vector2, len_px: float) -> int:
	var n := 0
	var step := cell_px * 2.0
	var d := 0.0
	while d < len_px:
		if grid.is_open(Vector2i((start + dir * d) / cell_px)):
			n += 1
		d += step
	return n
