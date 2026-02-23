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

## 右ドラッグでパンを開始する移動ピクセル閾値
const RIGHT_PAN_THRESHOLD: float = 4.0

## エッジ矢印のサイズ（ピクセル）
const EDGE_ARROW_SIZE: float = 10.0

## ノード小サイズ（small）
const NODE_SIZE_SMALL: Vector2 = Vector2(80, 32)

## ノード中サイズ（medium、デフォルト）
const NODE_SIZE_MEDIUM: Vector2 = Vector2(120, 48)

## ノード大サイズ（large）
const NODE_SIZE_LARGE: Vector2 = Vector2(160, 64)

## グループエッジの色
const GROUP_EDGE_COLOR: Color = Color(0.6, 0.4, 0.8, 0.6)

## グループエッジの線幅
const GROUP_EDGE_WIDTH: float = 3.0

## NodeType: MINOR ノードサイズ（ピクセル）
const NODE_TYPE_SIZE_MINOR: float = 20.0

## NodeType: NOTABLE ノードサイズ（ピクセル）
const NODE_TYPE_SIZE_NOTABLE: float = 32.0

## NodeType: KEYSTONE ノードサイズ（ピクセル）
const NODE_TYPE_SIZE_KEYSTONE: float = 44.0

## NodeType: SOCKET ノードサイズ（ピクセル）
const NODE_TYPE_SIZE_SOCKET: float = 24.0

## KEYSTONE ノードの二重枠の外側オフセット
const KEYSTONE_OUTER_BORDER_OFFSET: float = 4.0

## NOTABLE ノードの枠色
const NODE_NOTABLE_BORDER_COLOR: Color = Color(0.7, 0.75, 0.9, 1.0)

## KEYSTONE ノードの枠色
const NODE_KEYSTONE_BORDER_COLOR: Color = Color(1.0, 0.85, 0.4, 1.0)

## SOCKET ノードの枠色
const NODE_SOCKET_BORDER_COLOR: Color = Color(0.5, 0.8, 0.6, 1.0)

## カリング用のビューポートマージン係数（ポップイン防止）
const CULLING_MARGIN_RATIO: float = 1.2


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

## 右ボタン押下時のマウス位置（右ドラッグパン判定用）
var _right_press_pos: Vector2 = Vector2.ZERO

## 右ドラッグパン中か（コンテキストメニュー抑制に使用）
var _is_right_panning: bool = false

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

	# カリング用ビューポート矩形（ワールド座標）
	var vis_rect: Rect2 = _get_visible_rect_in_world()

	# エッジ（両端が画面外ならスキップ）
	for edge: Dictionary in _model.get_all_edges():
		if _is_edge_visible(edge, vis_rect):
			_draw_edge(edge)

	# グループエッジ
	for group_edge: Dictionary in _model.get_all_group_edges():
		_draw_group_edge(group_edge)

	# エッジ作成プレビュー
	if _is_edge_dragging and not _edge_drag_source_id.is_empty():
		_draw_edge_preview()

	# ノード（画面外ならスキップ）
	for node: Dictionary in _model.get_all_nodes():
		if _is_node_visible(node, vis_rect):
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


