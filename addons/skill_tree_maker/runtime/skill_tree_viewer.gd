class_name SkillTreeViewer
extends Control

## ゲームランタイム用スキルツリービューア
##
## PackLoader でデータを取得し、SkillTreeState で状態管理しながら、
## ノード/エッジ/説明パネルを描画する。
## CanvasView のパン/ズーム・座標変換パターンを踏襲しつつ、
## エディタ機能を排除してランタイム向けの操作を提供する。


# --- Signals ---

## ノードがクリックされたとき
signal node_clicked(node_id: String)

## ノードのアンロックが要求されたとき（ダブルクリック）
signal node_unlock_requested(node_id: String)

## ノード上にマウスホバーしたとき
signal node_hovered(node_id: String)

## ノードからマウスが離れたとき
signal node_hover_exited()


# --- Constants ---

## ノードのデフォルト描画サイズ（ピクセル）
const DEFAULT_NODE_SIZE: Vector2 = Vector2(64, 64)

## ノードの角丸半径
const NODE_CORNER_RADIUS: float = 8.0

## ノードの枠線幅
const NODE_BORDER_WIDTH: float = 2.0

## エッジの線幅
const EDGE_WIDTH: float = 3.0

## エッジの矢印サイズ
const EDGE_ARROW_SIZE: float = 8.0

## ズームステップ
const ZOOM_STEP: float = 0.1

## 最小ズーム
const ZOOM_MIN: float = 0.3

## 最大ズーム
const ZOOM_MAX: float = 3.0

## LOCKED ノード背景色
const COLOR_LOCKED: Color = Color(0.25, 0.25, 0.3, 1.0)

## CAN_UNLOCK ノード背景色
const COLOR_CAN_UNLOCK: Color = Color(0.2, 0.3, 0.45, 1.0)

## UNLOCKED ノード背景色
const COLOR_UNLOCKED: Color = Color(0.2, 0.45, 0.3, 1.0)

## LOCKED ノード枠色
const COLOR_LOCKED_BORDER: Color = Color(0.35, 0.35, 0.4, 1.0)

## CAN_UNLOCK ノード枠色
const COLOR_CAN_UNLOCK_BORDER: Color = Color(0.4, 0.6, 0.9, 1.0)

## UNLOCKED ノード枠色
const COLOR_UNLOCKED_BORDER: Color = Color(0.4, 0.8, 0.5, 1.0)

## 選択中ノードの枠色
const COLOR_SELECTED_BORDER: Color = Color(1.0, 0.85, 0.4, 1.0)

## LOCKED エッジ色
const EDGE_COLOR_LOCKED: Color = Color(0.3, 0.3, 0.4, 0.6)

## アクティブエッジ色（両端が UNLOCKED）
const EDGE_COLOR_ACTIVE: Color = Color(0.5, 0.7, 1.0, 0.9)

## キャンバス背景色
const BG_COLOR: Color = Color(0.1, 0.1, 0.13, 1.0)

## 説明パネル幅
const INFO_PANEL_WIDTH: float = 250.0

## 説明パネル内パディング
const INFO_PANEL_PADDING: float = 12.0

## 説明パネル背景色
const INFO_PANEL_BG_COLOR: Color = Color(0.12, 0.12, 0.16, 0.92)

## 説明パネル枠色
const INFO_PANEL_BORDER_COLOR: Color = Color(0.3, 0.35, 0.45, 1.0)

## フォントサイズ基準値（ピクセル）
const BASE_FONT_SIZE: float = 12.0

## フォント描画の最小サイズ（これ未満なら描画しない）
const MIN_FONT_SIZE: int = 6

## ラベルの最大文字数
const MAX_LABEL_LENGTH: int = 16

## ノードのラベルフォントサイズ
const NODE_LABEL_FONT_SIZE: float = 11.0

## 説明パネルのタイトルフォントサイズ
const INFO_TITLE_FONT_SIZE: float = 16.0

## 説明パネルの本文フォントサイズ
const INFO_BODY_FONT_SIZE: float = 12.0

## 説明パネル枠線幅
const INFO_PANEL_BORDER_WIDTH: float = 1.5

## 説明パネルのタイトル下余白
const INFO_TITLE_MARGIN_BOTTOM: float = 8.0

