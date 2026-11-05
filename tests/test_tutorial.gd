extends TestCase
## Einführung: jeder Hinweis genau einmal und im richtigen Moment, Tasten passend zum Gerät,
## Aufblüh-Klang wird bei vielen Bäumen kurz hintereinander leiser und dann still.


func _tut() -> Tutorial:
	return Tutorial.new(Game.load_json("res://data/tutorial.json"))


func _run(t: Tutorial, ctx: Dictionary, sec: float) -> Array[String]:
	var shown: Array[String] = []
	for i in int(sec * 10.0):
		var id := t.due(ctx, 0.1)
		if id != "":
			shown.append(id)
	return shown


func test_hints_once_and_in_order() -> void:
	var t := _tut()
	assert_eq(_run(t, {"can_buy": true, "bees": 0}, 0.5), [] as Array[String], "Fahr-Hinweis erst nach kurzer Wartezeit")
	assert_eq(_run(t, {"can_buy": false, "bees": 0}, 3.0), ["move"] as Array[String], "zuerst: wie man fährt")
	assert_eq(_run(t, {"can_buy": false, "bees": 0}, 5.0), [] as Array[String], "Skilltree-Hinweis erst mit genug Pollen")
	assert_eq(_run(t, {"can_buy": true, "bees": 0}, 2.0), ["tree"] as Array[String])
	assert_eq(_run(t, {"can_buy": true, "bees": 0, "quiet": true}, 1.0), [] as Array[String])
	assert_eq(_run(t, {"can_buy": true, "bees": 2, "quiet": true}, 3.0), [] as Array[String], "nicht, solange ein Menü offen ist")
	assert_eq(_run(t, {"can_buy": true, "bees": 2}, 1.0), ["bees"] as Array[String], "Bienen-Hinweis, sobald es Bienen gibt")
	assert_eq(_run(t, {"can_buy": true, "bees": 2}, 30.0), [] as Array[String], "jeder Hinweis nur einmal")
	assert_true(t.first("tree_help"), "Skilltree-Hilfe beim ersten Öffnen")
	assert_false(t.first("tree_help"), "danach nicht mehr")


func test_seen_hints_survive_save_and_reset_on_new_game() -> void:
	var t := _tut()
	_run(t, {"can_buy": true, "bees": 0}, 5.0)
	var saved := t.to_list()
	var t2 := _tut()
	t2.from_list(saved)
	assert_eq(_run(t2, {"can_buy": true, "bees": 0}, 5.0), [] as Array[String], "geladener Spielstand: keine Wiederholung")
	t2.reset()
	assert_eq(_run(t2, {"can_buy": false, "bees": 0}, 3.0), ["move"] as Array[String], "Neues Spiel: Hinweise wieder von vorn")


func test_key_names_follow_device() -> void:
	var was := KeyHints.pad
	KeyHints.setup(Game.load_json("res://data/tutorial.json").get("keys", {}))
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	KeyHints.observe(pad)
	assert_eq(KeyHints.fill("{tree}: Skilltree"), "Y: Skilltree")
	var v := KeyHints.version
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	assert_true(KeyHints.observe(key), "Wechsel zur Tastatur erkannt")
	assert_eq(KeyHints.version, v + 1)
	assert_eq(KeyHints.fill("{tree}: Skilltree"), "Tab: Skilltree")
	assert_false(KeyHints.observe(key), "gleiches Gerät: kein Wechsel")
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	assert_false(KeyHints.observe(drift), "leichtes Stick-Zittern zählt nicht")
	KeyHints.pad = was


func test_bloom_sound_gets_quieter_then_silent() -> void:
	var g: Dictionary = Game.load_json("res://data/audio.json")["groups"]["awake"]
	var step := float(g["step_db"])
	var max_n := int(g["max"])
	assert_eq(Sfx.group_db(0, step, max_n), 0.0, "erster Baum: voller (leiser) Klang")
	assert_true(Sfx.group_db(1, step, max_n) < 0.0, "zweiter kurz danach: leiser")
	assert_true(is_inf(Sfx.group_db(max_n, step, max_n)), "viele hintereinander: still")
	var level := float(Game.load_json("res://data/audio.json")["sfx_level_db"]["awake"])
	assert_true(level <= -20.0, "Aufblühen deutlich leiser als früher (-12 dB)")
