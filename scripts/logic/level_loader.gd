class_name LevelLoader
extends RefCounted
## Loads and validates level JSON files (format: GAME_DESIGN.md, chapter 10).

const LEVEL_PATH_FORMAT := "res://levels/level_%02d.json"


static func level_path(number: int) -> String:
	return LEVEL_PATH_FORMAT % number


static func level_exists(number: int) -> bool:
	return FileAccess.file_exists(level_path(number))


## Returns the level state, or null when the file is missing or invalid.
static func load_level(number: int) -> GameState:
	var path := level_path(number)
	if not FileAccess.file_exists(path):
		push_error("Level file not found: %s" % path)
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_error("Level file is not a JSON object: %s" % path)
		return null
	var error := validate(data)
	if error != "":
		push_error("Invalid level %s: %s" % [path, error])
		return null
	return GameState.from_dict(data)


## Returns "" when the data is a valid level, otherwise a description of the problem.
static func validate(data: Dictionary) -> String:
	if not (data.get("player") is Dictionary):
		return "missing player"
	var player := _read_cell(data["player"])
	if not GameState.in_bounds(player):
		return "player is outside the board"
	if not (data.get("trifids") is Array):
		return "missing trifids"
	var seen := {}
	for trifid: Variant in data["trifids"]:
		if not (trifid is Dictionary):
			return "invalid trifid entry"
		var cell := _read_cell(trifid)
		if not GameState.in_bounds(cell):
			return "trifid is outside the board"
		if cell == player:
			return "trifid is on the player's cell"
		if seen.has(cell):
			return "two entries for cell %s" % cell
		seen[cell] = true
		var count: Variant = trifid.get("count")
		if not _is_number(count) or int(count) < 1 or int(count) > GameState.MAX_COUNT:
			return "trifid count must be 1-%d" % GameState.MAX_COUNT
	if not (data.get("ammo") is Dictionary):
		return "missing ammo"
	var ammo: Dictionary = data["ammo"]
	for key in GameState.AMMO_KEYS:
		var value: Variant = ammo.get(key)
		if not _is_number(value) or int(value) < 0:
			return "ammo '%s' must be a number >= 0" % key
	return ""


static func _read_cell(data: Dictionary) -> Vector2i:
	var x: Variant = data.get("x")
	var y: Variant = data.get("y")
	if not _is_number(x) or not _is_number(y):
		return Vector2i(-1, -1)
	return Vector2i(int(x), int(y))


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
