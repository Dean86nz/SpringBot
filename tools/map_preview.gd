extends SceneTree
## Entwicklerwerkzeug: ganze Karte herausgezoomt (Wege, Wasser, Brücken, Objekte), linke Hälfte grau,
## rechte Hälfte grün und alt. Nicht Teil des Spiels.
##   Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tools/map_preview.gd -- <ausgabe.png> [zoom] [mitte_x] [mitte_y]
##   Ohne zoom: ganze Karte. Mitte in Zellen. Umgebungsvariable REGION (Standard heimatdorf), GRID=1 zeichnet
##   alle 50 Zellen eine Linie mit Zahl (zum Platzieren von Gebäuden).

var _frames := 0
var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	var cell := float(balance["map"]["cell_px"])
	var rid := OS.get_environment("REGION") if OS.get_environment("REGION") != "" else "heimatdorf"
	var dir := "res://data/regions/%s/" % rid
	var region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "region.json"))
	var grid := GroundGrid.new(int(region["width_cells"]), int(region["height_cells"]))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "world.json"))
	var bridges := WorldMap.build(grid, world)
	for i in grid.cells.size():
		if i % grid.width >= grid.width / 2:
			grid._green_index(i)
	var n := Node2D.new()
	root.add_child(n)
	var ground := GroundView.new()
	ground.bind(grid, cell, balance["ground"])
	ground.set_time(100000.0)
	n.add_child(ground)
	var bv := BridgeView.new()
	bv.bind(bridges, cell)
	n.add_child(bv)
	var start: Array = region["start_cell"]
	var objs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "objects.json"))
	for d in WorldObjects.place(grid, cell, objs, world, [(Vector2(start[0], start[1]) + Vector2(0.5, 0.5)) * cell]):
		var o := WorldObject.new()
		o.setup(d)
		n.add_child(o)
		o.set_awake(grid.is_green(Vector2i(o.position / cell)), false)
	if OS.get_environment("GRID") == "1":
		var lines := GridLines.new()
		lines.cells = Vector2i(grid.width, grid.height)
		lines.cell = cell
		n.add_child(lines)
	var cam := Camera2D.new()
	var size := Vector2(grid.width, grid.height) * cell
	cam.zoom = Vector2.ONE * (float(args[1]) if args.size() > 1 else minf(1920.0 / size.x, 1080.0 / size.y))
	cam.position = Vector2(float(args[2]), float(args[3])) * cell if args.size() > 3 else size * 0.5
	n.add_child(cam)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10:
		print("Karte %s -> %d" % [_out, root.get_viewport().get_texture().get_image().save_png(_out)])
		root.get_node("Sfx").quit_game()
	return false


class GridLines extends Node2D:
	var cells := Vector2i.ZERO
	var cell := 24.0

	func _ready() -> void:
		z_index = 50

	func _draw() -> void:
		for x in range(0, cells.x, 50):
			draw_line(Vector2(x * cell, 0), Vector2(x * cell, cells.y * cell), Color(0, 0, 0, 0.5), 6.0)
			for y in range(0, cells.y, 50):
				draw_string(ThemeDB.fallback_font, Vector2(x, y) * cell + Vector2(12, 120), "%d,%d" % [x, y], HORIZONTAL_ALIGNMENT_LEFT, -1, 110, Color.BLACK)
		for y in range(0, cells.y, 50):
			draw_line(Vector2(0, y * cell), Vector2(cells.x * cell, y * cell), Color(0, 0, 0, 0.5), 6.0)
