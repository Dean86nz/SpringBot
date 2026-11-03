class_name SkillTreeMenu
extends CanvasLayer
## Der Skilltree als Vollbild-Menü. Stick/D-Pad/Pfeile springen zum nächsten sichtbaren Knoten
## in diese Richtung, die Ansicht fährt mit. A/Enter kauft eine Stufe, das Menü bleibt offen.
## Rechter Stick (Maus ziehen, I/J/K/L) schiebt die Ansicht frei, gewählt ist dann der Knoten
## nahe der Bildmitte. LB/RB (Mausrad, Q/E) zoomen.
## Maus: Klick wählt, zweiter Klick kauft. Öffnen/Schließen steuert main.gd.
## Das Spiel läuft weiter (Pollen fließen), nur der Roboter steht.
## Leistung: Knoten, Linien und Symbole liegen auf einer statischen Ebene, die nur bei Änderungen
## (Kauf, Öffnen, Knoten wird bezahlbar) neu gezeichnet und zum Scrollen nur verschoben wird.
## Jedes Bild neu gezeichnet werden nur Auswahlring, Schein und Kauf-Effekt (Effekt-Ebene darunter).

const UNIT_PX := 170.0
const NODE_R := 40.0
const SPECIAL_R := 50.0
const VIEW_Y := 470.0           # Bildschirmhöhe, auf der der gewählte Knoten steht
const REPEAT_FIRST := 0.30
const REPEAT_NEXT := 0.15
const PAN_SPEED := 1300.0       # Bildschirm-Pixel pro Sekunde bei vollem Stick
const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.2
const ZOOM_START := 0.8
const ZOOM_RATE := 1.6          # Zoom-Faktor pro Sekunde beim Halten (exponentiell)
const WHEEL_STEP := 1.12
const DRAG_START_PX := 10.0
const BRANCH_COLORS := {
	"root": Color(1.0, 0.62, 0.76),
	"robot": Color(0.47, 0.72, 0.98),
	"growth": Color(0.52, 0.84, 0.40),
	"bees": Color(1.0, 0.78, 0.30),
}
const GOLD := Color(1.0, 0.84, 0.35)
const POOR := Color(1.0, 0.70, 0.66)

var _tree: SkillTree
var _layer := Node2D.new()         # statisch: Linien, Knoten, Symbole
var _fx := Node2D.new()            # jedes Bild: Schein, Auswahl, Kauf-Effekt
var _petals := PetalFx.new()       # Blütenblätter beim Kauf
var _input := Control.new()        # fängt Mausklicks über die ganze Fläche
var _static_key := PackedByteArray()
var _title := Label.new()
var _info_name := Label.new()
var _info_special := Label.new()
var _info_desc := Label.new()
var _info_effect := Label.new()
var _info_cost := Label.new()
var _selected := "root"
var _view := Vector2.ZERO        # Mittelpunkt der Ansicht in Baum-Pixeln (geglättet)
var _repeat := 0.0
var _held := false
var _time := 0.0
var _pop: Dictionary = {}        # id → Restzeit des Kauf-Effekts
var _shake := 0.0
var _font: Font
var _zoom := ZOOM_START
var _free := false               # Ansicht frei geschoben statt der Auswahl folgend
var _bounds := Rect2()           # alle Knoten plus Rand, in Baum-Pixeln
var _press := false              # linke Maustaste gedrückt
var _dragged := 0.0              # Mausweg seit dem Drücken


func setup(tree: SkillTree) -> void:
	_tree = tree
	layer = 20
	visible = false
	add_to_group(MenuKit.GROUP)
	_font = ThemeDB.fallback_font
	_bounds = Rect2(_pos("root"), Vector2.ZERO)
	for id in _tree.order:
		_bounds = _bounds.expand(_pos(id))
	_bounds = _bounds.grow(UNIT_PX)
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.17, 0.14, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_input.set_anchors_preset(Control.PRESET_FULL_RECT)
	_input.gui_input.connect(_on_canvas_input)
	add_child(_input)
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_layer.draw.connect(_draw_tree)
	add_child(_layer)
	_layer.add_child(_petals)   # eigene Zeichenfläche: Blätter fliegen über den Knoten
	# Streifen hinter der Kopfzeile, damit Knoten den Titel nicht überdecken
	var strip := ColorRect.new()
	strip.color = Color(0.09, 0.14, 0.12, 0.92)
	strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	strip.offset_bottom = 76
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = 18
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_build_info()


