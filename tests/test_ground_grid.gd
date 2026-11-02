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
