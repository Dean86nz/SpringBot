class_name Campaign
extends RefCounted
## Die Reise durch die Regionen (data/campaign.json): welche Regionen es gibt, in welcher Reihenfolge,
## und wo ihre Daten liegen. Jede Region hat einen Ordner mit region.json, world.json, objects.json
## und areas.json. Reine Logik; main.gd lädt damit die Daten der aktuellen Region.

const FILES := ["region", "world", "objects", "areas"]

var start := ""
var order: Array[String] = []
var finished_pollen_share := 0.25
var planned: Array[String] = []   # spätere Regionen, auf der Reisekarte verhüllt
var _dirs: Dictionary = {}   # id → Ordner


func _init(data: Dictionary = {}) -> void:
	for r: Dictionary in data.get("regions", []):
		var id := str(r.get("id", ""))
		if id.is_empty():
			continue
		order.append(id)
		_dirs[id] = str(r.get("dir", "res://data/regions/%s/" % id))
	start = str(data.get("start", order[0] if not order.is_empty() else ""))
	finished_pollen_share = float(data.get("finished_pollen_share", 0.25))
	for n in data.get("planned", []):
		planned.append(str(n))


func has(id: String) -> bool:
	return _dirs.has(id)


## Pfad einer Datei der Region, z. B. path("heimatdorf", "world") → ".../world.json".
func path(id: String, file: String) -> String:
	return str(_dirs.get(id, "")) + file + ".json"


## Alle Daten der Region: {region, world, objects, areas} (je ein Dictionary, fehlende Datei = {}).
func load_region(id: String) -> Dictionary:
	var out := {}
	for f: String in FILES:
		var p := path(id, f)
		out[f] = Game.load_json(p) if FileAccess.file_exists(p) else {}
	return out


## Zelle aus region.json als Pixelmitte (fallback, wenn der Eintrag fehlt).
static func cell_px(region: Dictionary, key: String, cell: float, fallback: Vector2) -> Vector2:
	var c: Variant = region.get(key)
	return (Vector2(c[0], c[1]) + Vector2(0.5, 0.5)) * cell if c is Array else fallback