func _build_info() -> void:
	var anchor := MarginContainer.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	anchor.add_theme_constant_override("margin_bottom", 20)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(center)
	var box := MenuKit.panel(center, 18, 4)
	box.custom_minimum_size = Vector2(900, 0)
	for l: Label in [_info_name, _info_special, _info_desc, _info_effect, _info_cost]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 24)
		box.add_child(l)
	_info_name.add_theme_font_size_override("font_size", 32)
	_info_special.text = "Besonderer Knoten"
	_info_special.add_theme_color_override("font_color", GOLD)
	_info_special.add_theme_font_size_override("font_size", 20)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.85))
	_info_effect.add_theme_color_override("font_color", Color(0.72, 0.95, 0.60))
	var hint := Label.new()
	hint.text = "Linker Stick / D-Pad: wählen  ·  Rechter Stick: schieben  ·  LB / RB: zoomen  ·  A: kaufen  ·  B: schließen\n" \
		+ "PC: Pfeile wählen  ·  Maus ziehen schiebt  ·  Mausrad / Q / E zoomt  ·  Enter oder zweiter Klick kauft  ·  Esc schließt"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.modulate = Color(1, 1, 1, 0.65)
	box.add_child(hint)


func open() -> void:
	visible = true
	if _tree.state(_selected) < SkillTree.State.AVAILABLE:
		_selected = "root"
	_view = _pos(_selected)
	_free = false
	_press = false
	_held = true   # Der Stick ist vom Fahren evtl. noch geneigt: erst nach dem Loslassen navigieren
	_static_key = PackedByteArray()
	_refresh()


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_shake = maxf(_shake - delta, 0.0)
	for id: String in _pop.keys():
		_pop[id] -= delta
		if _pop[id] <= 0.0:
			_pop.erase(id)
	_navigate(delta)
	_zoom_and_pan(delta)
	if not _free:
		_view = _view.lerp(_pos(_selected), clampf(10.0 * delta, 0.0, 1.0))
	_layer.position = _offset()
	_layer.scale = Vector2.ONE * _zoom
	_fx.position = _layer.position
	_fx.scale = _layer.scale
	_refresh()
	# Statische Ebene nur neu zeichnen, wenn sich Stufen oder Bezahlbarkeit geändert haben
	var key := _state_key()
	if key != _static_key:
		_static_key = key
		_layer.queue_redraw()
	_fx.queue_redraw()


## Stufe und Bezahlbarkeit aller Knoten als Bytes; ändert sich etwas, wird neu gezeichnet.
func _state_key() -> PackedByteArray:
	var k := PackedByteArray()
	k.resize(_tree.order.size())
	for i in _tree.order.size():
		var id := _tree.order[i]
		k[i] = _tree.level(id) * 2 + (1 if _tree.can_buy(id) else 0)
	return k


## Verschiebung von Baum-Pixeln auf Bildschirm-Pixel (vor dem Zoom: Bildschirm = Baum × Zoom + Offset).
func _offset() -> Vector2:
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920, 1080)
	return Vector2(size.x * 0.5, VIEW_Y) - _view * _zoom


func _to_tree(screen: Vector2) -> Vector2:
	return (screen - _offset()) / _zoom


## Zoom mit LB/RB bzw. Q/E (Halten), freies Schieben mit dem rechten Stick bzw. I/J/K/L.
func _zoom_and_pan(delta: float) -> void:
	var z := Input.get_axis("tree_zoom_out", "tree_zoom_in")
	if z != 0.0:
		_zoom = clampf(_zoom * exp(z * ZOOM_RATE * delta), ZOOM_MIN, ZOOM_MAX)
	var v := Input.get_vector("tree_pan_left", "tree_pan_right", "tree_pan_up", "tree_pan_down")
	if v != Vector2.ZERO:
		pan_by(v * PAN_SPEED * delta / _zoom)


## Schiebt die Ansicht um d Baum-Pixel; gewählt wird der sichtbare Knoten nahe der Mitte.
func pan_by(d: Vector2) -> void:
	_free = true
	_view = (_view + d).clamp(_bounds.position, _bounds.end)
	var near := nearest_node(_view, UNIT_PX * 0.75)
	if near != "":
		_select(near)


