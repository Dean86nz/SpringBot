class_name KeyHints
extends RefCounted
## Tastennamen passend zum Gerät: Wer zuletzt Controller benutzt hat, sieht „A“, „Y“, „Linker Stick“,
## wer Tastatur oder Maus benutzt hat, sieht „Enter“, „Tab“, „WASD“. Namen in data/tutorial.json ("keys").
## Game._input meldet jede Eingabe; version zählt bei jedem Gerätewechsel hoch, damit Anzeigen
## (HUD, Menüs) merken, dass sie ihren Text neu setzen müssen.

static var pad := false
static var version := 0
static var keys: Dictionary = {}


static func setup(key_names: Dictionary) -> void:
	keys = key_names
	pad = not Input.get_connected_joypads().is_empty()


## Merkt sich das zuletzt benutzte Gerät. true, wenn es gewechselt hat.
static func observe(event: InputEvent) -> bool:
	var now := pad
	if event is InputEventJoypadButton:
		now = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		now = true
	elif event is InputEventKey or event is InputEventMouseButton:
		now = false
	if now == pad:
		return false
	pad = now
	version += 1
	return true


## Name der Taste für das aktuelle Gerät, z. B. key("tree") → "Y" oder "Tab".
static func key(name: String) -> String:
	var k: Dictionary = keys.get(name, {})
	return str(k.get("pad" if pad else "keys", name))


## Ersetzt {name} im Text durch den Tastennamen.
static func fill(text: String) -> String:
	var out := text
	for name: String in keys:
		out = out.replace("{%s}" % name, key(name))
	return out
