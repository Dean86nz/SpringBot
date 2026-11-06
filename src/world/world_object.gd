class_name WorldObject
extends Node2D
## Ein Objekt der Welt (Platzhalter-Grafik im Stil von Roboter und Bienen, wie im Stil-Vorschlag):
## tot in der grauen Welt, erwacht im Grün. Ein eigener Knoten je Objekt, damit Godot nur sichtbare
## Objekte zeichnet. Die Erwach-Animation läuft über die Skalierung des Knotens; neu gezeichnet
## wird nur einmal, beim Wechsel von tot zu lebendig (ein blühender Baum hat über 200 Kreise).
## Arten: Bäume oak (Laubbaum), fir (Tanne), birch (Birke), fruit (Obstbaum), willow (Weide),
## sapling (junger Baum); dazu rock, pond, bush; am Wegrand log, fence, stones; im Dorf house, fountain,
## church, school, library, shop, smithy, farmhouse, barn, stand (Honigstand), field, laundry (Wäscheleine), cemetery (Friedhof),
## in Felder und Vorort auch windmill (Windmühle, die Flügel drehen sich als eigener Knoten), silo, garden (Gemüsegarten),
## Jede Region hat eigene Gebäude: im Vorort suburb (Einfamilienhaus), kita, bakery, pavilion; auf den Feldern manor
## (Gutshof), machine_hall (Maschinenhalle), wheat (Weizenfeld); in der Großstadt apartment (Wohnblock) und tower
## (Hochhaus) schräg von oben mit Fassade, dazu cathedral, museum, cafe, school_city, raised_beds, playground, fountain_city
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
const APARTMENT := Vector2(190, 120)   # halbe Größe des Wohnblocks (Pixel, vor der Skalierung)
const TOWER := Vector2(120, 120)

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
var _sails: Sails = null   # Windmühle: Flügel als eigener Knoten (drehen, ohne neu zu zeichnen)


## Flügel der Windmühle: kaputt zwei zerrissene, schief und still; repariert vier bespannte, die sich drehen.
class Sails extends Node2D:
	var alive := false

	func _process(delta: float) -> void:
		rotation += delta * 0.9

	func _draw() -> void:
		var ink := Color(0.30, 0.36, 0.44)
		var wood := Color(0.55, 0.40, 0.26) if alive else Color(0.50, 0.47, 0.44)
		var cloth := Color(0.98, 0.95, 0.88) if alive else Color(0.66, 0.64, 0.60)
		for k in (4 if alive else 2):
			var a := k * TAU / 4.0 + (0.0 if alive else 0.5 + k * 0.4)
			var length := 92.0 if alive or k == 0 else 56.0
			var d := Vector2.from_angle(a)
			var n := d.orthogonal()
			var base := d * 14.0
			var tip := base + d * (length - 14.0)
			draw_primitive(PackedVector2Array([base, tip, tip + n * 18.0]), PackedColorArray([cloth]), PackedVector2Array())
			draw_primitive(PackedVector2Array([base, tip + n * 18.0, base + n * 18.0]), PackedColorArray([cloth]), PackedVector2Array())
			for j in 4:   # Latten
				var q := base.lerp(tip, 0.2 + j * 0.25)
				draw_line(q, q + n * 18.0, wood, 2.0)
			draw_line(Vector2.ZERO, d * length, ink, 6.0)
			draw_line(Vector2.ZERO, d * length, wood, 4.0)
			draw_line(base + n * 18.0, tip + n * 18.0, wood, 2.0)
		Disc.ring_dot(self, Vector2.ZERO, 9.0, Color(0.42, 0.32, 0.24), ink, 2.0)


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
	if kind == "windmill":
		_sails = Sails.new()
		_sails.position = Vector2(0, -8)
		_sails.rotation = float(obj_seed % 7)
		_sails.z_index = 1
		add_child(_sails)
		_update_sails()


func _update_sails() -> void:
	if _sails:
		_sails.alive = _show_alive
		_sails.set_process(_show_alive)
		_sails.queue_redraw()


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
	_update_sails()


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
			_update_sails()
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
		"windmill":
			_windmill(alive)
		"silo":
			_silo(alive)
		"garden":
			_garden(alive)
		"apartment":
			_city_building(false, alive)
		"tower":
			_city_building(true, alive)
		"suburb":
			_suburb(alive)
		"kita":
			_kita(alive)
		"bakery":
			_bakery(alive)
		"pavilion":
			_pavilion(alive)
		"manor":
			_manor(alive)
		"machine_hall":
			_machine_hall(alive)
		"wheat":
			_wheat(alive)
		"cathedral":
			_cathedral(alive)
		"museum":
			_museum(alive)
		"cafe":
			_cafe(alive)
		"school_city":
			_city_school(alive)
		"raised_beds":
			_raised_beds(alive)
		"playground":
			_playground(alive)
		"fountain_city":
			_fountain_city(alive)
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


## Windmühle: runder Turm aus Stein mit Kegeldach, vorne eine Tür, Mehlsäcke daneben (die Flügel sind
## ein eigener Knoten, siehe Sails). Kaputt: Löcher im Dach, Steine liegen herum.
func _windmill(alive: bool) -> void:
	_tf(Vector2(10, 14))
	_dot(Vector2.ZERO, 48.0, SHADOW)
	_tf()
	_ring(Vector2.ZERO, 44.0, Color(0.86, 0.82, 0.74) if alive else Color(0.64, 0.61, 0.57), INK, 3.0)
	var roof := Color(0.46, 0.36, 0.30) if alive else Color(0.55, 0.52, 0.49)
	_ring(Vector2.ZERO, 34.0, roof, INK, 2.5)
	for k in 12:   # Dachschindeln strahlenförmig
		var a := k * TAU / 12.0
		draw_line(Vector2.from_angle(a) * 8.0, Vector2.from_angle(a) * 33.0, roof.darkened(0.25), 1.5)
	_rect_ink(Rect2(-9, 40, 18, 10), Color(0.48, 0.32, 0.22) if alive else Color(0.50, 0.46, 0.42))
	if alive:
		for k in 3:   # Mehlsäcke
			_ring(Vector2(30 + k * 11, 40 + (k % 2) * 6), 7.0, Color(0.96, 0.92, 0.82), INK, 1.5)
	else:
		_rng.seed = obj_seed
		for k in 3:   # Löcher im Dach
			var p := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(12, 26)
			_dot(p, _rng.randf_range(6, 9), Color(0.24, 0.22, 0.21))
			draw_line(p + Vector2(-8, 0), p + Vector2(8, 2), Color(0.42, 0.33, 0.26), 2.0)
		for k in 7:   # heruntergefallene Steine
			var q := Vector2.from_angle(0.6 + k * 0.35) * (52.0 + _rng.randf_range(0, 12))
			_ring(q, _rng.randf_range(3.0, 6.0), Color(0.66, 0.63, 0.58), INK, 1.0)


