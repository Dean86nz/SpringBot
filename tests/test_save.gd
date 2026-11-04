extends TestCase
## Spielstand: Raster und Skilltree überstehen Speichern und Laden, kaputte Dateien kosten
## höchstens den letzten Stand. Eigener Ordner, der echte Spielstand bleibt unberührt.
## Die zwei Fehlermeldungen (decompress, Parse JSON) im Testlauf sind gewollt.

const DIR := "user://test_saves/"


func test_grid_roundtrip_rebuilds_count_and_frontier() -> void:
	var a := GroundGrid.new(40, 30)
	a.paint_circle(Vector2(10, 10), 4.0)
	a.paint_circle(Vector2(30, 20), 3.0)
	var b := GroundGrid.new(40, 30)
	assert_true(b.load_bytes(a.to_bytes()))
	assert_eq(b.cells, a.cells)
	assert_eq(b.green_count, a.green_count)
	var fa := Array(a.frontier)
	var fb := Array(b.frontier)
	fa.sort()
	fb.sort()
	assert_eq(fb, fa, "Grenze neu aufgebaut")
	assert_false(GroundGrid.new(20, 20).load_bytes(a.to_bytes()), "falsche Kartengröße wird abgelehnt")


func test_skills_roundtrip() -> void:
	var data := Game.load_json(Game.SKILLTREE_PATH)
	var a := SkillTree.new(data)
	a.pollen = 1000.0
	a.buy("r1")
	a.tick(2.0, 100)
	var b := SkillTree.new(data)
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(b.level("r1"), 1)
	assert_eq(b.level("root"), 1, "Startknoten bleibt gekauft")
	assert_true(absf(b.pollen - a.pollen) < 0.001)
	assert_true(b.earned >= b.pollen, "gesammelt nie weniger als vorhanden")
	b.from_dict({"levels": {"r1": 99, "gibt_es_nicht": 1}})
	assert_eq(b.level("r1"), b.max_level("r1"), "Stufe auf Maximum begrenzt")


func test_store_rotates_and_survives_broken_file() -> void:
	var st := SaveStore.new(DIR)
	st.wipe()
	assert_false(st.has_save())
	st.write({"n": 1})
	st.write({"n": 2})
	assert_eq(int(st.read()["n"]), 2, "neuester Stand")
	var latest := str(SaveStore._read_file(DIR + SaveStore.META)["latest"])
	var f := FileAccess.open(DIR + latest, FileAccess.WRITE)
	f.store_string("{kaputt")
	f.close()
	assert_eq(int(st.read().get("n", 0)), 1, "kaputter neuester Stand: der ältere wird genommen")
	st.wipe()


func test_green_since_survives_save_and_old_saves_count_as_old() -> void:
	var a := GroundGrid.new(30, 20)
	a.time_sec = 125.0
	a.paint_circle(Vector2(10, 10), 3.0)
	var i := 10 * 30 + 10
	assert_eq(a.green_since(i), 125.0, "Zeitpunkt des Begrünens")
	assert_eq(a.green_since(0), -1.0, "grau")
	var b := GroundGrid.new(30, 20)
	b.load_bytes(a.to_bytes())
	b.load_since(a.since_to_bytes())
	assert_eq(b.green_since(i), 125.0)
	var c := GroundGrid.new(30, 20)
	c.load_bytes(a.to_bytes())
	c.load_since(PackedByteArray())
	assert_eq(c.green_since(i), 0.0, "alter Spielstand: Grün gilt als seit Spielbeginn grün")
