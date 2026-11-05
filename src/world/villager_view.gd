class_name VillagerView
extends Node2D
## Zeichnet die Menschen des Dorfes von oben: Schatten, Körper (Kleidung), Arme beim Gehen,
## Kopf mit Haaren oder Hut. Alles mit Disc (Kreise als Textur), ein einziges _draw.

const INK := Color(0.30, 0.36, 0.44)
const SHADOW := Color(0, 0, 0, 0.16)
const CLOTHES := [Color(0.86, 0.36, 0.34), Color(0.36, 0.56, 0.86), Color(0.98, 0.80, 0.30), Color(0.48, 0.74, 0.42), Color(0.72, 0.50, 0.86), Color(0.96, 0.62, 0.40)]
const SKIN := [Color(0.98, 0.84, 0.70), Color(0.86, 0.66, 0.50), Color(0.62, 0.44, 0.32)]
const HAIR := [Color(0.30, 0.22, 0.16), Color(0.86, 0.70, 0.36), Color(0.54, 0.30, 0.20), Color(0.18, 0.18, 0.20), Color(0.80, 0.80, 0.78)]
const SCALE := 2.2

var _people: Villagers


func bind(v: Villagers) -> void:
	_people = v
	z_index = 4


func _process(_delta: float) -> void:
	if _people and not _people.people.is_empty():
		queue_redraw()


func _draw() -> void:
	if _people == null:
		return
	for p in _people.people:
		if p.delay > 0.0:
			continue
		var walking := p.wait <= 0.0
		var bob := absf(sin(p.phase)) * 2.0 if walking else 0.0
		draw_set_transform(p.pos, p.dir, Vector2.ONE * SCALE)
		Disc.dot(self, Vector2(3, 4), 9.0, SHADOW)
		var cloth: Color = CLOTHES[p.look % CLOTHES.size()]
		var swing := sin(p.phase) * 4.0 if walking else 0.0
		for side in [-1.0, 1.0]:   # Arme schwingen beim Gehen
			Disc.ring_dot(self, Vector2(swing * side, side * 8.0), 3.2, cloth.darkened(0.1), INK, 1.5)
		Disc.ring_dot(self, Vector2.ZERO, 7.5 + bob * 0.2, cloth, INK, 2.0)
		var skin: Color = SKIN[(p.look / 6) % SKIN.size()]
		Disc.ring_dot(self, Vector2(1, 0), 5.0, skin, INK, 1.5)
		var hair: Color = HAIR[(p.look / 18) % HAIR.size()]
		if p.look % 5 == 0:   # Hut mit Krempe
			Disc.ring_dot(self, Vector2(0, 0), 6.5, Color(0.92, 0.84, 0.56), INK, 1.5)
			Disc.dot(self, Vector2(0, 0), 3.5, Color(0.80, 0.70, 0.44))
		else:
			Disc.dot(self, Vector2(-1.5, 0), 4.2, hair)
	draw_set_transform(Vector2.ZERO)