## キャンバスを再描画する（queue_redraw のラッパー）
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
## NodeType が設定されている場合は NodeType 別描画を使用し、
## そうでなければ style.shape ベースのレガシー描画を使用する。
##
## @param node: ノードデータ (Dictionary)
func _draw_node(node: Dictionary) -> void:
	var node_id: String = node.get("id", "")
	var pos_data: Dictionary = node.get("pos", {})
	var canvas_pos: Vector2 = _world_to_canvas(Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))

	var display_size: Vector2 = _get_node_display_size(node)
	var scaled_size: Vector2 = display_size * _tool_state.camera_zoom

	# 選択状態判定
	var is_selected: bool = _selection != null and _selection.is_node_id_selected(node_id)

	# style.color が設定されていればノード固有色を使用する
	var style: Dictionary = node.get("style", {})
	var color_str: String = style.get("color", "")
	var base_color: Color = NODE_SELECTED_COLOR if is_selected else NODE_COLOR
	if not color_str.is_empty() and not is_selected:
		base_color = Color.from_string(color_str, NODE_COLOR)

	# NodeType 別描画
	var node_type: String = node.get("node_type", "")
	if not node_type.is_empty():
		_draw_node_by_type(canvas_pos, scaled_size, base_color, is_selected, node_type)
	else:
		# レガシー: style.shape ベース描画
		var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_BORDER_COLOR
		var shape: String = style.get("shape", "square")
		match shape:
			"circle":
				var radius: float = min(scaled_size.x, scaled_size.y) * 0.5
				_draw_node_circle(canvas_pos, radius, base_color, border_color)
			"diamond":
				_draw_node_diamond(canvas_pos, scaled_size * 0.5, base_color, border_color)
			_:
				var rect: Rect2 = Rect2(canvas_pos - scaled_size * 0.5, scaled_size)
				_draw_node_square(rect, base_color, border_color)

	# ラベル（name_key を短縮表示）
	var label: String = node.get("name_key", node_id)
	if label.length() > MAX_LABEL_LENGTH:
		label = node_id

	var font: Font = ThemeDB.fallback_font
	var font_size: int = int(BASE_FONT_SIZE * _tool_state.camera_zoom)
	if font_size < MIN_FONT_SIZE:
		return
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos: Vector2 = canvas_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.25)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## NodeType に応じたノード描画を行う
##
## @param center: キャンバス中心座標 (Vector2)
## @param scaled_size: ズーム適用済みサイズ (Vector2)
## @param bg_color: 背景色 (Color)
## @param is_selected: 選択中か (bool)
## @param node_type: ノード種別 (String)
func _draw_node_by_type(center: Vector2, scaled_size: Vector2, bg_color: Color, is_selected: bool, node_type: String) -> void:
	match node_type:
		SkillTreeModel.NODE_TYPE_MINOR:
			_draw_node_minor(center, scaled_size, bg_color, is_selected)
		SkillTreeModel.NODE_TYPE_NOTABLE:
			_draw_node_notable(center, scaled_size, bg_color, is_selected)
		SkillTreeModel.NODE_TYPE_KEYSTONE:
			_draw_node_keystone(center, scaled_size, bg_color, is_selected)
		SkillTreeModel.NODE_TYPE_SOCKET:
			_draw_node_socket(center, scaled_size, bg_color, is_selected)
		_:
			_draw_node_minor(center, scaled_size, bg_color, is_selected)


## MINOR ノードを描画する（小円）
##
## @param center: キャンバス中心座標 (Vector2)
## @param scaled_size: ズーム適用済みサイズ (Vector2)
## @param bg_color: 背景色 (Color)
## @param is_selected: 選択中か (bool)
func _draw_node_minor(center: Vector2, scaled_size: Vector2, bg_color: Color, is_selected: bool) -> void:
	var radius: float = min(scaled_size.x, scaled_size.y) * 0.5
	var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_BORDER_COLOR
	_draw_node_circle(center, radius, bg_color, border_color)


## NOTABLE ノードを描画する（大円、特殊枠色）
##
## @param center: キャンバス中心座標 (Vector2)
## @param scaled_size: ズーム適用済みサイズ (Vector2)
## @param bg_color: 背景色 (Color)
## @param is_selected: 選択中か (bool)
func _draw_node_notable(center: Vector2, scaled_size: Vector2, bg_color: Color, is_selected: bool) -> void:
	var radius: float = min(scaled_size.x, scaled_size.y) * 0.5
	var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_NOTABLE_BORDER_COLOR
	_draw_node_circle(center, radius, bg_color, border_color)


## KEYSTONE ノードを描画する（大菱形、二重枠線）
##
## @param center: キャンバス中心座標 (Vector2)
## @param scaled_size: ズーム適用済みサイズ (Vector2)
## @param bg_color: 背景色 (Color)
## @param is_selected: 選択中か (bool)
func _draw_node_keystone(center: Vector2, scaled_size: Vector2, bg_color: Color, is_selected: bool) -> void:
	var half: Vector2 = scaled_size * 0.5
	var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_KEYSTONE_BORDER_COLOR
	_draw_node_diamond(center, half, bg_color, border_color)
	# 二重枠: 外側にもう一つ菱形を描画
	var outer_half: Vector2 = half + Vector2(KEYSTONE_OUTER_BORDER_OFFSET, KEYSTONE_OUTER_BORDER_OFFSET) * _tool_state.camera_zoom
	var top: Vector2 = center + Vector2(0.0, -outer_half.y)
	var right: Vector2 = center + Vector2(outer_half.x, 0.0)
	var bottom: Vector2 = center + Vector2(0.0, outer_half.y)
	var left_pt: Vector2 = center + Vector2(-outer_half.x, 0.0)
	draw_polyline(PackedVector2Array([top, right, bottom, left_pt, top]), border_color, NODE_BORDER_WIDTH * 0.5)


## SOCKET ノードを描画する（角丸四角形）
##
## @param center: キャンバス中心座標 (Vector2)
## @param scaled_size: ズーム適用済みサイズ (Vector2)
## @param bg_color: 背景色 (Color)
## @param is_selected: 選択中か (bool)
func _draw_node_socket(center: Vector2, scaled_size: Vector2, bg_color: Color, is_selected: bool) -> void:
	var border_color: Color = NODE_SELECTED_BORDER_COLOR if is_selected else NODE_SOCKET_BORDER_COLOR
	var rect: Rect2 = Rect2(center - scaled_size * 0.5, scaled_size)
	_draw_node_square(rect, bg_color, border_color)


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

	var to_half: float = _get_node_display_size(to_node).x * _tool_state.camera_zoom * 0.5
	draw_line(from_canvas, to_canvas, EDGE_COLOR, EDGE_WIDTH * _tool_state.camera_zoom)
	_draw_edge_arrow(from_canvas, to_canvas, EDGE_COLOR, _tool_state.camera_zoom, to_half)


