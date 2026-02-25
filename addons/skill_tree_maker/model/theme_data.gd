class_name ThemeData
extends RefCounted

## テーマデータモデルクラス
##
## theme.json のデータ構造をオブジェクトとして保持し、
## デフォルト値の生成、辞書との相互変換、バリデーションを提供する。


# --- Constants ---

## スキーマバージョン
const SCHEMA_VERSION: int = 1

## デフォルト背景ティント色
const DEFAULT_BG_TINT: String = "#1A1A2E"

## デフォルトノードサイズ（ピクセル）
const DEFAULT_NODE_SIZE: int = 48

## デフォルトエッジ幅（ピクセル）
const DEFAULT_EDGE_WIDTH: int = 3

## デフォルトウィンドウパディング（ピクセル）
const DEFAULT_PADDING: int = 24

## デフォルトグロー色（can_unlock 状態）
const DEFAULT_GLOW_COLOR_UNLOCK: String = "#88CCFF"

## デフォルトグロー色（unlocked 状態）
const DEFAULT_GLOW_COLOR_UNLOCKED: String = "#FFD27D"

## デフォルトエッジ色（ロック状態）
const DEFAULT_EDGE_COLOR_LOCKED: String = "#445066"

## デフォルトエッジ色（アクティブ状態）
const DEFAULT_EDGE_COLOR_ACTIVE: String = "#88CCFF"

## デフォルトノードプリセットキー
const DEFAULT_NODE_PRESET_KEY: String = "node_default"

## デフォルトエッジプリセットキー
const DEFAULT_EDGE_PRESET_KEY: String = "edge_default"


# --- Public Variables ---

## 背景設定（texture, tint, parallax）
var background: Dictionary = {}

## ウィンドウ設定（frame_9slice, padding）
var window: Dictionary = {}

## ノードプリセット一覧（キー: プリセット名, 値: プリセット辞書）
var node_presets: Dictionary = {}

## エッジプリセット一覧（キー: プリセット名, 値: プリセット辞書）
var edge_presets: Dictionary = {}

## エフェクト設定（glow 等）
var effects: Dictionary = {}

## フォント設定（main 等）
var fonts: Dictionary = {}


# --- Static Functions ---

## デフォルト値で初期化済みの ThemeData インスタンスを生成する
##
## @return: デフォルト値が設定された ThemeData
static func create_default() -> ThemeData:
	var theme: ThemeData = ThemeData.new()
	theme.background = {
		"texture": "",
		"tint": DEFAULT_BG_TINT,
		"parallax": {"enabled": false}
	}
	theme.window = {
		"frame_9slice": "",
		"padding": {
			"l": DEFAULT_PADDING,
			"t": DEFAULT_PADDING,
			"r": DEFAULT_PADDING,
			"b": DEFAULT_PADDING
		}
	}
	theme.node_presets = {
		DEFAULT_NODE_PRESET_KEY: {
			"base_texture": "",
			"size": DEFAULT_NODE_SIZE,
			"states": {
				"locked": {"overlay": "", "glow": false},
				"can_unlock": {
					"overlay": "",
					"glow": true,
					"glow_color": DEFAULT_GLOW_COLOR_UNLOCK
				},
				"unlocked": {
					"overlay": "",
					"glow": true,
					"glow_color": DEFAULT_GLOW_COLOR_UNLOCKED
				}
			}
		}
	}
	theme.edge_presets = {
		DEFAULT_EDGE_PRESET_KEY: {
			"width": DEFAULT_EDGE_WIDTH,
			"color_locked": DEFAULT_EDGE_COLOR_LOCKED,
			"color_active": DEFAULT_EDGE_COLOR_ACTIVE
		}
	}
	theme.effects = {
		"glow": {"texture": "", "blend": "add"}
	}
	theme.fonts = {
		"main": ""
	}
	return theme


# --- Public Functions ---

## 辞書からテーマデータを読み込む
##
## JSON パース済みの Dictionary から各セクションを復元する。
## 存在しないキーはデフォルト値（空辞書）のまま残る。
##
## @param data: JSON 辞書 (Dictionary)
func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		push_error("[ThemeData] from_dict: data is empty")
		return

	var version: int = data.get("schema_version", 0)
	if version != SCHEMA_VERSION:
		push_warning("[ThemeData] from_dict: schema_version mismatch (%d != %d)" % [version, SCHEMA_VERSION])

	background = data.get("background", {})
	window = data.get("window", {})
	node_presets = data.get("node_presets", {})
	edge_presets = data.get("edge_presets", {})
	effects = data.get("effects", {})
	fonts = data.get("fonts", {})


## テーマデータを辞書として書き出す
##
## schema_version を含む完全な JSON 辞書を返す。
##
## @return: テーマデータの Dictionary
func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"background": background,
		"window": window,
		"node_presets": node_presets,
		"edge_presets": edge_presets,
		"effects": effects,
		"fonts": fonts
	}


## テーマデータが有効かどうかを検証する
##
## node_presets に DEFAULT_NODE_PRESET_KEY、edge_presets に DEFAULT_EDGE_PRESET_KEY、
## background に "tint"、window に "padding" が存在するかを確認する。
##
## @return: 有効なら true
func is_valid() -> bool:
	if not node_presets.has(DEFAULT_NODE_PRESET_KEY):
		return false
	if not edge_presets.has(DEFAULT_EDGE_PRESET_KEY):
		return false
	if not background.has("tint"):
		return false
	if not window.has("padding"):
		return false
	return true


## 指定名のノードプリセットを取得する
##
## 存在しない場合はデフォルトプリセットにフォールバックする。
## デフォルトプリセットも存在しない場合は空辞書を返す。
##
## @param preset_name: プリセット名 (String)
## @return: プリセットの Dictionary
func get_node_preset(preset_name: String) -> Dictionary:
	if node_presets.has(preset_name):
		return node_presets[preset_name]
	# フォールバック: デフォルトプリセット
	if node_presets.has(DEFAULT_NODE_PRESET_KEY):
		return node_presets[DEFAULT_NODE_PRESET_KEY]
	return {}


## 指定名のエッジプリセットを取得する
##
## 存在しない場合はデフォルトプリセットにフォールバックする。
## デフォルトプリセットも存在しない場合は空辞書を返す。
##
## @param preset_name: プリセット名 (String)
## @return: プリセットの Dictionary
func get_edge_preset(preset_name: String) -> Dictionary:
	if edge_presets.has(preset_name):
		return edge_presets[preset_name]
	# フォールバック: デフォルトプリセット
	if edge_presets.has(DEFAULT_EDGE_PRESET_KEY):
		return edge_presets[DEFAULT_EDGE_PRESET_KEY]
	return {}
