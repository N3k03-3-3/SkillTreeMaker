class_name SkillTreeState
extends RefCounted

## ゲームランタイムでのスキルツリー状態管理
##
## ノードのアンロック状態（LOCKED / CAN_UNLOCK / UNLOCKED）を管理し、
## requires チェックと状態遷移ロジックを提供する。
## コスト消費はゲーム側の責務であり、本クラスでは行わない。
## serialize / deserialize でセーブ/ロードに対応する。


# --- Signals ---

## ノードの状態が変化したとき
signal node_state_changed(node_id: String, new_state: int)

## 全状態がリセットされたとき
signal state_reset()


# --- Enums ---

## ノードの状態
enum NodeState {
	LOCKED,       ## 前提未達成でアンロック不可
	CAN_UNLOCK,   ## 前提達成済み、コストを払えばアンロック可
	UNLOCKED,     ## アンロック済み
}


# --- Constants ---

## セーブデータのバージョン
const SAVE_VERSION: int = 1

## セーブデータのバージョンキー
const SAVE_KEY_VERSION: String = "version"

## セーブデータのアンロック済みノードキー
const SAVE_KEY_UNLOCKED: String = "unlocked"


# --- Private Variables ---

## ノード状態マップ: {node_id: NodeState}
var _node_states: Dictionary = {}

## runtime.json の生データ参照
var _runtime_data: Dictionary = {}

## ノードデータの ID 引き: {node_id: node_dict}
var _nodes_by_id: Dictionary = {}

## ツリーのエントリーノード ID（後方互換用）
var _entry_node_id: String = ""

## エントリポイント配列: [{class_id: String, node_id: String}]
var _entry_nodes: Array = []

## アンロックルール: SkillTreeModel.UNLOCK_RULE_REQUIRES or UNLOCK_RULE_PATH_CONNECTED
var _unlock_rule: String = SkillTreeModel.UNLOCK_RULE_REQUIRES

## エッジデータの無向隣接リスト: {node_id: [neighbor_id, ...]}
var _adjacency: Dictionary = {}


# --- Public Functions ---

## runtime データからステートを初期化する
##
## すべてのノードを LOCKED にし、ルールに従って CAN_UNLOCK を計算する。
##
## @param runtime_data: runtime.json の Dictionary (Dictionary)
## @param class_id: エントリポイントのクラス識別子 (String)
func initialize(runtime_data: Dictionary, class_id: String = "default") -> void:
	_runtime_data = runtime_data
	_node_states.clear()
	_nodes_by_id.clear()
	_adjacency.clear()

	# ノードを ID 引きマップに展開
	var nodes: Array = runtime_data.get("nodes", [])
	for node: Dictionary in nodes:
		var node_id: String = node.get("id", "")
		if node_id.is_empty():
			continue
		_nodes_by_id[node_id] = node
		_node_states[node_id] = NodeState.LOCKED

	# ツリーメタデータ読み込み
	var tree: Dictionary = runtime_data.get("tree", {})
	_unlock_rule = tree.get("unlock_rule", SkillTreeModel.UNLOCK_RULE_REQUIRES)
	_entry_nodes = tree.get("entry_nodes", [])

	# 後方互換: entry_node_id → entry_nodes
	if _entry_nodes.is_empty() and tree.has("entry_node_id"):
		var old_entry: String = tree.get("entry_node_id", "")
		if not old_entry.is_empty():
			_entry_nodes = [{"class_id": "default", "node_id": old_entry}]

	# 指定クラスのエントリノード ID を取得
	_entry_node_id = ""
	for entry: Dictionary in _entry_nodes:
		if entry.get("class_id", "") == class_id:
			_entry_node_id = entry.get("node_id", "")
			break
	# class_id が見つからなければ最初のエントリを使用
	if _entry_node_id.is_empty() and not _entry_nodes.is_empty():
		_entry_node_id = _entry_nodes[0].get("node_id", "")

	# 無向隣接リストを構築（path_connected モード用）
	_build_adjacency(runtime_data.get("edges", []))

	# CAN_UNLOCK の初期計算
	_recalculate_all_can_unlock()


## 指定ノードの現在の状態を取得する
##
## @param node_id: ノード ID (String)
## @return: NodeState 値。存在しないノードは LOCKED
func get_node_state(node_id: String) -> NodeState:
	return _node_states.get(node_id, NodeState.LOCKED) as NodeState


