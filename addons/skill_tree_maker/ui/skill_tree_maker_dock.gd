@tool
class_name SkillTreeMakerDock
extends Control

## SkillTreeMaker のメインドック UI
##
## Model / View / Service を統合し、ユーザー操作を橋渡しする。
## ツールバー、HierarchyPanel、CanvasView、InspectorPanel、ステータスバーを含む。


# --- Constants ---

## デフォルトの Pack 出力ディレクトリ
const DEFAULT_PACKS_DIR: String = "res://SkillTreePacks"

## ドック名
const DOCK_NAME: String = "SkillTreeMaker"

## ファイルダイアログの表示比率
const FILE_DIALOG_RATIO: float = 0.6


# --- Private Variables ---

## 現在のスキルツリーモデル
var _model: SkillTreeModel = null

## 選択状態モデル
var _selection: SelectionModel = null

## エディタ状態
var _tool_state: ToolState = null

## Pack のファイル I/O サービス
var _pack_repository: PackRepository = null

## テーマ解決サービス
var _theme_resolver: ThemeResolver = null

## 検証サービス
var _validator: Validator = null

## ランタイムエクスポーター
var _runtime_exporter: RuntimeExporter = null

## 現在開いている Pack のルートパス
var _current_pack_root: String = ""

## キャンバスビュー
var _canvas_view: CanvasView = null

## 階層パネル
var _hierarchy_panel: HierarchyPanel = null

## インスペクタパネル
var _inspector_panel: InspectorPanel = null

## ツールバーコンテナ
var _toolbar: HBoxContainer = null

## ステータスラベル
var _status_label: Label = null

## Pack 作成ダイアログ
var _pack_creation_dialog: PackCreationDialog = null

## コンテキストメニュー
var _context_menu: CanvasContextMenu = null

## Pack オープン用 EditorFileDialog
var _open_pack_dialog: EditorFileDialog = null

## グリッド表示 CheckButton
var _btn_grid: CheckButton = null

## スナップ CheckButton
var _btn_snap: CheckButton = null

## グループ名入力ダイアログ
var _group_name_dialog: GroupNameDialog = null

## プレビューモードか
var _is_preview_mode: bool = false

## プレビュー用ビューア
var _preview_viewer: SkillTreeViewer = null

## プレビューボタン
var _btn_preview: Button = null

## メインコンテンツの HSplitContainer
var _hsplit: HSplitContainer = null

## プレビュー中に無効化する編集系ボタン群
var _toolbar_edit_buttons: Array[BaseButton] = []


# --- Built-in Functions ---

## ドック初期化。サービスのインスタンス化と UI 構築を行う
func _ready() -> void:
	_pack_repository = PackRepository.new()
	_selection = SelectionModel.new()
	_tool_state = ToolState.new()
	_theme_resolver = ThemeResolver.new()
	_validator = Validator.new()
	_runtime_exporter = RuntimeExporter.new()
	_runtime_exporter.setup(_theme_resolver, _validator)

	_build_ui()
	_set_status("Ready")


# --- Public Functions ---

## 新しい Pack を作成する
##
## @param pack_id: Pack の識別子 (String)
## @param pack_name: Pack の表示名 (String)
## @param out_dir: 出力先ディレクトリ (String)。空なら DEFAULT_PACKS_DIR/<pack_id>
func new_pack(pack_id: String, pack_name: String, out_dir: String = "") -> void:
	if pack_id.is_empty():
		push_error("[SkillTreeMakerDock] new_pack: pack_id is empty")
		_set_status("Error: Pack ID is empty")
		return

	var pack_root: String = out_dir
	if pack_root.is_empty():
		pack_root = DEFAULT_PACKS_DIR.path_join(pack_id)

	if _pack_repository.pack_exists(pack_root):
		push_warning("[SkillTreeMakerDock] new_pack: pack already exists: " + pack_root)
		_set_status("Pack already exists: " + pack_root)
		return

	_model = _pack_repository.create_pack(pack_root, pack_id, pack_name)
	if _model == null:
		_set_status("Error: Failed to create pack")
		return

	_current_pack_root = pack_root
	_tool_state = _resolve_tool_state(_model)
	_selection.clear()
	_bind_all_panels()
	_set_status("Created: " + pack_name)


