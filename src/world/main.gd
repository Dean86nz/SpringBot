extends Node2D
## Hauptszene: Raster, Boden, Roboter, Kamera, HUD, Menüs und (nur Debug) Cheat-Menü.
## Jedes Bild begrünt der Roboter die Zellen in seinem Radius; grüne Zellen bringen Pollen.
## Mit den Wachstums-Knoten wächst die Grenze des Grüns von allein weiter,
## Bienen tragen das Grün zu neuen Stellen, Samenvögel (ab Felder und Vorort) säen ganze Streifen.
## Alle Werte kommen aus dem Skilltree.
## Regionen (Phase 3): data/campaign.json sagt, welche Regionen es gibt; die Daten der aktuellen Region
## liegen in ihrem Ordner (Campaign). Der Spielstand hat je Region einen Eintrag, Skills gelten für alle.
## Reisen (TravelScreen): speichern, Zielregion im Spielstand vermerken, Hauptszene neu laden (Game.arrival).
## Fertige Regionen bringen weiter einen Teil ihrer Pollen (campaign.json "finished_pollen_share").
## Wege, Flüsse und Brücken kommen aus world.json der Region (WorldMap); sie werden nie grün.
## Dürre Stellen (region.json "dry"): Dort wächst nichts von allein, Bienen schaffen nichts, nur Roboter und Samenvögel.
## Objekte (Bäume, Teiche, Büsche, Felsen, Wegrand) aus objects.json der Region erwachen, sobald unter
## ihnen Grün ist; um Bäume und Felsen fährt der Roboter herum.
## Gebiete (areas.json der Region) geben Boden und Objekten ihren Charakter; beim Betreten eines
## Gebiets blendet das HUD dezent seinen Namen ein.
## Großstadt: region.json "structures" sind feste Gebäude ohne Bewohner (erwachen mit dem Grün unter ihnen).
## Gärtner-Drohnen (GardenDrones) fliegen von der Ladestation (dock_cell) Runden über graue Höfe und Dächer.
## Dorf (region.json "village"): Gebäude (Wohnhäuser, Kirche mit Friedhof, Schule, Bücherei, Laden, Schmiede,
## Hof), Felder, Wäscheleine und Brunnen stehen fest. Die Gebäude bleiben kaputt, bis die Bewohner (Villagers)
## sie reparieren; die kehren nach und nach zurück, sobald um ihr Haus Grün und genug wiederhergestellt ist.
## Ist die Region fertig, gibt es ein Fest auf dem Dorfplatz; danach der Endbildschirm der Region.
## Tiere (data/animals.json) leben als Deko nahe der Kamera über dem Grün (Animals, AnimalView).
## Einführung (data/tutorial.json): beim Neuen Spiel eine kurze Einleitung (IntroScreen), im Spiel
## Hinweise genau einmal im richtigen Moment (Tutorial), Tasten passend zum Gerät (KeyHints).
## Läuft auch während der Pause (Menü-Eingaben), Roboter und Boden pausieren.
## Rahmen: Start mit Titelbildschirm (dahinter der gespeicherte Garten), Speichern alle
## paar Sekunden und bei jedem Menü, Endbildschirm, sobald die ganze Welt blüht.

const CAMPAIGN_PATH := "res://data/campaign.json"
const ANIMALS_PATH := "res://data/animals.json"