## Silo: hoher runder Speicher mit Blechkuppel, Leiter außen. Kaputt: Rost, ein Loch.
func _silo(alive: bool) -> void:
	_tf(Vector2(12, 18))
	_dot(Vector2.ZERO, 34.0, SHADOW)
	_tf()
	var metal := Color(0.80, 0.84, 0.88) if alive else Color(0.60, 0.58, 0.56)
	_ring(Vector2.ZERO, 30.0, metal.darkened(0.08), INK, 3.0)
	_ring(Vector2.ZERO, 22.0, metal, metal.darkened(0.2), 1.5)
	_ring(Vector2.ZERO, 12.0, metal.lightened(0.08), metal.darkened(0.2), 1.5)
	_ring(Vector2.ZERO, 5.0, metal.darkened(0.25), INK, 1.5)
	if alive:
		_dot(Vector2(-10, -10), 6.0, Color(1, 1, 1, 0.5))   # Glanz
		draw_line(Vector2(-4, -30), Vector2(-4, -50), INK, 1.5)   # Fähnchen
		_quad(PackedVector2Array([Vector2(-4, -50), Vector2(12, -46), Vector2(-4, -42)]), Color(0.92, 0.36, 0.30))
	else:
		_dot(Vector2(12, 6), 9.0, Color(0.62, 0.40, 0.26, 0.8))   # Rost
		_dot(Vector2(-14, 12), 6.0, Color(0.62, 0.40, 0.26, 0.7))
		_dot(Vector2(6, -14), 7.0, Color(0.24, 0.22, 0.21))       # Loch
	for k in 5:   # Leiter
		draw_line(Vector2(26, -12 + k * 6), Vector2(34, -12 + k * 6), INK, 1.5)
	draw_line(Vector2(26, -14), Vector2(26, 14), INK, 1.5)
	draw_line(Vector2(34, -14), Vector2(34, 14), INK, 1.5)


## Gemüsegarten im Vorort: Holzzaun, Beete mit Salat, Möhren und Kürbissen, daneben Bohnen.
## Kaputt: graue Erde, Unkraut, der Zaun ist umgefallen.
func _garden(alive: bool) -> void:
	_tf()
	var r := Rect2(-46, -32, 92, 64)
	draw_rect(r, Color(0.56, 0.42, 0.28) if alive else Color(0.62, 0.58, 0.52))
	var wood := Color(0.62, 0.46, 0.30) if alive else Color(0.55, 0.51, 0.46)
	_rng.seed = obj_seed
	for row in 3:
		var y := -22.0 + row * 22.0
		draw_rect(Rect2(-40, y - 6, 80, 12), Color(0.46, 0.34, 0.22) if alive else Color(0.56, 0.52, 0.47))
		for j in 6:
			var p := Vector2(-34 + j * 13.6, y)
			if not alive:
				if _rng.randf() < 0.5:
					draw_line(p + Vector2(-3, 3), p + Vector2(2, -4), Color(0.50, 0.48, 0.40), 1.5)   # Unkraut
				continue
			match row:
				0: _dot(p, 5.0, Color(0.50, 0.80, 0.36))   # Salat
				1:
					draw_line(p + Vector2(0, 4), p + Vector2(0, -2), Color(0.40, 0.70, 0.30), 2.0)   # Möhren
					_dot(p + Vector2(0, 4), 2.2, Color(1.0, 0.56, 0.20))
				_: _ring(p, 5.0, Color(1.0, 0.62, 0.20), Color(0.70, 0.40, 0.14), 1.2)   # Kürbisse
	if alive:
		for k in 3:   # Bohnen
			_ring(Vector2(52, -22 + k * 16), 4.0, Color(0.36, 0.64, 0.32), Color(0.30, 0.50, 0.26), 1.2)
	# Zaun: lebendig ringsum, kaputt nur Reste
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		if not alive and i % 2 == 1:
			continue
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		draw_line(a, b, wood, 3.0)
		for k in 6:
			_dot(a.lerp(b, k / 5.0), 2.5, wood.darkened(0.15))
	if not alive:
		draw_line(Vector2(r.end.x + 4, -20), Vector2(r.end.x + 16, 26), wood, 3.0)   # umgefallenes Zaunstück


## --- Großstadt: Gebäude schräg von oben (Dach oben, darunter die Vorderseite mit Fenstern) ---
## Stadtgebäude werden nicht gedreht, sondern am Bildschirm ausgerichtet: Die Grundfläche (e) liegt am Boden,
## das Dach ist um die Fassadenhöhe nach oben versetzt, dazwischen sieht man die Vorderseite mit Stockwerken.
## Liegt die Längsseite quer (angle ±90°), werden Breite und Tiefe getauscht.

const FLOOR_PX := 15.0
const WALLS := [Color(0.93, 0.87, 0.74), Color(0.86, 0.58, 0.45), Color(0.95, 0.85, 0.56), Color(0.70, 0.80, 0.88), Color(0.76, 0.84, 0.70), Color(0.74, 0.42, 0.34), Color(0.90, 0.78, 0.80)]
const AWNINGS := [Color(0.88, 0.30, 0.28), Color(0.30, 0.56, 0.42), Color(0.26, 0.44, 0.74), Color(0.96, 0.72, 0.24)]


## Grundfläche am Bildschirm (Breite und Tiefe getauscht, wenn das Gebäude quer steht).
func _screen_extent(e: Vector2) -> Vector2:
	return Vector2(e.y, e.x) if absf(sin(angle)) > 0.7 else e


