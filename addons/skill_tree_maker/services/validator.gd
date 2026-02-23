class_name Validator
extends RefCounted

## スキルツリーモデルの整合性検証サービス
##
## 循環参照・欠損参照・到達不能ノード・エントリノードの検証を行い、
## ValidationReport として結果を返す。


# --- Inner Class: ValidationReport ---

## 検証結果を格納するデータクラス
class ValidationReport extends RefCounted:

	# --- Constants ---

	## エラー種別: 循環参照
	const TYPE_CYCLE: String = "cycle"

	## エラー種別: 欠損参照
	const TYPE_MISSING_REF: String = "missing_ref"

	## エラー種別: 到達不能
	const TYPE_UNREACHABLE: String = "unreachable"

	## エラー種別: エントリノード
	const TYPE_ENTRY_NODE: String = "entry_node"

	## エラー種別: 経路接続不可
	const TYPE_PATH_DISCONNECTED: String = "path_disconnected"


	# --- Public Variables ---

	## エラー一覧（各要素: {type: String, message: String, node_ids: Array[String]}）
	var errors: Array[Dictionary] = []

	## 警告一覧（各要素: {type: String, message: String, node_ids: Array[String]}）
	var warnings: Array[Dictionary] = []


	# --- Public Functions ---

	## エラーがあるか判定する
	##
	## @return: エラーが1件以上あれば true
	func has_errors() -> bool:
		return errors.size() > 0


	## 警告があるか判定する
	##
	## @return: 警告が1件以上あれば true
	func has_warnings() -> bool:
		return warnings.size() > 0


	## エラーを追加する
	##
	## @param type: エラー種別 (String)
	## @param message: エラーメッセージ (String)
	## @param node_ids: 関連ノード ID の配列 (Array[String])
	func add_error(type: String, message: String, node_ids: Array[String] = []) -> void:
		errors.append({"type": type, "message": message, "node_ids": node_ids})


	## 警告を追加する
	##
	## @param type: 警告種別 (String)
	## @param message: 警告メッセージ (String)
	## @param node_ids: 関連ノード ID の配列 (Array[String])
	func add_warning(type: String, message: String, node_ids: Array[String] = []) -> void:
		warnings.append({"type": type, "message": message, "node_ids": node_ids})


	## 検証結果を人間可読な文字列で返す
	##
	## @return: サマリーテキスト
	func to_summary() -> String:
		var lines: PackedStringArray = PackedStringArray()
		lines.append("Errors: %d, Warnings: %d" % [errors.size(), warnings.size()])

		for err: Dictionary in errors:
			lines.append("  [ERROR] %s: %s" % [err.get("type", ""), err.get("message", "")])

		for warn: Dictionary in warnings:
			lines.append("  [WARN] %s: %s" % [warn.get("type", ""), warn.get("message", "")])

		return "\n".join(lines)


# --- Constants ---

## DFS 色定数: 未訪問
const _COLOR_WHITE: int = 0

## DFS 色定数: 探索中（現在のパス上）
const _COLOR_GRAY: int = 1

## DFS 色定数: 探索完了
const _COLOR_BLACK: int = 2


# --- Public Functions ---

## モデル全体を検証する
##
## 全ての検証チェックを実行し、統合された ValidationReport を返す。
##
## @param model: 検証対象の SkillTreeModel (SkillTreeModel)
## @return: 検証結果の ValidationReport
func validate(model: SkillTreeModel) -> ValidationReport:
	var report: ValidationReport = ValidationReport.new()

	if model == null:
		report.add_error("invalid", "Model is null")
		return report

	check_entry_nodes(model, report)
	check_missing_refs(model, report)
	check_cycles(model, report)
	check_unreachable(model, report)
	check_path_connectivity(model, report)

	return report


