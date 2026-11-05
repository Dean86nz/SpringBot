class_name VillagerView
extends Node2D
## Zeichnet das Leben im Dorf von oben, alles mit Disc (Kreise als Textur) in einem einzigen _draw:
## Menschen mit Kleidung je Arbeit (Schmied mit Schürze und Hammer, Bauer mit Strohhut und Hacke,
## Imker im weißen Anzug mit Schleier, Kinder kleiner und bunt), Hunde und Katzen, die Wäsche an der Leine,
## Honiggläser auf dem Stand, den Ball der Kinder und Funken am Amboss. Beim Fest hüpfen alle.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const CLOTHES := [Color(0.86, 0.36, 0.34), Color(0.36, 0.56, 0.86), Color(0.98, 0.80, 0.30), Color(0.48, 0.74, 0.42), Color(0.72, 0.50, 0.86), Color(0.96, 0.62, 0.40)]
const SKIN := [Color(0.98, 0.84, 0.70), Color(0.86, 0.66, 0.50), Color(0.62, 0.44, 0.32)]
const HAIR := [Color(0.30, 0.22, 0.16), Color(0.86, 0.70, 0.36), Color(0.54, 0.30, 0.20), Color(0.18, 0.18, 0.20), Color(0.80, 0.80, 0.78)]
const FUR := [Color(0.62, 0.44, 0.28), Color(0.92, 0.88, 0.80), Color(0.30, 0.26, 0.24), Color(0.86, 0.60, 0.30)]
const WASH := [Color(0.98, 0.98, 0.96), Color(0.55, 0.72, 0.95), Color(0.98, 0.70, 0.76), Color(0.98, 0.88, 0.45), Color(0.70, 0.88, 0.62), Color(0.96, 0.96, 0.98)]
const SCALE := 2.2

var _v: Villagers


func bind(v: Villagers) -> void:
	_v = v
	z_index = 4


func _process(_delta: float) -> void:
	if _v and _v.count_back() > 0:
		queue_redraw()


func _draw() -> void:
	if _v == null or _v.count_back() == 0:
		return
	_draw_things()
	for p in _v.people:
		if not p.back or p.delay > 0.0:
			continue
		match p.kind:
			Villagers.Kind.DOG: _dog(p)
			Villagers.Kind.CAT: _cat(p)
			_: _human(p)
	draw_set_transform(Vector2.ZERO)


## Wäsche, Honiggläser, Ball.
func _draw_things() -> void:
	for id: String in _v.laundry:
		var base: Vector2 = _v.places[id]["pos"]
		for k in int(_v.laundry[id]):
			var x := -50.0 + k * 20.0
			var col: Color = WASH[(k + id.length()) % WASH.size()]
			var sway := sin(Time.get_ticks_msec() * 0.003 + k) * 1.5
			draw_rect(Rect2(base + Vector2(x - 7 + sway, -2), Vector2(14, 12 if k % 2 else 9)), col)
			draw_line(base + Vector2(x - 7 + sway, -2), base + Vector2(x + 7 + sway, -2), INK, 1.0)
	for id: String in _v.places:
		if _v.places[id]["type"] == "stand":
			var pl: Dictionary = _v.places[id]
			for k in _v.jars:
				var j: Vector2 = pl["pos"] + Vector2(-20 + k * 8, 8).rotated(float(pl["angle"]))
				Disc.ring_dot(self, j, 3.6, Color(1.0, 0.70, 0.18), INK, 1.2)
	var has_kids := false
	for p in _v.people:
		if p.back and p.job == "kid" and not p.arriving:
			has_kids = true
	if has_kids and not _v.festive:
		Disc.dot(self, _v.ball + Vector2(3, 4), 6.0, SHADOW)
		Disc.ring_dot(self, _v.ball, 6.0, Color(0.95, 0.30, 0.28), INK, 1.5)
		Disc.dot(self, _v.ball + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.9))