## Wohnblock (4 bis 6 Stockwerke, farbiger Putz oder Backstein, unten Läden) oder Hochhaus (9 bis 13 Stockwerke,
## Glas oder Beton). Kaputt: graue Fassade, dunkle und eingeschlagene Fenster, Schmutzstreifen, Schutt auf dem Dach.
## Erwacht: Farbe, helle und erleuchtete Fenster, Blumenkästen, Markisen, Dachgarten.
func _city_building(tower: bool, alive: bool) -> void:
	_tf()
	_rng.seed = obj_seed
	var e := _screen_extent(TOWER if tower else APARTMENT)
	var floors := _rng.randi_range(9, 13) if tower else _rng.randi_range(4, 6)
	var f := floors * FLOOR_PX + 14.0
	var glass := tower and obj_seed % 2 == 0
	var wall: Color = WALLS[obj_seed % WALLS.size()]
	if tower:
		wall = Color(0.46, 0.62, 0.74) if glass else Color(0.82, 0.82, 0.80)
	if not alive:
		wall = wall.lerp(Color(0.62, 0.61, 0.59), 0.8)
	# Schatten nach rechts unten, länger bei hohen Häusern
	draw_rect(Rect2(Vector2(-e.x + 16, -e.y - f + 24), Vector2(e.x * 2 + f * 0.45, e.y * 2 + f - 12)), SHADOW)
	# Vorderseite
	var face := Rect2(Vector2(-e.x, e.y - f), Vector2(e.x * 2, f))
	draw_rect(face, wall.darkened(0.12))
	draw_rect(Rect2(face.position.x, face.end.y - 14, face.size.x, 14), wall.darkened(0.25))   # Sockel / Erdgeschoss
	var cols := int((e.x * 2 - 12) / 20.0)
	for k in floors:
		var y := face.position.y + 6 + k * FLOOR_PX
		if glass:
			draw_line(Vector2(face.position.x, y - 3), Vector2(face.end.x, y - 3), wall.darkened(0.35), 1.0)
		for c in cols:
			var x := face.position.x + 10 + c * 20.0
			var win := Rect2(Vector2(x, y), Vector2(12 if not glass else 18, 9))
			var r := _rng.randf()
			var col := Color(0.24, 0.24, 0.26)
			if alive:
				col = Color(1.0, 0.88, 0.58) if r < 0.18 else Color(0.74, 0.87, 0.96)
				if glass:
					col = Color(0.62, 0.82, 0.92) if r < 0.7 else Color(0.85, 0.95, 1.0)
			draw_rect(win, col)
			if not alive and r < 0.3:   # eingeschlagen
				draw_line(win.position, win.end, Color(0.55, 0.58, 0.60), 1.2)
				draw_line(Vector2(win.end.x, win.position.y), Vector2(win.position.x + 3, win.end.y), Color(0.55, 0.58, 0.60), 1.2)
			elif alive and not tower and r > 0.78:   # Blumenkasten
				draw_rect(Rect2(win.position + Vector2(-1, 9), Vector2(14, 3)), Color(0.55, 0.38, 0.24))
				_dot(win.position + Vector2(3, 9), 2.2, FLOWERS[(c + k) % FLOWERS.size()])
				_dot(win.position + Vector2(9, 9), 2.2, FLOWERS[(c + k + 2) % FLOWERS.size()])
	if not alive:   # Schmutzstreifen
		for k in 4:
			var x := _rng.randf_range(face.position.x + 6, face.end.x - 6)
			draw_line(Vector2(x, face.position.y + 4), Vector2(x + 2, face.position.y + f * _rng.randf_range(0.3, 0.8)), Color(0.40, 0.40, 0.40, 0.5), 3.0)
	# Erdgeschoss: Tür, bei Wohnblocks Läden mit Markisen
	draw_rect(Rect2(Vector2(-7, face.end.y - 13), Vector2(14, 13)), Color(0.36, 0.26, 0.20))
	if not tower:
		for side in [-1.0, 1.0]:
			var ax: float = side * e.x * 0.55 - 26.0
			var aw: Color = AWNINGS[(obj_seed + int(side + 1.0)) % AWNINGS.size()] if alive else Color(0.55, 0.53, 0.50)
			for k in 5:
				draw_rect(Rect2(Vector2(ax + k * 10.4, face.end.y - 20), Vector2(10.4, 7)), aw if k % 2 == 0 else aw.lightened(0.5))
	_outline(PackedVector2Array([face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y)]), INK, 2.5)
	# Dach
	var roof := Rect2(Vector2(-e.x, -e.y - f), e * 2.0)
	var top := wall.lightened(0.1) if not glass else Color(0.70, 0.72, 0.74)
	draw_rect(roof, top)
	var inner := roof.grow(-7.0)
	draw_rect(inner, Color(0.72, 0.71, 0.68) if alive else Color(0.58, 0.57, 0.55))
	_outline(PackedVector2Array([roof.position, Vector2(roof.end.x, roof.position.y), roof.end, Vector2(roof.position.x, roof.end.y)]), INK, 2.5)
	# Aufzugshaus und Lüftung
	var lift := Rect2(inner.position + Vector2(inner.size.x * 0.68, 8), Vector2(30, 22))
	draw_rect(lift.grow(1.0), INK)
	draw_rect(lift, top.darkened(0.08))
	if not alive:
		for k in int(inner.size.x * inner.size.y / 3000.0):   # Risse und Flecken
			var a := Vector2(_rng.randf_range(inner.position.x, inner.end.x), _rng.randf_range(inner.position.y, inner.end.y))
			draw_line(a, a + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(12, 26), Color(0.42, 0.41, 0.40), 1.5)
		for k in 3:
			_dot(Vector2(_rng.randf_range(inner.position.x + 12, inner.end.x - 12), _rng.randf_range(inner.position.y + 12, inner.end.y - 12)), _rng.randf_range(6, 11), Color(0.46, 0.45, 0.44, 0.6))
		if tower:   # umgeknickte Antenne
			draw_line(inner.position + Vector2(14, 14), inner.position + Vector2(34, 22), INK, 2.5)
		return
	_roof_garden(Rect2(inner.position + Vector2(6, 6), Vector2(inner.size.x * 0.6, inner.size.y - 12)))
	if tower:
		_ring(inner.end - Vector2(18, 18), 11.0, Color(0.70, 0.72, 0.76), INK, 2.0)   # Wassertank
		draw_line(inner.position + Vector2(14, 14), inner.position + Vector2(14, -8), INK, 2.0)   # Antenne
		_dot(inner.position + Vector2(14, -8), 2.5, Color(1.0, 0.35, 0.3))


