extends SceneTree
## Headless tests of the game logic. Run:
##   godot --headless --path . --script res://tests/run_tests.gd
## Exit code 0 = all passed, 1 = some failed.

var _checks := 0
var _failures := 0


func _init() -> void:
	_test_range()
	_test_move()
	_test_pistol()
	_test_machine_gun()
	_test_flamethrower()
	_test_grenade()
	_test_trifid_turn()
	_test_win()
	_test_level_loading()
	_test_serialization()
	_test_save_game()
	_test_custom_levels()
	_test_editor_rules()
	print("%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)


func _state(player: Vector2i) -> GameState:
	var state := GameState.new()
	state.player = player
	state.ammo = {
		GameState.AMMO_MACHINE_GUN: 2,
		GameState.AMMO_FLAMETHROWER: 2,
		GameState.AMMO_GRENADE: 2,
	}
	return state


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	return rng


func _test_range() -> void:
	var state := _state(Vector2i(4, 4))
	_check(Rules.in_range(state, Vector2i(8, 4)), "range: 4 cells straight is in range")
	_check(Rules.in_range(state, Vector2i(6, 7)), "range: (2,3) offset is in range")
	_check(not Rules.in_range(state, Vector2i(8, 5)), "range: (4,1) offset is out of range")
	_check(not Rules.in_range(state, Vector2i(7, 7)), "range: (3,3) offset is out of range")
	_check(Rules.range_cells(state).size() == 48, "range: 48 cells from the center")
	_check(Rules.range_cells(_state(Vector2i(0, 0))).size() == 16, "range: 16 cells from a corner")
	_check(Rules.weapon_range(Rules.Action.PISTOL) == 5, "range: pistol reaches 5")
	_check(Rules.weapon_range(Rules.Action.GRENADE) == 4, "range: grenade reaches 4")
	_check(Rules.in_range(state, Vector2i(8, 7), 5), "range 5: (4,3) offset is in range")
	_check(Rules.range_cells(state, 5).size() == 76, "range 5: 76 cells from the center")


func _test_move() -> void:
	_check(Rules.move_targets(_state(Vector2i(0, 0))).size() == 3, "move: 3 targets in a corner")
	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(5, 5), 1)
	_check(Rules.move_targets(state).size() == 7, "move: occupied cell is not a target")
	_check(Rules.perform(state, Rules.Action.MOVE, Vector2i(5, 5)) == Rules.INVALID, "move: cannot enter trifids")
	_check(Rules.perform(state, Rules.Action.MOVE, Vector2i(6, 6)) == Rules.INVALID, "move: only one cell")
	_check(Rules.perform(state, Rules.Action.MOVE, Vector2i(3, 3)) == 0, "move: valid move")
	_check(state.player == Vector2i(3, 3), "move: player moved")


func _cursor_at(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2(0.5, 0.5)


func _test_pistol() -> void:
	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(4, 6), 7)
	state.set_count(Vector2i(8, 8), 1)
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(4, 6)) == 7, "pistol: kills all on the cell")
	_check(state.get_count(Vector2i(4, 6)) == 0, "pistol: cell cleared")
	_check(state.kills == 7, "pistol: kills counted")
	_check(state.get_ammo(GameState.AMMO_MACHINE_GUN) == 2, "pistol: uses no ammo")
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(4, 6)) == Rules.INVALID, "pistol: empty cell is invalid")
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(8, 8)) == Rules.INVALID, "pistol: out of range is invalid")
	state.set_count(Vector2i(8, 7), 3)
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(8, 7)) == 3, "pistol: hits at distance 5")


