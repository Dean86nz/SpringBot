extends TestCase
## Kernlogik des Boden-Rasters: Begrünen im Kreis, Zählen, Ränder, Schmutz-Rechteck.


func test_circle_counts_cells_once() -> void:
	var g := GroundGrid.new(20, 20)
	var first := g.paint_circle(Vector2(10, 10), 2.0)
	assert_eq(first, 12, "Radius 2 um eine Zellecke trifft 12 Zellmittelpunkte")
	assert_eq(g.green_count, 12)
	assert_eq(g.paint_circle(Vector2(10, 10), 2.0), 0, "zweimal malen zählt nicht doppelt")
	assert_eq(g.green_count, 12)


func test_circle_clipped_at_edge() -> void:
	var g := GroundGrid.new(10, 10)
	var n := g.paint_circle(Vector2(0, 0), 2.0)
	assert_eq(n, 3, "nur das Viertel innerhalb der Karte")
	assert_eq(g.paint_circle(Vector2(-50, -50), 3.0), 0, "ganz außerhalb passiert nichts")


func test_coverage_and_full() -> void:
	var g := GroundGrid.new(4, 5)
	assert_eq(g.coverage(), 0.0)
	g.paint_circle(Vector2(2, 2.5), 100.0)
	assert_eq(g.green_count, 20)
	assert_eq(g.coverage(), 1.0)
	g.clear()
	assert_eq(g.green_count, 0)


func test_dirty_rect() -> void:
	var g := GroundGrid.new(30, 30)
	g.take_dirty()
	assert_false(g.take_dirty().has_area(), "nach dem Abholen leer")
	g.paint_circle(Vector2(5.5, 5.5), 1.0)
	g.set_green(Vector2i(20, 22))
	var r := g.take_dirty()
	assert_true(r.has_point(Vector2i(5, 5)) and r.has_point(Vector2i(20, 22)), "umfasst beide Änderungen")


func test_percent_never_rounds_up_to_100() -> void:
	assert_eq(Hud.format_percent(0.9999), "99,9")
	assert_eq(Hud.format_percent(1.0), "100,0")
	assert_eq(Hud.format_percent(0.1234), "12,3")


func test_frontier_tracks_grey_neighbours() -> void:
	var g := GroundGrid.new(10, 10)
	g.set_green(Vector2i(5, 5))
	assert_eq(g.frontier.size(), 4, "vier graue Nachbarn")
	g.set_green(Vector2i(6, 5))
	assert_eq(g.frontier.size(), 6, "Zelle (6,5) raus, drei neue Nachbarn dazu")
	g.set_green(Vector2i(0, 0))
	assert_eq(g.frontier.size(), 8, "Ecke hat nur zwei Nachbarn")
	for i in g.frontier:
		assert_eq(g.cells[i], GroundGrid.GREY, "Grenze enthält nur graue Zellen")


func test_spread_grows_only_at_frontier() -> void:
	var g := GroundGrid.new(20, 20)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	g.set_green(Vector2i(10, 10))
	var added := g.spread(30, 1, 0.5, rng)
	assert_eq(added, 30)
	assert_eq(g.green_count, 31)
	# Ohne Samenflug bleibt das Grün zusammenhängend: jede grüne Zelle hat einen grünen Nachbarn
	for y in 20:
		for x in 20:
			var c := Vector2i(x, y)
			if g.is_green(c) and c != Vector2i(10, 10):
				var n := g.is_green(c + Vector2i.LEFT) or g.is_green(c + Vector2i.RIGHT) \
					or g.is_green(c + Vector2i.UP) or g.is_green(c + Vector2i.DOWN)
				assert_true(n, "Zelle %s ohne grünen Nachbarn" % c)


func test_spread_fills_map_and_stops() -> void:
	var g := GroundGrid.new(6, 6)
	var rng := RandomNumberGenerator.new()
	g.set_green(Vector2i(0, 0))
	g.spread(1000, 4, 0.5, rng)
	assert_eq(g.green_count, 36, "ganze Karte grün")
	assert_true(g.frontier.is_empty())
	assert_eq(g.spread(10, 4, 0.5, rng), 0, "nichts mehr zu tun")


func test_spread_one_cell_per_event_even_with_seeds() -> void:
	var g := GroundGrid.new(100, 100)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	g.set_green(Vector2i(50, 50))
	assert_eq(g.spread(200, 8, 1.0, rng), 200, "Samenflug ersetzt Wachstum, verdoppelt es nicht")
	assert_eq(g.green_count, 201)


## Die sichtbare Spur liegt mittig unter dem Roboter, auch wenn er nicht auf einer Zellmitte fährt.
func test_visible_edge_follows_circle_not_cells() -> void:
	for cx: float in [10.0, 10.25, 10.5, 10.8]:
		var g := GroundGrid.new(24, 24)
		g.paint_circle(Vector2(cx, 12.5), 3.0)
		var left := _crossing(g, 12, -1, cx)
		var right := _crossing(g, 12, 1, cx)
		assert_true(absf((left + right) * 0.5 - cx) < 0.1, "Mitte %.2f statt %.2f" % [(left + right) * 0.5, cx])
		assert_true(absf(right - left - 6.0) < 0.3, "Breite %.2f statt 6" % (right - left))


## Wo die weich gefilterte Maske (Werte an Zellmitten x + 0,5) in Zeile y die 0,5 kreuzt.
func _crossing(g: GroundGrid, y: int, step: int, from: float) -> float:
	var x := int(from)
	while true:
		var a := g.vis[y * g.width + x] / 255.0
		var b := g.vis[y * g.width + x + step] / 255.0
		if a >= 0.5 and b < 0.5:
			return x + 0.5 + step * (a - 0.5) / (a - b)
		x += step
	return 0.0
