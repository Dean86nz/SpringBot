class_name MapScreen
extends CanvasLayer
## Übersichtskarte: zeigt die ganze Welt auf einen Blick, wo es schon grün und wo noch grau ist,
## dazu Wege, Wasser, die Namen der Gebiete, Bienenstock und Roboter (blinkt).
## Öffnen aus dem Pause-Menü oder direkt (Karte-Taste); schließen mit B / Esc / Karte-Taste.
## Die Masken kommen live vom Boden (GroundView), daher keine eigene Rechenarbeit beim Öffnen.

signal closed

const MAP_SIZE := Vector2(1120, 840)
const SHADER := preload("res://src/ui/map.gdshader")
const INK := Color(0.30, 0.36, 0.44)

var _map := ColorRect.new()
var _overlay := Control.new()
var _title := Label.new()
var _hint := Label.new()
var _world_px := Vector2.ONE       # Kartengröße in Weltpixeln
var _labels: Array[Dictionary] = []   # {pos: 0..1, name}
var _robot := Vector2.ZERO          # 0..1
var _hive := Vector2.ZERO           # 0..1
var _t := 0.0
var _keys_version := -1


## ground: Boden mit seinen Masken; areas: Gebiete (für Farben und Namen); world_px: Kartengröße.
func setup(ground: GroundView, areas: Areas, world_px: Vector2, map_cells: Vector2) -> void:
	_world_px = world_px
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for k in ["mask", "terrain_tex", "area_a", "use_areas"]:
		mat.set_shader_parameter(k, ground.shader_value(k))
	mat.set_shader_parameter("px_size", MAP_SIZE)
	_map.material = mat
	if areas:
		var centers := areas.centers()
		for i in centers.size():
			_labels.append({"pos": centers[i] / map_cells, "name": areas.name_of(i)})


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.16, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := MenuKit.panel(center, 20, 10)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	box.add_child(_title)
	_map.custom_minimum_size = MAP_SIZE
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_map)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_map.add_child(_overlay)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_hint)


## robot / hive in Weltpixeln, coverage 0..1.
func open(robot: Vector2, hive: Vector2, coverage: float) -> void:
	_robot = robot / _world_px
	_hive = hive / _world_px
	_title.text = "Karte   ·   Wiederhergestellt: %s %%" % Hud.format_percent(coverage)
	_keys_version = -1
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _keys_version != KeyHints.version:
		_keys_version = KeyHints.version
		_hint.text = KeyHints.fill("Grau = hier ist noch nichts wiederhergestellt   ·   {back}: zurück")
	_overlay.queue_redraw()


func _draw_overlay() -> void:
	var font := ThemeDB.fallback_font
	for l in _labels:
		var p: Vector2 = l["pos"] * MAP_SIZE
		var text: String = l["name"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		_overlay.draw_string_outline(font, p + Vector2(-w * 0.5, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0.15, 0.22, 0.17, 0.85))
		_overlay.draw_string(font, p + Vector2(-w * 0.5, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0.94))
	# Bienenstock
	var h := _hive * MAP_SIZE
	Disc.ring_dot(_overlay, h, 8.0, Color(1.0, 0.80, 0.30), INK, 3.0)
	# Roboter: pulsierender Ring und Punkt
	var r := _robot * MAP_SIZE
	var pulse := fmod(_t, 1.2) / 1.2
	_overlay.draw_arc(r, 10.0 + pulse * 22.0, 0, TAU, 32, Color(1, 1, 1, 1.0 - pulse), 3.0)
	Disc.ring_dot(_overlay, r, 10.0, Color(0.96, 0.95, 0.90), INK, 3.5)
	Disc.dot(_overlay, r + Vector2(3, 0), 3.5, Color(0.55, 0.80, 0.95))
