class_name Tutorial
extends RefCounted
## Hinweise im Spiel, jeder genau einmal je Spielstand (data/tutorial.json, "hints"):
## move zu Beginn, tree sobald der erste Kauf möglich ist, tree_help beim ersten Öffnen des
## Skilltrees, bees sobald es Bienen gibt. Reine Logik: main.gd fragt jedes Bild mit dem
## aktuellen Zustand nach, welcher Hinweis jetzt dran ist, und zeigt ihn an.

var hints: Dictionary = {}
var seen: Dictionary = {}   # id → true
var _wait: Dictionary = {}  # id → Sekunden, die die Bedingung schon erfüllt ist


func _init(cfg: Dictionary = {}) -> void:
	hints = cfg.get("hints", {})


## ctx: {can_buy: bool, bees: int, quiet: bool}. quiet = gerade nichts einblenden (Menü offen,
## anderer Hinweis sichtbar). Gibt die id des fälligen Hinweises zurück ("" = keiner) und merkt ihn.
func due(ctx: Dictionary, delta: float) -> String:
	for id: String in ["move", "tree", "bees"]:
		if seen.has(id) or not _condition(id, ctx):
			_wait.erase(id)
			continue
		_wait[id] = float(_wait.get(id, 0.0)) + delta
		if ctx.get("quiet", false) or _wait[id] < delay(id):
			continue
		seen[id] = true
		_wait.erase(id)
		return id
	return ""


func _condition(id: String, ctx: Dictionary) -> bool:
	match id:
		"move":
			return true
		"tree":
			return seen.has("move") and bool(ctx.get("can_buy", false))
		"bees":
			return int(ctx.get("bees", 0)) > 0
	return false


## Für Hinweise, die an einem Ereignis hängen (tree_help beim ersten Öffnen): true nur beim ersten Mal.
func first(id: String) -> bool:
	if seen.has(id):
		return false
	seen[id] = true
	return true


func delay(id: String) -> float:
	return float((hints.get(id, {}) as Dictionary).get("delay_sec", 0.0))


func show_sec(id: String) -> float:
	return float((hints.get(id, {}) as Dictionary).get("show_sec", 8.0))


func text(id: String) -> String:
	return str((hints.get(id, {}) as Dictionary).get("text", ""))


func reset() -> void:
	seen.clear()
	_wait.clear()


func to_list() -> Array:
	return seen.keys()


func from_list(a: Array) -> void:
	reset()
	for id in a:
		seen[str(id)] = true
