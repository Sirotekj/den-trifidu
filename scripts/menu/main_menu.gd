extends Control
## Main menu: New game | Continue | About | Editor | Quit (GAME_DESIGN.md, chapter 8).

@onready var _new_game_button: Button = $Buttons/NewGameButton
@onready var _continue_button: Button = $Buttons/ContinueButton
@onready var _about_button: Button = $Buttons/AboutButton
@onready var _editor_button: Button = $Buttons/EditorButton
@onready var _exit_button: Button = $Buttons/ExitButton


func _ready() -> void:
	_continue_button.disabled = not SaveGame.exists()
	_about_button.disabled = true  # "About" is added later.
	_new_game_button.pressed.connect(App.start_campaign.bind(1))
	_continue_button.pressed.connect(App.continue_saved)
	_editor_button.pressed.connect(App.open_editor)
	_exit_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	get_tree().quit()
