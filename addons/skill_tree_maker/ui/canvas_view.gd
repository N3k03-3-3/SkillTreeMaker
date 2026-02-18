@tool
class_name CanvasView
extends Control

## スキルツリーのグラフエディタキャンバス
##
## パン・ズーム、グリッド描画、ノード・エッジの描画と選択を担当する。
## SkillTreeModel のデータを可視化し、ユーザー操作をモデルに反映する。


# --- Signals ---

## ノード作成がリクエストされたとき（キャンバス上の位置）
signal node_create_requested(canvas_pos: Vector2)

## ノードが選択されたとき
signal node_selected(node_id: String)

## エッジが選択されたとき
signal edge_selected(edge_key: String)

## 選択がクリアされたとき（空白クリック）
signal selection_cleared()

## ノードがドラッグ移動されたとき
signal node_moved(node_id: String, new_pos: Vector2)

## ノード接続がリクエストされたとき
signal edge_create_requested(from_node_id: String, to_node_id: String)

## 選択中アイテムの削除がリクエストされたとき
signal delete_requested()

## 保存がリクエストされたとき（Ctrl+S）
signal save_requested()

## 右クリックコンテキストメニューがリクエストされたとき
signal context_menu_requested(context_type: String, context_id: String, world_pos: Vector2, screen_pos: Vector2)


# --- Constants ---

## ノードの描画サイズ（ピクセル）
const NODE_SIZE: Vector2 = Vector2(120, 48)

## ノードの角丸半径
const NODE_CORNER_RADIUS: float = 6.0

## エッジの線幅
const EDGE_WIDTH: float = 2.0

## エッジの当たり判定幅
const EDGE_HIT_WIDTH: float = 10.0

## グリッドラインの色
const GRID_COLOR: Color = Color(0.3, 0.3, 0.3, 0.3)

## グリッド太線の色（原点交差等）
const GRID_MAJOR_COLOR: Color = Color(0.4, 0.4, 0.4, 0.5)

## ノードの背景色（通常）
const NODE_COLOR: Color = Color(0.2, 0.25, 0.35, 1.0)

## ノードの背景色（選択中）
const NODE_SELECTED_COLOR: Color = Color(0.3, 0.4, 0.6, 1.0)

## ノードの枠色
const NODE_BORDER_COLOR: Color = Color(0.5, 0.6, 0.8, 1.0)

## ノードの選択枠色
const NODE_SELECTED_BORDER_COLOR: Color = Color(0.6, 0.8, 1.0, 1.0)

## エッジの色
const EDGE_COLOR: Color = Color(0.5, 0.6, 0.7, 0.8)

## エッジ作成中の仮線の色
const EDGE_PREVIEW_COLOR: Color = Color(0.4, 0.8, 1.0, 0.6)

## エッジ作成中の仮線の幅
const EDGE_PREVIEW_WIDTH: float = 2.0

## キャンバス背景色
const BG_COLOR: Color = Color(0.12, 0.13, 0.16, 1.0)

## パン速度係数
const PAN_SPEED: float = 1.0

## ズームステップ（ホイール1クリックあたり）
const ZOOM_STEP: float = 0.1

## グリッド太線の間隔（グリッドサイズの何倍か）
const GRID_MAJOR_INTERVAL: int = 5

## グリッドが表示される最小ピクセルサイズ
const GRID_MIN_VISIBLE_SIZE: float = 4.0

## ノードのラベル最大文字数（超過時は ID 表示）
const MAX_LABEL_LENGTH: int = 20

## ノードのフォントサイズ基準値（ピクセル）
const BASE_FONT_SIZE: float = 12.0

## フォント描画の最小サイズ（これ未満なら描画しない）
const MIN_FONT_SIZE: int = 6

## ノードの枠線幅
const NODE_BORDER_WIDTH: float = 2.0

## 線分ヒットテスト用の長さ二乗の最小閾値
const SEGMENT_LENGTH_SQ_EPSILON: float = 0.001


