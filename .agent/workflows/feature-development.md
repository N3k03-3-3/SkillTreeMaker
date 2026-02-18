---
description: 新機能開発のワークフロー
---

# 新機能開発ワークフロー

このワークフローは、SkillTreeMaker プロジェクトで新機能を開発する際の標準プロセスを定義します。

---

## 📋 概要

新機能開発は以下のフェーズで進めます：

1. **計画** (Planning)
2. **設計** (Design)
3. **実装** (Implementation)
4. **レビュー** (Review)
5. **テスト** (Testing)
6. **マージ** (Merge)

---

## Phase 1: 計画 (Planning)

### ステップ 1.1: Issue 作成

新機能のアイデアを Issue として記録します。

```markdown
## 機能概要
[機能の説明]

## 背景・動機
[なぜこの機能が必要か]

## 受け入れ基準
- [ ] 基準1
- [ ] 基準2

## 優先度
- [ ] High
- [ ] Medium
- [ ] Low
```

### ステップ 1.2: 仕様確認

関連する仕様書を確認：
- `document/specification.md`
- `document/クラス設計`

### ステップ 1.3: タスク分解

`task.md` に作業を追加：

```markdown
## [機能名]
- [ ] 設計書作成
- [ ] XXX クラス実装
- [ ] テストコード作成
- [ ] ドキュメント更新
```

---

## Phase 2: 設計 (Design)

### ステップ 2.1: 技術設計

以下を明確化：
- 影響を受けるクラス・ファイル
- 新規作成するクラス・ファイル
- データフォーマットの変更
- 後方互換性の考慮

### ステップ 2.2: ブランチ作成

```bash
git checkout -b feature/機能名
```

命名規則：
- `feature/` - 新機能
- `fix/` - バグ修正
- `refactor/` - リファクタリング
- `docs/` - ドキュメントのみ

---

## Phase 3: 実装 (Implementation)

### ステップ 3.1: コーディング規約確認

[`document/coding_standards.md`](../../document/coding_standards.md) を再確認。

### ステップ 3.2: Programmer Skill に従って実装

[`.agent/skills/programmer/SKILL.md`](../skills/programmer/SKILL.md) のチェックリストを使用：

**実装前**
- [ ] 仕様書を読んだ
- [ ] 設計を確認した
- [ ] コーディング規約を確認した

**実装中**
- [ ] すべての関数にコメント
- [ ] すべての変数に型アノテーション
- [ ] エラーハンドリング実装
- [ ] 命名規則厳守

**実装後**
- [ ] セルフレビュー実施
- [ ] 動作確認完了
- [ ] エラーログ0件

### ステップ 3.3: コミット

コミットメッセージ規約：

```
[type] 簡潔な説明

詳細説明（必要であれば）

Refs: #Issue番号
```

**type**:
- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `docs`: ドキュメント
- `test`: テスト追加・修正
- `style`: コードフォーマット

**例**:
```
feat: PackRepository にロード機能を実装

pack.json と runtime.json を読み込み、
SkillTreeModel を構築する機能を追加。

Refs: #42
```

---

## Phase 4: レビュー (Review)

### ステップ 4.1: プルリクエスト作成

```markdown
## 変更内容
[何を変更したか]

## 動機・背景
[なぜこの変更が必要か]

## テスト方法
[どのようにテストしたか]

## チェックリスト
- [ ] コーディング規約に準拠
- [ ] すべての関数にコメント
- [ ] 動作確認完了
- [ ] テストコード追加

## スクリーンショット（該当する場合）
[画像]

Refs: #Issue番号
```

### ステップ 4.2: レビュー依頼

レビュアーは [`.agent/skills/code_reviewer/SKILL.md`](../skills/code_reviewer/SKILL.md) に従ってレビュー。

### ステップ 4.3: フィードバック対応

レビューコメントに対応：
- 🔴 MUST FIX → 必ず修正
- 🟡 SHOULD FIX → 可能な限り修正
- 💬 議論 → チームで合意形成

---

## Phase 5: テスト (Testing)

### ステップ 5.1: 単体テスト

Godot Unit Test (GUT) でテスト：

```gdscript
extends GutTest

func test_load_pack_success():
    var repo := PackRepository.new()
    var model := repo.load_pack("res://test_data/valid_pack")
    
    assert_not_null(model)
    assert_eq(model.pack_meta.id, "test_pack")
```

### ステップ 5.2: 統合テスト

実際の Godot プロジェクトで動作確認：

```bash
# Godot MCP を使用
"Godotプロジェクトを実行してください"
```

### ステップ 5.3: エッジケーステスト

- null 入力
- 空文字列
- 不正なファイルパス
- 破損した JSON

---

## Phase 6: マージ (Merge)

### ステップ 6.1: 最終確認

- [ ] すべてのレビューコメントに対応
- [ ] テストがすべてパス
- [ ] コンフリクトが解消
- [ ] ドキュメントが更新済み

### ステップ 6.2: マージ

```bash
git checkout main
git merge feature/機能名
git push origin main
```

### ステップ 6.3: クリーンアップ

```bash
# ローカルブランチ削除
git branch -d feature/機能名

# リモートブランチ削除
git push origin --delete feature/機能名
```

### ステップ 6.4: Issue クローズ

Issue を "Done" にして、完了を記録。

---

## 🚨 トラブルシューティング

### コンフリクトが発生した

```bash
# main の最新を取得
git fetch origin
git rebase origin/main

# コンフリクト解消後
git add .
git rebase --continue
```

### レビューで大幅な修正が必要

設計に戻って再検討。必要なら別ブランチで再実装。

### テストが通らない

1. ローカルで再現
2. デバッグログで原因特定
3. 修正してコミット
4. 再度テスト

---

## ⏱️ 各フェーズの目安時間

| フェーズ | 小規模 | 中規模 | 大規模 |
|---------|--------|--------|--------|
| 計画 | 30分 | 1時間 | 2時間 |
| 設計 | 1時間 | 3時間 | 1日 |
| 実装 | 2時間 | 1日 | 3日 |
| レビュー | 30分 | 1時間 | 2時間 |
| テスト | 1時間 | 2時間 | 1日 |

---

## ✅ チェックリスト（全体）

開発完了前に確認：

- [ ] 仕様に準拠している
- [ ] コーディング規約に準拠している
- [ ] すべての関数にコメント
- [ ] すべての変数に型アノテーション
- [ ] エラーハンドリング実装
- [ ] セルフレビュー完了
- [ ] 単体テスト作成
- [ ] 統合テスト完了
- [ ] ドキュメント更新
- [ ] コードレビュー承認
- [ ] コンフリクト解消

---

**このワークフローに従うことで、高品質で一貫性のある開発を実現できます。**
