class_name LevelLoader
extends RefCounted
## Loads, validates and saves level JSON files (format: GAME_DESIGN.md, chapter 10).
## Campaign levels live in res://levels/level_NN.json, the player's own levels
## in user://levels/<name>.json.

const CAMPAIGN_DIR := "res://levels"
const CUSTOM_DIR := "user://levels"
const LEVEL_PATH_FORMAT := "res://levels/level_%02d.json"
const ACCENTS := "áäčďéěëíňóöřšťúůüýžÁÄČĎÉĚËÍŇÓÖŘŠŤÚŮÜÝŽ"
const PLAIN := "aacdeeeinoorstuuuyzAACDEEEINOORSTUUUYZ"


static func level_path(number: int) -> String:
	return LEVEL_PATH_FORMAT % number


static func level_exists(number: int) -> bool:
	return FileAccess.file_exists(level_path(number))


## Returns the campaign level state, or null when the file is missing or invalid.
static func load_level(number: int) -> GameState:
	return load_from_path(level_path(number))


## Returns the level state from any level file, or null when missing or invalid.
static func load_from_path(path: String) -> GameState:
	var data := read_json(path)
	if data.is_empty():
		push_error("Level file missing or not a JSON object: %s" % path)
		return null
	var error := validate(data)
	if error != "":
		push_error("Invalid level %s: %s" % [path, error])
		return null
	return GameState.from_dict(data)


## Parsed JSON object from a file, or {} when the file is missing or not an object.
static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func write_json(path: String, data: Dictionary) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK and error != ERR_ALREADY_EXISTS:
		return error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "  ", false) + "\n")
	file.close()
	return OK


## Numbers of the existing campaign levels, ascending.
static func campaign_numbers() -> Array[int]:
	var result: Array[int] = []
	for file in DirAccess.get_files_at(CAMPAIGN_DIR):
		if file.begins_with("level_") and file.ends_with(".json"):
			var number := file.trim_prefix("level_").trim_suffix(".json")
			if number.is_valid_int():
				result.append(number.to_int())
	result.sort()
	return result


static func next_campaign_number() -> int:
	var numbers := campaign_numbers()
	return 1 if numbers.is_empty() else numbers.back() + 1


static func save_campaign(data: Dictionary, number: int) -> Error:
	return write_json(level_path(number), data)


## Paths of the player's own levels, sorted by file name.
static func list_custom(dir: String = CUSTOM_DIR) -> Array[String]:
	var result: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir):
		return result
	var files := Array(DirAccess.get_files_at(dir))
	files.sort()
	for file: String in files:
		if file.ends_with(".json"):
			result.append(dir.path_join(file))
	return result


## Saves the player's own level. Overwrites `existing_path` when given (and inside `dir`),
## otherwise creates a new file named after the level. Returns the path, or "" on error.
static func save_custom(data: Dictionary, existing_path: String = "", dir: String = CUSTOM_DIR) -> String:
	var path := existing_path
	if path == "" or path.get_base_dir() != dir:
		path = unique_path(dir, slugify(str(data.get("name", ""))))
	return path if write_json(path, data) == OK else ""


## File-name friendly form of a level name: no diacritics, lower case, underscores.
static func slugify(level_name: String) -> String:
	var result := ""
	for character in level_name.strip_edges():
		var accent := ACCENTS.find(character)
		if accent >= 0:
			character = PLAIN[accent]
		character = character.to_lower()
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif not result.ends_with("_"):
			result += "_"
	result = result.trim_prefix("_").trim_suffix("_")
	return result if result != "" else "level"


static func unique_path(dir: String, slug: String) -> String:
	var path := dir.path_join(slug + ".json")
	var suffix := 2
	while FileAccess.file_exists(path):
		path = dir.path_join("%s_%d.json" % [slug, suffix])
		suffix += 1
	return path


## Level name stored in a level file (for lists), "" when missing.
static func read_name(path: String) -> String:
	return str(read_json(path).get("name", ""))


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
