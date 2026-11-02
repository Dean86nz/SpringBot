class_name SkillTree
extends RefCounted
## Pollen und Skilltree. Reine Logik, Daten aus data/skilltree.json.
## Ein Knoten ist kaufbar, wenn einer seiner Vorgänger (requires) mindestens Stufe 1 hat.
## Sichtbarkeit: gekauft oder kaufbar = sichtbar, Nachbar eines kaufbaren Knotens = „?“,
## alles andere verdeckt. Werte (stat) sind die Summe aller Effekte × Stufe plus Grundwert.

signal changed

enum State { HIDDEN, MYSTERY, AVAILABLE, OWNED }

var pollen := 0.0
var pollen_per_cell := 0.005
var nodes: Dictionary = {}       # id → Definition
var order: Array[String] = []
var levels: Dictionary = {}      # id → Stufe
var stats_info: Dictionary = {}  # stat → {label, format, scale}
var _base: Dictionary = {}
var _neighbors: Dictionary = {}  # id → Array[String] (Vorgänger und Nachfolger)


func _init(data: Dictionary = {}) -> void:
	pollen_per_cell = float(data.get("pollen_per_cell_per_sec", pollen_per_cell))
	_base = data.get("base", {})
	stats_info = data.get("stats", {})
	for d: Dictionary in data.get("nodes", []):
		var id := str(d["id"])
		nodes[id] = d
		order.append(id)
		_neighbors[id] = []
	for id in order:
		for r in nodes[id].get("requires", []):
			_neighbors[id].append(str(r))
			_neighbors[str(r)].append(id)
	reset()


# --- Pollen ---

## Pollen pro Sekunde bei `green_cells` grünen Zellen (inklusive Pollen-Bonus).
func rate(green_cells: int) -> float:
	return green_cells * pollen_per_cell * (1.0 + stat("pollen") / 100.0)


func tick(delta: float, green_cells: int) -> void:
	pollen += rate(green_cells) * delta


# --- Knoten ---

func level(id: String) -> int:
	return int(levels.get(id, 0))


func max_level(id: String) -> int:
	return int(nodes[id].get("max_level", 1))


func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)


func is_special(id: String) -> bool:
	return bool(nodes[id].get("special", false))


func cost(id: String) -> int:
	var d: Dictionary = nodes[id]
	return floori(float(d["base_cost"]) * pow(float(d.get("cost_growth", 1.0)), level(id)))


func state(id: String) -> State:
	if level(id) > 0:
		return State.OWNED
	if _is_unlocked(id):
		return State.AVAILABLE
	for n: String in _neighbors[id]:
		if level(n) == 0 and _is_unlocked(n):
			return State.MYSTERY
	return State.HIDDEN


func neighbors(id: String) -> Array:
	return _neighbors.get(id, [])


func can_buy(id: String) -> bool:
	return nodes.has(id) and _is_unlocked(id) and not is_maxed(id) and pollen >= cost(id)


## Kauft eine Stufe. true bei Erfolg.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	pollen -= cost(id)
	levels[id] = level(id) + 1
	changed.emit()
	return true


## Summe eines Werts über alle Knoten (plus Grundwert aus "base").
func stat(name: String) -> float:
	var total := float(_base.get(name, 0.0))
	for id in order:
		var lvl := level(id)
		if lvl > 0:
			total += float(nodes[id].get("effects", {}).get(name, 0.0)) * lvl
	return total


## Text der Wirkung je Stufe, z. B. "+0,5 Zellen Reichweite".
func effect_text(id: String) -> String:
	var parts: PackedStringArray = []
	var effects: Dictionary = nodes[id].get("effects", {})
	for k: String in effects:
		var info: Dictionary = stats_info.get(k, {})
		var v := float(effects[k]) * float(info.get("scale", 1.0))
		parts.append(str(info.get("format", "+%s")) % Fmt.num(v) + " " + str(info.get("label", k)))
	return ", ".join(parts)


func count_discovered() -> int:
	var n := 0
	for id in order:
		if state(id) >= State.AVAILABLE:
			n += 1
	return n


func max_all() -> void:
	for id in order:
		levels[id] = max_level(id)
	changed.emit()


func reset() -> void:
	pollen = 0.0
	for id in order:
		# Knoten ohne Vorgänger (die Wurzel) sind von Anfang an gekauft
		levels[id] = max_level(id) if nodes[id].get("requires", []).is_empty() else 0
	changed.emit()


func _is_unlocked(id: String) -> bool:
	var req: Array = nodes[id].get("requires", [])
	if req.is_empty():
		return true
	for r in req:
		if level(str(r)) > 0:
			return true
	return false
