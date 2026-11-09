class_name BoardView
extends Control
## Draws the 9×9 board with placeholder shapes and turns mouse input into cell clicks.

## `cursor` is the mouse position in cell units (1.0 = one cell), needed by the flamethrower.
signal cell_clicked(cell: Vector2i, cursor: Vector2)

const CELL_SIZE := 54.0
const PAPER_COLOR := Color(0.97, 0.95, 0.9)
const GRID_COLOR := Color(0.25, 0.22, 0.2)
const RANGE_COLOR := Color(0.95, 0.85, 0.4, 0.35)
const GRENADE_RANGE_COLOR := Color(0.95, 0.85, 0.4, 0.18)
const TARGET_COLOR := Color(0.95, 0.6, 0.2, 0.45)
const HOVER_COLOR := Color(0.9, 0.3, 0.1, 0.55)
const PLAYER_COLOR := Color(0.35, 0.25, 0.15)
const PLAYER_INNER_COLOR := Color(0.85, 0.7, 0.5)
const TRIFID_COLOR := Color(0.3, 0.55, 0.2)
const TRIFID_TEXT_COLOR := Color(1, 1, 1)
const CAUGHT_COLOR := Color(0.85, 0.1, 0.1)
const FONT_SIZE := 22

var state: GameState
var action: int = Rules.NONE
var interactive: bool = true

var _cursor: Vector2 = Vector2.ZERO
var _hovering: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * CELL_SIZE * GameState.SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


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
	draw_rect(Rect2(Vector2.ZERO, size), PAPER_COLOR)
	if state == null:
		return
	_draw_highlights()
	_draw_grid()
	for cell in GameState.all_cells():
		if cell == state.player:
			_draw_player(cell)
		var count := state.get_count(cell)
		if count > 0:
			_draw_trifid(cell, count)


func _draw_highlights() -> void:
	if not interactive or not Rules.can_use(state, action):
		return
	var hover_cell := Vector2i(_cursor.floor())
	match action:
		Rules.Action.MOVE:
			_fill_cells(Rules.move_targets(state), TARGET_COLOR)
		Rules.Action.PISTOL, Rules.Action.MACHINE_GUN:
			_fill_cells(Rules.range_cells(state, Rules.weapon_range(action)), RANGE_COLOR)
			_fill_cells(Rules.shoot_targets(state, action), TARGET_COLOR)
		Rules.Action.GRENADE:
			_fill_cells(Rules.range_cells(state, Rules.weapon_range(action)), GRENADE_RANGE_COLOR)
	# Flamethrower and grenade show their blast area under the cursor.
	if _hovering:
		_fill_cells(Rules.target_cells(state, action, hover_cell, _cursor), HOVER_COLOR)


func _fill_cells(cells: Array[Vector2i], color: Color) -> void:
	for cell in cells:
		draw_rect(_cell_rect(cell), color)


func _draw_grid() -> void:
	var length := CELL_SIZE * GameState.SIZE
	for i in range(1, GameState.SIZE):
		var offset := i * CELL_SIZE
		draw_line(Vector2(offset, 0), Vector2(offset, length), GRID_COLOR, 1.5)
		draw_line(Vector2(0, offset), Vector2(length, offset), GRID_COLOR, 1.5)
	draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * length), GRID_COLOR, false, 3.0)


func _draw_player(cell: Vector2i) -> void:
	var center := _cell_rect(cell).get_center()
	draw_circle(center, CELL_SIZE * 0.38, PLAYER_COLOR)
	draw_circle(center, CELL_SIZE * 0.2, PLAYER_INNER_COLOR)


func _draw_trifid(cell: Vector2i, count: int) -> void:
	var rect := _cell_rect(cell)
	var center := rect.get_center()
	draw_circle(center, CELL_SIZE * 0.36, TRIFID_COLOR)
	if cell == state.player:
		draw_arc(center, CELL_SIZE * 0.44, 0.0, TAU, 32, CAUGHT_COLOR, 3.0)
	var font := get_theme_default_font()
	var baseline := center.y + (font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) / 2.0
	draw_string(font, Vector2(rect.position.x, baseline), str(count),
		HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, FONT_SIZE, TRIFID_TEXT_COLOR)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
