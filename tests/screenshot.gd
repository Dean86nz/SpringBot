extends SceneTree
## Entwicklerwerkzeug: startet die Hauptszene, hält Aktionen und speichert einen Screenshot.
## Nicht headless (Fenster öffnet kurz).
##   Godot_v4.7.2-stable_win64_console.exe --path . -s tests/screenshot.gd -- <ausgabe.png> [frames] [plan]
##   plan: "aktion:von:bis" getrennt durch Komma, z. B. "move_right:2:60,move_down:40:120" ("-" = nichts)
##   CHEATS=1 öffnet bei Bild 5 das Cheat-Menü.
## Gibt am Ende die FPS aus (NOVSYNC=1 misst ungedrosselt).

var _frames := 0
var _target := 120
var _out := "user://screenshot.png"
var _plan: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out = args[0]
	if args.size() >= 2:
		_target = int(args[1])
	if args.size() >= 3 and args[2] != "-":
		for entry in args[2].split(","):
			var p := entry.split(":")
			_plan.append({"action": p[0], "from": int(p[1]), "to": int(p[2])})
	if OS.get_environment("NOVSYNC") == "1":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	change_scene_to_file("res://src/world/main.tscn")


func _process(_delta: float) -> bool:
	_frames += 1
	for s in _plan:
		if _frames == s["from"]:
			Input.action_press(s["action"])
		elif _frames == s["to"]:
			Input.action_release(s["action"])
	if _frames == 5 and OS.get_environment("CHEATS") == "1":
		current_scene.get_node("CheatMenu").open()
	if _frames == _target:
		var img := root.get_viewport().get_texture().get_image()
		var err := img.save_png(_out)
		print("screenshot %s -> %d, FPS %d" % [_out, err, Engine.get_frames_per_second()])
		quit(0)
	return false
