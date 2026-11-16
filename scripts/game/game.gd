extends Control
## Game screen: connects the action panel and the board to the rules and runs the turn loop
## (player action → win check → trifid turn → loss check). What to play comes from
## the App autoload (campaign level, saved game or a level from the editor).

enum Dialog { MENU, LEVEL_WON, GAME_WON, LOST, LEVEL_ERROR }

const DIALOG_MESSAGES := {
	Dialog.MENU: "MSG_MENU",
	Dialog.LEVEL_WON: "MSG_LEVEL_WON",
	Dialog.GAME_WON: "MSG_GAME_WON",
	Dialog.LOST: "MSG_LOST",
	Dialog.LEVEL_ERROR: "MSG_LEVEL_ERROR",
}
const FIRST_LEVEL := 1

@onready var _title: Label = $Title
@onready var _menu_button: Button = $MenuButton
@onready var _board: BoardView = $Board
@onready var _panel: ActionPanel = $ActionPanel
@onready var _kills_label: Label = $KillsLabel
@onready var _turn_label: Label = $TurnLabel
@onready var _overlay: Control = $Overlay
@onready var _message: Label = $Overlay/Dialog/Box/Message
@onready var _continue_button: Button = $Overlay/Dialog/Box/ContinueButton
@onready var _save_button: Button = $Overlay/Dialog/Box/SaveButton
@onready var _next_button: Button = $Overlay/Dialog/Box/NextButton
@onready var _restart_button: Button = $Overlay/Dialog/Box/RestartButton
@onready var _quit_button: Button = $Overlay/Dialog/Box/QuitButton

var _state: GameState = GameState.new()
## The level as it was at its start, for "play again".
var _start: GameState = null
var _source: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _selected: int = Rules.NONE
var _game_over: bool = false
var _dialog: int = Dialog.MENU


func _ready() -> void:
	_rng.randomize()
	_panel.action_selected.connect(_on_action_selected)
	_board.cell_clicked.connect(_on_cell_clicked)
	_menu_button.pressed.connect(_show_dialog.bind(Dialog.MENU))
	_continue_button.pressed.connect(_hide_dialog)
	_save_button.pressed.connect(_on_save_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	var request: Dictionary = App.game_request
	if request.is_empty():
		# Scene started directly from the Godot editor: play the first campaign level.
		var first := LevelLoader.load_level(FIRST_LEVEL)
		request = {"state": first, "start": first.duplicate_state() if first != null else null,
			"source": {"type": App.SOURCE_CAMPAIGN, "level": FIRST_LEVEL}}
	_source = request["source"]
	_start = request["start"]
	_begin(request["state"])


func _begin(state: GameState) -> void:
	_selected = Rules.NONE
	_game_over = false
	_hide_dialog()
	if state == null:
		_state = GameState.new()
		_end_game(Dialog.LEVEL_ERROR)
	else:
		_state = state
	_refresh()


func _campaign_level() -> int:
	if _source.get("type") == App.SOURCE_CAMPAIGN:
		return int(_source.get("level", 0))
	return 0


func _on_action_selected(action: int) -> void:
	if _game_over or not Rules.can_use(_state, action):
		return
	_selected = action
	_refresh()


func _on_cell_clicked(cell: Vector2i, cursor: Vector2) -> void:
	if _game_over or _overlay.visible or _selected == Rules.NONE:
		return
	if Rules.perform(_state, _selected, cell, cursor) == Rules.INVALID:
		return
	if Rules.is_won(_state):
		var level := _campaign_level()
		var has_next := level > 0 and LevelLoader.level_exists(level + 1)
		_end_game(Dialog.LEVEL_WON if has_next else Dialog.GAME_WON)
	elif Rules.trifid_turn(_state, _rng):
		_end_game(Dialog.LOST)
	elif not Rules.can_use(_state, _selected):
		_selected = Rules.NONE
	_refresh()


func _end_game(dialog: int) -> void:
	_game_over = true
	_selected = Rules.NONE
	_show_dialog(dialog)


func _refresh() -> void:
	var level := _campaign_level()
	if level > 0:
		_title.text = tr("LEVEL_TITLE") % level
	elif _state.level_name.strip_edges() != "":
		_title.text = _state.level_name
	else:
		_title.text = tr("EDITOR_UNTITLED")
	_kills_label.text = tr("KILLS") % _state.kills
	_turn_label.text = tr("TURN") % _state.turn
	_board.state = _state
	_board.action = _selected
	_board.interactive = not _game_over
	_board.queue_redraw()
	_panel.refresh(_state, _selected, not _game_over)


func _show_dialog(dialog: int) -> void:
	_dialog = dialog
	_message.text = tr(DIALOG_MESSAGES[dialog])
	_continue_button.visible = dialog == Dialog.MENU
	_save_button.visible = dialog == Dialog.MENU
	_next_button.visible = dialog == Dialog.LEVEL_WON
	_restart_button.visible = _start != null
	_overlay.visible = true


func _hide_dialog() -> void:
	_overlay.visible = false


func _on_save_pressed() -> void:
	var error := SaveGame.save(_state, _start, _source)
	_message.text = tr("MSG_SAVED") if error == OK else tr("MSG_SAVE_FAILED")


func _on_next_pressed() -> void:
	App.start_campaign(_campaign_level() + 1)


func _on_restart_pressed() -> void:
	var level := _campaign_level()
	if _dialog == Dialog.GAME_WON and level > 0:
		App.start_campaign(FIRST_LEVEL)
	elif _start != null:
		_begin(_start.duplicate_state())


func _on_quit_pressed() -> void:
	if _source.get("type") == App.SOURCE_EDITOR:
		App.open_editor()
	else:
		App.go_to_menu()
