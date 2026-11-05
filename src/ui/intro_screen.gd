class_name IntroScreen
extends CanvasLayer
## Kurze Einleitung beim Neuen Spiel: ein paar Bilder mit Überschrift und zwei, drei Sätzen
## (data/tutorial.json, "intro"). A / Enter / Klick: weiter, B / Esc: überspringen.
## Das erste Bild ist noch grau, das letzte grün: die Einleitung erzählt den Frühling im Kleinen.

signal finished

const GREY := Color(0.42, 0.44, 0.46, 0.96)
const GREEN := Color(0.20, 0.36, 0.22, 0.96)

var _slides: Array = []
var _page := 0
var _style := StyleBoxFlat.new()
var _title := Label.new()
var _text := Label.new()
var _dots := Label.new()
var _hint := Label.new()
var _next := Button.new()
var _keys_version := -1


func setup(slides: Array) -> void:
	_slides = slides


func _ready() -> void:
	layer = 36
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.14, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	_style.set_corner_radius_all(22)
	_style.set_border_width_all(4)
	_style.border_color = Color(0.62, 0.84, 0.45)
	panel.add_theme_stylebox_override("panel", _style)
	center.add_child(panel)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 40)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1000, 0)
	box.add_theme_constant_override("separation", 22)
	m.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	box.add_child(_title)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 30)
	_text.add_theme_constant_override("line_spacing", 6)
	box.add_child(_text)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots.add_theme_font_size_override("font_size", 30)
	_dots.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	box.add_child(_dots)
	var row := CenterContainer.new()
	box.add_child(row)
	_next.custom_minimum_size = Vector2(360, 64)
	_next.add_theme_font_size_override("font_size", 26)
	_next.pressed.connect(_advance)
	row.add_child(_next)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_hint)


func open() -> void:
	if _slides.is_empty():
		finished.emit()
		return
	_page = 0
	visible = true
	get_tree().paused = true
	_show()


func _show() -> void:
	var s: Dictionary = _slides[_page]
	_title.text = str(s.get("title", ""))
	_text.text = str(s.get("text", ""))
	var dots := ""
	for i in _slides.size():
		dots += ("●" if i == _page else "○") + (" " if i < _slides.size() - 1 else "")
	_dots.text = dots
	var t := 0.0 if _slides.size() < 2 else float(_page) / (_slides.size() - 1)
	_style.bg_color = GREY.lerp(GREEN, t)
	_next.text = "Los geht's!" if _page == _slides.size() - 1 else "Weiter"
	_next.grab_focus()
	_keys_version = -1


func _process(_delta: float) -> void:
	if visible and _keys_version != KeyHints.version:
		_keys_version = KeyHints.version
		_hint.text = KeyHints.fill("{next}: weiter   ·   {skip}: überspringen")


func _advance() -> void:
	if _page < _slides.size() - 1:
		_page += 1
		Sfx.play("select")
		_show()
	else:
		_finish()


func _finish() -> void:
	visible = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		Sfx.play("close")
		_finish()
		get_viewport().set_input_as_handled()