# --- Private Variables ---

## 参照する SkillTreeModel
var _model: SkillTreeModel = null

## 参照する SelectionModel
var _selection: SelectionModel = null

## 参照する ToolState
var _tool_state: ToolState = null

## パン操作中か
var _is_panning: bool = false

## パン操作の開始マウス位置
var _pan_start_mouse: Vector2 = Vector2.ZERO

## パン操作開始時のカメラ位置
var _pan_start_camera: Vector2 = Vector2.ZERO

## ドラッグ中のノード ID（空なら未ドラッグ）
var _dragging_node_id: String = ""

## ドラッグ開始時のノード位置
var _drag_start_node_pos: Vector2 = Vector2.ZERO

## ドラッグ開始時のマウス位置
var _drag_start_mouse: Vector2 = Vector2.ZERO

## エッジ作成ドラッグ中か
var _is_edge_dragging: bool = false

## エッジ作成の始点ノード ID
var _edge_drag_source_id: String = ""

## エッジ作成ドラッグ中のマウス位置（キャンバス座標）
var _edge_drag_mouse_pos: Vector2 = Vector2.ZERO

## コンテキストメニューからの接続モード中か
var _is_connect_mode: bool = false

## 接続モードの始点ノード ID
var _connect_source_id: String = ""


# --- Built-in Functions ---

## キャンバスの初期設定を行う（クリッピングとマウスフィルター）
func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


## キャンバス全体を再描画する（背景、グリッド、エッジ、ノード）
func _draw() -> void:
	# 背景
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	if _tool_state == null:
		return

	# グリッド
	if _tool_state.grid_enabled:
		_draw_grid()

	if _model == null:
		return

	# エッジ
	for edge: Dictionary in _model.get_all_edges():
		_draw_edge(edge)

	# エッジ作成プレビュー
	if _is_edge_dragging and not _edge_drag_source_id.is_empty():
		_draw_edge_preview()

	# ノード
	for node: Dictionary in _model.get_all_nodes():
		_draw_node(node)


## GUI 入力イベントを処理する
##
## @param event: 入力イベント (InputEvent)
func _gui_input(event: InputEvent) -> void:
	if _tool_state == null:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key_input(event as InputEventKey)


# --- Public Functions ---

## モデルを設定する
##
## @param model: SkillTreeModel (SkillTreeModel)
## @param selection: SelectionModel (SelectionModel)
## @param tool_state: ToolState (ToolState)
func set_model(model: SkillTreeModel, selection: SelectionModel, tool_state: ToolState) -> void:
	# 旧モデルのシグナル切断
	if _model != null:
		if _model.model_changed.is_connected(_on_model_changed):
			_model.model_changed.disconnect(_on_model_changed)

	_model = model
	_selection = selection
	_tool_state = tool_state

	# 新モデルのシグナル接続
	if _model != null:
		_model.model_changed.connect(_on_model_changed)

	if _tool_state != null:
		if not _tool_state.camera_changed.is_connected(_on_camera_changed):
			_tool_state.camera_changed.connect(_on_camera_changed)
		if not _tool_state.grid_changed.is_connected(_on_grid_changed):
			_tool_state.grid_changed.connect(_on_grid_changed)

	# エッジ作成状態をリセット
	_is_edge_dragging = false
	_edge_drag_source_id = ""
	_is_connect_mode = false
	_connect_source_id = ""

	queue_redraw()


## キャンバスを再描画する
func render() -> void:
	queue_redraw()


## 指定ノードにカメラをフォーカスする
##
## @param node_id: フォーカス先のノード ID (String)
func focus(node_id: String) -> void:
	if _model == null or _tool_state == null:
		return
	var node: Dictionary = _model.get_node(node_id)
	if node.is_empty():
		return
	var pos: Dictionary = node.get("pos", {})
	_tool_state.set_camera_pos(Vector2(pos.get("x", 0.0), pos.get("y", 0.0)))


