class_name MenuKit
extends RefCounted
## Gemeinsame Bausteine für alle Menüs: Panel mit Rand, große Knöpfe, Menü-Gruppe.
## Jedes Menü ist in der Gruppe "menu"; any_open() sagt, ob gerade eines sichtbar ist.

const GROUP := "menu"


static func any_open(tree: SceneTree) -> bool:
	for n in tree.get_nodes_in_group(GROUP):
		if (n as CanvasLayer).visible:
			return true
	return false


## Panel mit Innenabstand; gibt die VBox zurück, in die der Inhalt kommt.
static func panel(parent: Control, margin: int = 24) -> VBoxContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.27, 0.24, 0.94)
	style.set_corner_radius_all(18)
	style.set_border_width_all(4)
	style.border_color = Color(0.62, 0.84, 0.45)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	p.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	m.add_child(box)
	return box


static func title(box: VBoxContainer, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return l


static func button(box: VBoxContainer, text: String, width: float = 560, height: float = 64) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.add_theme_font_size_override("font_size", 26)
	box.add_child(b)
	return b


static func focus_first(box: Node) -> void:
	for c in box.get_children():
		if c is Button and not (c as Button).disabled:
			(c as Button).grab_focus()
			return
