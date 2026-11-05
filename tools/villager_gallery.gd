extends SceneTree
## Entwicklerwerkzeug: zeigt Bewohner (je Arbeit), Hunde und Katzen groß nebeneinander und speichert ein Bild.
##   Godot_v4.7.2-stable_win64_console.exe --path . -s tools/villager_gallery.gd -- <ausgabe.png>

var _out := "user://villagers.png"
var _frames := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_out = args[0]
	root.size = Vector2i(1400, 500)
	var bg := ColorRect.new()
	bg.color = Color(0.46, 0.76, 0.33)
	bg.size = Vector2(1400, 500)
	root.add_child(bg)
	var v := Villagers.new({}, 24.0, {}, Vector2.ZERO)
	var jobs := ["smith", "farmer", "beekeeper", "laundry", "kid", "read", "stroll"]
	for i in jobs.size():
		var p := Villagers.Person.new()
		p.job = jobs[i]
		p.back = true
		p.look = i * 9
		p.pos = Vector2(80 + i * 110, 120)
		p.target = p.pos
		p.wait = 1.0
		p.carry = jobs[i] in ["beekeeper", "laundry"]
		p.sitting = jobs[i] == "read"
		v.people.append(p)
	for i in 4:
		for kind in [Villagers.Kind.DOG, Villagers.Kind.CAT]:
			var a := Villagers.Person.new()
			a.kind = kind
			a.back = true
			a.look = i
			a.pos = Vector2(120 + i * 300 + (0 if kind == Villagers.Kind.DOG else 140), 330)
			a.target = a.pos + Vector2(50, 0) if i % 2 == 0 else a.pos
			a.sitting = i % 2 == 1
			v.people.append(a)
	var view := VillagerView.new()
	view.bind(v)
	view.scale = Vector2.ONE * 1.5
	view.position = Vector2(-60, -60)
	root.add_child(view)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		root.get_texture().get_image().save_png(_out)
		print("gespeichert: ", _out)
		return true
	return false