## 既存の Pack を開く
##
## @param pack_root: Pack ルートディレクトリのパス (String)
func open_pack(pack_root: String) -> void:
	if pack_root.is_empty():
		push_error("[SkillTreeMakerDock] open_pack: pack_root is empty")
		_set_status("Error: Pack root is empty")
		return

	_model = _pack_repository.load_pack(pack_root)
	if _model == null:
		_set_status("Error: Failed to load pack")
		return

	_current_pack_root = pack_root
	_tool_state = _resolve_tool_state(_model)
	_selection.clear()
	_bind_all_panels()

	var pack_name: String = _model.pack_meta.get("name", pack_root)
	_set_status("Opened: " + pack_name)


## 現在の Pack を保存する
func save_pack() -> void:
	if _model == null or _current_pack_root.is_empty():
		_set_status("Nothing to save")
		return

	# ToolState をモデルに反映
	_model.tool_state = _tool_state

	var success: bool = _pack_repository.save_pack(_model, _current_pack_root)

	# テーマが読み込まれていれば保存
	if _theme_resolver.is_loaded():
		var theme_path: String = _current_pack_root.path_join(
			_model.paths.get("theme", "theme/theme.json"))
		var theme_ok: bool = _theme_resolver.save_theme(theme_path)
		if not theme_ok:
			push_warning("[SkillTreeMakerDock] save_pack: Failed to save theme: " + theme_path)

	if success:
		_set_status("Saved")
	else:
		_set_status("Error: Failed to save pack")


## 現在の Pack を閉じる
func close_pack() -> void:
	_model = null
	_current_pack_root = ""
	if _selection != null:
		_selection.clear()
	if _tool_state != null:
		_tool_state.reset()
	if _canvas_view != null:
		_canvas_view.set_model(null, null, null)
	if _hierarchy_panel != null:
		_hierarchy_panel.set_model(null, null)
	if _inspector_panel != null:
		_inspector_panel.unbind()
	_set_status("Ready")


## 現在の Pack ルートパスを取得する
##
## @return: 現在の Pack ルートパス。未開封なら空文字列
func get_current_pack_root() -> String:
	return _current_pack_root


# --- Private Functions: UI Construction ---

## UI を構築する
func _build_ui() -> void:
	name = DOCK_NAME

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(vbox)

	# ツールバー
	_toolbar = _build_toolbar()
	vbox.add_child(_toolbar)

	# メインコンテンツ: HSplitContainer（3パネル）
	_hsplit = HSplitContainer.new()
	_hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_hsplit)

	# 左: HierarchyPanel
	_hierarchy_panel = HierarchyPanel.new()
	_hsplit.add_child(_hierarchy_panel)

	# 中央: CanvasView
	_canvas_view = CanvasView.new()
	_canvas_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hsplit.add_child(_canvas_view)

	# 右: InspectorPanel
	_inspector_panel = InspectorPanel.new()
	_hsplit.add_child(_inspector_panel)

	# プレビュー用ビューア（初期は非表示、ツリーに追加しない）
	_preview_viewer = SkillTreeViewer.new()
	_preview_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# シグナル接続: CanvasView
	_canvas_view.node_create_requested.connect(_on_node_create_requested)
	_canvas_view.node_selected.connect(_on_node_selected)
	_canvas_view.edge_selected.connect(_on_edge_selected)
	_canvas_view.selection_cleared.connect(_on_selection_cleared)
	_canvas_view.node_moved.connect(_on_node_moved)
	_canvas_view.edge_create_requested.connect(_on_edge_create_requested)
	_canvas_view.delete_requested.connect(_on_delete_requested)
	_canvas_view.save_requested.connect(_on_save_pressed)
	_canvas_view.context_menu_requested.connect(_on_context_menu_requested)

	# シグナル接続: HierarchyPanel
	_hierarchy_panel.node_selected_in_hierarchy.connect(_on_hierarchy_node_selected)
	_hierarchy_panel.group_selected_in_hierarchy.connect(_on_hierarchy_group_selected)

	# Pack 作成ダイアログ
	_pack_creation_dialog = PackCreationDialog.new()
	_pack_creation_dialog.pack_confirmed.connect(_on_pack_creation_confirmed)
	add_child(_pack_creation_dialog)

	# Pack オープンダイアログ
	_open_pack_dialog = EditorFileDialog.new()
	_open_pack_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_open_pack_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_pack_dialog.title = "Open Pack Folder"
	_open_pack_dialog.dir_selected.connect(_on_open_pack_dir_selected)
	add_child(_open_pack_dialog)

	# コンテキストメニュー
	_context_menu = CanvasContextMenu.new()
	_context_menu.create_node_at.connect(_on_node_create_requested)
	_context_menu.delete_node.connect(_on_context_delete_node)
	_context_menu.delete_edge.connect(_on_context_delete_edge)
	_context_menu.connect_from.connect(_on_context_connect_from)
	add_child(_context_menu)

	# グループ名ダイアログ
	_group_name_dialog = GroupNameDialog.new()
	_group_name_dialog.group_name_confirmed.connect(_on_group_name_confirmed)
	add_child(_group_name_dialog)

	# シグナル接続: HierarchyPanel（グループ管理）
	_hierarchy_panel.group_add_requested.connect(_on_group_add_requested)
	_hierarchy_panel.group_delete_requested.connect(_on_group_delete_requested)

	# ステータスバー
	var status_bar: PanelContainer = PanelContainer.new()
	vbox.add_child(status_bar)

	_status_label = Label.new()
	_status_label.text = "Ready"
	status_bar.add_child(_status_label)


