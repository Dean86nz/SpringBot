class_name Disc
extends RefCounted
## Schneller Ersatz für draw_circle in Zeichnungen, die jedes Bild neu entstehen (Roboter, Bienen,
## Tiere): eine weiche Kreis-Textur als Rechteck. draw_circle, Polygone und Bögen kosten je Aufruf
## rund 15–20 µs, ein Textur-Rechteck 0,2 µs (gemessen, Godot 4.7). Ovale über draw_set_transform.

static var TEX := _make(64)
static var BIG := _make(256)   # für große Kreise (Teiche, Baumkronen), sonst wird der Rand unscharf


static func _make(n: int) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var h := n * 0.5
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(h, h))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(h - 0.5 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Gefüllter Kreis (in den aktuellen Zeichen-Koordinaten von ci).
static func dot(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(BIG if r > 24.0 else TEX, Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), false, col)


## Kreis mit Rand: erst der Rand als größerer Kreis, darüber die Füllung.
static func ring_dot(ci: CanvasItem, c: Vector2, r: float, col: Color, edge: Color, width: float) -> void:
	dot(ci, c, r + width * 0.5, edge)
	dot(ci, c, r - width * 0.5, col)
