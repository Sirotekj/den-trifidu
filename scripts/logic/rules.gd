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
## Machine gun line: number of steps along the main axis.
const MACHINE_GUN_LENGTH := 4
## Flamethrower sector: full angle in degrees, radius in cells, samples per cell side.
const FLAME_ANGLE := 30.0
const FLAME_RADIUS := 4.0
const FLAME_SAMPLES := 6
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


## Range of the action in cells (pistol 5, grenade 4).
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


## Cells within pistol range that contain trifids (valid pistol targets).
static func pistol_targets(state: GameState) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in range_cells(state, PISTOL_RANGE):
		if state.get_count(cell) > 0:
			result.append(cell)
	return result


## Center of the fighter's cell in cell units (1.0 = one cell).
static func fighter_center(state: GameState) -> Vector2:
	return Vector2(state.player) + Vector2(0.5, 0.5)


## Aiming vector from the fighter's center to the cursor (cell units).
## ZERO when the cursor is on the fighter's own cell (= no aim).
static func aim_vector(state: GameState, cursor: Vector2) -> Vector2:
	if Vector2i(cursor.floor()) == state.player:
		return Vector2.ZERO
	return cursor - fighter_center(state)


## Machine gun line toward the cursor: the ray from the fighter's center is stepped
## one cell at a time along its main axis; each step hits the cell the ray is in.
static func machine_gun_cells(state: GameState, cursor: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var aim := aim_vector(state, cursor)
	if aim == Vector2.ZERO:
		return result
	var step := aim / maxf(absf(aim.x), absf(aim.y))
	var center := fighter_center(state)
	for i in range(1, MACHINE_GUN_LENGTH + 1):
		var cell := Vector2i((center + step * i).floor())
		if not GameState.in_bounds(cell):
			break
		result.append(cell)
	return result


## Flamethrower sector toward the cursor: FLAME_ANGLE wide, FLAME_RADIUS long.
## A cell is hit when at least one of its sample points lies inside the sector.
static func flame_cells(state: GameState, cursor: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var aim := aim_vector(state, cursor)
	if aim == Vector2.ZERO:
		return result
	var center := fighter_center(state)
	for cell in GameState.all_cells():
		if cell != state.player and _cell_in_sector(cell, center, aim.angle()):
			result.append(cell)
	return result


static func _cell_in_sector(cell: Vector2i, center: Vector2, axis: float) -> bool:
	var half_angle := deg_to_rad(FLAME_ANGLE / 2.0)
	for sy in FLAME_SAMPLES:
		for sx in FLAME_SAMPLES:
			var point := Vector2(cell) + Vector2(sx + 0.5, sy + 0.5) / FLAME_SAMPLES
			var offset := point - center
			if offset.length() > FLAME_RADIUS:
				continue
			if absf(angle_difference(axis, offset.angle())) <= half_angle:
				return true
	return false


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
## units, used for aiming the machine gun and the flamethrower).
## Empty array = the click is not a valid action.
static func target_cells(state: GameState, action: int, cell: Vector2i, cursor: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match action:
		Action.MOVE:
			if move_targets(state).has(cell):
				result.append(cell)
		Action.PISTOL:
			if pistol_targets(state).has(cell):
				result.append(cell)
		Action.MACHINE_GUN:
			result = machine_gun_cells(state, cursor)
		Action.FLAMETHROWER:
			result = flame_cells(state, cursor)
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
