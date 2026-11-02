class_name Robot
extends Node2D
## Der kleine Frühlings-Roboter (Platzhalter-Grafik, von oben gesehen, vorne = +x).
## Linker Stick fährt analog, WASD/Pfeile digital. Bleibt innerhalb der Karte.

var speed_px := 380.0
var accel := 10.0
var bounds := Rect2()
var velocity := Vector2.ZERO
var _wobble := 0.0
var _body_box := StyleBoxFlat.new()
var _head_box := StyleBoxFlat.new()


func _ready() -> void:
	_body_box.bg_color = Color(0.96, 0.95, 0.90)
	_body_box.set_corner_radius_all(14)
	_body_box.set_border_width_all(4)
	_body_box.border_color = Color(0.30, 0.36, 0.44)
	_head_box.bg_color = Color(0.55, 0.80, 0.95)
	_head_box.set_corner_radius_all(10)
	_head_box.set_border_width_all(3)
	_head_box.border_color = Color(0.30, 0.36, 0.44)


func _process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target := input * speed_px
	velocity = velocity.lerp(target, clampf(accel * delta, 0.0, 1.0))
	if velocity.length() < 2.0 and input == Vector2.ZERO:
		velocity = Vector2.ZERO
	position += velocity * delta
	if bounds.has_area():
		position = position.clamp(bounds.position, bounds.end)
	if velocity.length() > 20.0:
		rotation = lerp_angle(rotation, velocity.angle(), clampf(12.0 * delta, 0.0, 1.0))
		_wobble += delta * velocity.length() * 0.05
	queue_redraw()


func _draw() -> void:
	var outline := Color(0.30, 0.36, 0.44)
	# Schatten
	draw_set_transform(Vector2(4, 6), 0.0, Vector2(1.0, 0.85))
	draw_circle(Vector2.ZERO, 40.0, Color(0.0, 0.0, 0.0, 0.18))
	draw_set_transform(Vector2.ZERO)
	# Ketten links und rechts, mit wanderndem Profil
	for side in [-1.0, 1.0]:
		var r := Rect2(Vector2(-30, side * 30 - 9), Vector2(60, 18))
		draw_rect(r, Color(0.36, 0.40, 0.46))
		var off := fmod(_wobble * 6.0, 10.0)
		for i in 7:
			var x := -30.0 + i * 10.0 + off
			if x < 28.0:
				draw_line(Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), Color(0.25, 0.28, 0.33), 3.0)
	# Körper
	draw_style_box(_body_box, Rect2(Vector2(-28, -26), Vector2(56, 52)))
	# Kopf vorne mit Augen
	draw_style_box(_head_box, Rect2(Vector2(4, -18), Vector2(26, 36)))
	draw_circle(Vector2(22, -8), 4.5, outline)
	draw_circle(Vector2(22, 8), 4.5, outline)
	draw_circle(Vector2(23.5, -9.5), 1.6, Color.WHITE)
	draw_circle(Vector2(23.5, 6.5), 1.6, Color.WHITE)
	# Antenne mit Blume
	draw_line(Vector2(-10, 0), Vector2(-16, 0), outline, 3.0)
	var bloom := Vector2(-16, 0)
	for k in 5:
		draw_circle(bloom + Vector2.from_angle(k * TAU / 5.0 + _wobble * 0.2) * 7.0, 5.5, Color(1.0, 0.56, 0.69))
	draw_circle(bloom, 4.5, Color(1.0, 0.85, 0.30))