## エッジの矢印を描画する
##
## @param from_pos: 始点キャンバス座標 (Vector2)
## @param to_pos: 終点キャンバス座標 (Vector2)
## @param color: 矢印色 (Color)
## @param zoom: 現在のカメラズーム (float)
## @param node_half: 終点ノードの半径（負数時はデフォルトサイズを使用）(float)
func _draw_edge_arrow(from_pos: Vector2, to_pos: Vector2, color: Color, zoom: float, node_half: float = -1.0) -> void:
	var dir: Vector2 = (to_pos - from_pos).normalized()
	if dir.is_zero_approx():
		return

	# ノードの端から矢印を配置（ノード半径分手前）
	var effective_half: float = node_half if node_half >= 0.0 else NODE_SIZE_MEDIUM.x * zoom * 0.5
	var arrow_pos: Vector2 = to_pos - dir * effective_half
	var arrow_size: float = EDGE_ARROW_SIZE * zoom
	var perp: Vector2 = Vector2(-dir.y, dir.x)

	var points: PackedVector2Array = PackedVector2Array([
		arrow_pos,
		arrow_pos - dir * arrow_size + perp * (arrow_size * 0.5),
		arrow_pos - dir * arrow_size - perp * (arrow_size * 0.5),
	])
	draw_colored_polygon(points, color)


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


## ノードのスタイルから描画サイズを取得する
##
## NodeType が設定されている場合は NodeType ベースのサイズを使用し、
## そうでなければ style.size ベースのレガシーサイズを使用する。
##
## @param node: ノードデータ (Dictionary)
## @return: 描画サイズ (Vector2)
func _get_node_display_size(node: Dictionary) -> Vector2:
	var node_type: String = node.get("node_type", "")
	if not node_type.is_empty():
		var s: float = _get_node_type_size(node_type)
		return Vector2(s, s)

	# レガシー: style.size ベース
	var size_str: String = node.get("style", {}).get("size", "medium")
	match size_str:
		"small":
			return NODE_SIZE_SMALL
		"large":
			return NODE_SIZE_LARGE
		_:
			return NODE_SIZE_MEDIUM


## NodeType に基づくノードサイズを取得する
##
## @param node_type: ノード種別 (String)
## @return: ノードサイズ（ピクセル）(float)
func _get_node_type_size(node_type: String) -> float:
	match node_type:
		SkillTreeModel.NODE_TYPE_MINOR:
			return NODE_TYPE_SIZE_MINOR
		SkillTreeModel.NODE_TYPE_NOTABLE:
			return NODE_TYPE_SIZE_NOTABLE
		SkillTreeModel.NODE_TYPE_KEYSTONE:
			return NODE_TYPE_SIZE_KEYSTONE
		SkillTreeModel.NODE_TYPE_SOCKET:
			return NODE_TYPE_SIZE_SOCKET
		_:
			return NODE_TYPE_SIZE_MINOR


## 四角形ノードを描画する
##
## @param rect: 描画矩形 (Rect2)
## @param bg_color: 背景色 (Color)
## @param border_color: 枠色 (Color)
func _draw_node_square(rect: Rect2, bg_color: Color, border_color: Color) -> void:
	draw_rect(rect, bg_color, true)
	draw_rect(rect, border_color, false, NODE_BORDER_WIDTH)


## 円形ノードを描画する
##
## @param center: 中心キャンバス座標 (Vector2)
## @param radius: 半径 (float)
## @param bg_color: 背景色 (Color)
## @param border_color: 枠色 (Color)
func _draw_node_circle(center: Vector2, radius: float, bg_color: Color, border_color: Color) -> void:
	draw_circle(center, radius, bg_color)
	draw_arc(center, radius, 0.0, TAU, 32, border_color, NODE_BORDER_WIDTH)


## ダイヤモンド（菱形）ノードを描画する
##
## @param center: 中心キャンバス座標 (Vector2)
## @param half_size: X/Y それぞれの半径 (Vector2)
## @param bg_color: 背景色 (Color)
## @param border_color: 枠色 (Color)
func _draw_node_diamond(center: Vector2, half_size: Vector2, bg_color: Color, border_color: Color) -> void:
	var top: Vector2 = center + Vector2(0.0, -half_size.y)
	var right: Vector2 = center + Vector2(half_size.x, 0.0)
	var bottom: Vector2 = center + Vector2(0.0, half_size.y)
	var left: Vector2 = center + Vector2(-half_size.x, 0.0)
	var fill_points: PackedVector2Array = PackedVector2Array([top, right, bottom, left])
	draw_colored_polygon(fill_points, bg_color)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), border_color, NODE_BORDER_WIDTH)


