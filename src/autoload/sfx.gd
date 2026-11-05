extends Node
## Ton: Effekte und Musik (Aufbau übernommen aus Scrap Empire, ohne Fahrgeräusch).
## Effekte liegen unter assets/audio/sfx/<id>_<n>.ogg, mehrere Dateien = Varianten, dazu leichte
## Tonhöhen-Variation. Musik: mehrere Stücke von ruhig nach voller; je mehr Fläche blüht,
## desto weiter wird zum nächsten Stück übergeblendet (Schwellen in data/audio.json).
## Klänge, die oft kurz hintereinander kommen (Bäume erwachen), fasst play_grouped zusammen:
## jeder weitere innerhalb des Zeitfensters leiser, ab einer Höchstzahl gar nicht mehr ("groups").
## Lautstärke für Musik und Klänge stellt der Spieler im Pause-Menü ein (0..1, gespeichert in
## user://settings.json, nicht im Spielstand). Sie wirkt auf die Busse, zusätzlich zu den Grundwerten aus audio.json.
## Rein kosmetisch, keine Spiellogik.

const AUDIO_PATH := "res://data/audio.json"
const SFX_DIR := "res://assets/audio/sfx/"
const VOICES := 8
const JITTER := 0.05
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const SETTINGS_PATH := "user://settings.json"

var cfg: Dictionary = {}
var music := AudioStreamPlayer.new()
var _music_old := AudioStreamPlayer.new()   # zweiter Abspieler fürs Überblenden
var _tracks: Array[AudioStream] = []
var _playing := -1
var _streams: Dictionary = {}           # id → Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_play: Dictionary = {}
var _coverage := 0.0
var _groups: Dictionary = {}            # id → {last: ms, n: Klänge im laufenden Fenster}
var volume := {"music": 1.0, "sfx": 1.0}   # Regler im Pause-Menü, 0..1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cfg = Game.load_json(AUDIO_PATH)
	_ensure_bus(BUS_SFX, float(cfg.get("sfx_db", 0.0)))
	_ensure_bus(BUS_MUSIC, float(cfg.get("music_db", 0.0)))
	load_settings()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_players.append(p)
	for m in [music, _music_old]:
		m.bus = BUS_MUSIC
		add_child(m)
	_load_sfx()
	# Ohne Ausgabe (Tests, --audio-driver Dummy) läuft der Mischer nie,
	# gestartete Musik bliebe beim Beenden hängen
	if DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy":
		_start_music()


## Beendet das Spiel. Erst alles stoppen und den Mischer kurz laufen lassen,
## sonst bleiben laufende Ogg-Abspieler im AudioServer hängen (Fehlermeldung beim Beenden).
func quit_game() -> void:
	stop_all()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit()


func stop_all() -> void:
	music.stop()
	_music_old.stop()
	for p in _players:
		p.stop()


