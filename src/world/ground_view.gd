class_name GroundView
extends Node2D
## Zeichnet den Boden: eine Maske (GroundGrid.vis, 1 Pixel je Zelle, weich gefiltert) entscheidet im Shader
## (ground.gdshader) zwischen grauem und grünem Boden. Rauschen macht die Grenze organisch.
## Prinzip aus Scrap Empire (DirtView). Die Maske wird höchstens 30× pro Sekunde hochgeladen,
## „seit wann grün“ (GroundGrid.since) seltener, weil sich das Üppigwerden langsam ändert.
## Deko-Werte aus data/balance.json ("ground"), als Uniforms an den Shader.
## Gebiete (Regions) gehen als drei kleine Texturen mit je einem Pixel pro REGION_PX Zellen an den
## Shader; jedes Pixel mittelt seine Blöcke, die weiche Filterung macht die Grenzen sanft.

const SHADER := preload("res://src/world/ground.gdshader")
const UPLOAD_SECONDS := 1.0 / 30.0
const BORDER_COLOR := Color(0.50, 0.54, 0.60)
const REGION_PX := 8

var _grid: GroundGrid
var _size_px := Vector2.ZERO
var _img: Image
var _tex: ImageTexture
var _since_img: Image
var _since_tex: ImageTexture
var _timer := 0.0
var _since_timer := 0.0
var _since_dirty := false
var _since_upload := 0.25


## cfg: Abschnitt "ground" aus balance.json (Shader-Werte), leer = Standardwerte des Shaders.
func bind(grid: GroundGrid, cell_px: float, cfg: Dictionary = {}, regions: Regions = null) -> void:
	_grid = grid
	_size_px = Vector2(grid.width, grid.height) * cell_px
	_img = Image.create_from_data(grid.width, grid.height, false, Image.FORMAT_R8, grid.vis)
	_tex = ImageTexture.create_from_image(_img)
	_since_img = Image.create_from_data(grid.width, grid.height, false, Image.FORMAT_RG8, grid.since)
	_since_tex = ImageTexture.create_from_image(_since_img)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("mask", _tex)
	mat.set_shader_parameter("since_tex", _since_tex)
	# Wege und Wasser ändern sich nie: einmal hochladen
	var terrain_img := Image.create_from_data(grid.width, grid.height, false, Image.FORMAT_RG8, grid.terrain_vis)
	mat.set_shader_parameter("terrain_tex", ImageTexture.create_from_image(terrain_img))
	mat.set_shader_parameter("cell_px", cell_px)
	mat.set_shader_parameter("map_size", _size_px)
	for k: String in cfg:
		if k == "since_upload_sec":
			_since_upload = float(cfg[k])
		else:
			mat.set_shader_parameter(k, float(cfg[k]))
	if regions and not regions.list.is_empty():
		_bind_regions(mat, regions, grid)
	material = mat
	grid.take_dirty()
	queue_redraw()


func _bind_regions(mat: ShaderMaterial, regions: Regions, grid: GroundGrid) -> void:
	var w := ceili(grid.width / float(REGION_PX))
	var h := ceili(grid.height / float(REGION_PX))
	var imgs: Array[Image] = []
	for k in 3:
		imgs.append(Image.create(w, h, false, Image.FORMAT_RGBA8))
	var sub := REGION_PX / Regions.STEP   # Blöcke je Pixel und Richtung
	for y in h:
		for x in w:
			var acc: Array[Color] = [Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]
			for sy in sub:
				for sx in sub:
					var r: Dictionary = regions.list[regions.at_cell(Vector2((x * sub + sx) * Regions.STEP, (y * sub + sy) * Regions.STEP))]
					var g: Color = r["grass"]
					var d: Color = r["dry"]
					var f: Color = r["flower_color"]
					acc[0] += Color(g.r * 0.5, g.g * 0.5, g.b * 0.5, float(r["flowers"]) * 0.5)
					acc[1] += Color(f.r, f.g, f.b, float(r["flower_share"]))
					acc[2] += Color(d.r * 0.5, d.g * 0.5, d.b * 0.5, float(r["tufts"]) * 0.5)
			for k in 3:
				imgs[k].set_pixel(x, y, (acc[k] / float(sub * sub)).clamp())
	mat.set_shader_parameter("use_regions", true)
	mat.set_shader_parameter("region_a", ImageTexture.create_from_image(imgs[0]))
	mat.set_shader_parameter("region_b", ImageTexture.create_from_image(imgs[1]))
	mat.set_shader_parameter("region_c", ImageTexture.create_from_image(imgs[2]))


## Ein Wert des Boden-Shaders (z. B. die Masken für die Übersichtskarte).
func shader_value(param: String) -> Variant:
	return (material as ShaderMaterial).get_shader_parameter(param) if material else null


func _draw() -> void:
	if _grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, _size_px), Color.WHITE)


## Spielzeit in Sekunden (bestimmt, wie üppig länger grüne Stellen sind).
func set_time(sec: float) -> void:
	if material:
		(material as ShaderMaterial).set_shader_parameter("now", sec)


func _process(delta: float) -> void:
	if _grid == null:
		return
	_timer -= delta
	_since_timer -= delta
	if _since_dirty and _since_timer <= 0.0:
		_since_dirty = false
		_since_timer = _since_upload
		_since_img.set_data(_grid.width, _grid.height, false, Image.FORMAT_RG8, _grid.since)
		_since_tex.update(_since_img)
	if _timer > 0.0:
		return
	if _grid.take_dirty().has_area():
		_timer = UPLOAD_SECONDS
		_since_dirty = true
		# Ganze Maske neu setzen: ein Aufruf ist billiger als Pixel einzeln zu schreiben.
		_img.set_data(_grid.width, _grid.height, false, Image.FORMAT_R8, _grid.vis)
		_tex.update(_img)
