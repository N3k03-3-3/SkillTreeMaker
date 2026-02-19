class_name PackLoader
extends RefCounted

## ゲームランタイム用の Pack ローダー
##
## runtime.json と theme.json を読み込み、
## ゲーム内でスキルツリーを表示するために必要なデータ一式を返す。


# --- Constants ---

## runtime.json ファイル名
const RUNTIME_FILE: String = "runtime.json"

## サポートするスキーマバージョン
const SUPPORTED_SCHEMA_VERSION: int = 1


# --- Private Variables ---

## テーマ解決サービス
var _theme_resolver: ThemeResolver = null


# --- Public Functions ---

## runtime.json とテーマを一括で読み込む
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: {"runtime": Dictionary, "theme": Dictionary}。失敗時は空の Dictionary
func load_pack(pack_root: String) -> Dictionary:
	if pack_root.is_empty():
		push_error("[PackLoader] load_pack: pack_root is empty")
		return {}

	# runtime.json 読み込み
	var runtime_data: Dictionary = load_runtime(pack_root)
	if runtime_data.is_empty():
		return {}

	# テーマパスを runtime.json の tree.theme_ref から取得
	var tree: Dictionary = runtime_data.get("tree", {})
	var theme_ref: String = tree.get("theme_ref", "theme/theme.json")
	var theme_path: String = pack_root.path_join(theme_ref)

	# ThemeResolver でテーマを読み込み
	_theme_resolver = ThemeResolver.new()
	var theme_loaded: bool = _theme_resolver.load_theme(theme_path)
	if not theme_loaded:
		push_warning("[PackLoader] load_pack: theme load failed, using empty theme: " + theme_path)

	var theme_data: Dictionary = _theme_resolver.get_theme_data()

	return {
		"runtime": runtime_data,
		"theme": theme_data,
	}


## runtime.json を読み込んでパースされた Dictionary を返す
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: runtime.json の Dictionary。失敗時は空の Dictionary
func load_runtime(pack_root: String) -> Dictionary:
	if pack_root.is_empty():
		push_error("[PackLoader] load_runtime: pack_root is empty")
		return {}

	var runtime_path: String = pack_root.path_join(RUNTIME_FILE)
	var data: Dictionary = _read_json(runtime_path)
	if data.is_empty():
		return {}

	# スキーマバージョンチェック
	var version: int = data.get("schema_version", 0)
	if version != SUPPORTED_SCHEMA_VERSION:
		push_error("[PackLoader] load_runtime: unsupported schema version: " + str(version))
		return {}

	return data


## 内部の ThemeResolver インスタンスを取得する
##
## @return: ThemeResolver。未初期化なら null
func get_theme_resolver() -> ThemeResolver:
	return _theme_resolver


## アセットの相対パスを絶対パスに解決する
##
## @param relative_path: テーマからの相対パス (String)
## @return: 解決された絶対パス。ThemeResolver 未初期化なら空文字列
func resolve_asset(relative_path: String) -> String:
	if _theme_resolver == null:
		push_error("[PackLoader] resolve_asset: theme_resolver is not initialized")
		return ""
	return _theme_resolver.resolve_asset(relative_path)


# --- Private Functions ---

## JSON ファイルを読み込んで Dictionary を返す
##
## @param path: ファイルパス (String)
## @return: パースされた Dictionary。失敗時は空の Dictionary
func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[PackLoader] _read_json: cannot open file: " + path)
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text)
	if error != OK:
		push_error("[PackLoader] _read_json: JSON parse error in " + path + ": " + json.get_error_message())
		return {}

	if json.data is Dictionary:
		return json.data
	push_error("[PackLoader] _read_json: root is not Dictionary in " + path)
	return {}
