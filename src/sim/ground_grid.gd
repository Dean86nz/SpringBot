class_name GroundGrid
extends RefCounted
## Der Boden als Raster: je Zelle ein Byte (0 = grau, 255 = grün).
## Reine Logik ohne Darstellung. Der begrünte Anteil wird mitgezählt, nie neu durchsucht.
## Geänderte Zellen landen in einem Schmutz-Rechteck, das die Darstellung abholt.

const GREY := 0
const GREEN := 255

var width := 0
var height := 0
var cells := PackedByteArray()
var green_count := 0
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
	var i := c.y * width + c.x
	if cells[i] == GREEN:
		return false
	cells[i] = GREEN
	green_count += 1
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
			if dx * dx + dy * dy <= r2 and cells[row + x] != GREEN:
				cells[row + x] = GREEN
				added += 1
	if added > 0:
		green_count += added
		_mark(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
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


func _mark(r: Rect2i) -> void:
	_dirty = _dirty.merge(r) if _has_dirty else r
	_has_dirty = true
