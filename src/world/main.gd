extends Node2D
## Hauptszene: Raster, Boden, Roboter, Kamera, HUD, Menüs und (nur Debug) Cheat-Menü.
## Jedes Bild begrünt der Roboter die Zellen in seinem Radius; grüne Zellen bringen Pollen.
## Mit den Wachstums-Knoten wächst die Grenze des Grüns von allein weiter,
## Bienen tragen das Grün zu neuen Stellen. Alle Werte kommen aus dem Skilltree.
## Wege, Flüsse und Brücken kommen aus data/world.json (WorldMap); sie werden nie grün.
## Objekte (Bäume, Teiche, Büsche, Felsen, Wegrand) aus data/objects.json erwachen, sobald unter
## ihnen Grün ist; um Bäume und Felsen fährt der Roboter herum.
## Läuft auch während der Pause (Menü-Eingaben), Roboter und Boden pausieren.
## Rahmen: Start mit Titelbildschirm (dahinter der gespeicherte Garten), Speichern alle
## paar Sekunden und bei jedem Menü, Endbildschirm, sobald die ganze Welt blüht.

const WORLD_PATH := "res://data/world.json"
const OBJECTS_PATH := "res://data/objects.json"

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
var _bridge_view := BridgeView.new()
var _objects: Array[WorldObject] = []
var _obj_cfg: Dictionary = {}
var _awake_timer := 0.0
var _petals := PetalFx.new()
var _petal_carry := 0.0
var _milestone := 0          # erreichte Zehntel der Fläche (für Klang und Blätterregen)
var _robot := Robot.new()
var _camera := Camera2D.new()
var _hud := Hud.new()
var _tree := SkillTreeMenu.new()
var _pause := PauseMenu.new()
var _title := TitleScreen.new()
var _end := EndScreen.new()
var _store := SaveStore.new()
var _play_sec := 0.0         # Spielzeit in echten Sekunden (ohne Pause und Menüs)
var _world_sec := 0.0        # Spielzeit der Welt (läuft mit Zeit ×10 schneller), für „seit wann grün“
var _finished := false       # Ende schon erreicht (Endbildschirm kommt nur einmal)
var _end_wait := -1.0        # Sekunden bis zum Endbildschirm, < 0 = keiner geplant
var _autosave := 0.0
var _save_task := -1         # WorkerThreadPool-Aufgabe, die gerade schreibt


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var w := int(Game.num("map/width_cells", 320))
	var h := int(Game.num("map/height_cells", 240))
	cell_px = Game.num("map/cell_px", 24)
	_base_radius = Game.num("robot/green_radius_cells", 3.0)
	_base_speed = Game.num("robot/speed_px", 380.0)
	grid = GroundGrid.new(w, h)
	grid.hop_cells = int(Game.num("map/spread_hop_cells", 12))
	var t0 := Time.get_ticks_msec()
	var world_data := Game.load_json(WORLD_PATH)
	var bridges := WorldMap.build(grid, world_data)
	print("Wege und Wasser: %d Brücken, %d ms" % [bridges.size(), Time.get_ticks_msec() - t0])
	var tree_data := Game.load_json(Game.SKILLTREE_PATH)
	skills = SkillTree.new(tree_data)
	_spread_cap = int(tree_data.get("spread_max_events_per_frame", 3000))
	skills.changed.connect(_apply_upgrades)
	var size_px := Vector2(w, h) * cell_px
	var start: Variant = Game.dig(Game.balance, "robot/start_cell")
	_start_px = (Vector2(start[0], start[1]) + Vector2(0.5, 0.5)) * cell_px if start is Array else size_px * 0.5

	_ground.process_mode = Node.PROCESS_MODE_ALWAYS   # zeigt den geladenen Garten auch hinter dem Titel
	var ground_cfg: Variant = Game.dig(Game.balance, "ground")
	_ground.bind(grid, cell_px, ground_cfg if ground_cfg is Dictionary else {})
	add_child(_ground)
	_bridge_view.bind(bridges, cell_px)
	add_child(_bridge_view)
	var hive: Variant = Game.dig(Game.balance, "bees/hive_cell")
	var hive_px := (Vector2(hive[0], hive[1]) + Vector2(0.5, 0.5)) * cell_px if hive is Array else _start_px
	_bees.configure(Game.dig(Game.balance, "bees") if Game.dig(Game.balance, "bees") is Dictionary else {}, hive_px, cell_px)
	_base_bloom = _bees.bloom_radius
	_base_hover = _bees.hover_sec
	_obj_cfg = Game.load_json(OBJECTS_PATH)
	var blockers: Array[Dictionary] = []
	for d in WorldObjects.place(grid, cell_px, _obj_cfg, world_data, [_start_px, hive_px]):
		var o := WorldObject.new()
		o.setup(d)
		add_child(o)
		_objects.append(o)
		if float(d["block"]) > 0.0:
			blockers.append({"pos": d["pos"], "radius": float(d["block"])})
	print("Objekte: %d, davon %d Hindernisse, %d ms" % [_objects.size(), blockers.size(), Time.get_ticks_msec() - t0])
	_bee_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_bee_view.bind(_bees)
	add_child(_bee_view)
	_petals.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_petals)   # vor dem Roboter: Blätter liegen unter ihm
	_robot.process_mode = Node.PROCESS_MODE_PAUSABLE
	_robot.accel = Game.num("robot/accel", 10.0)
	_robot.radius_px = Game.num("robot/radius_px", 30.0)
	# Abstand zum Kartenrand: Der Roboter bleibt samt Ketten und Schatten ganz im Bild
	_robot.bounds = Rect2(Vector2.ZERO, size_px).grow(-Game.num("robot/edge_margin_px", 46.0))
	_robot.position = _start_px
	_robot.obstacles = [{"pos": hive_px, "radius": Game.num("bees/hive_radius_px", 32.0)}]
	_robot.obstacles.append_array(blockers)
	_robot.water_radius_px = Game.num("robot/water_radius_px", 24.0)
	_robot.walkable = func(p: Vector2) -> bool: return grid.is_walkable(Vector2i(p / cell_px))
	add_child(_robot)
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS   # Versatz für den Titel greift auch in der Pause
	_camera.zoom = Vector2.ONE * Game.num("camera/zoom", 1.0)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = Game.num("camera/smoothing", 6.0)
	# Kamera bleibt auf der Karte (Rand jenseits der Karte wäre nur leere Fläche)
	var edge := int(Game.num("camera/edge_margin_px", 0.0))
	_camera.limit_left = -edge
	_camera.limit_top = -edge
	_camera.limit_right = int(size_px.x) + edge
	_camera.limit_bottom = int(size_px.y) + edge
	_robot.add_child(_camera)
	add_child(_hud)
	_tree.setup(skills)
	add_child(_tree)
	_pause.title_requested.connect(show_title)
	_pause.quit_requested.connect(quit)
	add_child(_pause)
	_end.title_requested.connect(show_title)
	add_child(_end)
	_title.continue_requested.connect(_start_playing)
	_title.new_game_requested.connect(func() -> void:
		reset_game()
		save()
		_start_playing())
	_title.quit_requested.connect(quit)
	add_child(_title)
	if OS.is_debug_build():
		var cheats := CheatMenu.new()
		cheats.name = "CheatMenu"
		cheats.reset_requested.connect(reset_game)
		cheats.pollen_requested.connect(func() -> void: skills.pollen += 100000.0)
		cheats.unlock_all_requested.connect(skills.max_all)
		cheats.almost_done_requested.connect(func() -> void:
			grid.fill_except(_robot.position / cell_px + Vector2(20, 0), 2.5)
			_milestone = floori(grid.coverage() * 10.0))
		add_child(cheats)
	_apply_upgrades()
	load_game(_store.read())
	show_title()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_paint()
	_spread(delta)
	_bees.update(delta, grid, _rng, _bee_speed)
	_bee_blooms()
	skills.tick(delta, grid.green_count)
	_hud.set_pollen(skills.pollen, skills.rate(grid.green_count))
	var real := delta / maxf(Engine.time_scale, 0.001)
	_play_sec += real
	_world_sec += delta
	grid.time_sec = _world_sec
	_ground.set_time(_world_sec)
	_check_end(delta)
	_awake_timer -= delta
	if _awake_timer <= 0.0:
		_awake_timer = float(_obj_cfg.get("awake_check_sec", 0.2))
		_wake_objects(true)
	_autosave += real
	if _autosave >= Game.num("save/autosave_sec", 30.0):
		save()