func _human(p: Villagers.Person) -> void:
	var walking := p.wait <= 0.0 and p.pos != p.target
	var kid := p.job == "kid"
	var k := SCALE * (0.72 if kid else 1.0)
	var hop := 0.0
	if _v.festive and p.wait > 0.0:
		hop = absf(sin(p.act * 7.0)) * 8.0   # Freudensprünge
	elif kid and walking:
		hop = absf(sin(p.phase * 1.5)) * 4.0
	Disc.dot(self, p.pos + Vector2(3, 4) * k + Vector2(0, hop * 0.3), 9.0 * k, SHADOW)
	draw_set_transform(p.pos - Vector2(0, hop), p.dir, Vector2.ONE * k)
	var cloth: Color = CLOTHES[p.look % CLOTHES.size()]
	var skin: Color = SKIN[(p.look / 6) % SKIN.size()]
	match p.job:
		"smith": cloth = Color(0.38, 0.30, 0.26)
		"beekeeper": cloth = Color(0.97, 0.97, 0.94)
		"farmer": cloth = Color(0.40, 0.52, 0.72)
	var swing := sin(p.phase) * 4.0 if walking else 0.0
	var work := p.wait > 0.0 or p.sitting
	# Arme: beim Gehen schwingen, bei der Arbeit nach vorne
	for side in [-1.0, 1.0]:
		var hand := Vector2(swing * side, side * 8.0)
		if work and p.job in ["smith", "farmer", "read"]:
			hand = Vector2(7, side * 5.0)
		if p.carry:
			hand = Vector2(8, side * 4.0)
		Disc.ring_dot(self, hand, 3.2, cloth.darkened(0.1), INK, 1.5)
	Disc.ring_dot(self, Vector2.ZERO, 7.5, cloth, INK, 2.0)
	if p.job == "smith":   # Lederschürze
		Disc.dot(self, Vector2(3, 0), 4.5, Color(0.52, 0.36, 0.24))
	# Kopf
	if p.job == "beekeeper":
		Disc.ring_dot(self, Vector2(1, 0), 6.5, Color(0.96, 0.96, 0.92), INK, 1.5)   # Hut mit Schleier
		for g in 3:
			draw_line(Vector2(2 + g * 2 - 2, -4), Vector2(2 + g * 2 - 2, 4), Color(0.25, 0.25, 0.28, 0.7), 0.8)
	else:
		Disc.ring_dot(self, Vector2(1, 0), 5.0, skin, INK, 1.5)
		var hair: Color = HAIR[(p.look / 18) % HAIR.size()]
		if p.job == "farmer" or p.look % 7 == 0:   # Strohhut
			Disc.ring_dot(self, Vector2(0, 0), 7.0, Color(0.94, 0.84, 0.52), INK, 1.5)
			Disc.dot(self, Vector2(0, 0), 3.5, Color(0.84, 0.70, 0.40))
		else:
			Disc.dot(self, Vector2(-1.5, 0), 4.2, hair)
	# Werkzeug und Getragenes
	if p.job == "smith" and work:
		var lift := absf(sin(p.act * 5.0))
		var tip := Vector2(14 - lift * 4, 0)
		draw_line(Vector2(8, 4), tip + Vector2(0, 4), Color(0.50, 0.36, 0.24), 2.0)
		draw_rect(Rect2(tip + Vector2(-3, 1), Vector2(6, 6)), Color(0.32, 0.32, 0.36))
		if lift < 0.15:   # Schlag: Funken
			for s in 4:
				Disc.dot(self, Vector2(20 + s * 2.5, -6 + s * 4) , 1.6, Color(1.0, 0.80, 0.30))
	elif p.job == "farmer" and work:
		var chop := sin(p.act * 6.0) * 3.0
		draw_line(Vector2(6, 4), Vector2(18 + chop, 4), Color(0.55, 0.40, 0.26), 2.0)
		draw_line(Vector2(18 + chop, 0), Vector2(18 + chop, 8), Color(0.45, 0.45, 0.48), 2.5)
	elif p.job == "read" and p.sitting:
		var flip := 1.0 if fmod(p.act, 6.0) < 5.6 else 0.3
		draw_rect(Rect2(Vector2(8, -6), Vector2(6, 12)), Color(0.82, 0.30, 0.30))
		draw_rect(Rect2(Vector2(9, -5), Vector2(4, 10 * flip)), Color(0.98, 0.96, 0.90))
	elif p.carry and p.job == "beekeeper":
		Disc.ring_dot(self, Vector2(11, 0), 3.6, Color(1.0, 0.70, 0.18), INK, 1.2)
	elif p.carry and p.job == "laundry":
		Disc.ring_dot(self, Vector2(12, 0), 6.0, Color(0.80, 0.66, 0.42), INK, 1.5)
		Disc.dot(self, Vector2(12, 0), 3.5, Color(0.98, 0.98, 0.96))
	draw_set_transform(Vector2.ZERO)
	if p.job == "beekeeper" and p.wait > 0.0 and p.pos.distance_to(_v.hive) < 80.0:
		for b in 5:   # Bienen um den Imker
			var a := p.act * 3.0 + b * 1.3
			Disc.dot(self, p.pos + Vector2(cos(a), sin(a * 1.3)) * 22.0, 2.4, Color(1.0, 0.80, 0.25))


