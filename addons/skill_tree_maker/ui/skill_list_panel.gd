@tool
class_name SkillListPanel
extends PanelContainer

## スキル一覧を表示・検索・選択するパネル
##
## スキルの追加・削除リクエスト、選択変更をシグナルで通知する。
## 検索バーでリアルタイムフィルタリングが可能。


# --- Signals ---

## スキルが選択されたとき
signal skill_selected(skill_id: String)

## スキル作成がリクエストされたとき
signal skill_create_requested()

## スキル削除がリクエストされたとき
signal skill_delete_requested(skill_id: String)


# --- Constants ---

## パネルの最小幅
const PANEL_MIN_WIDTH: int = 200


# --- Private Variables ---

## 現在保持しているスキルエントリ一覧
var _entries: Array[SkillEntry] = []

## スキル一覧表示用の ItemList
var _item_list: ItemList = null

## 検索用の LineEdit
var _search_edit: LineEdit = null

## 現在のフィルタテキスト
var _filter_text: String = ""


# --- Built-in Functions ---

func _ready() -> void:
	custom_minimum_size.x = PANEL_MIN_WIDTH
	_build_ui()


# --- Public Functions ---

## スキルエントリ一覧を受け取り、リストを再描画する
##
## @param entries: 表示する SkillEntry の配列
func refresh(entries: Array[SkillEntry]) -> void:
	_entries = entries
	_refresh_list()


## 現在選択中のスキル ID を返す
##
## @return: 選択中のスキル ID。未選択なら空文字列
func get_selected_skill_id() -> String:
	if _item_list == null:
		return ""

	var selected_items: PackedInt32Array = _item_list.get_selected_items()
	if selected_items.is_empty():
		return ""

	var index: int = selected_items[0]
	var metadata: Variant = _item_list.get_item_metadata(index)
	if metadata is String:
		return metadata as String
	return ""


# --- Private Functions ---

## UI を構築する
func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# タイトルラベル
	var title_label: Label = Label.new()
	title_label.text = "Skills"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# 検索バー
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search..."
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_changed)
	vbox.add_child(_search_edit)

	# ボタン行
	var button_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(button_row)

	var add_button: Button = Button.new()
	add_button.text = "+ Skill"
	add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button.pressed.connect(_on_add_pressed)
	button_row.add_child(add_button)

	var delete_button: Button = Button.new()
	delete_button.text = "- Skill"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.pressed.connect(_on_delete_pressed)
	button_row.add_child(delete_button)

	# スキル一覧
	_item_list = ItemList.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.item_selected.connect(_on_item_selected)
	vbox.add_child(_item_list)


## フィルタ適用済みのスキル一覧で ItemList を更新する
func _refresh_list() -> void:
	if _item_list == null:
		return

	_item_list.clear()

	var filter_lower: String = _filter_text.to_lower()

	for entry: SkillEntry in _entries:
		# フィルタテキストが設定されていれば、表示名・ID・タグで絞り込む
		if not filter_lower.is_empty():
			var match_found: bool = false
			if entry.display_name.to_lower().find(filter_lower) >= 0:
				match_found = true
			elif entry.id.to_lower().find(filter_lower) >= 0:
				match_found = true
			else:
				for tag: String in entry.tags:
					if tag.to_lower().find(filter_lower) >= 0:
						match_found = true
						break
			if not match_found:
				continue

		var label: String = entry.display_name if not entry.display_name.is_empty() else entry.id
		var idx: int = _item_list.add_item(label)
		_item_list.set_item_metadata(idx, entry.id)


## "+ Skill" ボタン押下時の処理
func _on_add_pressed() -> void:
	skill_create_requested.emit()


## "- Skill" ボタン押下時の処理
func _on_delete_pressed() -> void:
	var selected_id: String = get_selected_skill_id()
	if selected_id.is_empty():
		return
	skill_delete_requested.emit(selected_id)


## ItemList のアイテム選択時の処理
##
## @param index: 選択されたアイテムのインデックス
func _on_item_selected(index: int) -> void:
	var metadata: Variant = _item_list.get_item_metadata(index)
	if metadata is String:
		skill_selected.emit(metadata as String)


## 検索テキスト変更時の処理
##
## @param text: 新しい検索テキスト
func _on_search_changed(text: String) -> void:
	_filter_text = text
	_refresh_list()