func _test_machine_gun() -> void:
	var state := _state(Vector2i(4, 4))
	for direction: Vector2i in Rules.NEIGHBOR_OFFSETS:
		var expected: Array[Vector2i] = []
		for step in range(1, 5):
			expected.append(state.player + direction * step)
		var cells := Rules.machine_gun_cells(state, _cursor_at(state.player + direction * 3))
		_check(cells == expected, "machine gun: 4 cells toward %s" % direction)
	var bent: Array[Vector2i] = [Vector2i(5, 4), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5)]
	_check(Rules.machine_gun_cells(state, Vector2(7.5, 5.5)) == bent, "machine gun: free direction (3,1)")
	_check(Rules.machine_gun_cells(_state(Vector2i(7, 4)), Vector2(8.5, 4.5)).size() == 1, "machine gun: clipped at edge")
	_check(Rules.machine_gun_cells(state, Vector2(4.7, 4.2)).is_empty(), "machine gun: no aim on own cell")

	state.set_count(Vector2i(5, 4), 3)
	state.set_count(Vector2i(8, 4), 9)
	state.set_count(Vector2i(5, 5), 2)
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(8, 4), Vector2(8.5, 4.5)) == 12, "machine gun: kills everything in line")
	_check(state.get_count(Vector2i(5, 5)) == 2, "machine gun: other cells untouched")
	_check(state.get_ammo(GameState.AMMO_MACHINE_GUN) == 1, "machine gun: ammo decreased")
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(4, 4), Vector2(4.5, 4.5)) == Rules.INVALID, "machine gun: own cell is invalid")
	_check(state.get_ammo(GameState.AMMO_MACHINE_GUN) == 1, "machine gun: invalid use keeps ammo")
	Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(0, 4), Vector2(0.5, 4.5))
	_check(not Rules.can_use(state, Rules.Action.MACHINE_GUN), "machine gun: unusable at 0 ammo")
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(5, 5), Vector2(5.5, 5.5)) == Rules.INVALID, "machine gun: no ammo is invalid")
	_check(state.get_count(Vector2i(5, 5)) == 2, "machine gun: no ammo leaves trifids")


func _test_flamethrower() -> void:
	var state := _state(Vector2i(4, 4))
	var right := Rules.flame_cells(state, Vector2(8.5, 4.5))
	for x in range(5, 9):
		_check(right.has(Vector2i(x, 4)), "flame right: hits (%d,4)" % x)
	_check(right.has(Vector2i(6, 5)), "flame right: sector widens")
	_check(not right.has(Vector2i(5, 5)), "flame right: (5,5) is outside 15°")
	_check(not right.has(Vector2i(5, 6)), "flame right: (5,6) is outside")
	_check(not right.has(state.player), "flame: own cell never hit")

	var diagonal := Rules.flame_cells(state, Vector2(8.5, 8.5))
	_check(diagonal.has(Vector2i(5, 5)) and diagonal.has(Vector2i(6, 6)) and diagonal.has(Vector2i(7, 7)), "flame diagonal: hits the diagonal")
	_check(not diagonal.has(Vector2i(8, 8)), "flame diagonal: beyond radius 4")

	var between := Rules.flame_cells(state, Rules.fighter_center(state) + Vector2.from_angle(deg_to_rad(22.5)) * 3.0)
	_check(between.has(Vector2i(5, 4)), "flame between directions: no gap next to the fighter")

	var edge := _state(Vector2i(0, 4))
	var far := Rules.flame_cells(edge, Vector2(8.5, 4.5))
	_check(far.has(Vector2i(4, 4)) and not far.has(Vector2i(5, 4)), "flame: radius 4")
	_check(Rules.flame_cells(state, Vector2(4.7, 4.2)).is_empty(), "flame: no aim on own cell")

	state.set_count(Vector2i(6, 4), 5)
	state.set_count(Vector2i(6, 5), 2)
	state.set_count(Vector2i(5, 6), 4)
	_check(Rules.perform(state, Rules.Action.FLAMETHROWER, Vector2i(8, 4), Vector2(8.5, 4.5)) == 7, "flame: kills everything in the sector")
	_check(state.get_count(Vector2i(5, 6)) == 4, "flame: outside the sector untouched")
	_check(state.get_ammo(GameState.AMMO_FLAMETHROWER) == 1, "flame: ammo decreased")
	_check(Rules.perform(state, Rules.Action.FLAMETHROWER, Vector2i(4, 4), Vector2(4.5, 4.5)) == Rules.INVALID, "flame: own cell is invalid")
	_check(state.get_ammo(GameState.AMMO_FLAMETHROWER) == 1, "flame: invalid use keeps ammo")


func _test_grenade() -> void:
	var state := _state(Vector2i(4, 4))
	_check(Rules.grenade_cells(state, Vector2i(6, 6)).size() == 9, "grenade: full 3x3")
	_check(Rules.grenade_cells(state, Vector2i(8, 8)).is_empty(), "grenade: center out of range")
	_check(Rules.grenade_cells(_state(Vector2i(2, 2)), Vector2i(0, 0)).size() == 4, "grenade: clipped in a corner")
	state.set_count(Vector2i(5, 5), 9)
	state.set_count(Vector2i(6, 6), 3)
	state.set_count(Vector2i(7, 7), 5)
	_check(Rules.perform(state, Rules.Action.GRENADE, Vector2i(5, 5)) == 12, "grenade: kills in 3x3")
	_check(state.player == Vector2i(4, 4), "grenade: fighter is unharmed")
	_check(state.get_count(Vector2i(7, 7)) == 5, "grenade: outside the area untouched")
	_check(state.kills == 12, "grenade: kills counted")


