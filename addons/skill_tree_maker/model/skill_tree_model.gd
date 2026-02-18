class_name SkillTreeModel
extends RefCounted

## スキルツリーのインメモリデータモデル
##
## pack.json と runtime.json のデータを統合して保持する。
## ノード・エッジの CRUD、メタデータ管理を提供する。


# --- Signals ---

## ノードが追加されたとき
signal node_added(node_id: String)

## ノードが削除されたとき
signal node_removed(node_id: String)

## ノードが更新されたとき
signal node_updated(node_id: String)

## エッジが追加されたとき
signal edge_added(from_id: String, to_id: String)

## エッジが削除されたとき
signal edge_removed(from_id: String, to_id: String)

## グループが追加されたとき
signal group_added(group_id: String)

## グループが削除されたとき
signal group_removed(group_id: String)

## モデルデータが変更されたとき（汎用）
signal model_changed()


# --- Constants ---

## スキーマバージョン
const SCHEMA_VERSION: int = 1

## デフォルトのグループ ID
const DEFAULT_GROUP_ID: String = "default"


# --- Public Variables ---

## パックメタデータ（pack.json の pack セクション）
var pack_meta: Dictionary = {}

## パスマッピング（pack.json の paths セクション）
var paths: Dictionary = {}

## ツリーメタデータ（runtime.json の tree セクション）
var tree_meta: Dictionary = {}

## エディタ状態への参照
var tool_state: ToolState = null

## ドラフトデータ（未使用ノード、ガイド線など）
var draft: Dictionary = {}


# --- Private Variables ---

## ノードデータ（キー: node_id, 値: Dictionary）
var _nodes: Dictionary = {}

## エッジデータ（キー: "from_id->to_id", 値: Dictionary）
var _edges: Dictionary = {}

## グループデータ（キー: group_id, 値: Dictionary）
var _groups: Dictionary = {}

## 次に自動採番する際のカウンタ
var _next_node_number: int = 1


# --- Public Functions ---

## ノードを ID で取得する
##
## @param node_id: ノード ID (String)
## @return: ノードデータの Dictionary。存在しなければ空の Dictionary
func get_node(node_id: String) -> Dictionary:
	if node_id.is_empty():
		push_warning("[SkillTreeModel] get_node: node_id is empty")
		return {}
	if not _nodes.has(node_id):
		return {}
	return _nodes[node_id]


## 全ノードを取得する
##
## @return: 全ノードの配列
func get_all_nodes() -> Array:
	return _nodes.values()


## 全ノード ID を取得する
##
## @return: 全ノード ID の配列
func get_all_node_ids() -> Array:
	return _nodes.keys()


## ノードを追加する
##
## @param node_data: ノードデータの Dictionary（id キー必須）
## @return: 追加成功なら true
func add_node(node_data: Dictionary) -> bool:
	if not node_data.has("id"):
		push_error("[SkillTreeModel] add_node: node_data must have 'id' key")
		return false

	var node_id: String = node_data["id"]
	if _nodes.has(node_id):
		push_error("[SkillTreeModel] add_node: node_id already exists: " + node_id)
		return false

	_nodes[node_id] = node_data
	node_added.emit(node_id)
	model_changed.emit()
	return true


## 新しいノードを指定位置に作成する
##
## @param pos: ノード位置 (Vector2)
## @param group_id: 所属グループ ID (String)
## @return: 作成されたノードデータの Dictionary
func create_node(pos: Vector2, group_id: String = DEFAULT_GROUP_ID) -> Dictionary:
	var node_id: String = _generate_node_id()
	var node_data: Dictionary = {
		"id": node_id,
		"group_id": group_id,
		"pos": {"x": pos.x, "y": pos.y},
		"name_key": "node." + node_id + ".name",
		"desc_key": "node." + node_id + ".desc",
		"icon_path": "",
		"style": {"preset": "node_default", "overrides": {}},
		"unlock": {"cost": {"type": "gp", "value": 1}, "requires": []},
		"payload": {},
	}
	add_node(node_data)
	return node_data


## ノードを削除する
##
## 関連するエッジも同時に削除される。
##
## @param node_id: 削除するノードの ID (String)
## @return: 削除成功なら true
func remove_node(node_id: String) -> bool:
	if not _nodes.has(node_id):
		push_error("[SkillTreeModel] remove_node: node not found: " + node_id)
		return false

	# 関連するエッジを削除
	var edges_to_remove: Array = []
	for edge_key: String in _edges.keys():
		var edge: Dictionary = _edges[edge_key]
		if edge["from"] == node_id or edge["to"] == node_id:
			edges_to_remove.append(edge_key)

	for edge_key: String in edges_to_remove:
		var edge: Dictionary = _edges[edge_key]
		_edges.erase(edge_key)
		edge_removed.emit(edge["from"], edge["to"])

	_nodes.erase(node_id)
	node_removed.emit(node_id)
	model_changed.emit()
	return true


## ノードデータを更新する
##
## @param node_id: 更新するノードの ID (String)
## @param updates: 更新するキーと値の Dictionary
## @return: 更新成功なら true
func update_node(node_id: String, updates: Dictionary) -> bool:
	if not _nodes.has(node_id):
		push_error("[SkillTreeModel] update_node: node not found: " + node_id)
		return false

	var node: Dictionary = _nodes[node_id]
	for key: String in updates.keys():
		node[key] = updates[key]

	node_updated.emit(node_id)
	model_changed.emit()
	return true


