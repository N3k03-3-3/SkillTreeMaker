@tool
class_name SkillCreationDialog
extends Window

## スキル作成・編集ダイアログ
##
## スキルの各フィールド（ID、名前、説明、カテゴリ、アイコン、
## 最大レベル、タグ、ステータス）を入力し、確定時に SkillEntry を返す。


# --- Signals ---

## スキルが確定されたとき
signal skill_confirmed(skill: SkillEntry)


# --- Constants ---

## ダイアログの幅
const DIALOG_WIDTH: int = 480

## ダイアログの高さ
const DIALOG_HEIGHT: int = 620

## ステータス値の最小値
const STAT_VALUE_MIN: int = -9999

## ステータス値の最大値
const STAT_VALUE_MAX: int = 9999

## ステータス値のステップ
const STAT_VALUE_STEP: int = 1

## レベル最小値
const LEVEL_MIN: int = 1

## レベル最大値
const LEVEL_MAX: int = 99

## カテゴリ選択肢
const CATEGORY_OPTIONS: PackedStringArray = PackedStringArray(["active", "passive", "toggle"])


# --- Private Variables ---

## ID 入力
var _id_edit: LineEdit = null

## 名前入力
var _name_edit: LineEdit = null

## 説明入力
var _desc_edit: TextEdit = null

## カテゴリ選択
var _category_button: OptionButton = null

## アイコンパス入力
var _icon_edit: LineEdit = null

## 最大レベル入力
var _level_spin: SpinBox = null

## タグ入力（カンマ区切り）
var _tags_edit: LineEdit = null

## ステータス行を格納するコンテナ
var _stats_container: VBoxContainer = null

## ファイル選択ダイアログ
var _file_dialog: FileDialog = null


# --- Built-in Functions ---

func _ready() -> void:
	title = "Create / Edit Skill"
	size = Vector2i(DIALOG_WIDTH, DIALOG_HEIGHT)
	unresizable = false
	close_requested.connect(_on_cancel_pressed)
	_build_ui()


# --- Public Functions ---

## ダイアログを表示する
##
## @param existing_skill: 編集対象のスキル。null なら新規作成モード
func show_dialog(existing_skill: SkillEntry = null) -> void:
	_clear_fields()
	if existing_skill != null:
		_populate_from_skill(existing_skill)
	popup_centered()


# --- Private Functions ---

