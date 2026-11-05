extends SceneTree
## Entwicklerwerkzeug: zeigt alle Objektarten nebeneinander, oben tot, unten erwacht, und speichert
## ein Bild. Nicht headless (Fenster öffnet kurz).
##   Godot_v4.7.2-stable_win64_console.exe --path . -s tools/object_gallery.gd -- <ausgabe.png>

const KINDS := ["oak", "fir", "birch", "fruit", "willow", "sapling", "rock", "pond", "bush", "log", "fence", "stones", "house", "fountain"]
const STEP := 200.0

var _out := "user://gallery.png"
var _frames := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out = args[0]
	root.size = Vector2i(int(STEP * 7), int(STEP * 4))
	for row in 2:
		var bg := ColorRect.new()
		bg.color = Color(0.70, 0.68, 0.64) if row == 0 else Color(0.46, 0.76, 0.33)
		bg.position = Vector2(0, row * STEP * 2)
		bg.size = Vector2(STEP * 7, STEP * 2)
		root.add_child(bg)
	for i in KINDS.size():
		for row in 2:
			var o := WorldObject.new()
			var pos := Vector2((i % 7 + 0.5) * STEP, (row * 2 + i / 7 + 0.5) * STEP)
			o.setup({"kind": KINDS[i], "pos": pos, "seed": 1234 + i * 7, "angle": 0.4})
			root.add_child(o)
			o.set_awake(row == 1, false)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		root.get_texture().get_image().save_png(_out)
		print("gespeichert: ", _out)
		return true
	return false
