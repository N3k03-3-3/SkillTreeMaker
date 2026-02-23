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


## ツリー全体のプロパティ（pack_meta, unlock_rule, entry_nodes）を表示する
##
## プロパティコンテナをクリアして再構築する。
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

	# unlock_rule
	var unlock_rules: Array[String] = SkillTreeModel.VALID_UNLOCK_RULES.duplicate()
	var current_rule: String = _model.tree_meta.get("unlock_rule", SkillTreeModel.UNLOCK_RULE_REQUIRES)
	var rule_btn: OptionButton = OptionButton.new()
	for i: int in range(unlock_rules.size()):
		rule_btn.add_item(unlock_rules[i], i)
		if unlock_rules[i] == current_rule:
			rule_btn.selected = i
	rule_btn.item_selected.connect(func(idx: int) -> void:
		_model.tree_meta["unlock_rule"] = unlock_rules[idx]
		property_changed.emit("tree_meta.unlock_rule", unlock_rules[idx])
		# UI を再構築して説明ラベルを更新
		edit_tree_props()
		edit_theme_props()
	)
	_properties_container.add_child(_create_property_row("Unlock Rule", rule_btn))

	# unlock_rule の説明ラベル
	if current_rule == SkillTreeModel.UNLOCK_RULE_PATH_CONNECTED:
		var desc_lbl: Label = Label.new()
		desc_lbl.text = "Entry point connected nodes only"
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 0.8))
		_properties_container.add_child(desc_lbl)

	# entry_nodes セクション
	_build_entry_nodes_section()


## エントリポイント一覧の編集セクションを構築する
func _build_entry_nodes_section() -> void:
	_properties_container.add_child(_create_section_label("-- Entry Nodes --"))

	var entry_nodes: Array = _model.get_entry_nodes()
	var all_node_ids: Array = _model.get_all_node_ids()

	for entry: Dictionary in entry_nodes:
		var class_id: String = entry.get("class_id", "")
		var node_id: String = entry.get("node_id", "")
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = class_id + " -> " + node_id
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var captured_class: String = class_id
		var del_btn: Button = Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size.x = 28
		del_btn.pressed.connect(func() -> void:
			_model.remove_entry_node(captured_class)
			edit_tree_props()
			edit_theme_props()
		)
		row.add_child(del_btn)
		_properties_container.add_child(row)

	# 追加 UI: class_id 入力 + ノード選択 + 追加ボタン
	var add_row: HBoxContainer = HBoxContainer.new()
	var class_edit: LineEdit = LineEdit.new()
	class_edit.placeholder_text = "class_id"
	class_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_edit.size_flags_stretch_ratio = 0.4
	add_row.add_child(class_edit)

	var node_opt: OptionButton = OptionButton.new()
	node_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_opt.size_flags_stretch_ratio = 0.4
	for nid: String in all_node_ids:
		node_opt.add_item(nid)
	add_row.add_child(node_opt)

	var add_btn: Button = Button.new()
	add_btn.text = "+"
	add_btn.custom_minimum_size.x = 28
	add_btn.pressed.connect(func() -> void:
		var cid: String = class_edit.text.strip_edges()
		if cid.is_empty() or node_opt.item_count == 0:
			return
		var nid: String = node_opt.get_item_text(node_opt.selected)
		_model.add_entry_node(cid, nid)
		edit_tree_props()
		edit_theme_props()
	)
	add_row.add_child(add_btn)
	_properties_container.add_child(add_row)


## グループプロパティ（ID, center, 依存関係）を表示する
##
## 選択中のグループ情報をプロパティコンテナに構築する。
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

	# B3: グループ依存関係
	_build_group_deps_section(group_id)


## ノードプロパティ（ID, NodeType, 基本情報, スタイル, コスト, アンロック条件, 位置）を表示する
##
## 選択中のノード情報をプロパティコンテナに構築する。
func edit_node_props() -> void:
	_clear_properties()
	_show_properties()

	if _model == null or _selection == null:
		return

	var node_id: String = _selection.selected_id
	var node: Dictionary = _model.get_node(node_id)
	if node.is_empty():
		return

	_properties_container.add_child(_create_readonly_row("ID", node_id))
	_build_node_type_section(node_id, node)
	_build_node_basics_section(node_id, node)
	_build_node_style_section(node_id, node)
	_build_node_cost_section(node_id, node)
	_build_node_unlock_section(node_id, node)
	_build_node_position_section(node_id, node)


