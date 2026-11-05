class_name BirdView
extends Node2D
## Zeichnet das Vogelhäuschen und alle Schwärme der Samenvögel in einem einzigen _draw.
## Ein Schwarm fliegt in V-Form (der Anführer vorn), hoch über dem Boden (Schatten weit versetzt),
## mit schlagenden Flügeln; beim Säen fallen kleine Samen. Rastende Schwärme picken Körner neben dem Häuschen.
## Kreise über Disc, Flügel und Schnabel als Dreiecke (draw_primitive).

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.13)
const BODY := Color(0.42, 0.62, 0.92)
const BELLY := Color(1.0, 0.80, 0.62)
const WING := Color(0.33, 0.50, 0.82)
const BEAK := Color(1.0, 0.62, 0.22)
const SEED := Color(0.62, 0.46, 0.28)
const K := 1.15         # Größe der Vögel
const HIGH := Vector2(26, 52)   # Schattenversatz im Flug

var _birds: SeedBirds
var _time := 0.0
var _has_nest := false


func bind(birds: SeedBirds) -> void:
	_birds = birds
	z_index = 6


func _process(delta: float) -> void:
	_time += delta
	var on := _birds != null and not _birds.flocks.is_empty()
	if on or _has_nest != on:
		queue_redraw()
	_has_nest = on


func _draw() -> void:
	if _birds == null or _birds.flocks.is_empty():
		return
	_draw_nest(_birds.nest)
	for s in _birds.seeds:
		var t := clampf((_birds.time - s.z) / SeedBirds.SEED_SEC, 0.0, 1.0)
		var p := Vector2(s.x, s.y)
		Disc.dot(self, p + HIGH * (1.0 - t) * 0.5 - Vector2(0, 30) * (1.0 - t), 2.6, Color(SEED, 1.0 - t * 0.5))
	for j in _birds.flocks.size():
		var f: SeedBirds.Flock = _birds.flocks[j]
		if f.state == SeedBirds.State.REST:
			_draw_resting(f, j)
		else:
			_draw_flock(f, j)
	draw_set_transform(Vector2.ZERO)


## Vogelhäuschen von oben: Pfahl mit Schatten, kleines Satteldach, vorne Einflugloch und Sitzstange.
func _draw_nest(p: Vector2) -> void:
	draw_set_transform(p + Vector2(10, 14), 0.0, Vector2(1.0, 0.7))
	Disc.dot(self, Vector2.ZERO, 26.0, Color(0, 0, 0, 0.16))
	draw_set_transform(Vector2.ZERO)
	var w := 22.0
	var h := 17.0
	var roof := Color(0.30, 0.62, 0.58)
	draw_rect(Rect2(p + Vector2(-w, -h), Vector2(w * 2, h)), roof.lightened(0.1))
	draw_rect(Rect2(p + Vector2(-w, 0), Vector2(w * 2, h)), roof.darkened(0.1))
	for k in 2:
		var y := -h + 6.0 + k * 6.0
		draw_line(p + Vector2(-w + 2, y), p + Vector2(w - 2, y), roof.darkened(0.25), 1.2)
		draw_line(p + Vector2(-w + 2, -y), p + Vector2(w - 2, -y), roof.darkened(0.3), 1.2)
	draw_line(p + Vector2(-w, 0), p + Vector2(w, 0), INK, 2.5)
	for e in [[Vector2(-w, -h), Vector2(w, -h)], [Vector2(w, -h), Vector2(w, h)], [Vector2(w, h), Vector2(-w, h)], [Vector2(-w, h), Vector2(-w, -h)]]:
		draw_line(p + e[0], p + e[1], INK, 2.5)
	Disc.ring_dot(self, p + Vector2(0, h + 4), 5.0, Color(0.20, 0.16, 0.14), INK, 1.5)   # Einflugloch
	draw_line(p + Vector2(-9, h + 12), p + Vector2(9, h + 12), Color(0.55, 0.40, 0.26), 3.0)   # Sitzstange
	for k in 6:   # Körner vor dem Häuschen
		Disc.dot(self, p + Vector2(-16 + k * 6.5, h + 22 + (k % 2) * 4), 2.2, SEED)


