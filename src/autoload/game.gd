extends Node
## Globaler Einstieg: Input-Map, Balancing-Daten, Vollbild. Erster Autoload (vor Sfx).

const BALANCE_PATH := "res://data/balance.json"
const SKILLTREE_PATH := "res://data/skilltree.json"
const TUTORIAL_PATH := "res://data/tutorial.json"

var balance: Dictionary = {}
## Nach dem Neuladen der Hauptszene: "" = Titel zeigen, "travel" = in der neuen Region ankommen,
## "new_game" = Einleitung eines neuen Spiels (main.gd lädt die Szene für eine andere Region neu).
var arrival := ""


## Bis 0.19.0 hieß das Spiel „Frühlings-Roboter“; Godot legt Spielstände nach dem Namen ab.
const OLD_USER_DIR := "Frühlings-Roboter"


func _ready() -> void:
	adopt_old_user_dir(OS.get_user_data_dir().get_base_dir().path_join(OLD_USER_DIR), OS.get_user_data_dir())
	InputSetup.apply()
	balance = load_json(BALANCE_PATH)
	KeyHints.setup(load_json(TUTORIAL_PATH).get("keys", {}))
	# Exportierte Builds (Ally) starten im Vollbild; im Editor bleibt es ein Fenster.
	if OS.has_feature("template"):
		get_window().mode = Window.MODE_FULLSCREEN


## Spielstände und Einstellungen aus dem alten Ordner übernehmen, wenn es im neuen noch keine gibt
## (Kopie, der alte Ordner bleibt). Gibt die Zahl kopierter Dateien zurück.
static func adopt_old_user_dir(old_dir: String, new_dir: String) -> int:
	if not DirAccess.dir_exists_absolute(old_dir):
		return 0
	var n := 0
	for sub in ["saves", "saves_debug"]:
		var from := old_dir.path_join(sub)
		var to := new_dir.path_join(sub)
		if not DirAccess.dir_exists_absolute(from) or (DirAccess.dir_exists_absolute(to) and not DirAccess.get_files_at(to).is_empty()):
			continue
		DirAccess.make_dir_recursive_absolute(to)
		for f in DirAccess.get_files_at(from):
			if DirAccess.copy_absolute(from.path_join(f), to.path_join(f)) == OK:
				n += 1
	var settings := old_dir.path_join("settings.json")
	if FileAccess.file_exists(settings) and not FileAccess.file_exists(new_dir.path_join("settings.json")):
		DirAccess.make_dir_recursive_absolute(new_dir)
		if DirAccess.copy_absolute(settings, new_dir.path_join("settings.json")) == OK:
			n += 1
	return n


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
	KeyHints.observe(event)   # Tastennamen passend zum zuletzt benutzten Gerät
	if event.is_action_pressed("toggle_fullscreen"):
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
