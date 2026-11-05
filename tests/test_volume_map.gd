extends TestCase
## Lautstärke-Regler: Werte bleiben gespeichert, 0 % ist stumm, halbe Stellung deutlich leiser.
## Übersichtskarte: jeder Gebietsname steht in seinem eigenen Gebiet, die Karte-Taste ist belegt.

const PATH := "user://test_saves/settings_test.json"


func test_volume_curve() -> void:
	assert_eq(Sfx.volume_db(1.0), 0.0, "voll = Grundlautstärke")
	assert_true(Sfx.volume_db(0.5) < -10.0 and Sfx.volume_db(0.5) > -14.0, "Mitte ≈ -12 dB")
	assert_true(Sfx.volume_db(0.0) < -80.0, "0 % praktisch stumm")


func test_volume_settings_roundtrip() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var keep: Dictionary = Sfx.volume.duplicate()
	Sfx.volume = {"music": 0.3, "sfx": 0.7}
	Sfx.save_settings(PATH)
	Sfx.volume = {"music": 1.0, "sfx": 1.0}
	Sfx.load_settings(PATH)
	assert_eq(Sfx.volume["music"], 0.3)
	assert_eq(Sfx.volume["sfx"], 0.7)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("kaputt")
	f.close()
	Sfx.load_settings(PATH)
	assert_eq(Sfx.volume["music"], 0.3, "kaputte Datei: Werte bleiben")
	Sfx.volume = keep
	Sfx.load_settings("user://gibt_es_nicht.json")   # setzt die Busse wieder auf die alten Werte


func test_area_names_sit_inside_their_area() -> void:
	var r := Areas.new(640, 480, Game.load_json("res://data/regions/heimatdorf/areas.json"))
	var c := r.centers()
	assert_eq(c.size(), r.list.size())
	for i in c.size():
		assert_eq(r.at_cell(c[i]), i, "Name von %s liegt im eigenen Gebiet" % r.name_of(i))


func test_map_key_bound() -> void:
	InputSetup.apply()   # der Test-Runner läuft vor den Autoloads
	assert_true(InputMap.has_action("map"), "Karte direkt öffnen")
	assert_false(InputMap.action_get_events("map").is_empty())