## ノード種別（NodeType）プロパティ行を構築する
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_type_section(node_id: String, node: Dictionary) -> void:
	var node_types: Array[String] = SkillTreeModel.VALID_NODE_TYPES.duplicate()
	var current_type: String = node.get("node_type", SkillTreeModel.NODE_TYPE_MINOR)
	var type_btn: OptionButton = OptionButton.new()
	for i: int in range(node_types.size()):
		type_btn.add_item(node_types[i], i)
		if node_types[i] == current_type:
			type_btn.selected = i
	type_btn.item_selected.connect(func(idx: int) -> void:
		_model.update_node(node_id, {"node_type": node_types[idx]})
		property_changed.emit("node_type", node_types[idx])
	)
	_properties_container.add_child(_create_property_row("Node Type", type_btn))


## ノード基本プロパティ行を構築する（name_key / desc_key / icon_path / group）
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_basics_section(node_id: String, node: Dictionary) -> void:
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = node.get("name_key", "")
	name_edit.text_changed.connect(func(t: String) -> void:
		_model.update_node(node_id, {"name_key": t})
		property_changed.emit("name_key", t)
	)
	_properties_container.add_child(_create_property_row("Name Key", name_edit))

	var desc_edit: LineEdit = LineEdit.new()
	desc_edit.text = node.get("desc_key", "")
	desc_edit.text_changed.connect(func(t: String) -> void:
		_model.update_node(node_id, {"desc_key": t})
		property_changed.emit("desc_key", t)
	)
	_properties_container.add_child(_create_property_row("Desc Key", desc_edit))

	var icon_edit: LineEdit = LineEdit.new()
	icon_edit.text = node.get("icon_path", "")
	icon_edit.placeholder_text = "res://icons/..."
	icon_edit.text_changed.connect(func(t: String) -> void:
		_model.update_node(node_id, {"icon_path": t})
		property_changed.emit("icon_path", t)
	)
	_properties_container.add_child(_create_property_row("Icon Path", icon_edit))

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
		_model.update_node(node_id, {"group_id": group_btn.get_item_text(idx)})
		property_changed.emit("group_id", group_btn.get_item_text(idx))
	)
	_properties_container.add_child(_create_property_row("Group", group_btn))


## ノードスタイルプロパティ行を構築する（preset / color / shape / size）
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_style_section(node_id: String, node: Dictionary) -> void:
	var style: Dictionary = node.get("style", {})

	var style_edit: LineEdit = LineEdit.new()
	style_edit.text = style.get("preset", "")
	style_edit.text_changed.connect(func(t: String) -> void:
		var s: Dictionary = _model.get_node(node_id).get("style", {})
		s["preset"] = t
		_model.update_node(node_id, {"style": s})
		property_changed.emit("style.preset", t)
	)
	_properties_container.add_child(_create_property_row("Style Preset", style_edit))

	var color_picker: ColorPickerButton = ColorPickerButton.new()
	color_picker.custom_minimum_size.x = 60
	var color_str: String = style.get("color", "")
	color_picker.color = Color.from_string(color_str, Color.WHITE) if not color_str.is_empty() else Color.WHITE
	color_picker.color_changed.connect(func(c: Color) -> void:
		var s: Dictionary = _model.get_node(node_id).get("style", {})
		s["color"] = c.to_html(false)
		_model.update_node(node_id, {"style": s})
		property_changed.emit("style.color", c.to_html(false))
	)
	_properties_container.add_child(_create_property_row("Color", color_picker))

	# B2: 形状
	var shapes: Array[String] = ["square", "circle", "diamond"]
	var current_shape: String = style.get("shape", "square")
	var shape_btn: OptionButton = OptionButton.new()
	for i: int in range(shapes.size()):
		shape_btn.add_item(shapes[i], i)
		if shapes[i] == current_shape:
			shape_btn.selected = i
	shape_btn.item_selected.connect(func(idx: int) -> void:
		var s: Dictionary = _model.get_node(node_id).get("style", {})
		s["shape"] = shapes[idx]
		_model.update_node(node_id, {"style": s})
		property_changed.emit("style.shape", shapes[idx])
	)
	_properties_container.add_child(_create_property_row("Shape", shape_btn))

	# B2: サイズ
	var sizes: Array[String] = ["small", "medium", "large"]
	var current_size: String = style.get("size", "medium")
	var size_btn: OptionButton = OptionButton.new()
	for i: int in range(sizes.size()):
		size_btn.add_item(sizes[i], i)
		if sizes[i] == current_size:
			size_btn.selected = i
	size_btn.item_selected.connect(func(idx: int) -> void:
		var s: Dictionary = _model.get_node(node_id).get("style", {})
		s["size"] = sizes[idx]
		_model.update_node(node_id, {"style": s})
		property_changed.emit("style.size", sizes[idx])
	)
	_properties_container.add_child(_create_property_row("Size", size_btn))


