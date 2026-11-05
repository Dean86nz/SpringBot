class_name Villagers
extends RefCounted
## Die Menschen des Dorfes (Phase 3): Ist die Region fertig, kehren sie zurück. Sie kommen von
## außerhalb des Dorfes zum Dorfplatz und schlendern danach zwischen Platz und Haustüren hin und her.
## Reine Deko und Logik in Weltpixeln; gezeichnet von VillagerView. Werte aus region.json ("village").

class Person:
	var pos := Vector2.ZERO
	var target := Vector2.ZERO
	var delay := 0.0     # Sekunden, bis die Person losgeht (gestaffelte Ankunft)
	var wait := 0.0      # Sekunden, die sie noch steht
	var look := 0        # Aussehen (Farben)
	var phase := 0.0     # Schritt-Animation
	var dir := 0.0       # Blickrichtung
	var arrived := false # schon einmal am Platz angekommen


var people: Array[Person] = []
var center := Vector2.ZERO     # Dorfplatz
var plaza_r := 200.0           # Radius des Platzes in Pixeln
var doors: Array[Vector2] = [] # vor jeder Haustür
var speed := 75.0
var wait_sec := Vector2(1.5, 5.0)
var arrive_from := 700.0       # Startabstand zum Platz in Pixeln
var spread := 4.0              # Ankunft verteilt über so viele Sekunden
var _rng := RandomNumberGenerator.new()


## cfg: "village" aus region.json; doors in Weltpixeln.
func _init(cfg: Dictionary = {}, cell_px: float = 24.0, p_doors: Array[Vector2] = [], rng_seed: int = 3) -> void:
	_rng.seed = rng_seed
	var c: Array = cfg.get("center", [0, 0])
	center = (Vector2(c[0], c[1]) + Vector2(0.5, 0.5)) * cell_px
	plaza_r = float(cfg.get("plaza_radius", 8.0)) * cell_px
	doors = p_doors
	speed = float(cfg.get("people_speed_px", 75.0))
	var ws: Array = cfg.get("wait_sec", [1.5, 5.0])
	wait_sec = Vector2(ws[0], ws[1])
	arrive_from = float(cfg.get("arrive_from_cells", 30.0)) * cell_px
	spread = float(cfg.get("arrive_spread_sec", 4.0))


## Rückkehr: count Menschen kommen gestaffelt von außen zum Platz.
func arrive(count: int) -> void:
	people.clear()
	for i in count:
		var p := _make()
		p.pos = center + Vector2.from_angle(_rng.randf() * TAU) * arrive_from
		p.target = _plaza_spot()
		p.delay = _rng.randf() * spread
		people.append(p)


## Schon zurück (Spielstand geladen): count Menschen stehen gleich verteilt im Dorf.
func settle(count: int) -> void:
	people.clear()
	for i in count:
		var p := _make()
		p.arrived = true
		p.pos = _plaza_spot() if i % 2 == 0 or doors.is_empty() else doors[_rng.randi() % doors.size()]
		p.target = p.pos
		p.wait = _rng.randf_range(0.0, wait_sec.y)
		people.append(p)


func clear() -> void:
	people.clear()


func update(delta: float) -> void:
	for p in people:
		if p.delay > 0.0:
			p.delay -= delta
			continue
		if p.wait > 0.0:
			p.wait -= delta
			continue
		var to := p.target - p.pos
		var step := speed * delta
		if to.length() <= step:
			p.pos = p.target
			p.arrived = true
			p.wait = _rng.randf_range(wait_sec.x, wait_sec.y)
			# nächstes Ziel: meist der Platz, manchmal eine Haustür
			p.target = doors[_rng.randi() % doors.size()] if not doors.is_empty() and _rng.randf() < 0.4 else _plaza_spot()
			continue
		p.pos += to.normalized() * step
		p.dir = to.angle()
		p.phase += delta * 9.0


## Wie viele sind schon am Platz angekommen?
func count_arrived() -> int:
	var n := 0
	for p in people:
		if p.arrived:
			n += 1
	return n


func _make() -> Person:
	var p := Person.new()
	p.look = _rng.randi() % 64
	p.phase = _rng.randf() * TAU
	return p


## Zufälliger Punkt auf dem Platz (nicht am Brunnen in der Mitte).
func _plaza_spot() -> Vector2:
	return center + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.4, 0.85) * plaza_r
