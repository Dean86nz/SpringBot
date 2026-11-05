class_name WorldObject
extends Node2D
## Ein Objekt der Welt (Platzhalter-Grafik im Stil von Roboter und Bienen, wie im Stil-Vorschlag):
## tot in der grauen Welt, erwacht im Grün. Ein eigener Knoten je Objekt, damit Godot nur sichtbare
## Objekte zeichnet. Die Erwach-Animation läuft über die Skalierung des Knotens; neu gezeichnet
## wird nur einmal, beim Wechsel von tot zu lebendig (ein blühender Baum hat über 200 Kreise).
## Arten: Bäume oak (Laubbaum), fir (Tanne), birch (Birke), fruit (Obstbaum), willow (Weide),
## sapling (junger Baum); dazu rock, pond, bush; am Wegrand log, fence, stones; im Dorf house, fountain,
## church, school, library, shop, smithy, farmhouse, barn, stand (Honigstand), field, laundry (Wäscheleine), cemetery (Friedhof)
## (angle dreht Gebäude so, dass ihre Vorderseite, lokal +y, zum Dorfplatz zeigt).
## Was sich im Dorf bewegt (Menschen, Wäsche, Honiggläser, Funken), zeichnet VillagerView.
## Jedes Objekt hat eine eigene Größe (size, über die Skalierung des Knotens).
## Godot zeichnet auch einmal aufgezeichnete Objekte jedes Bild neu; Kreise, Polygone und
## Linienzüge kosten dabei je Aufruf ein Vielfaches von Textur-Rechtecken, Dreiecken und Linien.
## Deshalb Kreise als Textur (Disc), Polygone als Dreiecksfächer, Umrisse als einzelne Linien.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const BLOSSOM := [Color(1.0, 0.72, 0.84), Color(1.0, 0.97, 0.98)]
const FLOWERS := [Color(1.0, 0.56, 0.69), Color(1.0, 0.85, 0.30), Color(1.0, 1.0, 0.96), Color(0.72, 0.55, 0.95), Color(1.0, 0.45, 0.35), Color(0.55, 0.75, 1.0)]
const ANIM_SEC := 0.7

var kind := "oak"
var obj_seed := 0
var angle := 0.0
var quiet := false      # erwacht leise (ohne Klang, wenige Blätter)
var vid := ""           # Gebäude des Dorfes: erwacht erst, wenn die Bewohner es repariert haben
var _size := 1.0
var awake := false
var _anim := -1.0       # läuft beim Erwachen von 0 bis ANIM_SEC, sonst < 0
var _show_alive := false
var _rng := RandomNumberGenerator.new()


func setup(d: Dictionary) -> void:
	kind = str(d["kind"])
	position = d["pos"]
	obj_seed = int(d["seed"])
	angle = float(d.get("angle", 0.0))
	quiet = bool(d.get("quiet", false))
	vid = str(d.get("id", ""))
	_size = float(d.get("size", 1.0))
	scale = Vector2.ONE * _size


## Godot schaltet _process beim Eintritt in den Baum ein; gebraucht wird es nur während der Animation.
func _ready() -> void:
	set_process(_anim >= 0.0)