## 説明パネルのセクション間余白
const INFO_SECTION_SPACING: float = 12.0

## 説明パネルの行間余白
const INFO_LINE_SPACING: float = 8.0

## 説明パネルの小行間余白
const INFO_LINE_SPACING_SMALL: float = 4.0

## 説明パネルの最小行間余白
const INFO_LINE_SPACING_TINY: float = 2.0

## ホバー時の明度上昇量
const HOVER_LIGHTEN_AMOUNT: float = 0.15

## アンロックフラッシュの最大強度
const UNLOCK_FLASH_INTENSITY: float = 0.3

## テキスト垂直センタリング補正係数
const TEXT_VERTICAL_CENTER_RATIO: float = 0.25

## 状態テキストカラー: CAN_UNLOCK
const TEXT_COLOR_CAN_UNLOCK: Color = Color(0.6, 0.8, 1.0, 1.0)

## 状態テキストカラー: UNLOCKED
const TEXT_COLOR_UNLOCKED: Color = Color(0.5, 0.9, 0.5, 1.0)

## 状態テキストカラー: LOCKED
const TEXT_COLOR_LOCKED: Color = Color(0.6, 0.6, 0.6, 1.0)


# --- Private Variables ---

## データローダー
var _pack_loader: PackLoader = null

## ノード状態管理
var _state: SkillTreeState = null

## runtime.json データ
var _runtime_data: Dictionary = {}

## テーマデータ
var _theme_data: Dictionary = {}

## ノード配列（runtime_data.nodes のキャッシュ）
var _nodes: Array = []

## エッジ配列（runtime_data.edges のキャッシュ）
var _edges: Array = []

## ノードデータの ID 引き
var _nodes_by_id: Dictionary = {}

## カメラ位置
var _camera_pos: Vector2 = Vector2.ZERO

## カメラズーム
var _camera_zoom: float = 1.0

## パン操作中か
var _is_panning: bool = false

## パン開始マウス位置
var _pan_start_mouse: Vector2 = Vector2.ZERO

## パン開始カメラ位置
var _pan_start_camera: Vector2 = Vector2.ZERO

## 選択中ノード ID
var _selected_node_id: String = ""

## ホバー中ノード ID
var _hovered_node_id: String = ""

## ノードごとのアニメーション状態: {node_id: NodeAnimationState}
var _anim_states: Dictionary = {}

## エッジのアニメーション遷移値: {edge_key: float} (0.0=locked色, 1.0=active色)
var _edge_anim_progress: Dictionary = {}


# --- Built-in Functions ---

## Control の初期設定
func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_process(false)


## アニメーション値を毎フレーム更新する
##
## @param delta: フレーム間隔（秒）(float)
func _process(delta: float) -> void:
	var needs_redraw: bool = false
	var any_animating: bool = false

	for node_id: String in _anim_states.keys():
		var anim: NodeAnimationState = _anim_states[node_id] as NodeAnimationState
		var state: SkillTreeState.NodeState = SkillTreeState.NodeState.LOCKED
		if _state != null:
			state = _state.get_node_state(node_id)
		var is_can_unlock: bool = (state == SkillTreeState.NodeState.CAN_UNLOCK)

		if anim.update(delta, is_can_unlock):
			needs_redraw = true

		if anim.is_animating(is_can_unlock):
			any_animating = true

	# エッジ色遷移
	needs_redraw = _update_edge_animations(delta) or needs_redraw
	if not _edge_anim_progress.is_empty():
		any_animating = true

	if needs_redraw:
		queue_redraw()

	if not any_animating:
		set_process(false)


## 描画処理
func _draw() -> void:
	# 背景
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	if _nodes.is_empty():
		return

	# エッジ → ノード → 説明パネルの順
	_draw_edges()
	_draw_nodes()

	if not _selected_node_id.is_empty():
		_draw_info_panel()


## GUI 入力イベントを処理する
##
## @param event: 入力イベント (InputEvent)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


# --- Public Functions ---

