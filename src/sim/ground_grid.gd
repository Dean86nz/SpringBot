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
## Die Ausbreitung springt über schmale Wege und Wasser (bis hop_cells): Für die Grenze zählt
## als Nachbar die nächste Landzelle in jeder Richtung, so bleibt kein Land eingeschlossen.
## Anzeige-Maske: Randzellen der Roboterspur behalten einen Teilwert nur, solange sie am Rand
## liegen; sobald alle Nachbarn grün (oder kein Land) sind, werden sie voll grün (_settle).
## Weg- und Wasserzellen neben grünem Land gelten in der Anzeige als grün, sonst fiele die
## weich gefilterte Maske am Wegrand ab und dort schiene Grau durch.
## Dürre Stellen (dry, von WorldMap.build_dry gesetzt): Land, auf dem nichts von allein wächst. Sie gehören
## nie zur Grenze (keine Ausbreitung), Bienen begrünen sie nicht (paint_circle mit wet_only); nur der Roboter
## und die Samenvögel. Sonnenblumen (sown): Zellen, durch die ein Saatstreifen der Samenvögel lief.

const GREY := 0
const GREEN := 255
const LAND := 0
const PATH := 1
const WATER := 2
const BRIDGE := 3
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var width := 0
var height := 0
var cells := PackedByteArray()
var vis := PackedByteArray()         # nur Darstellung: 0..255, ab 128 sichtbar grün
var since := PackedByteArray()       # je Zelle 2 Byte: Spielsekunde + 1, ab der sie grün ist (0 = grau)
var time_sec := 0.0                  # aktuelle Spielzeit, setzt main.gd jedes Bild
var terrain := PackedByteArray()     # LAND, PATH, WATER oder BRIDGE je Zelle
var terrain_vis := PackedByteArray() # nur Darstellung: 2 Byte je Zelle, Weg- und Wassermaske mit weichem Rand
var land_count := 0                  # Zellen, die grün werden können (= 100 %)
var hop_cells := 12                  # so weit springt die Ausbreitung über Wege und Wasser
var green_count := 0
var dry := PackedByteArray()         # 1 = dürre Stelle (bleibt wie das Gelände)
var sown := PackedByteArray()        # 255 = hier wächst eine Sonnenblume der Samenvögel (direkt als Textur nutzbar)
var sown_dirty := false              # sown hat sich geändert (Darstellung lädt neu hoch)
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
	dry = PackedByteArray()
	dry.resize(w * h)
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


## Land, das noch grau ist (Ziel für Bienen: ohne dürre Stellen, allow_dry false).
func is_open(c: Vector2i, allow_dry: bool = true) -> bool:
	if not in_bounds(c):
		return false
	var i := c.y * width + c.x
	return terrain[i] == LAND and cells[i] == GREY and (allow_dry or dry[i] == 0)


func is_dry(c: Vector2i) -> bool:
	return in_bounds(c) and dry[c.y * width + c.x] != 0


## Sonnenblume der Samenvögel in dieser Zelle (nur auf Land).
func mark_sown(c: Vector2i) -> void:
	if in_bounds(c) and terrain[c.y * width + c.x] == LAND and sown[c.y * width + c.x] == 0:
		sown[c.y * width + c.x] = 255
		sown_dirty = true


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
	sown = PackedByteArray()
	sown.resize(w * h)
	sown_dirty = true
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
	return in_bounds(c) and terrain[c.y * width + c.x] == LAND and cells[c.y * width + c.x] == GREEN


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
## wet_only: dürre Stellen bleiben, wie sie sind (Bienen).
func paint_circle(center: Vector2, radius: float, wet_only: bool = false) -> int:
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
			var v := 255 if d2 <= inner2 else mini(int((0.5 + radius - sqrt(d2)) * 255.0), 255)
			if terrain[i] == LAND and not (wet_only and dry[i] != 0):
				var old := vis[i]
				vis[i] = maxi(old, v)
				if d2 <= r2 and _green_index(i, false):
					added += 1
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
			var t := c + Vector2i(roundi(off.x), roundi(off.y))
			if not is_dry(t) and set_green(t):   # Samen gehen auf dürrem Boden nicht auf
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


## Sonnenblumen gepackt (für den Spielstand) und das Gegenstück (fehlt oder passt nicht: keine).
func sown_to_bytes() -> PackedByteArray:
	return sown.compress(FileAccess.COMPRESSION_DEFLATE)


func load_sown(packed: PackedByteArray) -> void:
	var raw := packed.decompress(width * height, FileAccess.COMPRESSION_DEFLATE) if packed.size() > 0 else PackedByteArray()
	if raw.size() == width * height:
		if raw.has(1):   # Spielstand aus 0.20.0: 1 statt 255
			for i in raw.size():
				if raw[i] == 1:
					raw[i] = 255
		sown = raw
		sown_dirty = true


