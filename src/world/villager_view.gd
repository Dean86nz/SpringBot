class_name VillagerView
extends Node2D
## Zeichnet das Leben im Dorf von oben, alles mit Disc (Kreise als Textur) in einem einzigen _draw:
## Menschen mit Kleidung je Arbeit (Schmied mit Schürze und Hammer, Bauer mit Strohhut und Hacke,
## Imker im weißen Anzug mit Schleier, Kinder kleiner und bunt), Hunde und Katzen, die Wäsche an der Leine,
## Honiggläser auf dem Stand, den Ball der Kinder und Funken am Amboss. Beim Fest hüpfen alle.
## Gebäude im Wiederaufbau bekommen ein Holzgerüst und einen Fortschrittsbalken; wer repariert, hämmert.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const CLOTHES := [Color(0.86, 0.36, 0.34), Color(0.36, 0.56, 0.86), Color(0.98, 0.80, 0.30), Color(0.48, 0.74, 0.42), Color(0.72, 0.50, 0.86), Color(0.96, 0.62, 0.40)]
const SKIN := [Color(0.98, 0.84, 0.70), Color(0.86, 0.66, 0.50), Color(0.62, 0.44, 0.32)]
const HAIR := [Color(0.30, 0.22, 0.16), Color(0.86, 0.70, 0.36), Color(0.54, 0.30, 0.20), Color(0.18, 0.18, 0.20), Color(0.80, 0.80, 0.78)]
const FUR := [Color(0.66, 0.46, 0.28), Color(0.94, 0.90, 0.80), Color(0.62, 0.62, 0.64), Color(0.90, 0.62, 0.30)]   # braun, creme, grau, rotbraun (kein Schwarz: Details sonst unsichtbar)
const WASH := [Color(0.98, 0.98, 0.96), Color(0.55, 0.72, 0.95), Color(0.98, 0.70, 0.76), Color(0.98, 0.88, 0.45), Color(0.70, 0.88, 0.62), Color(0.96, 0.96, 0.98)]
const SCALE := 2.2
## Halbe Größe des Daches je Gebäudeart (wie in world_object.gd), für Gerüst und Bauabschnitte.
const EXTENTS := {"house": Vector2(58, 42), "church": Vector2(38, 62), "school": Vector2(66, 38), "library": Vector2(48, 38),
	"shop": Vector2(48, 36), "smithy": Vector2(44, 36), "farmhouse": Vector2(54, 40), "barn": Vector2(72, 42),
	"stand": Vector2(30, 16), "field": Vector2(104, 64), "laundry": Vector2(64, 8), "cemetery": Vector2(70, 52),
	"windmill": Vector2(40, 40), "silo": Vector2(30, 30), "garden": Vector2(46, 32), "apartment": Vector2(190, 120), "tower": Vector2(120, 120),
	"suburb": Vector2(54, 40), "kita": Vector2(64, 36), "bakery": Vector2(42, 32), "pavilion": Vector2(42, 42), "manor": Vector2(72, 42),
	"machine_hall": Vector2(84, 48), "wheat": Vector2(104, 64), "cathedral": Vector2(40, 84), "museum": Vector2(62, 46), "cafe": Vector2(52, 30),
	"school_city": Vector2(64, 30), "raised_beds": Vector2(48, 30), "playground": Vector2(56, 40), "fountain_city": Vector2(48, 48)}

var _v: Villagers


func bind(v: Villagers) -> void:
	_v = v
	z_index = 4


var _last_back := 0


func _process(_delta: float) -> void:
	if _v == null:
		return
	var n := _v.count_back()
	# auch einmal neu zeichnen, wenn niemand mehr da ist (Neues Spiel), sonst bleibt das alte Bild stehen
	if n > 0 or n != _last_back:
		queue_redraw()
	_last_back = n


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


