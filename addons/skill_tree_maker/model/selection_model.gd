class_name SelectionModel
extends RefCounted

## 選択状態を追跡するモデル
##
## エディタ内で現在選択されているアイテム（ツリー、グループ、ノード、エッジ）を管理する。
## UI 間の連携（CanvasView ↔ InspectorPanel ↔ HierarchyPanel）に使用する。


# --- Signals ---

## 選択が変更されたとき
signal selection_changed(selection_type: String, selection_id: String)

## 選択がクリアされたとき
signal selection_cleared()


# --- Enums ---

## 選択対象の種別
enum SelectionType {
	NONE,
	TREE,
	GROUP,
	NODE,
	EDGE,
}


# --- Constants ---

## SelectionType を文字列に変換するテーブル
const TYPE_STRINGS: Dictionary = {
	SelectionType.NONE: "none",
	SelectionType.TREE: "tree",
	SelectionType.GROUP: "group",
	SelectionType.NODE: "node",
	SelectionType.EDGE: "edge",
}

## 文字列を SelectionType に変換するテーブル
const STRING_TYPES: Dictionary = {
	"none": SelectionType.NONE,
	"tree": SelectionType.TREE,
	"group": SelectionType.GROUP,
	"node": SelectionType.NODE,
	"edge": SelectionType.EDGE,
}


# --- Public Variables ---

## 現在の選択種別
var selected_type: SelectionType = SelectionType.NONE

## 現在の選択 ID
var selected_id: String = ""


# --- Public Functions ---

## 選択を設定する
##
## @param type: 選択種別 (SelectionType)
## @param id: 選択対象の ID (String)
func set_selection(type: SelectionType, id: String) -> void:
	selected_type = type
	selected_id = id
	var type_str: String = TYPE_STRINGS.get(type, "none")
	selection_changed.emit(type_str, id)


## 文字列指定で選択を設定する
##
## @param type_str: 選択種別の文字列（"tree", "group", "node", "edge"）(String)
## @param id: 選択対象の ID (String)
func set_selection_by_string(type_str: String, id: String) -> void:
	var type: SelectionType = STRING_TYPES.get(type_str, SelectionType.NONE)
	set_selection(type, id)


## ノードを選択する
##
## @param node_id: ノード ID (String)
func select_node(node_id: String) -> void:
	set_selection(SelectionType.NODE, node_id)


## エッジを選択する
##
## @param edge_key: エッジキー（"from_id->to_id" 形式）(String)
func select_edge(edge_key: String) -> void:
	set_selection(SelectionType.EDGE, edge_key)


## グループを選択する
##
## @param group_id: グループ ID (String)
func select_group(group_id: String) -> void:
	set_selection(SelectionType.GROUP, group_id)


## ツリー自体を選択する
func select_tree() -> void:
	set_selection(SelectionType.TREE, "")


## 選択をクリアする
func clear() -> void:
	selected_type = SelectionType.NONE
	selected_id = ""
	selection_cleared.emit()


## 何かが選択されているか判定する
##
## @return: 選択中なら true
func has_selection() -> bool:
	return selected_type != SelectionType.NONE


## ノードが選択されているか判定する
##
## @return: ノード選択中なら true
func is_node_selected() -> bool:
	return selected_type == SelectionType.NODE


## エッジが選択されているか判定する
##
## @return: エッジ選択中なら true
func is_edge_selected() -> bool:
	return selected_type == SelectionType.EDGE


## 指定したノード ID が選択されているか判定する
##
## @param node_id: 判定するノード ID (String)
## @return: 指定ノードが選択中なら true
func is_node_id_selected(node_id: String) -> bool:
	return selected_type == SelectionType.NODE and selected_id == node_id


## 選択種別を文字列で取得する
##
## @return: 選択種別の文字列
func get_type_string() -> String:
	return TYPE_STRINGS.get(selected_type, "none")