## Gegenstück zu to_bytes: übernimmt die Zellen und baut Zähler und Grenze neu auf.
## false (und nichts geändert), wenn die Daten nicht zu dieser Kartengröße passen.
func load_bytes(packed: PackedByteArray) -> bool:
	var raw := packed.decompress(width * height, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != width * height:
		return false
	_reset_state()
	for i in raw.size():
		if raw[i] == GREY or terrain[i] != LAND:   # Wege aus 0.10.1 waren „sauber“: zählt nicht mehr
			continue
		cells[i] = GREEN
		vis[i] = GREEN
		green_count += 1
		_cover_edges(i)   # einmalig beim Laden
	for i in cells.size():
		if cells[i] == GREY and terrain[i] == LAND and dry[i] == 0 and _has_green_neighbor(i):
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
## full_vis false: paint_circle hat die Anzeige schon gesetzt (Teilwert am Rand).
func _green_index(i: int, full_vis: bool = true) -> bool:
	if cells[i] == GREEN or terrain[i] != LAND:
		return false
	cells[i] = GREEN
	if full_vis:
		vis[i] = GREEN
	var s := mini(int(time_sec) + 1, 65535)
	since[i * 2] = s & 255
	since[i * 2 + 1] = s >> 8
	green_count += 1
	_frontier_remove(i)
	var x := i % width
	if x < width - 1:
		_touch(i, i + 1, DIRS[0])
	if x > 0:
		_touch(i, i - 1, DIRS[1])
	if i < cells.size() - width:
		_touch(i, i + width, DIRS[2])
	if i >= width:
		_touch(i, i - width, DIRS[3])
	if vis[i] != GREEN:
		_settle(i)
	return true


## Direkter Nachbar n der frisch grünen Zelle i: Land kommt in die Grenze; Weg oder Wasser wird
## in der Anzeige grün, und die nächste Landzelle dahinter kommt in die Grenze (Sprung).
func _touch(i: int, n: int, d: Vector2i) -> void:
	if terrain[n] == LAND:
		# Bedingungen vorab prüfen: spart bei jeder Ausbreitung zwei Funktionsaufrufe
		if cells[n] == GREY:
			if _slot[n] < 0:
				_frontier_add(n)
		elif vis[n] != GREEN:
			_settle(n)
		return
	if vis[n] != GREEN:
		vis[n] = GREEN
		_mark(Rect2i(n % width, n / width, 1, 1))
	var m := _land_neighbor(i, d)
	if m >= 0:
		_frontier_add(m)
		_settle(m)


## Direkte Nachbarn von i, die kein Land sind, werden in der Anzeige grün.
func _cover_edges(i: int) -> void:
	var x := i % width
	var y := i / width
	for d in DIRS:
		var nx := x + d.x
		var ny := y + d.y
		if nx >= 0 and ny >= 0 and nx < width and ny < height:
			var n := ny * width + nx
			if terrain[n] != LAND and vis[n] != GREEN:
				vis[n] = GREEN
				_mark(Rect2i(nx, ny, 1, 1))


## Nächste Landzelle von i aus in Richtung d, über Wege und Wasser hinweg (höchstens hop_cells), sonst -1.
func _land_neighbor(i: int, d: Vector2i) -> int:
	var x := i % width + d.x
	var y := i / width + d.y
	for s in hop_cells:
		if x < 0 or y < 0 or x >= width or y >= height:
			return -1
		var n := y * width + x
		if terrain[n] == LAND:
			return n
		x += d.x
		y += d.y
	return -1


func _has_green_neighbor(i: int) -> bool:
	for d in DIRS:
		var n := _land_neighbor(i, d)
		if n >= 0 and cells[n] == GREEN:
			return true
	return false


## Grüne Zelle mit Teilwert in der Anzeige wird voll grün, sobald sie nicht mehr am Rand liegt
## (alle direkten Nachbarn grün, kein Land oder außerhalb der Karte).
func _settle(i: int) -> void:
	if cells[i] != GREEN or vis[i] == GREEN:
		return
	var x := i % width
	var y := i / width
	for d in DIRS:
		var nx := x + d.x
		var ny := y + d.y
		if nx < 0 or ny < 0 or nx >= width or ny >= height:
			continue
		var n := ny * width + nx
		if terrain[n] == LAND and cells[n] != GREEN:
			return
	vis[i] = GREEN
	_mark(Rect2i(x, y, 1, 1))


func _frontier_add(i: int) -> void:
	if cells[i] == GREY and terrain[i] == LAND and dry[i] == 0 and _slot[i] < 0:
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