## ツールバーを構築する
##
## @return: ツールバーの HBoxContainer
func _build_toolbar() -> HBoxContainer:
	var toolbar: HBoxContainer = HBoxContainer.new()

	var btn_new: Button = Button.new()
	btn_new.text = "New Pack"
	btn_new.pressed.connect(_on_new_pack_pressed)
	toolbar.add_child(btn_new)

	var btn_open: Button = Button.new()
	btn_open.text = "Open Pack"
	btn_open.pressed.connect(_on_open_pack_pressed)
	toolbar.add_child(btn_open)

	var btn_save: Button = Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(_on_save_pressed)
	toolbar.add_child(btn_save)

	var btn_validate: Button = Button.new()
	btn_validate.text = "Validate"
	btn_validate.pressed.connect(_on_validate_pressed)
	toolbar.add_child(btn_validate)

	var btn_export: Button = Button.new()
	btn_export.text = "Export"
	btn_export.pressed.connect(_on_export_pressed)
	toolbar.add_child(btn_export)

	# Preview ボタン
	var separator_preview: VSeparator = VSeparator.new()
	toolbar.add_child(separator_preview)

	_btn_preview = Button.new()
	_btn_preview.text = "Preview"
	_btn_preview.pressed.connect(_on_preview_pressed)
	toolbar.add_child(_btn_preview)

	# スペーサー
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	# Grid/Snap コントロール
	var separator: VSeparator = VSeparator.new()
	toolbar.add_child(separator)

	_btn_grid = CheckButton.new()
	_btn_grid.text = "Grid"
	_btn_grid.button_pressed = true
	_btn_grid.toggled.connect(_on_grid_toggled)
	toolbar.add_child(_btn_grid)

	_btn_snap = CheckButton.new()
	_btn_snap.text = "Snap"
	_btn_snap.button_pressed = true
	_btn_snap.toggled.connect(_on_snap_toggled)
	toolbar.add_child(_btn_snap)

	var separator2: VSeparator = VSeparator.new()
	toolbar.add_child(separator2)

	var btn_zoom_reset: Button = Button.new()
	btn_zoom_reset.text = "1:1"
	btn_zoom_reset.pressed.connect(_on_zoom_reset_pressed)
	toolbar.add_child(btn_zoom_reset)

	# プレビュー中に無効化する編集系ボタン群
	_toolbar_edit_buttons = [btn_new, btn_open, btn_save, btn_validate, btn_export, _btn_grid, _btn_snap, btn_zoom_reset]

	return toolbar


# --- Private Functions: Helpers ---

