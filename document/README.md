# Document Directory

このディレクトリには、SkillTreeMaker プロジェクトの**仕様書・設計書・ガイドライン**が格納されています。

---

## 📁 ディレクトリ構造

```
document/
├── 0.作成仕様                      # 開発フロー・設計思想
├── 1.フォルダ仕様                  # Pack 構造・JSON スキーマ
├── 2.Godot EditorPlugin クラス設計 # アーキテクチャ・クラス図
├── coding_standards.md             # コーディング規約
└── README.md                       # このファイル
```

---

## 📚 ドキュメント一覧

### 仕様書・設計書

| ドキュメント | 説明 | 対象読者 |
|-------------|------|----------|
| **0.作成仕様** | 開発フロー、ツールとゲームの責務分離、SkillTree Pack の概念 | 全員 |
| **1.フォルダ仕様** | Pack 構造、JSON スキーマ（pack.json, runtime.json, theme.json） | プログラマー、デザイナー |
| **2.Godot EditorPlugin クラス設計** | システムアーキテクチャ、クラス図（Mermaid） | プログラマー |

### コーディング規約

| ドキュメント | 説明 | 対象読者 |
|-------------|------|----------|
| **coding_standards.md** | GDScript コーディング標準（命名規則、コメント規約、型アノテーション等） | 全員必読 |

---

## 🎯 読む順序（新規メンバー向け）

### 1. プロジェクト概要を理解

まず [`../README.md`](../README.md) を読んで、プロジェクト全体を把握。

### 2. 設計思想を学ぶ

次に以下を順に読む：

1. **0.作成仕様** - なぜこの設計にしたのか
2. **1.フォルダ仕様** - 具体的なデータ構造
3. **2.Godot EditorPlugin クラス設計** - 実装アーキテクチャ

### 3. コーディング規約を確認

**coding_standards.md** を熟読し、ルールを理解。

### 4. 役割別ガイドラインを読む

自分の役割に応じて：
- プログラマー → [`.agent/skills/programmer/SKILL.md`](../.agent/skills/programmer/SKILL.md)
- レビュアー → [`.agent/skills/code_reviewer/SKILL.md`](../.agent/skills/code_reviewer/SKILL.md)
- デザイナー → [`.agent/skills/designer/SKILL.md`](../.agent/skills/designer/SKILL.md)

---

## 📝 ドキュメント詳細

### 0.作成仕様

**内容**:
- 目指す開発フロー
- SkillTree Pack の中身
- JSON 分離の理由（pack.json vs runtime.json）
- テーマ設計（Style Preset）
- Godot アドインとしての実装方針
- ゲーム内反映の最短ルート
- 開発手順書

**重要ポイント**:
> ツールの責務は **編集・検証・書き出し（パック化）**。  
> ゲームの責務は **読み込み・描画・操作・取得判定（必要なら）**。  
> 両者を繋ぐのが **"SkillTree Pack"**。

---

### 1.フォルダ仕様

**内容**:
- SkillTree Pack の正式フォルダ構造
- pack.json スキーマ（編集・管理用）
- runtime.json スキーマ（ゲーム実行用）
- theme.json スキーマ（テーマ定義）

**重要ポイント**:
- `pack.json` はツールのみが読む（作業状態、メモ等含む）
- `runtime.json` はゲームが読む最小限のデータ
- `theme.json` で見た目を完全に分離

---

### 2.Godot EditorPlugin クラス設計

**内容**:
- UI（View）、データ（Model）、処理（Service）の分離
- クラス図（Mermaid）
- 主要クラスの責務

**重要ポイント**:
- EditorPlugin と ゲーム内実装で同じデータモデルを使える設計
- PackRepository, RuntimeExporter, Validator などのサービス層

---

### coding_standards.md

**内容**:
- 命名規則（snake_case / PascalCase）
- コメント規約（必須事項）
- 型アノテーション必須化
- コード構造（ファイル構造順序）
- エラーハンドリングパターン
- パフォーマンスガイドライン
- 禁止事項

**重要ポイント**:
- ✅ すべての関数にコメント必須
- ✅ すべての変数に型アノテーション必須
- ❌ マジックナンバー禁止
- ❌ 深いネスト禁止

---

## 🔄 ドキュメントの更新

### 更新が必要な場合

- 仕様変更
- 新機能追加
- 既存機能の改善
- アーキテクチャ変更

### 更新プロセス

1. **Issue 作成**: ドキュメント更新の必要性を記録
2. **ブランチ作成**: `docs/更新内容`
3. **ドキュメント編集**
4. **レビュー**: チームで確認
5. **マージ**: main へマージ

---

## 📊 ドキュメントの種類

### 仕様書（Specification）

- **目的**: 何を作るか
- **読者**: 全員
- **更新頻度**: 低（仕様確定後は変更少ない）

### 設計書（Design）

- **目的**: どう作るか
- **読者**: プログラマー
- **更新頻度**: 中（実装に合わせて調整）

### ガイドライン（Guidelines）

- **目的**: どう書くか
- **読者**: 全員
- **更新頻度**: 低（ベストプラクティスは安定）

---

## 🔗 関連リンク

### プロジェクト管理
- [README.md](../README.md) - プロジェクト概要
- [CONTRIBUTING.md](../CONTRIBUTING.md) - 貢献ガイド
- [CHANGELOG.md](../CHANGELOG.md) - 変更履歴

### 開発ガイドライン
- [`.agent/README.md`](../.agent/README.md) - Skills の説明
- [`.agent/workflows/feature-development.md`](../.agent/workflows/feature-development.md) - 開発ワークフロー

### 外部リソース
- [Godot Documentation](https://docs.godotengine.org/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

---

**このディレクトリのドキュメントは、プロジェクトの知識ベースです。開発中は常に参照してください。**