## エッジを追加する
##
## @param from_id: 接続元ノード ID (String)
## @param to_id: 接続先ノード ID (String)
## @param style_preset: スタイルプリセット名 (String)
## @return: 追加成功なら true
func add_edge(from_id: String, to_id: String, style_preset: String = "edge_default") -> bool:
	if not _nodes.has(from_id):
		push_error("[SkillTreeModel] add_edge: from node not found: " + from_id)
		return false
	if not _nodes.has(to_id):
		push_error("[SkillTreeModel] add_edge: to node not found: " + to_id)
		return false

	var edge_key: String = from_id + "->" + to_id
	if _edges.has(edge_key):
		push_error("[SkillTreeModel] add_edge: edge already exists: " + edge_key)
		return false

	_edges[edge_key] = {
		"from": from_id,
		"to": to_id,
		"style_preset": style_preset,
	}

	# requires にも追加
	var to_node: Dictionary = _nodes[to_id]
	if not to_node.has("unlock"):
		to_node["unlock"] = {"cost": {"type": "gp", "value": 1}, "requires": []}
	var requires: Array = to_node["unlock"]["requires"]
	if not requires.has(from_id):
		requires.append(from_id)

	edge_added.emit(from_id, to_id)
	model_changed.emit()
	return true


## エッジを削除する
##
## @param from_id: 接続元ノード ID (String)
## @param to_id: 接続先ノード ID (String)
## @return: 削除成功なら true
func remove_edge(from_id: String, to_id: String) -> bool:
	var edge_key: String = from_id + "->" + to_id
	if not _edges.has(edge_key):
		push_error("[SkillTreeModel] remove_edge: edge not found: " + edge_key)
		return false

	_edges.erase(edge_key)

	# requires からも削除
	if _nodes.has(to_id):
		var to_node: Dictionary = _nodes[to_id]
		if to_node.has("unlock") and to_node["unlock"].has("requires"):
			to_node["unlock"]["requires"].erase(from_id)

	edge_removed.emit(from_id, to_id)
	model_changed.emit()
	return true


## 全エッジを取得する
##
## @return: 全エッジの配列
func get_all_edges() -> Array:
	return _edges.values()


## グループを追加する
##
## @param group_id: グループ ID (String)
## @param center: グループ中心位置 (Vector2)
## @return: 追加成功なら true
func add_group(group_id: String, center: Vector2 = Vector2.ZERO) -> bool:
	if _groups.has(group_id):
		push_error("[SkillTreeModel] add_group: group already exists: " + group_id)
		return false
	_groups[group_id] = {"id": group_id, "center": {"x": center.x, "y": center.y}}
	group_added.emit(group_id)
	model_changed.emit()
	return true


## 全グループを取得する
##
## @return: 全グループの配列
func get_all_groups() -> Array:
	return _groups.values()


## グループを ID で取得する
##
## @param group_id: グループ ID (String)
## @return: グループデータの Dictionary。存在しなければ空の Dictionary
func get_group(group_id: String) -> Dictionary:
	return _groups.get(group_id, {})


## グループを削除する
##
## グループ内のノードは DEFAULT_GROUP_ID に移動してから削除する。
## DEFAULT_GROUP_ID は削除できない。
##
## @param group_id: 削除するグループ ID (String)
## @return: 削除成功なら true
func remove_group(group_id: String) -> bool:
	if group_id == DEFAULT_GROUP_ID:
		push_error("[SkillTreeModel] remove_group: cannot remove default group")
		return false
	if not _groups.has(group_id):
		push_error("[SkillTreeModel] remove_group: group not found: " + group_id)
		return false

	# グループ内ノードを default グループに移動
	for node: Dictionary in _nodes.values():
		if node.get("group_id", "") == group_id:
			node["group_id"] = DEFAULT_GROUP_ID
			node_updated.emit(node.get("id", ""))

	_groups.erase(group_id)
	group_removed.emit(group_id)
	model_changed.emit()
	return true


## ノード数を取得する
##
## @return: ノード数
func get_node_count() -> int:
	return _nodes.size()


## エッジ数を取得する
##
## @return: エッジ数
func get_edge_count() -> int:
	return _edges.size()


## 指定グループに属するノードを取得する
##
## @param group_id: グループ ID (String)
## @return: 該当ノードの配列
func get_nodes_by_group(group_id: String) -> Array:
	var result: Array = []
	for node: Dictionary in _nodes.values():
		if node.get("group_id", "") == group_id:
			result.append(node)
	return result


## エッジをキーで取得する
##
## @param edge_key: "from_id->to_id" 形式のキー (String)
## @return: エッジデータの Dictionary。存在しなければ空の Dictionary
func get_edge(edge_key: String) -> Dictionary:
	return _edges.get(edge_key, {})


## 指定ノードからの出発エッジを取得する
##
## @param node_id: ノード ID (String)
## @return: 出発エッジの配列
func get_outgoing_edges(node_id: String) -> Array:
	var result: Array = []
	for edge: Dictionary in _edges.values():
		if edge.get("from", "") == node_id:
			result.append(edge)
	return result


## モデルをクリアして初期状態にする
func clear() -> void:
	_nodes.clear()
	_edges.clear()
	_groups.clear()
	pack_meta = {}
	paths = {}
	tree_meta = {}
	draft = {}
	_next_node_number = 1
	model_changed.emit()


# --- Private Functions ---

## ノード ID を自動生成する
##
## @return: "n_001" 形式のノード ID
func _generate_node_id() -> String:
	var node_id: String = "n_%03d" % _next_node_number
	while _nodes.has(node_id):
		_next_node_number += 1
		node_id = "n_%03d" % _next_node_number
	_next_node_number += 1
	return node_id
