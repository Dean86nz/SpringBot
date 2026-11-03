extends "res://tests/test_case.gd"

const SfxScript := preload("res://src/autoload/sfx.gd")


func test_music_follows_progress() -> void:
	var tracks := [{"from_coverage": 0.0}, {"from_coverage": 0.2}, {"from_coverage": 0.6}]
	assert_eq(SfxScript.track_for(tracks, 0.0), 0, "Anfang: erstes Stück")
	assert_eq(SfxScript.track_for(tracks, 0.3), 1)
	assert_eq(SfxScript.track_for(tracks, 1.0), 2, "am Ende das vollste Stück")


func test_audio_config_is_consistent() -> void:
	var cfg := Game.load_json(SfxScript.AUDIO_PATH)
	var tracks: Array = cfg.get("tracks", [])
	assert_true(tracks.size() >= 2, "mehrere Musikstücke")
	assert_eq(float(tracks[0]["from_coverage"]), 0.0, "erstes Stück läuft von Anfang an")
	var last := -1.0
	for l: Dictionary in tracks:
		assert_true(ResourceLoader.exists(str(l["file"])), "Datei fehlt: %s" % l["file"])
		assert_true(float(l["from_coverage"]) > last, "Schwellen steigen an")
		last = float(l["from_coverage"])


func test_petals_reuse_oldest_when_full() -> void:
	var fx := PetalFx.new()
	fx.capacity = 8
	fx._ready()
	fx.burst(Vector2.ZERO, 20)
	assert_eq(fx._alive, 8, "nie mehr Blätter als der Vorrat")
	fx._process(5.0)
	assert_eq(fx._alive, 0, "nach Ablauf alle frei")
	fx.free()