## Dachgarten in r: Holzdeck, Beete mit Blumen, Bäumchen in Kübeln, Solarzellen.
func _roof_garden(r: Rect2) -> void:
	var deck := Rect2(r.position, Vector2(r.size.x * 0.35, r.size.y))
	draw_rect(deck, Color(0.74, 0.58, 0.40))
	for k in int(deck.size.x / 8.0):
		draw_line(deck.position + Vector2(k * 8.0, 0), deck.position + Vector2(k * 8.0, deck.size.y), Color(0.62, 0.47, 0.32), 1.0)
	var beds := Rect2(r.position + Vector2(r.size.x * 0.4, 0), Vector2(r.size.x * 0.6, r.size.y))
	var rows := maxi(int(beds.size.y / 22.0), 1)
	for row in rows:
		var b := Rect2(beds.position + Vector2(0, row * beds.size.y / rows), Vector2(beds.size.x, beds.size.y / rows - 4))
		_rect_ink(b, Color(0.46, 0.34, 0.22), 1.5)
		for j in int(b.size.x / 10.0):
			_dot(b.position + Vector2(6 + j * 10, b.size.y * 0.5), 4.0, Color(0.42, 0.74, 0.32) if (j + row) % 3 else FLOWERS[(j + row + obj_seed) % FLOWERS.size()])
	for k in 2:
		var tp := deck.position + Vector2(deck.size.x * 0.5, 14 + k * (deck.size.y - 28))
		_ring(tp, 9.0, Color(0.36, 0.64, 0.32), Color(0.26, 0.48, 0.24), 1.5)
		_dot(tp + Vector2(-3, -3), 4.0, Color(0.50, 0.78, 0.40))


## --- Vorort ---

## Walmdach (vier Dachflächen, kurzer First quer) mit Ziegelreihen. Tot: grau, mit Löchern.
func _hip(w: float, h: float, alive: bool, roof_alive: Color, holes: int = 3) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-w, -h, w * 2, h * 2), SHADOW)
	_tf(Vector2.ZERO, angle)
	var roof := roof_alive if alive else Color(0.56, 0.52, 0.48)
	var a := Vector2(-w + h, 0)
	var b := Vector2(w - h, 0)
	_quad(PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), b]), roof.lightened(0.1))
	_quad(PackedVector2Array([Vector2(-w, -h), b, a]), roof.lightened(0.1))
	_quad(PackedVector2Array([Vector2(-w, h), Vector2(w, h), b]), roof.darkened(0.14))
	_quad(PackedVector2Array([Vector2(-w, h), b, a]), roof.darkened(0.14))
	_quad(PackedVector2Array([Vector2(-w, -h), a, Vector2(-w, h)]), roof.darkened(0.02))
	_quad(PackedVector2Array([Vector2(w, -h), b, Vector2(w, h)]), roof.darkened(0.22))
	for k in 3:   # Ziegelreihen
		var t := 0.25 + k * 0.25
		draw_line(Vector2(-w + h * t, -h * (1.0 - t)), Vector2(w - h * t, -h * (1.0 - t)), roof.darkened(0.12), 1.2)
		draw_line(Vector2(-w + h * t, h * (1.0 - t)), Vector2(w - h * t, h * (1.0 - t)), roof.darkened(0.3), 1.2)
	for p in [[Vector2(-w, -h), a], [Vector2(w, -h), b], [Vector2(-w, h), a], [Vector2(w, h), b], [a, b]]:
		draw_line(p[0], p[1], INK, 2.0)
	_outline(PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]), INK, 3.0)
	if not alive:
		_ruin(w, h, holes)


const SUBURB_ROOFS := [Color(0.36, 0.38, 0.42), Color(0.58, 0.30, 0.26), Color(0.52, 0.40, 0.32), Color(0.42, 0.50, 0.58), Color(0.30, 0.44, 0.40)]


## Einfamilienhaus im Vorort: Walmdach, Garage mit Einfahrt, Garten mit Hecke hinten und je nach Haus
## Pool, Trampolin oder Terrasse mit Sonnenschirm. Kaputt: Hecke kahl, Pool leer und rissig.
func _suburb(alive: bool) -> void:
	_tf(Vector2.ZERO, angle)
	var hedge := Color(0.30, 0.52, 0.28) if alive else Color(0.52, 0.47, 0.40)
	# Garten hinten (lokal −y) mit Hecke
	for k in 9:
		var p := Vector2(-74 + k * 18.5, -96)
		_dot(p, 10.0 if alive else 6.0, hedge)
	for k in 3:
		_dot(Vector2(-78, -78 + k * 18), 10.0 if alive else 6.0, hedge)
		_dot(Vector2(78, -78 + k * 18), 10.0 if alive else 6.0, hedge)
	match obj_seed % 3:
		0:   # Pool
			var pool := Rect2(-34, -86, 56, 28)
			draw_rect(pool.grow(4), Color(0.86, 0.84, 0.80))
			draw_rect(pool, Color(0.40, 0.72, 0.92) if alive else Color(0.56, 0.55, 0.52))
			if alive:
				draw_line(pool.position + Vector2(8, 8), pool.position + Vector2(24, 8), Color(1, 1, 1, 0.7), 2.0)
			else:
				draw_line(pool.position + Vector2(10, 4), pool.position + Vector2(30, 22), Color(0.40, 0.38, 0.36), 1.5)
		1:   # Trampolin
			_ring(Vector2(-10, -72), 20.0, Color(0.20, 0.22, 0.26) if alive else Color(0.46, 0.45, 0.44), Color(0.30, 0.50, 0.86) if alive else Color(0.55, 0.53, 0.50), 4.0)
		_:   # Terrasse mit Sonnenschirm
			draw_rect(Rect2(-40, -76, 60, 26), Color(0.72, 0.58, 0.42) if alive else Color(0.58, 0.55, 0.50))
			if alive:
				for k in 8:
					_quad(PackedVector2Array([Vector2(-10, -64), Vector2(-10, -64) + Vector2.from_angle(k * TAU / 8.0) * 18.0, Vector2(-10, -64) + Vector2.from_angle((k + 1) * TAU / 8.0) * 18.0]), Color(0.95, 0.40, 0.36) if k % 2 == 0 else Color(0.98, 0.96, 0.92))
	# Einfahrt und Garage rechts
	draw_rect(Rect2(62, -18, 40, 74), Color(0.66, 0.66, 0.66) if alive else Color(0.58, 0.57, 0.55))
	_tf(Vector2(68, -8), angle)
	draw_rect(Rect2(0, -26, 40, 52), SHADOW)
	_tf(Vector2.ZERO, angle)
	_rect_ink(Rect2(62, -34, 40, 52), Color(0.80, 0.80, 0.78) if alive else Color(0.60, 0.58, 0.56))
	draw_rect(Rect2(66, 14, 32, 4), Color(0.45, 0.48, 0.52))   # Garagentor
	_hip(54.0, 40.0, alive, SUBURB_ROOFS[obj_seed % SUBURB_ROOFS.size()], 3)
	_tf(Vector2.ZERO, angle)
	# Weg zur Haustür, Briefkasten, Beet
	draw_rect(Rect2(-8, 40, 16, 22), Color(0.78, 0.74, 0.68) if alive else Color(0.60, 0.58, 0.55))
	_rect_ink(Rect2(-30, 58, 8, 6), Color(0.86, 0.30, 0.26) if alive else Color(0.55, 0.52, 0.50), 1.2)
	if alive:
		for k in 5:
			_flower(Vector2(14 + k * 8, 50), FLOWERS[(obj_seed + k) % FLOWERS.size()], 3.0)