## Pack を読み込んでビューアを初期化する
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: 読み込み成功なら true
func load_pack(pack_root: String) -> bool:
	_pack_loader = PackLoader.new()
	var pack_data: Dictionary = _pack_loader.load_pack(pack_root)
	if pack_data.is_empty():
		push_error("[SkillTreeViewer] load_pack: failed to load pack: " + pack_root)
		return false

	_runtime_data = pack_data.get("runtime", {})
	_theme_data = pack_data.get("theme", {})

	# ノード/エッジをキャッシュ
	_nodes = _runtime_data.get("nodes", [])
	_edges = _runtime_data.get("edges", [])
	_nodes_by_id.clear()
	for node: Dictionary in _nodes:
		var node_id: String = node.get("id", "")
		if not node_id.is_empty():
			_nodes_by_id[node_id] = node

	# SkillTreeState 初期化
	_state = SkillTreeState.new()
	_state.node_state_changed.connect(_on_node_state_changed)
	_state.state_reset.connect(_on_state_reset)
	_state.initialize(_runtime_data)

	# カメラリセット
	_camera_pos = Vector2.ZERO
	_camera_zoom = 1.0
	_selected_node_id = ""
	_hovered_node_id = ""

	# アニメーション状態を初期化
	_anim_states.clear()
	_edge_anim_progress.clear()
	for node: Dictionary in _nodes:
		var nid: String = node.get("id", "")
		if not nid.is_empty():
			_anim_states[nid] = NodeAnimationState.new()
	_activate_animation()

	queue_redraw()
	return true


## 既存のセーブデータから状態を復元する
##
## @param save_data: SkillTreeState.serialize() で生成された Dictionary (Dictionary)
func load_save_data(save_data: Dictionary) -> void:
	if _state == null:
		push_error("[SkillTreeViewer] load_save_data: state not initialized, call load_pack first")
		return
	_state.deserialize(save_data, _runtime_data)
	queue_redraw()


## 現在の状態をセーブ用にシリアライズする
##
## @return: セーブデータ Dictionary。State 未初期化なら空 Dictionary
func get_save_data() -> Dictionary:
	if _state == null:
		return {}
	return _state.serialize()


## SkillTreeState への直接参照を取得する
##
## @return: 内部の SkillTreeState インスタンス。未初期化なら null
func get_state() -> SkillTreeState:
	return _state


## 指定ノードにカメラをフォーカスする
##
## @param node_id: フォーカスするノード ID (String)
func focus_node(node_id: String) -> void:
	if not _nodes_by_id.has(node_id):
		return
	var node: Dictionary = _nodes_by_id[node_id]
	var pos: Dictionary = node.get("pos", {})
	_camera_pos = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	queue_redraw()


## カメラをリセットする（位置とズーム）
func reset_camera() -> void:
	_camera_pos = Vector2.ZERO
	_camera_zoom = 1.0
	queue_redraw()


# --- Private Functions: Drawing ---

## 全エッジを描画する
func _draw_edges() -> void:
	for edge: Dictionary in _edges:
		_draw_edge(edge)


## 単一エッジを描画する
##
## @param edge: エッジデータ (Dictionary)
func _draw_edge(edge: Dictionary) -> void:
	var from_id: String = edge.get("from", "")
	var to_id: String = edge.get("to", "")

	if not _nodes_by_id.has(from_id) or not _nodes_by_id.has(to_id):
		return

	var from_node: Dictionary = _nodes_by_id[from_id]
	var to_node: Dictionary = _nodes_by_id[to_id]

	var from_pos_data: Dictionary = from_node.get("pos", {})
	var to_pos_data: Dictionary = to_node.get("pos", {})

	var from_canvas: Vector2 = _world_to_canvas(Vector2(from_pos_data.get("x", 0.0), from_pos_data.get("y", 0.0)))
	var to_canvas: Vector2 = _world_to_canvas(Vector2(to_pos_data.get("x", 0.0), to_pos_data.get("y", 0.0)))

	var edge_color: Color = _get_edge_color(from_id, to_id, edge.get("style_preset", "edge_default"))

	# エッジ遷移アニメーション中なら色を補間
	var edge_key: String = from_id + "->" + to_id
	if _edge_anim_progress.has(edge_key):
		var progress: float = _edge_anim_progress[edge_key]
		edge_color = EDGE_COLOR_LOCKED.lerp(edge_color, progress)

	var line_width: float = EDGE_WIDTH * _camera_zoom

	draw_line(from_canvas, to_canvas, edge_color, line_width)

	# 矢印を描画
	_draw_arrow(from_canvas, to_canvas, edge_color, line_width)


