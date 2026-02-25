class_name ThemePresetLibrary
extends RefCounted

## ビルトインテーマプリセットを提供するサービス
##
## テーマ名をキーに Dictionary 形式の theme.json 構造を返す。
## ThemeData に依存せず raw Dictionary を返す設計。


# --- Constants ---

## プリセット名: デフォルト
const PRESET_DEFAULT: String = "default"

## プリセット名: スペース
const PRESET_SPACE: String = "space"

## プリセット名: アーケイン
const PRESET_ARCANE: String = "arcane"

## 全プリセット名の配列
const ALL_PRESET_NAMES: Array[String] = ["default", "space", "arcane"]

## スキーマバージョン
const SCHEMA_VERSION: int = 1

## ウィンドウパディング（左）
const WINDOW_PADDING_LEFT: int = 24

## ウィンドウパディング（上）
const WINDOW_PADDING_TOP: int = 24

## ウィンドウパディング（右）
const WINDOW_PADDING_RIGHT: int = 24

## ウィンドウパディング（下）
const WINDOW_PADDING_BOTTOM: int = 24

## ノードデフォルトサイズ
const NODE_DEFAULT_SIZE: int = 48

## エッジデフォルト幅
const EDGE_DEFAULT_WIDTH: int = 3

## エッジロック色（共通）
const EDGE_COLOR_LOCKED: String = "#445066"

## エッジアクティブ色（デフォルト）
const EDGE_COLOR_ACTIVE_DEFAULT: String = "#88CCFF"

## --- Default テーマ色定数 ---

## デフォルト: 背景色
const DEFAULT_BG_TINT: String = "#1A1A2E"

## デフォルト: アンロック可能グロー色
const DEFAULT_CAN_UNLOCK_GLOW: String = "#88CCFF"

## デフォルト: アンロック済みグロー色
const DEFAULT_UNLOCKED_GLOW: String = "#FFD27D"

## --- Space テーマ色定数 ---

## スペース: 背景色
const SPACE_BG_TINT: String = "#0A0A1A"

## スペース: アンロック可能グロー色
const SPACE_CAN_UNLOCK_GLOW: String = "#00BFFF"

## スペース: アンロック済みグロー色
const SPACE_UNLOCKED_GLOW: String = "#87CEEB"

## スペース: エッジアクティブ色
const SPACE_EDGE_COLOR_ACTIVE: String = "#00BFFF"

## --- Arcane テーマ色定数 ---

## アーケイン: 背景色
const ARCANE_BG_TINT: String = "#1A0A2E"

## アーケイン: アンロック可能グロー色
const ARCANE_CAN_UNLOCK_GLOW: String = "#BF00FF"

## アーケイン: アンロック済みグロー色
const ARCANE_UNLOCKED_GLOW: String = "#DA70D6"

## アーケイン: エッジアクティブ色
const ARCANE_EDGE_COLOR_ACTIVE: String = "#BF00FF"

## ノードデフォルトプリセットキー（ThemeData.DEFAULT_NODE_PRESET_KEY と値を一致させること）
const NODE_DEFAULT_KEY: String = "node_default"

## エッジデフォルトプリセットキー（ThemeData.DEFAULT_EDGE_PRESET_KEY と値を一致させること）
const EDGE_DEFAULT_KEY: String = "edge_default"


# --- Public Static Functions ---

## 利用可能なプリセット名一覧を返す
##
## @return: プリセット名の配列
static func get_preset_names() -> Array[String]:
	return ALL_PRESET_NAMES.duplicate()


## 指定されたプリセット名に対応するテーマ Dictionary を生成する
##
## 不明なプリセット名が指定された場合は default テーマを返す。
## 新プリセット追加時は ALL_PRESET_NAMES 定数も合わせて更新すること。
##
## @param preset_name: プリセット名 (String)
## @return: theme.json 形式の Dictionary
static func create_preset(preset_name: String) -> Dictionary:
	match preset_name:
		PRESET_SPACE:
			return get_space_theme()
		PRESET_ARCANE:
			return get_arcane_theme()
		_:
			return get_default_theme()


## デフォルトテーマの Dictionary を返す
##
## @return: default テーマの theme.json 形式 Dictionary
static func get_default_theme() -> Dictionary:
	return _build_theme(
		DEFAULT_BG_TINT,
		DEFAULT_CAN_UNLOCK_GLOW,
		DEFAULT_UNLOCKED_GLOW,
		EDGE_COLOR_ACTIVE_DEFAULT,
	)


## スペーステーマの Dictionary を返す
##
## @return: space テーマの theme.json 形式 Dictionary
static func get_space_theme() -> Dictionary:
	return _build_theme(
		SPACE_BG_TINT,
		SPACE_CAN_UNLOCK_GLOW,
		SPACE_UNLOCKED_GLOW,
		SPACE_EDGE_COLOR_ACTIVE,
	)


## アーケインテーマの Dictionary を返す
##
## @return: arcane テーマの theme.json 形式 Dictionary
static func get_arcane_theme() -> Dictionary:
	return _build_theme(
		ARCANE_BG_TINT,
		ARCANE_CAN_UNLOCK_GLOW,
		ARCANE_UNLOCKED_GLOW,
		ARCANE_EDGE_COLOR_ACTIVE,
	)


# --- Private Static Functions ---

## テーマ Dictionary を共通構造で構築する
##
## @param bg_tint: 背景色 (String)
## @param can_unlock_glow: アンロック可能時のグロー色 (String)
## @param unlocked_glow: アンロック済みのグロー色 (String)
## @param edge_active: エッジアクティブ色 (String)
## @return: theme.json 形式の Dictionary
static func _build_theme(
	bg_tint: String,
	can_unlock_glow: String,
	unlocked_glow: String,
	edge_active: String,
) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"background": {
			"texture": "",
			"tint": bg_tint,
			"parallax": {"enabled": false},
		},
		"window": {
			"frame_9slice": "",
			"padding": {
				"l": WINDOW_PADDING_LEFT,
				"t": WINDOW_PADDING_TOP,
				"r": WINDOW_PADDING_RIGHT,
				"b": WINDOW_PADDING_BOTTOM,
			},
		},
		"node_presets": {
			NODE_DEFAULT_KEY: {
				"base_texture": "",
				"size": NODE_DEFAULT_SIZE,
				"states": {
					"locked": {"overlay": "", "glow": false},
					"can_unlock": {
						"overlay": "",
						"glow": true,
						"glow_color": can_unlock_glow,
					},
					"unlocked": {
						"overlay": "",
						"glow": true,
						"glow_color": unlocked_glow,
					},
				},
			},
		},
		"edge_presets": {
			EDGE_DEFAULT_KEY: {
				"width": EDGE_DEFAULT_WIDTH,
				"color_locked": EDGE_COLOR_LOCKED,
				"color_active": edge_active,
			},
		},
		"effects": {},
		"fonts": {},
	}