func _test_trifid_turn() -> void:
	var single := _state(Vector2i(8, 8))
	single.set_count(Vector2i(0, 0), 1)
	_check(not Rules.trifid_turn(single, _rng()), "turn: no loss far away")
	_check(single.get_count(Vector2i(0, 0)) == 2, "turn: 1 doubles to 2")
	_check(single.turn == 2, "turn: counter increased")

	var spread := _state(Vector2i(8, 8))
	spread.set_count(Vector2i(4, 0), 5)
	Rules.trifid_turn(spread, _rng())
	_check(spread.get_count(Vector2i(4, 0)) == 9, "turn: 5 doubles and caps at 9")
	_check(spread.total_trifids() == 10, "turn: overflow spreads, new cell is not doubled")

	var crowded := _state(Vector2i(8, 8))
	for y in 3:
		for x in 3:
			crowded.set_count(Vector2i(x, y), 9)
	Rules.trifid_turn(crowded, _rng())
	_check(crowded.get_count(Vector2i(0, 0)) == 0, "turn: full corner cell surrounded by full cells dies")
	_check(crowded.get_count(Vector2i(1, 1)) == 0, "turn: full block dies together")
	var outside := 0
	for i in 4:
		outside += crowded.get_count(Vector2i(3, i)) + crowded.get_count(Vector2i(i, 3))
	_check(outside > 0, "turn: overflow still spreads outward")
	_check(crowded.kills == 0, "turn: overcrowding is not counted as kills")

	var open := _state(Vector2i(8, 8))
	open.set_count(Vector2i(4, 4), 9)
	Rules.trifid_turn(open, _rng())
	_check(open.get_count(Vector2i(4, 4)) == 9, "turn: full cell with free neighbors stays at 9")

	var blocked := _state(Vector2i(1, 0))
	blocked.set_count(Vector2i(0, 0), 9)
	blocked.set_count(Vector2i(0, 1), 9)
	blocked.set_count(Vector2i(1, 1), 9)
	_check(Rules.trifid_turn(blocked, _rng()), "turn: trifid reaching the fighter = loss")


func _test_win() -> void:
	var state := _state(Vector2i(4, 4))
	_check(Rules.is_won(state), "win: empty board")
	state.set_count(Vector2i(5, 5), 1)
	_check(not Rules.is_won(state), "win: not with a trifid left")


func _test_level_loading() -> void:
	_check(LevelLoader.level_exists(1), "level 1 exists")
	var number := 1
	while LevelLoader.level_exists(number):
		var level := LevelLoader.load_level(number)
		_check(level != null, "level %d loads and is valid" % number)
		if level != null:
			_check(level.total_trifids() > 0, "level %d has trifids" % number)
		number += 1

	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(0, 0), 1)
	var valid := state.to_dict()
	_check(LevelLoader.validate(valid) == "", "validate: saved level is valid")
	var bad_count := valid.duplicate(true)
	bad_count["trifids"][0]["count"] = 10
	_check(LevelLoader.validate(bad_count) != "", "validate: count 10 rejected")
	var on_player := valid.duplicate(true)
	on_player["trifids"].append({"x": 4, "y": 4, "count": 1})
	_check(LevelLoader.validate(on_player) != "", "validate: trifid on player rejected")
	var duplicate := valid.duplicate(true)
	duplicate["trifids"].append({"x": 0, "y": 0, "count": 2})
	_check(LevelLoader.validate(duplicate) != "", "validate: duplicate cell rejected")
	var no_player := valid.duplicate(true)
	no_player.erase("player")
	_check(LevelLoader.validate(no_player) != "", "validate: missing player rejected")


func _test_serialization() -> void:
	var state := _state(Vector2i(2, 3))
	state.set_count(Vector2i(7, 1), 6)
	state.kills = 5
	state.turn = 4
	var copy := GameState.from_dict(state.to_dict())
	_check(copy.player == state.player, "serialization: player")
	_check(copy.get_count(Vector2i(7, 1)) == 6, "serialization: trifids")
	_check(copy.kills == 5 and copy.turn == 4, "serialization: counters")
	_check(copy.get_ammo(GameState.AMMO_GRENADE) == 2, "serialization: ammo")


const TEST_SAVE := "user://test_save.json"
const TEST_LEVELS := "user://test_levels"


