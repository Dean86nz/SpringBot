extends TestCase
## Heimatdorf: Dorfplatz ist befestigt und erreichbar, Häuser stehen auf Land und lassen dem Roboter
## Platz, Start und Bienenstock bleiben frei; die Menschen kehren zum Platz zurück.

const DIR := "res://data/regions/heimatdorf/"


func _region() -> Dictionary:
	return Game.load_json(DIR + "region.json")


func _grid() -> GroundGrid:
	var g := GroundGrid.new(640, 480)
	WorldMap.build(g, Game.load_json(DIR + "world.json"))
	return g


func test_plaza_paved_and_houses_on_land() -> void:
	var r := _region()
	var v: Dictionary = r["village"]
	var g := _grid()
	var c: Array = v["center"]
	assert_eq(g.terrain[int(c[1]) * g.width + int(c[0])], GroundGrid.PATH, "Dorfplatz ist befestigt (wird nicht grün)")
	var start := Vector2(r["start_cell"][0], r["start_cell"][1])
	var hive := Vector2(r["hive_cell"][0], r["hive_cell"][1])
	var houses: Array = v["houses"]
	assert_true(houses.size() >= 8, "ein richtiges Dorf")
	for i in houses.size():
		var h := Vector2(houses[i][0], houses[i][1])
		# Hausfläche (gut 2 Zellen in jede Richtung) liegt ganz auf Land
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var q := Vector2i(h) + Vector2i(dx, dy)
				assert_eq(g.terrain[q.y * g.width + q.x], GroundGrid.LAND, "Haus %d steht nicht auf Land bei %s" % [i, q])
		assert_true(h.distance_to(start) > 8.0, "Start bleibt frei")
		assert_true(h.distance_to(hive) > 5.0, "Bienenstock bleibt frei")
		for j in range(i + 1, houses.size()):
			# zwei Hindernisse à 50 px (max. Größe 1.1) plus Durchfahrt für den Roboter (Durchmesser 60 px)
			var gap := h.distance_to(Vector2(houses[j][0], houses[j][1])) * 24.0 - 2.0 * 55.0
			assert_true(gap > 64.0, "zwischen Haus %d und %d passt der Roboter durch" % [i, j])


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


func test_people_return_to_plaza() -> void:
	var v: Dictionary = _region()["village"]
	var doors: Array[Vector2] = [Vector2(300, 200) * 24.0, Vector2(310, 195) * 24.0]
	var vil := Villagers.new(v, 24.0, doors, 9)
	vil.arrive(10)
	assert_eq(vil.people.size(), 10)
	assert_eq(vil.count_arrived(), 0, "am Anfang noch draußen")
	for p in vil.people:
		assert_true(p.pos.distance_to(vil.center) > vil.plaza_r * 1.5, "kommen von außerhalb des Platzes")
	for i in 60 * 20:
		vil.update(1.0 / 60.0)
	assert_eq(vil.count_arrived(), 10, "nach 20 s sind alle angekommen")
	for p in vil.people:
		assert_true(p.pos.distance_to(vil.center) < vil.plaza_r * 3.0, "bleiben im Dorf")
	vil.settle(6)
	assert_eq(vil.people.size(), 6)
	assert_eq(vil.count_arrived(), 6, "geladener Stand: schon da")
	vil.clear()
	assert_true(vil.people.is_empty())
