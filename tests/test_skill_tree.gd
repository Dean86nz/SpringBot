extends TestCase
## Kernlogik des Skilltrees: Kaufen, Voraussetzungen, Sichtbarkeit, Werte, Pollen.

const DATA := {
	"pollen_per_cell_per_sec": 0.5,
	"base": {"seed_reach": 1},
	"stats": {"radius": {"label": "Zellen", "format": "+%s"}},
	"nodes": [
		{"id": "root", "pos": [0, 0], "requires": [], "max_level": 1, "base_cost": 0, "effects": {}},
		{"id": "a", "pos": [1, 0], "requires": ["root"], "max_level": 2, "base_cost": 10, "cost_growth": 2.0, "effects": {"radius": 0.5}},
		{"id": "b", "pos": [2, 0], "requires": ["a"], "max_level": 1, "base_cost": 5, "effects": {"pollen": 100}},
		{"id": "c", "pos": [3, 0], "requires": ["b"], "max_level": 1, "base_cost": 5, "effects": {}},
	],
}


func test_root_owned_and_visibility() -> void:
	var t := SkillTree.new(DATA)
	assert_eq(t.state("root"), SkillTree.State.OWNED)
	assert_eq(t.state("a"), SkillTree.State.AVAILABLE)
	assert_eq(t.state("b"), SkillTree.State.MYSTERY, "Nachbar eines kaufbaren Knotens ist angedeutet")
	assert_eq(t.state("c"), SkillTree.State.HIDDEN)
	t.pollen = 100.0
	assert_true(t.buy("a"))
	assert_eq(t.state("b"), SkillTree.State.AVAILABLE)
	assert_eq(t.state("c"), SkillTree.State.MYSTERY)


func test_requires_and_costs() -> void:
	var t := SkillTree.new(DATA)
	t.pollen = 100.0
	assert_false(t.buy("b"), "Vorgänger fehlt")
	assert_true(t.buy("a"))
	assert_eq(t.cost("a"), 20, "Kosten verdoppeln sich")
	assert_true(t.buy("a"))
	assert_false(t.buy("a"), "Maximum erreicht")
	assert_eq(t.pollen, 70.0)


func test_stats_and_pollen_bonus() -> void:
	var t := SkillTree.new(DATA)
	assert_eq(t.stat("seed_reach"), 1.0, "Grundwert")
	t.max_all()
	assert_eq(t.stat("radius"), 1.0, "2 Stufen × 0,5")
	assert_eq(t.rate(10), 10.0, "10 Zellen × 0,5 × (1 + 100 %)")
	t.reset()
	assert_eq(t.level("a"), 0)
	assert_eq(t.level("root"), 1, "Wurzel bleibt nach dem Zurücksetzen gekauft")


func test_effect_text() -> void:
	var t := SkillTree.new(DATA)
	assert_eq(t.effect_text("a"), "+0,5 Zellen")


func test_real_data_is_consistent() -> void:
	var t := SkillTree.new(Game.load_json("res://data/skilltree.json"))
	assert_true(t.order.size() >= 40 and t.order.size() <= 90, "40–90 Knoten (jede Region bringt einen Ast), sind %d" % t.order.size())
	for id in t.order:
		for r in t.nodes[id].get("requires", []):
			assert_true(t.nodes.has(str(r)), "%s verlangt unbekannten Knoten %s" % [id, r])
	t.max_all()
	for id in t.order:
		assert_eq(t.state(id), SkillTree.State.OWNED, "%s erreichbar" % id)


func test_gamepad_navigation_finds_branches() -> void:
	var t := SkillTree.new(Game.load_json("res://data/skilltree.json"))
	t.max_all()
	var menu := SkillTreeMenu.new()
	menu.setup(t)
	assert_eq(menu.pick_neighbor("root", Vector2.UP), "r1", "oben: Roboter")
	assert_eq(menu.pick_neighbor("root", Vector2.RIGHT), "w1", "rechts: Wachstum")
	assert_eq(menu.pick_neighbor("root", Vector2.LEFT), "b1", "links: Bienen")
	# Von jedem Knoten aus ist in mindestens einer Richtung ein anderer erreichbar
	for id in t.order:
		var any := false
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			if menu.pick_neighbor(id, d) != "":
				any = true
		assert_true(any, "%s ist eine Sackgasse" % id)
	menu.free()


func test_free_pan_selects_center_and_stays_in_bounds() -> void:
	var t := SkillTree.new(Game.load_json("res://data/skilltree.json"))
	var menu := SkillTreeMenu.new()
	menu.setup(t)
	var r1: Array = t.nodes["r1"]["pos"]
	var r1_px := Vector2(float(r1[0]), float(r1[1])) * SkillTreeMenu.UNIT_PX
	assert_eq(menu.nearest_node(r1_px, 50.0), "r1", "kaufbarer Knoten in der Mitte wird gewählt")
	assert_eq(menu.nearest_node(r1_px * 3.0, 50.0), "", "verdeckte Knoten werden nicht gewählt")
	menu.pan_by(Vector2(1e6, 1e6))
	menu.pan_by(r1_px - Vector2(1e6, 1e6))
	assert_true(menu._view.x < 1e5, "Ansicht bleibt am Rand des Baums hängen")
	menu.free()


func test_number_format() -> void:
	assert_eq(Fmt.int_str(1234567), "1.234.567")
	assert_eq(Fmt.num(2.5), "2,5")
	assert_eq(Fmt.num(3.0), "3")