func _dog(p: Villagers.Person) -> void:
	var walking := p.pos != p.target
	var fur: Color = FUR[p.look % FUR.size()]
	var k := SCALE * 0.9
	var hop := absf(sin(p.phase * 1.5)) * 2.0 if walking else 0.0
	Disc.dot(self, p.pos + Vector2(3, 4), 8.0 * k, SHADOW)
	draw_set_transform(p.pos - Vector2(0, hop), p.dir, Vector2.ONE * k)
	var wag := sin(p.act * 14.0) * 0.6
	draw_line(Vector2(-8, 0), Vector2(-8, 0) + Vector2.from_angle(PI + wag) * 7.0, fur.darkened(0.2), 2.5)   # Schwanz
	draw_set_transform(p.pos - Vector2(0, hop), p.dir, Vector2(1.5, 1.0) * k)
	Disc.ring_dot(self, Vector2.ZERO, 5.5, fur, INK, 1.5)
	draw_set_transform(p.pos - Vector2(0, hop), p.dir, Vector2.ONE * k)
	Disc.ring_dot(self, Vector2(9, 0), 4.5, fur, INK, 1.5)
	for side in [-1.0, 1.0]:
		Disc.dot(self, Vector2(8, side * 4.0), 2.4, fur.darkened(0.3))   # Schlappohren
	Disc.dot(self, Vector2(13, 0), 1.6, Color(0.15, 0.15, 0.18))
	draw_set_transform(Vector2.ZERO)


func _cat(p: Villagers.Person) -> void:
	var fur: Color = FUR[(p.look + 1) % FUR.size()]
	var k := SCALE * 0.75
	Disc.dot(self, p.pos + Vector2(2, 3), 6.0 * k, SHADOW)
	draw_set_transform(p.pos, p.dir, Vector2.ONE * k)
	var curl := sin(p.act * 1.5) * 0.4
	for s in 4:   # geringelter Schwanz
		var a := PI + curl + s * 0.35
		Disc.dot(self, Vector2.from_angle(a) * (6.0 + s * 1.8) + Vector2(0, s * 1.2), 1.8, fur.darkened(0.1))
	Disc.ring_dot(self, Vector2.ZERO, 5.0 if p.sitting else 4.5, fur, INK, 1.3)
	Disc.ring_dot(self, Vector2(6, 0), 3.6, fur, INK, 1.2)
	for side in [-1.0, 1.0]:   # spitze Ohren
		_tri(Vector2(6, side * 2.0), Vector2(9, side * 5.5), Vector2(4, side * 4.5), fur.darkened(0.15))
	draw_set_transform(Vector2.ZERO)


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col]), PackedVector2Array())
