extends SceneTree
## Cuts the first game graphics out of the sketches in `inspirace/` and saves them
## to `assets/graphics/` in 2× resolution (Draft.png is ~1.81× the 800×600 game,
## so Draft pixels are scaled by 1600/1448).
##
## Run from the project folder:
##   godot --headless --path . --script res://tools/graphics/cut_draft.gd
## then re-import: godot --headless --path . --import
##
## All rectangles are in source-image pixels (Rect2i(x, y, width, height)).

const OUT := "res://assets/graphics/"
const DRAFT_TO_2X := 1600.0 / 1448.0
const CELL_2X := Vector2i(108, 108)
const SCREEN_2X := Vector2i(1600, 1200)

## Colour used for ink pixels made semi-transparent.
const INK := Color(0.09, 0.08, 0.07)
## Luminance range: darker than INK_DARK = full ink, lighter than INK_LIGHT = paper.
const INK_DARK := 0.42
const INK_LIGHT := 0.80
const FRAME_INK_LIGHT := 0.86
## Paper colour of the sketches, used to erase strokes.
const PAPER := Color(0.94, 0.93, 0.91)
## Pixels lighter than this are treated as paper when flood-filling the outside.
const PAPER_THRESHOLD := 0.62


func _init() -> void:
	var draft := _load_sketch("Draft.png")
	var man := _load_sketch("Man.png")

	_cut_characters(draft)
	_cut_icons(draft, man)
	_cut_ui(draft)
	_make_background(draft)
	print("cut_draft: done")
	quit()


# --- Assets -------------------------------------------------------------------

func _cut_characters(draft: Image) -> void:
	# Fighter in the middle of the board; erase the grid lines that touch him.
	var fighter := _figure(draft, Rect2i(477, 463, 118, 174), [
		Rect2i(476, 463, 8, 37),     # vertical grid line above the pistol
		Rect2i(565, 463, 9, 9),      # vertical grid line next to the smoke
		Rect2i(476, 585, 9, 52),     # vertical grid line left of the legs
		Rect2i(590, 534, 5, 12),     # horizontal grid line right of the fist
		Rect2i(477, 627, 14, 10),    # bottom grid line left of the boots
		Rect2i(521, 629, 30, 8),     # bottom grid line between the boots
		Rect2i(583, 627, 12, 10),    # bottom grid line right of the boots
	])
	_save(_fit(fighter, CELL_2X), "characters/fighter.png")

	# Top-left trifid without its number label and without the grid lines.
	var trifid := _figure(draft, Rect2i(137, 188, 141, 175), [
		Rect2i(247, 284, 31, 57),    # label (right part)
		Rect2i(252, 340, 26, 12),    # label bottom-right corner
		Rect2i(242, 315, 8, 24),     # label tick next to the leg
		Rect2i(137, 266, 4, 10),     # grid line left of the leaf
		Rect2i(255, 266, 23, 10),    # grid line right of the leaf
		Rect2i(161, 355, 27, 8),     # bottom grid line between the feet
		Rect2i(205, 355, 33, 8),
		Rect2i(258, 355, 20, 8),
	])
	_save(_fit(trifid, CELL_2X), "characters/trifid.png")


func _cut_icons(draft: Image, man: Image) -> void:
	_save(_scaled(_figure(draft, Rect2i(1006, 225, 114, 105), [
		Rect2i(1006, 222, 64, 15),   # card top edge
		Rect2i(1045, 320, 75, 12),   # card bottom edge
		Rect2i(1110, 282, 10, 14),   # stray stroke
	]), DRAFT_TO_2X), "icons/icon_pistol.png")

	_save(_scaled(_figure(draft, Rect2i(965, 360, 183, 108), [
		Rect2i(955, 355, 100, 32),   # card top edge
		Rect2i(1055, 355, 60, 20),
		Rect2i(955, 455, 110, 25),   # card bottom edge
		Rect2i(1098, 462, 52, 18),
		Rect2i(1115, 410, 35, 30),   # start of the label underline
		Rect2i(955, 360, 13, 108),   # card left edge
	]), DRAFT_TO_2X), "icons/icon_machine_gun.png")

	_save(_scaled(_figure(draft, Rect2i(966, 512, 292, 128), [
		Rect2i(958, 505, 62, 25),    # card top edge
		Rect2i(1050, 505, 90, 25),
		Rect2i(1150, 505, 110, 45),  # "Plamenomet" text
		Rect2i(955, 505, 14, 145),   # card left edge
		Rect2i(966, 512, 14, 40),
		Rect2i(955, 625, 20, 25),    # card bottom edge
		Rect2i(975, 639, 40, 11),
		Rect2i(1015, 625, 245, 25),
	]), DRAFT_TO_2X), "icons/icon_flamethrower.png")

	_save(_scaled(_figure(draft, Rect2i(1004, 676, 100, 112), [
		Rect2i(1000, 683, 35, 16),   # card top edge
		Rect2i(1100, 678, 12, 15),
		Rect2i(1000, 779, 20, 16),   # card bottom edge
		Rect2i(1052, 778, 60, 17),
	]), DRAFT_TO_2X), "icons/icon_grenade.png")

	# TEMPORARY: the Draft has no "move" icon, use the fighter's left boot from Man.png.
	var boot := _figure(man, Rect2i(75, 1238, 320, 212), [])
	_save(_fit(boot, Vector2i(150, 100)), "icons/icon_move.png")


