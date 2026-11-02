extends TestCase
## Roboter: Hindernisse schieben ihn auf den Rand, statt ihn durchzulassen.


func test_push_out_moves_to_edge() -> void:
	var p := Robot.push_out(Vector2(110, 100), Vector2(100, 100), 50.0)
	assert_eq(p, Vector2(150, 100), "auf den Rand in Bewegungsrichtung")


func test_push_out_leaves_outside_alone() -> void:
	assert_eq(Robot.push_out(Vector2(200, 100), Vector2(100, 100), 50.0), Vector2(200, 100))


func test_push_out_exact_center() -> void:
	var p := Robot.push_out(Vector2(100, 100), Vector2(100, 100), 50.0)
	assert_true(is_equal_approx(p.distance_to(Vector2(100, 100)), 50.0), "auch genau in der Mitte heraus")
