class_name PauseMenu
extends CanvasLayer
## Pause-Menü: Weiterspielen, Karte, Lautstärke, Steuerung, Titelbildschirm oder Spiel beenden.
## Öffnen/Schließen steuert main.gd (Start / Esc), dort wird auch gespeichert. Pausiert das Spiel, solange es offen ist.
## „Karte“ öffnet die Übersichtskarte (MapScreen, über main.gd). „Lautstärke“: zwei Regler für Musik und
## Klänge (Sfx.set_volume). „Steuerung“ zeigt alle Tasten zum Nachlesen, passend zum Gerät (data/tutorial.json, "controls").

signal title_requested
signal quit_requested
signal map_requested

var controls: Array = []   # Zeilen der Steuerungs-Seite: {head} oder {key, text}
var _box: VBoxContainer
var _on_controls := false
var _on_volume := false
var _keys_version := -1


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.16, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = MenuKit.panel(center, 32)
	_show_main()


func open() -> void:
	visible = true
	get_tree().paused = true
	_show_main()


func close() -> void:
	visible = false
	get_tree().paused = false


## Auf der Steuerungs-Seite führt B / Esc zurück zum Pause-Menü statt ins Spiel.
func on_subpage() -> bool:
	return _on_controls or _on_volume


func back() -> void:
	Sfx.play("close")
	_show_main()


func _show_main() -> void:
	_clear()
	_on_controls = false
	_on_volume = false
	MenuKit.title(_box, "Pause")
	MenuKit.button(_box, "Weiterspielen").pressed.connect(close)
	MenuKit.button(_box, "Karte").pressed.connect(func() -> void: map_requested.emit())
	MenuKit.button(_box, "Lautstärke").pressed.connect(func() -> void:
		Sfx.play("open")
		_show_volume())
	MenuKit.button(_box, "Steuerung").pressed.connect(func() -> void:
		Sfx.play("open")
		_show_controls())
	MenuKit.button(_box, "Zum Titelbildschirm").pressed.connect(func() -> void:
		visible = false
		title_requested.emit())
	MenuKit.button(_box, "Spiel beenden").pressed.connect(func() -> void: quit_requested.emit())
	MenuKit.focus_first(_box)


func _show_controls() -> void:
	_clear()
	_on_controls = true
	_keys_version = KeyHints.version
	MenuKit.title(_box, "Steuerung")
	var sub := Label.new()
	sub.text = "Controller" if KeyHints.pad else "Tastatur und Maus"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.modulate = Color(1, 1, 1, 0.7)
	_box.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 6)
	_box.add_child(grid)
	for row: Dictionary in controls:
		if row.has("head"):
			for k in 2:
				var h := Label.new()
				h.text = str(row["head"]) if k == 0 else ""
				h.add_theme_font_size_override("font_size", 26)
				h.add_theme_color_override("font_color", Color(0.72, 0.95, 0.60))
				grid.add_child(h)
			continue
		var key_name := KeyHints.key(str(row.get("key", "")))
		if key_name == "–":
			continue   # auf diesem Gerät keine Taste dafür (z. B. Vollbild am Controller)
		var key := Label.new()
		key.text = key_name
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key.add_theme_font_size_override("font_size", 24)
		key.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		grid.add_child(key)
		var what := Label.new()
		what.text = str(row.get("text", ""))
		what.add_theme_font_size_override("font_size", 24)
		grid.add_child(what)
	var note := Label.new()
	note.text = "Die Tasten passen sich an: Controller oder Tastatur, je nachdem, was du zuletzt benutzt hast."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 18)
	note.modulate = Color(1, 1, 1, 0.6)
	_box.add_child(note)
	MenuKit.button(_box, "Zurück").pressed.connect(back)
	MenuKit.focus_first(_box)


func _show_volume() -> void:
	_clear()
	_on_volume = true
	MenuKit.title(_box, "Lautstärke")
	var first: HSlider = null
	for row: Array in [["Musik", "music"], ["Klänge", "sfx"]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 20)
		_box.add_child(line)
		var name_l := Label.new()
		name_l.text = row[0]
		name_l.custom_minimum_size = Vector2(130, 0)
		name_l.add_theme_font_size_override("font_size", 26)
		line.add_child(name_l)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 10
		slider.value = roundf(float(Sfx.volume[row[1]]) * 10.0) * 10.0
		slider.custom_minimum_size = Vector2(320, 48)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_style_slider(slider)
		slider.focus_entered.connect(func() -> void: name_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55)))
		slider.focus_exited.connect(func() -> void: name_l.remove_theme_color_override("font_color"))
		line.add_child(slider)
		var val := Label.new()
		val.text = "%d %%" % int(slider.value)
		val.custom_minimum_size = Vector2(90, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.add_theme_font_size_override("font_size", 26)
		line.add_child(val)
		var kind: String = row[1]
		slider.value_changed.connect(func(v: float) -> void:
			val.text = "%d %%" % int(v)
			Sfx.set_volume(kind, v / 100.0)
			if kind == "sfx":
				Sfx.play_throttled("select", 0.08))   # Probeklang in der neuen Lautstärke
		if first == null:
			first = slider
	var note := Label.new()
	note.text = KeyHints.fill("{select}: Regler wählen   ·   links / rechts: leiser / lauter")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 18)
	note.modulate = Color(1, 1, 1, 0.6)
	_box.add_child(note)
	MenuKit.button(_box, "Zurück").pressed.connect(back)
	first.grab_focus()


## Dicke Schiene, gefüllter Teil grün, großer Knopf; gewählt (Fokus) wird der Knopf gelb mit Ring.
func _style_slider(slider: HSlider) -> void:
	var rail := StyleBoxFlat.new()
	rail.bg_color = Color(0.12, 0.16, 0.14)
	rail.set_corner_radius_all(8)
	rail.content_margin_top = 6
	rail.content_margin_bottom = 6
	var fill := rail.duplicate() as StyleBoxFlat
	fill.bg_color = Color(0.52, 0.80, 0.40)
	slider.add_theme_stylebox_override("slider", rail)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber", _knob(Color(0.96, 0.95, 0.90), Color(0.30, 0.36, 0.44)))
	slider.add_theme_icon_override("grabber_highlight", _knob(Color(1.0, 0.86, 0.35), Color(1, 1, 1)))


static func _knob(fill: Color, ring: Color) -> ImageTexture:
	var n := 30
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(n, n) * 0.5)
			var a := clampf(n * 0.5 - 0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(ring if d > n * 0.5 - 4.0 else fill, a))
	return ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	# Gerät gewechselt, während die Seite offen ist: Tasten neu anzeigen
	if visible and _on_controls and _keys_version != KeyHints.version:
		_show_controls()


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
