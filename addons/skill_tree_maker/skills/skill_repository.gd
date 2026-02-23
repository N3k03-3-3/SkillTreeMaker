class_name SkillRepository
extends RefCounted

## スキルデータの永続化を担当するリポジトリクラス
##
## skills.json の読み書き、任意パスへの JSON インポート・エクスポートを提供する。
## ファイル I/O には DirAccess / FileAccess を使用する。


# --- Constants ---

## スキルライブラリのデフォルトディレクトリ
const DEFAULT_SKILLS_DIR: String = "res://SkillLibrary"

## スキルデータファイル名
const SKILLS_FILE: String = "skills.json"

## JSON スキーマバージョン
const SCHEMA_VERSION: int = 1


# --- Public Functions ---

## 指定ディレクトリの skills.json からスキル一覧を読み込む
##
## @param dir_path: スキルデータが格納されたディレクトリパス (String)
## @return: 読み込まれた SkillEntry の配列。失敗時は空配列
func load_skills(dir_path: String) -> Array[SkillEntry]:
	var file_path: String = dir_path.path_join(SKILLS_FILE)
	return import_json(file_path)


## スキル一覧を指定ディレクトリの skills.json へ保存する
##
## @param entries: 保存する SkillEntry の配列
## @param dir_path: 保存先ディレクトリパス (String)
## @return: 保存成功なら true
func save_skills(entries: Array[SkillEntry], dir_path: String) -> bool:
	# ディレクトリが存在しなければ作成する
	if not DirAccess.dir_exists_absolute(dir_path):
		var err: Error = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("[SkillRepository] save_skills: failed to create directory: " + dir_path)
			return false

	var file_path: String = dir_path.path_join(SKILLS_FILE)
	return export_json(entries, file_path)


## 任意の JSON ファイルパスからスキル一覧をインポートする
##
## @param file_path: JSON ファイルの絶対パス (String)
## @return: 読み込まれた SkillEntry の配列。失敗時は空配列
func import_json(file_path: String) -> Array[SkillEntry]:
	var result: Array[SkillEntry] = []

	if not FileAccess.file_exists(file_path):
		push_error("[SkillRepository] import_json: file not found: " + file_path)
		return result

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SkillRepository] import_json: failed to open file: " + file_path)
		return result

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK:
		push_error("[SkillRepository] import_json: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return result

	var data: Variant = json.data
	if not data is Dictionary:
		push_error("[SkillRepository] import_json: root must be a Dictionary")
		return result

	var root: Dictionary = data as Dictionary
	if not root.has("skills"):
		push_error("[SkillRepository] import_json: missing 'skills' key")
		return result

	var skills_array: Variant = root["skills"]
	if not skills_array is Array:
		push_error("[SkillRepository] import_json: 'skills' must be an Array")
		return result

	for item: Variant in skills_array:
		if item is Dictionary:
			result.append(SkillEntry.from_dict(item as Dictionary))

	return result


## スキル一覧を任意の JSON ファイルパスへエクスポートする
##
## @param entries: エクスポートする SkillEntry の配列
## @param file_path: 出力先 JSON ファイルの絶対パス (String)
## @return: エクスポート成功なら true
func export_json(entries: Array[SkillEntry], file_path: String) -> bool:
	var skills_array: Array[Dictionary] = []
	for entry: SkillEntry in entries:
		skills_array.append(entry.to_dict())

	var root: Dictionary = {
		"version": SCHEMA_VERSION,
		"skills": skills_array,
	}

	var json_text: String = JSON.stringify(root, "\t")

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SkillRepository] export_json: failed to open file for writing: " + file_path)
		return false

	file.store_string(json_text)
	file.close()
	return true
