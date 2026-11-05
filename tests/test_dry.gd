extends TestCase
## Dürre Stellen: keine Ausbreitung, keine Bienen-Blüten, aber Roboter und Samenvögel begrünen sie;
## Sonnenblumen der Vögel im Spielstand; alter Spielstand-Ordner wird übernommen.


func _grid() -> GroundGrid:
	var g := GroundGrid.new(60, 40)
	WorldMap.build_dry(g, {"seed": 2, "wobble": 0.0, "patches": [[40, 20, 8]]})
	return g


func test_dry_patch_built_on_land() -> void:
	var g := _grid()
	assert_true(g.is_dry(Vector2i(40, 20)), "Mitte ist dürr")
	assert_false(g.is_dry(Vector2i(10, 20)), "weit weg nicht")
	var n := g.dry.count(1)
	assert_true(n > 150 and n < 260, "etwa ein Kreis mit Radius 8 (%d)" % n)


func test_spread_and_bees_stop_at_dry_ground() -> void:
	var g := _grid()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	g.paint_circle(Vector2(24, 20), 3.0)   # Roboter neben der dürren Stelle
	for i in 400:
		g.spread(100, 4.0, 0.3, rng)
	for i in g.cells.size():
		if g.dry[i] != 0:
			assert_eq(g.cells[i], GroundGrid.GREY, "Ausbreitung wächst nicht in die dürre Stelle")
	assert_eq(g.paint_circle(Vector2(40, 20), 3.0, true), 0, "Bienen-Blüte auf dürrem Boden: nichts")
	assert_false(g.is_open(Vector2i(40, 20), false), "für Bienen kein Ziel")
	assert_true(g.paint_circle(Vector2(40, 20), 3.0) > 0, "der Roboter begrünt sie")


func test_birds_prefer_dry_and_plant_sunflowers() -> void:
	var g := _grid()
	var b := SeedBirds.new()
	b.configure({"speed_px": 600.0, "strip_cells": 20, "width_cells": 1.5, "rest_sec": 0.3, "range_cells": [5, 20], "trips_home": 3, "target_tries": 30}, Vector2(20.5, 20.5) * 24.0, 24.0)
	b.set_count(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var dry_green := 0
	for i in 60 * 15:
		b.update(1.0 / 60.0, g, rng)
	for i in g.cells.size():
		if g.dry[i] != 0 and g.cells[i] == GroundGrid.GREEN:
			dry_green += 1
	assert_true(dry_green > 60, "Vögel begrünen dürren Boden (%d)" % dry_green)
	assert_true(g.sown.count(1) > 5, "Sonnenblumen-Reihen (%d)" % g.sown.count(1))
	var g2 := _grid()
	g2.load_sown(g.sown_to_bytes())
	assert_eq(g2.sown, g.sown, "Sonnenblumen im Spielstand")


func test_old_user_dir_adopted_once() -> void:
	var base := OS.get_user_data_dir().path_join("test_adopt")
	var old := base.path_join("alt")
	var neu := base.path_join("neu")
	DirAccess.make_dir_recursive_absolute(old.path_join("saves"))
	var f := FileAccess.open(old.path_join("saves/save_a.json"), FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	f = FileAccess.open(old.path_join("settings.json"), FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	assert_eq(Game.adopt_old_user_dir(old, neu), 2, "Spielstand und Einstellungen kopiert")
	assert_true(FileAccess.file_exists(neu.path_join("saves/save_a.json")), "Spielstand da")
	assert_eq(Game.adopt_old_user_dir(old, neu), 0, "zweites Mal: nichts überschreiben")
	for p in [neu.path_join("saves/save_a.json"), neu.path_join("settings.json"), old.path_join("saves/save_a.json"), old.path_join("settings.json")]:
		DirAccess.remove_absolute(p)
	for d in [neu.path_join("saves"), neu, old.path_join("saves"), old, base]:
		DirAccess.remove_absolute(d)
