class_name WorldObject
extends Node2D
## Ein Objekt der Welt (Platzhalter-Grafik im Stil von Roboter und Bienen, wie im Stil-Vorschlag):
## tot in der grauen Welt, erwacht im Grün. Ein eigener Knoten je Objekt, damit Godot nur sichtbare
## Objekte zeichnet. Die Erwach-Animation läuft über die Skalierung des Knotens; neu gezeichnet
## wird nur einmal, beim Wechsel von tot zu lebendig (ein blühender Baum hat über 200 Kreise).
## Arten: Bäume oak (Laubbaum), fir (Tanne), birch (Birke), fruit (Obstbaum), willow (Weide),
## sapling (junger Baum); dazu rock, pond, bush; am Wegrand log, fence, stones.
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