## Kita: flaches, buntes Gebäude, davor ein umzäunter Spielplatz mit Sandkasten, Rutsche und Schaukel.
func _kita(alive: bool) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-64, -36, 128, 72), SHADOW)
	_tf(Vector2.ZERO, angle)
	var colors := [Color(0.98, 0.70, 0.30), Color(0.50, 0.78, 0.46), Color(0.46, 0.68, 0.92), Color(0.96, 0.52, 0.56)]
	for k in 4:
		draw_rect(Rect2(-64 + k * 32, -36, 32, 72), colors[k] if alive else Color(0.62, 0.60, 0.57).darkened(0.03 * k))
	_outline(PackedVector2Array([Vector2(-64, -36), Vector2(64, -36), Vector2(64, 36), Vector2(-64, 36)]), INK, 3.0)
	for k in 4:   # Oberlichter
		_rect_ink(Rect2(-56 + k * 32, -8, 16, 16), Color(0.80, 0.90, 0.96) if alive else Color(0.30, 0.30, 0.30), 1.5)
	var yard := Rect2(-70, 44, 140, 66)
	draw_rect(yard, Color(0.56, 0.78, 0.42) if alive else Color(0.62, 0.60, 0.55))
	var fence := Color(0.96, 0.96, 0.92) if alive else Color(0.55, 0.53, 0.50)
	_outline(PackedVector2Array([Vector2(yard.position.x, yard.position.y), Vector2(yard.position.x, yard.end.y), yard.end, Vector2(yard.end.x, yard.position.y)]), fence, 2.0, false)
	_rect_ink(Rect2(-60, 56, 40, 34), Color(0.94, 0.86, 0.62) if alive else Color(0.60, 0.58, 0.54), 2.0)   # Sandkasten
	if alive:
		_dot(Vector2(-46, 72), 4.0, Color(0.92, 0.32, 0.30))   # Eimerchen
	draw_rect(Rect2(0, 54, 12, 44), Color(0.96, 0.82, 0.24) if alive else Color(0.56, 0.54, 0.50))   # Rutsche
	for k in 4:
		draw_line(Vector2(0, 58 + k * 10), Vector2(12, 58 + k * 10), INK, 1.0)
	draw_line(Vector2(30, 60), Vector2(60, 60), INK, 3.0)   # Schaukel
	for x in [38.0, 52.0]:
		draw_line(Vector2(x, 60), Vector2(x, 76 if alive else 70), INK, 1.0)
		draw_rect(Rect2(x - 4, 76 if alive else 70, 8, 4), Color(0.86, 0.30, 0.28) if alive else Color(0.50, 0.48, 0.46))
	if not alive:
		_ruin(64.0, 36.0, 2)


## Bäckerei: kleines Haus mit Walmdach, vorne Schaufenster, Brezel-Schild, Tischchen und Fahrradständer.
func _bakery(alive: bool) -> void:
	_hip(42.0, 32.0, alive, Color(0.72, 0.36, 0.24), 2)
	_tf(Vector2.ZERO, angle)
	draw_rect(Rect2(-34, 32, 68, 8), Color(0.80, 0.90, 0.96) if alive else Color(0.30, 0.30, 0.30))   # Schaufenster
	var pretzel := Color(0.66, 0.42, 0.20) if alive else Color(0.52, 0.48, 0.44)
	draw_arc(Vector2(-6, 50), 5.0, 0.0, TAU, 16, pretzel, 2.5)
	draw_arc(Vector2(4, 50), 5.0, 0.0, TAU, 16, pretzel, 2.5)
	_ring(Vector2(34, 56), 9.0, Color(0.92, 0.92, 0.90) if alive else Color(0.58, 0.56, 0.54), INK, 1.5)   # Tischchen
	for k in 3:   # Fahrradständer
		draw_line(Vector2(-46 + k * 6, 48), Vector2(-46 + k * 6, 62), Color(0.55, 0.58, 0.62), 2.0)


## Pavillon auf dem Vorplatz: achteckiges Dach auf Säulen, ringsum Bänke und Blumen.
func _pavilion(alive: bool) -> void:
	_tf(Vector2(8, 10))
	_dot(Vector2.ZERO, 44.0, SHADOW)
	_tf()
	var roof := Color(0.36, 0.56, 0.52) if alive else Color(0.56, 0.54, 0.51)
	var pts := PackedVector2Array()
	for k in 8:
		pts.append(Vector2.from_angle(k * TAU / 8.0 + TAU / 16.0) * 42.0)
	for k in 8:
		_quad(PackedVector2Array([Vector2.ZERO, pts[k], pts[(k + 1) % 8]]), roof.lightened(0.08) if k % 2 == 0 else roof.darkened(0.08))
	_outline(pts, INK, 2.5)
	for k in 8:
		draw_line(Vector2.ZERO, pts[k], INK, 1.2)
	_ring(Vector2.ZERO, 6.0, Color(0.95, 0.85, 0.40) if alive else Color(0.55, 0.52, 0.48), INK, 1.5)
	if alive:
		for k in 12:
			_flower(Vector2.from_angle(k * TAU / 12.0) * 54.0, FLOWERS[k % FLOWERS.size()], 3.2)
	else:
		_ruin(30.0, 30.0, 1)


