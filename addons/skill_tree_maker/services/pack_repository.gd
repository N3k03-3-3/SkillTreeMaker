class_name PackRepository
extends RefCounted

## Pack のファイル I/O を管理するサービス
##
## pack.json の読み込み・保存、ディレクトリ構造の作成を行う。
## ステートレスに設計されており、毎回パスを受け取って処理する。


# --- Constants ---

## Pack スキーマバージョン
const SCHEMA_VERSION: int = 1

## pack.json ファイル名
const PACK_FILE: String = "pack.json"

## runtime.json ファイル名
const RUNTIME_FILE: String = "runtime.json"

## theme.json ファイル名
const THEME_FILE: String = "theme/theme.json"

## 必須ディレクトリ一覧 (Array[String])
const REQUIRED_DIRS: Array[String] = [
	"theme",
	"theme/textures",
	"theme/ninepatch",
	"theme/fonts",
	"theme/vfx",
]

## 推奨ディレクトリ一覧 (Array[String])
const OPTIONAL_DIRS: Array[String] = [
	"icons",
	"locale",
	"previews",
	"meta",
]


# --- Public Functions ---

## Pack を読み込んで SkillTreeModel に変換する
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: 読み込まれた SkillTreeModel。失敗時は null
func load_pack(pack_root: String) -> SkillTreeModel:
	if pack_root.is_empty():
		push_error("[PackRepository] load_pack: pack_root is empty")
		return null

	var pack_path: String = pack_root.path_join(PACK_FILE)
	if not FileAccess.file_exists(pack_path):
		push_error("[PackRepository] load_pack: pack.json not found: " + pack_path)
		return null

	# pack.json 読み込み
	var pack_data: Dictionary = _read_json(pack_path)
	if pack_data.is_empty():
		push_error("[PackRepository] load_pack: failed to parse pack.json: " + pack_path)
		return null

	# runtime.json 読み込み（存在する場合）
	var runtime_path: String = pack_root.path_join(RUNTIME_FILE)
	var runtime_data: Dictionary = {}
	if FileAccess.file_exists(runtime_path):
		runtime_data = _read_json(runtime_path)

	# モデルに変換
	var model: SkillTreeModel = _build_model(pack_data, runtime_data)
	return model


## SkillTreeModel を pack.json として保存する
##
## @param model: 保存する SkillTreeModel (SkillTreeModel)
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: 保存成功なら true
func save_pack(model: SkillTreeModel, pack_root: String) -> bool:
	if model == null:
		push_error("[PackRepository] save_pack: model is null")
		return false
	if pack_root.is_empty():
		push_error("[PackRepository] save_pack: pack_root is empty")
		return false

	_ensure_directory_structure(pack_root)

	# pack.json 構築
	var pack_data: Dictionary = _build_pack_json(model)

	# 書き出し
	var pack_path: String = pack_root.path_join(PACK_FILE)
	var success: bool = _write_json(pack_path, pack_data)
	if not success:
		push_error("[PackRepository] save_pack: failed to write pack.json: " + pack_path)
		return false

	# runtime.json 構築・書き出し
	var runtime_data: Dictionary = _build_runtime_json(model)
	var runtime_path: String = pack_root.path_join(RUNTIME_FILE)
	success = _write_json(runtime_path, runtime_data)
	if not success:
		push_error("[PackRepository] save_pack: failed to write runtime.json: " + runtime_path)
		return false

	return true