## エントリポイントの存在と整合性を検証する
##
## entry_nodes 配列の各エントリについてノード存在チェックを行う。
## 後方互換: entry_nodes がなく entry_node_id がある場合も処理する。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_entry_nodes(model: SkillTreeModel, report: ValidationReport) -> void:
	var entry_nodes: Array = model.tree_meta.get("entry_nodes", [])

	# 後方互換: entry_node_id が存在する場合
	if entry_nodes.is_empty() and model.tree_meta.has("entry_node_id"):
		var old_id: String = model.tree_meta.get("entry_node_id", "")
		if old_id.is_empty():
			report.add_error(
				ValidationReport.TYPE_ENTRY_NODE,
				"Entry node ID is not set"
			)
			return
		var node: Dictionary = model.get_node(old_id)
		if node.is_empty():
			report.add_error(
				ValidationReport.TYPE_ENTRY_NODE,
				"Entry node not found: " + old_id,
				[old_id]
			)
		return

	if entry_nodes.is_empty():
		report.add_error(
			ValidationReport.TYPE_ENTRY_NODE,
			"No entry nodes defined"
		)
		return

	# "default" クラスの存在チェック
	var has_default: bool = false
	for entry: Dictionary in entry_nodes:
		var class_id: String = entry.get("class_id", "")
		var node_id: String = entry.get("node_id", "")

		if class_id == "default":
			has_default = true

		if node_id.is_empty():
			report.add_error(
				ValidationReport.TYPE_ENTRY_NODE,
				"Entry node ID is empty for class: " + class_id
			)
			continue

		var node: Dictionary = model.get_node(node_id)
		if node.is_empty():
			report.add_error(
				ValidationReport.TYPE_ENTRY_NODE,
				"Entry node not found: " + node_id + " (class: " + class_id + ")",
				[node_id]
			)

	if not has_default:
		report.add_warning(
			ValidationReport.TYPE_ENTRY_NODE,
			"No 'default' class entry node defined"
		)


## エッジが参照するノードの存在を検証する
##
## 各エッジの from/to が実在するノード ID かどうかを確認する。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_missing_refs(model: SkillTreeModel, report: ValidationReport) -> void:
	var all_node_ids: Array = model.get_all_node_ids()

	for edge: Dictionary in model.get_all_edges():
		var from_id: String = edge.get("from", "")
		var to_id: String = edge.get("to", "")

		if not all_node_ids.has(from_id):
			report.add_error(
				ValidationReport.TYPE_MISSING_REF,
				"Edge references missing 'from' node: " + from_id,
				[from_id]
			)

		if not all_node_ids.has(to_id):
			report.add_error(
				ValidationReport.TYPE_MISSING_REF,
				"Edge references missing 'to' node: " + to_id,
				[to_id]
			)


## 循環参照を検証する
##
## 3色 DFS で有向グラフの循環（バックエッジ）を検出する。
## エッジの from → to 方向で隣接リストを構築する。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_cycles(model: SkillTreeModel, report: ValidationReport) -> void:
	# 隣接リスト構築
	var adjacency: Dictionary = {}
	for node_id: String in model.get_all_node_ids():
		adjacency[node_id] = []

	for edge: Dictionary in model.get_all_edges():
		var from_id: String = edge.get("from", "")
		if adjacency.has(from_id):
			adjacency[from_id].append(edge.get("to", ""))

	# 3色マーキング DFS
	var color: Dictionary = {}
	for node_id: String in adjacency.keys():
		color[node_id] = _COLOR_WHITE

	for node_id: String in adjacency.keys():
		if color[node_id] == _COLOR_WHITE:
			_dfs_cycle_check(node_id, adjacency, color, report)


## 到達不能ノードを検証する
##
## 全エントリポイントから無向 BFS を実行し、到達できないノードを警告する。
## エントリノードが未設定・存在しない場合はスキップする。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_unreachable(model: SkillTreeModel, report: ValidationReport) -> void:
	var start_ids: Array[String] = _collect_entry_node_ids(model)
	if start_ids.is_empty():
		return

	var visited: Dictionary = _bfs_from_entries(model, start_ids)

	for node_id: String in model.get_all_node_ids():
		if not visited.has(node_id):
			report.add_warning(
				ValidationReport.TYPE_UNREACHABLE,
				"Node unreachable from entry: " + node_id,
				[node_id]
			)


