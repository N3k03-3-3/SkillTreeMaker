@tool
class_name HierarchyPanel
extends PanelContainer

## グループごとにノードを階層表示するパネル
##
## SkillTreeModel のノード・グループを Tree コントロールで表示する。
## 検索フィルタリングと、クリックによる SelectionModel 連携を行う。


# --- Signals ---

## ノードがクリック選択されたとき
signal node_selected_in_hierarchy(node_id: String)

## グループがクリック選択されたとき
signal group_selected_in_hierarchy(group_id: String)

## グループ追加がリクエストされたとき
signal group_add_requested()

## グループ削除がリクエストされたとき
signal group_delete_requested(group_id: String)


# --- Constants ---

## パネルの最小幅
const PANEL_MIN_WIDTH: int = 200

## ノード名の最大表示文字数
const MAX_DISPLAY_NAME_LENGTH: int = 30

## 検索フィルタの遅延時間（秒）
const FILTER_DELAY_SEC: float = 0.2


# --- Private Variables ---

## 参照する SkillTreeModel
var _model: SkillTreeModel = null

## 参照する SelectionModel
var _selection: SelectionModel = null

## Tree コントロール
var _tree: Tree = null

## 検索フィルタ用の LineEdit
var _search_edit: LineEdit = null

## 現在のフィルタテキスト（小文字化済み）
var _filter_text: String = ""

## グループ TreeItem のキャッシュ (group_id -> TreeItem)
var _group_items: Dictionary = {}

## ノード TreeItem のキャッシュ (node_id -> TreeItem)
var _node_items: Dictionary = {}

## フィルタ遅延用タイマー
var _filter_timer: Timer = null

## グループ操作ボタンバー
var _group_buttons_bar: HBoxContainer = null

## 選択同期中フラグ（無限ループ防止）
var _syncing_selection: bool = false


# --- Built-in Functions ---

## パネルの初期設定を行う
func _ready() -> void:
	custom_minimum_size.x = PANEL_MIN_WIDTH
	_build_ui()


# --- Public Functions ---

## モデルと SelectionModel を設定する
##
## 旧モデルのシグナルを切断し、新モデルのシグナルを接続してツリーを再構築する。
##
## @param model: SkillTreeModel（null で解除） (SkillTreeModel)
## @param selection: SelectionModel（null で解除） (SelectionModel)
func set_model(model: SkillTreeModel, selection: SelectionModel) -> void:
	# 旧モデルのシグナル切断
	if _model != null:
		if _model.model_changed.is_connected(_on_model_changed):
			_model.model_changed.disconnect(_on_model_changed)
		if _model.node_added.is_connected(_on_node_added):
			_model.node_added.disconnect(_on_node_added)
		if _model.node_removed.is_connected(_on_node_removed):
			_model.node_removed.disconnect(_on_node_removed)
		if _model.node_updated.is_connected(_on_node_updated):
			_model.node_updated.disconnect(_on_node_updated)
		if _model.group_added.is_connected(_on_group_changed):
			_model.group_added.disconnect(_on_group_changed)
		if _model.group_removed.is_connected(_on_group_changed):
			_model.group_removed.disconnect(_on_group_changed)

	# 旧 SelectionModel のシグナル切断
	if _selection != null:
		if _selection.selection_changed.is_connected(_on_external_selection_changed):
			_selection.selection_changed.disconnect(_on_external_selection_changed)

	_model = model
	_selection = selection

	# 新モデルのシグナル接続
	if _model != null:
		_model.model_changed.connect(_on_model_changed)
		_model.node_added.connect(_on_node_added)
		_model.node_removed.connect(_on_node_removed)
		_model.node_updated.connect(_on_node_updated)
		_model.group_added.connect(_on_group_changed)
		_model.group_removed.connect(_on_group_changed)

	# 新 SelectionModel のシグナル接続
	if _selection != null:
		_selection.selection_changed.connect(_on_external_selection_changed)

	_rebuild_tree()


## テキストでフィルタリングする
##
## @param text: フィルタ文字列 (String)
func search(text: String) -> void:
	_filter_text = text.strip_edges().to_lower()
	_rebuild_tree()


## 指定ノードをツリー上で選択状態にする
##
## @param node_id: 選択するノード ID (String)
func select(node_id: String) -> void:
	if not _node_items.has(node_id):
		return

	var item: TreeItem = _node_items[node_id]
	item.select(0)
	_tree.scroll_to_item(item)