## Wäsche, Honiggläser, Ball, Gerüste.
func _draw_things() -> void:
	for id: String in _v.repair:
		var r := float(_v.repair[id])
		if r > 0.0 and r < 1.0:
			_scaffold(_v.places[id], r)
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
		"miller": cloth = Color(0.92, 0.90, 0.84)
	var swing := sin(p.phase) * 4.0 if walking else 0.0
	var work := p.wait > 0.0 or p.sitting
	var repairing := p.fix != "" and p.pos == p.target
	# Arme: beim Gehen schwingen, bei der Arbeit nach vorne
	for side in [-1.0, 1.0]:
		var hand := Vector2(swing * side, side * 8.0)
		if repairing or (work and p.job in ["smith", "farmer", "read", "miller"]):
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
		if p.job == "miller":   # Müllermütze
			Disc.ring_dot(self, Vector2(-1, 0), 5.5, Color(0.98, 0.97, 0.94), INK, 1.5)
		elif p.job == "farmer" or p.look % 7 == 0:   # Strohhut
			Disc.ring_dot(self, Vector2(0, 0), 7.0, Color(0.94, 0.84, 0.52), INK, 1.5)
			Disc.dot(self, Vector2(0, 0), 3.5, Color(0.84, 0.70, 0.40))
		else:
			Disc.dot(self, Vector2(-1.5, 0), 4.2, hair)
	# Werkzeug und Getragenes
	if repairing or (p.job == "smith" and work):
		var lift := absf(sin(p.act * 5.0))
		var tip := Vector2(14 - lift * 4, 0)
		draw_line(Vector2(8, 4), tip + Vector2(0, 4), Color(0.50, 0.36, 0.24), 2.0)
		draw_rect(Rect2(tip + Vector2(-3, 1), Vector2(6, 6)), Color(0.32, 0.32, 0.36))
		if lift < 0.15:   # Schlag: Funken am Amboss, Holzspäne am Bau
			var chip := Color(0.82, 0.66, 0.40) if repairing else Color(1.0, 0.80, 0.30)
			for s in 4:
				Disc.dot(self, Vector2(20 + s * 2.5, -6 + s * 4), 1.6, chip)
	elif p.job == "farmer" and work:
		var chop := sin(p.act * 6.0) * 3.0
		draw_line(Vector2(6, 4), Vector2(18 + chop, 4), Color(0.55, 0.40, 0.26), 2.0)
		draw_line(Vector2(18 + chop, 0), Vector2(18 + chop, 8), Color(0.45, 0.45, 0.48), 2.5)
	elif p.job == "miller" and work:   # Mehlsack auf der Schulter
		Disc.ring_dot(self, Vector2(2, 9), 5.5, Color(0.96, 0.92, 0.82), INK, 1.5)
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


## Hund von oben: kräftiger Körper, vier Beine (laufen), großer Kopf mit kurzer, breiter Schnauze,
## große Schlappohren seitlich am Kopf, kurzer, dicker Ringelschwanz, der wedelt.
func _dog(p: Villagers.Person) -> void:
	var walking := p.pos.distance_to(p.target) > 12.0
	var fur: Color = FUR[p.look % FUR.size()]
	var dark := fur.darkened(0.35)
	var k := SCALE * 0.75
	Disc.dot(self, p.pos + Vector2(4, 5), 11.0 * k, SHADOW)
	draw_set_transform(p.pos, p.dir, Vector2.ONE * k)
	var step := sin(p.phase * 2.0) * 3.0 if walking else 0.0
	for leg: Vector2 in [Vector2(5.5, -5.5), Vector2(5.5, 5.5), Vector2(-5.5, -5.5), Vector2(-5.5, 5.5)]:   # Beine
		var sw := step if (leg.x > 0) == (leg.y > 0) else -step
		Disc.ring_dot(self, leg + Vector2(sw, signf(leg.y) * 1.5), 2.4, fur.darkened(0.15), INK, 1.0)
	# kurzer Ringelschwanz, wedelt
	var wag := sin(p.act * 14.0) * 3.0
	var tail := PackedVector2Array([Vector2(-8, 0), Vector2(-12, wag * 0.6), Vector2(-14, wag + 2.5), Vector2(-12.5, wag + 5.0)])
	_curve(tail, INK, 5.0)
	_curve(tail, fur, 3.2)
	_oval(Vector2(-1, 0), Vector2(11.0, 7.4), INK)          # Körper mit Rand
	_oval(Vector2(-1, 0), Vector2(10.0, 6.4), fur)
	Disc.dot(self, Vector2(-3, -1), 3.2, fur.lightened(0.15))   # heller Rückenfleck
	Disc.ring_dot(self, Vector2(9, 0), 6.4, fur, INK, 1.4)   # Kopf
	_oval(Vector2(14.5, 0), Vector2(4.4, 3.6), INK)
	_oval(Vector2(14.5, 0), Vector2(3.7, 2.9), fur.lightened(0.12))   # Schnauze
	Disc.dot(self, Vector2(18.2, 0), 1.9, Color(0.12, 0.12, 0.14))   # Nase
	for side in [-1.0, 1.0]:
		_oval(Vector2(7.5, side * 7.2), Vector2(4.6, 2.9), INK)   # Schlappohren hängen seitlich herab
		_oval(Vector2(7.5, side * 7.2), Vector2(3.9, 2.2), dark)
		Disc.dot(self, Vector2(11.5, side * 2.6), 1.2, Color(0.1, 0.1, 0.12))   # Augen
	draw_set_transform(Vector2.ZERO)


