class_name InputSetup
extends RefCounted
## Registriert alle Spielaktionen zur Laufzeit in der InputMap (übernommen aus Scrap Empire).
## Gamepad zuerst: linker Stick fährt. Tastatur: WASD oder Pfeiltasten.

const DEADZONE := 0.2


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e


static func _axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e


static var ACTIONS: Dictionary = {
	"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)],
	"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)],
	"move_up": [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)],
	"move_down": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)],
	"toggle_fullscreen": [_key(KEY_F11)],
}


static func apply() -> void:
	for action: String in ACTIONS.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, DEADZONE)
		for ev: InputEvent in ACTIONS[action]:
			InputMap.action_add_event(action, ev)
	# Menü-Navigation: A bestätigt, B bricht ab – auch wenn ein Export die Godot-Standards verliert.
	_ensure("ui_accept", _btn(JOY_BUTTON_A))
	_ensure("ui_cancel", _btn(JOY_BUTTON_B))
	_ensure("ui_up", _btn(JOY_BUTTON_DPAD_UP))
	_ensure("ui_down", _btn(JOY_BUTTON_DPAD_DOWN))
	_ensure("ui_left", _btn(JOY_BUTTON_DPAD_LEFT))
	_ensure("ui_right", _btn(JOY_BUTTON_DPAD_RIGHT))


static func _ensure(action: String, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
