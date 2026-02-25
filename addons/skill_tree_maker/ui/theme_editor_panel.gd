@tool
class_name ThemeEditorPanel
extends VBoxContainer

## テーマデータを視覚的に編集するパネル
##
## ThemeResolver を bind して theme.json の各セクションを編集できる。
## Background, Window, Node Preset, Edge Preset の各セクションを提供する。


# --- Signals ---

## テーマデータが変更されたとき
signal theme_changed(theme_data: Dictionary)


# --- Constants ---

## SpinBox の最小ノードサイズ
const NODE_SIZE_MIN: float = 16.0

## SpinBox の最大ノードサイズ
const NODE_SIZE_MAX: float = 128.0

## SpinBox の最小エッジ幅
const EDGE_WIDTH_MIN: float = 1.0

## SpinBox の最大エッジ幅
const EDGE_WIDTH_MAX: float = 16.0

## SpinBox の最小パディング
const PADDING_MIN: float = 0.0

## SpinBox の最大パディング
const PADDING_MAX: float = 256.0

## ラベル幅の比率（行全体に対するラベルの割合）
const LABEL_WIDTH_RATIO: float = 0.4

## 値コントロール幅の比率（1.0 - LABEL_WIDTH_RATIO）
const VALUE_WIDTH_RATIO: float = 1.0 - LABEL_WIDTH_RATIO

## セクションラベルの文字色
const SECTION_LABEL_COLOR: Color = Color(0.6, 0.8, 1.0, 1.0)


# --- Private Variables ---

## バインドされた ThemeResolver
var _theme_resolver: ThemeResolver = null

## プロパティ行を格納する VBoxContainer
var _properties_container: VBoxContainer = null


# --- Built-in Functions ---

## パネル初期化
func _ready() -> void:
	_build_ui()


# --- Public Functions ---

## ThemeResolver をバインドして UI を構築する
##
## resolver が null でもクラッシュしない。
## バインド後にテーマデータから UI を再構築する。
##
## @param resolver: テーマリゾルバ (ThemeResolver)、null 許容
func bind_theme_resolver(resolver: ThemeResolver) -> void:
	_theme_resolver = resolver
	rebuild_ui()


## UI をテーマデータから再構築する
##
## _properties_container の子を全てクリアし、
## ThemeResolver のデータに基づいて各セクションを構築する。
func rebuild_ui() -> void:
	_clear_properties()

	if _theme_resolver == null or not _theme_resolver.is_loaded():
		return

	var theme_data: Dictionary = _theme_resolver.get_theme_data()

	_build_background_section(theme_data)
	_build_window_section(theme_data)
	_build_node_preset_section(theme_data)
	_build_edge_preset_section(theme_data)


# --- Private Functions ---

## UI 要素を構築する（_properties_container を生成して add_child する）
##
## @return: なし（void）
func _build_ui() -> void:
	_properties_container = VBoxContainer.new()
	_properties_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_properties_container)


## プロパティコンテナの全子ノードを削除する
func _clear_properties() -> void:
	if _properties_container == null:
		return
	for child: Node in _properties_container.get_children():
		_properties_container.remove_child(child)
		child.queue_free()


