extends TestCase
## Heimatdorf: Dorfplatz ist befestigt, alle Gebäude und Felder liegen auf Land und lassen dem Roboter
## Platz, Start und Bienenstock bleiben frei; die Bewohner kehren nach und nach zurück und arbeiten.

const DIR := "res://data/regions/heimatdorf/"


func _region() -> Dictionary:
	return Game.load_json(DIR + "region.json")


func _grid() -> GroundGrid:
	var g := GroundGrid.new(640, 480)
	WorldMap.build(g, Game.load_json(DIR + "world.json"))
	return g


## Alle Felder einer Kreisfläche (Zellen) sind Land?
func _land_circle(g: GroundGrid, c: Vector2, r: float) -> String:
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(0.5, 0.5)) > r:
				continue
			if g.terrain[y * g.width + x] != GroundGrid.LAND:
				return "%d,%d" % [x, y]
	return ""


func test_plaza_paved_and_buildings_on_land() -> void:
	var r := _region()
	var v: Dictionary = r["village"]
	var types: Dictionary = v["types"]
	var g := _grid()
	var c: Array = v["center"]
	assert_eq(g.terrain[int(c[1]) * g.width + int(c[0])], GroundGrid.PATH, "Dorfplatz ist befestigt (wird nicht grün)")
	var start := Vector2(r["start_cell"][0], r["start_cell"][1])
	var hive := Vector2(r["hive_cell"][0], r["hive_cell"][1])
	var all: Array = (v["buildings"] as Array) + (v["props"] as Array)
	assert_true((v["buildings"] as Array).size() >= 12, "ein richtiges Dorf")
	var kinds := {}
	for b: Dictionary in all:
		kinds[b["type"]] = true
		var p := Vector2(b["pos"][0], b["pos"][1])
		var t: Dictionary = types[b["type"]]
		var rad := float(t["radius"]) * 0.75 / 24.0   # Hauptfläche des Gebäudes
		var bad := _land_circle(g, p, rad)
		assert_eq(bad, "", "%s steht nicht ganz auf Land (bei %s)" % [b["id"], bad])
		var blk := float(t["block"]) / 24.0
		if blk > 0.0:
			assert_true(p.distance_to(start) * 24.0 > float(t["block"]) + 90.0, "%s: Start bleibt frei" % b["id"])
			assert_true(p.distance_to(hive) * 24.0 > float(t["block"]) + 32.0 + 64.0, "%s: Bienenstock bleibt erreichbar" % b["id"])
	for k in ["church", "school", "library", "shop", "smithy", "farmhouse", "barn", "stand", "field", "laundry", "cemetery", "house"]:
		assert_true(kinds.has(k), "es gibt %s" % k)
	var b_list: Array = v["buildings"]
	for i in b_list.size():
		var ti: Dictionary = types[b_list[i]["type"]]
		for j in range(i + 1, b_list.size()):
			var tj: Dictionary = types[b_list[j]["type"]]
			var d := Vector2(b_list[i]["pos"][0], b_list[i]["pos"][1]).distance_to(Vector2(b_list[j]["pos"][0], b_list[j]["pos"][1])) * 24.0
			var gap := d - float(ti["block"]) * 1.1 - float(tj["block"]) * 1.1
			assert_true(gap > 64.0, "zwischen %s und %s passt der Roboter durch (%d px)" % [b_list[i]["id"], b_list[j]["id"], int(gap)])
	for res: Dictionary in v["residents"]:
		var ids := {}
		for b: Dictionary in all:
			ids[b["id"]] = true
		assert_true(ids.has(res["home"]), "Bewohner wohnt in einem Gebäude, das es gibt: %s" % res["home"])
		if res.has("work"):
			assert_true(ids.has(res["work"]), "Arbeitsplatz gibt es: %s" % res["work"])


func test_village_objects_placed_first_and_others_keep_away() -> void:
	var g := _grid()
	var world := Game.load_json(DIR + "world.json")
	var fixed: Array[Dictionary] = [{"kind": "house", "pos": Vector2(300.5, 200.5) * 24.0, "angle": 0.0, "seed": 1,
		"block": 50.0, "radius": 76.0, "size": 1.0, "quiet": false}]
	var objs := WorldObjects.place(g, 24.0, Game.load_json(DIR + "objects.json"), world, [Vector2(320.5, 240.5) * 24.0], null, fixed)
	assert_eq(objs[0]["kind"], "house", "feste Objekte zuerst")
	for k in range(1, objs.size()):
		var d: float = objs[k]["pos"].distance_to(objs[0]["pos"])
		assert_true(d > 76.0 + float(objs[k]["radius"]), "nichts steht im Haus")


