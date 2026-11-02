extends Node2D
## Hauptszene: Raster, Boden, Roboter, Kamera, HUD und (nur Debug) Cheat-Menü.
## Jedes Bild begrünt der Roboter die Zellen in seinem Radius.

var grid: GroundGrid
var cell_px := 24.0
var green_radius := 3.0
var _start_px := Vector2.ZERO
var _ground := GroundView.new()
var _robot := Robot.new()
var _camera := Camera2D.new()
var _hud := Hud.new()


func _ready() -> void:
	var w := int(Game.num("map/width_cells", 320))
	var h := int(Game.num("map/height_cells", 240))
	cell_px = Game.num("map/cell_px", 24)
	green_radius = Game.num("robot/green_radius_cells", 3.0)
	grid = GroundGrid.new(w, h)
	var size_px := Vector2(w, h) * cell_px
	var start: Variant = Game.dig(Game.balance, "robot/start_cell")
	_start_px = (Vector2(start[0], start[1]) + Vector2(0.5, 0.5)) * cell_px if start is Array else size_px * 0.5

	_ground.bind(grid, cell_px)
	add_child(_ground)
	_robot.speed_px = Game.num("robot/speed_px", 380.0)
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
	_camera.ignore_rotation = true
	add_child(_hud)
	if OS.is_debug_build():
		var cheats := CheatMenu.new()
		cheats.name = "CheatMenu"
		cheats.reset_requested.connect(reset_game)
		add_child(cheats)
	_paint()


func _process(_delta: float) -> void:
	_paint()


func _paint() -> void:
	grid.paint_circle(_robot.position / cell_px, green_radius)
	_hud.set_coverage(grid.coverage())


func reset_game() -> void:
	Engine.time_scale = 1.0
	grid.clear()
	_robot.position = _start_px
	_robot.velocity = Vector2.ZERO
	_camera.reset_smoothing()
	_paint()