## エッジの矢印を描画する
##
## @param from_pos: 始点キャンバス座標 (Vector2)
## @param to_pos: 終点キャンバス座標 (Vector2)
## @param color: 矢印の色 (Color)
## @param line_width: 線幅 (float)
func _draw_arrow(from_pos: Vector2, to_pos: Vector2, color: Color, line_width: float) -> void:
	var dir: Vector2 = (to_pos - from_pos).normalized()
	if dir.is_zero_approx():
		return

	# ノードの半径分手前に矢印を配置
	var node_size: float = _get_themed_node_size() * _camera_zoom * 0.5
	var arrow_pos: Vector2 = to_pos - dir * node_size
	var arrow_size: float = EDGE_ARROW_SIZE * _camera_zoom
	var perp: Vector2 = Vector2(-dir.y, dir.x)

	var points: PackedVector2Array = PackedVector2Array([
		arrow_pos,
		arrow_pos - dir * arrow_size + perp * arrow_size * 0.5,
		arrow_pos - dir * arrow_size - perp * arrow_size * 0.5,
	])
	draw_colored_polygon(points, color)


## 全ノードを描画する
func _draw_nodes() -> void:
	for node: Dictionary in _nodes:
		_draw_node(node)


## 単一ノードを描画する
##
## @param node: ノードデータ (Dictionary)
func _draw_node(node: Dictionary) -> void:
	var node_id: String = node.get("id", "")
	var pos_data: Dictionary = node.get("pos", {})
	var canvas_pos: Vector2 = _world_to_canvas(Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))

	var node_size: float = _get_themed_node_size()

	# アニメーションスケールを適用
	var anim: NodeAnimationState = _anim_states.get(node_id) as NodeAnimationState
	var anim_scale: float = anim.current_scale if anim != null else 1.0

	var scaled_size: float = node_size * anim_scale
	var half_size: Vector2 = Vector2(scaled_size, scaled_size) * _camera_zoom * 0.5
	var rect: Rect2 = Rect2(canvas_pos - half_size, half_size * 2.0)

	# 状態に応じた色を取得
	var colors: Dictionary = _get_node_colors(node_id)
	var bg_color: Color = colors.get("bg", COLOR_LOCKED)
	var border_color: Color = colors.get("border", COLOR_LOCKED_BORDER)

	# 選択中は枠色を上書き
	if node_id == _selected_node_id:
		border_color = COLOR_SELECTED_BORDER

	# ホバー中は明るくする
	if node_id == _hovered_node_id:
		bg_color = bg_color.lightened(HOVER_LIGHTEN_AMOUNT)

	# CAN_UNLOCK パルス: 枠色の alpha を変調
	if anim != null and _state != null:
		if _state.get_node_state(node_id) == SkillTreeState.NodeState.CAN_UNLOCK:
			border_color.a = anim.get_pulse_alpha()

	# アンロックアニメーション中の白フラッシュ
	if anim != null and anim.unlock_progress >= 0.0 and anim.unlock_progress < 1.0:
		var flash_intensity: float = 1.0 - anim.unlock_progress
		bg_color = bg_color.lerp(Color.WHITE, flash_intensity * UNLOCK_FLASH_INTENSITY)

	# 背景
	draw_rect(rect, bg_color, true)

	# 枠
	draw_rect(rect, border_color, false, NODE_BORDER_WIDTH)

	# ラベル
	var label: String = node.get("name_key", node_id)
	if label.length() > MAX_LABEL_LENGTH:
		label = node_id
	if label.length() > MAX_LABEL_LENGTH:
		label = label.substr(0, MAX_LABEL_LENGTH - 2) + ".."

	var font: Font = ThemeDB.fallback_font
	var font_size: int = int(NODE_LABEL_FONT_SIZE * _camera_zoom * anim_scale)
	if font_size < MIN_FONT_SIZE:
		return
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos: Vector2 = canvas_pos + Vector2(-text_size.x * 0.5, text_size.y * TEXT_VERTICAL_CENTER_RATIO)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## 説明パネルを描画する
func _draw_info_panel() -> void:
	if not _nodes_by_id.has(_selected_node_id):
		return

	var node: Dictionary = _nodes_by_id[_selected_node_id]
	var font: Font = ThemeDB.fallback_font

	# パネル位置・サイズ
	var panel_rect: Rect2 = Rect2(
		Vector2(size.x - INFO_PANEL_WIDTH, 0),
		Vector2(INFO_PANEL_WIDTH, size.y)
	)

	# パネル背景
	draw_rect(panel_rect, INFO_PANEL_BG_COLOR, true)
	draw_rect(panel_rect, INFO_PANEL_BORDER_COLOR, false, INFO_PANEL_BORDER_WIDTH)

	var x: float = panel_rect.position.x + INFO_PANEL_PADDING
	var y: float = INFO_PANEL_PADDING + INFO_TITLE_FONT_SIZE
	var max_width: float = INFO_PANEL_WIDTH - INFO_PANEL_PADDING * 2.0

	# タイトル
	var title: String = node.get("name_key", _selected_node_id)
	draw_string(font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT,
		int(max_width), int(INFO_TITLE_FONT_SIZE), Color.WHITE)
	y += INFO_TITLE_FONT_SIZE + INFO_TITLE_MARGIN_BOTTOM

	# 状態
	var state: SkillTreeState.NodeState = SkillTreeState.NodeState.LOCKED
	if _state != null:
		state = _state.get_node_state(_selected_node_id)
	var state_text: String = _get_state_display_text(state)
	var state_color: Color = _get_state_text_color(state)
	draw_string(font, Vector2(x, y), state_text, HORIZONTAL_ALIGNMENT_LEFT,
		int(max_width), int(INFO_BODY_FONT_SIZE), state_color)
	y += INFO_BODY_FONT_SIZE + INFO_SECTION_SPACING

	# 説明
	var desc: String = node.get("desc_key", "")
	if not desc.is_empty():
		draw_string(font, Vector2(x, y), desc, HORIZONTAL_ALIGNMENT_LEFT,
			int(max_width), int(INFO_BODY_FONT_SIZE), Color(0.8, 0.8, 0.8, 1.0))
		y += INFO_BODY_FONT_SIZE + INFO_LINE_SPACING

	# コスト
	var unlock: Dictionary = node.get("unlock", {})
	var cost: Dictionary = unlock.get("cost", {})
	if not cost.is_empty():
		var cost_text: String = "Cost: " + str(cost.get("value", 0)) + " " + str(cost.get("type", ""))
		draw_string(font, Vector2(x, y), cost_text, HORIZONTAL_ALIGNMENT_LEFT,
			int(max_width), int(INFO_BODY_FONT_SIZE), Color(1.0, 0.85, 0.4, 1.0))
		y += INFO_BODY_FONT_SIZE + INFO_LINE_SPACING

	# 前提条件
	var requires: Array = unlock.get("requires", [])
	if not requires.is_empty():
		draw_string(font, Vector2(x, y), "Requires:", HORIZONTAL_ALIGNMENT_LEFT,
			int(max_width), int(INFO_BODY_FONT_SIZE), Color(0.7, 0.7, 0.7, 1.0))
		y += INFO_BODY_FONT_SIZE + INFO_LINE_SPACING_SMALL
		for req_id: Variant in requires:
			var req_state: SkillTreeState.NodeState = SkillTreeState.NodeState.LOCKED
			if _state != null:
				req_state = _state.get_node_state(str(req_id))
			var req_color: Color = _get_state_text_color(req_state)
			var req_text: String = "  - " + str(req_id)
			draw_string(font, Vector2(x, y), req_text, HORIZONTAL_ALIGNMENT_LEFT,
				int(max_width), int(INFO_BODY_FONT_SIZE), req_color)
			y += INFO_BODY_FONT_SIZE + INFO_LINE_SPACING_TINY

	# ペイロード
	var payload: Dictionary = node.get("payload", {})
	if not payload.is_empty():
		y += INFO_LINE_SPACING
		var effect_id: String = payload.get("effect_id", "")
		if not effect_id.is_empty():
			draw_string(font, Vector2(x, y), "Effect: " + effect_id, HORIZONTAL_ALIGNMENT_LEFT,
				int(max_width), int(INFO_BODY_FONT_SIZE), Color(0.8, 0.7, 1.0, 1.0))