func _test_save_game() -> void:
	_remove(TEST_SAVE)
	_check(not SaveGame.exists(TEST_SAVE), "save: nothing saved yet")
	_check(SaveGame.load_game(TEST_SAVE).is_empty(), "save: loading nothing gives {}")
	var start := _state(Vector2i(4, 4))
	start.set_count(Vector2i(1, 1), 2)
	var state := start.duplicate_state()
	state.set_count(Vector2i(1, 1), 4)
	state.player = Vector2i(5, 5)
	state.kills = 3
	state.turn = 6
	state.ammo[GameState.AMMO_GRENADE] = 1
	var source := {"type": "campaign", "level": 2}
	_check(SaveGame.save(state, start, source, TEST_SAVE) == OK, "save: written")
	_check(SaveGame.exists(TEST_SAVE), "save: file exists")
	var saved := SaveGame.load_game(TEST_SAVE)
	_check(not saved.is_empty(), "save: loads back")
	if not saved.is_empty():
		var loaded: GameState = saved["state"]
		var loaded_start: GameState = saved["start"]
		_check(loaded.player == Vector2i(5, 5) and loaded.get_count(Vector2i(1, 1)) == 4, "save: board restored")
		_check(loaded.kills == 3 and loaded.turn == 6, "save: counters restored")
		_check(loaded.get_ammo(GameState.AMMO_GRENADE) == 1, "save: ammo restored")
		_check(loaded_start.get_count(Vector2i(1, 1)) == 2 and loaded_start.player == Vector2i(4, 4), "save: start of level restored")
		_check(saved["source"].get("type") == "campaign" and int(saved["source"].get("level")) == 2, "save: source restored")
	_remove(TEST_SAVE)


func _test_custom_levels() -> void:
	_check(LevelLoader.slugify("Můj první Level!") == "muj_prvni_level", "slug: diacritics and spaces")
	_check(LevelLoader.slugify("  ") == "level", "slug: empty name")
	_clear_dir(TEST_LEVELS)
	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(0, 0), 3)
	state.level_name = "Žlutý kůň"
	var first := LevelLoader.save_custom(state.to_level_dict(), "", TEST_LEVELS)
	var second := LevelLoader.save_custom(state.to_level_dict(), "", TEST_LEVELS)
	_check(first.get_file() == "zluty_kun.json", "custom: file named after the level")
	_check(second.get_file() == "zluty_kun_2.json", "custom: unique file name")
	state.set_count(Vector2i(0, 0), 5)
	_check(LevelLoader.save_custom(state.to_level_dict(), first, TEST_LEVELS) == first, "custom: overwrite keeps the file")
	_check(LevelLoader.list_custom(TEST_LEVELS).size() == 2, "custom: listed")
	var loaded := LevelLoader.load_from_path(first)
	_check(loaded != null and loaded.get_count(Vector2i(0, 0)) == 5, "custom: loads the overwritten level")
	_check(loaded != null and loaded.level_name == "Žlutý kůň", "custom: name kept")
	_check(not state.to_level_dict().has("kills"), "custom: level data has no game progress")
	_check(LevelLoader.next_campaign_number() == LevelLoader.campaign_numbers().back() + 1, "campaign: next number")
	_clear_dir(TEST_LEVELS)


func _test_editor_rules() -> void:
	var state := EditorRules.new_level()
	_check(state.player == Vector2i(4, 4) and state.total_trifids() == 0, "editor: new level")
	_check(EditorRules.check(state, false) == EditorRules.ERROR_NO_TRIFIDS, "editor: needs a trifid")
	_check(EditorRules.place_trifids(state, Vector2i(2, 2), 12), "editor: place trifids")
	_check(state.get_count(Vector2i(2, 2)) == 9, "editor: count capped at 9")
	_check(not EditorRules.place_trifids(state, Vector2i(4, 4), 3), "editor: not on the fighter")
	_check(EditorRules.check(state, true) == EditorRules.ERROR_NO_NAME, "editor: saving needs a name")
	state.level_name = "Test"
	_check(EditorRules.check(state, true) == "", "editor: valid level")
	EditorRules.place_player(state, Vector2i(2, 2))
	_check(state.player == Vector2i(2, 2) and state.get_count(Vector2i(2, 2)) == 0, "editor: fighter replaces trifids")
	EditorRules.place_trifids(state, Vector2i(3, 3), 2)
	EditorRules.erase(state, Vector2i(3, 3))
	_check(state.get_count(Vector2i(3, 3)) == 0, "editor: eraser")
	EditorRules.set_ammo(state, GameState.AMMO_GRENADE, 150)
	_check(state.get_ammo(GameState.AMMO_GRENADE) == EditorRules.MAX_AMMO, "editor: ammo capped")
	EditorRules.set_ammo(state, GameState.AMMO_GRENADE, -3)
	_check(state.get_ammo(GameState.AMMO_GRENADE) == 0, "editor: ammo not negative")


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _clear_dir(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
