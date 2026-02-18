class_name RuntimeExporter
extends RefCounted

## runtime.json の書き出しとアセットコピーを行うサービス
##
## SkillTreeModel からランタイムデータを構築し、
## バリデーションを通してから書き出す。
## 参照アセットのコピーも行う。


# --- Constants ---

## runtime.json ファイル名
const RUNTIME_FILE: String = "runtime.json"

## スキーマバージョン
const SCHEMA_VERSION: int = 1


# --- Private Variables ---

## テーマ解決サービス
var _theme_resolver: ThemeResolver = null

## 検証サービス
var _validator: Validator = null


# --- Public Functions ---

## 依存サービスを設定する
##
## @param theme_resolver: ThemeResolver インスタンス (ThemeResolver)
## @param validator: Validator インスタンス (Validator)
func setup(theme_resolver: ThemeResolver, validator: Validator) -> void:
	_theme_resolver = theme_resolver
	_validator = validator


## モデルからランタイムデータを構築する
##
## ノード・エッジ・ツリーメタから、ゲームが読む最小限の runtime.json データを生成する。
## editor_state や draft は含まない。
##
## @param model: ソース SkillTreeModel (SkillTreeModel)
## @return: runtime.json 形式の Dictionary。失敗時は空の Dictionary
func build_runtime(model: SkillTreeModel) -> Dictionary:
	if model == null:
		push_error("[RuntimeExporter] build_runtime: model is null")
		return {}

	# グループ配列構築
	var groups_array: Array = []
	for group: Dictionary in model.get_all_groups():
		groups_array.append(group.duplicate(true))

	# ツリーメタ構築
	var tree: Dictionary = model.tree_meta.duplicate(true)
	if not tree.has("layout"):
		tree["layout"] = {}
	tree["layout"]["groups"] = groups_array

	# ノード配列（editor のみの情報を除外）
	var nodes_array: Array = []
	for node: Dictionary in model.get_all_nodes():
		nodes_array.append(_sanitize_node(node))

	# エッジ配列
	var edges_array: Array = []
	for edge: Dictionary in model.get_all_edges():
		edges_array.append(edge.duplicate(true))

	return {
		"schema_version": SCHEMA_VERSION,
		"tree": tree,
		"nodes": nodes_array,
		"edges": edges_array,
	}


## ランタイムデータを書き出す
##
## バリデーション → 構築 → JSON 書き出しを一連で行う。
## バリデーションエラーがある場合は書き出しを中止し、レポートを返す。
## 警告のみの場合は書き出しを続行する。
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @param model: ソースモデル (SkillTreeModel)
## @return: ValidationReport（エラーなしなら has_errors() == false）
func write_runtime(pack_root: String, model: SkillTreeModel) -> Validator.ValidationReport:
	var report: Validator.ValidationReport = Validator.ValidationReport.new()

	# バリデーション実行
	if _validator != null:
		report = _validator.validate(model)

	if report.has_errors():
		push_warning("[RuntimeExporter] write_runtime: validation failed, aborting export")
		return report

	# ランタイムデータ構築
	var runtime_data: Dictionary = build_runtime(model)
	if runtime_data.is_empty():
		report.add_error("export", "Failed to build runtime data")
		return report

	# JSON 書き出し
	var runtime_path: String = pack_root.path_join(RUNTIME_FILE)
	var success: bool = _write_json(runtime_path, runtime_data)
	if not success:
		report.add_error("export", "Failed to write runtime.json: " + runtime_path)

	return report


## 参照アセットを Pack フォルダへコピーする
##
## ThemeResolver でアセット参照を収集し、まだコピーされていないファイルを
## Pack ルート内の適切な場所にコピーする。
##
## @param pack_root: Pack ルートディレクトリのパス (String)
## @param model: アセット参照を持つモデル (SkillTreeModel)
## @return: コピーされたファイル数
func copy_assets(pack_root: String, model: SkillTreeModel) -> int:
	if _theme_resolver == null:
		push_error("[RuntimeExporter] copy_assets: theme_resolver is null")
		return 0

	# テーマ読み込み（未読み込みの場合）
	if not _theme_resolver.is_loaded():
		var theme_path: String = pack_root.path_join(
			model.paths.get("theme", "theme/theme.json"))
		_theme_resolver.load_theme(theme_path)

	var refs: Array[String] = _theme_resolver.collect_references(model)
	var copied_count: int = 0

	for ref_path: String in refs:
		var source: String = _theme_resolver.resolve_asset(ref_path)
		var dest: String = pack_root.path_join(ref_path)

		if source.is_empty() or not FileAccess.file_exists(source):
			continue

		if FileAccess.file_exists(dest):
			continue

		# コピー先ディレクトリを確保
		var dest_dir: String = dest.get_base_dir()
		if not DirAccess.dir_exists_absolute(dest_dir):
			DirAccess.make_dir_recursive_absolute(dest_dir)

		var err: Error = DirAccess.copy_absolute(source, dest)
		if err == OK:
			copied_count += 1
		else:
			push_warning("[RuntimeExporter] copy_assets: failed to copy "
				+ source + " -> " + dest)

	return copied_count


# --- Private Functions ---

## ノードデータからエディタ専用フィールドを除外する
##
## 現在は deep duplicate のみ。将来エディタ専用フィールドが追加された場合、
## ここで除外する。
##
## @param node: 元のノードデータ (Dictionary)
## @return: サニタイズされたノードデータ
func _sanitize_node(node: Dictionary) -> Dictionary:
	return node.duplicate(true)


## Dictionary を JSON ファイルに書き出す
##
## @param path: ファイルパス (String)
## @param data: 書き出すデータ (Dictionary)
## @return: 書き出し成功なら true
func _write_json(path: String, data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[RuntimeExporter] _write_json: cannot open file: " + path)
		return false

	file.store_string(json_text)
	file.close()
	return true