# --- Private Functions: Input ---

## マウスボタン入力を処理する
##
## @param event: マウスボタンイベント (InputEventMouseButton)
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		# 中ボタン: パン
		if event.pressed:
			_is_panning = true
			_pan_start_mouse = event.position
			_pan_start_camera = _camera_pos
		else:
			_is_panning = false

	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom(ZOOM_STEP, event.position)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom(-ZOOM_STEP, event.position)

	elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			_handle_double_click(event.position)
		else:
			_handle_left_click(event.position)


## 左クリック処理
##
## @param mouse_pos: マウス位置 (Vector2)
func _handle_left_click(mouse_pos: Vector2) -> void:
	var hit_id: String = _hit_test_node(mouse_pos)

	if not hit_id.is_empty():
		_selected_node_id = hit_id
		node_clicked.emit(hit_id)
	else:
		_selected_node_id = ""

	queue_redraw()


## ダブルクリック処理（アンロック要求）
##
## @param mouse_pos: マウス位置 (Vector2)
func _handle_double_click(mouse_pos: Vector2) -> void:
	var hit_id: String = _hit_test_node(mouse_pos)
	if hit_id.is_empty():
		return

	_selected_node_id = hit_id
	node_clicked.emit(hit_id)

	if _state != null and _state.can_unlock(hit_id):
		node_unlock_requested.emit(hit_id)

	queue_redraw()