## グループ間エッジを描画する
##
## @param group_edge: グループエッジデータ (Dictionary)
func _draw_group_edge(group_edge: Dictionary) -> void:
	var from_id: String = group_edge.get("from", "")
	var to_id: String = group_edge.get("to", "")
	var from_group: Dictionary = _model.get_group(from_id)
	var to_group: Dictionary = _model.get_group(to_id)
	if from_group.is_empty() or to_group.is_empty():
		return

	var from_center: Dictionary = from_group.get("center", {})
	var to_center: Dictionary = to_group.get("center", {})
	var from_canvas: Vector2 = _world_to_canvas(
		Vector2(from_center.get("x", 0.0), from_center.get("y", 0.0)))
	var to_canvas: Vector2 = _world_to_canvas(
		Vector2(to_center.get("x", 0.0), to_center.get("y", 0.0)))

	draw_dashed_line(from_canvas, to_canvas, GROUP_EDGE_COLOR,
		GROUP_EDGE_WIDTH * _tool_state.camera_zoom, 12.0 * _tool_state.camera_zoom)
	_draw_edge_arrow(from_canvas, to_canvas, GROUP_EDGE_COLOR, _tool_state.camera_zoom, 0.0)


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

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# 右ドラッグパンの開始点を記録（コンテキストメニューと排他）
			_right_press_pos = event.position
			_is_panning = true
			_pan_start_mouse = event.position
			_pan_start_camera = _tool_state.camera_pos
			_is_right_panning = false
		else:
			_is_panning = false
			if not _is_right_panning:
				# 有意なドラッグなし = コンテキストメニュー
				_handle_right_click(event.position)
			_is_right_panning = false


## マウス移動を処理する
##
## @param event: マウス移動イベント (InputEventMouseMotion)
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning and _tool_state != null:
		var move_dist: float = event.position.distance_to(_right_press_pos)
		if not _is_right_panning and move_dist > RIGHT_PAN_THRESHOLD:
			_is_right_panning = true
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


# --- Private Functions: Culling ---

## ワールド座標でのビューポート矩形を取得する（カリング用）
##
## マージン付きで計算し、端の要素のポップインを防止する。
##
## @return: ワールド座標でのビューポート矩形
func _get_visible_rect_in_world() -> Rect2:
	if _tool_state == null:
		return Rect2()
	var top_left: Vector2 = _canvas_to_world(Vector2.ZERO)
	var bottom_right: Vector2 = _canvas_to_world(size)
	var rect: Rect2 = Rect2(top_left, bottom_right - top_left)
	# マージンを追加（矩形の各辺を拡張）
	var margin: Vector2 = rect.size * (CULLING_MARGIN_RATIO - 1.0) * 0.5
	return rect.grow_individual(margin.x, margin.y, margin.x, margin.y)


## ノードがビューポート内に表示されるか判定する
##
## @param node: ノードデータ (Dictionary)
## @param vis_rect: ワールド座標のビューポート矩形 (Rect2)
## @return: 表示されるなら true
func _is_node_visible(node: Dictionary, vis_rect: Rect2) -> bool:
	var pos_data: Dictionary = node.get("pos", {})
	var world_pos: Vector2 = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
	var display_size: Vector2 = _get_node_display_size(node)
	var node_half: float = max(display_size.x, display_size.y) * 0.5
	return vis_rect.grow(node_half).has_point(world_pos)


## エッジがビューポート内に表示されるか判定する
##
## 両端ノードが共に画面外の場合のみスキップする。
##
## @param edge: エッジデータ (Dictionary)
## @param vis_rect: ワールド座標のビューポート矩形 (Rect2)
## @return: 表示されるなら true
func _is_edge_visible(edge: Dictionary, vis_rect: Rect2) -> bool:
	var from_node: Dictionary = _model.get_node(edge.get("from", ""))
	var to_node: Dictionary = _model.get_node(edge.get("to", ""))
	if from_node.is_empty() or to_node.is_empty():
		return false

	var from_pos: Dictionary = from_node.get("pos", {})
	var to_pos: Dictionary = to_node.get("pos", {})
	var from_world: Vector2 = Vector2(from_pos.get("x", 0.0), from_pos.get("y", 0.0))
	var to_world: Vector2 = Vector2(to_pos.get("x", 0.0), to_pos.get("y", 0.0))

	return vis_rect.has_point(from_world) or vis_rect.has_point(to_world)


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
		var half_size: Vector2 = _get_node_display_size(node) * _tool_state.camera_zoom * 0.5
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
