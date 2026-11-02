class_name GroundGrid
extends RefCounted
## Der Boden als Raster: je Zelle ein Byte (0 = grau, 255 = grün).
## Reine Logik ohne Darstellung. Der begrünte Anteil wird mitgezählt, nie neu durchsucht.
## Geänderte Zellen landen in einem Schmutz-Rechteck, das die Darstellung abholt.
## Die Grenze (graue Zellen mit grünem Nachbarn) wird laufend mitgeführt: Liste plus
## Positionsindex, damit Hinzufügen, Entfernen und zufälliges Ziehen O(1) sind.

const GREY := 0
const GREEN := 255

var width := 0
var height := 0
var cells := PackedByteArray()
var green_count := 0
var frontier := PackedInt32Array()   # Zellindizes der Grenze
var _slot := PackedInt32Array()      # Zellindex → Position in frontier, -1 = nicht in der Grenze
var _dirty := Rect2i()
var _has_dirty := false


func _init(w: int = 0, h: int = 0) -> void:
	if w > 0 and h > 0:
		setup(w, h)


func setup(w: int, h: int) -> void:
	width = w
	height = h
	cells = PackedByteArray()
	cells.resize(w * h)
	frontier = PackedInt32Array()
	_slot = PackedInt32Array()
	_slot.resize(w * h)
	_slot.fill(-1)
	green_count = 0
	_dirty = Rect2i(0, 0, w, h)
	_has_dirty = true


func total() -> int:
	return width * height


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_green(c: Vector2i) -> bool:
	return in_bounds(c) and cells[c.y * width + c.x] == GREEN


## Anteil der begrünten Fläche, 0..1.
func coverage() -> float:
	return 0.0 if total() == 0 else float(green_count) / float(total())


## Macht eine Zelle grün. true, wenn sie vorher grau war.
func set_green(c: Vector2i) -> bool:
	if not in_bounds(c):
		return false
	if not _green_index(c.y * width + c.x):
		return false
	_mark(Rect2i(c, Vector2i.ONE))
	return true


## Begrünt alle Zellen, deren Mittelpunkt im Kreis liegt. center und radius in Zelleinheiten
## (Zelle (x, y) hat ihren Mittelpunkt bei x + 0,5 / y + 0,5). Gibt die Zahl neuer grüner Zellen zurück.
func paint_circle(center: Vector2, radius: float) -> int:
	var x0 := maxi(int(floor(center.x - radius)), 0)
	var x1 := mini(int(ceil(center.x + radius)), width - 1)
	var y0 := maxi(int(floor(center.y - radius)), 0)
	var y1 := mini(int(ceil(center.y + radius)), height - 1)
	if x0 > x1 or y0 > y1:
		return 0
	var r2 := radius * radius
	var added := 0
	for y in range(y0, y1 + 1):
		var dy := y + 0.5 - center.y
		var row := y * width
		for x in range(x0, x1 + 1):
			var dx := x + 0.5 - center.x
			if dx * dx + dy * dy <= r2 and _green_index(row + x):
				added += 1
	if added > 0:
		_mark(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
	return added


## Selbstausbreitung: höchstens `events` Zellen begrünen, jede an einer zufälligen Grenzzelle.
## Ist reach ≥ 2, wird mit Wahrscheinlichkeit seed_chance stattdessen ein Samen 2..reach Zellen
## weit geworfen (landet er auf Grün oder außerhalb, wächst doch die Grenzzelle).
## Jedes Ereignis begrünt also genau eine Zelle: Die Weite ändert den Ort, nicht das Tempo.
func spread(events: int, reach: int, seed_chance: float, rng: RandomNumberGenerator) -> int:
	var added := 0
	for e in events:
		if frontier.is_empty():
			break
		var i := frontier[rng.randi_range(0, frontier.size() - 1)]
		var c := Vector2i(i % width, i / width)
		if reach >= 2 and rng.randf() < seed_chance:
			var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2.0, float(reach))
			if set_green(c + Vector2i(roundi(off.x), roundi(off.y))):
				added += 1
				continue
		if set_green(c):
			added += 1
	return added


## Alles auf grau zurücksetzen.
func clear() -> void:
	setup(width, height)


## Gibt das seit dem letzten Aufruf geänderte Rechteck zurück (leer, wenn nichts geändert wurde).
func take_dirty() -> Rect2i:
	if not _has_dirty:
		return Rect2i()
	_has_dirty = false
	return _dirty


## Begrünt Zelle i und pflegt die Grenze. true, wenn sie vorher grau war.
func _green_index(i: int) -> bool:
	if cells[i] == GREEN:
		return false
	cells[i] = GREEN
	green_count += 1
	_frontier_remove(i)
	var x := i % width
	if x > 0:
		_frontier_add(i - 1)
	if x < width - 1:
		_frontier_add(i + 1)
	if i >= width:
		_frontier_add(i - width)
	if i < cells.size() - width:
		_frontier_add(i + width)
	return true


func _frontier_add(i: int) -> void:
	if cells[i] == GREY and _slot[i] < 0:
		_slot[i] = frontier.size()
		frontier.append(i)


func _frontier_remove(i: int) -> void:
	var s := _slot[i]
	if s < 0:
		return
	var last := frontier[frontier.size() - 1]
	frontier[s] = last
	_slot[last] = s
	frontier.resize(frontier.size() - 1)
	_slot[i] = -1


func _mark(r: Rect2i) -> void:
	_dirty = _dirty.merge(r) if _has_dirty else r
	_has_dirty = true
