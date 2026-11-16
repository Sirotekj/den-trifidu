class_name SaveGame
extends RefCounted
## The single saved game (GAME_DESIGN.md, chapter 9). The file holds the current state,
## the level as it was at its start (for "play again") and where the level came from.

const PATH := "user://save.json"


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(path)


## `source` describes the level origin, e.g. {"type": "campaign", "level": 2}.
static func save(state: GameState, start: GameState, source: Dictionary, path: String = PATH) -> Error:
	var data := state.to_dict()
	data["start"] = start.to_level_dict()
	data["source"] = source.duplicate()
	return LevelLoader.write_json(path, data)


## Returns {"state": GameState, "start": GameState, "source": Dictionary},
## or {} when there is no valid saved game.
static func load_game(path: String = PATH) -> Dictionary:
	var data := LevelLoader.read_json(path)
	if data.is_empty() or LevelLoader.validate(data) != "":
		return {}
	var start_data: Variant = data.get("start")
	if not (start_data is Dictionary) or LevelLoader.validate(start_data) != "":
		return {}
	var source: Variant = data.get("source")
	return {
		"state": GameState.from_dict(data),
		"start": GameState.from_dict(start_data),
		"source": source if source is Dictionary else {},
	}