## 新しい Pack を作成する
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @param pack_id: Pack の識別子 (String)
## @param pack_name: Pack の表示名 (String)
## @param theme_preset: テーマプリセット名 (String)。ThemePresetLibrary.PRESET_* 参照。デフォルトは "default"
## @return: 作成された SkillTreeModel。失敗時は null
func create_pack(pack_root: String, pack_id: String, pack_name: String, theme_preset: String = ThemePresetLibrary.PRESET_DEFAULT) -> SkillTreeModel:
	if pack_root.is_empty():
		push_error("[PackRepository] create_pack: pack_root is empty")
		return null
	if pack_id.is_empty():
		push_error("[PackRepository] create_pack: pack_id is empty")
		return null

	_ensure_directory_structure(pack_root)

	# 新規モデル作成
	var model: SkillTreeModel = SkillTreeModel.new()
	var now: String = Time.get_datetime_string_from_system(false, true)

	model.pack_meta = {
		"id": pack_id,
		"name": pack_name,
		"author": "",
		"created_at": now,
		"updated_at": now,
		"tags": [],
	}

	model.paths = {
		"runtime": RUNTIME_FILE,
		"theme": THEME_FILE,
		"icons_dir": "icons",
		"locale_dir": "locale",
		"preview_dir": "previews",
	}

	model.tree_meta = {
		"id": pack_id,
		"display_name_key": "tree." + pack_id + ".name",
		"description_key": "tree." + pack_id + ".desc",
		"theme_ref": THEME_FILE,
		"entry_nodes": [],
		"unlock_rule": SkillTreeModel.UNLOCK_RULE_REQUIRES,
		"layout": {
			"coordinate_space": "group_local",
			"groups": [],
		},
	}

	model.tool_state = ToolState.new()
	model.draft = {"unused_nodes": [], "guides": []}

	# デフォルトグループを追加
	model.add_group(SkillTreeModel.DEFAULT_GROUP_ID, Vector2.ZERO)

	# 初回保存
	var success: bool = save_pack(model, pack_root)
	if not success:
		push_error("[PackRepository] create_pack: failed to save initial pack")
		return null

	# テーマプリセットで theme.json を作成
	_create_theme_from_preset(pack_root, theme_preset)

	return model


## pack.json が存在するか判定する
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @return: pack.json が存在すれば true
func pack_exists(pack_root: String) -> bool:
	if pack_root.is_empty():
		return false
	return FileAccess.file_exists(pack_root.path_join(PACK_FILE))


# --- Private Functions ---

## ディレクトリ構造を保証する
##
## 必須・推奨ディレクトリを作成する。
## theme.json の生成は create_pack の _create_theme_from_preset に委譲する。
##
## @param pack_root: Pack ルートディレクトリのパス (String)
func _ensure_directory_structure(pack_root: String) -> void:
	if not DirAccess.dir_exists_absolute(pack_root):
		DirAccess.make_dir_recursive_absolute(pack_root)

	for dir_name: String in REQUIRED_DIRS:
		var dir_path: String = pack_root.path_join(dir_name)
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)

	for dir_name: String in OPTIONAL_DIRS:
		var dir_path: String = pack_root.path_join(dir_name)
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)


## JSON ファイルを読み込む
##
## @param path: ファイルパス (String)
## @return: パースされた Dictionary。失敗時は空の Dictionary
func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[PackRepository] _read_json: cannot open file: " + path)
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text)
	if error != OK:
		push_error("[PackRepository] _read_json: JSON parse error in " + path + ": " + json.get_error_message())
		return {}

	if json.data is Dictionary:
		return json.data
	push_error("[PackRepository] _read_json: root is not Dictionary in " + path)
	return {}


## Dictionary を JSON ファイルに書き出す
##
## @param path: ファイルパス (String)
## @param data: 書き出すデータ (Dictionary)
## @return: 書き出し成功なら true
func _write_json(path: String, data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data, "\t")

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[PackRepository] _write_json: cannot open file for writing: " + path)
		return false

	file.store_string(json_text)
	file.close()
	return true