func _cut_ui(draft: Image) -> void:
	# Number label next to the top-left trifid with the digit "1" erased. Its outline is
	# open in the bottom-left corner, so the inside is given as a polygon.
	_save(_scaled(_figure(draft, Rect2i(244, 287, 53, 62), [
		Rect2i(256, 301, 21, 35),    # digit
		Rect2i(240, 312, 7, 30),     # tick left of the label
	], PackedVector2Array([
		Vector2(252, 302), Vector2(290, 293), Vector2(287, 312), Vector2(289, 320),
		Vector2(285, 335), Vector2(252, 341),
	])), DRAFT_TO_2X), "ui/trifid_label.png")

	# Empty card frame: the "Pistole" card with its content removed and the gaps in
	# the top/bottom edges patched with clean pieces of the same edge.
	var card := draft.duplicate() as Image
	card.fill_rect(Rect2i(1005, 237, 290, 81), PAPER)          # icon, text
	card.fill_rect(Rect2i(1295, 237, 98, 72), PAPER)           # ∞
	card.blit_rect(draft, Rect2i(1295, 212, 40, 25), Vector2i(1085, 212))  # gun barrel
	card.blit_rect(draft, Rect2i(1290, 212, 100, 25), Vector2i(1145, 212)) # "Pistole"
	card.blit_rect(draft, Rect2i(1295, 212, 30, 25), Vector2i(1245, 212))
	card.blit_rect(draft, Rect2i(1100, 318, 47, 27), Vector2i(1003, 318))  # gun grip
	_save(_scaled(_ink_only(card.get_region(Rect2i(950, 212, 470, 133))), DRAFT_TO_2X),
		"ui/card_frame.png")

	# Top bar button frame ("Menu"), text erased; used for all buttons.
	var button := draft.duplicate() as Image
	button.fill_rect(Rect2i(75, 62, 187, 54), PAPER)    # "Menu"
	button.fill_rect(Rect2i(40, 30, 13, 25), PAPER)     # torn paper edge
	button.fill_rect(Rect2i(120, 30, 20, 15), PAPER)    # crack in the paper
	button.fill_rect(Rect2i(45, 32, 60, 10), PAPER)     # specks above the frame
	_save(_scaled(_ink_only(button.get_region(Rect2i(45, 32, 253, 116))), DRAFT_TO_2X),
		"ui/button_frame.png")


## Paper background 1600×1200: the Draft scaled up, with everything drawn on the paper
## (buttons, title, board, cards, texts) replaced by generated paper texture, so only
## the torn edge and the paper structure remain.
func _make_background(draft: Image) -> void:
	var stats := _paper_stats(draft, Rect2i(950, 940, 330, 40))
	var base := draft.duplicate() as Image
	base.convert(Image.FORMAT_RGBA8)
	base.resize(SCREEN_2X.x, SCREEN_2X.y, Image.INTERPOLATE_CUBIC)

	var areas: Array[Rect2] = []
	for r: Rect2i in [
		Rect2i(36, 26, 280, 136),     # Menu button
		Rect2i(405, 30, 620, 132),    # title with underlines
		Rect2i(1122, 28, 292, 134),   # "O hře" button
		Rect2i(92, 150, 1338, 876),  # board, cards, kill counter
	]:
		areas.append(Rect2(Vector2(r.position) * DRAFT_TO_2X, Vector2(r.size) * DRAFT_TO_2X))

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 7
	noise.frequency = 0.02
	noise.fractal_octaves = 5
	var grain := RandomNumberGenerator.new()
	grain.seed = 11
	const FEATHER := 16.0
	var mean: Color = stats["mean"]
	var spread: float = stats["std"]
	for y in SCREEN_2X.y:
		for x in SCREEN_2X.x:
			var weight := 0.0
			for a in areas:
				var inside := minf(minf(x - a.position.x, a.end.x - x), minf(y - a.position.y, a.end.y - y))
				weight = maxf(weight, clampf(inside / FEATHER, 0.0, 1.0))
			if weight <= 0.0:
				continue
			var n := noise.get_noise_2d(x, y) * 1.2 + grain.randfn(0.0, 0.55)
			var paper := Color(mean.r + n * spread, mean.g + n * spread, mean.b + n * spread * 1.1)
			base.set_pixel(x, y, base.get_pixel(x, y).lerp(paper, smoothstep(0.0, 1.0, weight)))
	base.convert(Image.FORMAT_RGB8)
	var path := ProjectSettings.globalize_path(OUT + "background/paper.jpg")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	base.save_jpg(path, 0.9)
	print("saved ", path)


