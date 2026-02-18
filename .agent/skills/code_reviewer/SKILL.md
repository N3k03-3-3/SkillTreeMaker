---
name: Code Reviewer Guardrails
description: Code review guidelines and checklist for SkillTreeMaker project
---

# Code Reviewer Guardrails for SkillTreeMaker

このスキルは、SkillTreeMaker プロジェクトでコードレビューを実施する際の**必須ガードレール**を定義します。

---

## 🎯 役割と責務

### コードレビュアーの責務

1. **品質保証**: コードが規約・仕様に準拠しているか確認
2. **バグ検出**: 潜在的なバグやエッジケースを指摘
3. **知識共有**: より良い実装方法の提案
4. **学習促進**: レビューを通じてチーム全体のスキル向上

---

## 📋 レビューチェックリスト

### レベル1: 必須項目（CRITICAL）

これらの項目が満たされていない場合、**MUST FIX** として差し戻してください。

#### ✅ コメント必須項目

- [ ] **すべての public 関数にコメントがある**
  - 機能説明
  - `@param` で引数説明
  - `@return` で戻り値説明
  
```gdscript
# ❌ REJECT: コメントなし
func load_pack(path: String) -> Dictionary:
    return {}

# ✅ APPROVE: 適切なコメント
## Pack をロードして Dictionary を返す
##
## @param path: Pack のルートパス
## @return ロードされた Pack データまたは空の Dictionary
func load_pack(path: String) -> Dictionary:
    return {}
```

#### ✅ 型アノテーション必須

- [ ] **すべての変数に型アノテーションがある**
- [ ] **すべての関数引数に型がある**
- [ ] **すべての関数に戻り値の型がある**

```gdscript
# ❌ REJECT
var count = 0
func process(data):
    return data

# ✅ APPROVE
var count: int = 0
func process(data: Array) -> Dictionary:
    return {}
```

#### ✅ 命名規則準拠

- [ ] **クラス名**: PascalCase
- [ ] **ファイル名**: snake_case (クラス名と一致)
- [ ] **関数名**: snake_case
- [ ] **変数名**: snake_case
- [ ] **プライベートメンバー**: _snake_case
- [ ] **定数**: SCREAMING_SNAKE_CASE

```gdscript
# ❌ REJECT
class_name skillTreeModel  # PascalCase 違反
var NodeCount: int = 0     # snake_case 違反
var internalCache = {}     # プライベートなのに _ なし

# ✅ APPROVE
class_name SkillTreeModel
var node_count: int = 0
var _internal_cache: Dictionary = {}
```

#### ✅ エラーハンドリング

- [ ] **null チェックがある**（null になりうる変数）
- [ ] **早期リターンでエラー処理**
- [ ] **適切なエラーメッセージ**（`push_error`）

```gdscript
# ❌ REJECT: エラー処理なし
func load_file(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    return file.get_as_text()  # file が null の可能性

# ✅ APPROVE
func load_file(path: String) -> String:
    if path.is_empty():
        push_error("[ClassName] Path is empty")
        return ""
    
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("[ClassName] Failed to open: " + path)
        return ""
    
    return file.get_as_text()
```

---

### レベル2: 推奨項目（RECOMMENDED）

これらは改善提案として指摘してください（差し戻しは不要）。

#### 💡 コードの可読性

- [ ] **関数が短い**（目安: 50行以内）
- [ ] **ネストが浅い**（3段階以内）
- [ ] **マジックナンバーがない**（定数化されている）
- [ ] **変数名が明確**（略語を避ける）

```gdscript
# 💡 提案: 関数が長すぎる（分割推奨）
func process_all_data():
    # 100行以上のコード...

# 💡 提案: マジックナンバー
if count > 100:  # なぜ 100 なのか？
    pass

# ✅ 改善例
const MAX_COUNT: int = 100  # 最大処理数の制限
if count > MAX_COUNT:
    pass
```

#### 💡 パフォーマンス

- [ ] **不要な繰り返し計算がない**
- [ ] **@onready の適切な使用**
- [ ] **文字列連結の最適化**

```gdscript
# 💡 提案: 毎回 size() を計算
for i in items.size():
    process(items[i])

# ✅ 改善例
var count := items.size()
for i in count:
    process(items[i])
```

#### 💡 設計

- [ ] **単一責任原則に従っている**
- [ ] **DRY原則に従っている**（重複コードなし）
- [ ] **適切な抽象化レベル**

---

### レベル3: ベストプラクティス（OPTIONAL）

余裕があれば指摘してください。

#### 🌟 より良い設計

- コードの再利用性
- 拡張性の考慮
- テストのしやすさ

---

## 🔍 レビューフロー

### 1. 事前チェック（5分）

プルリクエストを開く前に以下を確認：

```markdown
## レビュー前セルフチェック

- [ ] 変更ファイル数は妥当か（目安: 10ファイル以内）
- [ ] 変更行数は妥当か（目安: 500行以内）
- [ ] コミットメッセージが明確か
- [ ] 差分が意図通りか（意図しない変更がないか）
```

### 2. レビュー実施（15-30分）

#### ステップ1: 全体確認

- 変更の目的を理解
- 関連する仕様・設計を確認
- 全体の構造を把握

