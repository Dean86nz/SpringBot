extends SceneTree
## Entwicklerwerkzeug: startet die Hauptszene, hält Aktionen und speichert einen Screenshot.
## Nicht headless (Fenster öffnet kurz).
##   Godot_v4.7.2-stable_win64_console.exe --path . -s tests/screenshot.gd -- <ausgabe.png> [frames] [plan]
##   plan: "aktion:von:bis" getrennt durch Komma, z. B. "move_right:2:60,move_down:40:120" ("-" = nichts)
##   Das Spiel startet mit dem Titel: im Plan zuerst "ui_accept:10:11" (Spielen / Weiterspielen).
##   CHEATS=1 öffnet bei Bild 5 das Cheat-Menü, POLLEN=n gibt bei Bild 5 (oder POLLEN_AT) Pollen,
##   MAXALL=1 setzt bei Bild 20 alle Upgrades auf Maximum, TIMEX=n beschleunigt ab Bild 20 die Zeit,
##   ROBOT=x,y setzt den Roboter bei Bild 15 auf diese Zelle.
##   LUSH=1 spult bei Bild 15 die Weltzeit um 2000 s vor (alles Grün üppig, bunte Blumen).
##   ALMOST=1 begrünt bei Bild 15 (oder ALMOST_AT) die Welt bis auf einen Fleck rechts vom Roboter (Ende testen).
## Gibt am Ende die FPS aus (NOVSYNC=1 misst ungedrosselt) und die Grafikkarten-Zeit je Bild.

var _frames := 0
var _target := 120
var _out := "user://screenshot.png"
var _plan: Array = []
var _last_us := 0
var _worst_ms := 0.0
var _gpu_ms := 0.0
var _gpu_n := 0


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
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	change_scene_to_file("res://src/world/main.tscn")


func _process(_delta: float) -> bool:
	_frames += 1
	for s in _plan:
		if _frames == s["from"]:
			_send(s["action"], true)
		elif _frames == s["to"]:
			_send(s["action"], false)
	var pollen_at := int(OS.get_environment("POLLEN_AT")) if OS.get_environment("POLLEN_AT") != "" else 5
	if _frames == pollen_at and OS.get_environment("POLLEN") != "":
		current_scene.skills.pollen += float(OS.get_environment("POLLEN"))
	if _frames == 20 and OS.get_environment("MAXALL") == "1":
		current_scene.skills.max_all()
	if _frames == 20 and OS.get_environment("TIMEX") != "":
		Engine.time_scale = float(OS.get_environment("TIMEX"))
	if _frames == 15 and OS.get_environment("ROBOT") != "":
		var rc := OS.get_environment("ROBOT").split(",")
		var rob: Node2D = current_scene._robot
		rob.position = (Vector2(float(rc[0]), float(rc[1])) + Vector2(0.5, 0.5)) * current_scene.cell_px
	if _frames == 15 and OS.get_environment("LUSH") == "1":
		current_scene._world_sec += 2000.0
	var almost_at := int(OS.get_environment("ALMOST_AT")) if OS.get_environment("ALMOST_AT") != "" else 15
	if _frames == almost_at and OS.get_environment("ALMOST") == "1":
		current_scene.get_node("CheatMenu").almost_done_requested.emit()
	if _frames == 5 and OS.get_environment("CHEATS") == "1":
		current_scene.get_node("CheatMenu").open()
	var now := Time.get_ticks_usec()
	if _frames > 30 and _last_us > 0:
		var ms := (now - _last_us) / 1000.0
		if ms > 30.0:
			print("langsames Bild %d: %.1f ms, Grün %.1f %%" % [_frames, ms, current_scene.grid.coverage() * 100.0])
		_worst_ms = maxf(_worst_ms, ms)
	_last_us = now
	if _frames > 30:
		_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		_gpu_n += 1
	if _frames == _target:
		print("Grafikkarte im Schnitt %.2f ms je Bild" % (_gpu_ms / maxi(_gpu_n, 1)))
		var img := root.get_viewport().get_texture().get_image()
		var err := img.save_png(_out)
		print("screenshot %s -> %d, FPS %d, langsamstes Bild %.1f ms, Grün %.1f %%" % [_out, err, Engine.get_frames_per_second(), _worst_ms, current_scene.grid.coverage() * 100.0])
		Engine.time_scale = 1.0
		_target = -1
		root.get_node("Sfx").quit_game()
	return false


## Echtes InputEventAction, damit auch _unhandled_input (Menüs) reagiert.
func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
