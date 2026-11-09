class_name GameState
extends RefCounted
## Complete state of one game in progress: board, fighter, ammo and counters.
## Pure data without any scene dependency, shared by the game and the editor.

const SIZE := 9
const MAX_COUNT := 9
const AMMO_MACHINE_GUN := "machine_gun"
const AMMO_FLAMETHROWER := "flamethrower"
const AMMO_GRENADE := "grenade"
const AMMO_KEYS: Array[String] = [AMMO_MACHINE_GUN, AMMO_FLAMETHROWER, AMMO_GRENADE]
const FORMAT_VERSION := 1

var level_name: String = ""
var player: Vector2i = Vector2i.ZERO
var ammo: Dictionary = {AMMO_MACHINE_GUN: 0, AMMO_FLAMETHROWER: 0, AMMO_GRENADE: 0}
var kills: int = 0
var turn: int = 1

## Number of trifids per cell, row by row (index = y * SIZE + x). 0 = empty cell.
var _counts: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	_counts.resize(SIZE * SIZE)
	_counts.fill(0)


static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE


## All board cells, row by row from the top-left corner.
static func all_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in SIZE:
		for x in SIZE:
			result.append(Vector2i(x, y))
	return result


func get_count(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return 0
	return _counts[cell.y * SIZE + cell.x]


func set_count(cell: Vector2i, count: int) -> void:
	_counts[cell.y * SIZE + cell.x] = clampi(count, 0, MAX_COUNT)


func total_trifids() -> int:
	var total := 0
	for count in _counts:
		total += count
	return total


func get_ammo(key: String) -> int:
	return int(ammo.get(key, 0))


## Builds a state from level or save data. The data must already be validated
## (see LevelLoader.validate).
static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.level_name = str(data.get("name", ""))
	var player_data: Dictionary = data["player"]
	state.player = Vector2i(int(player_data["x"]), int(player_data["y"]))
	for trifid: Dictionary in data["trifids"]:
		state.set_count(Vector2i(int(trifid["x"]), int(trifid["y"])), int(trifid["count"]))
	var ammo_data: Dictionary = data["ammo"]
	for key in AMMO_KEYS:
		state.ammo[key] = int(ammo_data.get(key, 0))
	state.kills = int(data.get("kills", 0))
	state.turn = int(data.get("turn", 1))
	return state


## Serializes the state; the format is a superset of the level format,
## so it can be used both for levels and for saved games.
func to_dict() -> Dictionary:
	var trifids: Array = []
	for cell in all_cells():
		var count := get_count(cell)
		if count > 0:
			trifids.append({"x": cell.x, "y": cell.y, "count": count})
	return {
		"version": FORMAT_VERSION,
		"name": level_name,
		"player": {"x": player.x, "y": player.y},
		"trifids": trifids,
		"ammo": ammo.duplicate(),
		"kills": kills,
		"turn": turn,
	}
