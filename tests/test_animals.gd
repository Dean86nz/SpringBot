extends TestCase
## Tiere: nur über Grün, Anzahl wächst mit dem Grün, Frösche nur an erwachten Teichen,
## fliehen vor dem Roboter, verschwinden fern der Kamera.

const CFG := {
	"spawn_check_sec": 0.1, "view_margin_px": 100, "despawn_margin_px": 400, "fade_sec": 0.2,
	"butterfly": {"max": 6, "min_coverage": 0.02, "full_coverage": 0.5, "speed": 55, "turn": 2.5, "flee_px": 90},
	"hare": {"max": 3, "min_coverage": 0.05, "full_coverage": 0.5, "hop_px": [30, 50], "hop_sec": 0.3, "rest_sec": [0.3, 1.0], "flee_px": 150},
	"bird": {"min_coverage": 0.1, "every_sec": [2, 3], "flock": [2, 3], "speed": 230},
	"frog": {"per_pond": 2, "hop_sec": 0.4, "rest_sec": [0.5, 1.0], "dive_px": 130, "hidden_sec": [1.0, 2.0]}
}
const VIEW := Rect2(600, 600, 1200, 1000)


func _grid(green_left_cols: int) -> GroundGrid:
	var g := GroundGrid.new(100, 100)
	for y in 100:
		for x in green_left_cols:
			g.set_green(Vector2i(x, y))
	return g


func _run(a: Animals, sec: float, robot: Vector2 = Vector2(-9999, -9999), view: Rect2 = VIEW) -> void:
	for i in int(sec * 30.0):
		a.update(1.0 / 30.0, view, robot)


func test_no_animals_in_grey_world() -> void:
	var a := Animals.new(_grid(0), 24.0, CFG, 7)
	_run(a, 20.0)
	assert_eq(a.list.size(), 0, "graue Welt ohne Tiere")


func test_more_green_more_animals_up_to_max() -> void:
	var g := _grid(5)
	var a := Animals.new(g, 24.0, CFG, 7)
	assert_eq(a.cap("butterfly"), 1, "wenig Grün: einzelne Schmetterlinge")
	assert_eq(a.cap("hare"), 0, "Hasen erst ab mehr Grün")
	var full := Animals.new(_grid(100), 24.0, CFG, 7)
	assert_eq(full.cap("butterfly"), 6)
	_run(full, 10.0)
	assert_eq(full.count(Animals.BUTTERFLY), 6, "voll grün: alle Schmetterlinge")
	assert_true(full.count(Animals.HARE) <= 3, "nie mehr Hasen als max")


func test_butterflies_and_hares_stay_over_green() -> void:
	var g := _grid(50)   # links grün, rechts grau
	var a := Animals.new(g, 24.0, CFG, 3)
	var view := Rect2(400, 400, 1600, 1200)
	_run(a, 30.0, Vector2(-9999, -9999), view)
	assert_true(a.list.size() > 0)
	for an in a.list:
		if an.kind == Animals.BUTTERFLY or an.kind == Animals.HARE:
			assert_true(an.pos.x < 50 * 24.0 + 60.0, "Tier über Grau bei %s" % an.pos)


func test_hares_flee_from_robot() -> void:
	var a := Animals.new(_grid(100), 24.0, CFG, 5)
	_run(a, 6.0)
	var hares := a.list.filter(func(x: Animals.Animal) -> bool: return x.kind == Animals.HARE)
	assert_true(hares.size() > 0)
	var h: Animals.Animal = hares[0]
	var robot := h.pos + Vector2(40, 0)
	var before := h.pos.distance_to(robot)
	_run(a, 2.0, robot)
	assert_true(h.pos.distance_to(robot) > before + 40.0, "Hase hoppelt vom Roboter weg")


func test_frogs_only_at_awake_ponds_and_dive_near_robot() -> void:
	var a := Animals.new(_grid(100), 24.0, CFG, 9)
	a.ponds.append({"pos": Vector2(1200, 1100), "angle": 0.3, "size": 1.0, "awake": false})
	_run(a, 3.0)
	assert_eq(a.count(Animals.FROG), 0, "trockener Teich: keine Frösche")
	a.ponds[0]["awake"] = true
	_run(a, 1.0)
	assert_eq(a.count(Animals.FROG), 2)
	for an in a.list:
		if an.kind == Animals.FROG:
			var rim := Animals.rim_point(a.ponds[0], an.rim, Animals.POND_RIM)
			assert_true(an.pos.distance_to(rim) < 1.0 or an.hop >= 0.0, "Frosch sitzt am Teichrand")
	_run(a, 2.0, Vector2(1200, 1100))
	assert_true(a.splashes.size() > 0 or a.list.any(func(x: Animals.Animal) -> bool: return x.hidden > 0.0), "Frösche springen ins Wasser")
	a.ponds[0]["awake"] = false
	_run(a, 0.5)
	assert_eq(a.count(Animals.FROG), 0, "Teich wieder trocken (Neues Spiel): Frösche weg")


func test_animals_vanish_far_from_view_and_birds_cross() -> void:
	var a := Animals.new(_grid(100), 24.0, CFG, 11)
	var birds := 0
	for i in 16:
		_run(a, 0.5)
		birds = maxi(birds, a.count(Animals.BIRD))
	assert_true(birds >= 2, "Vögel ziehen in Gruppen vorbei")
	_run(a, 6.0, Vector2(-9999, -9999), Rect2(-50000, -50000, 100, 100))
	assert_eq(a.list.size(), 0, "fern der Kamera keine Tiere")
