@tool
extends EditorPlugin

## SkillTreeMaker の EditorPlugin エントリポイント
##
## プラグインのライフサイクル管理を行う。
## 有効化時にメインドックを追加し、無効化時に削除する。


# --- Constants ---

## プラグイン名
const PLUGIN_NAME: String = "SkillTreeMaker"

## ドックの最小サイズ
const DOCK_MIN_SIZE: Vector2 = Vector2(300, 200)


# --- Private Variables ---

## メインドックインスタンス
var _dock: SkillTreeMakerDock = null


# --- Built-in Functions ---

## プラグイン有効化時に呼ばれる
func _enter_tree() -> void:
	_dock = SkillTreeMakerDock.new()
	_dock.custom_minimum_size = DOCK_MIN_SIZE
	add_control_to_bottom_panel(_dock, PLUGIN_NAME)
	print("[SkillTreeMaker] Plugin enabled")


## プラグイン無効化時に呼ばれる
func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
	print("[SkillTreeMaker] Plugin disabled")