## Sofort (beim Laden) oder mit Animation.
func set_awake(on: bool, animate: bool) -> void:
	if awake == on:
		return
	awake = on
	_anim = 0.0 if animate and on else -1.0
	_show_alive = on and _anim < 0.0
	scale = Vector2.ONE * _size
	set_process(_anim >= 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _anim < 0.0:
		set_process(false)
		return
	_anim += delta
	var t := minf(_anim / ANIM_SEC, 1.0)
	if t < 0.25:
		scale = Vector2.ONE * _size * (1.0 - t * 0.8)          # das Tote zieht sich kurz zusammen
	else:
		if not _show_alive:
			_show_alive = true
			queue_redraw()
		var u := (t - 0.25) / 0.75
		scale = Vector2.ONE * _size * (0.8 + 0.2 * (1.0 - pow(1.0 - u, 3.0)) + sin(u * PI) * 0.12)   # das Lebende ploppt auf
	if _anim >= ANIM_SEC:
		_anim = -1.0
		scale = Vector2.ONE * _size
		set_process(false)


func _draw() -> void:
	var alive := _show_alive
	_rng.seed = obj_seed
	match kind:
		"oak":
			if alive:
				_oak_alive()
			else:
				_oak_dead()
		"fir":
			_fir(alive)
		"birch":
			_birch(alive)
		"fruit":
			if alive:
				_fruit_alive()
			else:
				_oak_dead(0.75)
		"willow":
			_willow(alive)
		"sapling":
			_sapling(alive)
		"rock":
			_rock(alive)
		"pond":
			if alive:
				_pond_alive()
			else:
				_pond_dry()
		"bush":
			if alive:
				_bush_alive()
			else:
				_bush_wilted()
		"log":
			_log(alive)
		"fence":
			_fence(alive)
		"stones":
			_stones(alive)
		"house":
			_house(alive)
		"fountain":
			_fountain(alive)
		"church":
			_church(alive)
		"school":
			_school(alive)
		"library":
			_library(alive)
		"shop":
			_shop(alive)
		"smithy":
			_smithy(alive)
		"farmhouse":
			_farmhouse(alive)
		"barn":
			_barn(alive)
		"stand":
			_stand(alive)
		"field":
			_field(alive)
		"laundry":
			_laundry(alive)
		"cemetery":
			_cemetery(alive)
	draw_set_transform(Vector2.ZERO)


# --- Hilfen: alles in lokalen Koordinaten ---

func _tf(offset: Vector2 = Vector2.ZERO, rot: float = 0.0, sc: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(offset, rot, sc)


func _shadow(r: float, sc: Vector2 = Vector2(1.0, 0.8)) -> void:
	_tf(Vector2(8, 12), 0.0, sc)
	_dot(Vector2.ZERO, r, SHADOW)
	_tf()


func _flower(p: Vector2, c: Color, s: float) -> void:
	for k in 5:
		_dot(p + Vector2.from_angle(k * TAU / 5.0) * s * 0.9, s * 0.75, c)
	_dot(p, s * 0.55, Color(1.0, 0.82, 0.28))


func _dot(c: Vector2, r: float, col: Color) -> void:
	Disc.dot(self, c, r, col)


## Kreis mit Rand der Breite w (wie draw_circle + draw_arc).
func _ring(c: Vector2, r: float, col: Color, edge: Color, w: float) -> void:
	Disc.ring_dot(self, c, r, col, edge, w)


## Gefülltes, gedrehtes Oval (setzt danach die Verschiebung per _tf zurück, wie bei den Blättern).
func _oval(c: Vector2, r: Vector2, rot: float, col: Color) -> void:
	draw_set_transform_matrix(Transform2D(rot, r, 0.0, c))
	draw_texture_rect(Disc.TEX, Rect2(-1, -1, 2, 2), false, col)
	_tf()


## Drei- oder Viereck ohne Triangulierung.
func _quad(pts: PackedVector2Array, col: Color) -> void:
	draw_primitive(pts, PackedColorArray([col]), PackedVector2Array())


## Sternförmiges Polygon (von center aus überall sichtbar) als Fächer aus Dreiecken.
func _fan(pts: PackedVector2Array, col: Color, center: Vector2 = Vector2.ZERO) -> void:
	var n := pts.size()
	for i in n:
		_quad(PackedVector2Array([center, pts[i], pts[(i + 1) % n]]), col)


## Umriss aus einzelnen Linien (closed: zurück zum ersten Punkt).
func _outline(pts: PackedVector2Array, col: Color, w: float, closed: bool = true) -> void:
	var n := pts.size()
	for i in (n if closed else n - 1):
		draw_line(pts[i], pts[(i + 1) % n], col, w)


# --- Bäume ---

## Kahler Laubbaum von oben: Äste sternförmig, Stammscheibe in der Mitte. k: Größe.
func _oak_dead(k: float = 1.0) -> void:
	_shadow(66.0 * k)
	_tf()
	var bark := Color(0.48, 0.40, 0.32)
	var a0 := _rng.randf() * TAU
	for i in 7:
		var a := a0 + i * TAU / 7.0 + _rng.randf_range(-0.2, 0.2)
		var tip := Vector2.from_angle(a) * _rng.randf_range(50.0, 64.0) * k
		draw_line(Vector2.ZERO, tip, bark, 6.0 * k)
		var mid := tip * 0.6
		draw_line(mid, mid + Vector2.from_angle(a + 0.7) * 20.0 * k, bark, 3.5 * k)
		draw_line(tip, tip + Vector2.from_angle(a - 0.5) * 13.0 * k, bark, 2.5)
	_ring(Vector2.ZERO, 14.0 * k, Color(0.50, 0.42, 0.34), INK, 3.0)


## Laubbaum: große, buckelige Krone in sattem Grün mit hellen Lichtflecken.
func _oak_alive() -> void:
	_shadow(78.0)
	_tf()
	var a0 := _rng.randf() * TAU
	var dark := Color(0.27, 0.54, 0.25)
	for i in 10:
		_dot(Vector2.from_angle(a0 + i * TAU / 10.0) * 46.0, 33.5, INK)
	for i in 10:
		_dot(Vector2.from_angle(a0 + i * TAU / 10.0) * 46.0, 30.5, dark)
	_dot(Vector2.ZERO, 50.0, dark)
	for i in 7:
		var q := Vector2.from_angle(a0 + i * TAU / 7.0 + 0.3) * _rng.randf_range(14.0, 40.0)
		_dot(q, _rng.randf_range(14.0, 20.0), Color(0.36, 0.64, 0.30))
	for i in 6:
		var q := Vector2(-14, -14) + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, 26.0)
		_dot(q, _rng.randf_range(6.0, 11.0), Color(0.48, 0.76, 0.36))


## Obstbaum: kleinere, runde Krone voller rosa oder weißer Blüten.
func _fruit_alive() -> void:
	_shadow(58.0)
	_tf()
	var a0 := _rng.randf() * TAU
	for i in 8:
		_dot(Vector2.from_angle(a0 + i * TAU / 8.0) * 32.0, 25.5, INK)
	for i in 8:
		_dot(Vector2.from_angle(a0 + i * TAU / 8.0) * 32.0, 22.5, Color(0.38, 0.66, 0.32))
	_dot(Vector2.ZERO, 36.0, Color(0.44, 0.74, 0.34))
	var blossom: Color = BLOSSOM[_rng.randi() % 2]
	for i in 28:
		var q := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, 50.0)
		_flower(q, blossom if i % 3 else Color(1.0, 0.97, 0.98), 4.2)


## Tanne von oben: gezackte Sterne in Schichten, innen heller. Tot: braungrau und licht.
func _fir(alive: bool) -> void:
	_shadow(52.0, Vector2(0.9, 0.8))
	_tf(Vector2.ZERO, angle)
	var spikes := 11
	var layers := [[54.0, 40.0], [38.0, 27.0], [22.0, 15.0]]
	var cols := [Color(0.16, 0.40, 0.30), Color(0.22, 0.50, 0.34), Color(0.30, 0.60, 0.38)]
	if not alive:
		cols = [Color(0.52, 0.47, 0.40), Color(0.58, 0.52, 0.44), Color(0.62, 0.56, 0.47)]
	for l in layers.size():
		var outer: float = layers[l][0]
		var inner: float = layers[l][1]
		var pts := PackedVector2Array()
		var off := l * 0.5
		for i in spikes * 2:
			var r := outer if i % 2 == 0 else inner
			if not alive and i % 2 == 0 and (i / 2 + l) % 3 == 0:
				r = inner + (outer - inner) * 0.3   # tote Tanne: abgebrochene Spitzen
			pts.append(Vector2.from_angle((i + off) * PI / spikes) * r)
		_fan(pts, cols[l])
		_outline(pts, INK, 2.5 if l == 0 else 1.5)
	if alive:
		_dot(Vector2.ZERO, 5.0, Color(0.42, 0.70, 0.44))
		for i in 3:
			var q := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(16.0, 34.0)
			_dot(q, 3.5, Color(0.55, 0.38, 0.24))   # Zapfen
	else:
		_dot(Vector2.ZERO, 6.0, Color(0.45, 0.38, 0.30))


