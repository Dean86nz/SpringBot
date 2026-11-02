extends Node2D
## Hauptszene: Raster, Boden, Roboter, Kamera, HUD, Menüs und (nur Debug) Cheat-Menü.
## Jedes Bild begrünt der Roboter die Zellen in seinem Radius; grüne Zellen bringen Pollen.
## Mit den Wachstums-Knoten wächst die Grenze des Grüns von allein weiter,
## Bienen tragen das Grün zu neuen Stellen. Alle Werte kommen aus dem Skilltree.
## Läuft auch während der Pause (Menü-Eingaben), Roboter und Boden pausieren.

var grid: GroundGrid
var skills: SkillTree
var cell_px := 24.0
var _base_radius := 3.0
var _base_speed := 380.0
var _green_radius := 3.0
var _spread_per_sec := 0.0   # Zellen, die pro Sekunde von allein wachsen
var _reach := 1.0
var _seed_chance := 0.3
var _spread_carry := 0.0
var _spread_cap := 3000
var _rng := RandomNumberGenerator.new()
var _bees := BeeSwarm.new()
var _bee_speed := 1.0
var _base_bloom := 2.3
var _base_hover := 2.0
var _bee_view := BeeView.new()
var _start_px := Vector2.ZERO
var _ground := GroundView.new()
var _robot := Robot.new()
var _camera := Camera2D.new()
var _hud := Hud.new()
var _tree := SkillTreeMenu.new()
var _pause := PauseMenu.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var w := int(Game.num("map/width_cells", 320))
	var h := int(Game.num("map/height_cells", 240))
	cell_px = Game.num("map/cell_px", 24)
	_base_radius = Game.num("robot/green_radius_cells", 3.0)
	_base_speed = Game.num("robot/speed_px", 380.0)
	grid = GroundGrid.new(w, h)
	var tree_data := Game.load_json(Game.SKILLTREE_PATH)
	skills = SkillTree.new(tree_data)
	_spread_cap = int(tree_data.get("spread_max_events_per_frame", 3000))
	skills.changed.connect(_apply_upgrades)
	var size_px := Vector2(w, h) * cell_px
	var start: Variant = Game.dig(Game.balance, "robot/start_cell")
	_start_px = (Vector2(start[0], start[1]) + Vector2(0.5, 0.5)) * cell_px if start is Array else size_px * 0.5

	_ground.process_mode = Node.PROCESS_MODE_PAUSABLE
	_ground.bind(grid, cell_px)
	add_child(_ground)
	var hive: Variant = Game.dig(Game.balance, "bees/hive_cell")
	var hive_px := (Vector2(hive[0], hive[1]) + Vector2(0.5, 0.5)) * cell_px if hive is Array else _start_px
	_bees.configure(Game.dig(Game.balance, "bees") if Game.dig(Game.balance, "bees") is Dictionary else {}, hive_px, cell_px)
	_base_bloom = _bees.bloom_radius
	_base_hover = _bees.hover_sec
	_bee_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_bee_view.bind(_bees)
	add_child(_bee_view)
	_robot.process_mode = Node.PROCESS_MODE_PAUSABLE
	_robot.accel = Game.num("robot/accel", 10.0)
	_robot.bounds = Rect2(Vector2.ZERO, size_px).grow(-cell_px * 0.5)
	_robot.position = _start_px
	_robot.radius_px = Game.num("robot/radius_px", 30.0)
	_robot.obstacles = [{"pos": hive_px, "radius": Game.num("bees/hive_radius_px", 32.0)}]
	add_child(_robot)
	_camera.zoom = Vector2.ONE * Game.num("camera/zoom", 1.0)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = Game.num("camera/smoothing", 6.0)
	_camera.limit_left = int(-cell_px * 4)
	_camera.limit_top = int(-cell_px * 4)
	_camera.limit_right = int(size_px.x + cell_px * 4)
	_camera.limit_bottom = int(size_px.y + cell_px * 4)
	_robot.add_child(_camera)
	add_child(_hud)
	_tree.setup(skills)
	add_child(_tree)
	add_child(_pause)
	if OS.is_debug_build():
		var cheats := CheatMenu.new()
		cheats.name = "CheatMenu"
		cheats.reset_requested.connect(reset_game)
		cheats.pollen_requested.connect(func() -> void: skills.pollen += 100000.0)
		cheats.unlock_all_requested.connect(skills.max_all)
		add_child(cheats)
	_apply_upgrades()
	_paint()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_paint()
	_spread(delta)
	_bees.update(delta, grid, _rng, _bee_speed)
	skills.tick(delta, grid.green_count)
	_hud.set_pollen(skills.pollen, skills.rate(grid.green_count))


func _paint() -> void:
	grid.paint_circle(_robot.position / cell_px, _green_radius)
	_hud.set_coverage(grid.coverage())


## Feste Zahl Zellen pro Sekunde (lineares Wachstum, unabhängig von der Länge der Grenze);
## Bruchteile wandern ins nächste Bild. Obergrenze je Bild schützt die Bildrate.
func _spread(delta: float) -> void:
	if _spread_per_sec <= 0.0 or grid.frontier.is_empty():
		_spread_carry = 0.0
		return
	_spread_carry += _spread_per_sec * delta
	var events := mini(int(_spread_carry), _spread_cap)
	_spread_carry = minf(_spread_carry - events, float(_spread_cap))
	if events > 0:
		grid.spread(events, _reach, _seed_chance, _rng)


func _apply_upgrades() -> void:
	_spread_per_sec = skills.stat("spread")
	_reach = skills.stat("seed_reach")
	_seed_chance = clampf(skills.stat("seed_chance"), 0.0, 0.9)
	_green_radius = _base_radius + skills.stat("radius")
	_robot.speed_px = _base_speed * (1.0 + skills.stat("speed") / 100.0)
	_bees.set_count(int(skills.stat("bees")))
	_bee_speed = 1.0 + skills.stat("bee_speed") / 100.0
	_bees.bloom_radius = _base_bloom + skills.stat("bloom")
	_bees.hover_sec = _base_hover * clampf(1.0 - skills.stat("bee_rest") / 100.0, 0.1, 1.0)


## Menüs öffnen und schließen. Das Cheat-Menü verwaltet sich selbst.
func _unhandled_input(event: InputEvent) -> void:
	if _tree.visible:
		if event.is_action_pressed("upgrades") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_tree.close()
			_robot.input_enabled = true
			get_viewport().set_input_as_handled()
	elif _pause.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_pause.close()
			get_viewport().set_input_as_handled()
	elif MenuKit.any_open(get_tree()):
		return
	elif event.is_action_pressed("upgrades"):
		_robot.input_enabled = false
		_tree.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_pause.open()
		get_viewport().set_input_as_handled()


func reset_game() -> void:
	Engine.time_scale = 1.0
	grid.clear()
	skills.reset()
	_spread_carry = 0.0
	_bees.set_count(0)
	_robot.position = _start_px
	_robot.velocity = Vector2.ZERO
	_camera.reset_smoothing()
	_paint()
