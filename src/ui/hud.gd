class_name Hud
extends CanvasLayer
## Prozentanzeige der begrünten Fläche (oben Mitte), Pollen (oben links),
## Tastenhinweis (unten links) und Versionsnummer (unten rechts).
## Unter der Prozentanzeige erscheint beim Betreten eines Gebiets kurz und dezent sein Name.
## Unten in der Mitte erscheinen Hinweise (Einführung) in einem dezenten Kasten; die Tasten im
## Hinweis und unten links passen sich dem Gerät an (KeyHints).

var _percent := Label.new()
var _pollen := Label.new()
var _hint := Label.new()
var _version := Label.new()
var _region := Label.new()
var _region_tw: Tween
var banner_cfg: Dictionary = {}   # Zeiten der Namenseinblendung (regions.json "banner")
const TIP_WIDTH := 1000.0
var _tip_panel := PanelContainer.new()
var _tip := Label.new()
var _tip_raw := ""        # Hinweis mit {Platzhaltern}, damit er beim Gerätewechsel neu gefüllt wird
var _tip_left := 0.0      # Sekunden, bis der Hinweis ausblendet
var _keys_version := -1


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
	_region.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_region.offset_top = 92
	_region.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region.add_theme_font_size_override("font_size", 30)
	_region.add_theme_color_override("font_color", Color(1, 1, 0.94, 0.9))
	_region.add_theme_color_override("font_outline_color", Color(0.22, 0.36, 0.24, 0.6))
	_region.add_theme_constant_override("outline_size", 8)
	_region.modulate.a = 0.0
	add_child(_region)
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.24, 0.18, 0.78)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_tip_panel.add_theme_stylebox_override("panel", style)
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.modulate.a = 0.0
	# Zeile über die ganze Breite unten, der Kasten darin mittig
	var row := CenterContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -190
	row.offset_bottom = -56
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tip.add_theme_font_size_override("font_size", 28)
	_tip.add_theme_color_override("font_color", Color(1, 1, 0.94))
	_tip_panel.add_child(_tip)
	row.add_child(_tip_panel)


func _process(delta: float) -> void:
	if _keys_version != KeyHints.version:
		_keys_version = KeyHints.version
		_hint.text = KeyHints.fill("{tree}: Skilltree   ·   {map}: Karte   ·   {pause}: Pause")
		_set_tip_text()
	if _tip_left > 0.0:
		_tip_left -= delta
		_tip_panel.modulate.a = minf(_tip_panel.modulate.a + delta * 2.5, 1.0)
	elif _tip_panel.modulate.a > 0.0:
		_tip_panel.modulate.a = maxf(_tip_panel.modulate.a - delta * 1.5, 0.0)


## Hinweis einblenden (text mit {Tasten}), nach sec Sekunden blendet er aus.
func show_tip(text: String, sec: float) -> void:
	_tip_raw = text
	_set_tip_text()
	_tip_left = sec


## Lange Hinweise umbrechen (höchstens TIP_WIDTH breit), kurze bleiben einzeilig und schmal.
func _set_tip_text() -> void:
	_tip.text = KeyHints.fill(_tip_raw)
	var w := _tip.get_theme_font("font").get_string_size(_tip.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if w > TIP_WIDTH else TextServer.AUTOWRAP_OFF
	_tip.custom_minimum_size = Vector2(TIP_WIDTH if w > TIP_WIDTH else 0.0, 0.0)
	_tip.reset_size()
	_tip_panel.reset_size()


## Hinweis vorzeitig ausblenden (z. B. wenn der Spieler schon tut, was er sagt).
func hide_tip() -> void:
	_tip_left = 0.0


func tip_visible() -> bool:
	return _tip_left > 0.0 or _tip_panel.modulate.a > 0.0


func set_coverage(fraction: float) -> void:
	_percent.text = "Frühling: %s %%" % format_percent(fraction)


## Prozentanzeige springt kurz auf (bei jedem vollen Zehntel).
func pulse() -> void:
	_percent.pivot_offset = _percent.size * 0.5
	var tw := create_tween()
	_percent.scale = Vector2.ONE * 1.4
	_percent.modulate = Color(1.0, 0.95, 0.6)
	tw.tween_property(_percent, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_percent, "modulate", Color.WHITE, 0.9)


## Name des Gebiets langsam ein- und wieder ausblenden.
func show_region(region_name: String) -> void:
	if region_name.is_empty():
		return
	if _region_tw:
		_region_tw.kill()
	_region.text = "~  %s  ~" % region_name
	_region_tw = create_tween()
	_region_tw.tween_property(_region, "modulate:a", 1.0, float(banner_cfg.get("fade_in_sec", 0.8)))
	_region_tw.tween_interval(float(banner_cfg.get("hold_sec", 2.5)))
	_region_tw.tween_property(_region, "modulate:a", 0.0, float(banner_cfg.get("fade_out_sec", 1.4)))


func set_pollen(amount: float, per_sec: float) -> void:
	_pollen.text = "Pollen: %s  (+%s/s)" % [Fmt.int_str(floori(amount)), Fmt.num(snappedf(per_sec, 0.1))]


## 0,1234 → "12,3" (deutsches Komma). Unter 100 % nie auf 100 aufrunden.
static func format_percent(fraction: float) -> String:
	var tenths := floori(clampf(fraction, 0.0, 1.0) * 1000.0)
	return "%d,%d" % [tenths / 10, tenths % 10]