## Katze von oben: schlanker Körper mit Streifen, runder Kopf mit großen spitzen Ohren und Schnurrhaaren,
## langer, glatter Schwanz in weitem Bogen. Sitzend rund, der Schwanz um den Körper gelegt.
func _cat(p: Villagers.Person) -> void:
	var fur: Color = FUR[(p.look + 3) % FUR.size()]
	var stripe := fur.darkened(0.3)
	var k := SCALE * 0.75
	Disc.dot(self, p.pos + Vector2(3, 4), 8.0 * k, SHADOW)
	draw_set_transform(p.pos, p.dir, Vector2.ONE * k)
	var sway := sin(p.act * 2.0) * 0.25
	var body := Vector2(6.0, 6.0) if p.sitting else Vector2(9.0, 4.6)
	# Schwanz: glatte Linie; sitzend um den Körper gelegt, laufend in weitem Bogen nach hinten
	var tail := PackedVector2Array()
	for s in 9:
		var t := float(s) / 8.0
		if p.sitting:
			tail.append(Vector2.from_angle(PI * 0.9 - t * (2.2 + sway)) * Vector2(body.x + 3.0, body.y + 3.0) - Vector2(1, 0))
		else:
			tail.append(Vector2(-body.x - t * 12.0, sin(t * 2.6 + sway) * 5.0 * t))
	_curve(tail, INK, 4.4)
	_curve(tail, fur, 3.0)
	draw_line(tail[tail.size() - 2], tail[tail.size() - 1], stripe, 3.0)   # dunkle Schwanzspitze
	_oval(Vector2(-1, 0), body + Vector2(1, 1), INK)
	_oval(Vector2(-1, 0), body, fur)
	for s in 3:   # Streifen über den Rücken
		var x := -body.x * 0.55 + s * body.x * 0.4
		draw_line(Vector2(x, -body.y + 1.5), Vector2(x + 1.0, body.y - 1.5), stripe, 1.5)
	var head := Vector2(body.x - 0.5, 0)
	for side in [-1.0, 1.0]:   # Schnurrhaare (unter dem Kopf)
		for w in 2:
			draw_line(head + Vector2(3.5, side * 1.5), head + Vector2(9.5, side * (3.0 + w * 2.8)), Color(0.98, 0.98, 0.98), 0.9)
	for side in [-1.0, 1.0]:   # spitze Ohren: schräg nach vorn außen, hinter dem Kopf
		var a := head + Vector2(-2.5, side * 1.8)
		var tip := head + Vector2(3.8, side * 8.4)
		var c := head + Vector2(2.2, side * 3.4)
		_tri(a, tip, c, INK)
		_tri(a + Vector2(0.7, side * 0.5), tip + Vector2(-0.6, -side * 1.3), c + Vector2(-0.5, 0), fur)
		_tri(a + Vector2(1.6, side * 1.6), tip + Vector2(-1.2, -side * 2.6), c + Vector2(-0.9, side * 0.2), Color(0.95, 0.70, 0.72))   # Innenohr
	Disc.ring_dot(self, head, 4.8, fur, INK, 1.3)
	for side in [-1.0, 1.0]:
		Disc.dot(self, head + Vector2(2.2, side * 1.9), 1.2, Color(0.30, 0.62, 0.30))   # grüne Augen
	Disc.dot(self, head + Vector2(4.3, 0), 1.0, Color(0.92, 0.55, 0.60))   # Nase
	draw_set_transform(Vector2.ZERO)


