extends SceneTree
## Entwicklerwerkzeug: Stil-Vorschlag für Phase 2 (Grün, Objekte, Tiere) als Standbild.
## Links die graue Welt mit toten Objekten, rechts dieselben Objekte erwacht.
## Nicht Teil des Spiels.
##   Godot_v4.7.2-stable_win64_console.exe --audio-driver Dummy --path . -s tools/style_preview.gd -- <ausgabe.png>

const CELL := 24.0
var _frames := 0
var _out := "user://style.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out = args[0]
	var root2d := Node2D.new()
	root.add_child(root2d)
	var grid := GroundGrid.new(80, 45)
	for y in grid.height:
		var edge := 37.0 + sin(y * 0.45) * 1.5 + sin(y * 0.17) * 1.2
		for x in grid.width:
			if x > edge:
				grid.set_green(Vector2i(x, y))
	var ground := GroundView.new()
	ground.bind(grid, CELL)
	root2d.add_child(ground)
	var canvas: Node2D = load("res://tools/style_preview_canvas.gd").new()
	root2d.add_child(canvas)
	var robot := Robot.new()
	robot.position = Vector2(1000, 820)
	robot.input_enabled = false
	robot.rotation = -0.4
	root2d.add_child(robot)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10:
		var img := root.get_viewport().get_texture().get_image()
		print("Vorschau %s -> %d" % [_out, img.save_png(_out)])
		root.get_node("Sfx").quit_game()
	return false
