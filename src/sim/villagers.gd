class_name Villagers
extends RefCounted
## Die Bewohner des Dorfes (Phase 3). Jeder hat ein Zuhause und eine Arbeit (region.json „residents“):
## Schmied am Amboss, Bauern auf dem Feld, Ladenbesitzer, Wäsche an der Leine, Imker zwischen Bienenstock
## und Honigstand, Kinder, die auf dem Platz spielen, jemand liest auf der Bank, andere schlendern.
## Manche haben einen Hund oder eine Katze.
## Sie kehren nach und nach zurück: sobald um ihr Haus Grün ist (ready) und der Frühling ihren Wert "from"
## erreicht hat. Sie kommen zu Fuß von außerhalb des Dorfes. Die Gebäude sind kaputt, bis die Bewohner sie
## reparieren (repair): zuerst das eigene Haus, dann die Arbeitsstelle (Bauern das Feld), dann helfen sie
## dort, wo noch etwas kaputt ist (höchstens zwei an einem Gebäude). Fertige Gebäude stehen in "repaired",
## main.gd lässt sie erwachen. Beim Fest (100 %) treffen sich alle auf dem Platz.
## Hindernisse (obstacles: Gebäude, Brunnen, Bienenstock) umgehen sie, statt hindurchzulaufen.
## Reine Deko und Logik in Weltpixeln; gezeichnet von VillagerView.

enum Kind { HUMAN, DOG, CAT }

class Person:
	var kind := Kind.HUMAN
	var job := "stroll"
	var home := ""
	var work := ""
	var from := 0.0        # ab diesem Frühlings-Anteil kommt die Person zurück
	var back := false      # schon zurück
	var arriving := false  # noch auf dem Weg ins Dorf
	var owner := -1        # Haustier: Index des Menschen
	var pos := Vector2.ZERO
	var target := Vector2.ZERO
	var delay := 0.0
	var wait := 0.0
	var look := 0
	var phase := 0.0       # Schritt-Animation
	var act := 0.0         # Arbeits-Animation (Hammer, Hacke, Umblättern …)
	var dir := 0.0
	var state := 0         # Schritt im Ablauf der Arbeit
	var carry := false     # trägt etwas (Honigglas, Wäschekorb)
	var sitting := false
	var slot := 0
	var fix := ""          # Gebäude, das die Person gerade repariert
	var check := 0.0       # Sekunden bis zur nächsten Suche nach Arbeit am Bau


var people: Array[Person] = []
var places: Dictionary = {}    # id → {pos, door, type, angle}
var center := Vector2.ZERO     # Dorfplatz
var plaza_r := 200.0
var hive := Vector2.ZERO
var speed := 85.0
var wait_sec := Vector2(1.5, 5.0)
var arrive_from := 500.0
var festive := false
var laundry: Dictionary = {}   # Wäscheleinen-id → Zahl der hängenden Stücke (0..LINE_SLOTS)
var jars := 0                  # Honiggläser auf dem Stand
var ball := Vector2.ZERO       # Ball der Kinder
var repair: Dictionary = {}    # Gebäude-id → Fortschritt 0..1 (1 = repariert)
var repaired: Array[String] = []   # seit dem letzten Abholen fertig geworden (main.gd lässt sie erwachen)
var ready := Callable()        # func(id) -> bool: Grün um das Gebäude, es kann repariert werden
var repair_sec := 12.0
var obstacles: Array[Dictionary] = []   # {pos, r}: Gebäude, Brunnen, Bienenstock
var _ball_target := Vector2.ZERO
var _rng := RandomNumberGenerator.new()

const LINE_SLOTS := 6
const MAX_JARS := 6


