---
name: Programmer Guardrails
description: Programming guidelines and mandatory checks for SkillTreeMaker development
---

# Programmer Guardrails for SkillTreeMaker

このスキルは、SkillTreeMaker プロジェクトでコードを実装する際の**必須ガードレール**を定義します。

---

## 🎯 役割と責務

### プログラマーの責務

1. **実装**: 仕様に基づいたコードの実装
2. **単体テスト**: 実装した機能のテスト作成
3. **ドキュメント**: コメントとドキュメントの整備
4. **コードレビュー対応**: レビュー指摘への対応

---

## 📋 必須チェックリスト

### コード実装前（BEFORE）

実装を開始する前に、以下を必ず確認してください：

- [ ] **仕様書を読んだ**
  - `document/specification.md` を確認
  - 該当する機能の要件を理解
  
- [ ] **設計書を確認した**
  - クラス設計図（Mermaid）を確認
  - 他のクラスとの依存関係を把握

- [ ] **コーディング規約を確認した**
  - `document/coding_standards.md` を熟読
  - 命名規則・コメント規約を把握

- [ ] **タスクが明確**
  - task.md で現在のタスクを確認
  - 実装範囲が明確

### コード実装中（DURING）

実装中は以下のルールを厳守してください：

#### 1. コメント必須

```gdscript
## すべての関数に必ず以下を含むコメントを記述
##
## - 機能説明
## - @param: 引数の説明（型と用途）
## - @return: 戻り値の説明
## - @warning: 注意事項（あれば）
func example_function(input: String) -> Dictionary:
    pass
```

#### 2. 型アノテーション必須

```gdscript
# ✅ すべての変数・引数・戻り値に型を明示
var node_count: int = 0
var nodes: Array[Dictionary] = []

func get_node(id: String) -> Dictionary:
    return {}
```

#### 3. エラーハンドリング必須

```gdscript
# ✅ 早期リターンでエラー処理
func load_file(path: String) -> Dictionary:
    if path.is_empty():
        push_error("[ClassName] Path is empty")
        return {}
    
    if not FileAccess.file_exists(path):
        push_error("[ClassName] File not found: " + path)
        return {}
    
    # 正常処理
    return {}
```

#### 4. 命名規則厳守

| 要素 | スタイル |
|------|---------|
| クラス | PascalCase |
| ファイル | snake_case |
| 関数 | snake_case |
| 変数 | snake_case |
| プライベート | _snake_case |
| 定数 | SCREAMING_SNAKE_CASE |

#### 5. DRY原則

- 同じコードを3回書いたら、関数・クラスに抽出
- 重複を見つけたら、リファクタリング

### コード実装後（AFTER）

実装完了後、以下を必ず実施してください：

- [ ] **セルフレビュー実施**
  - コーディング規約チェックリストを確認
  - 未使用変数・関数を削除
  - インポートを整理

- [ ] **動作確認**
  - 実装した機能が正しく動作するか確認
  - エッジケース（null, 空文字, 空配列）をテスト

- [ ] **コメント確認**
  - すべての public 関数にコメントがあるか
  - 複雑なロジックに説明コメントがあるか

- [ ] **エラーログ確認**
  - コンソールに警告・エラーが出ていないか
  - push_error の内容が適切か

---

## 🚫 禁止事項

以下の行為は**絶対に禁止**です：

### ❌ コメントなしのコード

```gdscript
# ❌ 禁止: コメントなし
func process_data(data):
    return data.map(lambda x: x * 2)
```

### ❌ 型アノテーションなし

```gdscript
# ❌ 禁止: 型なし
var count = 0
func get_item(id):
    return items[id]
```

### ❌ マジックナンバー

```gdscript
# ❌ 禁止
if count > 100:
    pass

# ✅ 正解
const MAX_COUNT: int = 100
if count > MAX_COUNT:
    pass
```

### ❌ エラー処理なし

```gdscript
# ❌ 禁止: エラー処理なし
func load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    return JSON.parse_string(file.get_as_text())  # file が null の可能性
```

### ❌ プライベート変数に _ なし

```gdscript
# ❌ 禁止
var internal_cache: Dictionary = {}

# ✅ 正解
var _internal_cache: Dictionary = {}
```

### ❌ 深いネスト（3段階以上）

```gdscript
# ❌ 禁止
func process():
    if a:
        if b:
            if c:
                # 深すぎる
```

---

## 🔍 実装パターン

### パターン1: データローダー

