extends TestCase
## Kernlogik der Pollen-Wirtschaft: Ertrag, Kosten, Kaufen, Maximum.

const DATA := {
	"pollen_per_cell_per_sec": 0.5,
	"upgrades": [{"id": "radius", "base_cost": 10, "cost_growth": 2.0, "max_level": 2, "per_level": 0.5}],
}


func test_tick_adds_pollen_per_green_cell() -> void:
	var e := Economy.new(DATA)
	e.tick(2.0, 10)
	assert_eq(e.pollen, 10.0, "10 Zellen × 0,5/s × 2 s")


func test_buy_costs_grow_and_stop_at_max() -> void:
	var e := Economy.new(DATA)
	assert_eq(e.cost("radius"), 10)
	assert_false(e.buy("radius"), "zu wenig Pollen")
	e.pollen = 35.0
	assert_true(e.buy("radius"))
	assert_eq(e.pollen, 25.0)
	assert_eq(e.cost("radius"), 20, "Kosten verdoppeln sich")
	assert_true(e.buy("radius"))
	assert_true(e.is_maxed("radius"))
	assert_false(e.buy("radius"), "über das Maximum hinaus nicht")
	assert_eq(e.pollen, 5.0)
	assert_eq(e.bonus("radius"), 1.0)


func test_reset_and_max_all() -> void:
	var e := Economy.new(DATA)
	e.max_all()
	assert_eq(e.level("radius"), 2)
	e.pollen = 99.0
	e.reset()
	assert_eq(e.level("radius"), 0)
	assert_eq(e.pollen, 0.0)


func test_number_format() -> void:
	assert_eq(Fmt.int_str(1234567), "1.234.567")
	assert_eq(Fmt.int_str(999), "999")
	assert_eq(Fmt.num(2.5), "2,5")
	assert_eq(Fmt.num(3.0), "3")
