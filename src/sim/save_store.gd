class_name SaveStore
extends RefCounted
## Spielstand auf der Platte: zwei abwechselnd beschriebene JSON-Dateien plus Meta-Datei
## (Ansatz aus Scrap Empire). Die Meta-Datei zeigt erst auf die neue Datei, wenn diese
## vollständig geschrieben ist; ein Absturz beim Schreiben kostet also höchstens den letzten Stand.
## Die Debug-EXE speichert in einen eigenen Ordner, damit Cheats nie den echten Stand berühren.

const VERSION := 1
const SLOTS := ["save_a.json", "save_b.json"]
const META := "save_meta.json"

var dir := ""


func _init(p_dir: String = "") -> void:
	dir = p_dir if p_dir != "" else ("user://saves_debug/" if OS.is_debug_build() else "user://saves/")
	DirAccess.make_dir_recursive_absolute(dir)


func has_save() -> bool:
	return not read().is_empty()


func write(data: Dictionary) -> bool:
	data["version"] = VERSION
	var target: String = SLOTS[1] if _latest() == SLOTS[0] else SLOTS[0]
	var f := FileAccess.open(dir + target, FileAccess.WRITE)
	if f == null:
		push_error("Spielstand konnte nicht geschrieben werden: " + dir + target)
		return false
	f.store_string(JSON.stringify(data, "", false))
	f.close()
	var meta := FileAccess.open(dir + META, FileAccess.WRITE)
	if meta == null:
		return false
	meta.store_string(JSON.stringify({"latest": target}))
	meta.close()
	return true


## Der neueste lesbare Stand, sonst der ältere, sonst {}.
func read() -> Dictionary:
	var latest := _latest()
	var order: Array[String] = []
	if latest != "":
		order.append(latest)
	for s: String in SLOTS:
		if s != latest:
			order.append(s)
	for s in order:
		var data := _read_file(dir + s)
		if int(data.get("version", 0)) == VERSION:
			return data
	return {}


## Löscht alle Stände (nur für Tests).
func wipe() -> void:
	for s: String in SLOTS + [META]:
		if FileAccess.file_exists(dir + s):
			DirAccess.remove_absolute(dir + s)


func _latest() -> String:
	var s := str(_read_file(dir + META).get("latest", ""))
	return s if s in SLOTS else ""


static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
