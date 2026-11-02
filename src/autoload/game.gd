extends Node
## Globaler Einstieg: Input-Map, Balancing-Daten, Vollbild. Erster und einziger Autoload.

const BALANCE_PATH := "res://data/balance.json"
const SKILLTREE_PATH := "res://data/skilltree.json"

var balance: Dictionary = {}


func _ready() -> void:
	InputSetup.apply()
	balance = load_json(BALANCE_PATH)
	# Exportierte Builds (Ally) starten im Vollbild; im Editor bleibt es ein Fenster.
	if OS.has_feature("template"):
		get_window().mode = Window.MODE_FULLSCREEN


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


## Liest einen Wert aus balance.json über einen Pfad wie "robot/speed_px".
func num(path: String, fallback: float = 0.0) -> float:
	var v: Variant = dig(balance, path)
	return float(v) if v is float or v is int else fallback


static func dig(d: Dictionary, path: String) -> Variant:
	var cur: Variant = d
	for part in path.split("/"):
		if not (cur is Dictionary) or not (cur as Dictionary).has(part):
			return null
		cur = cur[part]
	return cur


static func load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not (parsed is Dictionary):
		push_error("JSON nicht lesbar: " + path)
		return {}
	return parsed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
