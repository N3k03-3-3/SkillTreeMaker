@tool
class_name InspectorPanel
extends PanelContainer

## 選択中アイテムのプロパティ編集パネル
##
## SelectionModel の selection_changed シグナルに反応して、
## 選択種別に応じたプロパティエディタを動的に構築する。


# --- Signals ---

## プロパティが編集されたとき
signal property_changed(property_name: String, new_value: Variant)


# --- Constants ---

## パネルの最小幅
const PANEL_MIN_WIDTH: int = 250

## セクションのインデント
const SECTION_INDENT: int = 8

## ラベル幅の比率（行全体に対するラベルの割合）
const LABEL_WIDTH_RATIO: float = 0.4


# --- Private Variables ---

## 参照する SkillTreeModel
var _model: SkillTreeModel = null

## 参照する SelectionModel
var _selection: SelectionModel = null

## コンテンツを格納する VBoxContainer
var _content_container: VBoxContainer = null

## パネルタイトルラベル
var _title_label: Label = null

## 未選択時のラベル
var _no_selection_label: Label = null

## プロパティ一覧のスクロールコンテナ
var _scroll_container: ScrollContainer = null

## プロパティ行を格納する VBoxContainer
var _properties_container: VBoxContainer = null

## テーマリゾルバへの参照
var _theme_resolver: ThemeResolver = null


# --- Built-in Functions ---

## パネルの初期設定を行う
func _ready() -> void:
	custom_minimum_size.x = PANEL_MIN_WIDTH
	_build_ui()


# --- Public Functions ---

## SelectionModel と SkillTreeModel をバインドする
##
## @param model: スキルツリーモデル (SkillTreeModel)
## @param selection: 選択状態モデル (SelectionModel)
func bind_selection(model: SkillTreeModel, selection: SelectionModel) -> void:
	_model = model
	_selection = selection

	if _selection == null:
		return

	if not _selection.selection_changed.is_connected(_on_selection_changed):
		_selection.selection_changed.connect(_on_selection_changed)
	if not _selection.selection_cleared.is_connected(_on_selection_cleared):
		_selection.selection_cleared.connect(_on_selection_cleared)


## ThemeResolver を設定する
##
## bind_selection の後に呼ぶこと。
##
## @param theme_resolver: テーマリゾルバ (ThemeResolver)
func bind_theme_resolver(theme_resolver: ThemeResolver) -> void:
	_theme_resolver = theme_resolver


## ツリー全体のプロパティを表示する
func edit_tree_props() -> void:
	_clear_properties()
	_show_properties()

	if _model == null:
		return

	# pack_meta.id（読み取り専用）
	var pack_id: String = _model.pack_meta.get("id", "")
	_properties_container.add_child(_create_readonly_row("Pack ID", pack_id))

	# pack_meta.name
	var pack_name: String = _model.pack_meta.get("name", "")
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = pack_name
	name_edit.text_changed.connect(func(new_text: String) -> void:
		_model.pack_meta["name"] = new_text
		property_changed.emit("pack_meta.name", new_text)
	)
	_properties_container.add_child(_create_property_row("Name", name_edit))

	# pack_meta.author
	var author: String = _model.pack_meta.get("author", "")
	var author_edit: LineEdit = LineEdit.new()
	author_edit.text = author
	author_edit.text_changed.connect(func(new_text: String) -> void:
		_model.pack_meta["author"] = new_text
		property_changed.emit("pack_meta.author", new_text)
	)
	_properties_container.add_child(_create_property_row("Author", author_edit))

	# pack_meta.tags
	var tags_value: Variant = _model.pack_meta.get("tags", "")
	var tags_str: String = ""
	if tags_value is Array:
		tags_str = ",".join(tags_value)
	elif tags_value is String:
		tags_str = tags_value
	var tags_edit: LineEdit = LineEdit.new()
	tags_edit.text = tags_str
	tags_edit.placeholder_text = "tag1,tag2,..."
	tags_edit.text_changed.connect(func(new_text: String) -> void:
		_model.pack_meta["tags"] = new_text
		property_changed.emit("pack_meta.tags", new_text)
	)
	_properties_container.add_child(_create_property_row("Tags", tags_edit))

	# tree_meta.entry_node_id
	var entry_id: String = _model.tree_meta.get("entry_node_id", "")
	var entry_edit: LineEdit = LineEdit.new()
	entry_edit.text = entry_id
	entry_edit.text_changed.connect(func(new_text: String) -> void:
		_model.tree_meta["entry_node_id"] = new_text
		property_changed.emit("tree_meta.entry_node_id", new_text)
	)
	_properties_container.add_child(_create_property_row("Entry Node", entry_edit))


