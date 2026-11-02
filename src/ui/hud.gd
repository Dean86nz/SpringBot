class_name Hud
extends CanvasLayer
## Prozentanzeige der begrünten Fläche (oben Mitte), Pollen (oben links),
## Tastenhinweis (unten links) und Versionsnummer (unten rechts).

var _percent := Label.new()
var _pollen := Label.new()
var _hint := Label.new()
var _version := Label.new()


func _ready() -> void:
	layer = 10
	_percent.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_percent.offset_top = 24
	_percent.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_percent.add_theme_font_size_override("font_size", 48)
	_percent.add_theme_color_override("font_color", Color(1, 1, 1))
	_percent.add_theme_color_override("font_outline_color", Color(0.25, 0.45, 0.25))
	_percent.add_theme_constant_override("outline_size", 12)
	add_child(_percent)
	_pollen.position = Vector2(32, 24)
	_pollen.add_theme_font_size_override("font_size", 40)
	_pollen.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	_pollen.add_theme_color_override("font_outline_color", Color(0.45, 0.35, 0.10))
	_pollen.add_theme_constant_override("outline_size", 12)
	add_child(_pollen)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_left = 24
	_hint.offset_bottom = -10
	_hint.text = "Y / Tab: Upgrades   ·   Start / Esc: Pause"
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_hint.add_theme_color_override("font_outline_color", Color(0.3, 0.3, 0.35))
	_hint.add_theme_constant_override("outline_size", 6)
	add_child(_hint)
	_version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_version.offset_right = -16
	_version.offset_bottom = -10
	_version.text = "v" + Game.version() + (" DEBUG" if OS.is_debug_build() else "")
	_version.add_theme_font_size_override("font_size", 20)
	_version.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_version.add_theme_color_override("font_outline_color", Color(0.3, 0.3, 0.35))
	_version.add_theme_constant_override("outline_size", 6)
	add_child(_version)


func set_coverage(fraction: float) -> void:
	_percent.text = "Frühling: %s %%" % format_percent(fraction)


func set_pollen(amount: float, per_sec: float) -> void:
	_pollen.text = "Pollen: %s  (+%s/s)" % [Fmt.int_str(floori(amount)), Fmt.num(snappedf(per_sec, 0.1))]


## 0,1234 → "12,3" (deutsches Komma). Unter 100 % nie auf 100 aufrunden.
static func format_percent(fraction: float) -> String:
	var tenths := floori(clampf(fraction, 0.0, 1.0) * 1000.0)
	return "%d,%d" % [tenths / 10, tenths % 10]
