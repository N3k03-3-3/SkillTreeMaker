# Contributing to SkillTreeMaker

SkillTreeMaker プロジェクトへの貢献に興味を持っていただき、ありがとうございます！

このドキュメントは、プロジェクトへの貢献方法をガイドします。

---

## 📋 目次

1. [行動規範](#行動規範)
2. [始め方](#始め方)
3. [開発プロセス](#開発プロセス)
4. [コーディング規約](#コーディング規約)
5. [コミット規約](#コミット規約)
6. [プルリクエスト](#プルリクエスト)
7. [質問とサポート](#質問とサポート)

---

## 行動規範

### 基本原則

1. **敬意を持つ**: すべてのコントリビューターを尊重する
2. **建設的**: フィードバックは具体的で建設的に
3. **協力的**: チーム全体の成功を優先
4. **オープン**: 質問を歓迎し、知識を共有

### 禁止事項

- ハラスメント、差別、攻撃的な言動
- 他者のプライバシー侵害
- 技術的・非技術的な妨害行為

---

## 始め方

### 1. プロジェクトのセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/SkillTreeMaker.git
cd SkillTreeMaker

# Godot MCP のセットアップ
cd godot-mcp
npm install
npm run build
cd ..
```

### 2. 必須ドキュメントを読む

開発を始める前に、以下を必読：

- [README.md](README.md) - プロジェクト概要
- [document/coding_standards.md](document/coding_standards.md) - コーディング規約
- [.agent/skills/programmer/SKILL.md](.agent/skills/programmer/SKILL.md) - 実装ガイドライン

### 3. 開発環境の確認

**必要要件**:
- Godot Engine 4.5.1 以上
- Node.js 22.14.0 以上
- Git

**推奨ツール**:
- Cursor IDE (または VS Code)
- gdlint (コードリンター)
- GUT (Godot Unit Test)

---

## 開発プロセス

### ワークフロー

新機能開発は [`.agent/workflows/feature-development.md`](.agent/workflows/feature-development.md) に従ってください。

**簡易版フロー**:

1. **Issue を確認/作成**
2. **ブランチを作成** (`feature/機能名`)
3. **実装** (コーディング規約に従う)
4. **テスト** (単体・統合テスト)
5. **プルリクエスト** (レビュー依頼)
6. **フィードバック対応**
7. **マージ**

---

## コーディング規約

[`document/coding_standards.md`](document/coding_standards.md) を厳守してください。

### 重要ポイント

```gdscript
## ✅ すべての関数にコメント必須
##
## @param path: ファイルパス
## @return ロードされたデータ
func load_data(path: String) -> Dictionary:
    # ✅ 型アノテーション必須
    var result: Dictionary = {}
    
    # ✅ エラーハンドリング必須
    if path.is_empty():
        push_error("[ClassName] Path is empty")
        return {}
    
    return result
```

### 命名規則

| 要素 | スタイル | 例 |
|------|---------|-----|
| クラス | PascalCase | `SkillTreeModel` |
| ファイル | snake_case | `skill_tree_model.gd` |
| 関数 | snake_case | `load_pack()` |
| プライベート | _snake_case | `_internal_cache` |
| 定数 | SCREAMING_SNAKE_CASE | `MAX_NODES` |

---

## コミット規約

### コミットメッセージ形式

```
[type] 簡潔な説明（50文字以内）

詳細説明（任意、72文字で改行）

Refs: #Issue番号
```

### Type 一覧

- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `docs`: ドキュメント
- `test`: テスト追加・修正
- `style`: コードフォーマット
- `chore`: ビルド・設定変更

### 例

```bash
git commit -m "feat: PackRepository にバリデーション機能を追加

null チェックと循環参照検出を実装。
ValidationReport で結果を返す。

Refs: #42"
```

---

## プルリクエスト

### PR 作成前チェックリスト

- [ ] コーディング規約に準拠
- [ ] すべての関数にコメント
- [ ] 型アノテーション完備
- [ ] エラーハンドリング実装
- [ ] セルフレビュー完了
- [ ] テスト作成・実行
- [ ] ドキュメント更新

### PR テンプレート

```markdown
## 変更内容
[何を変更したか]

## 動機・背景
[なぜこの変更が必要か]

## テスト方法
[どのようにテストしたか]

## スクリーンショット（該当する場合）
[画像]

## チェックリスト
- [ ] コーディング規約に準拠
- [ ] すべての関数にコメント
- [ ] 動作確認完了
- [ ] テストコード追加
- [ ] ドキュメント更新

Refs: #Issue番号
```

### レビュープロセス

1. **レビュアー割り当て**
2. **レビュー実施** ([`.agent/skills/code_reviewer/SKILL.md`](.agent/skills/code_reviewer/SKILL.md) に従う)
3. **フィードバック対応**
4. **承認後マージ**

---

## 貢献の種類

### コード貢献

- 新機能実装
- バグ修正
- パフォーマンス改善
- リファクタリング

### ドキュメント貢献

- README 改善
- API ドキュメント追加
- チュートリアル作成
- 翻訳

### テスト貢献

- 単体テスト追加
- 統合テスト追加
- バグレポート

### デザイン貢献

- UI/UX 改善提案
- アセット作成
- テーマ作成

詳細: [`.agent/skills/designer/SKILL.md`](.agent/skills/designer/SKILL.md)

---

## 質問とサポート

### 質問する前に

1. [README.md](README.md) を確認
2. [document/](document/) の関連ドキュメントを確認
3. 既存の Issue を検索

### 質問方法

**Issue を作成**:

```markdown
## 質問
[具体的な質問]

## 試したこと
- [調べたドキュメント]
- [試したコード]

## 環境
- Godot バージョン: 4.5.1
- OS: Windows 11
```

### サポートチャンネル

- **GitHub Issues**: バグレポート・機能提案
- **Discussions**: 一般的な質問・議論

---

## ライセンス

このプロジェクトへの貢献は、プロジェクトのライセンスと同じライセンスの下で公開されます。

詳細: [LICENSE](LICENSE)

---

## 感謝

SkillTreeMaker プロジェクトへの貢献に感謝します！

すべてのコントリビューターは、プロジェクトの成功に不可欠です。

---

**Happy Contributing! 🎉**