## Birke: weißer Stamm mit schwarzen Strichen, lichte Krone aus kleinen hellgrünen Blättern.
func _birch(alive: bool) -> void:
	_shadow(44.0, Vector2(0.8, 0.7))
	_tf()
	var bark := Color(0.96, 0.95, 0.92)
	var trunk := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(7, 40), Vector2(-7, 40)])
	_quad(trunk, bark)
	_outline(trunk, INK, 2.5)
	for i in 4:
		var y := 10.0 + i * 8.0 + _rng.randf_range(-2, 2)
		var x0 := _rng.randf_range(-6, -1)
		draw_line(Vector2(x0, y), Vector2(x0 + _rng.randf_range(4, 8), y + 1), Color(0.16, 0.16, 0.18), 2.5)
	var twig := Color(0.52, 0.47, 0.42)
	var c := Vector2(0, -6)
	var a0 := _rng.randf() * TAU
	for i in 6:
		var a := a0 + i * TAU / 6.0
		draw_line(c, c + Vector2.from_angle(a) * 36.0, twig, 3.0)
		draw_line(c + Vector2.from_angle(a) * 22.0, c + Vector2.from_angle(a + 0.5) * 40.0, twig, 2.0)
	_ring(c, 6.0, bark, INK, 2.0)
	if not alive:
		return
	for i in 12:
		_dot(c + Vector2.from_angle(a0 + i * TAU / 12.0) * 30.0, 14.0, Color(0.38, 0.64, 0.28))
	for i in 46:
		var q := c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(4.0, 42.0)
		_dot(q, _rng.randf_range(5.0, 8.0), Color(0.52, 0.78, 0.32).lerp(Color(0.74, 0.88, 0.40), _rng.randf()))
	# weißer Stamm schaut unten aus der Krone heraus
	var low := PackedVector2Array([Vector2(-7, 30), Vector2(7, 30), Vector2(8, 54), Vector2(-8, 54)])
	_quad(low, bark)
	_outline(low, INK, 2.5)
	draw_line(Vector2(-8, 38), Vector2(-1, 39), Color(0.16, 0.16, 0.18), 2.5)
	draw_line(Vector2(1, 46), Vector2(8, 47), Color(0.16, 0.16, 0.18), 2.5)


## Trauerweide am Wasser: runde Krone, von der lange Zweige rundum herabhängen.
func _willow(alive: bool) -> void:
	_shadow(80.0)
	_tf()
	var a0 := _rng.randf() * TAU
	var base := Color(0.40, 0.66, 0.32) if alive else Color(0.56, 0.52, 0.42)
	var strand := Color(0.56, 0.78, 0.36) if alive else Color(0.48, 0.43, 0.35)
	if alive:
		_ring(Vector2.ZERO, 62.0, Color(0.34, 0.60, 0.30), INK, 3.0)
		_dot(Vector2.ZERO, 44.0, base)
	else:
		_ring(Vector2.ZERO, 16.0, Color(0.50, 0.42, 0.34), INK, 3.0)
	var n := 34 if alive else 22
	for i in n:
		var a := a0 + i * TAU / n + _rng.randf_range(-0.08, 0.08)
		var r0 := _rng.randf_range(8.0, 28.0)
		var r1 := _rng.randf_range(58.0, 76.0) * (1.0 if alive else 0.9)
		var bend := _rng.randf_range(-0.25, 0.25)
		var pts := PackedVector2Array()
		for k in 6:
			var t := k / 5.0
			pts.append(Vector2.from_angle(a + bend * t * t) * lerpf(r0, r1, t))
		_outline(pts, strand, 3.0 if alive else 2.0, false)
		if alive and i % 2 == 0:
			for k in range(2, 6):
				_dot(pts[k], 3.2, Color(0.66, 0.86, 0.42))


## Junger Baum: dünner Stecken mit drei Zweigen; erwacht mit ein paar frischen Blättern.
func _sapling(alive: bool) -> void:
	_tf(Vector2(5, 8))
	_dot(Vector2.ZERO, 18.0, SHADOW)
	_tf()
	var stick := Color(0.50, 0.40, 0.30)
	draw_line(Vector2(0, 16), Vector2(0, -6), stick, 4.0)
	var a0 := _rng.randf() * TAU
	for i in 3:
		var a := a0 + i * TAU / 3.0
		draw_line(Vector2(0, -6), Vector2(0, -6) + Vector2.from_angle(a) * 20.0, stick, 3.0)
	_dot(Vector2(0, -6), 4.0, stick)
	if not alive:
		return
	for i in 6:
		var a := a0 + i * TAU / 6.0
		var q := Vector2(0, -6) + Vector2.from_angle(a) * 17.0
		_oval(q, Vector2(12.75, 7.75), a, INK)
		_oval(q, Vector2(11.25, 6.25), a, Color(0.34, 0.64, 0.28) if i % 2 else Color(0.58, 0.84, 0.38))
		draw_line(q - Vector2.from_angle(a) * 9.0, q + Vector2.from_angle(a) * 9.0, Color(0.26, 0.48, 0.22), 1.5)
	_dot(Vector2(0, -6), 5.0, Color(0.50, 0.40, 0.30))


# --- Felsen ---

func _rock(moss: bool) -> void:
	var pts := PackedVector2Array()
	var a0 := _rng.randf() * TAU
	var stretch := Vector2(_rng.randf_range(54, 62), _rng.randf_range(40, 48))
	for k in 9:
		pts.append(Vector2.from_angle(a0 + k * TAU / 9.0) * stretch * (0.85 + 0.15 * sin(k * 2.3 + obj_seed % 7)))
	var sh := PackedVector2Array()
	for q in pts:
		sh.append(q + Vector2(6, 9))
	_tf()
	_fan(sh, SHADOW, Vector2(6, 9))
	_fan(pts, Color(0.66, 0.66, 0.68))
	_dot(Vector2(-12, -10), 20.0, Color(0.76, 0.76, 0.78))
	_outline(pts, INK, 3.0)
	if moss:
		for i in 14:
			var q := Vector2(_rng.randf_range(-38, 28), _rng.randf_range(-28, 8))
			_dot(q, _rng.randf_range(7, 13), Color(0.42, 0.70, 0.30).lerp(Color(0.60, 0.82, 0.36), _rng.randf()))
		_flower(Vector2(10, -14), Color(1.0, 1.0, 0.96), 4.0)


