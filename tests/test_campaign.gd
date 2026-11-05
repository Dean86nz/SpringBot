extends TestCase
## Regionen (Phase 3, Gerüst): jede Region der Reise hat ihre Daten, alte Spielstände werden zur
## Startregion, andere Regionen im Spielstand bleiben beim Speichern erhalten.


func _campaign() -> Campaign:
	return Campaign.new(Game.load_json("res://data/campaign.json"))


func test_every_region_has_its_data() -> void:
	var c := _campaign()
	assert_true(c.order.size() >= 1)
	assert_eq(c.start, "heimatdorf", "Reise beginnt im Heimatdorf")
	assert_true(c.has(c.start))
	for id in c.order:
		var d := c.load_region(id)
		for f in Campaign.FILES:
			assert_false((d[f] as Dictionary).is_empty(), "%s: %s.json fehlt" % [id, f])
		var r: Dictionary = d["region"]
		assert_false(str(r.get("name", "")).is_empty(), "%s hat einen Namen" % id)
		assert_true(int(r.get("width_cells", 0)) > 0 and int(r.get("height_cells", 0)) > 0)
		assert_true(r.get("start_cell") is Array and r.get("hive_cell") is Array)
	assert_true(c.finished_pollen_share > 0.0 and c.finished_pollen_share < 1.0)


func test_unknown_region_is_not_listed() -> void:
	var c := _campaign()
	assert_false(c.has("mond"))
	assert_true(c.load_region("mond")["world"].is_empty(), "unbekannte Region: keine Daten statt Absturz")


func test_old_save_becomes_start_region() -> void:
	var old := {"version": 1, "play_sec": 100.0, "finished": true, "robot": [10.0, 20.0],
		"grid": {"w": 640, "h": 480, "cells": "abc", "since": "def"}, "skills": {"pollen": 5.0}}
	var m := SaveStore.migrate(old, "heimatdorf")
	assert_eq(m["region"], "heimatdorf")
	assert_false(m.has("grid"), "Raster liegt jetzt bei der Region")
	var e: Dictionary = m["regions"]["heimatdorf"]
	assert_eq(e["grid"]["cells"], "abc")
	assert_eq(e["robot"], [10.0, 20.0])
	assert_eq(e["finished"], true)
	assert_eq(m["skills"], {"pollen": 5.0}, "Skills bleiben gemeinsam")
	assert_eq(m["play_sec"], 100.0)
	assert_eq(SaveStore.migrate(m, "heimatdorf"), m, "neuer Stand bleibt unverändert")
	assert_eq(SaveStore.migrate({}, "heimatdorf"), {}, "kein Stand bleibt leer")


func test_old_save_file_is_still_read() -> void:
	var store := SaveStore.new("user://test_saves/campaign_v1/")
	store.wipe()
	var f := FileAccess.open(store.dir + "save_a.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "play_sec": 7.0, "grid": {"w": 640, "h": 480}}))
	f.close()
	var data := store.read()
	assert_eq(int(data.get("version", 0)), 1, "Stand aus Version 1 wird gelesen, nicht verworfen")
	assert_true(SaveStore.migrate(data, "heimatdorf").has("regions"))
	var g := FileAccess.open(store.dir + "save_a.json", FileAccess.WRITE)
	g.store_string(JSON.stringify({"version": 99}))
	g.close()
	assert_true(store.read().is_empty(), "Stand aus der Zukunft wird nicht geladen")
	store.wipe()


func test_journey_has_second_region_and_planned_ones() -> void:
	var c := _campaign()
	assert_true(c.order.size() >= 2, "es gibt mindestens eine zweite Region zum Reisen")
	assert_eq(c.order[0], c.start, "die Reise beginnt mit der Startregion")
	assert_true(c.planned.size() >= 1, "spätere Regionen sind angekündigt")
	var first: Dictionary = c.load_region(c.order[1])["region"]
	assert_true(first.has("intro"), "neue Region hat eine kurze Einleitung")
