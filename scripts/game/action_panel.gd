class_name ActionPanel
extends VBoxContainer
## The 5 action cards on the right side; shows remaining ammo and the selected card.
## Each card is a toggle Button (theme variation "CardButton") with an icon, a name and
## the remaining count drawn on top.

signal action_selected(action: int)

const LABEL_KEYS := {
	Rules.Action.MOVE: "ACTION_MOVE",
	Rules.Action.PISTOL: "ACTION_PISTOL",
	Rules.Action.MACHINE_GUN: "ACTION_MACHINE_GUN",
	Rules.Action.FLAMETHROWER: "ACTION_FLAMETHROWER",
	Rules.Action.GRENADE: "ACTION_GRENADE",
}
const ICONS := {
	Rules.Action.MOVE: "res://assets/graphics/icons/icon_move.png",
	Rules.Action.PISTOL: "res://assets/graphics/icons/icon_pistol.png",
	Rules.Action.MACHINE_GUN: "res://assets/graphics/icons/icon_machine_gun.png",
	Rules.Action.FLAMETHROWER: "res://assets/graphics/icons/icon_flamethrower.png",
	Rules.Action.GRENADE: "res://assets/graphics/icons/icon_grenade.png",
}
const NAME_FONT_SIZE := 17
const COUNT_FONT_SIZE := 26
const CARD_HEIGHT := 60.0
## Area of the card used by the icon (left part), in pixels.
const ICON_WIDTH := 92.0
const ICON_MARGIN := 7.0
const COUNT_WIDTH := 44.0
const UNLIMITED_TEXT := "∞"
const HIGHLIGHT_COLOR := Color(0.98, 0.78, 0.25, 0.45)
const HIGHLIGHT_BORDER_COLOR := Color(0.75, 0.25, 0.05, 0.9)
## Whole card (frame, icon, texts) when the action cannot be used.
const DISABLED_MODULATE := Color(1, 1, 1, 0.3)

var _buttons: Dictionary = {}  # action -> Button
var _counts: Dictionary = {}  # action -> Label with remaining uses
var _highlights: Dictionary = {}  # action -> Panel shown on the selected card


func _ready() -> void:
	for action in Rules.ACTIONS:
		var button := Button.new()
		button.theme_type_variation = &"CardButton"
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, CARD_HEIGHT)
		button.pressed.connect(_on_button_pressed.bind(action))

		var highlight := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = HIGHLIGHT_COLOR
		style.border_color = HIGHLIGHT_BORDER_COLOR
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		highlight.add_theme_stylebox_override("panel", style)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.visible = false
		_add_filling(button, highlight, Vector4(8, 6, -8, -6))

		var icon_path: String = ICONS[action]
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_add_filling(button, icon, Vector4(ICON_MARGIN + 4, ICON_MARGIN, 0, -ICON_MARGIN))
			icon.anchor_right = 0.0
			icon.offset_right = ICON_WIDTH

		var title := Label.new()
		title.text = LABEL_KEYS[action]
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		title.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
		_add_filling(button, title, Vector4(ICON_WIDTH, 5, -24, -4))

		var count := Label.new()
		count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
		_add_filling(button, count, Vector4(0, 20, -14, -2))
		count.anchor_left = 1.0
		count.offset_left = -COUNT_WIDTH - 14

		add_child(button)
		_buttons[action] = button
		_counts[action] = count
		_highlights[action] = highlight


func refresh(state: GameState, selected: int, enabled: bool) -> void:
	for action: int in _buttons:
		var button: Button = _buttons[action]
		button.disabled = not enabled or not Rules.can_use(state, action)
		button.set_pressed_no_signal(action == selected)
		button.modulate = DISABLED_MODULATE if button.disabled else Color.WHITE
		_highlights[action].visible = action == selected
		var count: Label = _counts[action]
		count.text = _count_text(state, action)


## Adds `child` stretched over the whole card, shrunk by offsets (left, top, right, bottom).
func _add_filling(card: Control, child: Control, offsets: Vector4) -> void:
	card.add_child(child)
	child.set_anchors_preset(Control.PRESET_FULL_RECT)
	child.offset_left = offsets.x
	child.offset_top = offsets.y
	child.offset_right = offsets.z
	child.offset_bottom = offsets.w


func _count_text(state: GameState, action: int) -> String:
	if action == Rules.Action.MOVE:
		return ""
	var key := Rules.ammo_key(action)
	if key == "":
		return UNLIMITED_TEXT
	return str(state.get_ammo(key))


func _on_button_pressed(action: int) -> void:
	action_selected.emit(action)
