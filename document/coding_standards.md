# SkillTreeMaker コーディング規約

**バージョン**: 1.0  
**最終更新**: 2026-01-25  
**対象言語**: GDScript (Godot 4.5+)

---

## 📋 目次

1. [基本方針](#基本方針)
2. [命名規則](#命名規則)
3. [コメント規約](#コメント規約)
4. [コード構造](#コード構造)
5. [型アノテーション](#型アノテーション)
6. [エラーハンドリング](#エラーハンドリング)
7. [パフォーマンス](#パフォーマンス)
8. [禁止事項](#禁止事項)

---

## 基本方針

### 設計原則

1. **可読性優先**: コードは書くより読まれることが多い
2. **明示的優先**: 暗黙的な動作よりも明示的な記述
3. **DRY原則**: Don't Repeat Yourself - 重複を避ける
4. **単一責任**: 1つのクラス・関数は1つの責務のみ
5. **コメント必須**: すべての関数・クラスにコメント必須

### Godot 公式スタイルガイド準拠

このプロジェクトは [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) を基準とし、追加ルールを適用します。

---

## 命名規則

### ケーススタイル

| 要素 | スタイル | 例 |
|------|---------|-----|
| **クラス名** | PascalCase | `SkillTreeModel`, `PackRepository` |
| **ファイル名** | snake_case | `skill_tree_model.gd`, `pack_repository.gd` |
| **関数名** | snake_case | `load_pack()`, `validate_structure()` |
| **変数名（ローカル）** | snake_case | `node_count`, `current_index` |
| **変数名（プライベート）** | _snake_case | `_internal_state`, `_cache` |
| **定数名** | SCREAMING_SNAKE_CASE | `MAX_NODES`, `DEFAULT_THEME_PATH` |
| **シグナル名** | snake_case | `node_selected`, `pack_loaded` |
| **列挙型** | PascalCase (型) + SCREAMING_SNAKE_CASE (値) | `enum NodeState { LOCKED, UNLOCKED }` |

### 命名の明確性

#### ✅ 良い例

```gdscript
var node_count: int = 0
var is_valid: bool = false
var player_position: Vector2 = Vector2.ZERO
func calculate_total_cost() -> int:
    pass
```

#### ❌ 悪い例

```gdscript
var n: int = 0  # 略語は避ける
var flag: bool = false  # 意味が不明確
var pos = Vector2.ZERO  # 型アノテーションなし
func calc() -> int:  # 略語は避ける
    pass
```

### プライベートメンバー

クラス内部でのみ使用する変数・関数は必ずアンダースコア `_` で始める。

```gdscript
class_name SkillTreeModel
extends RefCounted

var public_data: Dictionary = {}  # 外部からアクセス可能
var _internal_cache: Array = []   # 内部使用のみ

func get_node(id: String) -> Dictionary:
    return _find_in_cache(id)

func _find_in_cache(id: String) -> Dictionary:
    # プライベートヘルパー関数
    pass
```

---

## コメント規約

### 必須コメント

すべての**クラス**、**関数**、**複雑なロジック**にコメントを記述すること。

### クラスコメント

```gdscript
## SkillTree のデータモデルを管理するクラス
##
## ノード、エッジ、メタ情報を保持し、Pack の読み書きをサポートする。
## runtime.json と pack.json の両方に対応。
##
## @tutorial: https://example.com/docs/skill-tree-model
class_name SkillTreeModel
extends RefCounted
```

### 関数コメント（必須）

すべての public 関数には以下を含むコメントを記述：

1. **機能説明**
2. **引数の説明** (`@param`)
3. **戻り値の説明** (`@return`)
4. **例外・エラー** (`@throws` または `@warning`)

```gdscript
## 指定された Pack ルートからスキルツリーをロードする
##
## pack.json と runtime.json を読み込み、SkillTreeModel インスタンスを構築する。
## ファイルが存在しない場合はエラーを返す。
##
## @param pack_root: Pack のルートディレクトリパス（絶対パス）
## @return ロードされた SkillTreeModel または null（失敗時）
## @warning pack_root が存在しない場合は null を返す
func load_pack(pack_root: String) -> SkillTreeModel:
    if not DirAccess.dir_exists_absolute(pack_root):
        push_error("Pack root does not exist: " + pack_root)
        return null
    
    # 実装...
    return SkillTreeModel.new()
```

### インラインコメント

複雑なロジックには説明コメントを追加。

```gdscript
func validate_structure(model: SkillTreeModel) -> ValidationReport:
    var report := ValidationReport.new()
    
    # 循環参照チェック: DFS で visited を追跡
    var visited: Dictionary = {}
    var stack: Array[String] = []
    
    for node in model.nodes:
        if node.id in visited:
            continue
        
        # スタックに追加して深さ優先探索開始
        stack.append(node.id)
        # ...
```

### TODO/FIXME/HACK コメント

```gdscript
# TODO: パフォーマンス改善 - キャッシュ機構を導入
# FIXME: エッジケースで null 参照が発生する可能性
# HACK: Godot 4.5.1 のバグ回避のための一時的な実装
```

---

## コード構造

### ファイル構造順序

GDScript ファイルは以下の順序で記述：

1. `class_name` 宣言
2. `extends` 宣言
3. クラスドキュメントコメント (`##`)
4. シグナル (`signal`)
5. 列挙型 (`enum`)
6. 定数 (`const`)
7. エクスポート変数 (`@export`)
8. パブリック変数
9. プライベート変数 (`_` 始まり)
10. `@onready` 変数
11. 組み込み仮想関数 (`_init`, `_ready`, `_process` 等)
12. パブリック関数
13. プライベート関数
14. インナークラス

```gdscript
class_name SkillTreeModel
extends RefCounted

## スキルツリーのデータモデル

# シグナル
signal structure_changed()
signal node_added(node_id: String)

# 列挙型
enum ValidationLevel {
    STRICT,
    NORMAL,
    LOOSE
}

# 定数
const SCHEMA_VERSION: int = 1
const MAX_NODES: int = 1000

# エクスポート変数
@export var debug_mode: bool = false

# パブリック変数
var pack_meta: Dictionary = {}
var runtime_data: Dictionary = {}

# プライベート変数
var _internal_cache: Dictionary = {}
var _is_dirty: bool = false

# @onready 変数
@onready var _file_handler := FileAccess.new()

# 組み込み関数
func _init() -> void:
    pass

# パブリック関数
func load_pack(pack_root: String) -> bool:
    pass

# プライベート関数
func _parse_json(path: String) -> Dictionary:
    pass
```

### インデント

- **タブ文字を使用** (Godot エディタのデフォルト)
- ネストごとに1レベル

### 行の長さ

- **推奨**: 100文字以内
- **最大**: 120文字

長い行は適切に分割：

```gdscript
# ✅ 良い例
var result := calculate_total_cost(
    node_count,
    base_cost,
    multiplier
)

# ❌ 悪い例
var result := calculate_total_cost(node_count, base_cost, multiplier, discount_rate, tax_rate, bonus_modifier)
```

---

## 型アノテーション

### 必須事項

すべての変数、関数の引数、戻り値に**型アノテーションを明示**すること。

```gdscript
# ✅ 良い例
var node_id: String = "n_001"
var position: Vector2 = Vector2(100, 200)
var nodes: Array[Dictionary] = []

func get_node_by_id(id: String) -> Dictionary:
    return {}

# ❌ 悪い例
var node_id = "n_001"  # 型推論に頼らない
var position = Vector2(100, 200)

func get_node_by_id(id):  # 型なし
    return {}
```

### 配列・辞書の型指定

Godot 4.0+ では配列の型指定が可能：

```gdscript
# 型付き配列
var node_ids: Array[String] = []
var positions: Array[Vector2] = []
var nodes: Array[Dictionary] = []

# 辞書（型指定不可だがコメントで明示）
var node_map: Dictionary = {}  # Dictionary[String, Dictionary]
```

### null 許容

null を返す可能性がある場合は、コメントで明示：

```gdscript
## ノードを ID で検索
## @return ノードの Dictionary または null（見つからない場合）
func find_node(id: String) -> Dictionary:
    # null を返す可能性あり
    return node_map.get(id, null)
```

---

## エラーハンドリング

### エラー処理の基本方針

1. **早期リターン**: エラー条件は関数の先頭でチェック
2. **明示的なエラー**: `push_error()` でエラーを報告
3. **null 安全**: null チェックを徹底

```gdscript
func load_pack(pack_root: String) -> SkillTreeModel:
    # 早期リターン: エラー条件を先にチェック
    if pack_root.is_empty():
        push_error("Pack root path is empty")
        return null
    
    if not DirAccess.dir_exists_absolute(pack_root):
        push_error("Pack root does not exist: " + pack_root)
        return null
    
    # 正常パス
    var model := SkillTreeModel.new()
    # ...
    return model
```

### エラーメッセージ

エラーメッセージは以下の形式：

```
[クラス名] エラー内容: 詳細情報
```

```gdscript
push_error("[PackRepository] Failed to load pack.json: " + pack_path)
push_warning("[Validator] Unreachable node detected: " + node_id)
```

---

## パフォーマンス

### @onready の活用

ノード取得は `@onready` を使用してキャッシュ：

```gdscript
# ✅ 良い例
@onready var canvas: Control = $Canvas
@onready var inspector: Panel = $Inspector

func _process(delta: float) -> void:
    canvas.queue_redraw()

# ❌ 悪い例
func _process(delta: float) -> void:
    $Canvas.queue_redraw()  # 毎フレーム検索
```

### ループ最適化

```gdscript
# ✅ 良い例: 配列サイズをキャッシュ
var count := nodes.size()
for i in count:
    process_node(nodes[i])

# ❌ 悪い例: 毎回 size() を呼ぶ
for i in nodes.size():
    process_node(nodes[i])
```

### 文字列連結

大量の文字列連結は `String` より `PackedStringArray` を使用：

```gdscript
# ✅ 良い例
var lines := PackedStringArray()
for node in nodes:
    lines.append(node.id)
var result := "\n".join(lines)

# ❌ 悪い例
var result := ""
for node in nodes:
    result += node.id + "\n"
```

---

## 禁止事項

### ❌ グローバル変数の乱用

```gdscript
# ❌ 禁止
var global_state = {}  # ファイルスコープのグローバル

# ✅ 許可: シングルトンパターン
# autoload で登録されたシングルトンは OK
```

### ❌ マジックナンバー

```gdscript
# ❌ 悪い例
if node_count > 100:
    pass

# ✅ 良い例
const MAX_NODES: int = 100
if node_count > MAX_NODES:
    pass
```

### ❌ 深いネスト

3段階以上のネストは避け、早期リターンやヘルパー関数で分離：

```gdscript
# ❌ 悪い例
func process():
    if condition1:
        if condition2:
            if condition3:
                # 深すぎる

# ✅ 良い例
func process():
    if not condition1:
        return
    if not condition2:
        return
    if not condition3:
        return
    
    # 処理
```

### ❌ 未使用変数・関数

IDE の警告に従い、未使用のコードは削除：

```gdscript
# ❌ 悪い例
func calculate(a: int, b: int, c: int) -> int:
    return a + b  # c は未使用

# ✅ 良い例
func calculate(a: int, b: int) -> int:
    return a + b
```

---

## リンター・フォーマッター

### gdlint（推奨）

プロジェクトでは `gdlint` の使用を推奨：

```bash
# インストール
pip install gdlint

# 実行
gdlint addons/skill_tree_maker/
```

### Godot エディタ設定

**Editor Settings** → **Text Editor** → **Behavior**:
- **Indent Type**: Tabs
- **Indent Size**: 1
- **Auto Indent**: On

---

## チェックリスト

コードレビュー前に以下を確認：

- [ ] すべての関数にコメント（機能、引数、戻り値）
- [ ] すべての変数に型アノテーション
- [ ] 命名規則に準拠（snake_case / PascalCase）
- [ ] プライベートメンバーは `_` で開始
- [ ] エラーハンドリング実装（null チェック、早期リターン）
- [ ] マジックナンバー排除（定数化）
- [ ] ネストは3段階以内
- [ ] インポート・依存関係を最小化

---

## 参考資料

- [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Google Style Guides](https://google.github.io/styleguide/)
- [Clean Code by Robert C. Martin](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)

---

**このコーディング規約は、すべてのチームメンバーが従うべき必須基準です。**