## cfg: "village" aus region.json; places: Gebäude und Requisiten mit Lage; hive_px: Bienenstock.
func _init(cfg: Dictionary = {}, cell_px: float = 24.0, p_places: Dictionary = {}, hive_px: Vector2 = Vector2.ZERO, rng_seed: int = 3) -> void:
	_rng.seed = rng_seed
	var c: Array = cfg.get("center", [0, 0])
	center = (Vector2(c[0], c[1]) + Vector2(0.5, 0.5)) * cell_px
	plaza_r = float(cfg.get("plaza_radius", 8.0)) * cell_px
	places = p_places
	hive = hive_px
	speed = float(cfg.get("people_speed_px", 85.0))
	var ws: Array = cfg.get("wait_sec", [1.5, 5.0])
	wait_sec = Vector2(ws[0], ws[1])
	arrive_from = float(cfg.get("arrive_from_cells", 22.0)) * cell_px
	repair_sec = float(cfg.get("repair_sec", 12.0))
	ball = center + Vector2(0, plaza_r * 0.6)
	_ball_target = ball
	for r: Dictionary in cfg.get("residents", []):
		var p := Person.new()
		p.job = str(r.get("job", "stroll"))
		p.home = str(r.get("home", ""))
		p.work = str(r.get("work", ""))
		p.from = float(r.get("from", 0.0))
		p.look = _rng.randi() % 64
		p.phase = _rng.randf() * TAU
		people.append(p)
		var owner := people.size() - 1
		for pet in ["dog", "cat"]:
			if bool(r.get(pet, false)):
				var a := Person.new()
				a.kind = Kind.DOG if pet == "dog" else Kind.CAT
				a.job = pet
				a.home = p.home
				a.owner = owner
				a.from = p.from
				a.look = _rng.randi() % 64
				people.append(a)
	for id: String in places:
		if places[id]["type"] == "laundry":
			laundry[id] = 0
		repair[id] = 0.0


func is_done(id: String) -> bool:
	return float(repair.get(id, 1.0)) >= 1.0


## Gebäude, die schon repariert sind (für den Spielstand).
func done_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in repair:
		if float(repair[id]) >= 1.0:
			out.append(id)
	return out


## Spielstand: diese Gebäude sind schon repariert.
func set_done(ids: Array) -> void:
	for id in ids:
		if repair.has(str(id)):
			repair[str(id)] = 1.0


func clear() -> void:
	for p in people:
		p.back = false
		p.arriving = false
		p.wait = 0.0
		p.state = 0
		p.carry = false
	festive = false
	jars = 0
	for id in laundry:
		laundry[id] = 0
	for id in repair:
		repair[id] = 0.0
	repaired.clear()


## Wer jetzt zurückkommen darf, macht sich auf den Weg ins Dorf. green(id) sagt, ob um das Haus Grün ist.
## instant: gleich an Ort und Stelle (Spielstand geladen). Gibt die Zahl der Neuankömmlinge zurück.
func update_return(coverage: float, green: Callable, instant: bool = false) -> int:
	var n := 0
	for i in people.size():
		var p := people[i]
		if p.back:
			continue
		if p.owner >= 0:
			if not people[p.owner].back:
				continue
		elif coverage < p.from or not green.call(p.home):
			continue
		p.back = true
		n += 1
		var home := _place_pos(p.home)
		if instant:
			p.pos = _job_spot(p) if p.owner < 0 else people[p.owner].pos + Vector2(30, 20)
			p.target = p.pos
			p.wait = _rng.randf_range(0.0, wait_sec.y)
		elif p.owner >= 0:
			p.pos = people[p.owner].pos + Vector2(-26, 18)
			p.target = p.pos
		else:
			var d := (home - center).normalized().rotated(_rng.randf_range(-0.5, 0.5))
			p.pos = center + d * (arrive_from + home.distance_to(center))
			p.arriving = true
			p.target = center if festive else _job_spot(p)
			p.delay = _rng.randf() * 1.5
	return n


func count_back() -> int:
	var n := 0
	for p in people:
		if p.back and p.kind == Kind.HUMAN:
			n += 1
	return n


func count_humans() -> int:
	var n := 0
	for p in people:
		if p.kind == Kind.HUMAN:
			n += 1
	return n


## Fest an (alle auf den Platz, sie hüpfen vor Freude) oder aus (zurück an die Arbeit).
func set_festive(on: bool) -> void:
	festive = on
	for p in people:
		if not p.back:
			continue
		p.state = 0
		p.wait = 0.0
		p.sitting = false
		p.carry = false
		if p.kind == Kind.HUMAN:
			p.target = _plaza_spot() if on else _job_spot(p)