## マウス移動を処理する
##
## @param event: マウス移動イベント (InputEventMouseMotion)
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning:
		var delta: Vector2 = (event.position - _pan_start_mouse) / _camera_zoom
		_camera_pos = _pan_start_camera - delta
		queue_redraw()
		return

	# ホバー検出
	var hit_id: String = _hit_test_node(event.position)
	if hit_id != _hovered_node_id:
		# 旧ホバーノードのアニメーション解除
		if not _hovered_node_id.is_empty() and _anim_states.has(_hovered_node_id):
			(_anim_states[_hovered_node_id] as NodeAnimationState).is_hovered = false
		# 新ホバーノードのアニメーション開始
		if not hit_id.is_empty() and _anim_states.has(hit_id):
			(_anim_states[hit_id] as NodeAnimationState).is_hovered = true

		var prev: String = _hovered_node_id
		_hovered_node_id = hit_id
		if not hit_id.is_empty():
			node_hovered.emit(hit_id)
		elif not prev.is_empty():
			node_hover_exited.emit()
		_activate_animation()
		queue_redraw()


## ズームを適用する
##
## @param delta: ズーム変化量 (float)
## @param pivot: ズームの中心点 (Vector2)
func _zoom(delta: float, pivot: Vector2) -> void:
	var old_zoom: float = _camera_zoom
	var new_zoom: float = clampf(old_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(old_zoom, new_zoom):
		return

	# ピボットを中心にズーム
	var world_pivot: Vector2 = _canvas_to_world(pivot)
	_camera_zoom = new_zoom
	var new_world_pivot: Vector2 = _canvas_to_world(pivot)
	_camera_pos -= new_world_pivot - world_pivot

	queue_redraw()


# --- Private Functions: Coordinate Conversion ---

## ワールド座標をキャンバスローカル座標に変換する
##
## @param world_pos: ワールド座標 (Vector2)
## @return: キャンバスローカル座標
func _world_to_canvas(world_pos: Vector2) -> Vector2:
	return (world_pos - _camera_pos) * _camera_zoom + size * 0.5


## キャンバスローカル座標をワールド座標に変換する
##
## @param canvas_pos: キャンバスローカル座標 (Vector2)
## @return: ワールド座標
func _canvas_to_world(canvas_pos: Vector2) -> Vector2:
	return (canvas_pos - size * 0.5) / _camera_zoom + _camera_pos


# --- Private Functions: Hit Testing ---

## ノードのヒットテストを行う
##
## @param mouse_pos: マウス位置（キャンバスローカル座標）(Vector2)
## @return: ヒットしたノード ID。ヒットなしなら空文字列
func _hit_test_node(mouse_pos: Vector2) -> String:
	var node_size: float = _get_themed_node_size()

	# 逆順（上に描画されたものを優先）
	for i: int in range(_nodes.size() - 1, -1, -1):
		var node: Dictionary = _nodes[i]
		var pos_data: Dictionary = node.get("pos", {})
		var canvas_pos: Vector2 = _world_to_canvas(Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0)))
		var half_size: Vector2 = Vector2(node_size, node_size) * _camera_zoom * 0.5
		var rect: Rect2 = Rect2(canvas_pos - half_size, half_size * 2.0)
		if rect.has_point(mouse_pos):
			return node.get("id", "")

	return ""


