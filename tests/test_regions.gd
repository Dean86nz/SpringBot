extends TestCase
## Gebiete: jedes Gebiet hat Fläche, Start im Blumental, Grenzen immer gleich, Objekte folgen den
## Gewichten (Obstbäume im Obstgarten, Felsen auf dem Felsenhügel), Namenswechsel ohne Flackern.


func _regions() -> Regions:
	return Regions.new(640, 480, Game.load_json("res://data/regions.json"))


func test_every_region_has_room_and_start_is_meadow() -> void:
	var r := _regions()
	assert_true(r.list.size() >= 4 and r.list.size() <= 6, "4 bis 6 Gebiete")
	for i in r.list.size():
		assert_true(r.share(i) > 0.08, "%s ist zu klein (%.2f)" % [r.name_of(i), r.share(i)])
		assert_false(r.name_of(i).is_empty())
	assert_eq(r.name_of(r.at_cell(Vector2(320, 240))), "Blumental", "Start im Blumental")
	var again := _regions()
	assert_eq(r.index, again.index, "Grenzen bei jedem Start gleich")
	assert_eq(r.at_cell(Vector2(-50, 9999)), r.at_cell(Vector2(0, 479)), "außerhalb: nächster Rand")


func test_objects_follow_region_weights() -> void:
	var g := GroundGrid.new(640, 480)
	var world := Game.load_json("res://data/world.json")
	WorldMap.build(g, world)
	var r := _regions()
	var objs := WorldObjects.place(g, 24.0, Game.load_json("res://data/objects.json"), world, [Vector2(320.5, 240.5) * 24.0], r)
	var by := {}   # "Gebiet/Art" -> Anzahl
	for o in objs:
		var key := "%s/%s" % [r.name_of(r.at_px(o["pos"], 24.0)), o["kind"]]
		by[key] = int(by.get(key, 0)) + 1
	var per_area := func(region: String, kind: String) -> float:
		for i in r.list.size():
			if r.name_of(i) == region:
				return int(by.get("%s/%s" % [region, kind], 0)) / r.share(i)
		return 0.0
	assert_true(per_area.call("Obstgarten", "fruit") > 3.0 * per_area.call("Blumental", "fruit"), "Obstbäume im Obstgarten")
	assert_true(per_area.call("Felsenhügel", "rock") > 3.0 * per_area.call("Blumental", "rock"), "Felsen auf dem Hügel")
	assert_true(per_area.call("Stiller Wald", "oak") > 3.0 * per_area.call("Blumental", "oak"), "Laubbäume im Wald")
	assert_true(per_area.call("Seenland", "pond") > 2.0 * per_area.call("Stiller Wald", "pond"), "Teiche im Seenland")
	assert_true(objs.size() > 360, "fast alle Objekte finden Platz (%d)" % objs.size())


func test_watch_switches_only_after_staying() -> void:
	var w := Regions.Watch.new()
	w.confirm_sec = 1.0
	assert_true(w.update(2, 0.1), "erstes Gebiet sofort zeigen")
	assert_false(w.update(2, 0.1))
	assert_false(w.update(3, 0.5), "kurz über die Grenze: noch nicht")
	assert_false(w.update(2, 0.1), "zurück: kein Wechsel")
	assert_false(w.update(3, 0.6))
	assert_false(w.update(3, 0.3))
	assert_true(w.update(3, 0.2), "lange genug im neuen Gebiet")
	assert_eq(w.current, 3)
	w.reset()
	assert_true(w.update(3, 0.0), "nach dem Titel wieder zeigen")
