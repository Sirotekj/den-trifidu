extends SceneTree
## Prepares the main menu pictures from the sketches in `inspirace/`:
## white paper becomes transparent, ink stays, size is 2× the on-screen size.
##
## Run from the project folder:
##   godot --headless --path . --script res://tools/graphics/menu_art.gd
## then re-import: godot --headless --path . --import

const OUT := "res://assets/graphics/menu/"
## 2× of the 250×375 area next to the menu buttons.
const SIZE_2X := Vector2i(500, 750)
const INK := Color(0.09, 0.08, 0.07)
const INK_DARK := 0.42
const INK_LIGHT := 0.85


func _init() -> void:
	_convert("Trifid.png", "menu_trifids.png")
	_convert("Man.png", "menu_fighter.png")
	quit()


func _convert(source: String, target: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://inspirace/" + source))
	img.convert(Image.FORMAT_RGBA8)
	var factor := minf(float(SIZE_2X.x) / img.get_width(), float(SIZE_2X.y) / img.get_height())
	img.resize(roundi(img.get_width() * factor), roundi(img.get_height() * factor), Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var alpha := 1.0 - smoothstep(INK_DARK, INK_LIGHT, img.get_pixel(x, y).get_luminance())
			img.set_pixel(x, y, Color(INK, alpha))
	var path := ProjectSettings.globalize_path(OUT + target)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("saved ", path, " ", img.get_size())
