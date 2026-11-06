extends SceneTree
## Entwicklerwerkzeug: zeigt alle Objektarten nebeneinander, oben tot, unten erwacht, und speichert
## ein Bild. Nicht headless (Fenster öffnet kurz).
##   Godot_v4.7.2-stable_win64_console.exe --path . -s tools/object_gallery.gd -- <ausgabe.png>

const KINDS := ["oak", "fir", "birch", "fruit", "willow", "sapling", "rock", "pond", "bush", "log", "fence", "stones", "house", "fountain", "church", "school", "library", "shop", "smithy", "farmhouse", "barn", "stand", "field", "laundry", "cemetery", "windmill", "silo", "garden", "apartment", "tower",
	"suburb", "kita", "bakery", "pavilion", "manor", "machine_hall", "wheat", "cathedral", "museum", "cafe", "school_city", "raised_beds", "playground", "fountain_city"]
const COLS := 8

var _out := "user://gallery.png"
var _frames := 0


## Optional als zweites Argument: Arten mit Komma (z. B. "suburb,kita"), dann größere Felder je Art.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out = args[0]
	var kinds: Array = Array(args[1].split(",")) if args.size() >= 2 else KINDS
	var step := 170.0 if args.size() < 2 else 520.0
	var cols := mini(COLS, kinds.size()) if args.size() < 2 else mini(4, kinds.size())
	var rows := ceili(kinds.size() / float(cols))
	var half := Vector2(cols, rows) * step
	for row in 2:
		var bg := ColorRect.new()
		bg.color = Color(0.70, 0.68, 0.64) if row == 0 else Color(0.46, 0.76, 0.33)
		bg.position = Vector2(0, row * half.y)
		bg.size = half
		root.add_child(bg)
	for i in kinds.size():
		for row in 2:
			var o := WorldObject.new()
			var pos := Vector2((i % cols + 0.5) * step, (row * rows + i / cols + 0.55) * step)
			o.setup({"kind": kinds[i], "pos": pos, "seed": 1234 + i * 7, "angle": 0.0 if args.size() >= 2 else 0.4})
			root.add_child(o)
			o.set_awake(row == 1, false)
	var cam := Camera2D.new()   # alles ins Fenster
	cam.zoom = Vector2.ONE * minf(1920.0 / half.x, 1080.0 / (half.y * 2.0))
	cam.position = Vector2(half.x * 0.5, half.y)
	root.add_child(cam)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		root.get_texture().get_image().save_png(_out)
		print("gespeichert: ", _out)
		return true
	return false
