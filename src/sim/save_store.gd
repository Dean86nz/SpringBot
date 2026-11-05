class_name SaveStore
extends RefCounted
## Spielstand auf der Platte: zwei abwechselnd beschriebene JSON-Dateien plus Meta-Datei
## (Ansatz aus Scrap Empire). Die Meta-Datei zeigt erst auf die neue Datei, wenn diese
## vollständig geschrieben ist; ein Absturz beim Schreiben kostet also höchstens den letzten Stand.
## Die Debug-EXE speichert in einen eigenen Ordner, damit Cheats nie den echten Stand berühren.
## Ab Version 2 hat jede Region ihren eigenen Eintrag („regions“: Raster, Roboter, fertig);
## Skilltree, Pollen, Spielzeit und Einführung gelten für alle Regionen. migrate() hebt alte Stände an.

const VERSION := 2
const SLOTS := ["save_a.json", "save_b.json"]
const META := "save_meta.json"

var dir := ""


func _init(p_dir: String = "") -> void:
	dir = p_dir if p_dir != "" else ("user://saves_debug/" if OS.is_debug_build() else "user://saves/")
	DirAccess.make_dir_recursive_absolute(dir)


## Alter Stand (Version 1: ein Raster unter "grid") → Version 2: dieses Raster gehört der Startregion.
static func migrate(data: Dictionary, start_region: String) -> Dictionary:
	if data.is_empty() or data.has("regions") or not data.has("grid"):
		return data
	var out := data.duplicate()
	out["regions"] = {start_region: {
		"grid": data["grid"],
		"robot": data.get("robot", []),
		"finished": data.get("finished", false),
	}}
	out["region"] = start_region
	for k in ["grid", "robot", "finished"]:
		out.erase(k)
	return out


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


## Der neueste lesbare Stand (auch aus älteren Versionen), sonst der ältere, sonst {}.
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
		var v := int(data.get("version", 0))
		if v >= 1 and v <= VERSION:   # ältere Stände lesen, migrate() hebt sie an
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
