class_name GroundGrid
extends RefCounted
## Der Boden als Raster: je Zelle ein Byte (0 = grau, 255 = grün).
## Reine Logik ohne Darstellung. Der begrünte Anteil wird mitgezählt, nie neu durchsucht.
## Geänderte Zellen landen in einem Schmutz-Rechteck, das die Darstellung abholt.
## Die Grenze (graue Zellen mit grünem Nachbarn) wird laufend mitgeführt: Liste plus
## Positionsindex, damit Hinzufügen, Entfernen und zufälliges Ziehen O(1) sind.
## Daneben eine Anzeige-Maske (vis): wie cells, aber der Roboter-Kreis setzt am Rand Teilwerte,
## damit der sichtbare Rand genau auf dem Kreis liegt statt am Zellraster einzurasten.
## Außerdem je Zelle der Zeitpunkt, seit dem sie grün ist (since, für „länger grün = üppiger“).
## Gelände (terrain, von WorldMap gesetzt): Nur Land wird grün und zählt zur Fläche; Wege und
## Wasser bleiben, wie sie sind. Über Wasser fährt der Roboter nur auf Brücken.

const GREY := 0
const GREEN := 255
const LAND := 0
const PATH := 1
const WATER := 2
const BRIDGE := 3

var width := 0
var height := 0
var cells := PackedByteArray()
var vis := PackedByteArray()         # nur Darstellung: 0..255, ab 128 sichtbar grün
var since := PackedByteArray()       # je Zelle 2 Byte: Spielsekunde + 1, ab der sie grün ist (0 = grau)
var time_sec := 0.0                  # aktuelle Spielzeit, setzt main.gd jedes Bild
var terrain := PackedByteArray()     # LAND, PATH, WATER oder BRIDGE je Zelle
var terrain_vis := PackedByteArray() # nur Darstellung: 2 Byte je Zelle, Weg- und Wassermaske mit weichem Rand
var land_count := 0                  # Zellen, die grün werden können (= 100 %)
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
	terrain = PackedByteArray()
	terrain.resize(w * h)
	terrain_vis = PackedByteArray()
	terrain_vis.resize(w * h * 2)
	land_count = w * h
	_reset_state()


## Gelände übernehmen (vor dem ersten Begrünen). soft: weiche Masken für die Darstellung.
func set_terrain(t: PackedByteArray, soft: PackedByteArray) -> void:
	terrain = t
	terrain_vis = soft
	land_count = t.count(LAND)
	_reset_state()


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and terrain[c.y * width + c.x] != WATER


## Land, das noch grau ist (Ziel für Bienen).
func is_open(c: Vector2i) -> bool:
	if not in_bounds(c):
		return false
	var i := c.y * width + c.x
	return terrain[i] == LAND and cells[i] == GREY


## Alles außer dem Gelände zurücksetzen: grau, keine Grenze, keine Zeiten.
func _reset_state() -> void:
	var w := width
	var h := height
	cells = PackedByteArray()
	cells.resize(w * h)
	vis = PackedByteArray()
	vis.resize(w * h)
	since = PackedByteArray()
	since.resize(w * h * 2)
	frontier = PackedInt32Array()
	_slot = PackedInt32Array()
	_slot.resize(w * h)
	_slot.fill(-1)
	green_count = 0
	_dirty = Rect2i(0, 0, w, h)
	_has_dirty = true


## Zellen, die grün werden können (Wege und Wasser zählen nicht).
func total() -> int:
	return land_count


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
## Anzeige: Zellen nahe dem Rand bekommen 0,5 + (radius − Abstand), so liegt die 0,5-Linie der
## weich gefilterten Maske genau auf dem Kreis (zählt nicht als grün).
func paint_circle(center: Vector2, radius: float) -> int:
	var reach := radius + 0.5
	var x0 := maxi(int(floor(center.x - reach)), 0)
	var x1 := mini(int(ceil(center.x + reach)), width - 1)
	var y0 := maxi(int(floor(center.y - reach)), 0)
	var y1 := mini(int(ceil(center.y + reach)), height - 1)
	if x0 > x1 or y0 > y1:
		return 0
	var r2 := radius * radius
	var inner2 := maxf(radius - 0.5, 0.0) ** 2
	var reach2 := reach * reach
	var added := 0
	var touched := false
	for y in range(y0, y1 + 1):
		var dy := y + 0.5 - center.y
		var row := y * width
		for x in range(x0, x1 + 1):
			var dx := x + 0.5 - center.x
			var d2 := dx * dx + dy * dy
			if d2 >= reach2:
				continue
			var i := row + x
			var old := vis[i]
			if d2 <= r2 and _green_index(i):
				added += 1
			if d2 > inner2:
				var v := mini(int((0.5 + radius - sqrt(d2)) * 255.0), 255)
				vis[i] = maxi(old, v)
			if vis[i] != old:
				touched = true
	if added > 0 or touched:
		_mark(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
	return added


## Selbstausbreitung: höchstens `events` Zellen begrünen, jede an einer zufälligen Grenzzelle.
## Ist reach ≥ 2, wird mit Wahrscheinlichkeit seed_chance stattdessen ein Samen 2..reach Zellen
## weit geworfen (landet er auf Grün oder außerhalb, wächst doch die Grenzzelle).
## Jedes Ereignis begrünt also genau eine Zelle: Die Weite ändert den Ort, nicht das Tempo.
func spread(events: int, reach: float, seed_chance: float, rng: RandomNumberGenerator) -> int:
	var added := 0
	for e in events:
		if frontier.is_empty():
			break
		var i := frontier[rng.randi_range(0, frontier.size() - 1)]
		var c := Vector2i(i % width, i / width)
		if reach >= 2.0 and rng.randf() < seed_chance:
			var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2.0, reach)
			if set_green(c + Vector2i(roundi(off.x), roundi(off.y))):
				added += 1
				continue
		if set_green(c):
			added += 1
	return added


