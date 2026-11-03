class_name TitleScreen
extends CanvasLayer
## Titelbildschirm über der (pausierten) Welt: Weiterspielen, Neues Spiel, Beenden.
## Gibt es einen Spielstand, verlangt „Neues Spiel“ eine Bestätigung. Hinter dem Menü
## sieht man den eigenen Garten, darüber fällt ein leichter Blätterregen.

signal continue_requested
signal new_game_requested
signal quit_requested

var _box: VBoxContainer
var _info := Label.new()
var _rain := PetalFx.new()
var _has_save := false


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.95, 0.97, 0.9, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_rain.capacity = 300
	_rain.fall = 160.0
	add_child(_rain)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 28)
	add_child(col)
	var title := Label.new()
	title.text = "Frühlings-Roboter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	title.add_theme_color_override("font_outline_color", Color(0.30, 0.55, 0.28))
	title.add_theme_constant_override("outline_size", 28)
	col.add_child(title)
	var sub := Label.new()
	sub.text = "Bring den Frühling zurück in die graue Welt."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color(1, 1, 1))
	sub.add_theme_color_override("font_outline_color", Color(0.30, 0.40, 0.30))
	sub.add_theme_constant_override("outline_size", 10)
	col.add_child(sub)
	var center := CenterContainer.new()
	col.add_child(center)
	_box = MenuKit.panel(center, 28)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 24)
	_info.add_theme_color_override("font_color", Color(0.85, 0.95, 0.8))
	var version := Label.new()
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -16
	version.offset_bottom = -10
	version.text = "v" + Game.version() + (" DEBUG" if OS.is_debug_build() else "")
	version.add_theme_font_size_override("font_size", 20)
	version.add_theme_color_override("font_outline_color", Color(0.3, 0.3, 0.35))
	version.add_theme_constant_override("outline_size", 6)
	add_child(version)


## info: Kurzbeschreibung des Spielstands ("" = keiner vorhanden).
func open(info: String) -> void:
	_has_save = info != ""
	_info.text = info
	_show_main()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible:
		_rain.rain(get_viewport().get_visible_rect().size.x, 10.0, delta)


func _show_main() -> void:
	_clear()
	if _has_save:
		_box.add_child(_info)
		MenuKit.button(_box, "Weiterspielen").pressed.connect(func() -> void: continue_requested.emit())
		MenuKit.button(_box, "Neues Spiel").pressed.connect(_show_confirm)
	else:
		MenuKit.button(_box, "Spielen").pressed.connect(func() -> void: new_game_requested.emit())
	MenuKit.button(_box, "Beenden").pressed.connect(func() -> void: quit_requested.emit())
	MenuKit.focus_first(_box)


func _show_confirm() -> void:
	Sfx.play("open")
	_clear()
	var l := Label.new()
	l.text = "Wirklich neu beginnen?\nDer bisherige Garten geht verloren."
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)
	_box.add_child(l)
	MenuKit.button(_box, "Zurück").pressed.connect(_back)
	MenuKit.button(_box, "Ja, neu beginnen").pressed.connect(func() -> void: new_game_requested.emit())
	MenuKit.focus_first(_box)


func _back() -> void:
	Sfx.play("close")
	_show_main()


## Knöpfe entfernen; das Info-Label bleibt erhalten und wird nur abgehängt.
func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		if c != _info:
			c.queue_free()


func _exit_tree() -> void:
	if _info.get_parent() == null:
		_info.free()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _has_save and _info.get_parent() == null:
			_back()
		get_viewport().set_input_as_handled()