func update(delta: float) -> void:
	_update_ball(delta)
	for p in people:
		if not p.back:
			continue
		if p.delay > 0.0:
			p.delay -= delta
			continue
		p.act += delta
		if p.arriving:
			if _walk(p, delta, speed):
				p.arriving = false
			continue
		if p.kind != Kind.HUMAN:
			_pet(p, delta)
		elif festive:
			_celebrate(p, delta)
		elif _rebuild(p, delta):
			pass
		else:
			match p.job:
				"smith": _stay_and_work(p, delta, 22.0)
				"shop": _stay_and_work(p, delta, 16.0)
				"read": _read(p, delta)
				"farmer":
					if is_done(p.work):
						_farm(p, delta)
					else:
						_stroll(p, delta)
				"laundry":
					if is_done(p.work):
						_laundry(p, delta)
					else:
						_stroll(p, delta)
				"beekeeper": _beekeeper(p, delta)
				"kid": _play(p, delta)
				_: _stroll(p, delta)


# --- Wiederaufbau ---

## Repariert die Person gerade etwas (oder macht sich auf den Weg dahin)? Dann true, sonst ihre Arbeit.
func _rebuild(p: Person, delta: float) -> bool:
	if p.fix == "":
		p.check -= delta
		if p.check > 0.0:
			return false
		p.check = 1.0
		p.fix = _pick_repair(p)
		if p.fix == "":
			return false
		var pl: Dictionary = places[p.fix]
		p.target = pl["pos"] + Vector2.from_angle(_rng.randf() * TAU) * (_size(p.fix) + 20.0)
		p.state = 0
	if is_done(p.fix):
		p.fix = ""
		p.state = 0
		return false
	if not _walk(p, delta, speed):
		return true
	p.dir = (places[p.fix]["pos"] - p.pos).angle()
	p.wait = 0.0
	repair[p.fix] = minf(float(repair[p.fix]) + delta / repair_sec, 1.0)
	if float(repair[p.fix]) >= 1.0:
		repaired.append(p.fix)
		p.fix = ""
	return true


## Was soll die Person reparieren? Eigenes Haus, dann Arbeitsstelle, dann das nächste kaputte Gebäude
## mit Grün drumherum, an dem noch keine zwei arbeiten. "" = nichts zu tun.
func _pick_repair(p: Person) -> String:
	for id in [p.home, p.work]:
		if id != "" and repair.has(id) and not is_done(id) and _can_fix(id):
			return id
	var best := ""
	var best_d := INF
	for id: String in repair:
		if is_done(id) or not _can_fix(id) or _workers(id) >= 2:
			continue
		var d := p.pos.distance_squared_to(places[id]["pos"])
		if d < best_d:
			best_d = d
			best = id
	return best


func _can_fix(id: String) -> bool:
	return not ready.is_valid() or ready.call(id)


func _workers(id: String) -> int:
	var n := 0
	for p in people:
		if p.fix == id:
			n += 1
	return n


func _size(id: String) -> float:
	return float(places[id].get("block", 40.0)) if float(places[id].get("block", 0.0)) > 0.0 else float(places[id].get("radius", 60.0)) * 0.7


# --- Arbeiten ---

## Ein Schritt zum Ziel; Hindernissen weicht die Person aus, indem sie an ihrem Rand entlanggeht.
func _walk(p: Person, delta: float, spd: float) -> bool:
	for o in obstacles:   # Ziel im Hindernis (Ball am Brunnen …): an seinen Rand legen
		var oc: Vector2 = o["pos"]
		var orr := float(o["r"]) + 10.0
		if p.target.distance_to(oc) < orr:
			var away := p.target - oc if p.target != oc else Vector2.DOWN
			p.target = oc + away.normalized() * orr
	var to := p.target - p.pos
	var step := spd * delta
	if to.length() <= step:
		p.pos = p.target
		return true
	var next := p.pos + to.normalized() * step
	for o in obstacles:
		var c: Vector2 = o["pos"]
		var r := float(o["r"]) + 8.0
		if next.distance_to(c) < r:
			var t := (p.pos - c).normalized().orthogonal()
			if t.dot(to) < 0.0:
				t = -t
			next = p.pos + t * step
			if next.distance_to(c) < r:
				next = c + (next - c).normalized() * r
			break
	p.dir = (next - p.pos).angle()
	p.pos = next
	p.phase += delta * spd / 9.0
	return false


