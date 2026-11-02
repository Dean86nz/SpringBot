extends TestCase
## Kernlogik der Bienen: Zielwahl auf Grau, Begrünen nach dem Schweben, Anzahl.


func _swarm() -> BeeSwarm:
	var s := BeeSwarm.new()
	s.configure({"speed_px": 1000.0, "bloom_radius_cells": 1.5, "hover_sec": 0.5, "hop_min_cells": 3, "hop_max_cells": 6}, Vector2(240, 240), 24.0)
	return s


func test_target_is_grey_cell() -> void:
	var g := GroundGrid.new(40, 40)
	g.paint_circle(Vector2(10, 10), 2.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var s := _swarm()
	for i in 20:
		var t := s.pick_target(Vector2(240, 240), g, rng)
		assert_false(g.is_green(Vector2i(t / 24.0)), "Ziel %s ist grau" % t)


func test_bee_greens_after_hover() -> void:
	var g := GroundGrid.new(40, 40)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var s := _swarm()
	s.set_count(1)
	s.bees[0].target = Vector2(500, 500)
	var added := 0
	for i in 120:   # 2 Sekunden bei 60 Bildern
		added += s.update(1.0 / 60.0, g, rng)
	assert_true(added > 0, "Biene hat nach dem Schweben begrünt")
	assert_true(g.is_green(Vector2i(20, 20)), "am Zielort ist es grün")


func test_full_map_falls_back_to_hive() -> void:
	var g := GroundGrid.new(10, 10)
	g.paint_circle(Vector2(5, 5), 100.0)
	var rng := RandomNumberGenerator.new()
	var s := _swarm()
	var t := s.pick_target(Vector2(100, 100), g, rng)
	assert_true(t.distance_to(s.hive) <= 5.0 * 24.0 + 0.1, "kreist um den Stock")


func test_set_count() -> void:
	var s := _swarm()
	s.set_count(3)
	assert_eq(s.bees.size(), 3)
	assert_eq(s.bees[2].pos, s.hive, "neue Biene startet am Stock")
	s.set_count(0)
	assert_eq(s.bees.size(), 0)