## 接続モードを開始する（コンテキストメニュー用）
##
## @param source_node_id: 始点ノード ID (String)
func start_connect_mode(source_node_id: String) -> void:
	_is_connect_mode = true
	_connect_source_id = source_node_id


# --- Private Functions: Drawing ---

## グリッドを描画する
func _draw_grid() -> void:
	var gs: float = float(_tool_state.grid_size) * _tool_state.camera_zoom
	if gs < GRID_MIN_VISIBLE_SIZE:
		return

	var offset: Vector2 = _get_canvas_offset()

	# 描画範囲を計算
	var start_x: float = fmod(offset.x, gs)
	var start_y: float = fmod(offset.y, gs)
	var grid_index_offset_x: int = int(floor(-offset.x / gs))
	var grid_index_offset_y: int = int(floor(-offset.y / gs))

	# 縦線
	var x: float = start_x
	var index: int = 0
	while x < size.x:
		var grid_index: int = grid_index_offset_x + index
		var color: Color = GRID_MAJOR_COLOR if grid_index % GRID_MAJOR_INTERVAL == 0 else GRID_COLOR
		draw_line(Vector2(x, 0), Vector2(x, size.y), color)
		x += gs
		index += 1

	# 横線
	var y: float = start_y
	index = 0
	while y < size.y:
		var grid_index: int = grid_index_offset_y + index
		var color: Color = GRID_MAJOR_COLOR if grid_index % GRID_MAJOR_INTERVAL == 0 else GRID_COLOR
		draw_line(Vector2(0, y), Vector2(size.x, y), color)
		y += gs
		index += 1


## ノードを描画する
##
## @param node: ノードデータ (Dictionary)
func _draw_node(node: Dictionary) -> void:
	var node_id: String = node.get("id", "")
	var pos_data: Dictionary = node.get("pos", {})
	var canvas_pos: Vector2 = _world_to_canvas(Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))

	var rect: Rect2 = Rect2(canvas_pos - NODE_SIZE * _tool_state.camera_zoom * 0.5, NODE_SIZE * _tool_state.camera_zoom)

	# 選択状態判定
	var is_selected: bool = _selection != null and _selection.is_node_id_selected(node_id)
	var bg_color: Color = NODE_SELECTED_COLOR if is_selected else NODE_COLOR
	var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_BORDER_COLOR

	# 背景
	draw_rect(rect, bg_color, true)

	# 枠
	draw_rect(rect, border_color, false, NODE_BORDER_WIDTH)

	# ラベル（name_key を短縮表示）
	var label: String = node.get("name_key", node_id)
	# name_key が長い場合は ID のみ表示
	if label.length() > MAX_LABEL_LENGTH:
		label = node_id

	var font: Font = ThemeDB.fallback_font
	var font_size: int = int(BASE_FONT_SIZE * _tool_state.camera_zoom)
	if font_size < MIN_FONT_SIZE:
		return
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos: Vector2 = canvas_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.25)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## エッジを描画する
##
## @param edge: エッジデータ (Dictionary)
func _draw_edge(edge: Dictionary) -> void:
	var from_id: String = edge.get("from", "")
	var to_id: String = edge.get("to", "")

	var from_node: Dictionary = _model.get_node(from_id)
	var to_node: Dictionary = _model.get_node(to_id)
	if from_node.is_empty() or to_node.is_empty():
		return

	var from_pos_data: Dictionary = from_node.get("pos", {})
	var to_pos_data: Dictionary = to_node.get("pos", {})

	var from_canvas: Vector2 = _world_to_canvas(Vector2(from_pos_data.get("x", 0.0), from_pos_data.get("y", 0.0)))
	var to_canvas: Vector2 = _world_to_canvas(Vector2(to_pos_data.get("x", 0.0), to_pos_data.get("y", 0.0)))

	draw_line(from_canvas, to_canvas, EDGE_COLOR, EDGE_WIDTH * _tool_state.camera_zoom)