## Am Arbeitsplatz stehen und arbeiten; alle paar Male ein kurzer Gang über den Platz und zurück.
func _stay_and_work(p: Person, delta: float, break_every: float) -> void:
	match p.state:
		0:   # zur Arbeit
			p.target = _job_spot(p)
			if _walk(p, delta, speed):
				p.state = 1
				p.wait = _rng.randf_range(break_every * 0.6, break_every * 1.4)
				p.dir = _work_dir(p)
		1:   # arbeiten
			p.wait -= delta
			if p.wait <= 0.0:
				p.state = 2
				p.target = _plaza_spot()
		2:   # Pause: kurz zum Platz
			if _walk(p, delta, speed * 0.8):
				p.state = 3
				p.wait = _rng.randf_range(wait_sec.x, wait_sec.y)
		3:
			p.wait -= delta
			if p.wait <= 0.0:
				p.state = 0


func _read(p: Person, delta: float) -> void:
	if p.state == 0:
		p.target = _job_spot(p)
		if _walk(p, delta, speed * 0.8):
			p.state = 1
			p.sitting = true
			p.dir = _work_dir(p)


## Bauer: geht langsam die Ackerreihen entlang und hackt.
func _farm(p: Person, delta: float) -> void:
	var f: Dictionary = places.get(p.work, {})
	if f.is_empty():
		_stroll(p, delta)
		return
	if p.wait > 0.0:
		p.wait -= delta
		return
	if _walk(p, delta, speed * 0.45):
		var rows := 8
		var row := p.slot % rows
		var along := -90.0 if (p.slot / rows) % 2 == 0 else 90.0
		p.slot += 1
		p.target = f["pos"] + Vector2(along * (1.0 if row % 2 == 0 else -1.0), -56.0 + row * 16.0 - 4.0)
		p.wait = _rng.randf_range(0.8, 2.0)   # hacken


## Wäsche: Stück für Stück aufhängen, dann eine Weile trocknen lassen, abnehmen, von vorn.
func _laundry(p: Person, delta: float) -> void:
	var l: Dictionary = places.get(p.work, {})
	if l.is_empty():
		_stroll(p, delta)
		return
	var line_pos: Vector2 = l["pos"]
	if p.wait > 0.0:
		p.wait -= delta
		return
	match p.state:
		0:   # Korb holen
			p.target = line_pos + Vector2(-80, 30)
			if _walk(p, delta, speed * 0.8):
				p.carry = true
				p.state = 1
				p.slot = 0
		1:   # zum nächsten Platz an der Leine
			p.target = line_pos + Vector2(-50 + p.slot * 20.0, 16)
			if _walk(p, delta, speed * 0.6):
				p.dir = -PI / 2.0
				p.wait = 1.4
				p.state = 2
		2:   # aufgehängt
			laundry[p.work] = mini(int(laundry[p.work]) + 1, LINE_SLOTS)
			p.slot += 1
			p.state = 1 if p.slot < LINE_SLOTS else 3
			if p.state == 3:
				p.carry = false
				p.target = _plaza_spot()
		3:   # während die Wäsche trocknet: auf dem Platz
			if _walk(p, delta, speed * 0.7):
				p.wait = _rng.randf_range(25.0, 40.0)
				p.state = 5
		5:   # zurück zur Leine und abnehmen
			p.target = line_pos + Vector2(-50 + (int(laundry[p.work]) - 1) * 20.0, 16)
			p.carry = true
			p.state = 4
		4:
			if _walk(p, delta, speed * 0.6):
				laundry[p.work] = maxi(int(laundry[p.work]) - 1, 0)
				p.wait = 0.8
				if int(laundry[p.work]) == 0:
					p.state = 0
					p.carry = false
					p.wait = 4.0
				else:
					p.target = line_pos + Vector2(-50 + (int(laundry[p.work]) - 1) * 20.0, 16)


## Imker: vom Stand zum Bienenstock, Honig holen, zurück zum Stand, ein Glas mehr auf dem Tisch.
func _beekeeper(p: Person, delta: float) -> void:
	if p.wait > 0.0:
		p.wait -= delta
		return
	match p.state:
		0:   # zum Bienenstock
			p.target = hive + Vector2(0, 44)
			if _walk(p, delta, speed * 0.7):
				p.dir = -PI / 2.0
				p.wait = _rng.randf_range(4.0, 6.0)
				p.state = 1
		1:
			p.carry = true
			p.state = 2
		2:   # mit Honig zurück zum Stand
			p.target = _job_spot(p)
			if _walk(p, delta, speed * 0.7):
				p.carry = false
				jars = mini(jars + 1, MAX_JARS)
				p.wait = _rng.randf_range(6.0, 10.0)
				p.state = 0
				if jars >= MAX_JARS:
					jars = MAX_JARS - 3   # Gläser verkauft