## 指定グループをツリー上で選択状態にする
##
## @param group_id: 選択するグループ ID (String)
func select_group(group_id: String) -> void:
	if not _group_items.has(group_id):
		return

	var item: TreeItem = _group_items[group_id]
	item.select(0)
	_tree.scroll_to_item(item)


# --- Private Functions: UI Construction ---

## UI 要素を構築する
func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(vbox)

	# タイトル
	var title: Label = Label.new()
	title.text = "Hierarchy"
	vbox.add_child(title)

	# 検索バー
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search nodes..."
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_text_changed)
	vbox.add_child(_search_edit)

	# グループ操作ボタンバー
	_group_buttons_bar = HBoxContainer.new()

	var btn_add_group: Button = Button.new()
	btn_add_group.text = "+ Group"
	btn_add_group.pressed.connect(_on_add_group_pressed)
	_group_buttons_bar.add_child(btn_add_group)

	var btn_del_group: Button = Button.new()
	btn_del_group.text = "- Group"
	btn_del_group.pressed.connect(_on_delete_group_pressed)
	_group_buttons_bar.add_child(btn_del_group)

	vbox.add_child(_group_buttons_bar)

	# フィルタ遅延タイマー
	_filter_timer = Timer.new()
	_filter_timer.one_shot = true
	_filter_timer.wait_time = FILTER_DELAY_SEC
	_filter_timer.timeout.connect(_on_filter_timer_timeout)
	add_child(_filter_timer)

	# Tree コントロール
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.item_selected.connect(_on_tree_item_selected)
	vbox.add_child(_tree)


# --- Private Functions: Tree Construction ---

## ツリーを全再構築する
func _rebuild_tree() -> void:
	if _tree == null:
		return

	_tree.clear()
	_group_items.clear()
	_node_items.clear()

	if _model == null:
		return

	var root: TreeItem = _tree.create_item()

	# 既知グループの ID を収集
	var known_group_ids: Array = []
	var groups: Array = _model.get_all_groups()
	for group: Dictionary in groups:
		var group_id: String = group.get("id", "")
		known_group_ids.append(group_id)

		var nodes: Array = _model.get_nodes_by_group(group_id)
		var filtered_nodes: Array = _filter_nodes(nodes)

		# フィルタ中で該当ノードがなければグループをスキップ
		if not _filter_text.is_empty() and filtered_nodes.size() == 0:
			continue

		_add_group_to_tree(root, group_id, nodes, filtered_nodes)

	# グループに属さないノードを処理
	_add_ungrouped_nodes(root, known_group_ids)


## グループとそのノードをツリーに追加する
##
## @param root: ルート TreeItem (TreeItem)
## @param group_id: グループ ID (String)
## @param all_nodes: グループ内の全ノード (Array)
## @param filtered_nodes: フィルタ後のノード (Array)
func _add_group_to_tree(root: TreeItem, group_id: String,
		all_nodes: Array, filtered_nodes: Array) -> void:
	var group_item: TreeItem = _tree.create_item(root)
	group_item.set_text(0, "%s (%d)" % [group_id, all_nodes.size()])
	group_item.set_metadata(0, {"type": "group", "id": group_id})
	_group_items[group_id] = group_item

	var display_nodes: Array = filtered_nodes if not _filter_text.is_empty() else all_nodes
	for node: Dictionary in display_nodes:
		_add_node_to_tree(group_item, node)


## ノードをツリーに追加する
##
## @param parent_item: 親 TreeItem (TreeItem)
## @param node: ノードデータ (Dictionary)
func _add_node_to_tree(parent_item: TreeItem, node: Dictionary) -> void:
	var node_id: String = node.get("id", "")
	var name_key: String = node.get("name_key", node_id)
	var label: String = name_key
	if label.length() > MAX_DISPLAY_NAME_LENGTH:
		label = node_id

	var node_item: TreeItem = _tree.create_item(parent_item)
	node_item.set_text(0, label)
	node_item.set_metadata(0, {"type": "node", "id": node_id})
	_node_items[node_id] = node_item