## エッジ作成中の仮接続線を描画する
func _draw_edge_preview() -> void:
	if _model == null:
		return

	var source_node: Dictionary = _model.get_node(_edge_drag_source_id)
	if source_node.is_empty():
		return

	var pos_data: Dictionary = source_node.get("pos", {})
	var from_canvas: Vector2 = _world_to_canvas(
		Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))

	var line_width: float = EDGE_PREVIEW_WIDTH
	if _tool_state != null:
		line_width *= _tool_state.camera_zoom

	draw_line(from_canvas, _edge_drag_mouse_pos, EDGE_PREVIEW_COLOR, line_width)


# --- Private Functions: Input Handling ---

## マウスボタン入力を処理する
##
## @param event: マウスボタンイベント (InputEventMouseButton)
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		# 中ボタン: パン
		if event.pressed:
			_is_panning = true
			_pan_start_mouse = event.position
			_pan_start_camera = _tool_state.camera_pos
		else:
			_is_panning = false

	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		# ホイール上: ズームイン
		_zoom(ZOOM_STEP, event.position)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		# ホイール下: ズームアウト
		_zoom(-ZOOM_STEP, event.position)

	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_left_click(event.position, event.shift_pressed)
		else:
			_handle_left_release(event.position)

	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_handle_right_click(event.position)


## マウス移動を処理する
##
## @param event: マウス移動イベント (InputEventMouseMotion)
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning and _tool_state != null:
		var delta: Vector2 = (event.position - _pan_start_mouse) / _tool_state.camera_zoom
		_tool_state.set_camera_pos(_pan_start_camera - delta)

	elif _is_edge_dragging:
		_edge_drag_mouse_pos = event.position
		queue_redraw()

	elif not _dragging_node_id.is_empty() and _model != null:
		var world_pos: Vector2 = _canvas_to_world(event.position)
		var delta_world: Vector2 = world_pos - _canvas_to_world(_drag_start_mouse)
		var new_pos: Vector2 = _drag_start_node_pos + delta_world
		if _tool_state != null and _tool_state.snap_enabled:
			new_pos = _tool_state.snap_position(new_pos)
		_model.update_node(_dragging_node_id, {"pos": {"x": new_pos.x, "y": new_pos.y}})
		queue_redraw()


## 左クリック処理
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
## @param shift_pressed: Shift キーが押されているか (bool)
func _handle_left_click(mouse_pos: Vector2, shift_pressed: bool) -> void:
	# ノードのヒットテスト
	var hit_node_id: String = _hit_test_node(mouse_pos)

	# 接続モード中（コンテキストメニュー経由）
	if _is_connect_mode and not hit_node_id.is_empty():
		if hit_node_id != _connect_source_id:
			edge_create_requested.emit(_connect_source_id, hit_node_id)
		_is_connect_mode = false
		_connect_source_id = ""
		queue_redraw()
		return

	if not hit_node_id.is_empty():
		# Shift+クリック: エッジ作成ドラッグ開始
		if shift_pressed:
			_is_edge_dragging = true
			_edge_drag_source_id = hit_node_id
			_edge_drag_mouse_pos = mouse_pos
			return

		# 通常クリック: 選択 + ノードドラッグ開始
		if _selection != null:
			_selection.select_node(hit_node_id)
		node_selected.emit(hit_node_id)

		_dragging_node_id = hit_node_id
		var node: Dictionary = _model.get_node(hit_node_id)
		var pos_data: Dictionary = node.get("pos", {})
		_drag_start_node_pos = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
		_drag_start_mouse = mouse_pos
		queue_redraw()
		return

	# 接続モード中に空白クリック: モード解除
	if _is_connect_mode:
		_is_connect_mode = false
		_connect_source_id = ""
		queue_redraw()
		return

	# エッジのヒットテスト
	var hit_edge_key: String = _hit_test_edge(mouse_pos)
	if not hit_edge_key.is_empty():
		if _selection != null:
			_selection.select_edge(hit_edge_key)
		edge_selected.emit(hit_edge_key)
		queue_redraw()
		return

	# 空白クリック: 選択クリア
	if _selection != null:
		_selection.clear()
	selection_cleared.emit()
	queue_redraw()


