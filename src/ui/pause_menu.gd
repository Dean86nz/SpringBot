class_name PauseMenu
extends CanvasLayer
## Pause-Menü: Weiterspielen, Steuerung, Titelbildschirm oder Spiel beenden. Öffnen/Schließen steuert
## main.gd (Start / Esc), dort wird auch gespeichert. Pausiert das Spiel, solange es offen ist.
## „Steuerung“ zeigt alle Tasten zum Nachlesen, passend zum Gerät (data/tutorial.json, "controls").

signal title_requested
signal quit_requested

var controls: Array = []   # Zeilen der Steuerungs-Seite: {head} oder {key, text}
var _box: VBoxContainer
var _on_controls := false
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
	return _on_controls


func back() -> void:
	Sfx.play("close")
	_show_main()


func _show_main() -> void:
	_clear()
	_on_controls = false
	MenuKit.title(_box, "Pause")
	MenuKit.button(_box, "Weiterspielen").pressed.connect(close)
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


func _process(_delta: float) -> void:
	# Gerät gewechselt, während die Seite offen ist: Tasten neu anzeigen
	if visible and _on_controls and _keys_version != KeyHints.version:
		_show_controls()


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