func _ensure_bus(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_volume_db(idx, db)


## Lautstärke setzen (kind: "music" oder "sfx", v 0..1), sofort hörbar und gespeichert.
func set_volume(kind: String, v: float) -> void:
	volume[kind] = clampf(v, 0.0, 1.0)
	_apply_volume()
	save_settings()


## Regler-Wert → dB-Abzug. Quadratisch, damit sich der Regler gleichmäßig anfühlt (50 % ≈ -12 dB).
static func volume_db(v: float) -> float:
	return linear_to_db(maxf(v * v, 0.00001))


func _apply_volume() -> void:
	for pair: Array in [[BUS_MUSIC, "music", "music_db"], [BUS_SFX, "sfx", "sfx_db"]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx < 0:
			continue
		var v := float(volume[pair[1]])
		AudioServer.set_bus_volume_db(idx, float(cfg.get(pair[2], 0.0)) + volume_db(v))
		AudioServer.set_bus_mute(idx, v <= 0.001)


func load_settings(path: String = SETTINGS_PATH) -> void:
	var text := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var d: Variant = JSON.parse_string(text) if text != "" else null
	if d is Dictionary:
		for k in ["music", "sfx"]:
			if (d as Dictionary).has(k):
				volume[k] = clampf(float(d[k]), 0.0, 1.0)
	_apply_volume()


func save_settings(path: String = SETTINGS_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(volume))


func play(id: String, pitch: float = 1.0, pitch_jitter: float = JITTER, db_add: float = 0.0) -> void:
	var list: Array = _streams.get(id, [])
	if list.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = list[randi() % list.size()]
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.volume_db = float(cfg.get("sfx_level_db", {}).get(id, -6.0)) + db_add
	p.play()


## Zusammengefasst: Kommt der Klang innerhalb von window_sec nach dem letzten wieder, wird er um
## step_db leiser, ab dem max-ten bleibt er still, bis window_sec lang Ruhe war.
func play_grouped(id: String) -> void:
	var g: Dictionary = cfg.get("groups", {}).get(id, {})
	var now := Time.get_ticks_msec()
	var st: Dictionary = _groups.get(id, {"last": -1000000, "n": 0})
	if now - int(st["last"]) > int(float(g.get("window_sec", 2.0)) * 1000.0):
		st["n"] = 0
	var db := group_db(int(st["n"]), float(g.get("step_db", 4.0)), int(g.get("max", 3)))
	st["n"] = int(st["n"]) + 1
	st["last"] = now
	_groups[id] = st
	if is_inf(db):
		return
	var pr: Array = g.get("pitch", [1.0, 1.0])
	play(id, randf_range(float(pr[0]), float(pr[1])), 0.0, db)


## Abschwächung in dB für den n-ten Klang (ab 0) im Fenster; -INF = gar nicht spielen.
static func group_db(n: int, step_db: float, max_n: int) -> float:
	return -INF if n >= max_n else -step_db * n


## Wie play, aber höchstens einmal je min_gap Sekunden (Echtzeit).
func play_throttled(id: String, min_gap: float, pitch: float = 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(id, -100000)) < int(min_gap * 1000.0):
		return
	_last_play[id] = now
	play(id, pitch)


## Begrünter Anteil 0..1; bestimmt, welches Musikstück läuft.
func set_progress(coverage: float) -> void:
	_coverage = coverage


## Index des Stücks für diesen Fortschritt: das letzte, dessen Schwelle erreicht ist.
static func track_for(tracks: Array, coverage: float) -> int:
	var idx := 0
	for i in tracks.size():
		if coverage >= float(tracks[i].get("from_coverage", 0.0)):
			idx = i
	return idx


## Wechselt das Stück, sobald eine neue Schwelle erreicht ist: das alte blendet aus,
## das neue beginnt von vorn und blendet gleichzeitig ein (zwei Abspieler).
func _process(delta: float) -> void:
	if _tracks.is_empty():
		return
	var tracks: Array = cfg.get("tracks", [])
	var off := float(cfg.get("off_db", -60.0))
	var step := delta * absf(off) / maxf(float(cfg.get("fade_sec", 5.0)), 0.1)
	var want := track_for(tracks, _coverage)
	if want != _playing:
		var tmp := _music_old
		_music_old = music
		music = tmp
		music.stream = _tracks[want]
		music.volume_db = off
		music.play()
		_playing = want
	music.volume_db = move_toward(music.volume_db, float(tracks[_playing].get("db", 0.0)), step)
	if _music_old.playing:
		_music_old.volume_db = move_toward(_music_old.volume_db, off, step)
		if _music_old.volume_db <= off:
			_music_old.stop()


func _start_music() -> void:
	for t: Dictionary in cfg.get("tracks", []):
		var path := str(t.get("file", ""))
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_tracks.append(s)
	_playing = -1   # erstes _process startet das passende Stück

## Lädt assets/audio/sfx/<id>_<n>.ogg als Varianten von <id>.
func _load_sfx() -> void:
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		var fname := f.trim_suffix(".import").trim_suffix(".remap")
		if not fname.ends_with(".ogg"):
			continue
		var id := fname.get_basename()
		var cut := id.rfind("_")
		if cut > 0:
			id = id.substr(0, cut)
		var stream: AudioStream = load(SFX_DIR + fname)
		if stream == null:
			continue
		if not _streams.has(id):
			_streams[id] = []
		if not (_streams[id] as Array).has(stream):
			_streams[id].append(stream)
