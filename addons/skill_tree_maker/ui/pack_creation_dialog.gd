@tool
class_name PackCreationDialog
extends ConfirmationDialog

## Pack 作成ダイアログ
##
## Pack ID、Pack 名、出力ディレクトリを入力し、
## バリデーション後に pack_confirmed シグナルを発火する。


# --- Signals ---

## Pack 作成が確定されたとき
signal pack_confirmed(pack_id: String, pack_name: String, out_dir: String)


# --- Constants ---

## デフォルトの出力ディレクトリ
const DEFAULT_OUTPUT_DIR: String = "res://SkillTreePacks"

## ダイアログの最小サイズ
const DIALOG_MIN_SIZE: Vector2i = Vector2i(420, 220)

## Pack ID に許可される文字パターン（英数字とアンダースコア）
const VALID_ID_PATTERN: String = "^[a-zA-Z0-9_]+$"

## エラーラベルの色
const ERROR_COLOR: Color = Color(1.0, 0.3, 0.3, 1.0)


# --- Private Variables ---

## Pack ID 入力フィールド
var _id_edit: LineEdit = null

## Pack 名入力フィールド
var _name_edit: LineEdit = null

## 出力ディレクトリ入力フィールド
var _dir_edit: LineEdit = null

## エラー表示ラベル
var _error_label: Label = null

## ID バリデーション用の正規表現
var _id_regex: RegEx = null

## 出力ディレクトリが手動編集されたか
var _dir_manually_edited: bool = false


# --- Built-in Functions ---

## ダイアログの初期設定を行う
func _ready() -> void:
	title = "New Pack"
	min_size = DIALOG_MIN_SIZE

	_id_regex = RegEx.new()
	_id_regex.compile(VALID_ID_PATTERN)

	_build_content()

	# ConfirmationDialog の確認シグナルを接続
	confirmed.connect(_on_confirmed)


# --- Public Functions ---

## ダイアログをリセットして表示する
func show_dialog() -> void:
	_reset_fields()
	popup_centered()


# --- Private Functions ---

## ダイアログのコンテンツを構築する
func _build_content() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	add_child(vbox)

	# Pack ID
	vbox.add_child(_create_label("Pack ID"))
	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "my_skill_tree"
	_id_edit.text_changed.connect(_on_id_text_changed)
	vbox.add_child(_id_edit)

	# Pack Name
	vbox.add_child(_create_label("Pack Name"))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "My Skill Tree"
	vbox.add_child(_name_edit)

	# Output Directory
	vbox.add_child(_create_label("Output Directory"))
	_dir_edit = LineEdit.new()
	_dir_edit.text = DEFAULT_OUTPUT_DIR
	_dir_edit.text_changed.connect(_on_dir_text_changed)
	vbox.add_child(_dir_edit)

	# エラーラベル
	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", ERROR_COLOR)
	_error_label.text = ""
	vbox.add_child(_error_label)


## ラベルを作成する
##
## @param text: ラベルテキスト (String)
## @return: Label インスタンス
func _create_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label


## 入力フィールドを初期状態にリセットする
func _reset_fields() -> void:
	if _id_edit != null:
		_id_edit.text = ""
	if _name_edit != null:
		_name_edit.text = ""
	if _dir_edit != null:
		_dir_edit.text = DEFAULT_OUTPUT_DIR
	if _error_label != null:
		_error_label.text = ""
	_dir_manually_edited = false


## 入力をバリデーションする
##
## @return: バリデーション成功なら true
func _validate() -> bool:
	var pack_id: String = _id_edit.text.strip_edges()

	if pack_id.is_empty():
		_error_label.text = "Pack ID is required"
		return false

	if _id_regex.search(pack_id) == null:
		_error_label.text = "Pack ID must contain only a-z, A-Z, 0-9, _"
		return false

	var pack_name: String = _name_edit.text.strip_edges()
	if pack_name.is_empty():
		_error_label.text = "Pack Name is required"
		return false

	_error_label.text = ""
	return true


# --- Signal Callbacks ---

## ID テキスト変更時に出力ディレクトリを自動更新する
##
## @param new_text: 新しい ID テキスト (String)
func _on_id_text_changed(new_text: String) -> void:
	if not _dir_manually_edited:
		var id: String = new_text.strip_edges()
		if id.is_empty():
			_dir_edit.text = DEFAULT_OUTPUT_DIR
		else:
			_dir_edit.text = DEFAULT_OUTPUT_DIR.path_join(id)


## 出力ディレクトリが手動編集されたことを記録する
##
## @param _new_text: 新しいテキスト (String)
func _on_dir_text_changed(_new_text: String) -> void:
	_dir_manually_edited = true


## 確認ボタン押下時のバリデーションとシグナル発火
func _on_confirmed() -> void:
	if not _validate():
		# バリデーション失敗時はダイアログを再表示（入力内容を保持）
		popup_centered()
		return

	var pack_id: String = _id_edit.text.strip_edges()
	var pack_name: String = _name_edit.text.strip_edges()
	var out_dir: String = _dir_edit.text.strip_edges()

	pack_confirmed.emit(pack_id, pack_name, out_dir)