func _paint() -> void:
	var fresh := grid.paint_circle(_robot.position / cell_px, _green_radius)
	_robot_petals(fresh)
	var cov := grid.coverage()
	_hud.set_coverage(cov)
	Sfx.set_progress(cov)
	var m := floori(cov * 10.0)
	if m > _milestone:
		_milestone = m
		Sfx.play("milestone", 1.0, 0.0)
		_petals.burst(_robot.position, 90, Vector2(160, 520), Vector2(1.0, 1.8), Vector2(7, 12))
		_hud.pulse()


## Sobald die ganze Welt blüht: kurz warten (Blätterregen, Glocke), dann der Endbildschirm.
func _check_end(delta: float) -> void:
	if _end_wait >= 0.0:
		_end_wait -= delta
		if _end_wait < 0.0:
			Sfx.play("special", 1.0, 0.0)
			save()
			_end.open(_play_sec, skills.earned, skills.count_bought(), skills.order.size() - 1, _bees.bees.size())
	elif not _finished and grid.coverage() >= Game.num("end/coverage", 1.0):
		_finished = true
		_end_wait = Game.num("end/delay_sec", 2.5)
		_petals.burst(_robot.position, 200, Vector2(200, 700), Vector2(1.5, 2.5), Vector2(8, 14))


