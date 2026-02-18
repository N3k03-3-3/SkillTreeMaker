@tool
class_name CanvasContextMenu
extends PopupMenu

## キャンバスの右クリックコンテキストメニュー
##
## キャンバス上の空白、ノード、エッジに応じた
## コンテキストメニューを表示し、操作シグナルを発火する。


# --- Signals ---

## ノード作成がリクエストされたとき
signal create_node_at(world_pos: Vector2)

## ノード削除がリクエストされたとき
signal delete_node(node_id: String)

## エッジ削除がリクエストされたとき
signal delete_edge(edge_key: String)

## ノードからの接続開始がリクエストされたとき
signal connect_from(node_id: String)


# --- Enums ---

## メニュー項目の ID
enum MenuId {
	CREATE_NODE = 0,
	DELETE_NODE = 1,
	DELETE_EDGE = 2,
	CONNECT_FROM = 3,
}


# --- Private Variables ---

## コンテキストのワールド座標（ノード作成位置）
var _context_world_pos: Vector2 = Vector2.ZERO

## コンテキストのノード ID
var _context_node_id: String = ""

## コンテキストのエッジキー
var _context_edge_key: String = ""


# --- Built-in Functions ---

## メニューの初期設定を行う
func _ready() -> void:
	id_pressed.connect(_on_id_pressed)


# --- Public Functions ---

## キャンバス空白の右クリックメニューを表示する
##
## @param world_pos: クリック位置のワールド座標 (Vector2)
## @param screen_pos: 画面上の表示位置 (Vector2i)
func show_canvas_menu(world_pos: Vector2, screen_pos: Vector2i) -> void:
	_context_world_pos = world_pos
	clear()
	add_item("Create Node", MenuId.CREATE_NODE)
	position = screen_pos
	popup()


## ノードの右クリックメニューを表示する
##
## @param node_id: 対象ノード ID (String)
## @param screen_pos: 画面上の表示位置 (Vector2i)
func show_node_menu(node_id: String, screen_pos: Vector2i) -> void:
	_context_node_id = node_id
	clear()
	add_item("Delete Node", MenuId.DELETE_NODE)
	add_item("Connect From Here", MenuId.CONNECT_FROM)
	position = screen_pos
	popup()


## エッジの右クリックメニューを表示する
##
## @param edge_key: 対象エッジキー ("from->to" 形式) (String)
## @param screen_pos: 画面上の表示位置 (Vector2i)
func show_edge_menu(edge_key: String, screen_pos: Vector2i) -> void:
	_context_edge_key = edge_key
	clear()
	add_item("Delete Edge", MenuId.DELETE_EDGE)
	position = screen_pos
	popup()


# --- Signal Callbacks ---

## メニュー項目が押されたときの処理
##
## @param id: メニュー項目の ID (int)
func _on_id_pressed(id: int) -> void:
	match id:
		MenuId.CREATE_NODE:
			create_node_at.emit(_context_world_pos)
		MenuId.DELETE_NODE:
			delete_node.emit(_context_node_id)
		MenuId.DELETE_EDGE:
			delete_edge.emit(_context_edge_key)
		MenuId.CONNECT_FROM:
			connect_from.emit(_context_node_id)
