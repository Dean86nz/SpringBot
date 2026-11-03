class_name PauseMenu
extends CanvasLayer
## Pause-Menü: Weiterspielen, Titelbildschirm oder Spiel beenden. Öffnen/Schließen steuert
## main.gd (Start / Esc), dort wird auch gespeichert. Pausiert das Spiel, solange es offen ist.

signal title_requested
signal quit_requested

var _box: VBoxContainer


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
	MenuKit.title(_box, "Pause")
	MenuKit.button(_box, "Weiterspielen").pressed.connect(close)
	MenuKit.button(_box, "Zum Titelbildschirm").pressed.connect(func() -> void:
		visible = false
		title_requested.emit())
	MenuKit.button(_box, "Spiel beenden").pressed.connect(func() -> void: quit_requested.emit())


func open() -> void:
	visible = true
	get_tree().paused = true
	MenuKit.focus_first(_box)


func close() -> void:
	visible = false
	get_tree().paused = false
