class_name TravelScreen
extends CanvasLayer
## Reisekarte (Phase 3): alle Regionen als Stationen auf einer geschwungenen Route. Fertige Regionen
## sind grün mit Häkchen, die aktuelle pulsiert, freie leuchten, gesperrte und spätere sind verhüllt.
## Links / rechts wählt, A reist (nur zu freien Regionen), B schließt. Öffnen aus dem Pause-Menü
## („Reisen“) oder nach dem Fest („Weiterreisen“); main.gd lädt dann die gewählte Region.

signal travel_chosen(id: String)
signal closed

## Eine Station: {id, name, state ("done", "current", "open", "locked", "planned"), progress 0..1, needs}
var stations: Array[Dictionary] = []
var _sel := 0
var _t := 0.0
var _route := Control.new()
var _name := Label.new()
var _status := Label.new()
var _hint := Label.new()
var _keys_version := -1


func _ready() -> void:
	layer = 33
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(MenuKit.GROUP)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.14, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := MenuKit.panel(center, 28, 14)
	MenuKit.title(box, "Reise")
	_route.custom_minimum_size = Vector2(1200, 340)
	_route.draw.connect(_draw_route)
	box.add_child(_route)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 40)
	_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	box.add_child(_name)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 26)
	box.add_child(_status)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_hint)


func open(p_stations: Array[Dictionary]) -> void:
	stations = p_stations
	_sel = 0
	for i in stations.size():
		if stations[i]["state"] == "current":
			_sel = i
	# Gleich die nächste freie Region vorwählen, wenn es eine gibt
	for i in stations.size():
		if stations[i]["state"] == "open":
			_sel = i
			break
	visible = true
	get_tree().paused = true
	get_viewport().gui_release_focus()   # sonst drückt A den Knopf des Menüs darunter
	_keys_version = -1
	_update_text()


func close() -> void:
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _keys_version != KeyHints.version:
		_keys_version = KeyHints.version
		_update_text()
	_route.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		var st: Dictionary = stations[_sel]
		if st["state"] in ["open", "done"]:
			Sfx.play("open")
			visible = false
			get_viewport().set_input_as_handled()
			travel_chosen.emit.call_deferred(st["id"])   # lädt die Szene neu: erst nach der Eingabe-Verarbeitung
			return
		else:
			Sfx.play("deny")
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		Sfx.play("close")
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _move(d: int) -> void:
	var n := clampi(_sel + d, 0, stations.size() - 1)
	if n != _sel:
		_sel = n
		Sfx.play_throttled("select", 0.06)
		_update_text()


func _update_text() -> void:
	if stations.is_empty():
		return
	var st: Dictionary = stations[_sel]
	var hidden: bool = st["state"] in ["locked", "planned"]
	_name.text = "???" if st["state"] == "planned" else str(st["name"])
	match st["state"]:
		"done": _status.text = "Blüht schon – besuchen"
		"current": _status.text = "Du bist hier   ·   Frühling: %s %%" % Hud.format_percent(float(st.get("progress", 0.0)))
		"open": _status.text = "Frei – hierhin reisen" + ("   ·   Frühling: %s %%" % Hud.format_percent(float(st["progress"])) if float(st.get("progress", 0.0)) > 0.0 else "")
		"locked": _status.text = "Erst muss %s blühen" % str(st.get("needs", ""))
		_: _status.text = "Kommt später"
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.55) if hidden else Color(0.80, 0.95, 0.70))
	_hint.text = KeyHints.fill("links / rechts: wählen   ·   {confirm}: reisen   ·   {back}: zurück")


## Position einer Station auf der geschwungenen Route.
func _station_pos(i: int) -> Vector2:
	var s := _route.size.max(_route.custom_minimum_size)
	var n := maxi(stations.size() - 1, 1)
	var x := 110.0 + (s.x - 220.0) * i / n
	return Vector2(x, s.y * 0.5 + sin(i * 1.9 + 0.6) * 70.0)


func _draw_route() -> void:
	var font := ThemeDB.fallback_font
	var ink := Color(0.30, 0.36, 0.44)
	# gepunkteter Weg zwischen den Stationen
	for i in stations.size() - 1:
		var a := _station_pos(i)
		var b := _station_pos(i + 1)
		var walked: bool = stations[i]["state"] == "done" or (stations[i]["state"] == "current" and stations[i + 1]["state"] in ["open", "done"])
		var steps := int(a.distance_to(b) / 18.0)
		for k in steps:
			var t := float(k) / steps
			var p := a.lerp(b, t) + Vector2(0, sin(t * PI) * -26.0)
			Disc.dot(_route, p, 4.0, Color(0.62, 0.84, 0.45) if walked else Color(0.55, 0.55, 0.55, 0.6))
	for i in stations.size():
		var st: Dictionary = stations[i]
		var p := _station_pos(i)
		var r := 46.0 if i == _sel else 38.0
		if i == _sel:
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			Disc.dot(_route, p, r + 10.0 + pulse * 6.0, Color(1.0, 0.92, 0.55, 0.35))
		var col := Color(0.50, 0.50, 0.52)
		match st["state"]:
			"done": col = Color(0.46, 0.76, 0.33)
			"current": col = Color(0.95, 0.80, 0.35)
			"open": col = Color(0.62, 0.84, 0.95)
		Disc.ring_dot(_route, p, r, col, ink, 4.0)
		var mark := "?"
		match st["state"]:
			"done": mark = "✓"
			"current": mark = "★"
			"open": mark = "→"
		var fs := 40
		var w := font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_route.draw_string(font, p + Vector2(-w * 0.5, 14), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1))
		var label := "???" if st["state"] == "planned" else str(st["name"])
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		_route.draw_string_outline(font, p + Vector2(-lw * 0.5, r + 34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0.12, 0.16, 0.14))
		_route.draw_string(font, p + Vector2(-lw * 0.5, r + 34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0.94) if st["state"] != "planned" else Color(1, 1, 1, 0.5))
		if float(st.get("progress", 0.0)) > 0.0 and st["state"] != "planned":   # kleiner Fortschrittsring
			_route.draw_arc(p, r + 6.0, -PI / 2.0, -PI / 2.0 + TAU * float(st["progress"]), 40, Color(0.55, 0.90, 0.40), 4.0)
