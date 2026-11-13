class_name BoardView
extends Control
## Draws the 9×9 board (hand-drawn grid, fighter and trifid sprites) and turns mouse input
## into cell clicks. Falls back to simple shapes when a sprite is missing.

## `cursor` is the mouse position in cell units (1.0 = one cell), needed by the flamethrower.
signal cell_clicked(cell: Vector2i, cursor: Vector2)

const CELL_SIZE := 54.0

const FIGHTER_TEXTURE := "res://assets/graphics/characters/fighter.png"
const TRIFID_TEXTURE := "res://assets/graphics/characters/trifid.png"
const LABEL_TEXTURE := "res://assets/graphics/ui/trifid_label.png"

const INK_COLOR := Color(0.12, 0.1, 0.09)
const GRID_COLOR := Color(0.12, 0.1, 0.09, 0.85)
const GRID_SHADOW_COLOR := Color(0.12, 0.1, 0.09, 0.3)
## How far the hand-drawn lines wobble, in pixels.
const GRID_JITTER := 0.5
const RANGE_COLOR := Color(0.95, 0.8, 0.25, 0.3)
const GRENADE_RANGE_COLOR := Color(0.95, 0.8, 0.25, 0.16)
const TARGET_COLOR := Color(0.95, 0.55, 0.15, 0.35)
const TARGET_OUTLINE_COLOR := Color(0.85, 0.4, 0.05, 0.95)
const HOVER_COLOR := Color(0.9, 0.25, 0.08, 0.4)
const HOVER_OUTLINE_COLOR := Color(0.75, 0.12, 0.03, 1.0)
const CAUGHT_COLOR := Color(0.8, 0.1, 0.05)
## Number label in the bottom-right corner of a trifid cell (fraction of the cell).
const LABEL_SIZE := Vector2(0.38, 0.45)
const LABEL_FONT_SIZE := 15
## Sprites are drawn a bit bigger than the cell (standing on its bottom edge).
const SPRITE_SCALE := 1.12
## Shapes used when a sprite is missing.
const PLAYER_COLOR := Color(0.35, 0.25, 0.15)
const PLAYER_INNER_COLOR := Color(0.85, 0.7, 0.5)
const TRIFID_COLOR := Color(0.3, 0.55, 0.2)
const FALLBACK_FONT_SIZE := 22

var state: GameState
var action: int = Rules.NONE
var interactive: bool = true

var _cursor: Vector2 = Vector2.ZERO
var _hovering: bool = false
var _fighter_texture: Texture2D = _load_texture(FIGHTER_TEXTURE)
var _trifid_texture: Texture2D = _load_texture(TRIFID_TEXTURE)
var _label_texture: Texture2D = _load_texture(LABEL_TEXTURE)
var _grid_lines: Array[PackedVector2Array] = []


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * CELL_SIZE * GameState.SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_grid()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor = event.position / CELL_SIZE
		_hovering = true
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cursor: Vector2 = event.position / CELL_SIZE
		var cell := Vector2i(cursor.floor())
		if interactive and GameState.in_bounds(cell):
			cell_clicked.emit(cell, cursor)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovering = false
		queue_redraw()


func _draw() -> void:
	# The paper comes from the background texture, the board only draws ink.
	if state == null:
		_draw_grid()
		return
	var outlines := _draw_highlights()
	_draw_grid()
	for cell in GameState.all_cells():
		if cell == state.player:
			_draw_player(cell)
		var count := state.get_count(cell)
		if count > 0:
			_draw_trifid(cell, count)
	# Outlines go over the sprites so targets stay visible on top of the trifids.
	for outline: Array in outlines:
		for cell: Vector2i in outline[0]:
			draw_rect(_cell_rect(cell).grow(-2.0), outline[1], false, outline[2])


## Fills the highlighted cells and returns the outlines to draw over the sprites
## as [cells, color, width] items.
func _draw_highlights() -> Array:
	var outlines: Array = []
	if not interactive or not Rules.can_use(state, action):
		return outlines
	var hover_cell := Vector2i(_cursor.floor())
	match action:
		Rules.Action.MOVE:
			var targets := Rules.move_targets(state)
			_fill_cells(targets, TARGET_COLOR)
			outlines.append([targets, TARGET_OUTLINE_COLOR, 2.0])
		Rules.Action.PISTOL, Rules.Action.MACHINE_GUN:
			_fill_cells(Rules.range_cells(state, Rules.weapon_range(action)), RANGE_COLOR)
			var targets := Rules.shoot_targets(state, action)
			_fill_cells(targets, TARGET_COLOR)
			outlines.append([targets, TARGET_OUTLINE_COLOR, 2.0])
		Rules.Action.GRENADE:
			_fill_cells(Rules.range_cells(state, Rules.weapon_range(action)), GRENADE_RANGE_COLOR)
	# Flamethrower and grenade show their blast area under the cursor.
	if _hovering:
		var area := Rules.target_cells(state, action, hover_cell, _cursor)
		_fill_cells(area, HOVER_COLOR)
		outlines.append([area, HOVER_OUTLINE_COLOR, 3.0])
	return outlines


