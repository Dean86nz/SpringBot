class_name WorldObjects
extends RefCounted
## Verteilt die Objekte der Welt (data/objects.json): Bäume, Felsen, Teiche, Büsche frei in der
## Landschaft, dazu Baumstämme, Zäune und Steine am Wegrand. Zufällig, aber mit festem seed, also
## jedes Mal gleich. Nie auf Wegen oder Wasser, nie zu nah am Start, nie überlappend.
## Reine Logik. Ergebnis: Liste von {kind, pos (Pixel), angle, seed, block (Pixel), wayside}.
## Ob ein Objekt erwacht ist, steht nicht hier: das ergibt sich aus dem Grün unter ihm.

const KINDS := ["tree", "rock", "pond", "bush"]


static func place(grid: GroundGrid, cell_px: float, data: Dictionary, world: Dictionary, keep_free: Array[Vector2]) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("seed", 1))
	var out: Array[Dictionary] = []
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
					"seed": rng.randi(), "block": 0.0, "radius": ws_r, "wayside": true})
	for kind in KINDS:
		var t: Dictionary = types.get(kind, {})
		var r := float(t.get("radius_px", 50.0))
		for n in int(t.get("count", 0)):
			for k in tries:
				var pos := Vector2(rng.randf_range(r, size.x - r), rng.randf_range(r, size.y - r))
				if _fits(grid, cell_px, pos, r, out, gap, keep_free, free_px):
					out.append({"kind": kind, "pos": pos, "angle": rng.randf() * TAU, "seed": rng.randi(),
						"block": float(t.get("block_px", 0.0)), "radius": r, "wayside": false})
					break
	return out


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