# --- Private Functions: Theme ---

## テーマからノードサイズを取得する（フォールバック付き）
##
## @return: ノードサイズ（ピクセル）
func _get_themed_node_size() -> float:
	var node_presets: Dictionary = _theme_data.get("node_presets", {})
	var default_preset: Dictionary = node_presets.get("node_default", {})
	return default_preset.get("size", DEFAULT_NODE_SIZE.x)


## ノード状態に対応する描画色を取得する
##
## @param node_id: ノード ID (String)
## @return: {bg: Color, border: Color} の Dictionary
func _get_node_colors(node_id: String) -> Dictionary:
	var state: SkillTreeState.NodeState = SkillTreeState.NodeState.LOCKED
	if _state != null:
		state = _state.get_node_state(node_id)

	# テーマからプリセット取得を試みる
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	var style: Dictionary = node.get("style", {})
	var preset_name: String = style.get("preset", "node_default")
	var node_presets: Dictionary = _theme_data.get("node_presets", {})
	var preset: Dictionary = node_presets.get(preset_name, {})
	var states: Dictionary = preset.get("states", {})

	# 状態名
	var state_key: String = "locked"
	var bg_fallback: Color = COLOR_LOCKED
	var border_fallback: Color = COLOR_LOCKED_BORDER
	match state:
		SkillTreeState.NodeState.CAN_UNLOCK:
			state_key = "can_unlock"
			bg_fallback = COLOR_CAN_UNLOCK
			border_fallback = COLOR_CAN_UNLOCK_BORDER
		SkillTreeState.NodeState.UNLOCKED:
			state_key = "unlocked"
			bg_fallback = COLOR_UNLOCKED
			border_fallback = COLOR_UNLOCKED_BORDER

	# テーマの glow_color があれば枠色に使用
	var state_data: Dictionary = states.get(state_key, {})
	var glow_color_str: String = state_data.get("glow_color", "")
	var border_color: Color = border_fallback
	if not glow_color_str.is_empty() and state_data.get("glow", false):
		border_color = Color.from_string(glow_color_str, border_fallback)

	return {"bg": bg_fallback, "border": border_color}


## エッジの描画色を取得する
##
## @param from_id: 始点ノード ID (String)
## @param to_id: 終点ノード ID (String)
## @param preset_name: プリセット名 (String)
## @return: エッジ色
func _get_edge_color(from_id: String, to_id: String, preset_name: String) -> Color:
	if _state == null:
		return EDGE_COLOR_LOCKED

	var from_state: SkillTreeState.NodeState = _state.get_node_state(from_id)
	var to_state: SkillTreeState.NodeState = _state.get_node_state(to_id)

	# 両端が UNLOCKED ならアクティブ色
	var is_active: bool = (
		from_state == SkillTreeState.NodeState.UNLOCKED
		and to_state == SkillTreeState.NodeState.UNLOCKED
	)

	# テーマからプリセット取得を試みる
	var edge_presets: Dictionary = _theme_data.get("edge_presets", {})
	var preset: Dictionary = edge_presets.get(preset_name, {})

	if is_active:
		var active_str: String = preset.get("color_active", "")
		if not active_str.is_empty():
			return Color.from_string(active_str, EDGE_COLOR_ACTIVE)
		return EDGE_COLOR_ACTIVE

	var locked_str: String = preset.get("color_locked", "")
	if not locked_str.is_empty():
		return Color.from_string(locked_str, EDGE_COLOR_LOCKED)
	return EDGE_COLOR_LOCKED