## Orte wie in main.gd (vereinfacht: Tür 60 px vor dem Gebäude).
func _places() -> Dictionary:
	var v: Dictionary = _region()["village"]
	var out := {}
	for b: Dictionary in (v["buildings"] as Array) + (v["props"] as Array):
		var pos := (Vector2(b["pos"][0], b["pos"][1]) + Vector2(0.5, 0.5)) * 24.0
		out[b["id"]] = {"pos": pos, "type": b["type"], "angle": 0.0, "door": pos + Vector2(0, 60)}
	return out


func test_residents_return_bit_by_bit_and_work() -> void:
	var v: Dictionary = _region()["village"]
	var hive := Vector2(314.5, 235.5) * 24.0
	var vil := Villagers.new(v, 24.0, _places(), hive, 4)
	var all_awake := func(_id: String) -> bool: return true
	var none_awake := func(_id: String) -> bool: return false
	assert_eq(vil.update_return(1.0, none_awake), 0, "ohne erwachtes Haus kommt niemand")
	var early := vil.update_return(0.2, all_awake)
	assert_true(early > 0 and vil.count_back() < vil.count_humans(), "bei 20 %% erst ein paar (%d)" % vil.count_back())
	for p in vil.people:
		if p.back and p.kind == Villagers.Kind.HUMAN:
			assert_true(p.arriving and p.pos.distance_to(vil.center) > vil.plaza_r * 2.0, "kommen zu Fuß von außerhalb")
	vil.update_return(1.0, all_awake)
	assert_eq(vil.count_back(), vil.count_humans(), "bei 100 % sind alle zurück")
	var pets := 0
	for p in vil.people:
		if p.kind != Villagers.Kind.HUMAN:
			pets += 1
			assert_true(p.back, "Haustiere kommen mit")
	assert_true(pets >= 2, "Hunde und Katzen")
	var max_wash := 0
	for i in 60 * 120:
		vil.update(1.0 / 60.0)
		for id in vil.laundry:
			max_wash = maxi(max_wash, int(vil.laundry[id]))
	for p in vil.people:
		assert_false(p.arriving, "alle sind angekommen")
	assert_true(max_wash >= 3, "Wäsche wird aufgehängt (%d)" % max_wash)
	assert_true(vil.jars > 0, "der Imker bringt Honig zum Stand")
	vil.set_festive(true)
	for i in 60 * 20:
		vil.update(1.0 / 60.0)
	for p in vil.people:
		if p.kind == Villagers.Kind.HUMAN:
			assert_true(p.pos.distance_to(vil.center) < vil.plaza_r * 1.1, "beim Fest alle auf dem Platz")
	vil.clear()
	assert_eq(vil.count_back(), 0, "Neues Spiel: alle wieder weg")


func test_loaded_save_residents_already_home() -> void:
	var vil := Villagers.new(_region()["village"], 24.0, _places(), Vector2.ZERO, 4)
	vil.update_return(1.0, func(_id: String) -> bool: return true, true)
	for p in vil.people:
		assert_false(p.arriving, "geladener Stand: niemand muss erst ankommen")


func test_residents_repair_buildings() -> void:
	var v: Dictionary = _region()["village"]
	var vil := Villagers.new(v, 24.0, _places(), Vector2(314.5, 235.5) * 24.0, 5)
	vil.ready = func(_id: String) -> bool: return true
	vil.obstacles.append({"pos": vil.center, "r": 46.0})   # Brunnen
	for id in vil.repair:
		assert_false(vil.is_done(id), "am Anfang ist alles kaputt")
	vil.update_return(1.0, func(_id: String) -> bool: return true)
	var done := {}
	var through_fountain := false
	for i in 60 * 240:
		vil.update(1.0 / 60.0)
		for id in vil.repaired:
			done[id] = true
		vil.repaired.clear()
		for p in vil.people:
			if p.kind == Villagers.Kind.HUMAN and p.pos.distance_to(vil.center) < 40.0:
				through_fountain = true
	assert_false(through_fountain, "niemand läuft durch den Brunnen")
	for id in vil.repair:
		assert_true(vil.is_done(id), "%s wurde repariert" % id)
	assert_eq(done.size(), vil.repair.size(), "jedes Gebäude meldet einmal „fertig“")
	var saved := vil.done_ids()
	var vil2 := Villagers.new(v, 24.0, _places(), Vector2.ZERO, 5)
	vil2.set_done(saved)
	for id in vil2.repair:
		assert_true(vil2.is_done(id), "Spielstand: repariert bleibt repariert")
