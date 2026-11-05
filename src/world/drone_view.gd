class_name DroneView
extends Node2D
## Zeichnet die Ladestation und alle Gärtner-Drohnen in einem einzigen _draw: Quadrokopter von oben
## (Kreuz aus vier Armen, drehende Rotoren als halbdurchsichtige Scheiben, Tank mit Grün, Lämpchen),
## hoch über dem Boden (Schatten weit versetzt), beim Sprühen ein feiner grüner Nebel darunter.
## Rastende Drohnen stehen auf den Feldern der Station. Kreise über Disc.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.14)
const BODY := Color(0.94, 0.95, 0.92)
const ARM := Color(0.45, 0.50, 0.56)
const TANK := Color(0.42, 0.76, 0.36)
const HIGH := Vector2(22, 44)
const K := 1.0

var _drones: GardenDrones
var _time := 0.0
var _shown := false


func bind(d: GardenDrones) -> void:
	_drones = d
	z_index = 6


func _process(delta: float) -> void:
	_time += delta
	var on := _drones != null and not _drones.drones.is_empty()
	if on or on != _shown:
		queue_redraw()
	_shown = on


func _draw() -> void:
	if _drones == null or _drones.drones.is_empty():
		return
	_draw_dock(_drones.dock, _drones.drones.size())
	for m in _drones.mist:
		var t := clampf((_drones.time - m.z) / GardenDrones.MIST_SEC, 0.0, 1.0)
		Disc.dot(self, Vector2(m.x, m.y) + Vector2(sin(m.z * 13.0), cos(m.z * 7.0)) * 6.0 * t, 5.0 + 9.0 * t, Color(0.70, 0.95, 0.65, 0.35 * (1.0 - t)))
	for i in _drones.drones.size():
		var d: GardenDrones.Drone = _drones.drones[i]
		if d.state == GardenDrones.State.CHARGE:
			_drone(_pad(i), 0.0, false, Vector2(4, 6))
		else:
			var bob := Vector2(0, sin(_time * 3.0 + i) * 2.0)
			_drone(d.pos + bob, d.dir.angle(), d.state == GardenDrones.State.MOW, HIGH)
	draw_set_transform(Vector2.ZERO)


## Platz der i-ten Drohne auf der Station (bis zu sechs Felder, weitere stapeln sich daneben).
func _pad(i: int) -> Vector2:
	var col := i % 3
	var row := (i / 3) % 2
	return _drones.dock + Vector2(-34 + col * 34, -16 + row * 32)


## Ladestation: graue Plattform mit sechs Feldern, grünes Blatt-Zeichen in der Mitte.
func _draw_dock(p: Vector2, n: int) -> void:
	draw_rect(Rect2(p + Vector2(-50, -34) + Vector2(6, 8), Vector2(100, 68)), SHADOW)
	draw_rect(Rect2(p + Vector2(-50, -34), Vector2(100, 68)), Color(0.62, 0.64, 0.66))
	draw_rect(Rect2(p + Vector2(-46, -30), Vector2(92, 60)), Color(0.72, 0.74, 0.76))
	for i in 6:
		Disc.ring_dot(self, _pad(i), 12.0, Color(0.66, 0.68, 0.70), Color(0.95, 0.85, 0.30), 2.0)
	for e in [[Vector2(-50, -34), Vector2(50, -34)], [Vector2(50, -34), Vector2(50, 34)], [Vector2(50, 34), Vector2(-50, 34)], [Vector2(-50, 34), Vector2(-50, -34)]]:
		draw_line(p + e[0], p + e[1], INK, 2.5)
	draw_set_transform(p + Vector2(0, 40), 0.6, Vector2(1.0, 0.5))
	Disc.dot(self, Vector2.ZERO, 7.0, Color(0.42, 0.76, 0.36))   # Blatt-Zeichen vorne
	draw_set_transform(Vector2.ZERO)


## Quadrokopter: Schatten, vier Arme mit Rotoren, Körper mit Tank und Lämpchen. spraying: Lämpchen grün blinkend.
func _drone(p: Vector2, ang: float, spraying: bool, high: Vector2) -> void:
	draw_set_transform(p + high, ang, Vector2(K, K))
	draw_line(Vector2(-14, -14), Vector2(14, 14), SHADOW, 5.0)
	draw_line(Vector2(-14, 14), Vector2(14, -14), SHADOW, 5.0)
	Disc.dot(self, Vector2.ZERO, 9.0, SHADOW)
	draw_set_transform(p, ang, Vector2(K, K))
	for s in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var tip: Vector2 = s * 14.0
		draw_line(Vector2.ZERO, tip, INK, 5.0)
		draw_line(Vector2.ZERO, tip, ARM, 3.0)
		var spin: float = _time * 40.0 + s.x * 2.0 + s.y
		Disc.dot(self, tip, 9.5, Color(0.85, 0.90, 0.95, 0.35))   # drehender Rotor (Unschärfe)
		draw_line(tip - Vector2.from_angle(spin) * 9.0, tip + Vector2.from_angle(spin) * 9.0, Color(0.30, 0.34, 0.40, 0.7), 2.0)
		Disc.dot(self, tip, 2.5, INK)
	Disc.ring_dot(self, Vector2.ZERO, 8.0, BODY, INK, 2.0)
	Disc.dot(self, Vector2(-2, 0), 4.5, TANK)
	var on := spraying and fmod(_time * 3.0, 1.0) < 0.6
	Disc.dot(self, Vector2(6, 0), 2.2, Color(0.4, 1.0, 0.45) if on else Color(1.0, 0.75, 0.3))
	draw_set_transform(Vector2.ZERO)