## pack.json と runtime.json から SkillTreeModel を構築する
##
## @param pack_data: pack.json のデータ (Dictionary)
## @param runtime_data: runtime.json のデータ (Dictionary)
## @return: 構築された SkillTreeModel
func _build_model(pack_data: Dictionary, runtime_data: Dictionary) -> SkillTreeModel:
	var model: SkillTreeModel = SkillTreeModel.new()

	# pack.json からメタデータを復元
	model.pack_meta = pack_data.get("pack", {})
	model.paths = pack_data.get("paths", {})
	model.draft = pack_data.get("draft", {})

	# editor_state から ToolState を復元
	model.tool_state = ToolState.new()
	var editor_state: Dictionary = pack_data.get("editor_state", {})
	model.tool_state.load_from_dict(editor_state)

	# runtime.json からツリーデータを復元
	if not runtime_data.is_empty():
		model.tree_meta = runtime_data.get("tree", {})

		# 後方互換: entry_node_id → entry_nodes 変換
		if not model.tree_meta.has("entry_nodes") and model.tree_meta.has("entry_node_id"):
			var old_entry_id: String = model.tree_meta.get("entry_node_id", "")
			if not old_entry_id.is_empty():
				model.tree_meta["entry_nodes"] = [{"class_id": "default", "node_id": old_entry_id}]
			else:
				model.tree_meta["entry_nodes"] = []

		# unlock_rule のデフォルト設定
		if not model.tree_meta.has("unlock_rule"):
			model.tree_meta["unlock_rule"] = SkillTreeModel.UNLOCK_RULE_REQUIRES

		# グループを復元
		var layout: Dictionary = model.tree_meta.get("layout", {})
		var groups: Array = layout.get("groups", [])
		for group: Dictionary in groups:
			var group_id: String = group.get("id", "")
			var center: Dictionary = group.get("center", {})
			if not group_id.is_empty():
				model.add_group(group_id, Vector2(center.get("x", 0.0), center.get("y", 0.0)))

		# ノードを復元（node_type のデフォルト補完を含む）
		var nodes: Array = runtime_data.get("nodes", [])
		for node: Dictionary in nodes:
			if not node.has("node_type"):
				node["node_type"] = SkillTreeModel.NODE_TYPE_MINOR
			model.add_node(node)

		# エッジ復元前にノードの requires をクリア（add_edge が再構築するため）
		for node: Dictionary in nodes:
			if node.has("unlock") and node["unlock"].has("requires"):
				node["unlock"]["requires"] = []

		# エッジを復元
		var edges: Array = runtime_data.get("edges", [])
		for edge: Dictionary in edges:
			var from_id: String = edge.get("from", "")
			var to_id: String = edge.get("to", "")
			var style_preset: String = edge.get("style_preset", "edge_default")
			if not from_id.is_empty() and not to_id.is_empty():
				model.add_edge(from_id, to_id, style_preset)

		# グループエッジを復元
		var group_edges: Array = runtime_data.get("group_edges", [])
		for ge: Dictionary in group_edges:
			var from_id: String = ge.get("from", "")
			var to_id: String = ge.get("to", "")
			if not from_id.is_empty() and not to_id.is_empty():
				model.add_group_edge(from_id, to_id)

	return model


## SkillTreeModel から pack.json 形式の Dictionary を構築する
##
## @param model: ソースモデル (SkillTreeModel)
## @return: pack.json 形式の Dictionary
func _build_pack_json(model: SkillTreeModel) -> Dictionary:
	# updated_at を更新
	var pack_meta: Dictionary = model.pack_meta.duplicate(true)
	pack_meta["updated_at"] = Time.get_datetime_string_from_system(false, true)

	# ToolState を Dictionary に変換
	var editor_state: Dictionary = {}
	if model.tool_state != null:
		editor_state = model.tool_state.to_dict()

	return {
		"schema_version": SCHEMA_VERSION,
		"pack": pack_meta,
		"paths": model.paths,
		"editor_state": editor_state,
		"draft": model.draft,
	}


## SkillTreeModel から runtime.json 形式の Dictionary を構築する
##
## @param model: ソースモデル (SkillTreeModel)
## @return: runtime.json 形式の Dictionary
func _build_runtime_json(model: SkillTreeModel) -> Dictionary:
	# グループをレイアウトに変換
	var groups_array: Array = []
	for group: Dictionary in model.get_all_groups():
		groups_array.append(group)

	var tree: Dictionary = model.tree_meta.duplicate(true)
	if not tree.has("layout"):
		tree["layout"] = {}
	tree["layout"]["groups"] = groups_array

	# entry_nodes と unlock_rule を確実に出力
	if not tree.has("entry_nodes"):
		tree["entry_nodes"] = []
	if not tree.has("unlock_rule"):
		tree["unlock_rule"] = SkillTreeModel.UNLOCK_RULE_REQUIRES

	# ノード配列
	var nodes_array: Array = model.get_all_nodes()

	# エッジ配列
	var edges_array: Array = model.get_all_edges()

	return {
		"schema_version": SCHEMA_VERSION,
		"tree": tree,
		"nodes": nodes_array,
		"edges": edges_array,
		"group_edges": model.get_all_group_edges(),
	}


## 指定プリセットで theme.json を作成する
##
## theme.json が既に存在する場合は何もしない。
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @param preset_name: テーマプリセット名 (String)
func _create_theme_from_preset(pack_root: String, preset_name: String) -> void:
	var theme_path: String = pack_root.path_join(THEME_FILE)
	if FileAccess.file_exists(theme_path):
		return

	var theme_data: Dictionary = ThemePresetLibrary.create_preset(preset_name)
	_write_json(theme_path, theme_data)
