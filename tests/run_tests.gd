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
	_test_flame_direction()
	_test_flamethrower()
	_test_grenade()
	_test_trifid_turn()
	_test_win()
	_test_level_loading()
	_test_serialization()
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
	_check(Rules.weapon_range(Rules.Action.MACHINE_GUN) == 4, "range: machine gun reaches 4")
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


func _test_pistol() -> void:
	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(4, 6), 2)
	state.set_count(Vector2i(8, 8), 1)
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(4, 6)) == 1, "pistol: kills one")
	_check(state.get_count(Vector2i(4, 6)) == 1, "pistol: count decreased")
	Rules.perform(state, Rules.Action.PISTOL, Vector2i(4, 6))
	_check(state.get_count(Vector2i(4, 6)) == 0, "pistol: trifid disappears at 0")
	_check(state.kills == 2, "pistol: kills counted")
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(4, 6)) == Rules.INVALID, "pistol: empty cell is invalid")
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(8, 8)) == Rules.INVALID, "pistol: out of range is invalid")
	state.set_count(Vector2i(8, 7), 1)
	_check(Rules.perform(state, Rules.Action.PISTOL, Vector2i(8, 7)) == 1, "pistol: hits at distance 5")
	state.set_count(Vector2i(8, 7), 1)
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(8, 7)) == Rules.INVALID, "machine gun: distance 5 is out of range")


func _test_machine_gun() -> void:
	var state := _state(Vector2i(4, 4))
	state.set_count(Vector2i(5, 5), 7)
	state.set_count(Vector2i(3, 3), 4)
	state.set_count(Vector2i(2, 2), 4)
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(5, 5)) == 7, "machine gun: kills all on cell")
	_check(state.get_count(Vector2i(5, 5)) == 0, "machine gun: cell cleared")
	_check(state.get_ammo(GameState.AMMO_MACHINE_GUN) == 1, "machine gun: ammo decreased")
	Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(3, 3))
	_check(not Rules.can_use(state, Rules.Action.MACHINE_GUN), "machine gun: unusable at 0 ammo")
	_check(Rules.perform(state, Rules.Action.MACHINE_GUN, Vector2i(2, 2)) == Rules.INVALID, "machine gun: no ammo is invalid")
	_check(state.get_count(Vector2i(2, 2)) == 4, "machine gun: no ammo leaves trifids")


func _test_flame_direction() -> void:
	var origin := Vector2i(4, 4)
	var expected := {
		Vector2i(8, 4): Vector2i(1, 0),
		Vector2i(0, 4): Vector2i(-1, 0),
		Vector2i(4, 0): Vector2i(0, -1),
		Vector2i(4, 8): Vector2i(0, 1),
		Vector2i(8, 8): Vector2i(1, 1),
		Vector2i(0, 0): Vector2i(-1, -1),
		Vector2i(8, 0): Vector2i(1, -1),
		Vector2i(0, 8): Vector2i(-1, 1),
		Vector2i(8, 5): Vector2i(1, 0),
		Vector2i(7, 6): Vector2i(1, 1),
	}
	for cell: Vector2i in expected:
		var cursor := Vector2(cell) + Vector2(0.5, 0.5)
		_check(Rules.flame_direction(origin, cursor) == expected[cell], "flame direction toward %s" % cell)
	_check(Rules.flame_direction(origin, Vector2(4.7, 4.2)) == Vector2i.ZERO, "flame direction: none on own cell")


func _test_flamethrower() -> void:
	var state := _state(Vector2i(4, 4))
	_check(Rules.flame_cells(state, Vector2i(1, 0)).size() == 4, "flame: 4 cells")
	_check(Rules.flame_cells(_state(Vector2i(7, 4)), Vector2i(1, 0)).size() == 1, "flame: clipped at edge")
	state.set_count(Vector2i(5, 4), 3)
	state.set_count(Vector2i(8, 4), 9)
	state.set_count(Vector2i(5, 5), 2)
	var killed := Rules.perform(state, Rules.Action.FLAMETHROWER, Vector2i(8, 4), Vector2(8.5, 4.5))
	_check(killed == 12, "flame: kills everything in line")
	_check(state.get_count(Vector2i(5, 5)) == 2, "flame: other cells untouched")
	_check(state.get_ammo(GameState.AMMO_FLAMETHROWER) == 1, "flame: ammo decreased")
	var edge := _state(Vector2i(8, 4))
	_check(Rules.perform(edge, Rules.Action.FLAMETHROWER, Vector2i(8, 4), Vector2(8.9, 4.5)) == Rules.INVALID, "flame: own cell is invalid")
	_check(edge.get_ammo(GameState.AMMO_FLAMETHROWER) == 2, "flame: invalid use keeps ammo")


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
