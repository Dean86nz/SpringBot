class_name Robot
extends Node2D
## Der kleine Gärtner-Roboter (Platzhalter-Grafik, von oben gesehen, vorne = +x).
## Linker Stick fährt analog, WASD/Pfeile digital. Bleibt innerhalb der Karte und fährt
## nicht durch Hindernisse (Kreise, z. B. der Bienenstock), sondern gleitet an ihnen entlang.
## Über Wasser fährt er nicht (walkable sagt, ob ein Punkt befahrbar ist); am Ufer gleitet er
## entlang, indem er die Bewegung in x und y getrennt versucht.

var speed_px := 380.0
var accel := 10.0
var bounds := Rect2()
var radius_px := 30.0
var obstacles: Array[Dictionary] = []   # {"pos": Vector2, "radius": float}
const OBSTACLE_BUCKET_PX := 512.0
var _buckets: Dictionary = {}   # Rasterzelle → Hindernisse darin (Großstadt: Tausende), neu bei geänderter Liste
var _bucket_n := -1
var walkable := Callable()                # func(p: Vector2) -> bool, leer = überall befahrbar
var water_radius_px := 24.0               # so weit um die Mitte muss der Boden befahrbar sein
var velocity := Vector2.ZERO
## Aus, solange ein Menü offen ist, in dem der Stick navigiert.
var input_enabled := true
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
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down") if input_enabled else Vector2.ZERO
	var target := input * speed_px
	velocity = velocity.lerp(target, clampf(accel * delta, 0.0, 1.0))
	if velocity.length() < 2.0 and input == Vector2.ZERO:
		velocity = Vector2.ZERO
	var next := position + velocity * delta
	if not can_stand(next):
		var nx := Vector2(next.x, position.y)
		var ny := Vector2(position.x, next.y)
		if can_stand(nx):
			next = nx
			velocity.y = 0.0
		elif can_stand(ny):
			next = ny
			velocity.x = 0.0
		else:
			next = position
			velocity = Vector2.ZERO
	position = next
	for o in _near_obstacles():
		position = push_out(position, o["pos"], float(o["radius"]) + radius_px)
	if bounds.has_area():
		position = position.clamp(bounds.position, bounds.end)
	if velocity.length() > 20.0:
		rotation = lerp_angle(rotation, velocity.angle(), clampf(12.0 * delta, 0.0, 1.0))
		_wobble += delta * velocity.length() * 0.05
	queue_redraw()


## Hindernisse in der Nähe (3 × 3 Rasterzellen); das Raster wird neu gebaut, wenn sich die Liste ändert.
## Hindernisse sind kleiner als eine Rasterzelle, deshalb reicht die Nachbarschaft.
func _near_obstacles() -> Array:
	if _bucket_n != obstacles.size():
		_bucket_n = obstacles.size()
		_buckets.clear()
		for o in obstacles:
			var k := Vector2i((Vector2(o["pos"]) / OBSTACLE_BUCKET_PX).floor())
			if not _buckets.has(k):
				_buckets[k] = []
			(_buckets[k] as Array).append(o)
	var out := []
	var c := Vector2i((position / OBSTACLE_BUCKET_PX).floor())
	for y in range(c.y - 1, c.y + 2):
		for x in range(c.x - 1, c.x + 2):
			var list: Variant = _buckets.get(Vector2i(x, y))
			if list != null:
				out.append_array(list)
	return out


## Mitte und 8 Punkte im Kreis water_radius_px befahrbar?
func can_stand(p: Vector2) -> bool:
	if not walkable.is_valid():
		return true
	if not walkable.call(p):
		return false
	for k in 8:
		if not walkable.call(p + Vector2.from_angle(k * TAU / 8.0) * water_radius_px):
			return false
	return true


## Schiebt p aus dem Kreis (center, min_dist) auf den Rand. Außerhalb bleibt p unverändert.
static func push_out(p: Vector2, center: Vector2, min_dist: float) -> Vector2:
	var d := p - center
	var len := d.length()
	if len >= min_dist:
		return p
	if len < 0.001:
		return center + Vector2.DOWN * min_dist
	return center + d / len * min_dist


func _draw() -> void:
	var outline := Color(0.30, 0.36, 0.44)
	# Schatten
	draw_set_transform(Vector2(4, 6), 0.0, Vector2(1.0, 0.85))
	Disc.dot(self, Vector2.ZERO, 40.0, Color(0.0, 0.0, 0.0, 0.18))
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
	Disc.dot(self, Vector2(22, -8), 4.5, outline)
	Disc.dot(self, Vector2(22, 8), 4.5, outline)
	Disc.dot(self, Vector2(23.5, -9.5), 1.6, Color.WHITE)
	Disc.dot(self, Vector2(23.5, 6.5), 1.6, Color.WHITE)
	# Antenne mit Blume
	draw_line(Vector2(-10, 0), Vector2(-16, 0), outline, 3.0)
	var bloom := Vector2(-16, 0)
	for k in 5:
		Disc.dot(self, bloom + Vector2.from_angle(k * TAU / 5.0 + _wobble * 0.2) * 7.0, 5.5, Color(1.0, 0.56, 0.69))
	Disc.dot(self, bloom, 4.5, Color(1.0, 0.85, 0.30))