#### ステップ2: 詳細レビュー

ファイルごとに以下を確認：

1. **必須項目チェック**（レベル1）
   - コメント
   - 型アノテーション
   - 命名規則
   - エラーハンドリング

2. **推奨項目チェック**（レベル2）
   - 可読性
   - パフォーマンス
   - 設計

3. **ロジック確認**
   - 想定通りの動作か
   - エッジケースの考慮
   - バグの可能性

#### ステップ3: フィードバック記述

コメントのテンプレート：

```markdown
## 🔴 MUST FIX (必須修正)

- [ ] [ファイル名:行番号] 指摘内容
  理由: XXX
  修正例: YYY

## 🟡 SHOULD FIX (推奨修正)

- [ ] [ファイル名:行番号] 指摘内容
  提案: XXX

## 🟢 GOOD POINTS (良い点)

- [ファイル名] 良かった点
```

---

## 📝 コメント例

### ✅ 良いコメント例

```markdown
## 🔴 MUST FIX

- [ ] skill_tree_model.gd:42 `load_pack` 関数にコメントがありません
  理由: public 関数にはコメントが必須です（coding_standards.md 参照）
  修正例:
  ```gdscript
  ## Pack をロードして SkillTreeModel を返す
  ##
  ## @param pack_root: Pack のルートディレクトリパス
  ## @return ロードされた SkillTreeModel または null
  func load_pack(pack_root: String) -> SkillTreeModel:
  ```

## 🟡 SHOULD FIX

- [ ] validator.gd:128 ネストが深すぎます（4段階）
  提案: 早期リターンで浅くできます
  ```gdscript
  # Before
  if a:
      if b:
          if c:
              if d:
                  process()
  
  # After
  if not a:
      return
  if not b:
      return
  if not c:
      return
  if not d:
      return
  process()
  ```

## 🟢 GOOD POINTS

- pack_repository.gd: エラーハンドリングが丁寧で読みやすい！
- theme_resolver.gd: 適切な関数分割で見通しが良い
```

### ❌ 悪いコメント例

```markdown
# ❌ 曖昧
- コメントが足りません

# ❌ 感情的
- このコード、ひどすぎます

# ❌ 理由なし
- ここを修正してください

# ✅ 具体的・建設的
- [ ] file.gd:42 `process_data` 関数にコメントがありません
  理由: コーディング規約により public 関数にはコメントが必須です
  修正例: （コード例を提示）
```

---

## 🚫 レビュー時の禁止事項

### ❌ やってはいけないこと

1. **人格攻撃**
   - ❌ "このコードは最悪です"
   - ✅ "このコードは可読性を改善できます"

2. **曖昧な指摘**
   - ❌ "なんか変です"
   - ✅ "null チェックが不足しています（例: file.gd:42）"

3. **一方的な押し付け**
   - ❌ "絶対にこうすべき"
   - ✅ "こうすると可読性が向上します。どう思いますか？"

4. **スコープ外の指摘**
   - ❌ 今回の変更と無関係な部分を指摘
   - ✅ 今回の変更に関連する部分のみ指摘

5. **重箱の隅**
   - ❌ スペースの位置など些細すぎる指摘
   - ✅ 機能・品質に影響する部分を優先

---

## 📊 レビュー判定基準

### APPROVE（承認）

以下の条件をすべて満たす場合、承認してください：

- ✅ レベル1（必須項目）がすべてクリア
- ✅ 論理的なバグがない
- ✅ 仕様・設計に準拠している

レベル2（推奨項目）は改善提案として残し、承認してOKです。

### REQUEST CHANGES（修正依頼）

以下のいずれかに該当する場合、修正依頼してください：

- ❌ レベル1（必須項目）の違反がある
- ❌ 論理的なバグがある
- ❌ 仕様・設計に反している

### COMMENT（コメントのみ）

質問や議論の余地がある場合に使用：

- 💬 設計の意図を確認したい
- 💬 代替案を提案したい
- 💬 より良い方法があるか議論したい

---

## 🎯 レビューの目的を忘れない

### レビューは批判ではなく、協力

- **目的**: チーム全体のコード品質向上
- **姿勢**: 建設的・教育的・協力的
- **結果**: より良いプロダクトとスキル向上

### 良いレビューの3原則

1. **Specific（具体的）**: どこが、なぜ、どう修正すべきか明確に
2. **Actionable（実行可能）**: 修正方法を提示
3. **Kind（親切）**: 敬意を持って、学びを促す

---

## 📚 参考資料

レビュー時に参照すべきドキュメント：

- `document/coding_standards.md` - コーディング規約
- `document/specification.md` - 仕様
- `document/クラス設計` - 設計図
- [Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)

---

## ✅ レビュアー最終チェックリスト

レビュー完了前に確認：

- [ ] レベル1（必須項目）をすべてチェックした
- [ ] 論理的なバグがないか確認した
- [ ] 仕様・設計に準拠しているか確認した
- [ ] フィードバックは具体的で建設的か
- [ ] Good Points（良い点）も指摘した
- [ ] 適切な判定（APPROVE / REQUEST CHANGES）をした

---

**高品質なレビューは、チーム全体の成長につながります。丁寧かつ建設的なレビューをお願いします。**
