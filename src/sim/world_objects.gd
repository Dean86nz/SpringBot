class_name WorldObjects
extends RefCounted
## Verteilt die Objekte der Welt (data/objects.json): Bäume (Laubbaum, Tanne, Birke, Obstbaum,
## Weide, junger Baum), Felsen, Teiche, Büsche frei in der Landschaft, dazu Baumstämme, Zäune und
## Steine am Wegrand. Zufällig, aber mit festem seed, also jedes Mal gleich. Nie auf Wegen oder
## Wasser, nie zu nah am Start, nie überlappend. Weiden stehen nur nahe am Wasser (near_water_cells).
## Jedes Objekt bekommt eine eigene Größe aus "size" [min, max]; Radius und Hindernis wachsen mit.
## Reine Logik. Ergebnis: Liste von {kind, pos (Pixel), angle, seed, block (Pixel), radius, size, quiet}.
## quiet: erwacht leise (ohne Klang, wenige Blätter), z. B. Wegrand und junge Bäume.
## Mit Gebieten (Areas) steht jede Art bevorzugt dort, wo ihr Gewicht hoch ist (z. B. Obstbäume
## im Obstgarten); dazu kommen je Gebiet "extra" Objekte, die nur dort stehen (dichter Wald).
## fixed: Objekte mit fester Lage (Häuser, Brunnen des Dorfes), schon im Ergebnis-Format; sie kommen
## zuerst und ohne Prüfung, alle anderen halten Abstand zu ihnen.
## Ob ein Objekt erwacht ist, steht nicht hier: das ergibt sich aus dem Grün unter ihm.

## Reihenfolge = Platzierung: Große und wählerische zuerst, damit sie noch Platz finden.
const KINDS := ["pond", "willow", "oak", "fir", "rock", "fruit", "birch", "bush", "sapling"]


static func place(grid: GroundGrid, cell_px: float, data: Dictionary, world: Dictionary, keep_free: Array[Vector2], areas: Areas = null, fixed: Array[Dictionary] = []) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 1))
	var out: Array[Dictionary] = fixed.duplicate()
	var gap := float(data.get("min_gap_px", 24.0))
	var free_px := float((data.get("keep_free", {}) as Dictionary).get("radius_cells", 10.0)) * cell_px
	var tries := int(data.get("tries", 60))
	var types: Dictionary = data.get("types", {})
	var size := Vector2(grid.width, grid.height) * cell_px
	# Wegrand zuerst: diese Plätze sind durch die Wege vorgegeben
	var ws: Dictionary = data.get("wayside", {})
	var kinds: Array = ws.get("kinds", [])
	var every: Array = ws.get("every_cells", [14, 24])
	var ws_r := float(ws.get("radius_px", 40.0))
	for p: Dictionary in world.get("paths", []):
		if kinds.is_empty():
			break
		var line := WorldMap.curve(p)
		var hw := float(p.get("width", 4.0)) * 0.5 + float(ws.get("offset_cells", 1.4))
		var next := rng.randf_range(float(every[0]), float(every[1]))
		var walked := 0.0
		for i in range(1, line.size() - 1):
			walked += line[i].distance_to(line[i - 1])
			if walked < next:
				continue
			walked = 0.0
			next = rng.randf_range(float(every[0]), float(every[1]))
			var tan := (line[i + 1] - line[i - 1]).normalized()
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var pos := (line[i] + tan.orthogonal() * side * hw) * cell_px
			if _fits(grid, cell_px, pos, ws_r, out, gap, keep_free, free_px):
				out.append({"kind": kinds[rng.randi() % kinds.size()], "pos": pos, "angle": tan.angle(),
					"seed": rng.randi(), "block": 0.0, "radius": ws_r, "size": 1.0, "quiet": true})
	for kind in KINDS:
		var t: Dictionary = types.get(kind, {})
		var sz: Array = t.get("size", [1.0, 1.0])
		var water := float(t.get("near_water_cells", 0.0))
		var max_w := areas.max_object_weight(kind) if areas else 0.0
		var only: Array[int] = []   # je Objekt: -1 = überall (nach Gewicht), sonst nur in diesem Gebiet
		for n in int(t.get("count", 0)):
			only.append(-1)
		if areas:
			for i in areas.list.size():
				for n in areas.extra_count(i, kind):
					only.append(i)
		for home in only:
			var f := rng.randf_range(float(sz[0]), float(sz[1]))
			var r := float(t.get("radius_px", 50.0)) * f
			var n_tries := int(t.get("tries", tries)) * (1 if home < 0 else 5)
			for k in n_tries:
				var pos := Vector2(rng.randf_range(r, size.x - r), rng.randf_range(r, size.y - r))
				if home >= 0:
					if areas.at_px(pos, cell_px) != home:
						continue
				elif max_w > 0.0 and rng.randf() * max_w >= areas.object_weight(areas.at_px(pos, cell_px), kind):
					continue
				if water > 0.0 and not _near_water(grid, cell_px, pos, r + water * cell_px):
					continue
				if _fits(grid, cell_px, pos, r, out, gap, keep_free, free_px):
					out.append({"kind": kind, "pos": pos, "angle": rng.randf() * TAU, "seed": rng.randi(),
						"block": float(t.get("block_px", 0.0)) * f, "radius": r, "size": f,
						"quiet": bool(t.get("quiet", false))})
					break
	return out


## Liegt im Umkreis reach (Pixel) um pos Wasser? Stichproben auf 16 Strahlen.
static func _near_water(grid: GroundGrid, cell_px: float, pos: Vector2, reach: float) -> bool:
	for k in 16:
		var dir := Vector2.from_angle(k * TAU / 16.0)
		for s in range(1, 6):
			var c := Vector2i((pos + dir * reach * s / 5.0) / cell_px)
			if grid.in_bounds(c) and grid.terrain[c.y * grid.width + c.x] == GroundGrid.WATER:
				return true
	return false


## Nur Land unter dem ganzen Kreis, Abstand zu anderen Objekten und zum Start.
static func _fits(grid: GroundGrid, cell_px: float, pos: Vector2, r: float, placed: Array[Dictionary], gap: float, keep_free: Array[Vector2], free_px: float) -> bool:
	for f in keep_free:
		if pos.distance_to(f) < free_px + r:
			return false
	for o in placed:
		if pos.distance_to(o["pos"]) < r + float(o["radius"]) + gap:
			return false
	var c0 := Vector2i((pos - Vector2(r, r)) / cell_px)
	var c1 := Vector2i((pos + Vector2(r, r)) / cell_px)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var cc := (Vector2(x, y) + Vector2(0.5, 0.5)) * cell_px
			if cc.distance_to(pos) > r:
				continue
			if not grid.in_bounds(Vector2i(x, y)) or grid.terrain[y * grid.width + x] != GroundGrid.LAND:
				return false
	return true
