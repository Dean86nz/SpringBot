class_name UpgradeMenu
extends CanvasLayer
## Upgrade-Menü rechts am Rand. A kauft eine Stufe, das Menü bleibt offen und der Fokus
## bleibt auf dem Knopf, damit man mehrmals hintereinander kaufen kann.
## Das Spiel läuft weiter (Pollen fließen), nur der Roboter steht. Öffnen/Schließen: main.gd.

const COLOR_OK := Color(1, 1, 1)
const COLOR_POOR := Color(1.0, 0.72, 0.68)
const COLOR_MAX := Color(0.75, 0.95, 0.65)

var _eco: Economy
var _box: VBoxContainer
var _pollen := Label.new()
var _buttons: Dictionary = {}   # id → Button


func setup(eco: Economy) -> void:
	_eco = eco
	layer = 20
	visible = false
	add_to_group(MenuKit.GROUP)
	var anchor := MarginContainer.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	anchor.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	anchor.add_theme_constant_override("margin_right", 32)
	anchor.add_theme_constant_override("margin_top", 70)
	anchor.add_theme_constant_override("margin_bottom", 50)
	add_child(anchor)
	var holder := VBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	anchor.add_child(holder)
	_box = MenuKit.panel(holder, 20, 8)
	MenuKit.title(_box, "Upgrades")
	_pollen.add_theme_font_size_override("font_size", 28)
	_pollen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pollen.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	_box.add_child(_pollen)
	var group := ""
	for id in eco.order:
		var g := str(eco.defs[id].get("group", ""))
		if g != group:
			group = g
			var head := Label.new()
			head.text = g
			head.add_theme_font_size_override("font_size", 22)
			head.add_theme_color_override("font_color", Color(0.70, 0.92, 0.55))
			_box.add_child(head)
		var b := MenuKit.button(_box, "", 680, 76)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_buy.bind(id))
		_buttons[id] = b
	var hint := Label.new()
	hint.text = "A / Enter: kaufen   ·   B / Esc: schließen"
	hint.add_theme_font_size_override("font_size", 20)
	hint.modulate = Color(1, 1, 1, 0.7)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(hint)


func open() -> void:
	visible = true
	refresh()
	(_buttons[_eco.order[0]] as Button).grab_focus()


func close() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		refresh()


func refresh() -> void:
	_pollen.text = "Pollen: %s" % Fmt.int_str(floori(_eco.pollen))
	for id: String in _buttons:
		var b: Button = _buttons[id]
		var d: Dictionary = _eco.defs[id]
		var lvl := _eco.level(id)
		var line1 := "%s   ·   Stufe %d / %d   ·   " % [d["name"], lvl, _eco.max_level(id)]
		# Ohne Grundwert zeigt "jetzt" den Bonus (+1), mit Grundwert den Gesamtwert (3)
		var has_base := d.has("base")
		var now := ("" if has_base else "+") + Fmt.num(_eco.base(id) + _eco.bonus(id))
		var line2 := "+%s %s je Stufe (jetzt %s)" % [Fmt.num(float(d["per_level"])), d["unit"], now]
		var col := COLOR_OK
		if _eco.is_maxed(id):
			line1 += "Maximal"
			col = COLOR_MAX
		else:
			line1 += "%s Pollen" % Fmt.int_str(_eco.cost(id))
			if not _eco.can_buy(id):
				col = COLOR_POOR
		b.text = "%s\n%s" % [line1, line2]
		for key in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(key, col)


func _buy(id: String) -> void:
	var b: Button = _buttons[id]
	var ok := _eco.buy(id)
	refresh()
	# Kurzes Feedback: grünes Aufleuchten beim Kauf, rotes Wackeln, wenn es nicht reicht
	var t := create_tween()
	if ok:
		b.modulate = Color(0.7, 1.4, 0.7)
		t.tween_property(b, "modulate", Color.WHITE, 0.25)
	else:
		var x := b.position.x
		t.tween_property(b, "position:x", x + 10, 0.04)
		t.tween_property(b, "position:x", x - 10, 0.06)
		t.tween_property(b, "position:x", x, 0.04)