## Objekte, unter denen es grün geworden ist, erwachen (mit Klang und Blättern, wenn animate).
## Ohne Grün (Neues Spiel) schlafen sie wieder ein.
func _wake_objects(animate: bool) -> void:
	var bursts := int(_obj_cfg.get("max_bursts_per_check", 6))   # erwachen viele auf einmal: nicht jedes mit Blättern
	for o in _objects:
		var green := grid.is_green(Vector2i(o.position / cell_px))
		if green == o.awake:
			continue
		o.set_awake(green, animate)
		if green and animate and bursts > 0:
			bursts -= 1
			var big := not o.quiet
			_petals.burst(o.position, int(_obj_cfg.get("awake_petals" if big else "wayside_petals", 10)), Vector2(60, 220), Vector2(0.6, 1.2), Vector2(6, 10))
			if big:
				Sfx.play_throttled("awake", 0.15, randf_range(0.9, 1.15))


## Frisch begrünte Zellen unter dem Roboter werfen ein paar Blätter nach hinten.
func _robot_petals(fresh: int) -> void:
	if fresh <= 0 or _robot.velocity.length() < 20.0:
		return
	_petal_carry += fresh * 0.3
	var n := mini(int(_petal_carry), 4)
	_petal_carry -= n
	var back := -_robot.velocity.normalized()
	for i in n:
		var p := _robot.position + back * _robot.radius_px * 0.8 + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _robot.radius_px * 0.6
		_petals.burst(p, 1, Vector2(40, 140), Vector2(0.7, 1.2), Vector2(6, 10), back, 1.1)


## Wo eine Biene etwas erblühen ließ, fliegen ein paar Blätter.
func _bee_blooms() -> void:
	for p in _bees.blooms:
		_petals.burst(p, 6, Vector2(30, 130), Vector2(0.6, 1.1), Vector2(5, 8))
	_bees.blooms.clear()


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
			Sfx.play("close")
			_robot.input_enabled = true
			save()
		get_viewport().set_input_as_handled()
	elif _pause.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_pause.close()
			Sfx.play("close")
			get_viewport().set_input_as_handled()
	elif MenuKit.any_open(get_tree()):
		return
	elif event.is_action_pressed("upgrades"):
		_robot.input_enabled = false
		_tree.open()
		Sfx.play("open")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		save()
		_pause.open()
		Sfx.play("open")
		get_viewport().set_input_as_handled()


func reset_game() -> void:
	Engine.time_scale = 1.0
	grid.clear()
	skills.reset()
	_spread_carry = 0.0
	_milestone = 0
	_play_sec = 0.0
	_world_sec = 0.0
	grid.time_sec = 0.0
	_ground.set_time(0.0)
	_finished = false
	_end_wait = -1.0
	_bees.set_count(0)
	_robot.position = _start_px
	_robot.velocity = Vector2.ZERO
	_camera.reset_smoothing()
	_paint()
	_wake_objects(false)