## Sichtbarer Knoten (gekauft oder kaufbar), der p am nächsten liegt, höchstens max_dist entfernt.
func nearest_node(p: Vector2, max_dist: float) -> String:
	var best := ""
	var best_d := max_dist
	for id in _tree.order:
		if _tree.state(id) < SkillTree.State.AVAILABLE:
			continue
		var d := _pos(id).distance_to(p)
		if d <= best_d:
			best_d = d
			best = id
	return best


## Richtung aus Stick, D-Pad, Pfeilen und WASD; Halten wiederholt nach kurzer Pause.
func _navigate(delta: float) -> void:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") \
		+ Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() < 0.5:
		_held = false
		_repeat = 0.0
		return
	if _held:
		_repeat -= delta
		if _repeat > 0.0:
			return
		_repeat = REPEAT_NEXT
	else:
		_held = true
		_repeat = REPEAT_FIRST
	var next := pick_neighbor(_selected, v.normalized())
	if next != "":
		_select(next)
	_free = false


## Nächster sichtbarer Knoten in Richtung dir (Einheitsvektor). Bevorzugt nahe Knoten mit kleinem
## Winkel zur Richtung; außerhalb von ±65° zählt nichts. Leer, wenn es keinen gibt.
func pick_neighbor(from: String, dir: Vector2) -> String:
	var best := ""
	var best_score := INF
	var p0 := _pos(from)
	for id in _tree.order:
		if id == from or _tree.state(id) < SkillTree.State.AVAILABLE:
			continue
		var d := _pos(id) - p0
		var dist := d.length()
		var c := d.dot(dir) / dist
		if c < 0.42:
			continue
		var score := dist * (1.0 + 2.5 * (1.0 - c))
		if score < best_score:
			best_score = score
			best = id
	return best


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_buy(_selected)
		get_viewport().set_input_as_handled()


## Maus: Ziehen (links, rechts oder Mitte) schiebt, Rad zoomt zur Mausposition,
## Loslassen ohne Ziehen wählt bzw. kauft.
func _on_canvas_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null:
		if mm.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			_dragged += mm.relative.length()
			if _dragged >= DRAG_START_PX:
				pan_by(-mm.relative / _zoom)
		return
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	if mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# Der Baum-Punkt unter der Maus bleibt beim Zoomen stehen
		var before := _to_tree(mb.position)
		_zoom = clampf(_zoom * (WHEEL_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / WHEEL_STEP), ZOOM_MIN, ZOOM_MAX)
		_free = true
		_view = (_view + before - _to_tree(mb.position)).clamp(_bounds.position, _bounds.end)
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_dragged = 0.0
		return
	if mb.pressed:
		_press = true
		_dragged = 0.0
		return
	if not _press or _dragged >= DRAG_START_PX:
		_press = false
		return
	_press = false
	var p := _to_tree(mb.position)
	for id in _tree.order:
		if _tree.state(id) >= SkillTree.State.AVAILABLE and p.distance_to(_pos(id)) <= _radius(id):
			if id == _selected:
				_buy(id)
			else:
				_select(id)
				_free = false
			return


func _buy(id: String) -> void:
	if _tree.buy(id):
		_pop[id] = 0.35
		var special := _tree.is_special(id)
		# Höhere Stufen klingen etwas heller
		Sfx.play("special" if special else "buy", 1.0 + 0.04 * (_tree.level(id) - 1))
		_petals.burst(_pos(id), 40 if special else 22, Vector2(140, 420), Vector2(0.5, 1.0), Vector2(7, 12))
	else:
		_shake = 0.3
		Sfx.play("deny")


func _select(id: String) -> void:
	if id != _selected:
		_selected = id
		Sfx.play_throttled("select", float(Sfx.cfg.get("select_min_gap_sec", 0.06)))