# --- Image helpers --------------------------------------------------------------

func _load_sketch(file: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://inspirace/" + file))
	img.convert(Image.FORMAT_RGBA8)
	return img


## Cuts a figure: paper connected to the border becomes transparent (soft ink edge),
## paper enclosed by the outline stays opaque so the figure hides the grid behind it.
## `erase` rectangles (source coordinates) are painted white first. Pixels inside the
## optional `solid` polygon (source coordinates) always stay opaque.
func _figure(src: Image, rect: Rect2i, erase: Array, solid := PackedVector2Array()) -> Image:
	var img := src.get_region(rect)
	for e: Rect2i in erase:
		img.fill_rect(Rect2i(e.position - rect.position, e.size), PAPER)
	var w := img.get_width()
	var h := img.get_height()
	var outside := PackedByteArray()
	outside.resize(w * h)
	var queue := PackedInt32Array()
	for x in w:
		queue.append(x)
		queue.append((h - 1) * w + x)
	for y in h:
		queue.append(y * w)
		queue.append(y * w + w - 1)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		if outside[i] == 1:
			continue
		var x := i % w
		var y := i / w
		if img.get_pixel(x, y).get_luminance() < PAPER_THRESHOLD:
			continue
		outside[i] = 1
		if x > 0: queue.append(i - 1)
		if x < w - 1: queue.append(i + 1)
		if y > 0: queue.append(i - w)
		if y < h - 1: queue.append(i + w)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var near_outside := outside[y * w + x] == 1 \
				or (x > 0 and outside[y * w + x - 1] == 1) \
				or (x < w - 1 and outside[y * w + x + 1] == 1) \
				or (y > 0 and outside[(y - 1) * w + x] == 1) \
				or (y < h - 1 and outside[(y + 1) * w + x] == 1)
			var is_solid := not solid.is_empty() and Geometry2D.is_point_in_polygon(
				Vector2(rect.position) + Vector2(x, y) + Vector2(0.5, 0.5), solid)
			if near_outside and not is_solid:
				img.set_pixel(x, y, _ink(c))
			else:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return img


## Keeps only the ink strokes: all paper becomes transparent. Used for thin frames,
## so lighter strokes are kept more than with `_ink`.
func _ink_only(img: Image) -> Image:
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, _ink(img.get_pixel(x, y), FRAME_INK_LIGHT))
	return img


func _ink(c: Color, light := INK_LIGHT) -> Color:
	var alpha := 1.0 - smoothstep(INK_DARK, light, c.get_luminance())
	return Color(INK, alpha)


func _scaled(img: Image, factor: float) -> Image:
	img.resize(roundi(img.get_width() * factor), roundi(img.get_height() * factor),
		Image.INTERPOLATE_LANCZOS)
	return img


## Scales the image to fit `size` (keeping proportions) and centres it on a transparent canvas.
func _fit(img: Image, size: Vector2i) -> Image:
	var factor := minf(float(size.x) / img.get_width(), float(size.y) / img.get_height())
	_scaled(img, factor)
	var canvas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(INK, 0.0))
	var offset := (size - img.get_size()) / 2
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), offset)
	return canvas


func _paper_stats(img: Image, rect: Rect2i) -> Dictionary:
	var sum := Color(0, 0, 0, 0)
	var lums := PackedFloat32Array()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := img.get_pixel(x, y)
			sum += c
			lums.append(c.get_luminance())
	var count := float(lums.size())
	var mean_lum := 0.0
	for l in lums:
		mean_lum += l
	mean_lum /= count
	var variance := 0.0
	for l in lums:
		variance += (l - mean_lum) * (l - mean_lum)
	var mean := Color(sum.r / count, sum.g / count, sum.b / count)
	var spread := sqrt(variance / count)
	print("paper mean ", mean, " std ", spread)
	return {"mean": mean, "std": spread}


func _save(img: Image, file: String) -> void:
	var path := ProjectSettings.globalize_path(OUT + file)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("saved ", path, " ", img.get_size())