# --- Teiche ---

func _pond_dry() -> void:
	_tf(Vector2.ZERO, angle, Vector2(1.5, 1.0))
	_ring(Vector2.ZERO, 70.0, Color(0.58, 0.52, 0.44), Color(0.46, 0.40, 0.34), 3.0)
	_dot(Vector2.ZERO, 58.0, Color(0.68, 0.61, 0.50))
	_tf(Vector2.ZERO, angle)
	for i in 9:
		var a := _rng.randf() * TAU
		var q := Vector2(cos(a) * 20, sin(a) * 12)
		draw_line(q, q + Vector2(cos(a) * 55, sin(a) * 34), Color(0.50, 0.44, 0.36), 2.0)


func _pond_alive() -> void:
	_tf(Vector2.ZERO, angle, Vector2(1.5, 1.0))
	_dot(Vector2.ZERO, 74.0, Color(0.62, 0.78, 0.42))
	_ring(Vector2.ZERO, 66.0, Color(0.40, 0.68, 0.88), INK, 3.0)
	_dot(Vector2(-14, -12), 40.0, Color(0.52, 0.78, 0.94))
	_tf(Vector2.ZERO, angle)
	for i in 4:
		var q := Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-32, 32))
		_dot(q, 14.0, Color(0.36, 0.66, 0.30))
		_quad(PackedVector2Array([q, q + Vector2(16, -5), q + Vector2(16, 5)]), Color(0.40, 0.68, 0.88))
		if i % 2 == 0:
			_flower(q, Color(1.0, 0.62, 0.78) if i == 0 else Color(1.0, 0.97, 0.98), 5.0)


# --- Büsche ---

func _bush_wilted() -> void:
	_shadow(44.0)
	_tf()
	for k in 6:
		var q := Vector2.from_angle(k * TAU / 6.0 + obj_seed % 5) * 21.0
		_ring(q, 21.0, Color(0.58, 0.55, 0.40), Color(0.45, 0.42, 0.32), 2.0)
	_dot(Vector2.ZERO, 19.0, Color(0.62, 0.58, 0.42))


func _bush_alive() -> void:
	_shadow(48.0)
	_tf()
	for k in 6:
		_dot(Vector2.from_angle(k * TAU / 6.0 + obj_seed % 5) * 23.0, 25.5, INK)
	for k in 6:
		_dot(Vector2.from_angle(k * TAU / 6.0 + obj_seed % 5) * 23.0, 22.5, Color(0.30, 0.60, 0.28))
	_dot(Vector2.ZERO, 25.0, Color(0.38, 0.68, 0.32))
	for i in 16:
		var q := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5, 38)
		_dot(q, 4.5, Color(0.88, 0.18, 0.30))
		_dot(q + Vector2(-1.3, -1.3), 1.4, Color(1, 1, 1, 0.8))


# --- Wegrand: Baumstamm, Zaun, Steine ---

func _log(alive: bool) -> void:
	_tf(Vector2(5, 8), angle)
	draw_rect(Rect2(-34, -11, 68, 22), SHADOW)
	_tf(Vector2.ZERO, angle)
	var wood := Color(0.62, 0.50, 0.38) if alive else Color(0.55, 0.50, 0.45)
	draw_rect(Rect2(-34, -11, 68, 22), wood)
	draw_line(Vector2(-30, -4), Vector2(26, -4), wood.darkened(0.2), 2.0)
	draw_line(Vector2(-26, 4), Vector2(30, 4), wood.darkened(0.2), 2.0)
	_outline(PackedVector2Array([Vector2(-34, -11), Vector2(34, -11), Vector2(34, 11), Vector2(-34, 11)]), INK, 2.5)
	_ring(Vector2(34, 0), 11.0, wood.lightened(0.2), INK, 2.5)
	_ring(Vector2(34, 0), 5.0, wood.lightened(0.2), wood.darkened(0.25), 1.5)
	if alive:
		for i in 6:
			_dot(Vector2(_rng.randf_range(-28, 20), _rng.randf_range(-9, 6)), _rng.randf_range(4, 7), Color(0.42, 0.70, 0.30))
		for i in 2:
			var m := Vector2(_rng.randf_range(-20, 10), -13.0)
			_dot(m, 5.0, Color(0.92, 0.30, 0.28))
			_dot(m + Vector2(-1.5, -1.5), 1.3, Color(1, 1, 1))


func _fence(alive: bool) -> void:
	_tf(Vector2.ZERO, angle)
	var wood := Color(0.70, 0.54, 0.36) if alive else Color(0.58, 0.55, 0.50)
	for y in [-4.0, 4.0]:
		draw_line(Vector2(-40, y + 6), Vector2(40, y + 6), SHADOW, 4.0)
		draw_line(Vector2(-40, y), Vector2(40, y), wood, 4.0)
	for x in [-38.0, 0.0, 38.0]:
		_ring(Vector2(x, 0), 6.0, wood.darkened(0.15), INK, 2.0)
	if not alive:
		draw_line(Vector2(12, -6), Vector2(24, 6), wood.darkened(0.3), 2.0)   # gebrochene Latte
	else:
		for i in 7:
			var q := Vector2(_rng.randf_range(-36, 36), _rng.randf_range(-6, 6))
			_dot(q, 4.0, Color(0.36, 0.66, 0.30))
			if i % 2 == 0:
				_flower(q, FLOWERS[_rng.randi() % FLOWERS.size()], 3.5)


