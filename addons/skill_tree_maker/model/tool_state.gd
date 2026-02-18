class_name ToolState
extends RefCounted

## エディタの UI 状態を保持するモデル
##
## カメラ位置・ズーム・グリッド設定・選択状態など、
## pack.json の editor_state セクションに対応する。


# --- Signals ---

## カメラ状態が変更されたとき
signal camera_changed()

## グリッド設定が変更されたとき
signal grid_changed()


# --- Constants ---

## デフォルトのズーム値
const DEFAULT_ZOOM: float = 1.0

## ズームの最小値
const ZOOM_MIN: float = 0.1

## ズームの最大値
const ZOOM_MAX: float = 5.0

## デフォルトのグリッドサイズ（ピクセル）
const DEFAULT_GRID_SIZE: int = 32


# --- Public Variables ---

## カメラ位置
var camera_pos: Vector2 = Vector2.ZERO

## カメラのズーム倍率
var camera_zoom: float = DEFAULT_ZOOM

## グリッド表示の有効/無効
var grid_enabled: bool = true

## グリッドサイズ（ピクセル単位）
var grid_size: int = DEFAULT_GRID_SIZE

## スナップの有効/無効
var snap_enabled: bool = true

## 最後に選択されたノード ID
var last_selected_id: String = ""

## 作業メモ
var notes: String = ""


# --- Public Functions ---

## カメラ位置を設定する
##
## @param pos: 新しいカメラ位置 (Vector2)
func set_camera_pos(pos: Vector2) -> void:
	camera_pos = pos
	camera_changed.emit()


## カメラズームを設定する
##
## 値は ZOOM_MIN ～ ZOOM_MAX にクランプされる。
##
## @param zoom: 新しいズーム倍率 (float)
func set_camera_zoom(zoom: float) -> void:
	camera_zoom = clampf(zoom, ZOOM_MIN, ZOOM_MAX)
	camera_changed.emit()


## グリッド表示を切り替える
##
## @param enabled: 有効にする場合 true (bool)
func set_grid_enabled(enabled: bool) -> void:
	grid_enabled = enabled
	grid_changed.emit()


## グリッドサイズを設定する
##
## @param size: グリッドサイズ（ピクセル単位、1 以上）(int)
func set_grid_size(size: int) -> void:
	grid_size = maxi(1, size)
	grid_changed.emit()


## スナップを切り替える
##
## @param enabled: 有効にする場合 true (bool)
func set_snap_enabled(enabled: bool) -> void:
	snap_enabled = enabled
	grid_changed.emit()


## 位置をグリッドにスナップする
##
## @param pos: スナップ前の位置 (Vector2)
## @return: スナップ後の位置
func snap_position(pos: Vector2) -> Vector2:
	if not snap_enabled or grid_size <= 0:
		return pos
	var gs: float = float(grid_size)
	return Vector2(
		snapped(pos.x, gs),
		snapped(pos.y, gs),
	)


## editor_state の Dictionary からデータを復元する
##
## @param data: pack.json の editor_state セクション (Dictionary)
func load_from_dict(data: Dictionary) -> void:
	if data.has("camera"):
		var cam: Dictionary = data["camera"]
		camera_pos = Vector2(cam.get("x", 0.0), cam.get("y", 0.0))
		camera_zoom = clampf(cam.get("zoom", DEFAULT_ZOOM), ZOOM_MIN, ZOOM_MAX)

	if data.has("grid"):
		var grid: Dictionary = data["grid"]
		grid_enabled = grid.get("enabled", true)
		grid_size = maxi(1, grid.get("size", DEFAULT_GRID_SIZE))
		snap_enabled = grid.get("snap", true)

	if data.has("selection"):
		var sel: Dictionary = data["selection"]
		last_selected_id = sel.get("last_selected_node_id", "")

	notes = data.get("notes", "")


## 現在の状態を Dictionary にエクスポートする
##
## @return: pack.json の editor_state セクション形式の Dictionary
func to_dict() -> Dictionary:
	return {
		"camera": {"x": camera_pos.x, "y": camera_pos.y, "zoom": camera_zoom},
		"grid": {"enabled": grid_enabled, "size": grid_size, "snap": snap_enabled},
		"selection": {"last_selected_node_id": last_selected_id},
		"notes": notes,
	}


## 状態をデフォルトにリセットする
func reset() -> void:
	camera_pos = Vector2.ZERO
	camera_zoom = DEFAULT_ZOOM
	grid_enabled = true
	grid_size = DEFAULT_GRID_SIZE
	snap_enabled = true
	last_selected_id = ""
	notes = ""
	camera_changed.emit()
	grid_changed.emit()
