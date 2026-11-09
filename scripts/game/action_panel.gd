class_name ActionPanel
extends VBoxContainer
## The 5 action cards on the right side; shows remaining ammo and the selected card.

signal action_selected(action: int)

const LABEL_KEYS := {
	Rules.Action.MOVE: "ACTION_MOVE",
	Rules.Action.PISTOL: "ACTION_PISTOL",
	Rules.Action.MACHINE_GUN: "ACTION_MACHINE_GUN",
	Rules.Action.FLAMETHROWER: "ACTION_FLAMETHROWER",
	Rules.Action.GRENADE: "ACTION_GRENADE",
}
const FONT_SIZE := 20
const CARD_HEIGHT := 60.0
const UNLIMITED_TEXT := "∞"

var _buttons: Dictionary = {}  # action -> Button
var _counts: Dictionary = {}  # action -> Label with remaining uses


func _ready() -> void:
	for action in Rules.ACTIONS:
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, CARD_HEIGHT)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = LABEL_KEYS[action]
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_on_button_pressed.bind(action))

		var count := Label.new()
		count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size", FONT_SIZE)
		button.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		count.offset_right = -14.0

		add_child(button)
		_buttons[action] = button
		_counts[action] = count


func refresh(state: GameState, selected: int, enabled: bool) -> void:
	for action: int in _buttons:
		var button: Button = _buttons[action]
		button.disabled = not enabled or not Rules.can_use(state, action)
		button.set_pressed_no_signal(action == selected)
		var count: Label = _counts[action]
		count.text = _count_text(state, action)


func _count_text(state: GameState, action: int) -> String:
	if action == Rules.Action.MOVE:
		return ""
	var key := Rules.ammo_key(action)
	if key == "":
		return UNLIMITED_TEXT
	return str(state.get_ammo(key))


func _on_button_pressed(action: int) -> void:
	action_selected.emit(action)
