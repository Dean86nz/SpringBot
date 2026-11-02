class_name Economy
extends RefCounted
## Pollen und Upgrade-Stufen. Reine Logik: grüne Zellen bringen Pollen pro Sekunde,
## Upgrades kosten base_cost × cost_growth^Stufe (abgerundet). Daten aus data/upgrades.json.

signal changed

var pollen := 0.0
var pollen_per_cell := 0.01
var levels: Dictionary = {}   # id → Stufe
var defs: Dictionary = {}     # id → Definition
var order: Array[String] = []


func _init(data: Dictionary = {}) -> void:
	pollen_per_cell = float(data.get("pollen_per_cell_per_sec", 0.01))
	for d: Dictionary in data.get("upgrades", []):
		var id := str(d["id"])
		defs[id] = d
		order.append(id)
		levels[id] = 0


## Pollen pro Sekunde bei `green_cells` grünen Zellen.
func rate(green_cells: int) -> float:
	return green_cells * pollen_per_cell


func tick(delta: float, green_cells: int) -> void:
	pollen += rate(green_cells) * delta


func level(id: String) -> int:
	return int(levels.get(id, 0))


func max_level(id: String) -> int:
	return int(defs[id].get("max_level", 1))


func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)


func cost(id: String) -> int:
	var d: Dictionary = defs[id]
	return floori(float(d["base_cost"]) * pow(float(d["cost_growth"]), level(id)))


func can_buy(id: String) -> bool:
	return defs.has(id) and not is_maxed(id) and pollen >= cost(id)


## Kauft eine Stufe. true bei Erfolg.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	pollen -= cost(id)
	levels[id] = level(id) + 1
	changed.emit()
	return true


## Gesamtbonus eines Upgrades bei Stufe `lvl` (Standard: aktuelle Stufe).
func bonus(id: String, lvl: int = -1) -> float:
	if not defs.has(id):
		return 0.0
	return float(defs[id].get("per_level", 0.0)) * (level(id) if lvl < 0 else lvl)


func max_all() -> void:
	for id in order:
		levels[id] = max_level(id)
	changed.emit()


func reset() -> void:
	pollen = 0.0
	for id in order:
		levels[id] = 0
	changed.emit()
