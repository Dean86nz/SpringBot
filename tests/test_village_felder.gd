extends TestCase
## Felder und Vorort: Vorplatz befestigt, Gebäude, Felder und Gärten auf Land, der Roboter passt überall
## durch, Start, Bienenstock und Vogelhäuschen bleiben frei. Wer auf den fernen Höfen wohnt, trifft sich
## auf dem eigenen Hof und hilft nur in der Nähe; am Ende ist alles repariert.

const DIR := "res://data/regions/felder/"


func _region() -> Dictionary:
	return Game.load_json(DIR + "region.json")


func _grid() -> GroundGrid:
	var r := _region()
	var g := GroundGrid.new(int(r["width_cells"]), int(r["height_cells"]))
	WorldMap.build(g, Game.load_json(DIR + "world.json"))
	return g


func _cell(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func test_layout() -> void:
	var r := _region()
	var v: Dictionary = r["village"]
	var types: Dictionary = v["types"]
	var g := _grid()
	var c: Array = v["center"]
	assert_eq(g.terrain[int(c[1]) * g.width + int(c[0])], GroundGrid.PATH, "Vorplatz ist befestigt")
	var keep := [_cell(r["start_cell"]), _cell(r["hive_cell"]), _cell(r["nest_cell"])]
	var all: Array = (v["buildings"] as Array) + (v["props"] as Array)
	var kinds := {}
	var ids := {}
	for b: Dictionary in all:
		kinds[b["type"]] = true
		ids[b["id"]] = true
		var p := _cell(b["pos"])
		var t: Dictionary = types[b["type"]]
		var sz: Array = t.get("size", [1.0, 1.0])
		var rad := float(t["radius"]) * float(sz[1]) * 0.75 / 24.0
		for y in range(int(p.y - rad), int(p.y + rad) + 1):
			for x in range(int(p.x - rad), int(p.x + rad) + 1):
				if Vector2(x, y).distance_to(p) <= rad:
					assert_eq(g.terrain[y * g.width + x], GroundGrid.LAND, "%s steht ganz auf Land (%d,%d)" % [b["id"], x, y])
		var blk := float(t["block"]) * float(sz[1])
		if blk > 0.0:
			for k in keep:
				assert_true(p.distance_to(k) * 24.0 > blk + 100.0, "%s: Start, Bienenstock und Häuschen bleiben frei" % b["id"])
	for k in ["suburb", "bakery", "kita", "manor", "machine_hall", "silo", "windmill", "wheat", "garden", "laundry"]:
		assert_true(kinds.has(k), "es gibt %s" % k)
	var bl: Array = v["buildings"]
	for i in bl.size():
		var ti: Dictionary = types[bl[i]["type"]]
		for j in range(i + 1, bl.size()):
			var tj: Dictionary = types[bl[j]["type"]]
			var d := _cell(bl[i]["pos"]).distance_to(_cell(bl[j]["pos"])) * 24.0
			var gap := d - float(ti["block"]) * 1.3 - float(tj["block"]) * 1.3
			assert_true(gap > 64.0, "zwischen %s und %s passt der Roboter durch (%d px)" % [bl[i]["id"], bl[j]["id"], int(gap)])
	for res: Dictionary in v["residents"]:
		assert_true(ids.has(res["home"]), "Zuhause gibt es: %s" % res["home"])
		if res.has("work"):
			assert_true(ids.has(res["work"]), "Arbeit gibt es: %s" % res["work"])


## Orte wie in main.gd (vereinfacht: Tür 60 px vor dem Gebäude, Größe 1).
func _places() -> Dictionary:
	var v: Dictionary = _region()["village"]
	var out := {}
	for b: Dictionary in (v["buildings"] as Array) + (v["props"] as Array):
		var pos := (_cell(b["pos"]) + Vector2(0.5, 0.5)) * 24.0
		var t: Dictionary = v["types"][b["type"]]
		out[b["id"]] = {"pos": pos, "type": b["type"], "angle": 0.0, "door": pos + Vector2(0, 60), "block": float(t["block"]), "radius": float(t["radius"]), "size": 1.0}
	return out


func test_farm_people_stay_on_their_farm_and_everything_gets_repaired() -> void:
	var v: Dictionary = _region()["village"]
	var vil := Villagers.new(v, 24.0, _places(), Vector2(393.5, 324.5) * 24.0, 7)
	var far := 0
	for p in vil.people:
		if p.kind != Villagers.Kind.HUMAN:
			continue
		var home: Vector2 = vil.places[p.home]["pos"]
		if home.distance_to(vil.center) > vil.hub_dist:
			far += 1
			assert_true(p.hub.distance_to(home) < 300.0, "%s trifft sich auf dem eigenen Hof" % p.home)
		else:
			assert_eq(p.hub, vil.center, "%s trifft sich auf dem Vorplatz" % p.home)
	assert_true(far >= 6, "Höfe draußen mit eigenen Leuten (%d)" % far)
	vil.update_return(1.0, func(_id: String) -> bool: return true)
	var max_off := 0.0
	for i in 60 * 600:
		vil.update(1.0 / 60.0)
		if i % 30 == 0:
			for p in vil.people:
				if p.kind == Villagers.Kind.HUMAN and not p.arriving and p.job != "hike":
					max_off = maxf(max_off, p.pos.distance_to(p.hub))
	assert_true(max_off < vil.local_dist + 300.0, "niemand läuft quer über die Karte (%d px)" % int(max_off))
	var left: Array[String] = []
	for id: String in vil.repair:
		if not vil.is_done(id):
			left.append(id)
	assert_eq(left.size(), 0, "nach zehn Minuten ist alles repariert, offen: %s" % ", ".join(left))
	vil.set_festive(true)
	for i in 60 * 30:
		vil.update(1.0 / 60.0)
	for p in vil.people:
		if p.kind == Villagers.Kind.HUMAN:
			assert_true(p.pos.distance_to(p.hub) < p.hub_r * 1.1, "Fest am eigenen Treffpunkt (%s)" % p.home)
