class_name BridgeView
extends Node2D
## Holzbrücken über Fluss und Bach (Platzhalter-Grafik im Stil von Roboter und Bienen).
## Die Brücken kommen von WorldMap (in Zellen); gezeichnet wird einmal, sie ändern sich nie.

const WOOD := Color(0.72, 0.55, 0.36)
const WOOD_DARK := Color(0.55, 0.40, 0.25)
const INK := Color(0.30, 0.36, 0.44)

var _bridges: Array[Dictionary] = []
var _cell_px := 24.0


func bind(bridges: Array[Dictionary], cell_px: float) -> void:
	_bridges = bridges
	_cell_px = cell_px
	queue_redraw()


func _draw() -> void:
	for b in _bridges:
		var c: Vector2 = b["center"] * _cell_px
		var dir: Vector2 = b["dir"]
		var l := float(b["length"]) * _cell_px
		var w := float(b["width"]) * _cell_px
		var deck := Rect2(-l * 0.5, -w * 0.5, l, w)
		draw_set_transform(c + Vector2(6, 10), dir.angle())
		draw_rect(deck, Color(0, 0, 0, 0.18))
		draw_set_transform(c, dir.angle())
		draw_rect(deck, WOOD)
		# Bretter quer zur Fahrtrichtung
		var x := -l * 0.5 + 12.0
		var k := 0
		while x < l * 0.5:
			draw_line(Vector2(x, -w * 0.5), Vector2(x, w * 0.5), WOOD_DARK, 2.0)
			if k % 3 == 1:
				draw_rect(Rect2(x - 12.0, -w * 0.5, 12.0, w), Color(1, 1, 1, 0.06))
			x += 12.0
			k += 1
		draw_rect(deck, INK, false, 3.0)
		# Geländer an beiden Seiten mit Pfosten
		for s in [-1.0, 1.0]:
			var y: float = s * (w * 0.5 - 5.0)
			draw_line(Vector2(-l * 0.5 + 6.0, y), Vector2(l * 0.5 - 6.0, y), WOOD_DARK, 7.0)
			draw_line(Vector2(-l * 0.5 + 6.0, y - 2.0), Vector2(l * 0.5 - 6.0, y - 2.0), WOOD.lightened(0.15), 2.0)
			var posts := maxi(int(l / 70.0), 1)
			for i in posts + 1:
				var px := -l * 0.5 + 8.0 + (l - 16.0) * float(i) / posts
				draw_circle(Vector2(px, y), 6.0, WOOD_DARK)
				draw_arc(Vector2(px, y), 6.0, 0.0, TAU, 12, INK, 2.0)
	draw_set_transform(Vector2.ZERO)