## Background セクションを構築する
##
## @param theme_data: テーマデータ辞書 (Dictionary)
func _build_background_section(theme_data: Dictionary) -> void:
	# theme_data は ThemeResolver.get_theme_data() の参照渡し。
	# キーが欠損している場合はここで補完し、インメモリのテーマデータを直接更新する。
	if not theme_data.has("background"):
		theme_data["background"] = {}
	var bg: Dictionary = theme_data["background"]

	_properties_container.add_child(_create_section_label("--- Background ---"))

	# tint (ColorPickerButton)
	var tint_str: String = bg.get("tint", ThemeData.DEFAULT_BG_TINT)
	var tint_picker: ColorPickerButton = ColorPickerButton.new()
	tint_picker.custom_minimum_size.x = 60
	tint_picker.color = Color.from_string(tint_str, Color.from_string(ThemeData.DEFAULT_BG_TINT, Color.WHITE))
	tint_picker.color_changed.connect(func(new_color: Color) -> void:
		bg["tint"] = "#" + new_color.to_html(false)
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Tint", tint_picker))

	# texture (LineEdit)
	var tex_edit: LineEdit = LineEdit.new()
	tex_edit.text = bg.get("texture", "")
	tex_edit.placeholder_text = "textures/bg.png"
	tex_edit.text_changed.connect(func(new_text: String) -> void:
		bg["texture"] = new_text
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Texture", tex_edit))

	# parallax (CheckBox)
	if not bg.has("parallax"):
		bg["parallax"] = {"enabled": false}
	var parallax: Dictionary = bg["parallax"]
	var parallax_check: CheckBox = CheckBox.new()
	parallax_check.button_pressed = parallax.get("enabled", false)
	parallax_check.toggled.connect(func(pressed: bool) -> void:
		parallax["enabled"] = pressed
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Parallax", parallax_check))


## Window セクションを構築する
##
## @param theme_data: テーマデータ辞書 (Dictionary)
func _build_window_section(theme_data: Dictionary) -> void:
	if not theme_data.has("window"):
		theme_data["window"] = {}
	var win: Dictionary = theme_data["window"]
	if not win.has("padding"):
		win["padding"] = {
			"l": ThemeData.DEFAULT_PADDING,
			"t": ThemeData.DEFAULT_PADDING,
			"r": ThemeData.DEFAULT_PADDING,
			"b": ThemeData.DEFAULT_PADDING
		}
	var padding: Dictionary = win["padding"]

	_properties_container.add_child(_create_section_label("--- Window ---"))

	# frame_9slice (LineEdit)
	var frame_edit: LineEdit = LineEdit.new()
	frame_edit.text = win.get("frame_9slice", "")
	frame_edit.placeholder_text = "textures/frame.png"
	frame_edit.text_changed.connect(func(new_text: String) -> void:
		win["frame_9slice"] = new_text
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Frame 9Slice", frame_edit))

	# padding l/t/r/b (SpinBox x4)
	for side: String in ["l", "t", "r", "b"]:
		var spin: SpinBox = SpinBox.new()
		spin.min_value = PADDING_MIN
		spin.max_value = PADDING_MAX
		spin.step = 1.0
		spin.value = padding.get(side, ThemeData.DEFAULT_PADDING)
		var captured_side: String = side
		spin.value_changed.connect(func(new_val: float) -> void:
			padding[captured_side] = int(new_val)
			_apply_to_theme_data()
		)
		_properties_container.add_child(
			_create_property_row("Padding " + side.to_upper(), spin))


## Node Preset セクション（node_default）を構築する
##
## @param theme_data: テーマデータ辞書 (Dictionary)
func _build_node_preset_section(theme_data: Dictionary) -> void:
	if not theme_data.has("node_presets"):
		theme_data["node_presets"] = {}
	var presets: Dictionary = theme_data["node_presets"]

	if not presets.has(ThemeData.DEFAULT_NODE_PRESET_KEY):
		return

	var preset: Dictionary = presets[ThemeData.DEFAULT_NODE_PRESET_KEY]

	_properties_container.add_child(
		_create_section_label("--- Node Preset: " + ThemeData.DEFAULT_NODE_PRESET_KEY + " ---"))

	# base_texture (LineEdit)
	var base_tex_edit: LineEdit = LineEdit.new()
	base_tex_edit.text = preset.get("base_texture", "")
	base_tex_edit.placeholder_text = "textures/node.png"
	base_tex_edit.text_changed.connect(func(new_text: String) -> void:
		preset["base_texture"] = new_text
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Base Texture", base_tex_edit))

	# size (SpinBox 16-128)
	var size_spin: SpinBox = SpinBox.new()
	size_spin.min_value = NODE_SIZE_MIN
	size_spin.max_value = NODE_SIZE_MAX
	size_spin.step = 1.0
	size_spin.value = preset.get("size", ThemeData.DEFAULT_NODE_SIZE)
	size_spin.value_changed.connect(func(new_val: float) -> void:
		preset["size"] = int(new_val)
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Size", size_spin))

	# 各ステート: locked / can_unlock / unlocked
	if not preset.has("states"):
		preset["states"] = {}
	var states: Dictionary = preset["states"]

	_build_node_state_ui(states, "locked")
	_build_node_state_ui(states, "can_unlock")
	_build_node_state_ui(states, "unlocked")


## ノードプリセットの各ステート UI を構築する
##
## @param states: ステート辞書 (Dictionary)
## @param state_key: ステートキー ("locked", "can_unlock", "unlocked") (String)
func _build_node_state_ui(states: Dictionary, state_key: String) -> void:
	if not states.has(state_key):
		states[state_key] = {"overlay": "", "glow": false}
	var state: Dictionary = states[state_key]

	_properties_container.add_child(_create_section_label("  [" + state_key + "]"))

	# glow (CheckBox)
	var glow_check: CheckBox = CheckBox.new()
	glow_check.button_pressed = state.get("glow", false)
	glow_check.toggled.connect(func(pressed: bool) -> void:
		state["glow"] = pressed
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Glow", glow_check))

	# glow_color (ColorPickerButton) -- can_unlock / unlocked のみ
	# locked ステートは仕様上 glow_color を持たない（常に非発光のため設定不要）
	if state_key != "locked":
		var default_glow: String = ThemeData.DEFAULT_GLOW_COLOR_UNLOCK if state_key == "can_unlock" else ThemeData.DEFAULT_GLOW_COLOR_UNLOCKED
		var glow_color_str: String = state.get("glow_color", default_glow)
		var glow_picker: ColorPickerButton = ColorPickerButton.new()
		glow_picker.custom_minimum_size.x = 60
		glow_picker.color = Color.from_string(glow_color_str, Color.from_string(default_glow, Color.WHITE))
		glow_picker.color_changed.connect(func(new_color: Color) -> void:
			state["glow_color"] = "#" + new_color.to_html(false)
			_apply_to_theme_data()
		)
		_properties_container.add_child(_create_property_row("Glow Color", glow_picker))


## Edge Preset セクション（edge_default）を構築する
##
## @param theme_data: テーマデータ辞書 (Dictionary)
func _build_edge_preset_section(theme_data: Dictionary) -> void:
	if not theme_data.has("edge_presets"):
		theme_data["edge_presets"] = {}
	var presets: Dictionary = theme_data["edge_presets"]

	if not presets.has(ThemeData.DEFAULT_EDGE_PRESET_KEY):
		return

	var preset: Dictionary = presets[ThemeData.DEFAULT_EDGE_PRESET_KEY]

	_properties_container.add_child(
		_create_section_label("--- Edge Preset: " + ThemeData.DEFAULT_EDGE_PRESET_KEY + " ---"))

	# width (SpinBox 1-16)
	var width_spin: SpinBox = SpinBox.new()
	width_spin.min_value = EDGE_WIDTH_MIN
	width_spin.max_value = EDGE_WIDTH_MAX
	width_spin.step = 1.0
	width_spin.value = preset.get("width", ThemeData.DEFAULT_EDGE_WIDTH)
	width_spin.value_changed.connect(func(new_val: float) -> void:
		preset["width"] = int(new_val)
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Width", width_spin))

	# color_locked (ColorPickerButton)
	var locked_color_str: String = preset.get("color_locked", ThemeData.DEFAULT_EDGE_COLOR_LOCKED)
	var locked_picker: ColorPickerButton = ColorPickerButton.new()
	locked_picker.custom_minimum_size.x = 60
	locked_picker.color = Color.from_string(
		locked_color_str,
		Color.from_string(ThemeData.DEFAULT_EDGE_COLOR_LOCKED, Color.WHITE))
	locked_picker.color_changed.connect(func(new_color: Color) -> void:
		preset["color_locked"] = "#" + new_color.to_html(false)
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Color Locked", locked_picker))

	# color_active (ColorPickerButton)
	var active_color_str: String = preset.get("color_active", ThemeData.DEFAULT_EDGE_COLOR_ACTIVE)
	var active_picker: ColorPickerButton = ColorPickerButton.new()
	active_picker.custom_minimum_size.x = 60
	active_picker.color = Color.from_string(
		active_color_str,
		Color.from_string(ThemeData.DEFAULT_EDGE_COLOR_ACTIVE, Color.WHITE))
	active_picker.color_changed.connect(func(new_color: Color) -> void:
		preset["color_active"] = "#" + new_color.to_html(false)
		_apply_to_theme_data()
	)
	_properties_container.add_child(_create_property_row("Color Active", active_picker))


## UI の値をテーマデータに書き戻して theme_changed シグナルを emit する
##
## @return: なし（void）
func _apply_to_theme_data() -> void:
	if _theme_resolver == null or not _theme_resolver.is_loaded():
		return
	theme_changed.emit(_theme_resolver.get_theme_data())


## ラベルと値コントロールを横並びにしたプロパティ行を作成する
##
## @param label_text: ラベルテキスト (String)
## @param value_control: 値の入力コントロール (Control)
## @return: 行の HBoxContainer
func _create_property_row(label_text: String, value_control: Control) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = LABEL_WIDTH_RATIO
	row.add_child(label)

	value_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_control.size_flags_stretch_ratio = VALUE_WIDTH_RATIO
	row.add_child(value_control)

	return row


## セクションラベルを作成する
##
## @param text: 表示テキスト (String)
## @return: Label ノード
func _create_section_label(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", SECTION_LABEL_COLOR)
	return lbl
