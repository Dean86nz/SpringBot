extends TestCase
## Gärtner-Drohnen: Runden von außen nach innen über einem grauen Quadrat, zurück zur Station, Ruhe ohne Grau;
## Großstadt: Gebäude auf Land, nicht auf Straßen, Roboter passt zwischen ihnen durch.


func _drones(dock: Vector2) -> GardenDrones:
	var d := GardenDrones.new()
	d.configure({"speed_px": 900.0, "area_cells": 6, "spray_cells": 1.6, "charge_sec": 0.5, "range_cells": [10, 30]}, dock, 24.0)
	return d


func test_rounds_go_inward() -> void:
	var pts := GardenDrones.rounds(Vector2(100, 100), 60.0, 20.0)
	assert_eq(pts[pts.size() - 1], Vector2(100, 100), "endet in der Mitte")
	assert_eq(pts[0], Vector2(40, 40), "beginnt an der äußeren Ecke")
	assert_true(pts.size() >= 10, "mehrere Runden (%d Punkte)" % pts.size())


func test_drone_greens_squares_and_returns() -> void:
	var g := GroundGrid.new(120, 90)
	var dock := Vector2(60.5, 45.5) * 24.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var d := _drones(dock)
	d.set_count(1)
	var added := 0
	var charged := false
	for i in 60 * 30:
		added += d.update(1.0 / 60.0, g, rng)
		if added > 0 and d.drones[0].state == GardenDrones.State.CHARGE:
			charged = true
	assert_eq(added, g.green_count, "alles Grün kommt von der Drohne")
	assert_true(added > 400, "ganze Flächen begrünt (%d)" % added)
	assert_true(charged, "zwischendurch an der Station geladen")
	g.fill_except(Vector2(-100, -100), 1.0)
	for i in 60 * 20:
		d.update(1.0 / 60.0, g, rng)
	assert_true(d.drones[0].pos.distance_to(dock) < 12.0 * 24.0, "ohne Grau in der Nähe der Station")


func test_city_buildings_on_land_with_room() -> void:
	var r := Game.load_json("res://data/regions/stadt/region.json")
	var g := GroundGrid.new(int(r["width_cells"]), int(r["height_cells"]))
	WorldMap.build(g, Game.load_json("res://data/regions/stadt/world.json"))
	var list: Array = r["structures"]["list"]
	assert_true(list.size() > 300, "eine richtige Stadt (%d Gebäude)" % list.size())
	var bad := 0
	for b: Dictionary in list:
		var c := Vector2i(b["pos"][0], b["pos"][1])
		for o in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			if g.terrain[(c + o).y * g.width + (c + o).x] != GroundGrid.LAND:
				bad += 1
	assert_eq(bad, 0, "kein Gebäude auf Straße oder Wasser")
	var start := Vector2(r["start_cell"][0], r["start_cell"][1])
	assert_eq(g.terrain[int(start.y) * g.width + int(start.x)], GroundGrid.LAND, "Start auf Land")
	for k in ["hive_cell", "nest_cell", "dock_cell"]:
		var p: Array = r[k]
		assert_eq(g.terrain[int(p[1]) * g.width + int(p[0])], GroundGrid.LAND, "%s auf Land" % k)
	for i in list.size():
		for j in range(i + 1, mini(i + 12, list.size())):
			var d := Vector2(list[i]["pos"][0], list[i]["pos"][1]).distance_to(Vector2(list[j]["pos"][0], list[j]["pos"][1])) * 24.0
			if d < 400.0:
				assert_true(d - 72.0 * 1.1 * 2.0 > 64.0, "Roboter passt zwischen Gebäuden durch (%d px)" % int(d))