## --- Felder: Gutshof, Maschinenhalle, Weizenfeld ---

## Gutshof: großes Haus mit dunklem Walmdach und Gauben, dazu ein Seitenflügel (L-Form).
func _manor(alive: bool) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-100, -2, 44, 90), SHADOW)
	_tf(Vector2.ZERO, angle)
	var wing := Color(0.70, 0.30, 0.24) if alive else Color(0.56, 0.52, 0.48)
	draw_rect(Rect2(-100, 0, 44, 86), wing.darkened(0.06))
	draw_line(Vector2(-78, 4), Vector2(-78, 84), INK, 2.0)
	_outline(PackedVector2Array([Vector2(-100, 0), Vector2(-56, 0), Vector2(-56, 86), Vector2(-100, 86)]), INK, 2.5)
	_hip(72.0, 42.0, alive, Color(0.30, 0.32, 0.36), 4)
	_tf(Vector2.ZERO, angle)
	for k in 3:   # Gauben
		var gp := Vector2(-36 + k * 36, 22)
		_rect_ink(Rect2(gp - Vector2(8, 6), Vector2(16, 12)), Color(0.86, 0.84, 0.78) if alive else Color(0.56, 0.54, 0.50), 1.5)
		draw_rect(Rect2(gp - Vector2(4, 2), Vector2(8, 6)), Color(0.74, 0.87, 0.96) if alive else Color(0.24, 0.24, 0.26))
	draw_rect(Rect2(-9, 40, 18, 9), Color(0.40, 0.28, 0.20))


## Maschinenhalle: Wellblechdach mit Rippen, offene Seite mit Traktor davor. Kaputt: Rost und Löcher.
func _machine_hall(alive: bool) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-84, -48, 168, 96), SHADOW)
	_tf(Vector2.ZERO, angle)
	var tin := Color(0.70, 0.76, 0.80) if alive else Color(0.58, 0.56, 0.53)
	draw_rect(Rect2(-84, -48, 168, 48), tin.lightened(0.06))
	draw_rect(Rect2(-84, 0, 168, 48), tin.darkened(0.1))
	for k in 21:
		var x := -84.0 + 4 + k * 8.0
		draw_line(Vector2(x, -46), Vector2(x, 46), tin.darkened(0.22), 1.5)
	draw_line(Vector2(-84, 0), Vector2(84, 0), INK, 2.5)
	_outline(PackedVector2Array([Vector2(-84, -48), Vector2(84, -48), Vector2(84, 48), Vector2(-84, 48)]), INK, 3.0)
	_rng.seed = obj_seed
	if not alive:
		for k in 4:
			var p := Vector2(_rng.randf_range(-70, 70), _rng.randf_range(-36, 36))
			_dot(p, _rng.randf_range(8, 14), Color(0.62, 0.38, 0.22, 0.7))
			if k % 2 == 0:
				_dot(p, 5.0, Color(0.24, 0.22, 0.21))
	# Traktor vor dem offenen Tor
	var t := Vector2(-20, 70)
	var body := Color(0.30, 0.60, 0.30) if alive else Color(0.55, 0.42, 0.32)
	_rect_ink(Rect2(t + Vector2(-16, -12), Vector2(44, 24)), body, 1.5)
	_rect_ink(Rect2(t + Vector2(-14, -9), Vector2(16, 18)), Color(0.80, 0.90, 0.96) if alive else Color(0.40, 0.40, 0.40), 1.2)   # Kabine
	for w in [Vector2(-8, -16), Vector2(-8, 16)]:
		draw_rect(Rect2(t + w - Vector2(9, 4), Vector2(18, 8)), Color(0.18, 0.18, 0.20))   # große Räder
	for w in [Vector2(22, -14), Vector2(22, 14)]:
		draw_rect(Rect2(t + w - Vector2(5, 3), Vector2(10, 6)), Color(0.18, 0.18, 0.20))
	_dot(t + Vector2(14, -6), 2.5, INK)   # Auspuff


## Weizenfeld: goldene Halme in Reihen, am Rand Mohn, Fahrspuren. Tot: graue Stoppeln.
func _wheat(alive: bool) -> void:
	_tf()
	var r := Rect2(-104, -64, 208, 128)
	draw_rect(r, Color(0.90, 0.76, 0.36) if alive else Color(0.64, 0.60, 0.53))
	_rng.seed = obj_seed
	for k in 16:
		var y := r.position.y + 6 + k * 7.6
		for j in 26:
			var x := r.position.x + 4 + j * 8.0 + (k % 2) * 4.0
			if alive:
				draw_line(Vector2(x, y + 3), Vector2(x + 1.5, y - 3), Color(0.78, 0.60, 0.22), 1.6)
				_dot(Vector2(x + 1.5, y - 3), 1.6, Color(0.98, 0.86, 0.46))
			elif (j + k) % 3 == 0:
				draw_line(Vector2(x, y + 1), Vector2(x + 1, y - 2), Color(0.52, 0.49, 0.44), 1.2)
	for x in [-40.0, 40.0]:   # Fahrspuren
		draw_line(Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), Color(0.74, 0.60, 0.30) if alive else Color(0.56, 0.53, 0.48), 3.0)
	if alive:
		for k in 14:
			_dot(Vector2(_rng.randf_range(r.position.x + 4, r.end.x - 4), r.end.y - _rng.randf_range(2, 10)), 2.6, Color(0.92, 0.22, 0.20))
	_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color(0.62, 0.48, 0.24) if alive else Color(0.50, 0.47, 0.42), 2.0)


## --- Großstadt: Altstadt ---