## ノードコストプロパティ行を構築する（cost.type / cost.value）
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_cost_section(node_id: String, node: Dictionary) -> void:
	var unlock: Dictionary = node.get("unlock", {})
	var cost: Dictionary = unlock.get("cost", {})

	var cost_type_btn: OptionButton = OptionButton.new()
	var cost_types: Array[String] = ["gp", "item", "level"]
	var current_cost_type: String = cost.get("type", "gp")
	for i: int in range(cost_types.size()):
		cost_type_btn.add_item(cost_types[i], i)
		if cost_types[i] == current_cost_type:
			cost_type_btn.selected = i
	cost_type_btn.item_selected.connect(func(idx: int) -> void:
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var c: Dictionary = u.get("cost", {})
		c["type"] = cost_type_btn.get_item_text(idx)
		u["cost"] = c
		_model.update_node(node_id, {"unlock": u})
		property_changed.emit("unlock.cost.type", cost_type_btn.get_item_text(idx))
	)
	_properties_container.add_child(_create_property_row("Cost Type", cost_type_btn))

	var cost_spin: SpinBox = SpinBox.new()
	cost_spin.min_value = 0.0
	cost_spin.max_value = 99999.0
	cost_spin.step = 1.0
	cost_spin.value = cost.get("value", 1)
	cost_spin.value_changed.connect(func(v: float) -> void:
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var c: Dictionary = u.get("cost", {})
		c["value"] = int(v)
		u["cost"] = c
		_model.update_node(node_id, {"unlock": u})
		property_changed.emit("unlock.cost.value", int(v))
	)
	_properties_container.add_child(_create_property_row("Cost Value", cost_spin))


## B4: アンロック条件プロパティ行を構築する（requires_all / requires_any / level_reqs）
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_unlock_section(node_id: String, node: Dictionary) -> void:
	var unlock: Dictionary = node.get("unlock", {})
	var all_node_ids: Array = _model.get_all_node_ids()

	_properties_container.add_child(_create_section_label("-- Requires ALL --"))
	_build_requires_list(node_id, "requires", unlock.get("requires", []), all_node_ids)

	_properties_container.add_child(_create_section_label("-- Requires ANY --"))
	_build_requires_list(node_id, "requires_any", unlock.get("requires_any", []), all_node_ids)

	_properties_container.add_child(_create_section_label("-- Level Reqs --"))
	_build_level_reqs(node_id, unlock.get("level_reqs", {}), all_node_ids)


## requires_all / requires_any のリスト行を構築する（アイテム一覧 + 追加 UI）
##
## @param node_id: ノード ID (String)
## @param field_key: "requires" か "requires_any" (String)
## @param current_list: 現在のリスト (Array)
## @param all_node_ids: 全ノード ID 配列 (Array)
func _build_requires_list(node_id: String, field_key: String, current_list: Array, all_node_ids: Array) -> void:
	for req_id: String in current_list:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = req_id
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var captured_req: String = req_id
		var del_btn: Button = Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size.x = 28
		del_btn.pressed.connect(func() -> void:
			var u: Dictionary = _model.get_node(node_id).get("unlock", {})
			var r: Array = u.get(field_key, [])
			r.erase(captured_req)
			u[field_key] = r
			_model.update_node(node_id, {"unlock": u})
			edit_node_props()
		)
		row.add_child(del_btn)
		_properties_container.add_child(row)

	var add_row: HBoxContainer = HBoxContainer.new()
	var opt: OptionButton = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for nid: String in all_node_ids:
		if nid != node_id and not current_list.has(nid):
			opt.add_item(nid)
	add_row.add_child(opt)
	var add_btn: Button = Button.new()
	add_btn.text = "+"
	add_btn.custom_minimum_size.x = 28
	add_btn.pressed.connect(func() -> void:
		if opt.item_count == 0:
			return
		var nid: String = opt.get_item_text(opt.selected)
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var r: Array = u.get(field_key, [])
		if not r.has(nid):
			r.append(nid)
			u[field_key] = r
			_model.update_node(node_id, {"unlock": u})
			edit_node_props()
	)
	add_row.add_child(add_btn)
	_properties_container.add_child(add_row)