## 左ボタンリリース処理
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
func _handle_left_release(mouse_pos: Vector2) -> void:
	# エッジ作成ドラッグ完了
	if _is_edge_dragging:
		var target_id: String = _hit_test_node(mouse_pos)
		if not target_id.is_empty() and target_id != _edge_drag_source_id:
			edge_create_requested.emit(_edge_drag_source_id, target_id)
		_is_edge_dragging = false
		_edge_drag_source_id = ""
		queue_redraw()
		return

	# ノードドラッグ完了
	if not _dragging_node_id.is_empty():
		if _model != null:
			var node: Dictionary = _model.get_node(_dragging_node_id)
			var pos_data: Dictionary = node.get("pos", {})
			var final_pos: Vector2 = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
			node_moved.emit(_dragging_node_id, final_pos)
		_dragging_node_id = ""


## 右クリック処理（コンテキストメニュー表示）
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
func _handle_right_click(mouse_pos: Vector2) -> void:
	var world_pos: Vector2 = _canvas_to_world(mouse_pos)
	if _tool_state != null and _tool_state.snap_enabled:
		world_pos = _tool_state.snap_position(world_pos)

	var screen_pos: Vector2 = get_global_transform() * mouse_pos

	# ヒットテストでコンテキスト判定
	var hit_node: String = _hit_test_node(mouse_pos)
	if not hit_node.is_empty():
		context_menu_requested.emit("node", hit_node, world_pos, screen_pos)
		return

	var hit_edge: String = _hit_test_edge(mouse_pos)
	if not hit_edge.is_empty():
		context_menu_requested.emit("edge", hit_edge, world_pos, screen_pos)
		return

	context_menu_requested.emit("canvas", "", world_pos, screen_pos)


## キー入力を処理する
##
## @param event: キー入力イベント (InputEventKey)
func _handle_key_input(event: InputEventKey) -> void:
	if not event.pressed:
		return

	if event.keycode == KEY_DELETE:
		delete_requested.emit()
		accept_event()

	elif event.keycode == KEY_S and event.ctrl_pressed:
		save_requested.emit()
		accept_event()

	elif event.keycode == KEY_ESCAPE:
		if _is_connect_mode:
			_is_connect_mode = false
			_connect_source_id = ""
			queue_redraw()
			accept_event()
		if _is_edge_dragging:
			_is_edge_dragging = false
			_edge_drag_source_id = ""
			queue_redraw()
			accept_event()


## ズームを適用する
##
## @param delta: ズーム変化量 (float)
## @param pivot: ズームの中心点（キャンバスローカル座標）(Vector2)
func _zoom(delta: float, pivot: Vector2) -> void:
	if _tool_state == null:
		return

	var old_zoom: float = _tool_state.camera_zoom
	var new_zoom: float = clampf(old_zoom + delta, ToolState.ZOOM_MIN, ToolState.ZOOM_MAX)
	if is_equal_approx(old_zoom, new_zoom):
		return

	# ピボットを中心にズーム（シグナルは最後の set_camera_pos で発火）
	var world_pivot: Vector2 = _canvas_to_world(pivot)
	_tool_state.camera_zoom = clampf(new_zoom, ToolState.ZOOM_MIN, ToolState.ZOOM_MAX)
	var new_world_pivot: Vector2 = _canvas_to_world(pivot)
	_tool_state.set_camera_pos(_tool_state.camera_pos - (new_world_pivot - world_pivot))


# --- Private Functions: Coordinate Conversion ---

## ワールド座標をキャンバスローカル座標に変換する
##
## @param world_pos: ワールド座標 (Vector2)
## @return: キャンバスローカル座標。_tool_state が null の場合は Vector2.ZERO
func _world_to_canvas(world_pos: Vector2) -> Vector2:
	if _tool_state == null:
		return Vector2.ZERO
	return (world_pos - _tool_state.camera_pos) * _tool_state.camera_zoom + size * 0.5


