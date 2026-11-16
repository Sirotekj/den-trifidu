extends Control
## Level editor screen (GAME_DESIGN.md, chapter 11). The edited level lives in
## App.editor_state, so it survives a test play in the game screen.

enum Tool { FIGHTER, TRIFID, ERASER }

@onready var _board: BoardView = $Board
@onready var _menu_button: Button = $MenuButton
@onready var _fighter_tool: Button = $Panel/Tools/FighterTool
@onready var _trifid_tool: Button = $Panel/Tools/TrifidTool
@onready var _eraser_tool: Button = $Panel/Tools/EraserTool
@onready var _count_value: Label = $Panel/CountRow/Value
@onready var _count_minus: Button = $Panel/CountRow/Minus
@onready var _count_plus: Button = $Panel/CountRow/Plus
@onready var _ammo_rows: Dictionary = {
	GameState.AMMO_MACHINE_GUN: $Panel/MachineGunRow,
	GameState.AMMO_FLAMETHROWER: $Panel/FlamethrowerRow,
	GameState.AMMO_GRENADE: $Panel/GrenadeRow,
}
@onready var _name_edit: LineEdit = $Panel/NameEdit
@onready var _new_button: Button = $Panel/Buttons/NewButton
@onready var _load_button: Button = $Panel/Buttons/LoadButton
@onready var _save_button: Button = $Panel/Buttons/SaveButton
@onready var _play_button: Button = $Panel/Buttons/PlayButton
@onready var _save_campaign_button: Button = $Panel/SaveCampaignButton
@onready var _status: Label = $Panel/Status
@onready var _overlay: Control = $Overlay
@onready var _level_list: VBoxContainer = $Overlay/Dialog/Box/Scroll/LevelList
@onready var _cancel_button: Button = $Overlay/Dialog/Box/CancelButton

var _state: GameState
var _tool: int = Tool.TRIFID
var _count: int = 1


