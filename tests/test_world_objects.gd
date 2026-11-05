extends TestCase
## Objekte der Welt: immer gleich verteilt, nie auf Wegen oder Wasser, Start frei, Wegrand belegt,
## alle Baumarten da, Weiden am Wasser.


func _place() -> Array[Dictionary]:
	var g := GroundGrid.new(640, 480)
	var world := Game.load_json("res://data/regions/heimatdorf/world.json")
	WorldMap.build(g, world)
	var start := Vector2(320.5, 240.5) * 24.0
	return WorldObjects.place(g, 24.0, Game.load_json("res://data/regions/heimatdorf/objects.json"), world, [start])


func test_objects_placed_deterministically_on_land_with_room() -> void:
	var a := _place()
	var b := _place()
	assert_eq(a.size(), b.size(), "gleiche Verteilung bei jedem Start")
	assert_eq(a[5]["pos"], b[5]["pos"])
	var counts := {}
	for o in a:
		counts[o["kind"]] = int(counts.get(o["kind"], 0)) + 1
	for k in ["oak", "fir", "birch", "fruit", "willow", "sapling", "rock", "pond", "bush", "log", "fence", "stones"]:
		assert_true(int(counts.get(k, 0)) > 0, "keine Objekte der Art %s" % k)
	var start := Vector2(320.5, 240.5) * 24.0
	for i in a.size():
		assert_true(a[i]["pos"].distance_to(start) > 240.0, "Start bleibt frei")
		for j in range(i + 1, a.size()):
			var gap: float = a[i]["pos"].distance_to(a[j]["pos"]) - float(a[i]["block"]) - float(a[j]["block"])
			if float(a[i]["block"]) > 0.0 and float(a[j]["block"]) > 0.0:
				assert_true(gap > 70.0, "zwischen zwei Hindernissen passt der Roboter durch")


func test_willows_stand_near_water_and_sizes_vary() -> void:
	var g := GroundGrid.new(640, 480)
	WorldMap.build(g, Game.load_json("res://data/regions/heimatdorf/world.json"))
	var sizes := {}
	for o in _place():
		sizes[snappedf(float(o["size"]), 0.01)] = true
		if o["kind"] != "willow":
			continue
		var c := Vector2i(o["pos"] / 24.0)
		var wet := false
		for y in range(c.y - 14, c.y + 15):
			for x in range(c.x - 14, c.x + 15):
				if g.in_bounds(Vector2i(x, y)) and g.terrain[y * g.width + x] == GroundGrid.WATER:
					wet = true
		assert_true(wet, "Weide bei %s steht nicht am Wasser" % c)
	assert_true(sizes.size() > 20, "Objekte haben verschiedene Größen")
