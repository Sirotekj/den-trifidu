extends CanvasLayer
## Autoload "App": switches screens with a fade through black and passes data
## between them (what the game should play, which level the editor is editing).

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const EDITOR_SCENE := "res://scenes/editor/editor.tscn"
const FADE_TIME := 0.35

const SOURCE_CAMPAIGN := "campaign"
const SOURCE_CUSTOM := "custom"
const SOURCE_EDITOR := "editor"

## What the game screen plays: {"state": GameState, "start": GameState, "source": Dictionary}.
## `source` is {"type": "campaign", "level": N}, {"type": "custom", "path": ...}
## or {"type": "editor"} (test play from the editor).
var game_request: Dictionary = {}

## Level open in the editor; kept while test playing so the editor comes back unchanged.
var editor_state: GameState = null
## File of the level open in the editor: own level path, or "" when not saved yet.
var editor_custom_path: String = ""
## Campaign number of the level open in the editor, 0 when it is not a campaign level.
var editor_campaign_number: int = 0

var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale("cs")
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fade)
	# The program starts black and the first screen fades in.
	_fade_to(0.0)


func go_to_menu() -> void:
	change_screen(MENU_SCENE)


func open_editor() -> void:
	change_screen(EDITOR_SCENE)


func start_campaign(level: int) -> void:
	_play(LevelLoader.load_level(level), {"type": SOURCE_CAMPAIGN, "level": level})


func continue_saved() -> void:
	var saved := SaveGame.load_game()
	if saved.is_empty():
		return
	game_request = saved
	change_screen(GAME_SCENE)


## Test play of the level being edited (it does not have to be saved).
func play_from_editor(state: GameState) -> void:
	_play(state.duplicate_state(), {"type": SOURCE_EDITOR})


func change_screen(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func _play(state: GameState, source: Dictionary) -> void:
	game_request = {
		"state": state,
		"start": state.duplicate_state() if state != null else null,
		"source": source,
	}
	change_screen(GAME_SCENE)


func _fade_to(alpha: float) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
	if alpha == 0.0:
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