## path_connected モード時の経路接続性を検証する
##
## unlock_rule が "path_connected" の場合のみ実行する。
## 全エントリポイントから BFS でグラフを探索し、到達不可能なノードを警告する。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_path_connectivity(model: SkillTreeModel, report: ValidationReport) -> void:
	var unlock_rule: String = model.tree_meta.get("unlock_rule", SkillTreeModel.UNLOCK_RULE_REQUIRES)
	if unlock_rule != SkillTreeModel.UNLOCK_RULE_PATH_CONNECTED:
		return

	var start_ids: Array[String] = _collect_entry_node_ids(model)
	if start_ids.is_empty():
		return

	var visited: Dictionary = _bfs_from_entries(model, start_ids)

	for node_id: String in model.get_all_node_ids():
		if not visited.has(node_id):
			report.add_warning(
				ValidationReport.TYPE_PATH_DISCONNECTED,
				"Node not path-connected from any entry: " + node_id,
				[node_id]
			)


# --- Private Functions ---

## エントリポイントから無向 BFS を実行し、到達可能なノードの集合を返す
##
## @param model: 対象モデル (SkillTreeModel)
## @param start_ids: 開始ノード ID の配列 (Array[String])
## @return: 到達可能なノード ID をキーとする Dictionary
func _bfs_from_entries(model: SkillTreeModel, start_ids: Array[String]) -> Dictionary:
	# 無向隣接リスト構築（エッジの両方向を登録）
	var adjacency: Dictionary = {}
	for node_id: String in model.get_all_node_ids():
		adjacency[node_id] = []

	for edge: Dictionary in model.get_all_edges():
		var from_id: String = edge.get("from", "")
		var to_id: String = edge.get("to", "")
		if adjacency.has(from_id):
			adjacency[from_id].append(to_id)
		if adjacency.has(to_id):
			adjacency[to_id].append(from_id)

	# 全エントリポイントから BFS
	var visited: Dictionary = {}
	var queue: Array[String] = []
	for start_id: String in start_ids:
		if model.get_node(start_id).is_empty():
			continue
		visited[start_id] = true
		queue.append(start_id)

	while queue.size() > 0:
		var current: String = queue.pop_front()
		for neighbor: String in adjacency.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	return visited


## モデルからエントリノード ID を収集する（後方互換対応）
##
## @param model: 対象モデル (SkillTreeModel)
## @return: エントリノード ID の配列
func _collect_entry_node_ids(model: SkillTreeModel) -> Array[String]:
	var ids: Array[String] = []
	var entry_nodes: Array = model.tree_meta.get("entry_nodes", [])
	for entry: Dictionary in entry_nodes:
		var nid: String = entry.get("node_id", "")
		if not nid.is_empty() and not ids.has(nid):
			ids.append(nid)

	# 後方互換: entry_node_id
	if ids.is_empty() and model.tree_meta.has("entry_node_id"):
		var old_id: String = model.tree_meta.get("entry_node_id", "")
		if not old_id.is_empty():
			ids.append(old_id)

	return ids


## DFS で循環参照をチェックする（3色マーキング方式）
##
## @param node_id: 現在探索中のノード ID (String)
## @param adjacency: 隣接リスト (Dictionary)
## @param color: ノードの色状態 (Dictionary)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func _dfs_cycle_check(node_id: String, adjacency: Dictionary,
		color: Dictionary, report: ValidationReport) -> void:
	color[node_id] = _COLOR_GRAY

	for neighbor: String in adjacency.get(node_id, []):
		if color.get(neighbor, _COLOR_WHITE) == _COLOR_GRAY:
			report.add_error(
				ValidationReport.TYPE_CYCLE,
				"Cycle detected: " + node_id + " -> " + neighbor,
				[node_id, neighbor]
			)
		elif color.get(neighbor, _COLOR_WHITE) == _COLOR_WHITE:
			_dfs_cycle_check(neighbor, adjacency, color, report)

	color[node_id] = _COLOR_BLACK
