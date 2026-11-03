class_name EndScreen
extends CanvasLayer
## Ende: Die ganze Welt blüht. Zeigt einen kurzen Rückblick und lässt weiterfahren
## oder zum Titelbildschirm zurückkehren. Erscheint nur einmal je Spielstand.

signal title_requested

var _box: VBoxContainer
var _stats := Label.new()
var _rain := PetalFx.new()


func _ready() -> void:
	layer = 32
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(1.0, 0.98, 0.9, 0.2)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_rain.capacity = 400
	_rain.fall = 160.0
	add_child(_rain)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = MenuKit.panel(center, 36, 16)
	MenuKit.title(_box, "Die Welt blüht wieder!").add_theme_font_size_override("font_size", 56)
	var text := Label.new()
	text.text = "Kein grauer Fleck mehr: Der kleine Roboter, seine Bienen\nund der Wind haben den Frühling überall hingebracht."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 26)
	_box.add_child(text)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_font_size_override("font_size", 28)
	_stats.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_box.add_child(_stats)
	MenuKit.button(_box, "Weiterfahren").pressed.connect(close)
	MenuKit.button(_box, "Zum Titelbildschirm").pressed.connect(func() -> void:
		close()
		title_requested.emit())


func open(play_sec: float, earned: float, bought: int, nodes: int, bees: int) -> void:
	_stats.text = "Spielzeit: %s\nPollen gesammelt: %s\nKnoten gekauft: %d von %d\nBienen: %d" % [
		format_time(play_sec), Fmt.int_str(floori(earned)), bought, nodes, bees]
	visible = true
	get_tree().paused = true
	MenuKit.focus_first(_box)
	_rain.burst(Vector2(get_viewport().get_visible_rect().size.x * 0.5, 120.0), 120, Vector2(200, 700), Vector2(2.0, 3.5), Vector2(9, 15), Vector2.DOWN, 1.4)


func close() -> void:
	visible = false
	get_tree().paused = false


func _process(delta: float) -> void:
	if visible:
		_rain.rain(get_viewport().get_visible_rect().size.x, 18.0, delta)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Sekunden → "1:05 h" oder "42 min".
static func format_time(sec: float) -> String:
	var m := floori(sec / 60.0)
	return "%d:%02d h" % [m / 60, m % 60] if m >= 60 else "%d min" % m