## グループプロパティを表示する
func edit_group_props() -> void:
	_clear_properties()
	_show_properties()

	if _model == null or _selection == null:
		return

	var group_id: String = _selection.selected_id
	var group: Dictionary = {}
	for g: Dictionary in _model.get_all_groups():
		if g.get("id", "") == group_id:
			group = g
			break

	if group.is_empty():
		return

	# id（読み取り専用）
	_properties_container.add_child(_create_readonly_row("ID", group_id))

	# center.x
	var center: Dictionary = group.get("center", {"x": 0.0, "y": 0.0})
	var spin_cx: SpinBox = SpinBox.new()
	spin_cx.min_value = -99999.0
	spin_cx.max_value = 99999.0
	spin_cx.step = 1.0
	spin_cx.value = center.get("x", 0.0)
	spin_cx.value_changed.connect(func(new_val: float) -> void:
		group["center"]["x"] = new_val
		property_changed.emit("center.x", new_val)
	)
	_properties_container.add_child(_create_property_row("Center X", spin_cx))

	# center.y
	var spin_cy: SpinBox = SpinBox.new()
	spin_cy.min_value = -99999.0
	spin_cy.max_value = 99999.0
	spin_cy.step = 1.0
	spin_cy.value = center.get("y", 0.0)
	spin_cy.value_changed.connect(func(new_val: float) -> void:
		group["center"]["y"] = new_val
		property_changed.emit("center.y", new_val)
	)
	_properties_container.add_child(_create_property_row("Center Y", spin_cy))