## 指定ノードがアンロック可能か判定する
##
## requires の全ノードが UNLOCKED であるかチェックする。
##
## @param node_id: ノード ID (String)
## @return: アンロック可能なら true
func can_unlock(node_id: String) -> bool:
	if not _nodes_by_id.has(node_id):
		return false

	var current_state: NodeState = get_node_state(node_id)
	if current_state != NodeState.CAN_UNLOCK:
		return false

	return true


## 指定ノードのアンロックコスト情報を取得する
##
## @param node_id: ノード ID (String)
## @return: {"type": String, "value": int} のコスト Dictionary。取得できない場合は空 Dictionary
func get_unlock_cost(node_id: String) -> Dictionary:
	if not _nodes_by_id.has(node_id):
		return {}

	var node: Dictionary = _nodes_by_id[node_id]
	var unlock: Dictionary = node.get("unlock", {})
	return unlock.get("cost", {})


## 指定ノードをアンロックする
##
## 前提条件チェック（requires）は行うが、コスト消費はゲーム側の責務。
## アンロック成功時に node_state_changed シグナルを発火し、
## 後続ノードの CAN_UNLOCK を更新する。
##
## @param node_id: アンロックするノード ID (String)
## @return: アンロック成功なら true
func unlock_node(node_id: String) -> bool:
	if not can_unlock(node_id):
		push_warning("[SkillTreeState] unlock_node: cannot unlock node: " + node_id)
		return false

	_node_states[node_id] = NodeState.UNLOCKED
	node_state_changed.emit(node_id, NodeState.UNLOCKED)

	# 後続ノードの CAN_UNLOCK 状態を更新
	_refresh_dependents(node_id)

	return true


## アンロック済みノード ID の配列を取得する
##
## @return: UNLOCKED 状態のノード ID 配列
func get_unlocked_nodes() -> Array[String]:
	var result: Array[String] = []
	for node_id: String in _node_states.keys():
		if _node_states[node_id] == NodeState.UNLOCKED:
			result.append(node_id)
	return result


## 全ノード ID と状態のペアを取得する
##
## @return: {node_id: NodeState} の Dictionary
func get_all_states() -> Dictionary:
	return _node_states.duplicate()


## 現在の状態をセーブ用 Dictionary にシリアライズする
##
## @return: セーブデータ Dictionary
func serialize() -> Dictionary:
	return {
		SAVE_KEY_VERSION: SAVE_VERSION,
		SAVE_KEY_UNLOCKED: get_unlocked_nodes(),
	}


## セーブデータから状態を復元する
##
## runtime_data で初期化した後、セーブデータの unlocked ノードを順次アンロックし、
## 全ノードの CAN_UNLOCK を再計算する。
##
## @param save_data: serialize() で生成された Dictionary (Dictionary)
## @param runtime_data: runtime.json の Dictionary (Dictionary)
## @param class_id: エントリポイントのクラス識別子 (String)
func deserialize(save_data: Dictionary, runtime_data: Dictionary, class_id: String = "default") -> void:
	# まず初期化
	initialize(runtime_data, class_id)

	# セーブデータからアンロック済みノードを復元
	var unlocked: Array = save_data.get(SAVE_KEY_UNLOCKED, [])
	for node_id: Variant in unlocked:
		var id: String = str(node_id)
		if _node_states.has(id):
			_node_states[id] = NodeState.UNLOCKED

	# 全ノードの CAN_UNLOCK を再計算
	_recalculate_all_can_unlock()


## 全状態を初期状態にリセットする
func reset() -> void:
	if _runtime_data.is_empty():
		push_error("[SkillTreeState] reset: no runtime data loaded")
		return

	initialize(_runtime_data)
	state_reset.emit()


# --- Private Functions ---

## 指定ノードのアンロックにより CAN_UNLOCK になる後続ノードを更新する
##
## @param unlocked_node_id: アンロックされたノード ID (String)
func _refresh_dependents(unlocked_node_id: String) -> void:
	if _unlock_rule == SkillTreeModel.UNLOCK_RULE_PATH_CONNECTED:
		_refresh_dependents_path_connected(unlocked_node_id)
	else:
		_refresh_dependents_requires(unlocked_node_id)


## requires モードでの後続ノード更新
##
## @param unlocked_node_id: アンロックされたノード ID (String)
func _refresh_dependents_requires(unlocked_node_id: String) -> void:
	for node_id: String in _nodes_by_id.keys():
		if _node_states[node_id] != NodeState.LOCKED:
			continue

		var node: Dictionary = _nodes_by_id[node_id]
		var unlock: Dictionary = node.get("unlock", {})
		var requires: Array = unlock.get("requires", [])

		# このノードが unlocked_node_id を requires に含んでいるか
		if not requires.has(unlocked_node_id):
			continue

		# 全 requires が UNLOCKED かチェック
		if _are_all_requires_unlocked(requires):
			_node_states[node_id] = NodeState.CAN_UNLOCK
			node_state_changed.emit(node_id, NodeState.CAN_UNLOCK)