func _ready() -> void:
	if App.editor_state == null:
		_reset_to_new_level()
	_state = App.editor_state

	_fighter_tool.pressed.connect(_select_tool.bind(Tool.FIGHTER))
	_trifid_tool.pressed.connect(_select_tool.bind(Tool.TRIFID))
	_eraser_tool.pressed.connect(_select_tool.bind(Tool.ERASER))
	_count_minus.pressed.connect(_change_count.bind(-1))
	_count_plus.pressed.connect(_change_count.bind(1))
	for key: String in _ammo_rows:
		var row: Control = _ammo_rows[key]
		row.get_node("Minus").pressed.connect(_change_ammo.bind(key, -1))
		row.get_node("Plus").pressed.connect(_change_ammo.bind(key, 1))
	_name_edit.text = _state.level_name
	_name_edit.text_changed.connect(_on_name_changed)
	_board.cell_clicked.connect(_on_cell_clicked)
	_board.cell_right_clicked.connect(_on_cell_right_clicked)
	_menu_button.pressed.connect(App.go_to_menu)
	_new_button.pressed.connect(_on_new_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_save_campaign_button.pressed.connect(_on_save_campaign_pressed)
	_save_campaign_button.visible = OS.has_feature("editor")
	_cancel_button.pressed.connect(_overlay.hide)
	_overlay.hide()
	_set_status("")
	_refresh()


func _reset_to_new_level() -> void:
	App.editor_state = EditorRules.new_level()
	App.editor_custom_path = ""
	App.editor_campaign_number = 0


func _refresh() -> void:
	_board.state = _state
	_board.action = Rules.NONE
	_board.interactive = true
	_board.queue_redraw()
	_fighter_tool.set_pressed_no_signal(_tool == Tool.FIGHTER)
	_trifid_tool.set_pressed_no_signal(_tool == Tool.TRIFID)
	_eraser_tool.set_pressed_no_signal(_tool == Tool.ERASER)
	_count_value.text = str(_count)
	for key: String in _ammo_rows:
		var row: Control = _ammo_rows[key]
		var value: Label = row.get_node("Value")
		value.text = str(_state.get_ammo(key))


func _set_status(text: String) -> void:
	_status.text = text


func _select_tool(tool: int) -> void:
	_tool = tool
	_refresh()


func _change_count(delta: int) -> void:
	_count = clampi(_count + delta, 1, GameState.MAX_COUNT)
	_tool = Tool.TRIFID
	_refresh()


func _change_ammo(key: String, delta: int) -> void:
	EditorRules.set_ammo(_state, key, _state.get_ammo(key) + delta)
	_refresh()


func _on_name_changed(text: String) -> void:
	_state.level_name = text


func _on_cell_clicked(cell: Vector2i, _cursor: Vector2) -> void:
	match _tool:
		Tool.FIGHTER:
			EditorRules.place_player(_state, cell)
		Tool.TRIFID:
			EditorRules.place_trifids(_state, cell, _count)
		Tool.ERASER:
			EditorRules.erase(_state, cell)
	_refresh()


func _on_cell_right_clicked(cell: Vector2i) -> void:
	EditorRules.erase(_state, cell)
	_refresh()


func _on_new_pressed() -> void:
	_reset_to_new_level()
	_state = App.editor_state
	_name_edit.text = ""
	_set_status("")
	_refresh()


func _on_save_pressed() -> void:
	_state.level_name = _name_edit.text.strip_edges()
	var error := EditorRules.check(_state, true)
	if error != "":
		_set_status(tr(error))
		return
	var path := LevelLoader.save_custom(_state.to_level_dict(), App.editor_custom_path)
	if path == "":
		_set_status(tr("EDITOR_ERR_WRITE"))
		return
	App.editor_custom_path = path
	_set_status(tr("EDITOR_SAVED") % _state.level_name)


func _on_save_campaign_pressed() -> void:
	var error := EditorRules.check(_state, false)
	if error != "":
		_set_status(tr(error))
		return
	var number := App.editor_campaign_number
	if number <= 0:
		number = LevelLoader.next_campaign_number()
	if _state.level_name.strip_edges() == "":
		_state.level_name = tr("LEVEL_TITLE") % number
		_name_edit.text = _state.level_name
	if LevelLoader.save_campaign(_state.to_level_dict(), number) != OK:
		_set_status(tr("EDITOR_ERR_WRITE"))
		return
	App.editor_campaign_number = number
	_set_status(tr("EDITOR_SAVED_CAMPAIGN") % number)


func _on_play_pressed() -> void:
	var error := EditorRules.check(_state, false)
	if error != "":
		_set_status(tr(error))
		return
	App.play_from_editor(_state)


func _on_load_pressed() -> void:
	for child in _level_list.get_children():
		child.queue_free()
	for number in LevelLoader.campaign_numbers():
		var path := LevelLoader.level_path(number)
		_add_level_button(tr("EDITOR_CAMPAIGN_ITEM") % [number, LevelLoader.read_name(path)],
			path, number, "")
	for path in LevelLoader.list_custom():
		var level_name := LevelLoader.read_name(path)
		if level_name == "":
			level_name = path.get_file().get_basename()
		_add_level_button(tr("EDITOR_CUSTOM_ITEM") % level_name, path, 0, path)
	if _level_list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "EDITOR_NO_LEVELS"
		_level_list.add_child(empty)
	_overlay.show()


func _add_level_button(text: String, path: String, campaign_number: int, custom_path: String) -> void:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_load_level.bind(path, campaign_number, custom_path))
	_level_list.add_child(button)


func _load_level(path: String, campaign_number: int, custom_path: String) -> void:
	_overlay.hide()
	var loaded := LevelLoader.load_from_path(path)
	if loaded == null:
		_set_status(tr("EDITOR_ERR_INVALID"))
		return
	App.editor_state = loaded
	App.editor_custom_path = custom_path
	App.editor_campaign_number = campaign_number
	_state = loaded
	_name_edit.text = loaded.level_name
	_set_status(tr("EDITOR_LOADED") % loaded.level_name)
	_refresh()