## ノードプロパティを表示する
func edit_node_props() -> void:
	_clear_properties()
	_show_properties()

	if _model == null or _selection == null:
		return

	var node_id: String = _selection.selected_id
	var node: Dictionary = _model.get_node(node_id)
	if node.is_empty():
		return

	# id（読み取り専用）
	_properties_container.add_child(_create_readonly_row("ID", node_id))

	# name_key
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = node.get("name_key", "")
	name_edit.text_changed.connect(func(new_text: String) -> void:
		_model.update_node(node_id, {"name_key": new_text})
		property_changed.emit("name_key", new_text)
	)
	_properties_container.add_child(_create_property_row("Name Key", name_edit))

	# desc_key
	var desc_edit: LineEdit = LineEdit.new()
	desc_edit.text = node.get("desc_key", "")
	desc_edit.text_changed.connect(func(new_text: String) -> void:
		_model.update_node(node_id, {"desc_key": new_text})
		property_changed.emit("desc_key", new_text)
	)
	_properties_container.add_child(_create_property_row("Desc Key", desc_edit))

	# icon_path
	var icon_edit: LineEdit = LineEdit.new()
	icon_edit.text = node.get("icon_path", "")
	icon_edit.placeholder_text = "res://icons/..."
	icon_edit.text_changed.connect(func(new_text: String) -> void:
		_model.update_node(node_id, {"icon_path": new_text})
		property_changed.emit("icon_path", new_text)
	)
	_properties_container.add_child(_create_property_row("Icon Path", icon_edit))

	# group_id（OptionButton）
	var group_btn: OptionButton = OptionButton.new()
	var groups: Array = _model.get_all_groups()
	var current_group_id: String = node.get("group_id", "")
	var selected_idx: int = 0
	for i: int in range(groups.size()):
		var gid: String = groups[i].get("id", "")
		group_btn.add_item(gid, i)
		if gid == current_group_id:
			selected_idx = i
	if groups.size() > 0:
		group_btn.selected = selected_idx
	group_btn.item_selected.connect(func(idx: int) -> void:
		var gid: String = group_btn.get_item_text(idx)
		_model.update_node(node_id, {"group_id": gid})
		property_changed.emit("group_id", gid)
	)
	_properties_container.add_child(_create_property_row("Group", group_btn))

	# style.preset
	var style: Dictionary = node.get("style", {})
	var style_edit: LineEdit = LineEdit.new()
	style_edit.text = style.get("preset", "")
	style_edit.text_changed.connect(func(new_text: String) -> void:
		var s: Dictionary = _model.get_node(node_id).get("style", {})
		s["preset"] = new_text
		_model.update_node(node_id, {"style": s})
		property_changed.emit("style.preset", new_text)
	)
	_properties_container.add_child(_create_property_row("Style Preset", style_edit))

	# unlock.cost.type（OptionButton）
	var unlock: Dictionary = node.get("unlock", {})
	var cost: Dictionary = unlock.get("cost", {})
	var cost_type_btn: OptionButton = OptionButton.new()
	var cost_types: Array = ["gp", "item", "level"]
	var current_cost_type: String = cost.get("type", "gp")
	for i: int in range(cost_types.size()):
		cost_type_btn.add_item(cost_types[i], i)
		if cost_types[i] == current_cost_type:
			cost_type_btn.selected = i
	cost_type_btn.item_selected.connect(func(idx: int) -> void:
		var ct: String = cost_type_btn.get_item_text(idx)
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var c: Dictionary = u.get("cost", {})
		c["type"] = ct
		u["cost"] = c
		_model.update_node(node_id, {"unlock": u})
		property_changed.emit("unlock.cost.type", ct)
	)
	_properties_container.add_child(_create_property_row("Cost Type", cost_type_btn))

	# unlock.cost.value
	var cost_spin: SpinBox = SpinBox.new()
	cost_spin.min_value = 0.0
	cost_spin.max_value = 99999.0
	cost_spin.step = 1.0
	cost_spin.value = cost.get("value", 1)
	cost_spin.value_changed.connect(func(new_val: float) -> void:
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var c: Dictionary = u.get("cost", {})
		c["value"] = int(new_val)
		u["cost"] = c
		_model.update_node(node_id, {"unlock": u})
		property_changed.emit("unlock.cost.value", int(new_val))
	)
	_properties_container.add_child(_create_property_row("Cost Value", cost_spin))

	# pos.x / pos.y
	var pos: Dictionary = node.get("pos", {"x": 0.0, "y": 0.0})
	var spin_x: SpinBox = SpinBox.new()
	spin_x.min_value = -99999.0
	spin_x.max_value = 99999.0
	spin_x.step = 1.0
	spin_x.value = pos.get("x", 0.0)

	var spin_y: SpinBox = SpinBox.new()
	spin_y.min_value = -99999.0
	spin_y.max_value = 99999.0
	spin_y.step = 1.0
	spin_y.value = pos.get("y", 0.0)

	spin_x.value_changed.connect(func(_new_val: float) -> void:
		_model.update_node(node_id, {"pos": {"x": spin_x.value, "y": spin_y.value}})
		property_changed.emit("pos.x", spin_x.value)
	)
	spin_y.value_changed.connect(func(_new_val: float) -> void:
		_model.update_node(node_id, {"pos": {"x": spin_x.value, "y": spin_y.value}})
		property_changed.emit("pos.y", spin_y.value)
	)
	_properties_container.add_child(_create_property_row("Pos X", spin_x))
	_properties_container.add_child(_create_property_row("Pos Y", spin_y))