## 全パネルにモデルをバインドする
func _bind_all_panels() -> void:
	_canvas_view.set_model(_model, _selection, _tool_state)
	_hierarchy_panel.set_model(_model, _selection)
	_inspector_panel.bind_selection(_model, _selection)

	# テーマ読み込みとインスペクタへの参照設定
	_inspector_panel.bind_theme_resolver(_theme_resolver)
	if _model != null and not _current_pack_root.is_empty():
		var theme_path: String = _current_pack_root.path_join(
			_model.paths.get("theme", "theme/theme.json"))
		_theme_resolver.load_theme(theme_path)

	_sync_toolbar_to_tool_state()


## モデルから ToolState を取得する（null の場合は新規作成）
##
## @param model: SkillTreeModel (SkillTreeModel)
## @return: モデルの ToolState、または新規 ToolState
func _resolve_tool_state(model: SkillTreeModel) -> ToolState:
	if model != null and model.tool_state != null:
		return model.tool_state
	return ToolState.new()


## ToolState の状態をツールバーのコントロールに反映する
func _sync_toolbar_to_tool_state() -> void:
	if _tool_state == null:
		return
	if _btn_grid != null:
		_btn_grid.button_pressed = _tool_state.grid_enabled
	if _btn_snap != null:
		_btn_snap.button_pressed = _tool_state.snap_enabled


## 選択中のノードまたはエッジを削除する
func _delete_selected() -> void:
	if _model == null or _selection == null:
		return

	if _selection.is_node_selected():
		var node_id: String = _selection.selected_id
		_model.remove_node(node_id)
		_selection.clear()
		_set_status("Deleted node: " + node_id)

	elif _selection.is_edge_selected():
		var edge_key: String = _selection.selected_id
		var parts: PackedStringArray = edge_key.split("->")
		if parts.size() != 2:
			push_error("[SkillTreeMakerDock] _delete_selected: invalid edge_key: " + edge_key)
			return
		_model.remove_edge(parts[0], parts[1])
		_selection.clear()
		_set_status("Deleted edge: " + edge_key)


# --- Private Functions: Status ---

## ステータスバーのテキストを更新する
##
## @param text: 表示するテキスト (String)
func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


# --- Signal Callbacks ---

## キャンバスからノード作成リクエスト
##
## @param canvas_pos: ワールド座標上の位置 (Vector2)
func _on_node_create_requested(canvas_pos: Vector2) -> void:
	if _model == null:
		_set_status("Open or create a pack first")
		return

	var node: Dictionary = _model.create_node(canvas_pos)
	var node_id: String = node.get("id", "")
	if node_id.is_empty():
		_set_status("Error: Failed to create node")
		return
	_selection.select_node(node_id)
	_set_status("Node created: " + node_id)


## ノード選択
##
## @param node_id: 選択されたノード ID (String)
func _on_node_selected(node_id: String) -> void:
	_set_status("Selected: " + node_id)


## エッジ選択
##
## @param edge_key: 選択されたエッジキー (String)
func _on_edge_selected(edge_key: String) -> void:
	_set_status("Selected edge: " + edge_key)


## 選択クリア
func _on_selection_cleared() -> void:
	_set_status("Selection cleared")


## ノード移動完了
##
## @param node_id: 移動したノードの ID (String)
## @param new_pos: 移動後のワールド座標 (Vector2)
func _on_node_moved(node_id: String, new_pos: Vector2) -> void:
	_set_status("Moved: " + node_id + " -> (%d, %d)" % [int(new_pos.x), int(new_pos.y)])


## エッジ作成リクエスト
##
## @param from_id: 始点ノード ID (String)
## @param to_id: 終点ノード ID (String)
func _on_edge_create_requested(from_id: String, to_id: String) -> void:
	if _model == null:
		return

	var success: bool = _model.add_edge(from_id, to_id)
	if success:
		_selection.select_edge(from_id + "->" + to_id)
		_set_status("Edge created: " + from_id + " -> " + to_id)
	else:
		_set_status("Failed to create edge")


## 削除リクエスト（Delete キー）
func _on_delete_requested() -> void:
	_delete_selected()


## HierarchyPanel でノード選択時
##
## @param node_id: 選択されたノード ID (String)
func _on_hierarchy_node_selected(node_id: String) -> void:
	_canvas_view.focus(node_id)
	_set_status("Selected: " + node_id)