## Linienzug aus einzelnen Linien (billig) mit runden Gelenken.
func _curve(pts: PackedVector2Array, col: Color, w: float) -> void:
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], col, w)
	for i in range(1, pts.size() - 1):
		Disc.dot(self, pts[i], w * 0.5, col)


## Gefülltes Oval in den aktuellen Zeichen-Koordinaten (Disc-Textur gestreckt).
func _oval(c: Vector2, r: Vector2, col: Color) -> void:
	draw_texture_rect(Disc.TEX, Rect2(c - r, r * 2.0), false, col)


## Gebäude im Wiederaufbau, sichtbar in Abschnitten: bis 35 % wird Schutt geräumt (nur Gerüst),
## bis 70 % entsteht ein neuer Dachstuhl aus hellem Holz, danach decken neue Ziegel Reihe für Reihe das Dach.
## Dazu Holzgerüst und Fortschrittsbalken.
func _scaffold(pl: Dictionary, progress: float) -> void:
	var c: Vector2 = pl["pos"]
	var rot := float(pl.get("angle", 0.0))
	var e: Vector2 = EXTENTS.get(pl.get("type", "house"), Vector2(50, 40)) * float(pl.get("size", 1.0))
	var wood := Color(0.70, 0.52, 0.32)
	var fresh := Color(0.90, 0.74, 0.50)
	draw_set_transform(c, rot, Vector2.ONE)
	if progress > 0.35:   # neuer Dachstuhl
		var beams := int(clampf((progress - 0.35) / 0.35, 0.0, 1.0) * (e.x * 2.0 / 12.0))
		draw_rect(Rect2(-e, Vector2(e.x * 2.0, e.y * 2.0)), Color(0.24, 0.22, 0.21, 0.55))
		for k in beams:
			var x := -e.x + 6.0 + k * 12.0
			draw_line(Vector2(x, -e.y), Vector2(x, e.y), INK, 4.5)
			draw_line(Vector2(x, -e.y), Vector2(x, e.y), fresh, 3.0)
		if beams > 0:
			draw_line(Vector2(-e.x, 0), Vector2(-e.x + beams * 12.0, 0), fresh.darkened(0.15), 4.0)
	if progress > 0.7:   # neue Ziegel, Reihe für Reihe von hinten nach vorn
		var t := clampf((progress - 0.7) / 0.3, 0.0, 1.0)
		var rows := int(t * e.y * 2.0 / 8.0)
		for r in rows:
			var y := -e.y + r * 8.0
			draw_rect(Rect2(Vector2(-e.x, y), Vector2(e.x * 2.0, 8.0)), Color(0.86, 0.48, 0.32) if r % 2 == 0 else Color(0.80, 0.42, 0.28))
			draw_line(Vector2(-e.x, y + 8.0), Vector2(e.x, y + 8.0), Color(0.62, 0.30, 0.22), 1.0)
	var s := maxf(e.x, e.y) + 8.0
	var corners := [Vector2(-e.x - 8, -e.y - 8), Vector2(e.x + 8, -e.y - 8), Vector2(e.x + 8, e.y + 8), Vector2(-e.x - 8, e.y + 8)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		draw_line(a, b, INK, 5.0)
		draw_line(a, b, wood, 3.0)   # Bretter
		draw_line(a, (a + b) * 0.5 + (b - a).orthogonal().normalized() * 6.0, wood.darkened(0.2), 2.0)   # Strebe
	for a: Vector2 in corners:
		Disc.ring_dot(self, a, 4.0, wood.darkened(0.15), INK, 1.5)   # Pfosten
	draw_set_transform(Vector2.ZERO)
	var bar := Rect2(c + Vector2(-34, -s - 30), Vector2(68, 9))
	draw_rect(bar.grow(2.0), INK)
	draw_rect(bar, Color(0.20, 0.24, 0.22))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(0.55, 0.85, 0.40))


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col]), PackedVector2Array())
