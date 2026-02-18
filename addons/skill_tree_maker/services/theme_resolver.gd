class_name ThemeResolver
extends RefCounted

## テーマファイルの読み込みとアセットパス解決を担当するサービス
##
## theme.json を読み込み、相対パスの解決と参照アセットの収集を行う。


# --- Constants ---

## theme.json ファイル名
const THEME_FILE_NAME: String = "theme.json"

## デフォルトスキーマバージョン
const DEFAULT_SCHEMA_VERSION: int = 1


# --- Private Variables ---

## 読み込んだテーマデータ
var _theme_data: Dictionary = {}

## テーマファイルのベースディレクトリ
var _base_dir: String = ""


# --- Public Functions ---

## theme.json を読み込む
##
## FileAccess で JSON を読み込み、_base_dir をテーマファイルの親ディレクトリに設定する。
##
## @param theme_path: theme.json のファイルパス (String)
## @return: 読み込み成功なら true
func load_theme(theme_path: String) -> bool:
	if theme_path.is_empty():
		push_error("[ThemeResolver] load_theme: theme_path is empty")
		return false

	if not FileAccess.file_exists(theme_path):
		push_error("[ThemeResolver] load_theme: file not found: " + theme_path)
		return false

	var file: FileAccess = FileAccess.open(theme_path, FileAccess.READ)
	if file == null:
		push_error("[ThemeResolver] load_theme: cannot open file: " + theme_path)
		return false

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text)
	if error != OK:
		push_error("[ThemeResolver] load_theme: JSON parse error in " + theme_path + ": " + json.get_error_message())
		return false

	if not json.data is Dictionary:
		push_error("[ThemeResolver] load_theme: root is not Dictionary in " + theme_path)
		return false

	_theme_data = json.data
	_base_dir = theme_path.get_base_dir()
	return true


## テーマデータを取得する
##
## @return: 読み込まれたテーマデータの Dictionary
func get_theme_data() -> Dictionary:
	return _theme_data


## 相対パスをフルパスに解決する
##
## _base_dir と path_join で結合し、テーマファイルからの相対パスを絶対パスに変換する。
##
## @param relative_path: テーマファイルからの相対パス (String)
## @return: 解決されたフルパス (String)
func resolve_asset(relative_path: String) -> String:
	if relative_path.is_empty():
		return ""
	return _base_dir.path_join(relative_path)


## モデル内で参照される全アセットパスを収集する
##
## theme.json 内のテクスチャ・フォント参照と、モデル内の各ノードの icon_path を
## すべて収集し、空文字列を除外・重複排除して返す。
##
## @param model: アセット参照を収集する対象のモデル (SkillTreeModel)
## @return: 参照される全アセットの相対パス配列
func collect_references(model: SkillTreeModel) -> Array[String]:
	var refs: Array[String] = []

	# theme.json: background.texture
	var bg: Dictionary = _theme_data.get("background", {})
	_append_if_valid(refs, bg.get("texture", ""))

	# theme.json: window.frame_9slice
	var window: Dictionary = _theme_data.get("window", {})
	_append_if_valid(refs, window.get("frame_9slice", ""))

	# theme.json: node_presets 内の各プリセット
	var node_presets: Dictionary = _theme_data.get("node_presets", {})
	for preset_key: String in node_presets.keys():
		var preset: Dictionary = node_presets[preset_key]
		_append_if_valid(refs, preset.get("base_texture", ""))
		var states: Dictionary = preset.get("states", {})
		for state_key: String in states.keys():
			var state: Dictionary = states[state_key]
			_append_if_valid(refs, state.get("overlay", ""))

	# theme.json: effects 内の各エフェクト
	var effects: Dictionary = _theme_data.get("effects", {})
	for effect_key: String in effects.keys():
		var effect: Dictionary = effects[effect_key]
		_append_if_valid(refs, effect.get("texture", ""))

	# theme.json: fonts 内の各フォント
	var fonts: Dictionary = _theme_data.get("fonts", {})
	for font_key: String in fonts.keys():
		_append_if_valid(refs, fonts[font_key])

	# model: 全ノードの icon_path
	if model != null:
		var nodes: Array = model.get_all_nodes()
		for node: Dictionary in nodes:
			_append_if_valid(refs, node.get("icon_path", ""))

	return refs


## ノードプリセットを取得する
##
## @return: node_presets の Dictionary
func get_node_presets() -> Dictionary:
	return _theme_data.get("node_presets", {})


## エッジプリセットを取得する
##
## @return: edge_presets の Dictionary
func get_edge_presets() -> Dictionary:
	return _theme_data.get("edge_presets", {})


## テーマが読み込まれているか判定する
##
## @return: テーマデータが読み込まれていれば true
func is_loaded() -> bool:
	return not _theme_data.is_empty()


## 現在のテーマデータをファイルに保存する
##
## @param theme_path: 保存先の theme.json パス (String)
## @return: 保存成功なら true
func save_theme(theme_path: String) -> bool:
	if theme_path.is_empty():
		push_error("[ThemeResolver] save_theme: theme_path is empty")
		return false
	if _theme_data.is_empty():
		push_error("[ThemeResolver] save_theme: no theme data loaded")
		return false

	var json_text: String = JSON.stringify(_theme_data, "\t")
	var file: FileAccess = FileAccess.open(theme_path, FileAccess.WRITE)
	if file == null:
		push_error("[ThemeResolver] save_theme: cannot open file for writing: " + theme_path)
		return false

	file.store_string(json_text)
	file.close()
	return true


# --- Private Functions ---

## 有効な（空でない・重複しない）パスを配列に追加する
##
## @param refs: 追加先の配列 (Array[String])
## @param path: 追加するパス (String)
func _append_if_valid(refs: Array[String], path: String) -> void:
	if path.is_empty():
		return
	if refs.has(path):
		return
	refs.append(path)