## HierarchyPanel でグループ選択時
##
## @param group_id: 選択されたグループ ID (String)
func _on_hierarchy_group_selected(group_id: String) -> void:
	_set_status("Group selected: " + group_id)


## コンテキストメニュー表示リクエスト
##
## @param context_type: コンテキスト種別 ("canvas" / "node" / "edge") (String)
## @param context_id: 対象 ID (String)
## @param world_pos: ワールド座標 (Vector2)
## @param screen_pos: 画面座標 (Vector2)
func _on_context_menu_requested(context_type: String, context_id: String,
		world_pos: Vector2, screen_pos: Vector2) -> void:
	var pos: Vector2i = Vector2i(int(screen_pos.x), int(screen_pos.y))
	match context_type:
		"canvas":
			_context_menu.show_canvas_menu(world_pos, pos)
		"node":
			_context_menu.show_node_menu(context_id, pos)
		"edge":
			_context_menu.show_edge_menu(context_id, pos)


## コンテキストメニューからノード削除
##
## @param node_id: 削除するノード ID (String)
func _on_context_delete_node(node_id: String) -> void:
	if _model == null:
		return
	_model.remove_node(node_id)
	_selection.clear()
	_set_status("Deleted node: " + node_id)


## コンテキストメニューからエッジ削除
##
## @param edge_key: 削除するエッジキー (String)
func _on_context_delete_edge(edge_key: String) -> void:
	if _model == null:
		return
	var parts: PackedStringArray = edge_key.split("->")
	if parts.size() != 2:
		push_error("[SkillTreeMakerDock] _on_context_delete_edge: invalid edge_key: " + edge_key)
		return
	_model.remove_edge(parts[0], parts[1])
	_selection.clear()
	_set_status("Deleted edge: " + edge_key)


## コンテキストメニューから接続開始
##
## @param node_id: 始点ノード ID (String)
func _on_context_connect_from(node_id: String) -> void:
	_canvas_view.start_connect_mode(node_id)
	_set_status("Connect mode: click target node (Escape to cancel)")


## Pack 作成ダイアログからの確認
##
## @param pack_id: Pack ID (String)
## @param pack_name: Pack 名 (String)
## @param out_dir: 出力ディレクトリ (String)
func _on_pack_creation_confirmed(pack_id: String, pack_name: String, out_dir: String) -> void:
	new_pack(pack_id, pack_name, out_dir)


## New Pack ボタン押下
func _on_new_pack_pressed() -> void:
	_pack_creation_dialog.show_dialog()


## Open Pack ボタン押下
func _on_open_pack_pressed() -> void:
	_open_pack_dialog.popup_centered_ratio(FILE_DIALOG_RATIO)


## Pack オープンダイアログでディレクトリ選択時
##
## @param dir_path: 選択されたディレクトリパス (String)
func _on_open_pack_dir_selected(dir_path: String) -> void:
	open_pack(dir_path)


## Save ボタン押下
func _on_save_pressed() -> void:
	save_pack()


## Validate ボタン押下
func _on_validate_pressed() -> void:
	if _model == null:
		_set_status("Open or create a pack first")
		return

	var report: Validator.ValidationReport = _validator.validate(_model)

	if report.has_errors():
		_set_status("Validation FAILED: %d error(s), %d warning(s)"
			% [report.errors.size(), report.warnings.size()])
	elif report.has_warnings():
		_set_status("Validation OK with %d warning(s)" % report.warnings.size())
	else:
		_set_status("Validation passed")


## Export ボタン押下
func _on_export_pressed() -> void:
	if _model == null or _current_pack_root.is_empty():
		_set_status("Open or create a pack first")
		return

	# 先に保存
	save_pack()

	# runtime.json 書き出し
	var report: Validator.ValidationReport = _runtime_exporter.write_runtime(
		_current_pack_root, _model)

	if report.has_errors():
		var first_error: String = report.errors[0].get("message", "Unknown error")
		_set_status("Export FAILED: " + first_error)
		return

	# アセットコピー
	var copied: int = _runtime_exporter.copy_assets(_current_pack_root, _model)
	_set_status("Exported runtime.json (%d assets copied)" % copied)


