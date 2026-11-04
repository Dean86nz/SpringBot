extends SceneTree
## Entwicklerwerkzeug: ganze Karte herausgezoomt (Wege, Wasser, Brücken), linke Hälfte grau,
## rechte Hälfte grün und alt. Nicht Teil des Spiels.
##   Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tools/map_preview.gd -- <ausgabe.png> [zoom] [mitte_x] [mitte_y]
##   Ohne zoom: ganze Karte. Mitte in Zellen.

var _frames := 0
var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	var cell := float(balance["map"]["cell_px"])
	var grid := GroundGrid.new(int(balance["map"]["width_cells"]), int(balance["map"]["height_cells"]))
	var bridges := WorldMap.build(grid, JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json")))
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