## Alles auf grau zurücksetzen (das Gelände bleibt).
func clear() -> void:
	_reset_state()


## Begrünt alles außer einem Kreis (center, radius in Zellen). Nur fürs Cheat-Menü.
func fill_except(center: Vector2, radius: float) -> void:
	for i in cells.size():
		if Vector2(i % width + 0.5, i / width + 0.5).distance_to(center) > radius:
			_green_index(i)
	_mark(Rect2i(0, 0, width, height))


## Zellen als gepackte Bytes (für den Spielstand; main.gd packt eine Kopie im Hintergrund).
func to_bytes() -> PackedByteArray:
	return cells.compress(FileAccess.COMPRESSION_DEFLATE)


## Spielsekunde, ab der Zelle i grün ist (-1 = grau).
func green_since(i: int) -> float:
	var s := since[i * 2] | (since[i * 2 + 1] << 8)
	return s - 1.0 if s > 0 else -1.0


## „Seit wann grün“ gepackt (für den Spielstand).
func since_to_bytes() -> PackedByteArray:
	return since.compress(FileAccess.COMPRESSION_DEFLATE)


## Gegenstück zu since_to_bytes. Ohne passende Daten (alter Spielstand) gilt alles Grün
## als seit Spielbeginn grün. Nach load_bytes aufrufen.
func load_since(packed: PackedByteArray) -> void:
	var raw := packed.decompress(width * height * 2, FileAccess.COMPRESSION_DEFLATE) if packed.size() > 0 else PackedByteArray()
	if raw.size() == width * height * 2:
		since = raw
		return
	for i in cells.size():
		if cells[i] == GREEN:
			since[i * 2] = 1
	_mark(Rect2i(0, 0, width, height))


## Gegenstück zu to_bytes: übernimmt die Zellen und baut Zähler und Grenze neu auf.
## false (und nichts geändert), wenn die Daten nicht zu dieser Kartengröße passen.
func load_bytes(packed: PackedByteArray) -> bool:
	var raw := packed.decompress(width * height, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != width * height:
		return false
	_reset_state()
	for i in raw.size():
		if raw[i] != GREY and terrain[i] == LAND:
			cells[i] = GREEN
	green_count = cells.count(GREEN)
	vis = cells.duplicate()
	for i in cells.size():
		if cells[i] == GREY and terrain[i] == LAND and _has_green_neighbor(i):
			_slot[i] = frontier.size()
			frontier.append(i)
	return true


## Gibt das seit dem letzten Aufruf geänderte Rechteck zurück (leer, wenn nichts geändert wurde).
func take_dirty() -> Rect2i:
	if not _has_dirty:
		return Rect2i()
	_has_dirty = false
	return _dirty


## Begrünt Zelle i und pflegt die Grenze. true, wenn sie vorher grau war.
func _green_index(i: int) -> bool:
	if cells[i] == GREEN or terrain[i] != LAND:
		return false
	cells[i] = GREEN
	vis[i] = GREEN
	var s := mini(int(time_sec) + 1, 65535)
	since[i * 2] = s & 255
	since[i * 2 + 1] = s >> 8
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


func _has_green_neighbor(i: int) -> bool:
	var x := i % width
	if (x > 0 and cells[i - 1] == GREEN) or (x < width - 1 and cells[i + 1] == GREEN):
		return true
	return (i >= width and cells[i - width] == GREEN) or (i < cells.size() - width and cells[i + width] == GREEN)


func _frontier_add(i: int) -> void:
	if cells[i] == GREY and terrain[i] == LAND and _slot[i] < 0:
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