## B4: level_reqs セクション行を構築する（node_id → min_level のリスト + 追加 UI）
##
## @param node_id: ノード ID (String)
## @param level_reqs: 現在の level_reqs Dictionary (Dictionary)
## @param all_node_ids: 全ノード ID 配列 (Array)
func _build_level_reqs(node_id: String, level_reqs: Dictionary, all_node_ids: Array) -> void:
	for lreq_nid: String in level_reqs.keys():
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = lreq_nid
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var spin: SpinBox = SpinBox.new()
		spin.min_value = 1.0
		spin.max_value = 999.0
		spin.step = 1.0
		spin.value = level_reqs.get(lreq_nid, 1)
		spin.custom_minimum_size.x = 60
		var captured_lnid: String = lreq_nid
		spin.value_changed.connect(func(v: float) -> void:
			var u: Dictionary = _model.get_node(node_id).get("unlock", {})
			var lr: Dictionary = u.get("level_reqs", {})
			lr[captured_lnid] = int(v)
			u["level_reqs"] = lr
			_model.update_node(node_id, {"unlock": u})
		)
		row.add_child(spin)
		var del_btn: Button = Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size.x = 28
		del_btn.pressed.connect(func() -> void:
			var u: Dictionary = _model.get_node(node_id).get("unlock", {})
			var lr: Dictionary = u.get("level_reqs", {})
			lr.erase(captured_lnid)
			u["level_reqs"] = lr
			_model.update_node(node_id, {"unlock": u})
			edit_node_props()
		)
		row.add_child(del_btn)
		_properties_container.add_child(row)

	var add_row: HBoxContainer = HBoxContainer.new()
	var opt: OptionButton = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for nid: String in all_node_ids:
		if nid != node_id and not level_reqs.has(nid):
			opt.add_item(nid)
	add_row.add_child(opt)
	var lv_spin: SpinBox = SpinBox.new()
	lv_spin.min_value = 1.0
	lv_spin.max_value = 999.0
	lv_spin.step = 1.0
	lv_spin.value = 1.0
	lv_spin.custom_minimum_size.x = 60
	add_row.add_child(lv_spin)
	var add_btn: Button = Button.new()
	add_btn.text = "+"
	add_btn.custom_minimum_size.x = 28
	add_btn.pressed.connect(func() -> void:
		if opt.item_count == 0:
			return
		var nid: String = opt.get_item_text(opt.selected)
		var u: Dictionary = _model.get_node(node_id).get("unlock", {})
		var lr: Dictionary = u.get("level_reqs", {})
		lr[nid] = int(lv_spin.value)
		u["level_reqs"] = lr
		_model.update_node(node_id, {"unlock": u})
		edit_node_props()
	)
	add_row.add_child(add_btn)
	_properties_container.add_child(add_row)


## ノード位置プロパティ行を構築する（pos.x / pos.y）
##
## @param node_id: ノード ID (String)
## @param node: ノードデータ (Dictionary)
func _build_node_position_section(node_id: String, node: Dictionary) -> void:
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

	spin_x.value_changed.connect(func(_v: float) -> void:
		_model.update_node(node_id, {"pos": {"x": spin_x.value, "y": spin_y.value}})
		property_changed.emit("pos.x", spin_x.value)
	)
	spin_y.value_changed.connect(func(_v: float) -> void:
		_model.update_node(node_id, {"pos": {"x": spin_x.value, "y": spin_y.value}})
		property_changed.emit("pos.y", spin_y.value)
	)
	_properties_container.add_child(_create_property_row("Pos X", spin_x))
	_properties_container.add_child(_create_property_row("Pos Y", spin_y))


## エッジプロパティ（from, to, style_preset）を表示する
##
## 選択中のエッジ情報をプロパティコンテナに構築する。
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
##
## Selection / Model / ThemeResolver の参照を解放し、未選択表示に戻す。
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


## セクションラベルを作成する
##
## @param text: 表示テキスト (String)
## @return: Label ノード
func _create_section_label(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
	return lbl


## B3: グループ依存関係セクションを構築する（このグループが「前提」とするグループ一覧）
##
## @param group_id: 現在のグループ ID (String)
func _build_group_deps_section(group_id: String) -> void:
	_properties_container.add_child(_create_section_label("-- Group Dependencies --"))

	var all_group_edges: Array = _model.get_all_group_edges()
	var current_deps: Array[String] = []
	for ge: Dictionary in all_group_edges:
		if ge.get("from", "") == group_id:
			current_deps.append(ge.get("to", ""))

	for dep_id: String in current_deps:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = dep_id
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var captured_dep: String = dep_id
		var del_btn: Button = Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size.x = 28
		del_btn.pressed.connect(func() -> void:
			_model.remove_group_edge(group_id, captured_dep)
			edit_group_props()
		)
		row.add_child(del_btn)
		_properties_container.add_child(row)

	# 追加 UI
	var add_row: HBoxContainer = HBoxContainer.new()
	var opt: OptionButton = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for g: Dictionary in _model.get_all_groups():
		var gid: String = g.get("id", "")
		if gid != group_id and not current_deps.has(gid):
			opt.add_item(gid)
	add_row.add_child(opt)
	var add_btn: Button = Button.new()
	add_btn.text = "+"
	add_btn.custom_minimum_size.x = 28
	add_btn.pressed.connect(func() -> void:
		if opt.item_count == 0:
			return
		var target_gid: String = opt.get_item_text(opt.selected)
		_model.add_group_edge(group_id, target_gid)
		edit_group_props()
	)
	add_row.add_child(add_btn)
	_properties_container.add_child(add_row)


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