## グリッド表示トグル
##
## @param pressed: 新しい状態 (bool)
func _on_grid_toggled(pressed: bool) -> void:
	if _tool_state != null:
		_tool_state.set_grid_enabled(pressed)


## スナップトグル
##
## @param pressed: 新しい状態 (bool)
func _on_snap_toggled(pressed: bool) -> void:
	if _tool_state != null:
		_tool_state.set_snap_enabled(pressed)


## ズームリセットボタン押下
func _on_zoom_reset_pressed() -> void:
	if _tool_state != null:
		_tool_state.set_camera_zoom(ToolState.DEFAULT_ZOOM)
		_tool_state.set_camera_pos(Vector2.ZERO)


## HierarchyPanel からグループ追加リクエスト
func _on_group_add_requested() -> void:
	if _model == null:
		_set_status("Open or create a pack first")
		return
	_group_name_dialog.show_dialog()


## HierarchyPanel からグループ削除リクエスト
##
## @param group_id: 削除するグループ ID (String)
func _on_group_delete_requested(group_id: String) -> void:
	if _model == null:
		return
	var success: bool = _model.remove_group(group_id)
	if success:
		_selection.clear()
		_set_status("Deleted group: " + group_id)
	else:
		_set_status("Error: Could not delete group: " + group_id)


## グループ名ダイアログからグループ ID 確定
##
## @param group_id: 入力されたグループ ID (String)
func _on_group_name_confirmed(group_id: String) -> void:
	if _model == null:
		return
	var success: bool = _model.add_group(group_id, Vector2.ZERO)
	if success:
		_selection.select_group(group_id)
		_set_status("Group created: " + group_id)
	else:
		_set_status("Error: Group already exists: " + group_id)


## Preview ボタン押下
func _on_preview_pressed() -> void:
	if _is_preview_mode:
		_exit_preview_mode()
	else:
		_enter_preview_mode()


# --- Private Functions: Preview Mode ---

## プレビューモードに入る
##
## ランタイムデータをインメモリで構築し、CanvasView を SkillTreeViewer に差し替える。
func _enter_preview_mode() -> void:
	if _model == null or _current_pack_root.is_empty():
		_set_status("Open or create a pack first")
		return

	# ランタイムデータをインメモリで構築
	var runtime_data: Dictionary = _runtime_exporter.build_runtime(_model)
	if runtime_data.is_empty():
		_set_status("Preview error: failed to build runtime data")
		return

	# テーマデータを取得
	var theme_data: Dictionary = _theme_resolver.get_theme_data()

	# SkillTreeViewer にデータをロード
	var success: bool = _preview_viewer.load_pack_from_data(runtime_data, theme_data)
	if not success:
		_set_status("Preview error: failed to initialize viewer")
		return

	_is_preview_mode = true

	# 中央パネルを CanvasView → SkillTreeViewer に差し替え
	var canvas_index: int = _canvas_view.get_index()
	_hsplit.remove_child(_canvas_view)
	_hsplit.add_child(_preview_viewer)
	_hsplit.move_child(_preview_viewer, canvas_index)

	# ボタン状態を更新
	_btn_preview.text = "Edit"
	_set_toolbar_edit_enabled(false)

	_set_status("Preview Mode: double-click to unlock nodes")


## プレビューモードを終了する
##
## SkillTreeViewer を CanvasView に戻す。
func _exit_preview_mode() -> void:
	_is_preview_mode = false

	# 中央パネルを SkillTreeViewer → CanvasView に差し替え
	var preview_index: int = _preview_viewer.get_index()
	_hsplit.remove_child(_preview_viewer)
	_hsplit.add_child(_canvas_view)
	_hsplit.move_child(_canvas_view, preview_index)

	# ボタン状態を復帰
	_btn_preview.text = "Preview"
	_set_toolbar_edit_enabled(true)

	_set_status("Edit Mode")


## 編集系ツールバーボタンの有効/無効を一括設定する
##
## @param enabled: 有効にするなら true (bool)
func _set_toolbar_edit_enabled(enabled: bool) -> void:
	for btn: BaseButton in _toolbar_edit_buttons:
		btn.disabled = not enabled
