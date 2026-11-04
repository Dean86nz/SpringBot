extends TestCase
## Wege und Wasser: richtige Karte erreichbar, Wasser nie grün, Fläche nur aus Land.


func _real_grid() -> GroundGrid:
	var g := GroundGrid.new(640, 480)
	WorldMap.build(g, Game.load_json("res://data/world.json"))
	return g


func test_real_map_every_land_cell_reachable_over_bridges() -> void:
	var g := _real_grid()
	var balance := Game.load_json(Game.BALANCE_PATH)
	var start: Array = Game.dig(balance, "robot/start_cell")
	var hive: Array = Game.dig(balance, "bees/hive_cell")
	assert_eq(g.terrain[int(start[1]) * g.width + int(start[0])], GroundGrid.LAND, "Start liegt auf Land")
	assert_eq(g.terrain[int(hive[1]) * g.width + int(hive[0])], GroundGrid.LAND, "Bienenstock liegt auf Land")
	assert_true(g.terrain.count(GroundGrid.WATER) > 1000, "es gibt Wasser")
	assert_true(g.terrain.count(GroundGrid.PATH) > 1000, "es gibt Wege")
	assert_true(g.terrain.count(GroundGrid.BRIDGE) > 0, "es gibt Brücken")
	# Breitensuche über befahrbare Zellen: ohne Brücken wäre ein Teil der Karte abgeschnitten
	var seen := PackedByteArray()
	seen.resize(g.width * g.height)
	var queue := PackedInt32Array([int(start[1]) * g.width + int(start[0])])
	seen[queue[0]] = 1
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % g.width
		for n in [i - 1 if x > 0 else -1, i + 1 if x < g.width - 1 else -1, i - g.width, i + g.width]:
			if n >= 0 and n < seen.size() and seen[n] == 0 and g.terrain[n] != GroundGrid.WATER:
				seen[n] = 1
				queue.append(n)
	var missed := 0
	for i in seen.size():
		if seen[i] == 0 and g.terrain[i] == GroundGrid.LAND:
			missed += 1
	assert_eq(missed, 0, "Landzellen ohne Weg zum Start")


func test_water_and_paths_never_green_and_not_counted() -> void:
	var g := GroundGrid.new(20, 10)
	var t := PackedByteArray()
	t.resize(200)
	for y in 10:
		t[y * 20 + 5] = GroundGrid.WATER
		t[y * 20 + 6] = GroundGrid.PATH
	var soft := PackedByteArray()
	soft.resize(400)
	g.set_terrain(t, soft)
	assert_eq(g.total(), 180, "nur Land zählt")
	g.paint_circle(Vector2(6, 5), 4.0)
	assert_false(g.is_green(Vector2i(5, 5)), "Wasser bleibt")
	assert_false(g.is_green(Vector2i(6, 5)), "Weg bleibt")
	assert_true(g.is_green(Vector2i(4, 5)))
	assert_false(g.frontier.has(5 * 20 + 5), "Wasser gehört nie zur Grenze")
	assert_false(g.is_walkable(Vector2i(5, 5)))
	assert_true(g.is_walkable(Vector2i(6, 5)), "auf dem Weg darf man fahren")
	var rng := RandomNumberGenerator.new()
	for k in 50:
		g.spread(100, 3.0, 0.5, rng)
	assert_eq(g.coverage(), 1.0, "100 % erreichbar, obwohl Weg und Wasser grau bleiben")


func test_robot_stops_at_water() -> void:
	var r := Robot.new()
	r.walkable = func(p: Vector2) -> bool: return p.x < 100.0
	r.water_radius_px = 20.0
	assert_true(r.can_stand(Vector2(50, 0)))
	assert_false(r.can_stand(Vector2(90, 0)), "Rand des Roboters wäre im Wasser")
	r.free()


## Ohne Roboter und Bienen: Die Ausbreitung allein erreicht jede Landzelle (springt über Wege und
## Wasser), und bei 100 % ist die Anzeige-Maske überall voll grün (kein Grau mehr sichtbar).
func test_spread_alone_fills_real_map_and_leaves_no_grey() -> void:
	var g := _real_grid()
	g.paint_circle(Vector2(320.3, 240.7), 3.0, true)
	g.paint_circle(Vector2(330.6, 240.2), 3.0, true)   # zweite Spur: Randzellen mit Teilwert
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	while not g.frontier.is_empty():
		g.spread(20000, 1.0, 0.0, rng)
	assert_eq(g.coverage(), 1.0, "alles Land grün")
	var partial := 0
	for i in g.vis.size():
		if g.terrain[i] == GroundGrid.LAND and g.vis[i] != GroundGrid.GREEN:
			partial += 1
	assert_eq(partial, 0, "Landzellen, die in der Anzeige nicht voll grün sind")


func test_only_robot_cleans_paths() -> void:
	var g := GroundGrid.new(20, 10)
	var t := PackedByteArray()
	t.resize(200)
	for y in 10:
		t[y * 20 + 10] = GroundGrid.PATH
	var soft := PackedByteArray()
	soft.resize(400)
	g.set_terrain(t, soft)
	g.paint_circle(Vector2(10.5, 5.5), 2.0)
	assert_eq(g.clean_count, 0, "Bienen säubern keine Wege")
	g.paint_circle(Vector2(10.5, 5.5), 2.0, true)
	assert_eq(g.last_cleaned, 5, "Roboter säubert die Wegzellen im Kreis")
	assert_eq(g.path_clean(), 0.5)
	assert_eq(g.coverage() < 1.0, true)
	var b := GroundGrid.new(20, 10)
	b.set_terrain(t, soft)
	b.load_bytes(g.to_bytes())
	assert_eq(b.clean_count, 5, "saubere Wege überstehen Speichern und Laden")