# --- Private Functions: Utility ---

## 状態の表示テキストを取得する
##
## @param state: ノード状態 (SkillTreeState.NodeState)
## @return: 表示テキスト
func _get_state_display_text(state: SkillTreeState.NodeState) -> String:
	match state:
		SkillTreeState.NodeState.LOCKED:
			return "LOCKED"
		SkillTreeState.NodeState.CAN_UNLOCK:
			return "CAN UNLOCK"
		SkillTreeState.NodeState.UNLOCKED:
			return "UNLOCKED"
	return "UNKNOWN"


## 状態に対応するテキスト色を取得する
##
## @param state: ノード状態 (SkillTreeState.NodeState)
## @return: テキスト色
func _get_state_text_color(state: SkillTreeState.NodeState) -> Color:
	match state:
		SkillTreeState.NodeState.LOCKED:
			return TEXT_COLOR_LOCKED
		SkillTreeState.NodeState.CAN_UNLOCK:
			return TEXT_COLOR_CAN_UNLOCK
		SkillTreeState.NodeState.UNLOCKED:
			return TEXT_COLOR_UNLOCKED
	return TEXT_COLOR_LOCKED


# --- Signal Callbacks ---

## ノード状態変更時にアニメーションを開始して再描画する
##
## @param node_id: 変化したノード ID (String)
## @param new_state: 新しい状態 (int)
func _on_node_state_changed(node_id: String, new_state: int) -> void:
	# UNLOCKED になったらアンロックアニメーションを開始
	if new_state == SkillTreeState.NodeState.UNLOCKED:
		if _anim_states.has(node_id):
			(_anim_states[node_id] as NodeAnimationState).start_unlock()
		_start_edge_animations_for_node(node_id)

	_activate_animation()
	queue_redraw()


## 状態リセット時にアニメーション状態をリセットして再描画する
func _on_state_reset() -> void:
	_selected_node_id = ""
	_hovered_node_id = ""

	# 全アニメーション状態をリセット
	_anim_states.clear()
	_edge_anim_progress.clear()
	for node: Dictionary in _nodes:
		var nid: String = node.get("id", "")
		if not nid.is_empty():
			_anim_states[nid] = NodeAnimationState.new()
	_activate_animation()
	queue_redraw()


# --- Private Functions: Animation ---

## アニメーションループを有効化する
func _activate_animation() -> void:
	set_process(true)


## エッジ色遷移アニメーションを更新する
##
## @param delta: フレーム間隔（秒）(float)
## @return: 再描画が必要なら true
func _update_edge_animations(delta: float) -> bool:
	if _edge_anim_progress.is_empty():
		return false

	var needs_redraw: bool = false
	var completed_keys: Array[String] = []

	for edge_key: String in _edge_anim_progress.keys():
		var progress: float = _edge_anim_progress[edge_key]
		progress = minf(progress + delta / NodeAnimationState.EDGE_TRANSITION_DURATION, 1.0)
		_edge_anim_progress[edge_key] = progress
		needs_redraw = true

		if progress >= 1.0:
			completed_keys.append(edge_key)

	# 完了したエッジを辞書から削除
	for key: String in completed_keys:
		_edge_anim_progress.erase(key)

	return needs_redraw


## 指定ノードに関連するエッジの色遷移アニメーションを開始する
##
## @param node_id: アンロックされたノード ID (String)
func _start_edge_animations_for_node(node_id: String) -> void:
	if _state == null:
		return

	for edge: Dictionary in _edges:
		var from_id: String = edge.get("from", "")
		var to_id: String = edge.get("to", "")

		# このノードが端点であるエッジを探す
		if from_id != node_id and to_id != node_id:
			continue

		# 両端が UNLOCKED ならアクティブ化遷移を開始
		var from_state: SkillTreeState.NodeState = _state.get_node_state(from_id)
		var to_state: SkillTreeState.NodeState = _state.get_node_state(to_id)
		if from_state == SkillTreeState.NodeState.UNLOCKED and to_state == SkillTreeState.NodeState.UNLOCKED:
			var edge_key: String = from_id + "->" + to_id
			_edge_anim_progress[edge_key] = 0.0