## キャンバスローカル座標をワールド座標に変換する
##
## @param canvas_pos: キャンバスローカル座標 (Vector2)
## @return: ワールド座標。_tool_state が null の場合は Vector2.ZERO
func _canvas_to_world(canvas_pos: Vector2) -> Vector2:
	if _tool_state == null:
		return Vector2.ZERO
	return (canvas_pos - size * 0.5) / _tool_state.camera_zoom + _tool_state.camera_pos


## キャンバスのオフセット（カメラ位置に基づくグリッド描画用）
##
## @return: オフセットベクトル
func _get_canvas_offset() -> Vector2:
	return size * 0.5 - _tool_state.camera_pos * _tool_state.camera_zoom


# --- Private Functions: Hit Testing ---

## マウス位置でノードのヒットテストを行う
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
## @return: ヒットしたノードの ID。ヒットなしなら空文字列
func _hit_test_node(mouse_pos: Vector2) -> String:
	if _model == null or _tool_state == null:
		return ""

	# 逆順（上に描画されたものを優先）
	var nodes: Array = _model.get_all_nodes()
	for i: int in range(nodes.size() - 1, -1, -1):
		var node: Dictionary = nodes[i]
		var pos_data: Dictionary = node.get("pos", {})
		var canvas_pos: Vector2 = _world_to_canvas(Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))
		var half_size: Vector2 = NODE_SIZE * _tool_state.camera_zoom * 0.5
		var rect: Rect2 = Rect2(canvas_pos - half_size, half_size * 2.0)
		if rect.has_point(mouse_pos):
			return node.get("id", "")

	return ""


## マウス位置でエッジのヒットテストを行う
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
## @return: ヒットしたエッジのキー（"from->to" 形式）。ヒットなしなら空文字列
func _hit_test_edge(mouse_pos: Vector2) -> String:
	if _model == null:
		return ""

	for edge: Dictionary in _model.get_all_edges():
		var from_node: Dictionary = _model.get_node(edge.get("from", ""))
		var to_node: Dictionary = _model.get_node(edge.get("to", ""))
		if from_node.is_empty() or to_node.is_empty():
			continue

		var from_pos_data: Dictionary = from_node.get("pos", {})
		var to_pos_data: Dictionary = to_node.get("pos", {})
		var from_canvas: Vector2 = _world_to_canvas(Vector2(from_pos_data.get("x", 0.0), from_pos_data.get("y", 0.0)))
		var to_canvas: Vector2 = _world_to_canvas(Vector2(to_pos_data.get("x", 0.0), to_pos_data.get("y", 0.0)))

		var dist: float = _point_to_segment_distance(mouse_pos, from_canvas, to_canvas)
		if dist < EDGE_HIT_WIDTH:
			return edge.get("from", "") + "->" + edge.get("to", "")

	return ""


## 点から線分への最短距離を計算する
##
## @param point: 判定する点 (Vector2)
## @param seg_a: 線分の始点 (Vector2)
## @param seg_b: 線分の終点 (Vector2)
## @return: 最短距離
func _point_to_segment_distance(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var ab: Vector2 = seg_b - seg_a
	var length_sq: float = ab.length_squared()
	if length_sq < SEGMENT_LENGTH_SQ_EPSILON:
		return point.distance_to(seg_a)

	var t: float = clampf((point - seg_a).dot(ab) / length_sq, 0.0, 1.0)
	var closest: Vector2 = seg_a + ab * t
	return point.distance_to(closest)


# --- Signal Callbacks ---

## モデル変更時の再描画
func _on_model_changed() -> void:
	queue_redraw()


## カメラ変更時の再描画
func _on_camera_changed() -> void:
	queue_redraw()


## グリッド設定変更時の再描画
func _on_grid_changed() -> void:
	queue_redraw()