## Dom: langes Kirchenschiff mit Querhaus (Kreuzform), Kupferdach, vorne zwei Türme mit grünen Spitzen.
func _cathedral(alive: bool) -> void:
	_tf(Vector2(10, 14), angle)
	draw_rect(Rect2(-40, -84, 80, 168), SHADOW)
	draw_rect(Rect2(-70, -40, 140, 50), SHADOW)
	_tf(Vector2.ZERO, angle)
	var roof := Color(0.40, 0.66, 0.58) if alive else Color(0.56, 0.54, 0.51)
	for r in [Rect2(-40, -84, 80, 150), Rect2(-70, -44, 140, 46)]:
		draw_rect(Rect2(r.position, Vector2(r.size.x * 0.5, r.size.y)), roof.lightened(0.08))
		draw_rect(Rect2(r.position + Vector2(r.size.x * 0.5, 0), Vector2(r.size.x * 0.5, r.size.y)), roof.darkened(0.1))
		_outline(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), INK, 3.0)
	draw_line(Vector2(0, -84), Vector2(0, 66), INK, 2.5)
	draw_line(Vector2(-70, -21), Vector2(70, -21), INK, 2.0)
	_ring(Vector2(0, -21), 16.0, roof.lightened(0.2), INK, 2.5)   # Vierungskuppel
	var stone := Color(0.84, 0.80, 0.72) if alive else Color(0.62, 0.60, 0.57)
	for sx in [-24.0, 24.0]:   # Türme vorne
		var c := Vector2(sx, 82)
		var pts := PackedVector2Array([c + Vector2(-18, -18), c + Vector2(18, -18), c + Vector2(18, 18), c + Vector2(-18, 18)])
		draw_rect(Rect2(c - Vector2(18, 18), Vector2(36, 36)), stone)
		for k in 4:
			_quad(PackedVector2Array([c, pts[k], pts[(k + 1) % 4]]), roof.lightened(0.12) if k % 2 == 0 else roof.darkened(0.1))
		_outline(pts, INK, 2.5)
		_dot(c, 3.0, Color(1.0, 0.84, 0.35) if alive else Color(0.45, 0.42, 0.40))
	if not alive:
		_ruin(40.0, 70.0, 4)


## Museum (Stadtbibliothek): flaches Steindach mit Kuppel, vorne eine Säulenreihe und Treppe.
func _museum(alive: bool) -> void:
	_tf(Vector2(8, 10), angle)
	draw_rect(Rect2(-62, -46, 124, 92), SHADOW)
	_tf(Vector2.ZERO, angle)
	var stone := Color(0.90, 0.87, 0.80) if alive else Color(0.62, 0.60, 0.57)
	_rect_ink(Rect2(-62, -46, 124, 92), stone, 3.0)
	_rect_ink(Rect2(-54, -38, 108, 76), stone.darkened(0.06), 1.5)
	_ring(Vector2(0, -4), 26.0, Color(0.50, 0.66, 0.78) if alive else Color(0.56, 0.55, 0.53), INK, 2.5)
	_ring(Vector2(0, -4), 14.0, Color(0.62, 0.76, 0.86) if alive else Color(0.60, 0.59, 0.57), INK, 1.5)
	_dot(Vector2(-6, -10), 5.0, Color(1, 1, 1, 0.35 if alive else 0.1))
	for k in 6:   # Säulen
		_ring(Vector2(-45 + k * 18, 54), 5.0, stone.lightened(0.05), INK, 1.5)
	for k in 3:   # Treppe
		draw_line(Vector2(-52, 62 + k * 4), Vector2(52, 62 + k * 4), stone.darkened(0.15 + k * 0.05), 3.0)
	if not alive:
		_ruin(62.0, 46.0, 2)


## Café: Haus schräg von oben (zwei Stockwerke) mit Markise, davor Tische mit Sonnenschirmen.
func _cafe(alive: bool) -> void:
	_tf()
	_rng.seed = obj_seed
	var e := _screen_extent(Vector2(52, 30))
	var f := 2 * FLOOR_PX + 14.0
	var wall: Color = WALLS[obj_seed % WALLS.size()] if alive else Color(0.62, 0.61, 0.59)
	draw_rect(Rect2(Vector2(-e.x + 12, -e.y - f + 18), Vector2(e.x * 2 + 20, e.y * 2 + f - 10)), SHADOW)
	var face := Rect2(Vector2(-e.x, e.y - f), Vector2(e.x * 2, f))
	draw_rect(face, wall.darkened(0.1))
	for k in int((e.x * 2 - 12) / 20.0):
		draw_rect(Rect2(Vector2(face.position.x + 10 + k * 20, face.position.y + 6), Vector2(12, 9)), Color(0.74, 0.87, 0.96) if alive else Color(0.24, 0.24, 0.26))
	var aw: Color = AWNINGS[obj_seed % AWNINGS.size()] if alive else Color(0.55, 0.53, 0.50)
	for k in int(e.x * 2 / 12.0):
		draw_rect(Rect2(Vector2(-e.x + k * 12, face.end.y - 16), Vector2(12, 9)), aw if k % 2 == 0 else Color(0.98, 0.96, 0.92) if alive else aw.lightened(0.2))
	_outline(PackedVector2Array([face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y)]), INK, 2.0)
	var roof := Rect2(Vector2(-e.x, -e.y - f), e * 2.0)
	draw_rect(roof, Color(0.72, 0.42, 0.32) if alive else Color(0.56, 0.52, 0.48))
	for k in int(roof.size.y / 7.0):
		draw_line(roof.position + Vector2(2, 4 + k * 7), roof.position + Vector2(roof.size.x - 2, 4 + k * 7), Color(0.50, 0.30, 0.24, 0.6), 1.2)
	_outline(PackedVector2Array([roof.position, Vector2(roof.end.x, roof.position.y), roof.end, Vector2(roof.position.x, roof.end.y)]), INK, 2.5)
	for k in 3:   # Tische mit Schirmen vor dem Haus
		var c := Vector2(-e.x + 18 + k * (e.x * 2 - 36) / 2.0, e.y + 26)
		if alive:
			for s in 8:
				_quad(PackedVector2Array([c, c + Vector2.from_angle(s * TAU / 8.0) * 16.0, c + Vector2.from_angle((s + 1) * TAU / 8.0) * 16.0]), aw if s % 2 == 0 else Color(0.98, 0.96, 0.92))
			_dot(c, 2.0, INK)
		else:
			_ring(c, 7.0, Color(0.58, 0.56, 0.54), INK, 1.2)


