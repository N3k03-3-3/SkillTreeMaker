class_name SkillEntry
extends RefCounted

## スキル1件分のデータを保持するモデルクラス
##
## スキルの ID、表示名、説明、カテゴリ、アイコン、最大レベル、
## ステータス、タグを保持し、Dictionary との相互変換を提供する。


# --- Constants ---

## カテゴリ: アクティブスキル
const CATEGORY_ACTIVE: String = "active"

## カテゴリ: パッシブスキル
const CATEGORY_PASSIVE: String = "passive"

## カテゴリ: トグルスキル
const CATEGORY_TOGGLE: String = "toggle"

## デフォルトの最大レベル
const DEFAULT_LEVEL_MAX: int = 1


# --- Public Variables ---

## スキル固有 ID
var id: String = ""

## 表示名
var display_name: String = ""

## スキルの説明文
var description: String = ""

## カテゴリ（"active" / "passive" / "toggle"）
var category: String = CATEGORY_ACTIVE

## アイコン画像の res:// パス
var icon_path: String = ""

## 最大レベル
var level_max: int = DEFAULT_LEVEL_MAX

## ゲーム固有のステータス辞書（例: {"mp_cost": 10, "damage": 50}）
var stats: Dictionary = {}

## タグ一覧
var tags: Array[String] = []


# --- Public Functions ---

## 全フィールドを辞書に変換して返す
##
## @return: スキルデータを格納した Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"category": category,
		"icon_path": icon_path,
		"level_max": level_max,
		"stats": stats.duplicate(),
		"tags": tags.duplicate(),
	}


## 辞書から SkillEntry を復元して返す
##
## @param d: スキルデータの Dictionary
## @return: 復元された SkillEntry インスタンス
static func from_dict(d: Dictionary) -> SkillEntry:
	var entry: SkillEntry = SkillEntry.new()
	entry.id = d.get("id", "")
	entry.display_name = d.get("display_name", "")
	entry.description = d.get("description", "")
	entry.category = d.get("category", CATEGORY_ACTIVE)
	entry.icon_path = d.get("icon_path", "")
	entry.level_max = d.get("level_max", DEFAULT_LEVEL_MAX)
	entry.stats = d.get("stats", {})

	var raw_tags: Array = d.get("tags", [])
	var typed_tags: Array[String] = []
	for tag: Variant in raw_tags:
		typed_tags.append(str(tag))
	entry.tags = typed_tags

	return entry
