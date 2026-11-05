class_name WorldMap
extends RefCounted
## Baut Wege und Wasser aus data/world.json ins Gelände des Bodenrasters.
## Jede Linie ist eine Catmull-Rom-Kurve durch ihre Punkte, die zusätzlich leicht schlängelt.
## Für jede Zelle wird der Abstand zur nächsten Linie berechnet: innerhalb der halben Breite
## ist die Zelle Wasser bzw. Weg (Wasser hat Vorrang). Die weichen Masken (0,5 genau auf dem
## Rand) gehen an die Darstellung, damit Ufer und Wegränder rund statt treppig aussehen.
## Wo ein Weg Wasser kreuzt, entsteht eine Brücke; ihre Wasserzellen werden befahrbar.
## Plätze ("plazas": Mitte und Radius in Zellen) sind runde, befestigte Flächen wie Wege (z. B. Dorfplatz).
## Alles in Zellen, reine Logik. Gibt die Brücken zurück: {center, dir, length, width}.

const FAR := 1.0e9


static func build(grid: GroundGrid, data: Dictionary) -> Array[Dictionary]:
	var n := grid.width * grid.height
	var water := PackedFloat32Array()   # Abstand zum Rand: < 0 innen
	water.resize(n)
	water.fill(FAR)
	var path := PackedFloat32Array()
	path.resize(n)
	path.fill(FAR)
	for r: Dictionary in data.get("rivers", []):
		_raster(grid, curve(r), float(r.get("width", 4.0)) * 0.5, water)
	var path_lines: Array[PackedVector2Array] = []
	for p: Dictionary in data.get("paths", []):
		var line := curve(p)
		path_lines.append(line)
		_raster(grid, line, float(p.get("width", 4.0)) * 0.5, path)
	for pl: Dictionary in data.get("plazas", []):
		var c: Array = pl.get("center", [0, 0])
		_raster(grid, PackedVector2Array([Vector2(c[0], c[1]), Vector2(c[0], c[1]) + Vector2(0.01, 0)]), float(pl.get("radius", 6.0)), path)
	var t := PackedByteArray()
	t.resize(n)
	var soft := PackedByteArray()
	soft.resize(n * 2)
	for i in n:
		if water[i] <= 0.0:
			t[i] = GroundGrid.WATER
		elif path[i] <= 0.0:
			t[i] = GroundGrid.PATH
		soft[i * 2] = int(clampf(0.5 - path[i], 0.0, 1.0) * 255.0)
		soft[i * 2 + 1] = int(clampf(0.5 - water[i], 0.0, 1.0) * 255.0)
	var bridges: Array[Dictionary] = []
	var bw := float(data.get("bridge_width", 6.0))
	var over := float(data.get("bridge_overhang", 1.5))
	for line in path_lines:
		for b in _find_crossings(grid, line, t, bw, over):
			_mark_bridge(grid, b, t)
			bridges.append(b)
	grid.set_terrain(t, soft)
	return bridges


## Punkte der Linie im Abstand von etwa einer Zelle, mit leichtem Schlängeln quer zur Richtung.
static func curve(line: Dictionary) -> PackedVector2Array:
	var ctrl: Array = line.get("points", [])
	var pts := PackedVector2Array()
	if ctrl.size() < 2:
		return pts
	var cp: Array[Vector2] = []
	for c: Array in ctrl:
		cp.append(Vector2(float(c[0]), float(c[1])))
	for k in cp.size() - 1:
		var p0 := cp[maxi(k - 1, 0)]
		var p1 := cp[k]
		var p2 := cp[k + 1]
		var p3 := cp[mini(k + 2, cp.size() - 1)]
		var steps := maxi(int(p1.distance_to(p2)), 1)
		for s in steps:
			var u := float(s) / steps
			var u2 := u * u
			var u3 := u2 * u
			pts.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3))
	pts.append(cp[-1])
	var amp := float(line.get("wiggle", 0.0))
	if amp <= 0.0:
		return pts
	var seed := cp[0].x * 0.37 + cp[0].y * 0.71
	var out := PackedVector2Array()
	var s_len := 0.0
	for i in pts.size():
		if i > 0:
			s_len += pts[i].distance_to(pts[i - 1])
		var tan := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var off := sin(s_len * 0.09 + seed) * amp + sin(s_len * 0.031 + seed * 2.0) * amp * 0.6
		# Enden nicht verschieben, damit Linien sauber am Kartenrand oder an anderen Linien beginnen
		var fade := clampf(minf(i, pts.size() - 1 - i) / 12.0, 0.0, 1.0)
		out.append(pts[i] + tan.orthogonal() * off * fade)
	return out


## Trägt für jede Zelle nahe der Linie den Abstand zum Rand ein (Abstand − halbe Breite), das Minimum zählt.
static func _raster(grid: GroundGrid, pts: PackedVector2Array, hw: float, dist: PackedFloat32Array) -> void:
	var reach := hw + 1.0
	for k in pts.size() - 1:
		var a := pts[k]
		var b := pts[k + 1]
		var ab := b - a
		var ab2 := maxf(ab.length_squared(), 0.0001)
		var x0 := maxi(int(floor(minf(a.x, b.x) - reach)), 0)
		var x1 := mini(int(ceil(maxf(a.x, b.x) + reach)), grid.width - 1)
		var y0 := maxi(int(floor(minf(a.y, b.y) - reach)), 0)
		var y1 := mini(int(ceil(maxf(a.y, b.y) + reach)), grid.height - 1)
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var c := Vector2(x + 0.5, y + 0.5)
				var h := clampf((c - a).dot(ab) / ab2, 0.0, 1.0)
				var d := c.distance_to(a + ab * h) - hw
				var i := y * grid.width + x
				if d < dist[i]:
					dist[i] = d


## Abschnitte, auf denen die Weglinie über Wasser läuft → je eine Brücke über den ganzen Abschnitt.
static func _find_crossings(grid: GroundGrid, line: PackedVector2Array, t: PackedByteArray, bw: float, over: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start := -1
	for i in line.size():
		var c := Vector2i(line[i])
		var wet := grid.in_bounds(c) and t[c.y * grid.width + c.x] == GroundGrid.WATER
		if wet and start < 0:
			start = i
		elif not wet and start >= 0:
			var a := line[maxi(start - 1, 0)]
			var b := line[i]
			out.append({"center": (a + b) * 0.5, "dir": (b - a).normalized(), "length": a.distance_to(b) + over * 2.0, "width": bw})
			start = -1
	return out


static func _mark_bridge(grid: GroundGrid, b: Dictionary, t: PackedByteArray) -> void:
	var c: Vector2 = b["center"]
	var dir: Vector2 = b["dir"]
	var half_l := float(b["length"]) * 0.5
	var half_w := float(b["width"]) * 0.5
	var r := int(ceil(half_l + half_w))
	for y in range(maxi(int(c.y) - r, 0), mini(int(c.y) + r, grid.height - 1) + 1):
		for x in range(maxi(int(c.x) - r, 0), mini(int(c.x) + r, grid.width - 1) + 1):
			var d := Vector2(x + 0.5, y + 0.5) - c
			var i := y * grid.width + x
			if absf(d.dot(dir)) <= half_l and absf(d.dot(dir.orthogonal())) <= half_w and t[i] == GroundGrid.WATER:
				t[i] = GroundGrid.BRIDGE
