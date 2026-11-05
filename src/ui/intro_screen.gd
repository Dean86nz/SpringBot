class_name IntroScreen
extends CanvasLayer
## Kurze Einleitung beim Neuen Spiel: drei Seiten mit bewegtem Bild (IntroArt), Überschrift und
## ein, zwei Sätzen (data/tutorial.json, "intro"). A / Enter / Klick: weiter, B / Esc: überspringen.
## Die Seiten erzählen den Frühling im Kleinen: grau, der Roboter erwacht, alles blüht.
## Seitenwechsel blenden weich über; nach „Los geht's!“ (nicht beim Überspringen) gibt es Blütenregen.

signal finished

const GREY := Color(0.36, 0.38, 0.40, 0.97)
const GREEN := Color(0.18, 0.33, 0.21, 0.97)
const FADE_OUT := 0.18
const FADE_IN := 0.35

var skipped := false   # zuletzt übersprungen statt bis zum Ende durchgeklickt
var _slides: Array = []
var _page := 0
var _style := StyleBoxFlat.new()
var _art := IntroArt.new()
var _content := VBoxContainer.new()   # Bild und Text, blendet beim Seitenwechsel über
var _title := Label.new()
var _text := Label.new()
var _dots := Label.new()
var _hint := Label.new()
var _next := Button.new()
var _keys_version := -1
var _tw: Tween


func setup(slides: Array) -> void:
	_slides = slides


func _ready() -> void:
	layer = 36
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.14, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	_style.set_corner_radius_all(26)
	_style.set_border_width_all(5)
	_style.border_color = Color(0.62, 0.84, 0.45)
	_style.shadow_color = Color(0, 0, 0, 0.3)
	_style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", _style)
	center.add_child(panel)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	m.add_child(box)
	_content.add_theme_constant_override("separation", 18)
	box.add_child(_content)
	# Bild mit Rahmen
	var frame := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.set_border_width_all(4)
	fs.border_color = Color(0.30, 0.36, 0.44)
	fs.set_corner_radius_all(14)
	fs.set_expand_margin_all(2)
	frame.add_theme_stylebox_override("panel", fs)
	_art.custom_minimum_size = Vector2(1040, 400)
	frame.add_child(_art)
	_content.add_child(frame)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 54)
	_title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	_title.add_theme_color_override("font_outline_color", Color(0.12, 0.18, 0.14, 0.6))
	_title.add_theme_constant_override("outline_size", 10)
	_content.add_child(_title)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(1040, 0)
	_text.add_theme_font_size_override("font_size", 32)
	_text.add_theme_constant_override("line_spacing", 8)
	_content.add_child(_text)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots.add_theme_font_size_override("font_size", 28)
	_dots.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	box.add_child(_dots)
	var row := CenterContainer.new()
	box.add_child(row)
	_next.custom_minimum_size = Vector2(380, 66)
	_next.add_theme_font_size_override("font_size", 28)
	_next.pressed.connect(_advance)
	row.add_child(_next)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_hint)


func open() -> void:
	skipped = false
	if _slides.is_empty():
		finished.emit()
		return
	_page = 0
	visible = true
	get_tree().paused = true
	_show()
	_content.modulate.a = 0.0
	_fade_in()


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
	_art.show_page(str(s.get("art", "")))


func _fade_in() -> void:
	_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.tween_property(_content, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)


func _process(_delta: float) -> void:
	if visible and _keys_version != KeyHints.version:
		_keys_version = KeyHints.version
		_hint.text = KeyHints.fill("{next}: weiter   ·   {skip}: überspringen")


func _advance() -> void:
	if _tw and _tw.is_running():
		_tw.kill()   # schnell weitergeklickt: Übergang abkürzen
		_show()
		_content.modulate.a = 1.0
	if _page >= _slides.size() - 1:
		_finish()
		return
	Sfx.play("select")
	_page += 1
	_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw.tween_property(_content, "modulate:a", 0.0, FADE_OUT)
	_tw.tween_callback(func() -> void:
		_show()
		_fade_in())


func _finish() -> void:
	if _tw:
		_tw.kill()
	visible = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		Sfx.play("close")
		skipped = true
		_finish()
		get_viewport().set_input_as_handled()