## Stadtschule: Gebäude schräg von oben (drei Stockwerke, orange) mit Sportplatz daneben.
func _city_school(alive: bool) -> void:
	_tf()
	var court := Rect2(-70, 46, 140, 70)
	draw_rect(court, Color(0.86, 0.46, 0.34) if alive else Color(0.58, 0.56, 0.53))
	var line := Color(1, 1, 1, 0.9) if alive else Color(0.70, 0.70, 0.68)
	_outline(PackedVector2Array([court.position + Vector2(6, 6), Vector2(court.end.x - 6, court.position.y + 6), court.end - Vector2(6, 6), Vector2(court.position.x + 6, court.end.y - 6)]), line, 1.5)
	draw_line(Vector2(0, court.position.y + 6), Vector2(0, court.end.y - 6), line, 1.5)
	draw_arc(court.get_center(), 12.0, 0.0, TAU, 20, line, 1.5)
	for x in [court.position.x + 8, court.end.x - 8]:
		draw_line(Vector2(x, court.get_center().y - 10), Vector2(x, court.get_center().y + 10), Color(0.95, 0.95, 0.95), 3.0)   # Tore
	var e := Vector2(64, 30)
	var f := 3 * FLOOR_PX + 14.0
	var wall := Color(0.96, 0.66, 0.36) if alive else Color(0.62, 0.61, 0.59)
	draw_rect(Rect2(Vector2(-e.x + 12, -e.y - f + 18), Vector2(e.x * 2 + 24, e.y * 2 + f - 10)), SHADOW)
	var face := Rect2(Vector2(-e.x, e.y - f), Vector2(e.x * 2, f))
	draw_rect(face, wall.darkened(0.1))
	for k in 3:
		for c in 6:
			draw_rect(Rect2(Vector2(face.position.x + 8 + c * 20, face.position.y + 6 + k * FLOOR_PX), Vector2(14, 9)), Color(0.74, 0.87, 0.96) if alive else Color(0.24, 0.24, 0.26))
	_outline(PackedVector2Array([face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y)]), INK, 2.0)
	var roof := Rect2(Vector2(-e.x, -e.y - f), e * 2.0)
	_rect_ink(roof, wall.lightened(0.15) if alive else Color(0.60, 0.59, 0.57), 2.5)
	if alive:   # Uhr über dem Eingang
		_ring(Vector2(0, face.position.y + 4), 6.0, Color(0.98, 0.98, 0.96), INK, 1.5)


## Hochbeete der Gemeinschaftsgärten: Holzkästen im Raster mit Gemüse und Blumen. Kaputt: leer und morsch.
func _raised_beds(alive: bool) -> void:
	_tf()
	var wood := Color(0.66, 0.48, 0.30) if alive else Color(0.55, 0.51, 0.46)
	for row in 2:
		for col in 3:
			var r := Rect2(Vector2(-48 + col * 34, -30 + row * 32), Vector2(28, 24))
			_rect_ink(r, wood, 1.5)
			draw_rect(r.grow(-3), Color(0.40, 0.30, 0.20) if alive else Color(0.58, 0.55, 0.50))
			if alive:
				for j in 3:
					_dot(r.position + Vector2(7 + j * 7, 12), 3.5, Color(0.42, 0.74, 0.32) if (row + col + j) % 3 else FLOWERS[(row + col + j) % FLOWERS.size()])


## Spielplatz: Klettergerüst, Wippe, Sandkasten auf Fallschutz.
func _playground(alive: bool) -> void:
	_tf()
	var base := Rect2(-56, -40, 112, 80)
	draw_rect(base, Color(0.86, 0.52, 0.40) if alive else Color(0.60, 0.58, 0.54))
	_outline(PackedVector2Array([base.position, Vector2(base.end.x, base.position.y), base.end, Vector2(base.position.x, base.end.y)]), INK, 2.0)
	_rect_ink(Rect2(-48, -32, 34, 34), Color(0.94, 0.86, 0.62) if alive else Color(0.62, 0.60, 0.56), 1.5)
	var metal := Color(0.30, 0.52, 0.86) if alive else Color(0.50, 0.48, 0.46)
	for k in 4:   # Klettergerüst
		draw_line(Vector2(4 + k * 12, -30), Vector2(4 + k * 12, 6), metal, 2.5)
		draw_line(Vector2(4, -30 + k * 12), Vector2(40, -30 + k * 12), metal, 2.5)
	draw_line(Vector2(-40, 24), Vector2(10, 18 if alive else 30), Color(0.96, 0.80, 0.24) if alive else Color(0.55, 0.53, 0.50), 6.0)   # Wippe
	_dot(Vector2(-15, 21), 4.0, INK)


## Stadtbrunnen: quadratisches Becken mit Fontänen in den Ecken und einer Statue in der Mitte.
func _fountain_city(alive: bool) -> void:
	_tf(Vector2(8, 10))
	draw_rect(Rect2(-48, -48, 96, 96), SHADOW)
	_tf()
	_rect_ink(Rect2(-48, -48, 96, 96), Color(0.76, 0.74, 0.70), 3.0)
	draw_rect(Rect2(-40, -40, 80, 80), Color(0.40, 0.66, 0.88) if alive else Color(0.60, 0.57, 0.52))
	if alive:
		for c in [Vector2(-26, -26), Vector2(26, -26), Vector2(-26, 26), Vector2(26, 26)]:
			for k in 6:
				_dot(c + Vector2.from_angle(k * TAU / 6.0) * 7.0, 2.5, Color(0.92, 0.97, 1.0))
			_dot(c, 3.5, Color(1, 1, 1))
	_ring(Vector2.ZERO, 14.0, Color(0.70, 0.70, 0.72), INK, 2.0)   # Sockel
	_ring(Vector2(0, -2), 8.0, Color(0.52, 0.66, 0.60) if alive else Color(0.56, 0.55, 0.53), INK, 1.5)   # Statue (Bronze)
	_dot(Vector2(0, -4), 3.5, Color(0.60, 0.74, 0.68) if alive else Color(0.60, 0.59, 0.57))
