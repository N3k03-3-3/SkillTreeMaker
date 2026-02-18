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

	check_entry_node(model, report)
	check_missing_refs(model, report)
	check_cycles(model, report)
	check_unreachable(model, report)

	return report


## エントリノードの存在を検証する
##
## tree_meta.entry_node_id が設定されていること、かつ該当ノードが存在することを確認する。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_entry_node(model: SkillTreeModel, report: ValidationReport) -> void:
	var entry_id: String = model.tree_meta.get("entry_node_id", "")

	if entry_id.is_empty():
		report.add_error(
			ValidationReport.TYPE_ENTRY_NODE,
			"Entry node ID is not set"
		)
		return

	var node: Dictionary = model.get_node(entry_id)
	if node.is_empty():
		report.add_error(
			ValidationReport.TYPE_ENTRY_NODE,
			"Entry node not found: " + entry_id,
			[entry_id]
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
## エントリノードから無向 BFS を実行し、到達できないノードを警告する。
## エントリノードが未設定・存在しない場合はスキップする。
##
## @param model: 検証対象 (SkillTreeModel)
## @param report: 結果を追記する ValidationReport (ValidationReport)
func check_unreachable(model: SkillTreeModel, report: ValidationReport) -> void:
	var entry_id: String = model.tree_meta.get("entry_node_id", "")
	if entry_id.is_empty():
		return

	if model.get_node(entry_id).is_empty():
		return

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

	# BFS
	var visited: Dictionary = {}
	var queue: Array[String] = [entry_id]
	visited[entry_id] = true

	while queue.size() > 0:
		var current: String = queue.pop_front()
		for neighbor: String in adjacency.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	# 到達不能ノードを警告
	for node_id: String in model.get_all_node_ids():
		if not visited.has(node_id):
			report.add_warning(
				ValidationReport.TYPE_UNREACHABLE,
				"Node unreachable from entry: " + node_id,
				[node_id]
			)


# --- Private Functions ---

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