```gdscript
class_name DataLoader
extends RefCounted

## JSON ファイルをロードして Dictionary を返す
##
## @param file_path: 読み込むファイルの絶対パス
## @return ロードされた Dictionary または空の Dictionary（失敗時）
func load_json(file_path: String) -> Dictionary:
    # 早期リターン: 引数チェック
    if file_path.is_empty():
        push_error("[DataLoader] File path is empty")
        return {}
    
    # 早期リターン: ファイル存在チェック
    if not FileAccess.file_exists(file_path):
        push_error("[DataLoader] File not found: " + file_path)
        return {}
    
    # ファイル読み込み
    var file := FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_error("[DataLoader] Failed to open file: " + file_path)
        return {}
    
    # JSON パース
    var content := file.get_as_text()
    file.close()
    
    var json := JSON.new()
    var error := json.parse(content)
    
    if error != OK:
        push_error("[DataLoader] JSON parse error at line " + str(json.get_error_line()))
        return {}
    
    return json.data
```

### パターン2: バリデーター

```gdscript
class_name Validator
extends RefCounted

## バリデーション結果を保持するクラス
class ValidationReport:
    var errors: Array[String] = []
    var warnings: Array[String] = []
    
    func has_errors() -> bool:
        return errors.size() > 0
    
    func add_error(message: String) -> void:
        errors.append(message)
    
    func add_warning(message: String) -> void:
        warnings.append(message)

## SkillTreeModel を検証
##
## @param model: 検証対象のモデル
## @return ValidationReport インスタンス
func validate(model: SkillTreeModel) -> ValidationReport:
    var report := ValidationReport.new()
    
    _check_entry_node(model, report)
    _check_cycles(model, report)
    _check_unreachable_nodes(model, report)
    
    return report

## エントリーノードの存在を確認（プライベート）
func _check_entry_node(model: SkillTreeModel, report: ValidationReport) -> void:
    var entry_id: String = model.runtime_data.get("tree", {}).get("entry_node_id", "")
    
    if entry_id.is_empty():
        report.add_error("Entry node ID is not set")
        return
    
    var node := model.get_node(entry_id)
    if node.is_empty():
        report.add_error("Entry node not found: " + entry_id)
```

---

## 📊 パフォーマンスガイドライン

### DO ✅

```gdscript
# ✅ @onready でキャッシュ
@onready var canvas: Control = $Canvas

# ✅ 配列サイズをキャッシュ
var count := items.size()
for i in count:
    process(items[i])

# ✅ PackedStringArray で文字列結合
var lines := PackedStringArray()
for item in items:
    lines.append(item.to_string())
var result := "\n".join(lines)
```

### DON'T ❌

```gdscript
# ❌ 毎フレーム get_node
func _process(delta: float) -> void:
    $Canvas.queue_redraw()

# ❌ 毎回 size() 呼び出し
for i in items.size():
    process(items[i])

# ❌ 文字列連結の繰り返し
var result := ""
for item in items:
    result += item.to_string() + "\n"
```

---

## 🧪 テスト要件

実装した機能には、以下のテストを作成してください：

### 最低限のテスト

1. **正常系**: 期待通りの動作
2. **異常系**: エラーハンドリング
3. **境界値**: null, 空配列, 0, 最大値

### テストコード例

```gdscript
# tests/test_pack_repository.gd
extends GutTest

func test_load_pack_success():
    var repo := PackRepository.new()
    var model := repo.load_pack("res://test_data/valid_pack")
    
    assert_not_null(model, "Model should not be null")
    assert_eq(model.pack_meta.id, "test_pack", "Pack ID mismatch")

func test_load_pack_invalid_path():
    var repo := PackRepository.new()
    var model := repo.load_pack("invalid/path")
    
    assert_null(model, "Should return null for invalid path")

func test_load_pack_empty_path():
    var repo := PackRepository.new()
    var model := repo.load_pack("")
    
    assert_null(model, "Should return null for empty path")
```

---

## 🔧 推奨ツール

### gdlint

コード品質チェック用リンター：

```bash
pip install gdlint
gdlint addons/skill_tree_maker/
```

### GUT (Godot Unit Test)

単体テストフレームワーク：

```
https://github.com/bitwes/Gut
```

---

## 📞 困ったときは

### 質問の前にチェック

1. `document/coding_standards.md` を確認
2. `document/specification.md` で仕様を確認
3. 既存コードで類似実装を探す

### 質問する場合

- 何をしようとしているか
- 何がわからないか
- どこまで調べたか

を明確にして質問してください。

---

## ✅ 最終チェックリスト

コードレビュー依頼前に再確認：

- [ ] すべての関数にコメント（機能・引数・戻り値）
- [ ] すべての変数に型アノテーション
- [ ] 命名規則に準拠
- [ ] プライベートメンバーは `_` 始まり
- [ ] エラーハンドリング実装
- [ ] マジックナンバー排除
- [ ] ネストは3段階以内
- [ ] 動作確認完了
- [ ] コンソールエラー0件

---

**これらのガードレールを守ることで、高品質で保守性の高いコードを維持できます。**