## V-Form: Anführer vorn, die anderen schräg dahinter links und rechts.
func _draw_flock(f: SeedBirds.Flock, j: int) -> void:
	var ang := f.dir.angle()
	var back := -f.dir
	var side := f.dir.orthogonal()
	var high := HIGH * (0.75 if f.state == SeedBirds.State.SOW else 1.0)
	for i in _birds.flock_size:
		var row := (i + 1) / 2
		var s := 1.0 if i % 2 == 1 else -1.0
		var p := f.pos + back * row * 26.0 + side * s * row * 22.0
		p += Vector2(sin(_time * 1.7 + i * 2.1 + j), cos(_time * 1.3 + i * 1.4)) * 3.0   # leichtes Schaukeln
		var flap := sin(_time * (11.0 if f.state == SeedBirds.State.SOW else 8.0) + i * 0.9 + j * 1.7)
		_bird(p, ang, flap, high)


## Rastende Vögel picken Körner rund um das Häuschen (Kopf nickt, ab und zu ein Hüpfer).
func _draw_resting(f: SeedBirds.Flock, j: int) -> void:
	var c := _birds.nest + Vector2(0, 70.0 + 26.0 * (j / 4)).rotated(j * 1.25 - 0.6) + Vector2(0, -12)   # jeder Schwarm an seinem Platz
	var n := mini(_birds.flock_size, 3)   # rastend nur ein paar sichtbar, der Rest sitzt im Häuschen
	for i in n:
		var a := i * TAU / n + j
		var hop := maxf(0.0, sin(_time * 2.3 + i * 1.9 + j))
		var p := c + Vector2.from_angle(a) * (16.0 + 8.0 * (i % 2)) + Vector2(0, -hop * hop * 6.0)
		var look := a + PI + sin(_time * 0.9 + i) * 0.8
		var peck := 2.0 if fmod(_time * 1.6 + i * 0.7, 1.0) < 0.2 else 0.0
		Disc.dot(self, p + Vector2(4, 6), 7.0, SHADOW)
		_body(Transform2D(look, Vector2(K, K) * 0.85, 0.0, p), peck)


## Fliegender Vogel: Schatten (versetzt), Flügel (flap −1..1), Schwanz, Körper, Kopf mit Schnabel.
func _bird(p: Vector2, ang: float, flap: float, high: Vector2) -> void:
	draw_set_transform(p + high, ang, Vector2(K, K * (0.6 + 0.4 * absf(flap))))
	_tri(Vector2(4, 0), Vector2(-6, -18), Vector2(-6, 18), SHADOW)
	Disc.dot(self, Vector2.ZERO, 7.0, SHADOW)
	var xf := Transform2D(ang, Vector2(K, K), 0.0, p)
	draw_set_transform_matrix(xf)
	var span := 6.0 + 12.0 * (0.5 + 0.5 * flap)
	for sy in [-1.0, 1.0]:
		_tri(Vector2(4, sy * 2.0), Vector2(-6, sy * 2.0), Vector2(-3, sy * span), WING)
		draw_line(Vector2(4, sy * 2.0), Vector2(-3, sy * span), INK, 1.2)
	_body(xf, 0.0)


## Körper, Schwanz, Kopf und Schnabel im Raum xf (vorn = +x); peck schiebt den Kopf nach vorn.
func _body(xf: Transform2D, peck: float) -> void:
	draw_set_transform_matrix(xf)
	_tri(Vector2(-6, 0), Vector2(-15, -5), Vector2(-15, 5), WING.darkened(0.15))   # Schwanz
	draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(1.35, 1.0), 0.0, Vector2.ZERO))
	Disc.ring_dot(self, Vector2.ZERO, 7.0, BODY, INK, 1.5)
	draw_set_transform_matrix(xf)
	Disc.dot(self, Vector2(-1, 0), 3.8, BELLY)
	var head := Vector2(8 + peck, 0)
	Disc.ring_dot(self, head, 4.6, BODY.lightened(0.08), INK, 1.3)
	_tri(head + Vector2(3.5, -1.8), head + Vector2(8.5, 0), head + Vector2(3.5, 1.8), BEAK)
	Disc.dot(self, head + Vector2(1.5, -2.4), 1.1, INK)
	Disc.dot(self, head + Vector2(1.5, 2.4), 1.1, INK)


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col]), PackedVector2Array())
