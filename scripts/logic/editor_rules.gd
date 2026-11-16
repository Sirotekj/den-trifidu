class_name EditorRules
extends RefCounted
## Level editing operations (GAME_DESIGN.md, chapter 11), independent of the editor scene.

const MAX_AMMO := 99
const DEFAULT_AMMO := {
	GameState.AMMO_MACHINE_GUN: 10,
	GameState.AMMO_FLAMETHROWER: 5,
	GameState.AMMO_GRENADE: 3,
}
const ERROR_NO_TRIFIDS := "EDITOR_ERR_NO_TRIFIDS"
const ERROR_NO_NAME := "EDITOR_ERR_NO_NAME"
const ERROR_INVALID := "EDITOR_ERR_INVALID"


## Empty board with the fighter in the center and default ammo.
static func new_level() -> GameState:
	var state := GameState.new()
	@warning_ignore("integer_division")
	state.player = Vector2i(GameState.SIZE / 2, GameState.SIZE / 2)
	state.ammo = DEFAULT_AMMO.duplicate()
	return state


## Moves the fighter; trifids on the target cell are removed.
static func place_player(state: GameState, cell: Vector2i) -> void:
	if not GameState.in_bounds(cell):
		return
	state.set_count(cell, 0)
	state.player = cell


## Sets the trifid count on a cell. Returns false for the fighter's cell.
static func place_trifids(state: GameState, cell: Vector2i, count: int) -> bool:
	if not GameState.in_bounds(cell) or cell == state.player:
		return false
	state.set_count(cell, clampi(count, 1, GameState.MAX_COUNT))
	return true


static func erase(state: GameState, cell: Vector2i) -> void:
	if GameState.in_bounds(cell):
		state.set_count(cell, 0)


static func set_ammo(state: GameState, key: String, value: int) -> void:
	state.ammo[key] = clampi(value, 0, MAX_AMMO)


## "" when the level can be played/saved, otherwise a translation key of the problem.
static func check(state: GameState, require_name: bool) -> String:
	if state.total_trifids() == 0:
		return ERROR_NO_TRIFIDS
	if require_name and state.level_name.strip_edges() == "":
		return ERROR_NO_NAME
	if LevelLoader.validate(state.to_level_dict()) != "":
		return ERROR_INVALID
	return ""