func _stones(moss: bool) -> void:
	_tf()
	for i in 3:
		var q := Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-12, 12))
		var r := _rng.randf_range(8, 14)
		_dot(q + Vector2(3, 4), r, SHADOW)
		_ring(q, r, Color(0.64, 0.64, 0.66).lerp(Color(0.74, 0.74, 0.76), _rng.randf()), INK, 2.0)
		if moss:
			_dot(q + Vector2(-r * 0.3, -r * 0.3), r * 0.5, Color(0.44, 0.72, 0.30))
	if moss:
		_flower(Vector2(_rng.randf_range(-10, 10), 14), FLOWERS[_rng.randi() % FLOWERS.size()], 3.5)


# --- Dorf ---

const ROOFS := [Color(0.84, 0.36, 0.28), Color(0.80, 0.52, 0.30), Color(0.40, 0.52, 0.72), Color(0.66, 0.40, 0.56), Color(0.88, 0.62, 0.30)]

## Haus von oben: Satteldach (zwei Dachhälften, First quer), Kamin, vorne Blumenkästen.
## Tot: verblichenes, fleckiges Dach mit Löchern, schiefer Kamin. Lebendig: bunte Ziegel, Blumen, Büsche.
func _house(alive: bool) -> void:
	var w := 58.0
	var h := 42.0
	_tf(Vector2(8, 10), angle)   # Schatten fällt immer nach rechts unten
	draw_rect(Rect2(-w, -h, w * 2, h * 2), SHADOW)
	_tf(Vector2.ZERO, angle)
	var roof: Color = ROOFS[obj_seed % ROOFS.size()] if alive else Color(0.56, 0.52, 0.48)
	draw_rect(Rect2(-w, -h, w * 2, h), roof.lightened(0.08))   # hintere Dachhälfte im Licht
	draw_rect(Rect2(-w, 0, w * 2, h), roof.darkened(0.12))
	# Ziegelreihen parallel zum First
	for k in 5:
		var y := -h + 7.0 + k * 7.0
		draw_line(Vector2(-w + 2, y), Vector2(w - 2, y), roof.darkened(0.22), 1.5)
		draw_line(Vector2(-w + 2, -y), Vector2(w - 2, -y), roof.darkened(0.3), 1.5)
	draw_line(Vector2(-w, 0), Vector2(w, 0), INK, 3.0)   # First
	_outline(PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]), INK, 3.0)
	# Kamin
	var cx := -w * 0.45 + float(obj_seed % 3) * w * 0.3
	var chim := Rect2(cx - 7, -h * 0.6, 14, 14)
	draw_rect(chim, Color(0.62, 0.40, 0.34) if alive else Color(0.50, 0.47, 0.44))
	_outline(PackedVector2Array([chim.position, Vector2(chim.end.x, chim.position.y), chim.end, Vector2(chim.position.x, chim.end.y)]), INK, 2.0)
	if not alive:
		_ruin(w, h, 4)
		return
	_dot(Vector2(cx, -h * 0.6 + 7), 4.0, Color(0.30, 0.26, 0.24))   # Kaminöffnung
	# Blumenkästen vorne (zum Platz) und Büsche an den Ecken
	for side in [-1.0, 1.0]:
		var bx: float = side * w * 0.55
		draw_rect(Rect2(bx - 16, h + 1, 32, 7), Color(0.58, 0.40, 0.26))
		for k in 4:
			_flower(Vector2(bx - 12 + k * 8, h + 3), FLOWERS[(obj_seed + k) % FLOWERS.size()], 3.0)
		_dot(Vector2(side * (w + 6), -h + 4), 11.0, Color(0.32, 0.60, 0.30))
		_dot(Vector2(side * (w + 4), -h + 1), 6.0, Color(0.44, 0.72, 0.36))
	# Tür in der Mitte vorne
	draw_rect(Rect2(-8, h - 2, 16, 10), Color(0.48, 0.32, 0.22))


## Dorfbrunnen: runder Steinrand, Säule in der Mitte. Tot: trocken mit Rissen. Lebendig: Wasser, Spritzer, Blumenring.
func _fountain(alive: bool) -> void:
	_shadow(46.0, Vector2(1.0, 0.9))
	_tf()
	_ring(Vector2.ZERO, 42.0, Color(0.70, 0.70, 0.72), INK, 3.0)
	_dot(Vector2.ZERO, 32.0, Color(0.40, 0.66, 0.88) if alive else Color(0.62, 0.58, 0.52))
	if alive:
		_dot(Vector2(-8, -8), 20.0, Color(0.55, 0.78, 0.95))
		for k in 10:   # Spritzer rund um die Säule
			_dot(Vector2.from_angle(k * TAU / 10.0) * 16.0, 2.5, Color(0.92, 0.97, 1.0))
		for k in 12:   # Blumenring außen
			_flower(Vector2.from_angle(k * TAU / 12.0 + 0.2) * 50.0, FLOWERS[k % FLOWERS.size()], 3.5)
	else:
		for k in 5:
			var a := k * TAU / 5.0 + 0.4
			draw_line(Vector2.from_angle(a) * 8.0, Vector2.from_angle(a + 0.3) * 26.0, Color(0.50, 0.46, 0.40), 2.0)
	_ring(Vector2.ZERO, 9.0, Color(0.78, 0.78, 0.80), INK, 2.5)
	if alive:
		_dot(Vector2.ZERO, 4.0, Color(0.92, 0.97, 1.0))


## Gemeinsamer Rahmen für Gebäude: Schatten, Satteldach (First quer, x-Richtung), Ziegelreihen, Umriss.
## Tot: verblichen mit Löchern.
func _gable(w: float, h: float, alive: bool, roof_alive: Color, holes: int = 4) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-w, -h, w * 2, h * 2), SHADOW)
	_tf(Vector2.ZERO, angle)
	var roof := roof_alive if alive else Color(0.56, 0.52, 0.48)
	draw_rect(Rect2(-w, -h, w * 2, h), roof.lightened(0.08))
	draw_rect(Rect2(-w, 0, w * 2, h), roof.darkened(0.12))
	var rows := int(h / 7.0) - 1
	for k in rows:
		var y := -h + 7.0 + k * 7.0
		draw_line(Vector2(-w + 2, y), Vector2(w - 2, y), roof.darkened(0.22), 1.5)
		draw_line(Vector2(-w + 2, -y), Vector2(w - 2, -y), roof.darkened(0.3), 1.5)
	draw_line(Vector2(-w, 0), Vector2(w, 0), INK, 3.0)
	_outline(PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]), INK, 3.0)
	if not alive:
		_ruin(w, h, holes)