## エッジプロパティを表示する
func edit_edge_props() -> void:
	_clear_properties()
	_show_properties()

	if _model == null or _selection == null:
		return

	var edge_key: String = _selection.selected_id
	var parts: PackedStringArray = edge_key.split("->")
	if parts.size() != 2:
		return

	var from_id: String = parts[0]
	var to_id: String = parts[1]

	# エッジデータを検索
	var edge: Dictionary = {}
	for e: Dictionary in _model.get_all_edges():
		if e.get("from", "") == from_id and e.get("to", "") == to_id:
			edge = e
			break

	# from（読み取り専用）
	_properties_container.add_child(_create_readonly_row("From", from_id))

	# to（読み取り専用）
	_properties_container.add_child(_create_readonly_row("To", to_id))

	# style_preset
	var style_edit: LineEdit = LineEdit.new()
	style_edit.text = edge.get("style_preset", "")
	style_edit.text_changed.connect(func(new_text: String) -> void:
		edge["style_preset"] = new_text
		property_changed.emit("style_preset", new_text)
	)
	_properties_container.add_child(_create_property_row("Style Preset", style_edit))


## テーマプロパティを表示する（ツリープロパティに追記する形で呼ばれる）
##
## ThemeResolver が保持するテーマデータを編集する。
## 変更はインメモリに即時反映され、Save Pack 時にディスクへ書き出される。
## _on_selection_changed の "tree" 分岐で edit_tree_props() の後に呼ばれるため、
## _clear_properties() / _show_properties() は呼ばない。
func edit_theme_props() -> void:
	if _theme_resolver == null or not _theme_resolver.is_loaded():
		_properties_container.add_child(
			_create_readonly_row("Theme", "(not loaded)"))
		return

	var theme_data: Dictionary = _theme_resolver.get_theme_data()

	# --- Background ---
	# キーが存在しない場合は theme_data に直接登録して参照を保持する
	if not theme_data.has("background"):
		theme_data["background"] = {}
	var bg: Dictionary = theme_data["background"]

	var sep_bg: Label = Label.new()
	sep_bg.text = "--- Background ---"
	_properties_container.add_child(sep_bg)

	var tint_edit: LineEdit = LineEdit.new()
	tint_edit.text = bg.get("tint", "#FFFFFF")
	tint_edit.placeholder_text = "#RRGGBB"
	tint_edit.text_changed.connect(func(new_text: String) -> void:
		bg["tint"] = new_text
		property_changed.emit("background.tint", new_text)
	)
	_properties_container.add_child(_create_property_row("Tint", tint_edit))

	var tex_edit: LineEdit = LineEdit.new()
	tex_edit.text = bg.get("texture", "")
	tex_edit.placeholder_text = "textures/bg.png"
	tex_edit.text_changed.connect(func(new_text: String) -> void:
		bg["texture"] = new_text
		property_changed.emit("background.texture", new_text)
	)
	_properties_container.add_child(_create_property_row("Texture", tex_edit))

	# --- Window ---
	if not theme_data.has("window"):
		theme_data["window"] = {}
	var window: Dictionary = theme_data["window"]
	if not window.has("padding"):
		window["padding"] = {"l": 24, "t": 24, "r": 24, "b": 24}
	var padding: Dictionary = window["padding"]

	var sep_win: Label = Label.new()
	sep_win.text = "--- Window ---"
	_properties_container.add_child(sep_win)

	for side: String in ["l", "t", "r", "b"]:
		var spin: SpinBox = SpinBox.new()
		spin.min_value = 0.0
		spin.max_value = 256.0
		spin.step = 1.0
		spin.value = padding.get(side, 24)
		spin.value_changed.connect(func(new_val: float) -> void:
			padding[side] = int(new_val)
			property_changed.emit("window.padding." + side, int(new_val))
		)
		_properties_container.add_child(_create_property_row("Padding " + side.to_upper(), spin))

	# --- Node Presets ---
	var sep_np: Label = Label.new()
	sep_np.text = "--- Node Presets ---"
	_properties_container.add_child(sep_np)

	var node_presets: Dictionary = theme_data.get("node_presets", {})
	for preset_key: String in node_presets.keys():
		var preset: Dictionary = node_presets[preset_key]

		_properties_container.add_child(_create_readonly_row("Preset", preset_key))

		var size_spin: SpinBox = SpinBox.new()
		size_spin.min_value = 16.0
		size_spin.max_value = 256.0
		size_spin.step = 1.0
		size_spin.value = preset.get("size", 48)
		size_spin.value_changed.connect(func(new_val: float) -> void:
			preset["size"] = int(new_val)
			property_changed.emit("node_presets." + preset_key + ".size", int(new_val))
		)
		_properties_container.add_child(_create_property_row("Size", size_spin))