var grid: GroundGrid
var campaign: Campaign
var region_id := ""          # aktuelle Region
var _region_saves: Dictionary = {}   # Spielstand-Einträge der übrigen Regionen, unverändert weitergereicht
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
var _birds := SeedBirds.new()
var _bird_view := BirdView.new()
var _bird_speed := 1.0
var _bird_base: Dictionary = {}   # Grundwerte der Samenvögel (Streifen, Breite, Rast)
var _nest_blocks := false         # Vogelhäuschen steht (Hindernis für den Roboter)
var _drones := GardenDrones.new()
var _drone_view := DroneView.new()
var _drone_speed := 1.0
var _drone_base: Dictionary = {}  # Grundwerte der Drohnen (Fläche, Sprühkreis, Laden)
var _dock_blocks := false
var _start_px := Vector2.ZERO
var _ground := GroundView.new()
var _bridge_view := BridgeView.new()
var _objects: Array[WorldObject] = []
var _obj_cfg: Dictionary = {}
var _awake_timer := 0.0
var _areas: Areas
var _area_watch := Areas.Watch.new()
var _animals: Animals
var _animal_view := AnimalView.new()
var _ponds: Array[WorldObject] = []   # gleiche Reihenfolge wie _animals.ponds
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
var _intro := IntroScreen.new()
var _region_intro := IntroScreen.new()   # Ankunft in einer neuen Region
var _travel := TravelScreen.new()
var _next_region := ""       # beim nächsten Speichern als aktuelle Region vermerken (Reise)
var _bonus_cells := 0.0      # Pollen-Zellen aus fertigen anderen Regionen
var _map := MapScreen.new()
var _map_from_pause := false   # Karte aus dem Pause-Menü geöffnet: beim Schließen dorthin zurück
var _hive_px := Vector2.ZERO
var _tutorial: Tutorial
var _tip_id := ""            # gerade sichtbarer Hinweis
var _tip_from := Vector2.ZERO   # Roboterposition beim Einblenden (Fahr-Hinweis endet nach etwas Weg)
var _store := SaveStore.new()
var _play_sec := 0.0         # Spielzeit in echten Sekunden (ohne Pause und Menüs)
var _world_sec := 0.0        # Spielzeit der Welt (läuft mit Zeit ×10 schneller), für „seit wann grün“
var _finished := false       # Ende schon erreicht (Endbildschirm kommt nur einmal)
var _region_info: Dictionary = {}   # region.json der aktuellen Region
var _village: Dictionary = {}       # region.json "village", leer = Region ohne Dorf
var _villagers: Villagers
var _village_by_id: Dictionary = {}   # Gebäude-id → WorldObject (erwacht?)
var _villager_view := VillagerView.new()
var _fest_petals := 0.0
var _end_wait := -1.0        # Sekunden bis zum Endbildschirm, < 0 = keiner geplant
var _autosave := 0.0
var _save_task := -1         # WorkerThreadPool-Aufgabe, die gerade schreibt


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	campaign = Campaign.new(Game.load_json(CAMPAIGN_PATH))
	var saved := SaveStore.migrate(_store.read(), campaign.start)
	region_id = str(saved.get("region", campaign.start))
	if not campaign.has(region_id):
		push_warning("Region %s unbekannt, Start in %s" % [region_id, campaign.start])
		region_id = campaign.start
	var rdata := campaign.load_region(region_id)
	var region: Dictionary = rdata["region"]
	_region_info = region
	_village = region.get("village", {})
	var w := int(region.get("width_cells", 640))
	var h := int(region.get("height_cells", 480))
	cell_px = Game.num("map/cell_px", 24)
	_base_radius = Game.num("robot/green_radius_cells", 3.0)
	_base_speed = Game.num("robot/speed_px", 380.0)
	grid = GroundGrid.new(w, h)
	grid.hop_cells = int(Game.num("map/spread_hop_cells", 12))
	var t0 := Time.get_ticks_msec()
	var world_data: Dictionary = rdata["world"]
	var bridges := WorldMap.build(grid, world_data)
	var dry_cells := WorldMap.build_dry(grid, region.get("dry", {}))
	print("Wege und Wasser: %d Brücken, %d dürre Zellen, %d ms" % [bridges.size(), dry_cells, Time.get_ticks_msec() - t0])
	var areas_data: Dictionary = rdata["areas"]
	_areas = Areas.new(w, h, areas_data)
	var banner: Dictionary = areas_data.get("banner", {})
	_area_watch.confirm_sec = float(banner.get("confirm_sec", 1.0))
	var tree_data := Game.load_json(Game.SKILLTREE_PATH)
	skills = SkillTree.new(tree_data)
	_spread_cap = int(tree_data.get("spread_max_events_per_frame", 3000))
	skills.changed.connect(_apply_upgrades)
	var size_px := Vector2(w, h) * cell_px
	_start_px = Campaign.cell_px(region, "start_cell", cell_px, size_px * 0.5)

	_ground.process_mode = Node.PROCESS_MODE_ALWAYS   # zeigt den geladenen Garten auch hinter dem Titel
	var ground_cfg: Variant = Game.dig(Game.balance, "ground")
	var gcfg: Dictionary = (ground_cfg as Dictionary).duplicate() if ground_cfg is Dictionary else {}
	gcfg.merge(region.get("ground", {}), true)   # z. B. Asphalt in der Großstadt
	_ground.bind(grid, cell_px, gcfg, _areas)
	add_child(_ground)
	_bridge_view.bind(bridges, cell_px)
	add_child(_bridge_view)
	var hive_px := Campaign.cell_px(region, "hive_cell", cell_px, _start_px)
	_hive_px = hive_px
	_bees.configure(Game.dig(Game.balance, "bees") if Game.dig(Game.balance, "bees") is Dictionary else {}, hive_px, cell_px)
	_base_bloom = _bees.bloom_radius
	_base_hover = _bees.hover_sec
	var nest_px := Campaign.cell_px(region, "nest_cell", cell_px, hive_px + Vector2(-90, 60))
	var bird_cfg: Variant = Game.dig(Game.balance, "birds")
	_birds.configure(bird_cfg if bird_cfg is Dictionary else {}, nest_px, cell_px)
	_bird_base = {"strip": _birds.strip_cells, "width": _birds.width_cells, "rest": _birds.rest_sec}
	var dock_px := Campaign.cell_px(region, "dock_cell", cell_px, hive_px + Vector2(0, 110))
	var drone_cfg: Variant = Game.dig(Game.balance, "drones")
	_drones.configure(drone_cfg if drone_cfg is Dictionary else {}, dock_px, cell_px)
	_drone_base = {"area": _drones.area_cells, "spray": _drones.spray_cells, "charge": _drones.charge_sec}
	_obj_cfg = rdata["objects"]
	var blockers: Array[Dictionary] = []
	var avoid: Array[Dictionary] = []   # wo keine Hasen hoppeln
	var places := {}
	var fixed := _village_objects(places)
	var village_fixed := fixed.duplicate()
	fixed.append_array(_structure_objects(region.get("structures", {})))
	for d in WorldObjects.place(grid, cell_px, _obj_cfg, world_data, [_start_px, hive_px, nest_px, dock_px], _areas, fixed):
		var o := WorldObject.new()
		o.setup(d)
		add_child(o)
		_objects.append(o)
		if d.has("blockers"):   # lange Gebäude: mehrere Kreise entlang der Längsachse
			blockers.append_array(d["blockers"])
		elif float(d["block"]) > 0.0:
			blockers.append({"pos": d["pos"], "radius": float(d["block"])})
		if d["kind"] == "pond":
			_ponds.append(o)
		if d.has("id"):
			_village_by_id[d["id"]] = o
		if not d["quiet"]:
			avoid.append({"pos": d["pos"], "radius": float(d["radius"]) * 0.8})
	print("Objekte: %d, davon %d Hindernisse, %d ms" % [_objects.size(), blockers.size(), Time.get_ticks_msec() - t0])
	_animals = Animals.new(grid, cell_px, Game.load_json(ANIMALS_PATH))
	for o in _ponds:
		_animals.ponds.append({"pos": o.position, "angle": o.angle, "size": o.scale.x, "awake": false})
	_animals.avoid = avoid
	_villagers = Villagers.new(_village, cell_px, places, hive_px)
	_villagers.ready = _building_green
	for wp: Dictionary in world_data.get("paths", []):   # Wege für die Wanderer, ein Punkt etwa alle 3 Zellen
		var line := WorldMap.curve(wp)
		var px := PackedVector2Array()
		for i in range(0, line.size(), 3):
			px.append(line[i] * cell_px)
		if px.size() > 4:
			_villagers.trails.append(px)
	for d in fixed:   # Gebäude der Stadt nur in der Nähe des Dorfes (jeder Schritt prüft alle Hindernisse)
		if float(d["block"]) > 0.0 and (village_fixed.has(d) or d["pos"].distance_to(_villagers.center) < 140.0 * cell_px):
			_villagers.obstacles.append({"pos": d["pos"], "r": float(d["block"])})
	_villagers.obstacles.append({"pos": hive_px, "r": Game.num("bees/hive_radius_px", 32.0)})
	_villager_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_villager_view.bind(_villagers)
	add_child(_villager_view)
	_animal_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_animal_view.bind(_animals)
	add_child(_animal_view)
	_bee_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_bee_view.bind(_bees)
	add_child(_bee_view)
	_bird_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_bird_view.bind(_birds)
	add_child(_bird_view)
	_drone_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	_drone_view.bind(_drones)
	add_child(_drone_view)
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
	_hud.banner_cfg = banner
	add_child(_hud)
	_tree.setup(skills)
	add_child(_tree)
	var tut_data := Game.load_json(Game.TUTORIAL_PATH)
	_tutorial = Tutorial.new(tut_data)
	_pause.controls = tut_data.get("controls", [])
	_intro.setup(tut_data.get("intro", []))
	_intro.finished.connect(func() -> void:
		_start_playing()
		if not _intro.skipped:   # „Los geht's!“: kleiner Blütenregen um den Roboter
			_petals.burst(_robot.position, 70, Vector2(120, 420), Vector2(1.0, 1.8), Vector2(7, 12)))
	add_child(_intro)
	_map.setup(_ground, _areas, size_px, Vector2(w, h))
	_map.closed.connect(func() -> void:
		if _map_from_pause:
			_pause.open()
		else:
			get_tree().paused = false)
	add_child(_map)
	_travel.travel_chosen.connect(func(id: String) -> void: travel_to(id))
	_travel.closed.connect(func() -> void:
		if _end.visible:
			_end.refocus()
		else:
			_pause.open())
	add_child(_travel)
	_pause.travel_requested.connect(func() -> void:
		_pause.visible = false
		_open_travel())
	_end.travel_requested.connect(_open_travel)
	_region_intro.setup([_region_info.get("intro", {})] if _region_info.has("intro") else [])
	_region_intro.finished.connect(_start_playing)
	add_child(_region_intro)
	_pause.map_requested.connect(func() -> void:
		_pause.visible = false
		_open_map(true))
	_pause.title_requested.connect(show_title)
	_pause.quit_requested.connect(quit)
	add_child(_pause)
	_end.title_requested.connect(show_title)
	_end.closed.connect(_end_fest)
	_end.set_texts(str(region.get("finished_title", "Die Welt blüht wieder!")), str(region.get("finished_text", "")))
	add_child(_end)
	_title.continue_requested.connect(_start_playing)
	_title.new_game_requested.connect(func() -> void:
		reset_game()
		if region_id != campaign.start:   # neues Spiel beginnt immer in der ersten Region
			travel_to(campaign.start, "new_game")
			return
		save(true)
		_title.close()
		_intro.open())
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
	load_game(saved)
	var arrival := Game.arrival
	Game.arrival = ""
	match arrival:
		"travel": _arrive()
		"new_game":
			_title.close()
			_intro.open()
		_: show_title()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_paint()
	_spread(delta)
	_bees.update(delta, grid, _rng, _bee_speed)
	_bee_blooms()
	if not _birds.flocks.is_empty():
		_birds.update(delta, grid, _rng, _bird_speed)
		for p in _birds.blooms:   # wo die Saat aufgeht, ein paar Blätter
			_petals.burst(p, 3, Vector2(30, 120), Vector2(0.6, 1.0), Vector2(5, 8))
		_birds.blooms.clear()
	if not _drones.drones.is_empty():
		_drones.update(delta, grid, _rng, _drone_speed)
		for p in _drones.blooms:
			_petals.burst(p, 3, Vector2(30, 120), Vector2(0.6, 1.0), Vector2(5, 8))
		_drones.blooms.clear()
	var cells := grid.green_count + int(_bonus_cells)   # fertige andere Regionen bringen auch Pollen
	skills.tick(delta, cells)
	_hud.set_pollen(skills.pollen, skills.rate(cells))
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
	_animals.update(delta, _view_rect(), _robot.position)
	if not _villagers.people.is_empty():
		_villagers.update(delta)
		for id in _villagers.repaired:   # fertig repariert: Gebäude erwacht
			var o: WorldObject = _village_by_id.get(id)
			if o and not o.awake:
				o.set_awake(true, true)
				_petals.burst(o.position, int(_obj_cfg.get("awake_petals", 24)), Vector2(60, 220), Vector2(0.6, 1.2), Vector2(6, 10))
				Sfx.play_grouped("awake")
		_villagers.repaired.clear()
	if _area_watch.update(_areas.at_px(_robot.position, cell_px), real):
		_hud.show_area(_areas.name_of(_area_watch.current))
	_update_tips(real)
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
		if m < 10:   # bei 100 % übernimmt das Fest (kein Jingle obendrauf)
			Sfx.play("milestone", 1.0, 0.0)
		_petals.burst(_robot.position, 90, Vector2(160, 520), Vector2(1.0, 1.8), Vector2(7, 12))
		_hud.pulse()