## Kinder: rennen auf dem Platz herum und jagen dem Ball nach.
func _play(p: Person, delta: float) -> void:
	if p.wait > 0.0:
		p.wait -= delta
		return
	if _walk(p, delta, speed * 1.6):
		p.wait = _rng.randf_range(0.2, 1.2)
		p.target = ball + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(20, 70) if _rng.randf() < 0.6 else _plaza_spot()


func _update_ball(delta: float) -> void:
	var to := _ball_target - ball
	var step := 230.0 * delta
	if to.length() <= step:
		ball = _ball_target
		var kids: Array[Person] = []
		for p in people:
			if p.back and p.job == "kid" and not p.arriving:
				kids.append(p)
		_ball_target = kids[_rng.randi() % kids.size()].pos if not kids.is_empty() else center + Vector2(0, plaza_r * 0.5)
	else:
		ball += to.normalized() * step


func _stroll(p: Person, delta: float) -> void:
	if p.wait > 0.0:
		p.wait -= delta
		return
	if _walk(p, delta, speed * 0.75):
		p.wait = _rng.randf_range(wait_sec.x, wait_sec.y)
		var r := _rng.randf()
		if r < 0.45:
			p.target = _plaza_spot()
		else:
			var ids := places.keys()
			var id: String = ids[_rng.randi() % ids.size()]
			p.target = places[id]["door"]


func _celebrate(p: Person, delta: float) -> void:
	if p.wait > 0.0:
		p.wait -= delta
		return
	if _walk(p, delta, speed):
		p.wait = _rng.randf_range(1.0, 3.0)   # hüpft (VillagerView), dann zum nächsten Platz
		p.target = _plaza_spot()


## Hund folgt seinem Menschen (rennt mit Kindern), Katze sitzt lange vor einem Haus und wechselt selten.
func _pet(p: Person, delta: float) -> void:
	var o := people[p.owner]
	if p.kind == Kind.DOG:
		var want := o.pos + Vector2.from_angle(o.dir + PI * 0.75) * 34.0
		if festive or o.job == "kid":
			want = o.pos + Vector2.from_angle(p.act * 1.3) * 50.0
		p.target = want
		if p.pos.distance_to(want) > 12.0:
			_walk(p, delta, speed * (1.8 if p.pos.distance_to(want) > 80.0 else 1.1))
		return
	if p.wait > 0.0:
		p.wait -= delta
		p.sitting = true
		return
	p.sitting = false
	if _walk(p, delta, speed * 0.5):
		p.wait = _rng.randf_range(12.0, 30.0)
		var ids := places.keys()
		var id: String = ids[_rng.randi() % ids.size()]
		p.target = places[id]["door"] + Vector2(_rng.randf_range(-30, 30), 8)


# --- Orte ---

func _place_pos(id: String) -> Vector2:
	return places[id]["pos"] if places.has(id) else center


## Wo die Person ihre Arbeit tut (im Weltmaß, aus der Lage des Gebäudes).
func _job_spot(p: Person) -> Vector2:
	var pl: Dictionary = places.get(p.home, {})
	if pl.is_empty():
		return _plaza_spot()
	var rot := float(pl.get("angle", 0.0))
	var local := Vector2.ZERO
	match p.job:
		"smith": local = Vector2(22, 76)
		"shop": local = Vector2(58, 62)
		"read": local = Vector2(-23, 50)
		"beekeeper": local = Vector2(0, 30)
		"farmer":
			var f: Dictionary = places.get(p.work, {})
			return f["pos"] + Vector2(-90, -60) if not f.is_empty() else _plaza_spot()
		"laundry":
			var l: Dictionary = places.get(p.work, {})
			return l["pos"] + Vector2(-80, 30) if not l.is_empty() else _plaza_spot()
		"kid": return _plaza_spot()
		_: return pl["door"]
	return pl["pos"] + local.rotated(rot)


## Blickrichtung bei der Arbeit (zum Amboss, zur Ladentür …).
func _work_dir(p: Person) -> float:
	var pl: Dictionary = places.get(p.home, {})
	var rot := float(pl.get("angle", 0.0))
	match p.job:
		"smith": return rot - PI / 2.0   # zum Amboss (lokal −y)
		"read": return rot + PI / 2.0
	return rot + PI / 2.0


func _plaza_spot() -> Vector2:
	return center + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.4, 0.85) * plaza_r