## UI を構築する
func _build_ui() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# タイトル
	var title_label: Label = Label.new()
	title_label.text = "Create / Edit Skill"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# ID
	vbox.add_child(_create_label("ID"))
	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "skill_id"
	vbox.add_child(_id_edit)

	# Name
	vbox.add_child(_create_label("Name"))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Skill Name"
	vbox.add_child(_name_edit)

	# Description
	vbox.add_child(_create_label("Description"))
	_desc_edit = TextEdit.new()
	_desc_edit.custom_minimum_size.y = 60
	_desc_edit.placeholder_text = "Skill description..."
	vbox.add_child(_desc_edit)

	# Category
	vbox.add_child(_create_label("Category"))
	_category_button = OptionButton.new()
	for option: String in CATEGORY_OPTIONS:
		_category_button.add_item(option)
	vbox.add_child(_category_button)

	# Icon Path
	vbox.add_child(_create_label("Icon Path"))
	var icon_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(icon_row)

	_icon_edit = LineEdit.new()
	_icon_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_icon_edit.placeholder_text = "res://path/to/icon.png"
	icon_row.add_child(_icon_edit)

	var browse_button: Button = Button.new()
	browse_button.text = "Browse"
	browse_button.pressed.connect(_on_browse_pressed)
	icon_row.add_child(browse_button)

	# Level Max
	vbox.add_child(_create_label("Level Max"))
	_level_spin = SpinBox.new()
	_level_spin.min_value = LEVEL_MIN
	_level_spin.max_value = LEVEL_MAX
	_level_spin.value = SkillEntry.DEFAULT_LEVEL_MAX
	vbox.add_child(_level_spin)

	# Tags
	vbox.add_child(_create_label("Tags (comma separated)"))
	_tags_edit = LineEdit.new()
	_tags_edit.placeholder_text = "fire, magic, aoe"
	vbox.add_child(_tags_edit)

	# Stats セクション
	vbox.add_child(_create_label("Stats (key: value)"))

	_stats_container = VBoxContainer.new()
	vbox.add_child(_stats_container)

	var add_stat_button: Button = Button.new()
	add_stat_button.text = "+ Add Stat"
	add_stat_button.pressed.connect(_add_stat_row.bind("", 0))
	vbox.add_child(add_stat_button)

	# 区切り線
	var separator: HSeparator = HSeparator.new()
	vbox.add_child(separator)

	# OK / Cancel ボタン
	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(button_row)

	var ok_button: Button = Button.new()
	ok_button.text = "OK"
	ok_button.pressed.connect(_on_ok_pressed)
	button_row.add_child(ok_button)

	var cancel_button: Button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_row.add_child(cancel_button)

	# FileDialog（アイコン選択用）
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.filters = PackedStringArray(["*.png ; PNG Images", "*.svg ; SVG Images"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


## 編集時にフィールドへ既存データをセットする
##
## @param skill: セットする SkillEntry
func _populate_from_skill(skill: SkillEntry) -> void:
	_id_edit.text = skill.id
	_name_edit.text = skill.display_name
	_desc_edit.text = skill.description

	# カテゴリの選択インデックスを特定する
	for i: int in range(CATEGORY_OPTIONS.size()):
		if CATEGORY_OPTIONS[i] == skill.category:
			_category_button.selected = i
			break

	_icon_edit.text = skill.icon_path
	_level_spin.value = skill.level_max
	_tags_edit.text = ", ".join(skill.tags)

	# ステータス行をクリアして再構築
	_clear_stats()
	for key: String in skill.stats.keys():
		var value: Variant = skill.stats[key]
		_add_stat_row(key, int(value))


## ステータス入力行を 1 つ追加する
##
## @param key: ステータスキー名
## @param value: ステータス値
func _add_stat_row(key: String = "", value: int = 0) -> void:
	var row: HBoxContainer = HBoxContainer.new()

	var key_edit: LineEdit = LineEdit.new()
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_edit.placeholder_text = "stat_key"
	key_edit.text = key
	row.add_child(key_edit)

	var value_spin: SpinBox = SpinBox.new()
	value_spin.min_value = STAT_VALUE_MIN
	value_spin.max_value = STAT_VALUE_MAX
	value_spin.step = STAT_VALUE_STEP
	value_spin.value = value
	value_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_spin)

	var remove_button: Button = Button.new()
	remove_button.text = "x"
	remove_button.pressed.connect(_on_remove_stat_pressed.bind(row))
	row.add_child(remove_button)

	_stats_container.add_child(row)


## OK ボタン押下時の処理
func _on_ok_pressed() -> void:
	var skill_id: String = _id_edit.text.strip_edges()
	if skill_id.is_empty():
		push_error("[SkillCreationDialog] _on_ok_pressed: ID is required")
		return

	var skill: SkillEntry = SkillEntry.new()
	skill.id = skill_id
	skill.display_name = _name_edit.text.strip_edges()
	skill.description = _desc_edit.text.strip_edges()
	skill.category = CATEGORY_OPTIONS[_category_button.selected]
	skill.icon_path = _icon_edit.text.strip_edges()
	skill.level_max = int(_level_spin.value)

	# タグのパース
	var raw_tags: String = _tags_edit.text.strip_edges()
	var typed_tags: Array[String] = []
	if not raw_tags.is_empty():
		for tag: String in raw_tags.split(","):
			var trimmed: String = tag.strip_edges()
			if not trimmed.is_empty():
				typed_tags.append(trimmed)
	skill.tags = typed_tags

	# ステータスの収集
	var stats: Dictionary = {}
	for child: Node in _stats_container.get_children():
		if child is HBoxContainer:
			var row: HBoxContainer = child as HBoxContainer
			if row.get_child_count() >= 2:
				var key_node: Node = row.get_child(0)
				var value_node: Node = row.get_child(1)
				if key_node is LineEdit and value_node is SpinBox:
					var stat_key: String = (key_node as LineEdit).text.strip_edges()
					if not stat_key.is_empty():
						stats[stat_key] = int((value_node as SpinBox).value)
	skill.stats = stats

	skill_confirmed.emit(skill)
	hide()


## Cancel ボタン押下時の処理
func _on_cancel_pressed() -> void:
	hide()


## Browse ボタン押下時の処理
func _on_browse_pressed() -> void:
	_file_dialog.popup_centered()


## ファイル選択完了時の処理
##
## @param path: 選択されたファイルパス
func _on_file_selected(path: String) -> void:
	_icon_edit.text = path


## ステータス行の削除ボタン押下時の処理
##
## @param row: 削除対象の HBoxContainer
func _on_remove_stat_pressed(row: HBoxContainer) -> void:
	_stats_container.remove_child(row)
	row.queue_free()


## 全入力フィールドを初期状態にクリアする
func _clear_fields() -> void:
	if _id_edit != null:
		_id_edit.text = ""
	if _name_edit != null:
		_name_edit.text = ""
	if _desc_edit != null:
		_desc_edit.text = ""
	if _category_button != null:
		_category_button.selected = 0
	if _icon_edit != null:
		_icon_edit.text = ""
	if _level_spin != null:
		_level_spin.value = SkillEntry.DEFAULT_LEVEL_MAX
	if _tags_edit != null:
		_tags_edit.text = ""
	_clear_stats()


## ステータス行を全て削除する
func _clear_stats() -> void:
	if _stats_container == null:
		return
	for child: Node in _stats_container.get_children():
		_stats_container.remove_child(child)
		child.queue_free()


## ラベルを生成するヘルパー
##
## @param text: ラベルテキスト
## @return: 生成された Label
func _create_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label