## Kaputtes Dach: große Löcher mit freiliegenden Sparren, eingestürzte Ecke, Schutt und ein umgestürzter
## Balken neben dem Gebäude. Gilt für alle Gebäude des Dorfes (im aktuellen Zeichen-Rahmen).
func _ruin(w: float, h: float, holes: int = 3) -> void:
	_rng.seed = obj_seed
	var dark := Color(0.24, 0.22, 0.21)
	var beam := Color(0.42, 0.33, 0.26)
	for k in clampi(holes / 2, 1, 3):
		var hw := _rng.randf_range(w * 0.28, w * 0.45)
		var hh := _rng.randf_range(h * 0.45, h * 0.75)
		var p := Vector2(_rng.randf_range(-w + 4, w - hw - 4), _rng.randf_range(-h + 4, h - hh - 4))
		draw_rect(Rect2(p, Vector2(hw, hh)), dark)
		for r in int(hw / 9.0):   # Sparren über dem Loch
			var x := p.x + 5.0 + r * 9.0
			draw_line(Vector2(x, p.y - 2), Vector2(x, p.y + hh + 2), beam, 2.5)
		draw_line(Vector2(p.x - 2, p.y + hh * 0.5), Vector2(p.x + hw + 2, p.y + hh * 0.5 + _rng.randf_range(-3, 3)), beam, 2.0)
	# eingestürzte Ecke
	var sx := -1.0 if obj_seed % 2 == 0 else 1.0
	var corner := PackedVector2Array([Vector2(sx * w, h), Vector2(sx * (w - w * 0.55), h), Vector2(sx * w, h - h * 0.9)])
	_quad(corner, Color(0.58, 0.55, 0.50))
	_outline(PackedVector2Array([corner[1], corner[2]]), INK, 2.0, false)
	for k in 6:   # Schutt
		var q := Vector2(sx * (w + 8.0 + _rng.randf_range(0, 14)), _rng.randf_range(-h * 0.2, h * 0.9))
		_ring(q, _rng.randf_range(3.0, 6.0), Color(0.62, 0.60, 0.57).lerp(Color(0.50, 0.40, 0.34), _rng.randf()), INK, 1.0)
	var b0 := Vector2(-sx * (w + 6), -h * 0.6)   # umgestürzter Balken
	draw_line(b0, b0 + Vector2(sx * 10, h * 1.1), INK, 6.0)
	draw_line(b0, b0 + Vector2(sx * 10, h * 1.1), beam, 4.0)


func _rect_ink(r: Rect2, col: Color, w: float = 2.0) -> void:
	draw_rect(r, col)
	_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), INK, w)


## Kirche: langes Schiff (First längs), vorne ein Turm mit Spitzdach und Kreuz.
func _church(alive: bool) -> void:
	var w := 38.0
	var h := 62.0
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-w, -h, w * 2, h * 2), SHADOW)
	_dot(Vector2(0, h + 18), 30.0, SHADOW)
	_tf(Vector2.ZERO, angle)
	var roof := Color(0.52, 0.34, 0.32) if alive else Color(0.55, 0.52, 0.49)
	draw_rect(Rect2(-w, -h, w, h * 2), roof.lightened(0.08))
	draw_rect(Rect2(0, -h, w, h * 2), roof.darkened(0.12))
	for k in 4:
		var x := -w + 8.0 + k * 8.0
		draw_line(Vector2(x, -h + 2), Vector2(x, h - 2), roof.darkened(0.22), 1.5)
		draw_line(Vector2(-x, -h + 2), Vector2(-x, h - 2), roof.darkened(0.3), 1.5)
	draw_line(Vector2(0, -h), Vector2(0, h), INK, 3.0)
	_outline(PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]), INK, 3.0)
	# Turm vorne: quadratisch, Spitzdach aus vier Dreiecken, Kreuz
	var c := Vector2(0, h + 12)
	var t := 26.0
	var stone := Color(0.80, 0.78, 0.72) if alive else Color(0.62, 0.60, 0.57)
	var tip := Color(0.38, 0.50, 0.62) if alive else Color(0.50, 0.48, 0.46)
	var pts := PackedVector2Array([c + Vector2(-t, -t), c + Vector2(t, -t), c + Vector2(t, t), c + Vector2(-t, t)])
	draw_rect(Rect2(c - Vector2(t, t), Vector2(t, t) * 2), stone)
	for k in 4:
		_quad(PackedVector2Array([c, pts[k], pts[(k + 1) % 4]]), tip.lightened(0.12) if k % 2 == 0 else tip.darkened(0.08))
	_outline(pts, INK, 3.0)
	draw_line(pts[0], pts[2], INK, 1.5)
	draw_line(pts[1], pts[3], INK, 1.5)
	var gold := Color(1.0, 0.84, 0.35) if alive else Color(0.45, 0.42, 0.40)
	draw_line(c + Vector2(0, -9), c + Vector2(0, 9), gold, 3.5)
	draw_line(c + Vector2(-6, -3), c + Vector2(6, -3), gold, 3.5)
	if not alive:
		_tf(Vector2.ZERO, angle)
		_ruin(w, h, 4)


