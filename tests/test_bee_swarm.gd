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


func test_full_map_bees_visit_near_hive() -> void:
	var g := GroundGrid.new(10, 10)
	g.paint_circle(Vector2(5, 5), 100.0)
	var rng := RandomNumberGenerator.new()
	var s := _swarm()
	for i in 20:
		var t := s.pick_target(Vector2(100, 100), g, rng)
		assert_true(s.last_pick_idle, "nichts zu begrünen: nur ein Besuch")
		assert_true(t.distance_to(s.hive) <= s.idle_radius * 24.0 + 0.1, "bleibt in der Nähe des Stocks")


func test_set_count() -> void:
	var s := _swarm()
	s.set_count(3)
	assert_eq(s.bees.size(), 3)
	assert_eq(s.bees[2].pos, s.hive, "neue Biene startet am Stock")
	s.set_count(0)
	assert_eq(s.bees.size(), 0)


func test_idle_bees_visit_flowers_and_rest_in_hive() -> void:
	var g := GroundGrid.new(60, 60)
	for y in 60:
		for x in 60:
			g.set_green(Vector2i(x, y))
	var s := BeeSwarm.new()
	s.configure({}, Vector2(30.5, 30.5) * 24.0, 24.0)
	s.trees = PackedVector2Array([Vector2(36, 30) * 24.0])
	s.set_count(6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var rested := false
	var far := 0.0
	for i in 60 * 40:
		s.update(1.0 / 60.0, g, rng)
		for b in s.bees:
			rested = rested or b.rest > 0.0
			far = maxf(far, b.pos.distance_to(s.hive))
	assert_true(rested, "Bienen ruhen ab und zu im Stock")
	assert_true(far > 5.0 * 24.0, "Bienen fliegen zu Blüten weiter weg, nicht nur um den Stock (%d px)" % int(far))
	assert_true(far < (s.idle_radius + 3.0) * 24.0, "aber bleiben in der Nähe des Stocks")