func _fill_cells(cells: Array[Vector2i], color: Color) -> void:
	for cell in cells:
		draw_rect(_cell_rect(cell), color)


## Precomputes slightly wobbly grid lines so the grid looks drawn by hand.
func _build_grid() -> void:
	_grid_lines.clear()
	var length := CELL_SIZE * GameState.SIZE
	for i in range(0, GameState.SIZE + 1):
		var offset := i * CELL_SIZE
		_grid_lines.append(_wobbly_line(Vector2(offset, 0), Vector2(offset, length), i * 2))
		_grid_lines.append(_wobbly_line(Vector2(0, offset), Vector2(length, offset), i * 2 + 1))


func _wobbly_line(from: Vector2, to: Vector2, line_seed: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := GameState.SIZE * 2
	var normal := (to - from).orthogonal().normalized()
	for step in steps + 1:
		var t := float(step) / steps
		var wobble := _noise(line_seed, step) * GRID_JITTER
		points.append(from.lerp(to, t) + normal * wobble)
	return points


## Deterministic pseudo-random value in [-1, 1] (only for the look of the grid).
func _noise(a: int, b: int) -> float:
	var value := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return (value - floorf(value)) * 2.0 - 1.0


func _draw_grid() -> void:
	var last := _grid_lines.size() - 2
	for i in _grid_lines.size():
		var line := _grid_lines[i]
		var is_border := i < 2 or i >= last
		draw_polyline(line, GRID_COLOR, 2.6 if is_border else 1.6, true)
		# A second, lighter stroke next to the line, like a pen going over it twice.
		var shift := Vector2(0.9, 0.7) if is_border else Vector2(0.6, -0.5)
		var shadow := PackedVector2Array()
		for point in line:
			shadow.append(point + shift)
		draw_polyline(shadow, GRID_SHADOW_COLOR, 1.2, true)
	# Outer double border like in the sketch.
	var length := CELL_SIZE * GameState.SIZE
	draw_rect(Rect2(Vector2.ONE * -4.0, Vector2.ONE * (length + 8.0)), GRID_SHADOW_COLOR, false, 1.5)


func _draw_player(cell: Vector2i) -> void:
	var rect := _cell_rect(cell)
	if _fighter_texture != null:
		draw_texture_rect(_fighter_texture, _sprite_rect(rect), false)
		return
	var center := rect.get_center()
	draw_circle(center, CELL_SIZE * 0.38, PLAYER_COLOR)
	draw_circle(center, CELL_SIZE * 0.2, PLAYER_INNER_COLOR)


func _draw_trifid(cell: Vector2i, count: int) -> void:
	var rect := _cell_rect(cell)
	var center := rect.get_center()
	if cell == state.player:
		draw_arc(center, CELL_SIZE * 0.46, 0.0, TAU, 32, CAUGHT_COLOR, 3.0)
	if _trifid_texture == null or _label_texture == null:
		_draw_trifid_shape(rect, count)
		return
	# The trifid stands a bit to the left to make room for its number label.
	draw_texture_rect(_trifid_texture, _sprite_rect(rect).grow_individual(5.0, 0.0, -5.0, 0.0), false)
	var label_size := LABEL_SIZE * CELL_SIZE
	var label_rect := Rect2(rect.end - label_size - Vector2(1.0, 1.0), label_size)
	draw_texture_rect(_label_texture, label_rect, false)
	var font := get_theme_default_font()
	var baseline := label_rect.get_center().y \
		+ (font.get_ascent(LABEL_FONT_SIZE) - font.get_descent(LABEL_FONT_SIZE)) / 2.0
	draw_string(font, Vector2(label_rect.position.x + 1.0, baseline), str(count),
		HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, LABEL_FONT_SIZE, INK_COLOR)


func _draw_trifid_shape(rect: Rect2, count: int) -> void:
	var center := rect.get_center()
	draw_circle(center, CELL_SIZE * 0.36, TRIFID_COLOR)
	var font := get_theme_default_font()
	var baseline := center.y + (font.get_ascent(FALLBACK_FONT_SIZE) - font.get_descent(FALLBACK_FONT_SIZE)) / 2.0
	draw_string(font, Vector2(rect.position.x, baseline), str(count),
		HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, FALLBACK_FONT_SIZE, Color.WHITE)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("Missing sprite, drawing a placeholder: " + path)
		return null
	return load(path) as Texture2D


## Sprite area for a cell: SPRITE_SCALE times the cell, centred, standing on the cell bottom.
func _sprite_rect(cell_rect: Rect2) -> Rect2:
	var sprite_size := cell_rect.size * SPRITE_SCALE
	var origin := Vector2(cell_rect.get_center().x - sprite_size.x / 2.0, cell_rect.end.y - sprite_size.y)
	return Rect2(origin, sprite_size)
