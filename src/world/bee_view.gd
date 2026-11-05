class_name BeeView
extends Node2D
## Zeichnet Bienenstock und alle Bienen in einem einzigen _draw (Platzhalter-Grafik).
## Bienen schweben in der Höhe (Schatten versetzt) und wackeln leicht beim Schweben.
## Kreise über Disc (draw_circle ist je Aufruf rund 80-mal teurer).

const BEE_SCALE := 1.5

var _swarm: BeeSwarm
var _time := 0.0


func bind(swarm: BeeSwarm) -> void:
	_swarm = swarm
	z_index = 5


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _swarm == null:
		return
	_draw_hive(_swarm.hive)
	for i in _swarm.bees.size():
		var b: BeeSwarm.Bee = _swarm.bees[i]
		if b.rest > 0.0:
			continue   # ruht im Stock
		var phase := _time * 7.0 + i * 1.7
		var bob := Vector2(cos(phase * 0.5), sin(phase)) * (3.0 if b.hover > 0.0 else 1.0)
		var dir := (b.target - b.pos).angle() if b.flying else sin(phase * 0.3) * 0.6
		_draw_bee(b.pos + bob, dir, phase)


func _draw_hive(p: Vector2) -> void:
	var outline := Color(0.55, 0.38, 0.15)
	draw_set_transform(p + Vector2(6, 10), 0.0, Vector2(1.0, 0.6))
	Disc.dot(self, Vector2.ZERO, 36.0, Color(0, 0, 0, 0.16))
	draw_set_transform(Vector2.ZERO)
	# Drei gestapelte Ringe, unten breiter
	var rings := [[Vector2(0, 14), 30.0], [Vector2(0, -2), 25.0], [Vector2(0, -16), 18.0]]
	for r in rings:
		Disc.ring_dot(self, p + r[0], r[1], Color(1.0, 0.80, 0.35), outline, 3.0)
	Disc.dot(self, p + Vector2(0, 16), 7.0, Color(0.35, 0.22, 0.08))


func _draw_bee(p: Vector2, angle: float, phase: float) -> void:
	var k := BEE_SCALE
	draw_set_transform(p + Vector2(5, 12) * k, angle, Vector2(1.0, 0.7) * k)
	Disc.dot(self, Vector2.ZERO, 7.0, Color(0, 0, 0, 0.15))
	# Flügel flattern
	var flap := 0.6 + 0.4 * absf(sin(phase * 4.0))
	for s in [-1.0, 1.0]:
		draw_set_transform(p + Vector2(-1, 6 * s).rotated(angle) * k, angle + s * 0.5, Vector2(0.8, flap) * k)
		Disc.dot(self, Vector2.ZERO, 6.0, Color(1, 1, 1, 0.75))
	draw_set_transform(p, angle, Vector2(1.3, 1.0) * k)
	Disc.dot(self, Vector2.ZERO, 7.0, Color(1.0, 0.82, 0.20))
	draw_set_transform(p, angle, Vector2(k, k))
	draw_line(Vector2(-3, -6), Vector2(-3, 6), Color(0.2, 0.18, 0.15), 2.5)
	draw_line(Vector2(2, -6.5), Vector2(2, 6.5), Color(0.2, 0.18, 0.15), 2.5)
	Disc.dot(self, Vector2(8, 0), 3.5, Color(0.2, 0.18, 0.15))
	draw_set_transform(Vector2.ZERO)