## シグナル切断とプロパティクリアを行う
func unbind() -> void:
	if _selection != null:
		if _selection.selection_changed.is_connected(_on_selection_changed):
			_selection.selection_changed.disconnect(_on_selection_changed)
		if _selection.selection_cleared.is_connected(_on_selection_cleared):
			_selection.selection_cleared.disconnect(_on_selection_cleared)

	_model = null
	_selection = null
	_theme_resolver = null
	_clear_properties()
	_show_no_selection()


# --- Private Functions ---

## UI 要素を構築する（_ready から呼び出す）
func _build_ui() -> void:
	_content_container = VBoxContainer.new()
	_content_container.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_content_container)

	# タイトルラベル
	_title_label = Label.new()
	_title_label.text = "Inspector"
	_content_container.add_child(_title_label)

	# 未選択ラベル
	_no_selection_label = Label.new()
	_no_selection_label.text = "Nothing selected"
	_content_container.add_child(_no_selection_label)

	# スクロールコンテナ
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.visible = false
	_content_container.add_child(_scroll_container)

	# プロパティコンテナ
	_properties_container = VBoxContainer.new()
	_properties_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_properties_container)


## プロパティコンテナの全子ノードを削除する
func _clear_properties() -> void:
	if _properties_container == null:
		return
	for child: Node in _properties_container.get_children():
		_properties_container.remove_child(child)
		child.queue_free()


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
	value_control.size_flags_stretch_ratio = 1.0 - LABEL_WIDTH_RATIO
	row.add_child(value_control)

	return row


## 読み取り専用のラベルペアを作成する
##
## @param label_text: ラベルテキスト (String)
## @param value_text: 値テキスト (String)
## @return: 行の HBoxContainer
func _create_readonly_row(label_text: String, value_text: String) -> HBoxContainer:
	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	return _create_property_row(label_text, value_label)


## プロパティ表示モードに切り替える
func _show_properties() -> void:
	if _no_selection_label != null:
		_no_selection_label.hide()
	if _scroll_container != null:
		_scroll_container.show()


## 未選択表示モードに切り替える
func _show_no_selection() -> void:
	if _scroll_container != null:
		_scroll_container.hide()
	if _no_selection_label != null:
		_no_selection_label.show()


# --- Signal Callbacks ---

## 選択変更時のコールバック
##
## @param selection_type: 選択種別の文字列 (String)
## @param selection_id: 選択対象の ID (String)
func _on_selection_changed(selection_type: String, selection_id: String) -> void:
	match selection_type:
		"node":
			edit_node_props()
		"edge":
			edit_edge_props()
		"group":
			edit_group_props()
		"tree":
			edit_tree_props()
			edit_theme_props()


## 選択クリア時のコールバック
func _on_selection_cleared() -> void:
	_clear_properties()
	_show_no_selection()
