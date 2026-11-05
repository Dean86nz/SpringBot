class_name BeeSwarm
extends RefCounted
## Bienen als Helfer: Jede Biene fliegt zu einer grauen Stelle in der Nähe, schwebt dort kurz
## und begrünt beim Abflug einen kleinen Kreis. Findet sie in der Nähe nichts Graues, nimmt sie
## eine zufällige Grenzzelle der ganzen Karte (so schließen Bienen am Ende die letzten Lücken).
## Ist alles grün, benehmen sie sich wie echte Bienen: Sie fliegen zu Blüten auf der Wiese und zu
## erwachten Bäumen und Büschen (trees) in der Nähe des Stocks, verweilen dort und kriechen ab und zu
## in den Stock, um auszuruhen (rest: unsichtbar). Dürre Stellen meiden sie, dort blüht für sie nichts.
## Reine Logik, Positionen in Weltpixeln.

class Bee:
	var pos := Vector2.ZERO
	var target := Vector2.ZERO
	var hover := 0.0      # Restzeit über der Blüte; > 0 = schwebt
	var flying := false
	var idle := false     # Ziel ist nur ein Besuch (Blüte, Baum, Stock), nichts zu begrünen
	var rest := 0.0       # Restzeit im Stock; > 0 = unsichtbar


var bees: Array[Bee] = []
var hive := Vector2.ZERO
var cell_px := 24.0
var speed_px := 260.0
var bloom_radius := 2.3   # Zellen
var hover_sec := 2.0
var hop_min := 6.0        # Zellen
var hop_max := 18.0
var tries := 8
var blooms := PackedVector2Array()   # Orte (Pixel), an denen seit dem letzten Abholen etwas erblüht ist
var trees := PackedVector2Array()    # erwachte Bäume und Büsche nahe dem Stock (setzt main.gd)
var idle_radius := 16.0   # Zellen um den Stock, in denen Bienen ohne Arbeit Blüten besuchen
var last_pick_idle := false


func configure(cfg: Dictionary, p_hive: Vector2, p_cell_px: float) -> void:
	hive = p_hive
	cell_px = p_cell_px
	speed_px = float(cfg.get("speed_px", speed_px))
	bloom_radius = float(cfg.get("bloom_radius_cells", bloom_radius))
	hover_sec = float(cfg.get("hover_sec", hover_sec))
	hop_min = float(cfg.get("hop_min_cells", hop_min))
	hop_max = float(cfg.get("hop_max_cells", hop_max))
	tries = int(cfg.get("target_tries", tries))


## Passt die Zahl der Bienen an; neue starten am Stock.
func set_count(n: int) -> void:
	while bees.size() < n:
		var b := Bee.new()
		b.pos = hive
		b.target = hive
		bees.append(b)
	if bees.size() > n:
		bees.resize(n)


func update(delta: float, grid: GroundGrid, rng: RandomNumberGenerator, speed_factor: float = 1.0) -> int:
	var added := 0
	var step := speed_px * speed_factor * delta
	for b in bees:
		if b.rest > 0.0:
			b.rest -= delta
			if b.rest <= 0.0:
				b.target = pick_target(b.pos, grid, rng)
				b.idle = last_pick_idle
				b.flying = true
			continue
		if b.hover > 0.0:
			b.hover -= delta
			if b.hover <= 0.0:
				# Kleiner Versatz unterhalb einer Zelle: Flecken werden rund und verschieden statt rautenförmig
				var jitter := Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
				var n := grid.paint_circle(b.pos / cell_px + jitter, bloom_radius, true)
				added += n
				if n > 0:
					blooms.append(b.pos)
				b.target = pick_target(b.pos, grid, rng)
				b.idle = last_pick_idle
				b.flying = true
			continue
		var to := b.target - b.pos
		if to.length() <= step:
			b.pos = b.target
			b.flying = false
			# Über grauem Land schweben und blühen lassen; über Grün, Weg oder Wasser gleich weiterfliegen
			if grid.is_open(Vector2i(b.pos / cell_px), false):
				b.hover = hover_sec
			elif b.idle and b.pos.distance_to(hive) < cell_px:
				b.rest = rng.randf_range(3.0, 8.0)   # im Stock ausruhen
			elif b.idle:
				b.hover = rng.randf_range(1.5, 4.0)  # an der Blüte naschen
			else:
				b.target = pick_target(b.pos, grid, rng)
				b.idle = last_pick_idle
				b.flying = true
		else:
			b.pos += to / to.length() * step
	return added


## Nächstes Ziel: graue Zelle in hop_min..hop_max Zellen Abstand, sonst eine Grenzzelle,
## sonst (alles grün) ein Besuch: der Stock, ein Baum oder eine Blüte nahe dem Stock (last_pick_idle).
func pick_target(from: Vector2, grid: GroundGrid, rng: RandomNumberGenerator) -> Vector2:
	last_pick_idle = false
	for t in tries:
		var p := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(hop_min, hop_max) * cell_px
		var c := Vector2i(p / cell_px)
		if grid.is_open(c, false):
			return (Vector2(c) + Vector2(0.5, 0.5)) * cell_px
	if not grid.frontier.is_empty():
		var i := grid.frontier[rng.randi_range(0, grid.frontier.size() - 1)]
		return (Vector2(i % grid.width, i / grid.width) + Vector2(0.5, 0.5)) * cell_px
	last_pick_idle = true
	var r := rng.randf()
	if r < 0.2:
		return hive
	if r < 0.5 and not trees.is_empty():
		return trees[rng.randi() % trees.size()] + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, 40.0)
	for t in tries:
		var p := hive + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, idle_radius) * cell_px
		if grid.is_green(Vector2i(p / cell_px)):
			return p
	return hive
