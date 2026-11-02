extends Node2D
## Hauptszene: Raster, Boden, Roboter, Kamera, HUD, Menüs und (nur Debug) Cheat-Menü.
## Jedes Bild begrünt der Roboter die Zellen in seinem Radius; grüne Zellen bringen Pollen.
## Mit den Wachstums-Upgrades wächst die Grenze des Grüns von allein weiter.
## Läuft auch während der Pause (Menü-Eingaben), Roboter und Boden pausieren.

var grid: GroundGrid
var eco: Economy
var cell_px := 24.0
var _base_radius := 3.0
var _base_speed := 380.0
var _green_radius := 3.0
var _spread_per_sec := 0.0   # Anteil der Grenzzellen, die pro Sekunde wachsen
var _reach := 1
var _spread_carry := 0.0
var _spread_cap := 3000
var _rng := RandomNumberGenerator.new()
var _start_px := Vector2.ZERO
var _ground := GroundView.new()
var _robot := Robot.new()
var _camera := Camera2D.new()
var _hud := Hud.new()
var _upgrades := UpgradeMenu.new()
var _pause := PauseMenu.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var w := int(Game.num("map/width_cells", 320))
	var h := int(Game.num("map/height_cells", 240))
	cell_px = Game.num("map/cell_px", 24)
	_base_radius = Game.num("robot/green_radius_cells", 3.0)
	_base_speed = Game.num("robot/speed_px", 380.0)
	grid = GroundGrid.new(w, h)
	var upgrade_data := Game.load_json(Game.UPGRADES_PATH)
	eco = Economy.new(upgrade_data)
	_spread_cap = int(upgrade_data.get("spread_max_events_per_frame", 3000))
	eco.changed.connect(_apply_upgrades)
	var size_px := Vector2(w, h) * cell_px
	var start: Variant = Game.dig(Game.balance, "robot/start_cell")
	_start_px = (Vector2(start[0], start[1]) + Vector2(0.5, 0.5)) * cell_px if start is Array else size_px * 0.5

	_ground.process_mode = Node.PROCESS_MODE_PAUSABLE
	_ground.bind(grid, cell_px)
	add_child(_ground)
	_robot.process_mode = Node.PROCESS_MODE_PAUSABLE
	_robot.accel = Game.num("robot/accel", 10.0)
	_robot.bounds = Rect2(Vector2.ZERO, size_px).grow(-cell_px * 0.5)
	_robot.position = _start_px
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
	_upgrades.setup(eco)
	add_child(_upgrades)
	add_child(_pause)
	if OS.is_debug_build():
		var cheats := CheatMenu.new()
		cheats.name = "CheatMenu"
		cheats.reset_requested.connect(reset_game)
		cheats.pollen_requested.connect(func() -> void: eco.pollen += 10000.0)
		cheats.unlock_all_requested.connect(eco.max_all)
		add_child(cheats)
	_apply_upgrades()
	_paint()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_paint()
	_spread(delta)
	eco.tick(delta, grid.green_count)
	_hud.set_pollen(eco.pollen, eco.rate(grid.green_count))


func _paint() -> void:
	grid.paint_circle(_robot.position / cell_px, _green_radius)
	_hud.set_coverage(grid.coverage())


## Erwartete Wachstumsereignisse = Grenzzellen × Anteil × Zeit; Bruchteile wandern ins nächste Bild.
## Obergrenze je Bild schützt die Bildrate (Zeit ×10, sehr lange Grenzen).
func _spread(delta: float) -> void:
	if _spread_per_sec <= 0.0:
		return
	_spread_carry += grid.frontier.size() * _spread_per_sec * delta
	var events := mini(int(_spread_carry), _spread_cap)
	_spread_carry = minf(_spread_carry - events, float(_spread_cap))
	if events > 0:
		grid.spread(events, _reach, _rng)


func _apply_upgrades() -> void:
	_spread_per_sec = eco.bonus("spread") / 100.0
	_reach = int(eco.base("reach") + eco.bonus("reach"))
	_green_radius = _base_radius + eco.bonus("radius")
	_robot.speed_px = _base_speed * (1.0 + eco.bonus("speed") / 100.0)


## Menüs öffnen und schließen. Das Cheat-Menü verwaltet sich selbst.
func _unhandled_input(event: InputEvent) -> void:
	if _upgrades.visible:
		if event.is_action_pressed("upgrades") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_upgrades.close()
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
		_upgrades.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_pause.open()
		get_viewport().set_input_as_handled()


func reset_game() -> void:
	Engine.time_scale = 1.0
	grid.clear()
	eco.reset()
	_spread_carry = 0.0
	_robot.position = _start_px
	_robot.velocity = Vector2.ZERO
	_camera.reset_smoothing()
	_paint()
