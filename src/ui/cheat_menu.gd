class_name CheatMenu
extends CanvasLayer
## Cheat-Menü NUR zum Testen. main.gd hängt es ausschließlich in Debug-Builds ein
## (OS.is_debug_build()); in der Release-EXE existiert es nicht.
## Öffnen: PC F12, Ally L3 + R3 (beide Sticks drücken) 1 s halten. Schließen: B, Esc oder F12.

signal reset_requested
signal pollen_requested
signal unlock_all_requested

const HOLD_SECONDS := 1.0

var _panel := PanelContainer.new()
var _box := VBoxContainer.new()
var _info := Label.new()
var _hold := 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.16, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_panel.add_child(margin)
	margin.add_child(_box)
	_box.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "CHEATS (nur Debug-Build)"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	_add("+100.000 Pollen", func() -> void: pollen_requested.emit())
	_add("Alles freischalten (ganzer Skilltree)", func() -> void: unlock_all_requested.emit())
	_add("Zeit ×10 an/aus", func() -> void: Engine.time_scale = 1.0 if Engine.time_scale > 1.0 else 10.0)
	_add("Spielstand zurücksetzen", func() -> void:
		close()
		reset_requested.emit())
	_add("Schließen", close)
	_info.add_theme_font_size_override("font_size", 22)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_info)


func _add(text: String, cb: Callable, disabled: bool = false) -> void:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.custom_minimum_size = Vector2(620, 56)
	b.add_theme_font_size_override("font_size", 24)
	if cb.is_valid():
		b.pressed.connect(func() -> void:
			cb.call()
			_refresh_info())
	_box.add_child(b)


func _refresh_info() -> void:
	_info.text = "Zeit ×%d" % int(Engine.time_scale)


func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh_info()
	for c in _box.get_children():
		if c is Button and not (c as Button).disabled:
			(c as Button).grab_focus()
			break


func close() -> void:
	visible = false
	get_tree().paused = false


func _process(delta: float) -> void:
	if visible:
		return
	var held := false
	for dev in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(dev, JOY_BUTTON_LEFT_STICK) and Input.is_joy_button_pressed(dev, JOY_BUTTON_RIGHT_STICK):
			held = true
	# Echte Zeit, damit Zeit ×10 das Halten nicht verkürzt
	_hold = _hold + delta / maxf(Engine.time_scale, 0.001) if held else 0.0
	if _hold >= HOLD_SECONDS and not MenuKit.any_open(get_tree()):
		_hold = 0.0
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).keycode == KEY_F12:
		if visible:
			close()
		elif not MenuKit.any_open(get_tree()):
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