## Schule: breites Haus, davor ein Pausenhof mit Zaun, Fahnenmast und Hüpfkästchen.
func _school(alive: bool) -> void:
	_tf(Vector2.ZERO, angle)
	var yard := Rect2(-56, 40, 112, 46)
	draw_rect(yard, Color(0.78, 0.74, 0.66) if alive else Color(0.62, 0.60, 0.56))
	_gable(66.0, 38.0, alive, Color(0.86, 0.52, 0.30))
	var wood := Color(0.55, 0.42, 0.30)
	draw_line(Vector2(yard.position.x, yard.end.y), Vector2(yard.end.x, yard.end.y), wood, 2.0)
	for k in 8:   # Zaunpfosten
		_dot(Vector2(yard.position.x + k * 16.0, yard.end.y), 3.0, wood)
	var mast := Vector2(yard.end.x - 8, yard.position.y + 8)
	if alive:
		_quad(PackedVector2Array([mast, mast + Vector2(24, -6), mast + Vector2(24, 6), mast + Vector2(0, 4)]), Color(0.36, 0.62, 0.92))
		for k in 5:   # Hüpfkästchen mit Kreide
			var r := Rect2(-34 + k * 13, 56, 12, 12)
			_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color(1, 1, 1, 0.85), 1.5)
	_ring(mast, 3.5, Color(0.70, 0.70, 0.72), INK, 1.5)
	draw_rect(Rect2(-9, 36, 18, 8), Color(0.48, 0.32, 0.22))


## Bücherei: Haus mit rundem Oberlicht, davor eine Bank und ein Schild mit offenem Buch.
func _library(alive: bool) -> void:
	_gable(48.0, 38.0, alive, Color(0.36, 0.46, 0.66))
	_ring(Vector2(0, -19), 9.0, Color(0.80, 0.88, 0.96) if alive else Color(0.50, 0.50, 0.50), INK, 2.0)
	_rect_ink(Rect2(-40, 46, 34, 9), Color(0.62, 0.46, 0.30) if alive else Color(0.52, 0.48, 0.44))   # Bank
	var sc := Vector2(26, 52)
	_rect_ink(Rect2(sc - Vector2(13, 9), Vector2(26, 18)), Color(0.96, 0.92, 0.80) if alive else Color(0.60, 0.58, 0.55))
	if alive:   # aufgeschlagenes Buch auf dem Schild
		draw_rect(Rect2(sc + Vector2(-9, -5), Vector2(8, 10)), Color(0.82, 0.30, 0.30))
		draw_rect(Rect2(sc + Vector2(1, -5), Vector2(8, 10)), Color(0.82, 0.30, 0.30))
		draw_line(sc + Vector2(0, -5), sc + Vector2(0, 5), INK, 1.5)
	draw_rect(Rect2(-8, 36, 16, 8), Color(0.48, 0.32, 0.22))


## Dorfladen: Haus mit gestreifter Markise über dem Eingang, Obst- und Gemüsekisten davor.
func _shop(alive: bool) -> void:
	_gable(48.0, 36.0, alive, Color(0.80, 0.52, 0.30))
	var aw := Rect2(-44, 34, 88, 16)
	for k in 8:
		var stripe := k % 2 == 0
		var col := (Color(0.92, 0.32, 0.30) if stripe else Color(0.98, 0.96, 0.92)) if alive else (Color(0.55, 0.50, 0.47) if stripe else Color(0.66, 0.64, 0.60))
		draw_rect(Rect2(aw.position.x + k * 11.0, aw.position.y, 11, aw.size.y), col)
	_outline(PackedVector2Array([aw.position, Vector2(aw.end.x, aw.position.y), aw.end, Vector2(aw.position.x, aw.end.y)]), INK, 2.0)
	var fruit := [Color(0.92, 0.30, 0.26), Color(1.0, 0.70, 0.22), Color(0.50, 0.78, 0.30), Color(0.62, 0.36, 0.70)]
	for k in 4:   # Kisten
		var r := Rect2(-42 + k * 22, 54, 18, 14)
		_rect_ink(r, Color(0.66, 0.50, 0.32) if alive else Color(0.55, 0.51, 0.46), 1.5)
		if alive:
			for j in 3:
				_dot(r.position + Vector2(4 + j * 5, 7), 3.0, fruit[k])


## Schmiede: dunkles Dach, großer Kamin mit Glut, davor Amboss und Hufeisen.
func _smithy(alive: bool) -> void:
	_gable(44.0, 36.0, alive, Color(0.42, 0.40, 0.44))
	var chim := Rect2(14, -30, 22, 22)
	_rect_ink(chim, Color(0.56, 0.36, 0.30) if alive else Color(0.50, 0.47, 0.44))
	_dot(chim.get_center(), 7.0, Color(0.20, 0.16, 0.14))
	if alive:
		_dot(chim.get_center(), 5.0, Color(1.0, 0.55, 0.20))
		_dot(chim.get_center(), 2.5, Color(1.0, 0.85, 0.40))
	var a := Vector2(22, 54)   # Amboss
	var anvil := PackedVector2Array([a + Vector2(-13, -6), a + Vector2(13, -6), a + Vector2(9, 6), a + Vector2(-9, 6)])
	_quad(anvil, Color(0.30, 0.32, 0.36))
	_outline(anvil, INK, 1.5)
	if alive:   # Hufeisen
		for k in 3:
			var hp := Vector2(-30 + k * 10, 54)
			_outline(PackedVector2Array([hp + Vector2(-3, 3), hp + Vector2(-3, -2), hp + Vector2(0, -4), hp + Vector2(3, -2), hp + Vector2(3, 3)]), Color(0.42, 0.42, 0.46), 2.0, false)
	draw_rect(Rect2(-8, 34, 16, 8), Color(0.30, 0.24, 0.20))


## Bauernhaus: großes Haus mit Strohdach, daneben ein Gemüsegarten.
func _farmhouse(alive: bool) -> void:
	_tf(Vector2.ZERO, angle)
	var g := Rect2(-48, 44, 52, 26)
	draw_rect(g, Color(0.55, 0.40, 0.28) if alive else Color(0.58, 0.54, 0.48))
	if alive:
		for k in 3:
			for j in 6:
				_dot(g.position + Vector2(6 + j * 8, 6 + k * 8), 3.0, Color(0.40, 0.70, 0.30))
	_gable(54.0, 40.0, alive, Color(0.86, 0.74, 0.40), 5)
	draw_rect(Rect2(-8, 38, 16, 8), Color(0.48, 0.32, 0.22))