## Sobald die ganze Welt blüht: kurz warten (Blätterregen, Glocke), dann der Endbildschirm.
func _check_end(delta: float) -> void:
	if _end_wait >= 0.0:
		_end_wait -= delta
		if not _village.is_empty():
			_fest_burst(delta)
		if _end_wait < 0.0:
			save()
			_end.open(_play_sec, skills.earned, skills.count_bought(), skills.order.size() - 1, _bees.bees.size())
	elif not _finished and grid.coverage() >= Game.num("end/coverage", 1.0):
		_finished = true
		_end_wait = Game.num("end/delay_sec", 2.5)
		_petals.burst(_robot.position, 200, Vector2(200, 700), Vector2(1.5, 2.5), Vector2(8, 14))
		if not _village.is_empty():
			_start_fest()


## Gebäude, Requisiten und Brunnen des Dorfes als feste Objekte (Format wie WorldObjects.place).
## Gebäude drehen ihre Vorderseite zum Platz (oder zum Punkt "face"); davor liegt die Tür. places bekommt je id Lage, Tür,
## Art und Drehung (für die Bewohner).
func _village_objects(places: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _village.is_empty():
		return out
	var c: Array = _village.get("center", [0, 0])
	var center := (Vector2(c[0], c[1]) + Vector2(0.5, 0.5)) * cell_px
	var types: Dictionary = _village.get("types", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var all: Array = (_village.get("buildings", []) as Array) + (_village.get("props", []) as Array)
	for b: Dictionary in all:
		var kind := str(b.get("type", "house"))
		var t: Dictionary = types.get(kind, {})
		var pos := (Vector2(b["pos"][0], b["pos"][1]) + Vector2(0.5, 0.5)) * cell_px
		var sz: Array = t.get("size", [1.0, 1.0])
		var f := rng.randf_range(float(sz[0]), float(sz[1]))
		var face := center
		if b.get("face") is Array:   # eigene Blickrichtung (z. B. zum Hof statt zum fernen Dorfplatz)
			face = (Vector2(b["face"][0], b["face"][1]) + Vector2(0.5, 0.5)) * cell_px
		var to_plaza := (face - pos).normalized()
		var rot := 0.0 if kind in ["field", "laundry", "garden", "windmill", "silo"] else to_plaza.angle() - PI / 2.0
		if b.has("rot"):   # feste Drehung in Grad (z. B. zur Straße in der Großstadt)
			rot = deg_to_rad(float(b["rot"]))
		var block := float(t.get("block", 50.0)) * f
		out.append({"id": str(b["id"]), "kind": kind, "pos": pos, "angle": rot, "seed": rng.randi(),
			"block": block, "radius": float(t.get("radius", 76.0)) * f, "size": f, "quiet": kind in ["field", "laundry", "stand", "garden"]})
		if kind == "apartment":
			out[out.size() - 1]["blockers"] = _building_blockers(kind, pos, rot, f, block)
		places[str(b["id"])] = {"pos": pos, "type": kind, "angle": rot, "block": block, "radius": float(t.get("radius", 76.0)) * f, "size": f,
			"door": pos + Vector2(0, block + 16.0).rotated(rot) if block > 0.0 else pos + Vector2(0, 30)}
	var fo: Variant = _village.get("fountain")
	if fo is Array:
		out.append({"kind": "fountain", "pos": (Vector2(fo[0], fo[1]) + Vector2(0.5, 0.5)) * cell_px, "angle": 0.0,
			"seed": 5, "block": 46.0, "radius": 60.0, "size": 1.0, "quiet": false})
	return out


## Gebäude der Stadt (region.json "structures"): feste Objekte ohne Bewohner; sie erwachen mit dem Grün
## unter ihnen. rot = Drehung in Grad (Vorderseite zur Straße).
func _structure_objects(cfg: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var types: Dictionary = cfg.get("types", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for b: Dictionary in cfg.get("list", []):
		var kind := str(b.get("type", "apartment"))
		var t: Dictionary = types.get(kind, {})
		var sz: Array = t.get("size", [1.0, 1.0])
		var f := rng.randf_range(float(sz[0]), float(sz[1]))
		var pos := (Vector2(b["pos"][0], b["pos"][1]) + Vector2(0.5, 0.5)) * cell_px
		var ang := deg_to_rad(float(b.get("rot", 0.0)))
		var d := {"kind": kind, "pos": pos, "angle": ang, "seed": rng.randi(), "block": float(t.get("block", 60.0)) * f,
			"radius": float(t.get("radius", 90.0)) * f, "size": f, "quiet": false}
		d["blockers"] = _building_blockers(kind, pos, ang, f, float(d["block"]))
		out.append(d)
	return out


## Hinderniskreise eines Gebäudes: ein Wohnblock bekommt drei Kreise entlang seiner Längsachse.
func _building_blockers(kind: String, pos: Vector2, ang: float, f: float, block: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if kind == "apartment":
		var e := WorldObject.APARTMENT * f
		for k in [-1.0, 0.0, 1.0]:
			out.append({"pos": pos + Vector2(k * (e.x - e.y), 0).rotated(ang), "radius": e.y})
	else:
		out.append({"pos": pos, "radius": block})
	return out


## Region fertig: Kamera schwenkt zum Dorf, alle treffen sich auf dem Platz, sanftes Glockenspiel, Banner.
func _start_fest() -> void:
	_end_wait = float(_village.get("fest_sec", 9.0))
	_villagers.set_festive(true)
	_robot.input_enabled = false
	_hud.hide_tip()
	var to := _villagers.center - _robot.position
	create_tween().tween_property(_camera, "offset", to, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Sfx.play("fest", 1.0, 0.0)
	_hud.show_banner(str(_region_info.get("finished_banner", "")), float(_village.get("fest_sec", 9.0)) - 1.0)


## Während des Festes fliegen über dem Dorfplatz Blüten.
func _fest_burst(delta: float) -> void:
	_fest_petals += float(_village.get("fest_petals_per_sec", 40.0)) * delta
	while _fest_petals >= 1.0:
		_fest_petals -= 1.0
		var p := _villagers.center + Vector2.from_angle(randf() * TAU) * randf() * _villagers.plaza_r * 1.6
		_petals.burst(p, 1, Vector2(60, 220), Vector2(1.0, 1.8), Vector2(7, 12))


## Endbildschirm zu: Kamera zurück zum Roboter, weiterfahren; die Bewohner gehen wieder an die Arbeit.
func _end_fest() -> void:
	_robot.input_enabled = true
	_villagers.set_festive(false)
	create_tween().tween_property(_camera, "offset", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Grün unter dem Objekt? Steht es nicht auf Land (Brunnen auf dem Dorfplatz), zählt das nächste Land
## in acht Richtungen: Ist dort irgendwo Grün, erwacht es.
func _green_under(pos: Vector2) -> bool:
	var c := Vector2i(pos / cell_px)
	if not grid.in_bounds(c) or grid.terrain[c.y * grid.width + c.x] == GroundGrid.LAND:
		return grid.is_green(c)
	for k in 8:
		var d := Vector2.from_angle(k * TAU / 8.0)
		for s in range(1, 16):
			var q := c + Vector2i((d * s).round())
			if not grid.in_bounds(q):
				break
			if grid.terrain[q.y * grid.width + q.x] == GroundGrid.LAND:
				if grid.is_green(q):
					return true
				break
	return false


## Objekte, unter denen es grün geworden ist, erwachen (mit Klang und Blättern, wenn animate).
## Ohne Grün (Neues Spiel) schlafen sie wieder ein.
func _wake_objects(animate: bool) -> void:
	var bursts := int(_obj_cfg.get("max_bursts_per_check", 6))   # erwachen viele auf einmal: nicht jedes mit Blättern
	for o in _objects:
		var green := _villagers.is_done(o.vid) if o.vid != "" else _green_under(o.position)
		if green == o.awake:
			continue
		o.set_awake(green, animate)
		if green and animate and bursts > 0:
			bursts -= 1
			var big := not o.quiet
			_petals.burst(o.position, int(_obj_cfg.get("awake_petals" if big else "wayside_petals", 10)), Vector2(60, 220), Vector2(0.6, 1.2), Vector2(6, 10))
			if big:
				Sfx.play_grouped("awake")
	for k in _ponds.size():
		_animals.ponds[k]["awake"] = _ponds[k].awake
	_villagers.update_return(grid.coverage(), _building_green, not animate)
	# Bienen ohne Arbeit besuchen erwachte Bäume und Büsche nahe dem Stock
	_bees.trees.clear()
	for o in _objects:
		if o.awake and o.kind in ["oak", "fruit", "birch", "willow", "bush", "sapling"] and o.position.distance_to(_bees.hive) < _bees.idle_radius * cell_px:
			_bees.trees.append(o.position)


## Grün unter einem Gebäude des Dorfes: dann kann es repariert werden und seine Bewohner kommen.
func _building_green(id: String) -> bool:
	var o: WorldObject = _village_by_id.get(id)
	return o != null and _green_under(o.position)


## Reisekarte mit allen Regionen: fertig, aktuell, frei (die vorige blüht), gesperrt, später.
func _open_travel() -> void:
	var st: Array[Dictionary] = []
	var prev_done := true
	var prev_name := ""
	for id in campaign.order:
		var info: Dictionary = campaign.load_region(id)["region"] if id != region_id else _region_info
		var e: Dictionary = _region_saves.get(id, {})
		var done := _finished if id == region_id else bool(e.get("finished", false))
		var progress := grid.coverage() if id == region_id else float(e.get("green_cells", 0)) / maxf(float(e.get("land_cells", 1)), 1.0)
		var state := "current" if id == region_id else ("done" if done else ("open" if prev_done else "locked"))
		st.append({"id": id, "name": str(info.get("name", id)), "state": state, "progress": progress, "needs": prev_name})
		prev_done = done
		prev_name = str(info.get("name", id))
	for n in campaign.planned:
		st.append({"id": "", "name": n, "state": "planned"})
	_travel.open(st)


## In eine andere Region reisen: Stand sichern (Ziel als aktuelle Region), Hauptszene neu laden.
func travel_to(id: String, arrival: String = "travel") -> void:
	if not campaign.has(id):
		return
	_next_region = id
	save(true)
	finish_saving()
	Game.arrival = arrival
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


## Angereist: beim ersten Besuch die kurze Einleitung der Region, sonst gleich los; großer Name als Banner.
func _arrive() -> void:
	_title.close()
	var first := not (_region_saves.get(region_id, {}) as Dictionary).has("grid")
	if first and _region_info.has("intro"):
		_region_intro.open()
	else:
		_start_playing()
	_hud.show_banner(str(_region_info.get("name", "")), 4.0)


func _open_map(from_pause: bool) -> void:
	_map_from_pause = from_pause
	Sfx.play("open")
	_map.open(_robot.position, _hive_px, grid.coverage())


## Hinweise der Einführung: der fällige wird eingeblendet; der Fahr-Hinweis verschwindet,
## sobald der Roboter ein Stück gefahren ist, der Skilltree-Hinweis beim Öffnen des Skilltrees.
func _update_tips(delta: float) -> void:
	if _tip_id == "move" and _robot.position.distance_to(_tip_from) > float(_tutorial.hints.get("move", {}).get("done_px", 400.0)):
		_hud.hide_tip()
	if not _hud.tip_visible():
		_tip_id = ""
	var branch := str(_tutorial.hints.get("birds_branch", {}).get("node", ""))
	var ctx := {"can_buy": not _tutorial.seen.has("tree") and _first_buy_possible(), "bees": _bees.bees.size(),
		"birds": _birds.flocks.size(),
		"drones": _drones.drones.size(),
		"drones_branch": _branch_open("drones_branch"),
		"dry": grid.is_dry(Vector2i(_robot.position / cell_px)) and not grid.is_green(Vector2i(_robot.position / cell_px)),
		"birds_branch": _branch_open("birds_branch"),
		"quiet": _tip_id != "" or not _hud.visible or MenuKit.any_open(get_tree()) or _end_wait >= 0.0}
	var id := _tutorial.due(ctx, delta)
	if id != "":
		_tip_id = id
		_tip_from = _robot.position
		_hud.show_tip(_tutorial.text(id), _tutorial.show_sec(id))


## Ist der Ast zum Hinweis id (tutorial.json "node") erreichbar, aber noch nichts davon gekauft?
func _branch_open(id: String) -> bool:
	var node := str(_tutorial.hints.get(id, {}).get("node", ""))
	return skills.nodes.has(node) and not skills.is_gated(node) and skills.level(node) == 0


func _first_buy_possible() -> bool:
	for id in skills.order:
		if skills.can_buy(id):
			return true
	return false


## Sichtbarer Ausschnitt der Welt in Pixeln.
func _view_rect() -> Rect2:
	var size := get_viewport_rect().size / _camera.zoom
	return Rect2(_camera.get_screen_center_position() - size * 0.5, size)


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
	_birds.set_count(int(skills.stat("birds")))
	_bird_speed = 1.0 + skills.stat("bird_speed") / 100.0
	_birds.strip_cells = float(_bird_base["strip"]) + skills.stat("strip")
	_birds.width_cells = float(_bird_base["width"]) + skills.stat("strip_width")
	_birds.rest_sec = float(_bird_base["rest"]) * clampf(1.0 - skills.stat("bird_rest") / 100.0, 0.1, 1.0)
	_drones.set_count(int(skills.stat("drones")))
	_drone_speed = 1.0 + skills.stat("drone_speed") / 100.0
	_drones.area_cells = float(_drone_base["area"]) + skills.stat("drone_area")
	_drones.spray_cells = float(_drone_base["spray"]) + skills.stat("drone_spray")
	_drones.charge_sec = float(_drone_base["charge"]) * clampf(1.0 - skills.stat("drone_charge") / 100.0, 0.1, 1.0)
	var dock_on := not _drones.drones.is_empty()
	if dock_on != _dock_blocks:   # die Station steht erst mit der ersten Drohne
		_dock_blocks = dock_on
		var db := {"pos": _drones.dock, "radius": Game.num("drones/dock_radius_px", 44.0)}
		if dock_on:
			_robot.obstacles.append(db)
		else:
			_robot.obstacles.erase(db)
	var nest_on := not _birds.flocks.is_empty()
	if nest_on != _nest_blocks:   # das Häuschen steht erst mit dem ersten Schwarm
		_nest_blocks = nest_on
		var ob := {"pos": _birds.nest, "radius": Game.num("birds/nest_radius_px", 26.0)}
		if nest_on:
			_robot.obstacles.append(ob)
		else:
			_robot.obstacles.erase(ob)


## Menüs öffnen und schließen. Das Cheat-Menü verwaltet sich selbst.
func _unhandled_input(event: InputEvent) -> void:
	if _tree.visible:
		if event.is_action_pressed("upgrades") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_tree.close()
			Sfx.play("close")
			_robot.input_enabled = true
			save()
		get_viewport().set_input_as_handled()
	elif _map.visible:
		if event.is_action_pressed("map") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			Sfx.play("close")
			_map.close()
			get_viewport().set_input_as_handled()
	elif _pause.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			if _pause.on_subpage() and not event.is_action_pressed("pause"):
				_pause.back()
			else:
				_pause.close()
				Sfx.play("close")
			get_viewport().set_input_as_handled()
	elif MenuKit.any_open(get_tree()):
		return
	elif event.is_action_pressed("upgrades"):
		_robot.input_enabled = false
		_tree.open()
		Sfx.play("open")
		_tutorial.first("tree")   # schon gefunden: der Hinweis zum Öffnen kommt nicht mehr
		for hint in ["birds_branch", "drones_branch"]:   # neuer Ast schon gesehen
			var branch := str(_tutorial.hints.get(hint, {}).get("node", ""))
			if skills.nodes.has(branch) and not skills.is_gated(branch):
				_tutorial.first(hint)
		if _tip_id in ["tree", "birds_branch", "drones_branch"]:
			_hud.hide_tip()
		if _tutorial.first("tree_help"):
			_tree.show_help(_tutorial.text("tree_help"), _tutorial.show_sec("tree_help"))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		_open_map(false)
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
	_birds.set_count(0)
	_drones.set_count(0)
	_drones.mist.clear()
	_drones.blooms.clear()
	_birds.seeds.clear()
	_birds.blooms.clear()
	_animals.clear()
	_villagers.clear()
	_villager_view.queue_redraw()   # auch in der Pause (Titel, Einleitung): altes Bild der Bewohner löschen
	_region_saves.clear()   # Neues Spiel: alle Regionen von vorn
	skills.regions.assign([region_id])
	_tutorial.reset()
	_tip_id = ""
	_hud.hide_tip()
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
	_area_watch.reset()   # Name des Gebiets nach dem Titel zeigen
	get_tree().paused = false
	create_tween().tween_property(_camera, "offset", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Kurzinfo zum Spielstand für den Titelbildschirm ("" = noch nie gespielt).
func _save_info() -> String:
	if _play_sec <= 0.0:
		return ""
	var state := "ganz wiederhergestellt" if _finished else "Wiederhergestellt: %s %%" % Hud.format_percent(grid.coverage())
	return "%s   ·   %s   ·   Spielzeit %s" % [str(_region_info.get("name", "")), state, EndScreen.format_time(_play_sec)]


## Packen und Schreiben (ca. 10 ms am PC) laufen in einem Hintergrund-Thread, damit das
## automatische Speichern kein Bild verschluckt. Die Zellen werden vorher kopiert.
## force: auch ohne Spielzeit speichern (Reise, neues Spiel in einer anderen Region).
func save(force: bool = false) -> void:
	_autosave = 0.0
	if _play_sec <= 0.0 and not force:
		return   # noch nicht gespielt: nichts zu sichern
	finish_saving()
	var data := {
		"game_version": Game.version(),
		"play_sec": _play_sec,
		"world_sec": _world_sec,
		"skills": skills.to_dict(),
		"tutorial": _tutorial.to_list(),
		"region": _next_region if _next_region != "" else region_id,
	}
	var regions := _region_saves.duplicate()   # andere Regionen bleiben, wie sie geladen wurden
	var entry := {
		"finished": _finished or _end_wait >= 0.0,
		"robot": [_robot.position.x, _robot.position.y],
		"grid": {"w": grid.width, "h": grid.height},
		"repaired": _villagers.done_ids(),
		"green_cells": grid.green_count,
		"land_cells": grid.total(),
	}
	regions[region_id] = entry
	data["regions"] = regions
	var cells := grid.cells.duplicate()
	var since := grid.since.duplicate()
	var sown := grid.sown.duplicate()
	_save_task = WorkerThreadPool.add_task(func() -> void:
		entry["grid"]["cells"] = Marshalls.raw_to_base64(cells.compress(FileAccess.COMPRESSION_DEFLATE))
		entry["grid"]["since"] = Marshalls.raw_to_base64(since.compress(FileAccess.COMPRESSION_DEFLATE))
		entry["grid"]["sown"] = Marshalls.raw_to_base64(sown.compress(FileAccess.COMPRESSION_DEFLATE))
		_store.write(data))


## Wartet, bis ein laufendes Speichern fertig ist (vor dem Beenden).
func finish_saving() -> void:
	if _save_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_save_task)
		_save_task = -1


## Übernimmt einen Spielstand (alte Stände vorher mit SaveStore.migrate anheben). Leer = frisches Spiel.
## Skills, Pollen, Spielzeit und Einführung gelten für alle Regionen; hat die aktuelle Region noch keinen
## Eintrag (gerade angereist), beginnt sie frisch.
func load_game(data: Dictionary) -> void:
	reset_game()
	_region_saves = (data.get("regions", {}) as Dictionary).duplicate()
	var entry: Dictionary = _region_saves.get(region_id, {})
	var reached: Array[String] = [region_id]   # erreichte Regionen schalten ihre Äste im Skilltree frei
	for id: String in _region_saves:
		if not reached.has(id):
			reached.append(id)
	skills.regions = reached
	if not data.is_empty():
		skills.from_dict(data.get("skills", {}))
		_tutorial.from_list(data.get("tutorial", []))   # alte Spielstände: Hinweise kommen noch einmal
		_play_sec = float(data.get("play_sec", 0.0))
		_world_sec = float(data.get("world_sec", _play_sec))
		grid.time_sec = _world_sec
		_ground.set_time(_world_sec)
	_bonus_cells = 0.0
	for id: String in _region_saves:
		var e: Dictionary = _region_saves[id]
		if id != region_id and bool(e.get("finished", false)):
			_bonus_cells += float(e.get("green_cells", 0)) * campaign.finished_pollen_share
	var g: Dictionary = entry.get("grid", {})
	var fits := int(g.get("w", 0)) == grid.width and int(g.get("h", 0)) == grid.height
	if not fits or not grid.load_bytes(Marshalls.base64_to_raw(str(g.get("cells", "")))):
		if not g.is_empty():
			push_warning("Spielstand passt nicht zur Karte, Region beginnt neu")
		_paint()
		_wake_objects(false)
		return
	grid.load_since(Marshalls.base64_to_raw(str(g.get("since", ""))))
	grid.load_sown(Marshalls.base64_to_raw(str(g.get("sown", ""))))
	_finished = bool(entry.get("finished", false))
	var r: Array = entry.get("robot", [])
	if r.size() == 2:
		_robot.position = Vector2(float(r[0]), float(r[1])).clamp(_robot.bounds.position, _robot.bounds.end)
		if not _robot.can_stand(_robot.position):
			_robot.position = _start_px   # alter Spielstand: Platz liegt jetzt im Wasser
	_camera.reset_smoothing()
	_milestone = floori(grid.coverage() * 10.0)
	if entry.has("repaired"):
		_villagers.set_done(entry["repaired"])
	else:   # Stand von vor 0.17.2: was schon grün war, gilt als repariert (wie es aussah)
		var done: Array[String] = []
		for id: String in _village_by_id:
			if _building_green(id):
				done.append(id)
		_villagers.set_done(done)
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
