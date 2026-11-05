class_name Regions
extends RefCounted
## Gebiete der Welt (data/regions.json): Jede Zelle gehört zum nächsten Mittelpunkt eines Gebiets,
## gemessen an einer mit Rauschen verbogenen Position, damit die Grenzen natürlich verlaufen.
## Gespeichert in Blöcken zu STEP × STEP Zellen (für Grenzen, die ohnehin weich sind, reicht das).
## Jedes Gebiet hat eigene Farben, Blumen- und Büscheldichte und Objekt-Gewichte. Reine Logik, nie
## gespeichert: ergibt sich immer gleich aus den Daten.

const STEP := 4

var list: Array[Dictionary] = []   # {name, grass, dry, flowers, tufts, flower_color, flower_share, objects, extra}
var cols := 0
var rows := 0
var index := PackedByteArray()     # Gebiet je Block


func _init(map_w: int, map_h: int, data: Dictionary) -> void:
	cols = ceili(map_w / float(STEP))
	rows = ceili(map_h / float(STEP))
	index.resize(cols * rows)
	var points: Array[Vector2] = []
	var owner: Array[int] = []
	for r: Dictionary in data.get("regions", []):
		var k := list.size()
		list.append({
			"name": str(r.get("name", "")),
			"grass": _color(r.get("grass", [1, 1, 1])),
			"dry": _color(r.get("dry", [1, 1, 1])),
			"flowers": float(r.get("flowers", 1.0)),
			"tufts": float(r.get("tufts", 1.0)),
			"flower_color": _color(r.get("flower_color", [1, 1, 1])),
			"flower_share": float(r.get("flower_share", 0.0)),
			"objects": r.get("objects", {}),
			"extra": r.get("extra", {}),
		})
		for p: Array in r.get("points", []):
			points.append(Vector2(float(p[0]), float(p[1])))
			owner.append(k)
	if points.is_empty():
		return
	var warp := float(data.get("warp_cells", 0.0))
	var nx := FastNoiseLite.new()
	nx.seed = int(data.get("seed", 1))
	nx.frequency = 1.0 / maxf(float(data.get("warp_scale_cells", 140.0)), 1.0)
	var ny := FastNoiseLite.new()
	ny.seed = nx.seed + 101
	ny.frequency = nx.frequency
	for by in rows:
		for bx in cols:
			var c := (Vector2(bx, by) + Vector2(0.5, 0.5)) * STEP
			var w := c + Vector2(nx.get_noise_2dv(c), ny.get_noise_2dv(c)) * warp
			var best := 0
			var best_d := INF
			for i in points.size():
				var d := w.distance_squared_to(points[i])
				if d < best_d:
					best_d = d
					best = i
			index[by * cols + bx] = owner[best]


static func _color(a: Array) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]))


## Gebiet einer Zelle (Zellkoordinaten, auch Bruchteile). Außerhalb der Karte: nächster Rand.
func at_cell(c: Vector2) -> int:
	if list.is_empty():
		return 0
	var bx := clampi(int(c.x) / STEP, 0, cols - 1)
	var by := clampi(int(c.y) / STEP, 0, rows - 1)
	return index[by * cols + bx]


func at_px(p: Vector2, cell_px: float) -> int:
	return at_cell(p / cell_px)


func name_of(i: int) -> String:
	return list[i]["name"] if i >= 0 and i < list.size() else ""


## Wie gern steht eine Objektart in diesem Gebiet (1 = normal, 0 = nie)?
func object_weight(i: int, kind: String) -> float:
	if i < 0 or i >= list.size():
		return 1.0
	return float((list[i]["objects"] as Dictionary).get(kind, 1.0))


## Wie viele Objekte dieser Art zusätzlich nur in Gebiet i stehen (z. B. Bäume im Wald).
func extra_count(i: int, kind: String) -> int:
	return int((list[i]["extra"] as Dictionary).get(kind, 0))


func max_object_weight(kind: String) -> float:
	var m := 0.0
	for i in list.size():
		m = maxf(m, object_weight(i, kind))
	return m


## Anteil der Karte, der zu Gebiet i gehört (0..1).
func share(i: int) -> float:
	return index.count(i) / float(maxi(index.size(), 1))


## Merkt, in welchem Gebiet der Roboter ist. Ein Wechsel zählt erst, wenn er confirm_sec lang
## im neuen Gebiet bleibt (kein Flackern, wenn er an der Grenze entlangfährt).
class Watch:
	var current := -1
	var confirm_sec := 1.0
	var _cand := -1
	var _t := 0.0

	## true, wenn das Gebiet gerade gewechselt hat (auch beim ersten Aufruf nach reset).
	func update(region: int, delta: float) -> bool:
		if current < 0:
			current = region
			_cand = -1
			return true
		if region == current:
			_cand = -1
			return false
		if region != _cand:
			_cand = region
			_t = 0.0
		_t += delta
		if _t < confirm_sec:
			return false
		current = region
		_cand = -1
		return true

	func reset() -> void:
		current = -1
		_cand = -1