# --- Rahmen: Titel, Speichern, Beenden ---

func show_title() -> void:
	save()
	Engine.time_scale = 1.0
	_hud.visible = false
	_robot.input_enabled = false
	_camera.offset = _title_offset()
	_title.open(_save_info())


## Versatz, der den Roboter unter das Titelmenü schiebt. Der Versatz umgeht die Kartengrenze
## der Kamera, deshalb wird er hier so gekürzt, dass die Ansicht auf der Karte bleibt.
func _title_offset() -> Vector2:
	var half := get_viewport_rect().size.y * 0.5 / _camera.zoom.y
	var lo := _camera.limit_top + half
	var hi := _camera.limit_bottom - half
	var center := clampf(_robot.position.y, lo, hi)
	var want := clampf(center - Game.num("camera/title_offset_px", 330.0), lo, hi)
	return Vector2(0, want - center)


func _start_playing() -> void:
	_title.close()
	_hud.visible = true
	_robot.input_enabled = true
	_autosave = 0.0
	get_tree().paused = false
	create_tween().tween_property(_camera, "offset", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Kurzinfo zum Spielstand für den Titelbildschirm ("" = noch nie gespielt).
func _save_info() -> String:
	if _play_sec <= 0.0:
		return ""
	var state := "Die Welt blüht!" if _finished else "Frühling: %s %%" % Hud.format_percent(grid.coverage())
	return "%s   ·   Spielzeit %s" % [state, EndScreen.format_time(_play_sec)]


## Packen und Schreiben (ca. 10 ms am PC) laufen in einem Hintergrund-Thread, damit das
## automatische Speichern kein Bild verschluckt. Die Zellen werden vorher kopiert.
func save() -> void:
	_autosave = 0.0
	if _play_sec <= 0.0:
		return   # noch nicht gespielt: nichts zu sichern
	finish_saving()
	var data := {
		"game_version": Game.version(),
		"play_sec": _play_sec,
		"world_sec": _world_sec,
		"finished": _finished or _end_wait >= 0.0,
		"robot": [_robot.position.x, _robot.position.y],
		"grid": {"w": grid.width, "h": grid.height},
		"skills": skills.to_dict(),
	}
	var cells := grid.cells.duplicate()
	var since := grid.since.duplicate()
	_save_task = WorkerThreadPool.add_task(func() -> void:
		data["grid"]["cells"] = Marshalls.raw_to_base64(cells.compress(FileAccess.COMPRESSION_DEFLATE))
		data["grid"]["since"] = Marshalls.raw_to_base64(since.compress(FileAccess.COMPRESSION_DEFLATE))
		_store.write(data))


## Wartet, bis ein laufendes Speichern fertig ist (vor dem Beenden).
func finish_saving() -> void:
	if _save_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_save_task)
		_save_task = -1


## Übernimmt einen Spielstand. Leer oder unpassend = frisches Spiel.
func load_game(data: Dictionary) -> void:
	reset_game()
	var g: Dictionary = data.get("grid", {})
	var fits := int(g.get("w", 0)) == grid.width and int(g.get("h", 0)) == grid.height
	if not fits or not grid.load_bytes(Marshalls.base64_to_raw(str(g.get("cells", "")))):
		if not data.is_empty():
			push_warning("Spielstand passt nicht zur Karte, neues Spiel")
		_paint()
		return
	grid.load_since(Marshalls.base64_to_raw(str(g.get("since", ""))))
	skills.from_dict(data.get("skills", {}))
	_play_sec = float(data.get("play_sec", 0.0))
	_world_sec = float(data.get("world_sec", _play_sec))
	grid.time_sec = _world_sec
	_ground.set_time(_world_sec)
	_finished = bool(data.get("finished", false))
	var r: Array = data.get("robot", [])
	if r.size() == 2:
		_robot.position = Vector2(float(r[0]), float(r[1])).clamp(_robot.bounds.position, _robot.bounds.end)
		if not _robot.can_stand(_robot.position):
			_robot.position = _start_px   # alter Spielstand: Platz liegt jetzt im Wasser
	_camera.reset_smoothing()
	_milestone = floori(grid.coverage() * 10.0)
	_paint()
	_wake_objects(false)


func quit() -> void:
	save()
	finish_saving()
	Sfx.quit_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		finish_saving()
