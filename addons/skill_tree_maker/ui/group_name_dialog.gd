@tool
class_name GroupNameDialog
extends ConfirmationDialog

## グループ名入力ダイアログ
##
## 新規グループの ID を入力し、バリデーション後に
## group_name_confirmed シグナルを発火する。


# --- Signals ---

## グループ名が確定されたとき
signal group_name_confirmed(group_id: String)


# --- Constants ---

## ダイアログの最小サイズ
const DIALOG_MIN_SIZE: Vector2i = Vector2i(320, 140)

## グループ ID に許可される文字パターン（英数字とアンダースコア）
const VALID_ID_PATTERN: String = "^[a-zA-Z0-9_]+$"

## エラーラベルの色
const ERROR_COLOR: Color = Color(1.0, 0.3, 0.3, 1.0)


# --- Private Variables ---

## グループ ID 入力フィールド
var _id_edit: LineEdit = null

## エラー表示ラベル
var _error_label: Label = null

## ID バリデーション用の正規表現
var _id_regex: RegEx = null


# --- Built-in Functions ---

## ダイアログの初期設定を行う
func _ready() -> void:
	title = "New Group"
	min_size = DIALOG_MIN_SIZE

	_id_regex = RegEx.new()
	_id_regex.compile(VALID_ID_PATTERN)

	_build_content()

	# ConfirmationDialog の確認シグナルを接続
	confirmed.connect(_on_confirmed)


# --- Public Functions ---

## ダイアログをリセットして表示する
func show_dialog() -> void:
	if _id_edit != null:
		_id_edit.text = ""
	if _error_label != null:
		_error_label.text = ""
	popup_centered()


# --- Private Functions ---

## ダイアログのコンテンツを構築する
func _build_content() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	add_child(vbox)

	var label: Label = Label.new()
	label.text = "Group ID"
	vbox.add_child(label)

	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "my_group"
	vbox.add_child(_id_edit)

	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", ERROR_COLOR)
	_error_label.text = ""
	vbox.add_child(_error_label)


## 入力をバリデーションする
##
## @return: バリデーション成功なら true
func _validate() -> bool:
	var group_id: String = _id_edit.text.strip_edges()

	if group_id.is_empty():
		_error_label.text = "Group ID is required"
		return false

	if _id_regex.search(group_id) == null:
		_error_label.text = "Group ID must contain only a-z, A-Z, 0-9, _"
		return false

	_error_label.text = ""
	return true


# --- Signal Callbacks ---

## 確認ボタン押下時のバリデーションとシグナル発火
func _on_confirmed() -> void:
	if not _validate():
		# バリデーション失敗時はダイアログを再表示（入力内容を保持）
		popup_centered()
		return

	group_name_confirmed.emit(_id_edit.text.strip_edges())