## Scheune: lang, rotes Dach, große Tore vorne, Heuballen daneben.
func _barn(alive: bool) -> void:
	_gable(72.0, 42.0, alive, Color(0.72, 0.26, 0.22), 6)
	var door := Rect2(-22, 40, 44, 10)
	_rect_ink(door, Color(0.58, 0.32, 0.22) if alive else Color(0.52, 0.48, 0.44))
	var cross := Color(0.95, 0.92, 0.85) if alive else Color(0.66, 0.64, 0.60)
	draw_line(door.position, door.end, cross, 2.0)
	draw_line(Vector2(door.position.x, door.end.y), Vector2(door.end.x, door.position.y), cross, 2.0)
	for k in 3:   # Heuballen
		var p := Vector2(86, -26 + k * 26)
		_ring(p, 12.0, Color(0.92, 0.80, 0.42) if alive else Color(0.66, 0.62, 0.52), INK, 2.0)
		_ring(p, 5.0, Color(0.84, 0.70, 0.34) if alive else Color(0.60, 0.56, 0.48), Color(0.70, 0.58, 0.30), 1.0)


## Honigstand: kleiner Tisch mit gelb-brauner Markise (die Gläser zeichnet VillagerView).
func _stand(alive: bool) -> void:
	_tf(Vector2(6, 8), angle)
	draw_rect(Rect2(-30, -16, 60, 32), SHADOW)
	_tf(Vector2.ZERO, angle)
	for k in 6:
		var stripe := k % 2 == 0
		var col := (Color(0.98, 0.78, 0.26) if stripe else Color(0.62, 0.42, 0.24)) if alive else (Color(0.62, 0.58, 0.50) if stripe else Color(0.52, 0.48, 0.44))
		draw_rect(Rect2(-30 + k * 10, -16, 10, 18), col)
	_rect_ink(Rect2(-28, 2, 56, 12), Color(0.66, 0.50, 0.32) if alive else Color(0.55, 0.51, 0.46), 1.5)
	_outline(PackedVector2Array([Vector2(-30, -16), Vector2(30, -16), Vector2(30, 2), Vector2(-30, 2)]), INK, 2.0)


## Feld: Ackerfurchen; lebendig mit Reihen junger Pflanzen.
func _field(alive: bool) -> void:
	_tf()
	var r := Rect2(-104, -64, 208, 128)
	draw_rect(r, Color(0.58, 0.44, 0.30) if alive else Color(0.62, 0.58, 0.52))
	for k in 8:
		var y := r.position.y + 8.0 + k * 16.0
		draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x - 4, y), Color(0.46, 0.34, 0.22) if alive else Color(0.54, 0.50, 0.45), 3.0)
		if alive:
			for j in 13:
				_dot(Vector2(r.position.x + 10 + j * 16, y - 4), 4.5, Color(0.42, 0.72, 0.30) if (j + k) % 3 else Color(0.56, 0.80, 0.34))
	_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color(0.40, 0.32, 0.24), 2.0)


## Wäscheleine: zwei Pfosten, Leine, Wäschekorb (die Wäsche selbst zeichnet VillagerView).
func _laundry(alive: bool) -> void:
	_tf()
	draw_line(Vector2(-64, 0), Vector2(64, 0), Color(0.92, 0.92, 0.90) if alive else Color(0.70, 0.70, 0.68), 1.5)
	for x in [-64.0, 64.0]:
		_ring(Vector2(x, 0), 4.5, Color(0.58, 0.44, 0.30) if alive else Color(0.52, 0.48, 0.44), INK, 1.5)
	_ring(Vector2(-80, 16), 11.0, Color(0.80, 0.66, 0.42) if alive else Color(0.60, 0.56, 0.50), INK, 2.0)


## Friedhof: niedrige Steinmauer, Reihen von Grabsteinen und Kreuzen, im Grün mit Blumen auf den Gräbern.
## Tot: umgekippte Steine, kahle Erde.
func _cemetery(alive: bool) -> void:
	_tf()
	var r := Rect2(-70, -52, 140, 104)
	draw_rect(r, Color(0.50, 0.70, 0.36) if alive else Color(0.62, 0.59, 0.54))
	var wall := Color(0.72, 0.70, 0.66) if alive else Color(0.58, 0.56, 0.53)
	_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x + 52, r.end.y)]), wall, 5.0, false)
	_outline(PackedVector2Array([Vector2(r.position.x + 30, r.end.y), Vector2(r.position.x, r.end.y), r.position]), wall, 5.0, false)   # Lücke unten = Tor
	_rng.seed = obj_seed
	for row in 3:
		for k in 5:
			var p := Vector2(-52 + k * 26, -32 + row * 30)
			var fallen := not alive and _rng.randf() < 0.4
			draw_rect(Rect2(p + Vector2(-8, 4), Vector2(16, 12)), Color(0.46, 0.38, 0.30) if alive else Color(0.55, 0.51, 0.46))   # Grab
			if (k + row) % 3 == 0:   # Kreuz
				var c := Color(0.50, 0.40, 0.32) if alive else Color(0.48, 0.45, 0.42)
				var rot := 0.0 if not fallen else 1.2
				draw_line(p + Vector2(0, -8).rotated(rot), p + Vector2(0, 6).rotated(rot), c, 3.0)
				draw_line(p + Vector2(-5, -3).rotated(rot), p + Vector2(5, -3).rotated(rot), c, 3.0)
			else:   # Grabstein
				var stone := PackedVector2Array([p + Vector2(-6, -4), p + Vector2(6, -4), p + Vector2(6, 4), p + Vector2(-6, 4)])
				if fallen:
					stone = PackedVector2Array([p + Vector2(-8, 0), p + Vector2(8, -2), p + Vector2(8, 5), p + Vector2(-8, 6)])
				_quad(stone, Color(0.74, 0.74, 0.76) if alive else Color(0.60, 0.59, 0.58))
				_outline(stone, INK, 1.5)
			if alive and (k + row) % 2 == 0:
				_flower(p + Vector2(0, 10), FLOWERS[(k + row * 2) % FLOWERS.size()], 2.8)