func _refresh() -> void:
	_title.text = "Skilltree   ·   Pollen: %s   ·   Entdeckt: %d / %d" % [
		Fmt.int_str(floori(_tree.pollen)), _tree.count_discovered(), _tree.order.size()]
	var id := _selected
	var d: Dictionary = _tree.nodes[id]
	_info_name.text = str(d["name"])
	_info_special.visible = _tree.is_special(id)
	_info_desc.text = str(d.get("desc", ""))
	var eff := _tree.effect_text(id)
	_info_effect.visible = eff != ""
	_info_effect.text = ("Je Stufe: " if _tree.max_level(id) > 1 else "Wirkung: ") + eff
	var col := Color.WHITE
	if d.get("requires", []).is_empty():
		_info_cost.text = "Hier beginnt der Frühling."
	elif _tree.is_maxed(id):
		_info_cost.text = "Stufe %d / %d   ·   voll ausgebaut" % [_tree.level(id), _tree.max_level(id)]
		col = Color(0.75, 0.95, 0.65)
	else:
		_info_cost.text = "Stufe %d / %d   ·   Kosten: %s Pollen" % [_tree.level(id), _tree.max_level(id), Fmt.int_str(_tree.cost(id))]
		if not _tree.can_buy(id):
			col = POOR
	_info_cost.add_theme_color_override("font_color", col)


# --- Zeichnen ---

func _pos(id: String) -> Vector2:
	var p: Array = _tree.nodes[id]["pos"]
	return Vector2(float(p[0]), float(p[1])) * UNIT_PX


func _radius(id: String) -> float:
	return SPECIAL_R if _tree.is_special(id) else NODE_R


func _color(id: String) -> Color:
	return BRANCH_COLORS.get(str(_tree.nodes[id].get("branch", "root")), Color.WHITE)


func _draw_tree() -> void:
	# Verbindungen zuerst, damit die Knoten darüber liegen
	for id in _tree.order:
		var s1 := _tree.state(id)
		if s1 == SkillTree.State.HIDDEN:
			continue
		for r in _tree.nodes[id].get("requires", []):
			var s2 := _tree.state(str(r))
			if s2 == SkillTree.State.HIDDEN:
				continue
			var a := _pos(id)
			var b := _pos(str(r))
			if s1 == SkillTree.State.OWNED and s2 == SkillTree.State.OWNED:
				_layer.draw_line(a, b, _color(id), 7.0, true)
			elif s1 == SkillTree.State.MYSTERY or s2 == SkillTree.State.MYSTERY:
				_layer.draw_dashed_line(a, b, Color(1, 1, 1, 0.22), 3.0, 10.0)
			else:
				_layer.draw_line(a, b, Color(0.75, 0.82, 0.75, 0.55), 4.0, true)
	for id in _tree.order:
		var st := _tree.state(id)
		if st != SkillTree.State.HIDDEN:
			_draw_node(id, st)


## Effekt-Ebene (liegt unter den Knoten): pulsierender Schein bei bezahlbaren Knoten,
## Auswahlring (wackelt rot, wenn der Kauf nicht geht) und ein Ring, der sich beim Kauf ausdehnt.
func _draw_fx() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	for id in _tree.order:
		if _tree.can_buy(id):
			_fx.draw_circle(_pos(id), _radius(id) + 8.0 + pulse * 4.0, Color(1.0, 0.95, 0.55, 0.25 + 0.2 * pulse))
	for id: String in _pop:
		var t := 1.0 - float(_pop[id]) / 0.35
		_fx.draw_arc(_pos(id), _radius(id) + 10.0 + t * 40.0, 0.0, TAU, 48, Color(1.0, 0.95, 0.6, 1.0 - t), 6.0, true)
	var p := _pos(_selected)
	var ring := Color.WHITE
	if _shake > 0.0:
		p.x += sin(_shake * 60.0) * 8.0
		ring = POOR
	_fx.draw_arc(p, _radius(_selected) + 7.0, 0.0, TAU, 48, ring, 5.0, true)


func _draw_node(id: String, st: SkillTree.State) -> void:
	var p := _pos(id)
	var r := _radius(id)
	var col := _color(id)
	if st == SkillTree.State.MYSTERY:
		_layer.draw_circle(p, NODE_R * 0.8, Color(0.22, 0.27, 0.25))
		_layer.draw_arc(p, NODE_R * 0.8, 0.0, TAU, 40, Color(1, 1, 1, 0.25), 3.0, true)
		_text(p + Vector2(0, 2), "?", 34, Color(1, 1, 1, 0.45))
		return
	if _tree.is_special(id):
		_star(p, r + 16.0, r + 2.0, GOLD if st == SkillTree.State.OWNED else Color(GOLD, 0.55))
	var fill := col if st == SkillTree.State.OWNED else col.darkened(0.6)
	_layer.draw_circle(p, r, fill)
	_layer.draw_arc(p, r, 0.0, TAU, 48, col.lightened(0.3) if st == SkillTree.State.OWNED else col, 4.0, true)
	_icon(id, p, r * 0.55, Color.WHITE if st == SkillTree.State.OWNED else Color(1, 1, 1, 0.75))
	# Stufen als Punkte unter dem Knoten
	var maxl := _tree.max_level(id)
	if maxl > 1:
		var lvl := _tree.level(id)
		for i in maxl:
			var dp := p + Vector2((i - (maxl - 1) * 0.5) * 14.0, r + 16.0)
			_layer.draw_circle(dp, 5.0, col if i < lvl else Color(1, 1, 1, 0.2))