## path_connected モードでの後続ノード更新
##
## アンロック済みノードに隣接する LOCKED ノードを CAN_UNLOCK にする。
##
## @param unlocked_node_id: アンロックされたノード ID (String)
func _refresh_dependents_path_connected(unlocked_node_id: String) -> void:
	var neighbors: Array = _adjacency.get(unlocked_node_id, [])
	for neighbor_id: String in neighbors:
		if _node_states.get(neighbor_id, NodeState.LOCKED) == NodeState.LOCKED:
			_node_states[neighbor_id] = NodeState.CAN_UNLOCK
			node_state_changed.emit(neighbor_id, NodeState.CAN_UNLOCK)


## 全ノードの CAN_UNLOCK 状態を再計算する
func _recalculate_all_can_unlock() -> void:
	if _unlock_rule == SkillTreeModel.UNLOCK_RULE_PATH_CONNECTED:
		_recalculate_path_connected()
	else:
		_recalculate_requires_mode()


## requires モードでの CAN_UNLOCK 再計算
func _recalculate_requires_mode() -> void:
	for node_id: String in _nodes_by_id.keys():
		if _node_states.get(node_id, NodeState.LOCKED) != NodeState.LOCKED:
			continue

		var node: Dictionary = _nodes_by_id[node_id]
		var unlock: Dictionary = node.get("unlock", {})
		var requires: Array = unlock.get("requires", [])

		# requires が空 → CAN_UNLOCK（エントリーノードを含む）
		if requires.is_empty():
			_node_states[node_id] = NodeState.CAN_UNLOCK
			continue

		# 全 requires が UNLOCKED → CAN_UNLOCK
		if _are_all_requires_unlocked(requires):
			_node_states[node_id] = NodeState.CAN_UNLOCK


## path_connected モードでの CAN_UNLOCK 再計算
##
## エントリノードから、アンロック済みノードを経由して隣接するノードを CAN_UNLOCK にする。
## エントリノード自体は常に CAN_UNLOCK。
func _recalculate_path_connected() -> void:
	# エントリノードが未アンロックなら CAN_UNLOCK にする
	if not _entry_node_id.is_empty() and _nodes_by_id.has(_entry_node_id):
		if _node_states.get(_entry_node_id, NodeState.LOCKED) == NodeState.LOCKED:
			_node_states[_entry_node_id] = NodeState.CAN_UNLOCK

	# アンロック済みノードに隣接する LOCKED ノードを CAN_UNLOCK にする
	for node_id: String in _nodes_by_id.keys():
		if _node_states.get(node_id, NodeState.LOCKED) != NodeState.UNLOCKED:
			continue
		# このアンロック済みノードの隣接ノードをチェック
		var neighbors: Array = _adjacency.get(node_id, [])
		for neighbor_id: String in neighbors:
			if _node_states.get(neighbor_id, NodeState.LOCKED) == NodeState.LOCKED:
				_node_states[neighbor_id] = NodeState.CAN_UNLOCK


## requires 配列の全ノードが UNLOCKED かチェックする
##
## @param requires: requires ノード ID の配列 (Array)
## @return: 全て UNLOCKED なら true
func _are_all_requires_unlocked(requires: Array) -> bool:
	for req_id: Variant in requires:
		var id: String = str(req_id)
		if _node_states.get(id, NodeState.LOCKED) != NodeState.UNLOCKED:
			return false
	return true


## エッジデータから無向隣接リストを構築する
##
## @param edges: エッジ配列 (Array)
func _build_adjacency(edges: Array) -> void:
	_adjacency.clear()
	for node_id: String in _nodes_by_id.keys():
		_adjacency[node_id] = []

	for edge: Dictionary in edges:
		var from_id: String = edge.get("from", "")
		var to_id: String = edge.get("to", "")
		if from_id.is_empty() or to_id.is_empty():
			continue
		if _adjacency.has(from_id) and not (_adjacency[from_id] as Array).has(to_id):
			(_adjacency[from_id] as Array).append(to_id)
		if _adjacency.has(to_id) and not (_adjacency[to_id] as Array).has(from_id):
			(_adjacency[to_id] as Array).append(from_id)
