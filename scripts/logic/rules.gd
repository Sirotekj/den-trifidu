class_name Rules
extends RefCounted
## Game rules as pure static functions (see GAME_DESIGN.md, chapters 5-7).

enum Action { MOVE, PISTOL, MACHINE_GUN, FLAMETHROWER, GRENADE }

const NONE := -1
const INVALID := -1
const ACTIONS: Array[int] = [
	Action.MOVE, Action.PISTOL, Action.MACHINE_GUN, Action.FLAMETHROWER, Action.GRENADE,
]
## Weapon ranges in cells, measured between cell centers.
const PISTOL_RANGE := 5
const RANGE := 4
const FLAME_LENGTH := 4
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


## Ammo key for weapons with limited uses, "" for unlimited actions.
static func ammo_key(action: int) -> String:
	match action:
		Action.MACHINE_GUN:
			return GameState.AMMO_MACHINE_GUN
		Action.FLAMETHROWER:
			return GameState.AMMO_FLAMETHROWER
		Action.GRENADE:
			return GameState.AMMO_GRENADE
	return ""


static func can_use(state: GameState, action: int) -> bool:
	if not ACTIONS.has(action):
		return false
	var key := ammo_key(action)
	return key == "" or state.get_ammo(key) > 0


static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in NEIGHBOR_OFFSETS:
		var neighbor := cell + offset
		if GameState.in_bounds(neighbor):
			result.append(neighbor)
	return result


## Range of the action in cells (pistol 5, machine gun and grenade 4).
static func weapon_range(action: int) -> int:
	return PISTOL_RANGE if action == Action.PISTOL else RANGE


static func in_range(state: GameState, cell: Vector2i, radius: int = RANGE) -> bool:
	var delta := cell - state.player
	return delta.x * delta.x + delta.y * delta.y <= radius * radius


## Cells within the given range, excluding the fighter's own cell.
static func range_cells(state: GameState, radius: int = RANGE) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in GameState.all_cells():
		if cell != state.player and in_range(state, cell, radius):
			result.append(cell)
	return result


static func move_targets(state: GameState) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in neighbors(state.player):
		if state.get_count(cell) == 0:
			result.append(cell)
	return result


## Cells in range of the weapon that contain trifids (valid pistol and machine gun targets).
static func shoot_targets(state: GameState, action: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in range_cells(state, weapon_range(action)):
		if state.get_count(cell) > 0:
			result.append(cell)
	return result


## One of 8 directions from the fighter toward the cursor (angle rounded to 45°).
## `cursor` is in cell units (1.0 = one cell). Returns ZERO when the cursor is
## on the fighter's own cell.
static func flame_direction(origin: Vector2i, cursor: Vector2) -> Vector2i:
	if Vector2i(cursor.floor()) == origin:
		return Vector2i.ZERO
	var offset := cursor - (Vector2(origin) + Vector2(0.5, 0.5))
	var angle := roundi(offset.angle() / (PI / 4.0)) * (PI / 4.0)
	return Vector2i(roundi(cos(angle)), roundi(sin(angle)))


static func flame_cells(state: GameState, direction: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if direction == Vector2i.ZERO:
		return result
	for step in range(1, FLAME_LENGTH + 1):
		var cell := state.player + direction * step
		if not GameState.in_bounds(cell):
			break
		result.append(cell)
	return result


## 3×3 area around `center`, clipped to the board. Empty if the center is out of range.
static func grenade_cells(state: GameState, center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not GameState.in_bounds(center) or not in_range(state, center):
		return result
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := center + Vector2i(dx, dy)
			if GameState.in_bounds(cell):
				result.append(cell)
	return result


## Cells the action would affect when clicked at `cell` / `cursor` (cursor in cell
## units, used by the flamethrower). Empty array = the click is not a valid action.
static func target_cells(state: GameState, action: int, cell: Vector2i, cursor: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match action:
		Action.MOVE:
			if move_targets(state).has(cell):
				result.append(cell)
		Action.PISTOL, Action.MACHINE_GUN:
			if shoot_targets(state, action).has(cell):
				result.append(cell)
		Action.FLAMETHROWER:
			result = flame_cells(state, flame_direction(state.player, cursor))
		Action.GRENADE:
			result = grenade_cells(state, cell)
	return result


## Performs the player's action. Returns the number of killed trifids,
## or INVALID when the action cannot be done (state stays unchanged).
static func perform(state: GameState, action: int, cell: Vector2i, cursor: Vector2 = Vector2.ZERO) -> int:
	if not can_use(state, action):
		return INVALID
	var cells := target_cells(state, action, cell, cursor)
	if cells.is_empty():
		return INVALID
	var killed := 0
	match action:
		Action.MOVE:
			state.player = cell
		Action.PISTOL:
			state.set_count(cell, state.get_count(cell) - 1)
			killed = 1
		_:
			for target in cells:
				killed += state.get_count(target)
				state.set_count(target, 0)
	var key := ammo_key(action)
	if key != "":
		state.ammo[key] = state.get_ammo(key) - 1
	state.kills += killed
	return killed


## Trifid turn (GAME_DESIGN.md, chapter 6). Returns true when a trifid reaches
## the fighter's cell (= player lost).
static func trifid_turn(state: GameState, rng: RandomNumberGenerator) -> bool:
	# 1. Double all occupied cells at once, cap at 9 and remember the overflow.
	var overflow := {}
	for cell in GameState.all_cells():
		var count := state.get_count(cell)
		if count == 0:
			continue
		var doubled := count * 2
		if doubled > GameState.MAX_COUNT:
			overflow[cell] = doubled - GameState.MAX_COUNT
		state.set_count(cell, doubled)
	# 2. Spread the overflow one trifid at a time to random neighbors with room.
	#    Cells are processed row by row; newly reached cells are not doubled again.
	for cell: Vector2i in overflow:
		var remaining: int = overflow[cell]
		while remaining > 0:
			var options: Array[Vector2i] = []
			for neighbor in neighbors(cell):
				if state.get_count(neighbor) < GameState.MAX_COUNT:
					options.append(neighbor)
			if options.is_empty():
				break  # No room around: the rest of the overflow is lost.
			var target := options[rng.randi_range(0, options.size() - 1)]
			state.set_count(target, state.get_count(target) + 1)
			remaining -= 1
			if target == state.player:
				return true
	# 3. Overcrowding: every full cell whose neighbors are all full dies out.
	#    Evaluated at once, so a whole block of full cells disappears together.
	var overcrowded: Array[Vector2i] = []
	for cell in GameState.all_cells():
		if state.get_count(cell) == GameState.MAX_COUNT and _all_neighbors_full(state, cell):
			overcrowded.append(cell)
	for cell in overcrowded:
		state.set_count(cell, 0)
	state.turn += 1
	return false


static func _all_neighbors_full(state: GameState, cell: Vector2i) -> bool:
	for neighbor in neighbors(cell):
		if state.get_count(neighbor) < GameState.MAX_COUNT:
			return false
	return true


static func is_won(state: GameState) -> bool:
	return state.total_trifids() == 0