## グループに属さないノードをツリーに追加する
##
## @param root: ルート TreeItem (TreeItem)
## @param known_group_ids: 既知のグループ ID 配列 (Array)
func _add_ungrouped_nodes(root: TreeItem, known_group_ids: Array) -> void:
	var ungrouped: Array = []
	for node: Dictionary in _model.get_all_nodes():
		var gid: String = node.get("group_id", "")
		if not known_group_ids.has(gid):
			ungrouped.append(node)

	if ungrouped.size() == 0:
		return

	var filtered: Array = _filter_nodes(ungrouped)
	if not _filter_text.is_empty() and filtered.size() == 0:
		return

	var ungrouped_item: TreeItem = _tree.create_item(root)
	ungrouped_item.set_text(0, "(ungrouped) (%d)" % ungrouped.size())
	ungrouped_item.set_metadata(0, {"type": "group", "id": ""})

	var display: Array = filtered if not _filter_text.is_empty() else ungrouped
	for node: Dictionary in display:
		_add_node_to_tree(ungrouped_item, node)


## フィルタ条件に合致するノードを抽出する
##
## @param nodes: 対象ノード配列 (Array)
## @return: フィルタ後のノード配列
func _filter_nodes(nodes: Array) -> Array:
	if _filter_text.is_empty():
		return nodes

	var result: Array = []
	for node: Dictionary in nodes:
		var node_id: String = node.get("id", "").to_lower()
		var name_key: String = node.get("name_key", "").to_lower()
		if node_id.contains(_filter_text) or name_key.contains(_filter_text):
			result.append(node)
	return result


# --- Signal Callbacks ---

## Tree アイテム選択時
func _on_tree_item_selected() -> void:
	if _syncing_selection:
		return

	var selected_item: TreeItem = _tree.get_selected()
	if selected_item == null:
		return

	var meta: Variant = selected_item.get_metadata(0)
	if meta == null or not meta is Dictionary:
		return

	var item_type: String = meta.get("type", "")
	var item_id: String = meta.get("id", "")

	_syncing_selection = true

	if item_type == "node":
		if _selection != null:
			_selection.select_node(item_id)
		node_selected_in_hierarchy.emit(item_id)
	elif item_type == "group" and not item_id.is_empty():
		if _selection != null:
			_selection.select_group(item_id)
		group_selected_in_hierarchy.emit(item_id)

	_syncing_selection = false


## 検索テキスト変更時（遅延フィルタ起動）
##
## @param _new_text: 新しいテキスト (String)（タイマー経由で処理）
func _on_search_text_changed(_new_text: String) -> void:
	_filter_timer.stop()
	_filter_timer.start()


## フィルタ遅延タイマー完了時
func _on_filter_timer_timeout() -> void:
	search(_search_edit.text)


## モデル変更時
func _on_model_changed() -> void:
	_rebuild_tree()


## ノード追加時
##
## @param _node_id: 追加されたノード ID (String)
func _on_node_added(_node_id: String) -> void:
	_rebuild_tree()


## ノード削除時
##
## @param _node_id: 削除されたノード ID (String)
func _on_node_removed(_node_id: String) -> void:
	_rebuild_tree()


## ノード更新時（名前変更等を反映）
##
## @param _node_id: 更新されたノード ID (String)
func _on_node_updated(_node_id: String) -> void:
	_rebuild_tree()


## グループ追加ボタン押下
func _on_add_group_pressed() -> void:
	group_add_requested.emit()


## グループ削除ボタン押下（選択中のグループを対象とする）
func _on_delete_group_pressed() -> void:
	var selected_item: TreeItem = _tree.get_selected()
	if selected_item == null:
		return

	var meta: Variant = selected_item.get_metadata(0)
	if meta == null or not meta is Dictionary:
		return

	var item_type: String = meta.get("type", "")
	var item_id: String = meta.get("id", "")

	if item_type != "group" or item_id.is_empty():
		return

	group_delete_requested.emit(item_id)


## グループ追加・削除時
##
## @param _group_id: 変更されたグループ ID (String)
func _on_group_changed(_group_id: String) -> void:
	_rebuild_tree()


## 外部からの選択変更時（CanvasView での選択を Hierarchy に反映）
##
## @param selection_type: 選択種別の文字列 (String)
## @param selection_id: 選択対象の ID (String)
func _on_external_selection_changed(selection_type: String, selection_id: String) -> void:
	if _syncing_selection:
		return

	_syncing_selection = true

	if selection_type == "node":
		select(selection_id)
	elif selection_type == "group":
		select_group(selection_id)

	_syncing_selection = false