func _star(c: Vector2, outer: float, inner: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var rad := outer if i % 2 == 0 else inner
		pts.append(c + Vector2.from_angle(i * TAU / 16.0 - PI / 2.0) * rad)
	_layer.draw_colored_polygon(pts, col)


func _text(center: Vector2, s: String, size: int, col: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_layer.draw_string(_font, center + Vector2(-w * 0.5, size * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Kleines Symbol je nach Hauptwirkung des Knotens.
func _icon(id: String, p: Vector2, s: float, col: Color) -> void:
	var effects: Dictionary = _tree.nodes[id].get("effects", {})
	var kind := "root" if effects.is_empty() else str(effects.keys()[0])
	match kind:
		"radius":
			_layer.draw_arc(p, s * 0.45, 0.0, TAU, 24, col, 3.0, true)
			_layer.draw_arc(p, s, 0.0, TAU, 32, col, 3.0, true)
		"speed", "bee_speed":
			for dx in [-0.45, 0.25]:
				var o := p + Vector2(dx * s, 0)
				_layer.draw_polyline(PackedVector2Array([o + Vector2(-0.3, -0.6) * s, o + Vector2(0.3, 0) * s, o + Vector2(-0.3, 0.6) * s]), col, 4.0, true)
		"pollen":
			# Dunkler Rand, damit die gelben Punkte auch auf dem gelben Bienen-Ast sichtbar sind
			for a in 3:
				var c := p + Vector2.from_angle(a * TAU / 3.0 - PI / 2.0) * s * 0.45
				_layer.draw_circle(c, s * 0.36, Color(0.25, 0.2, 0.1, col.a))
				_layer.draw_circle(c, s * 0.27, Color(1.0, 0.9, 0.4, col.a))
		"spread":
			var leaf := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				leaf.append(p + Vector2(lerpf(-s, s, t), -sin(t * PI) * s * 0.55))
			for i in range(11, 0, -1):
				var t := float(i) / 12.0
				leaf.append(p + Vector2(lerpf(-s, s, t), sin(t * PI) * s * 0.55))
			_layer.draw_colored_polygon(leaf, col)
		"seed_reach", "seed_chance":
			_layer.draw_circle(p, s * 0.2, col)
			for a in 7:
				var d := Vector2.from_angle(a * TAU / 7.0)
				_layer.draw_line(p + d * s * 0.25, p + d * s * 0.85, col, 2.0, true)
				_layer.draw_circle(p + d * s * 0.9, s * 0.12, col)
		"bees":
			for sy in [-1.0, 1.0]:
				_layer.draw_circle(p + Vector2(-s * 0.1, sy * s * 0.55), s * 0.32, Color(1, 1, 1, col.a * 0.7))
			_layer.draw_set_transform(p, 0.0, Vector2(1.3, 1.0))
			_layer.draw_circle(Vector2.ZERO, s * 0.5, col)
			_layer.draw_set_transform(Vector2.ZERO)
			for dx in [-0.25, 0.2]:
				_layer.draw_line(p + Vector2(dx * s, -s * 0.55), p + Vector2(dx * s, s * 0.55), Color(0.2, 0.18, 0.15), 4.0)
		"bloom", "root":
			for a in 5:
				_layer.draw_circle(p + Vector2.from_angle(a * TAU / 5.0) * s * 0.55, s * 0.4, Color(1.0, 0.7, 0.82, col.a))
			_layer.draw_circle(p, s * 0.35, Color(1.0, 0.88, 0.35, col.a))
		"bee_rest":
			_layer.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.6, -0.8) * s, p + Vector2(0.6, -0.8) * s, p]), col)
			_layer.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.6, 0.8) * s, p + Vector2(0.6, 0.8) * s, p]), col)
		_:
			_text(p, "+", 30, col)
