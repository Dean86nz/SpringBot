extends TestCase
## Samenvögel: Schwärme säen weit vom Häuschen lange Streifen, ruhen ohne Arbeit in der Nähe des
## Häuschens; der Ast im Skilltree bleibt verborgen, bis man die Region erreicht hat.


func _birds(nest: Vector2) -> SeedBirds:
	var b := SeedBirds.new()
	b.configure({"speed_px": 600.0, "strip_cells": 30, "width_cells": 1.5, "rest_sec": 0.5, "range_cells": [20, 40], "trips_home": 2}, nest, 24.0)
	return b


func test_flock_sows_long_strips_far_away() -> void:
	var g := GroundGrid.new(200, 150)
	var nest := Vector2(100.5, 75.5) * 24.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var b := _birds(nest)
	b.set_count(1)
	var added := 0
	for i in 60 * 20:
		added += b.update(1.0 / 60.0, g, rng)
	assert_eq(added, g.green_count, "alles Grün kommt von den Vögeln")
	assert_true(added > 400, "in 20 s ganze Streifen gesät (%d Zellen)" % added)
	var far := 0
	for i in g.cells.size():
		if g.is_green(Vector2i(i % g.width, i / g.width)) and Vector2(i % g.width, i / g.width).distance_to(nest / 24.0) > 20.0:
			far += 1
	assert_true(far > added / 2, "das meiste weit weg vom Häuschen (%d von %d)" % [far, added])
	assert_false(b.seeds.is_empty() and b.blooms.is_empty(), "Samen fallen, Blüten gehen auf")


func test_idle_when_all_green_and_count() -> void:
	var g := GroundGrid.new(120, 90)
	g.fill_except(Vector2(-100, -100), 1.0)
	var nest := Vector2(60.5, 45.5) * 24.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var b := _birds(nest)
	b.set_count(3)
	assert_eq(b.flocks.size(), 3, "drei Schwärme")
	var added := 0
	var max_d := 0.0
	for i in 60 * 30:
		added += b.update(1.0 / 60.0, g, rng)
		for f in b.flocks:
			max_d = maxf(max_d, f.pos.distance_to(nest))
	assert_eq(added, 0, "nichts mehr zu säen")
	assert_true(max_d < 22.0 * 24.0, "Runden in der Nähe des Häuschens (%d px)" % int(max_d))
	b.set_count(1)
	assert_eq(b.flocks.size(), 1, "weniger Schwärme")


func test_bird_branch_hidden_until_region_reached() -> void:
	var t := SkillTree.new(Game.load_json(Game.SKILLTREE_PATH))
	t.pollen = 1.0e9
	var birds: Array[String] = []
	for id in t.order:
		if str(t.nodes[id].get("region", "")) == "felder":
			birds.append(id)
	assert_true(birds.size() >= 10, "ein ganzer Ast Samenvögel (%d)" % birds.size())
	t.regions.assign(["heimatdorf"])
	for id in birds:
		assert_eq(t.state(id), SkillTree.State.HIDDEN, "%s verborgen im Heimatdorf" % id)
		assert_false(t.can_buy(id), "%s nicht käuflich" % id)
	t.regions.assign(["heimatdorf", "felder"])
	assert_eq(t.state("v1"), SkillTree.State.AVAILABLE, "in Felder und Vorort frei")
	assert_true(t.buy("v1"), "Vogelhäuschen kaufen")
	assert_eq(t.stat("birds"), 1.0, "ein Schwarm")
	t.regions.assign(["heimatdorf"])
	assert_eq(t.state("v1"), SkillTree.State.OWNED, "Gekauftes bleibt (Vögel helfen überall)")
