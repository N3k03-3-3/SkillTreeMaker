# SkillTreeMaker

Godot Engine 用の汎用スキルツリーGUIメーカー

## 📋 プロジェクト概要

**SkillTreeMaker** は、Godot Engine の EditorPlugin として実装される、ゲーム開発者向けのスキルツリー作成・管理ツールです。複数のゲームプロジェクトで転用可能な設計により、効率的なスキルツリー制作を実現します。

### 主要機能

- 🎨 **ビジュアルエディタ**: ノードベースのGUIでスキルツリーを直感的に作成
- 📦 **パックシステム**: 独立したパック形式でスキルツリーを管理・転用
- 🎭 **テーマシステム**: 完全カスタマイズ可能な見た目とスタイル
- ✅ **バリデーション**: 循環参照や構造エラーの自動検証
- 🎮 **ランタイムサポート**: ゲーム内での読み込み・表示機能

---

## 🏗️ システムアーキテクチャ

### 設計思想

> **ツールとゲームの責務分離**

- **ツール側**: 編集・検証・書き出し（パック化）
- **ゲーム側**: 読み込み・描画・操作・取得判定
- **接続点**: SkillTree Pack（共通データフォーマット）

### SkillTree Pack 構造

```
<PackRoot>/
├── pack.json              # 編集・管理用
├── runtime.json           # ゲーム実行用
├── theme/
│   ├── theme.json        # テーマ定義
│   ├── textures/         # テクスチャ素材
│   ├── ninepatch/        # 9スライス素材
│   ├── fonts/            # フォント
│   └── vfx/              # エフェクト
├── icons/                # ノード用アイコン
└── locale/               # 多言語辞書
```

---

## 🚀 開発環境セットアップ

### 必要要件

- **Godot Engine**: 4.5.1 以上
- **Node.js**: 22.14.0 以上（Godot MCP 使用時）
- **Git**: バージョン管理用

### Godot MCP 統合

このプロジェクトは **Godot MCP（Model Context Protocol）** を統合しており、AI アシスタントから直接 Godot プロジェクトを操作できます。

#### セットアップ済み内容

✅ godot-mcp サーバーインストール済み  
✅ `.cursor/mcp.json` 設定完了  
✅ Godot 4.5.1 パス設定済み

詳細は [Godot MCP セットアップガイド](document/godot_mcp_setup.md) を参照してください。

---

## 📖 ドキュメント

### 仕様書・設計書

| ドキュメント | 説明 |
|-------------|------|
| [0.作成仕様](document/0.作成仕様) | 開発フローとツール設計思想 |
| [1.フォルダ仕様](document/1.フォルダ仕様) | Pack構造とJSONスキーマ |
| [2.Godot EditorPlugin クラス設計](document/2.Godot%20EditorPlugin%20クラス設計) | アーキテクチャとクラス図 |

### セットアップ・運用ガイド

- **Godot MCP セットアップガイド**: `.cursor/mcp.json` の設定と使い方

### 開発ガイドライン

| ドキュメント | 説明 | 対象 |
|-------------|------|------|
| [コーディング規約](document/coding_standards.md) | GDScript コーディング標準 | 全員必読 |
| [Programmer Guardrails](.agent/skills/programmer/SKILL.md) | 実装時の必須チェックリスト | プログラマー |
| [Code Reviewer Guardrails](.agent/skills/code_reviewer/SKILL.md) | レビュー基準とフロー | レビュアー |
| [Designer Guardrails](.agent/skills/designer/SKILL.md) | アセット管理とデザイン仕様 | デザイナー |

---

## 👥 チーム作業ガードレール

### コーディング規約（全員必読）

すべてのコードは [`document/coding_standards.md`](document/coding_standards.md) に従うこと。

**重要ポイント**:
- ✅ **コメント必須**: すべての関数にコメント（機能・引数・戻り値）
- ✅ **型アノテーション必須**: すべての変数・関数に型を明示
- ✅ **命名規則**: snake_case / PascalCase を厳守
- ✅ **エラーハンドリング**: null チェック・早期リターン

### 役割別ガードレール

#### 💻 Programmer
実装前に [`.agent/skills/programmer/SKILL.md`](.agent/skills/programmer/SKILL.md) を必読。

**チェックリスト**:
- [ ] 仕様書確認
- [ ] コメント・型アノテーション完備
- [ ] セルフレビュー実施

#### 👀 Code Reviewer  
レビュー前に [`.agent/skills/code_reviewer/SKILL.md`](.agent/skills/code_reviewer/SKILL.md) を必読。

**レビュー基準**:
- 🔴 MUST FIX: コメント、型、命名規則、エラー処理
- 🟡 SHOULD FIX: 可読性、パフォーマンス
- 🟢 GOOD POINTS: 良い点も必ずフィードバック

#### 🎨 Designer
アセット作成前に [`.agent/skills/designer/SKILL.md`](.agent/skills/designer/SKILL.md) を必読。

**アセット規則**:
- ✅ ファイル名: snake_case
- ✅ フォーマット: PNG (32bit RGBA)
- ✅ 最適化: 1MB 以下



## 🛠️ 実装ワークフロー

### 1. アドイン導入

```
addons/skill_tree_maker/ をプロジェクトへ追加
→ Project Settings で有効化
→ ツールタブが表示されることを確認
```

### 2. パック作成

```
New Pack 
→ pack名入力
→ 出力先指定（res://SkillTreePacks/PackName）
→ テーマテンプレ選択
```

### 3. GUIデザイン

```
キャンバスでノード配置
→ 接続（依存関係）作成
→ プロパティ編集
→ 背景・枠・エフェクト調整
```

### 4. 検証と書き出し

```
Validate（循環参照チェック等）
→ Export（pack.json + runtime.json 生成）
→ ゲーム側での動作確認
```

---

## 🎮 ゲーム内統合

### ランタイムシーン

```gdscript
# イベントからスキルツリーを開く例
EventManager.open_skill_tree("constellation_aries")

# SkillTreePackLoader の使用例
var loader = SkillTreePackLoader.new()
var tree_data = loader.load_pack("res://SkillTreePacks/constellation_aries")
skill_tree_viewer.display(tree_data)
```

---

## 🔧 開発ツール

### Godot MCP を使用した開発

AI アシスタント（Cursor など）から以下の操作が可能：

- Godot エディタの起動
- プロジェクトの実行・停止
- シーンの作成・編集
- デバッグ出力のキャプチャ
- プロジェクト構造の分析

詳細は [Godot MCP セットアップガイド](document/godot_mcp_setup.md) を参照。

---

## 📁 プロジェクト構造

```
SkillTreeMaker/
├── .agent/
│   └── skills/                     # 役割別ガードレール
│       ├── programmer/SKILL.md
│       ├── code_reviewer/SKILL.md
│       └── designer/SKILL.md
├── addons/skill_tree_maker/        # EditorPlugin 本体
│   ├── plugin.cfg                  # プラグイン定義
│   ├── skill_tree_maker_plugin.gd  # プラグインエントリポイント
│   ├── model/                      # データモデル層
│   │   ├── skill_tree_model.gd     # ノード/エッジ/グループ管理
│   │   ├── selection_model.gd      # 選択状態管理
│   │   └── tool_state.gd           # Grid/Snap/ズーム状態
│   ├── services/                   # ビジネスロジック層
│   │   ├── pack_repository.gd      # Pack 永続化
│   │   ├── theme_resolver.gd       # テーマ解決・保存
│   │   ├── validator.gd            # 構造バリデーション
│   │   └── runtime_exporter.gd     # runtime.json 生成
│   └── ui/                         # UI 層
│       ├── skill_tree_maker_dock.gd # メインコーディネータ
│       ├── canvas_view.gd          # キャンバス描画
│       ├── hierarchy_panel.gd      # 階層ツリー
│       ├── inspector_panel.gd      # プロパティ編集
│       ├── canvas_context_menu.gd  # 右クリックメニュー
│       ├── pack_creation_dialog.gd # Pack 作成ダイアログ
│       └── group_name_dialog.gd    # グループ名入力ダイアログ
├── document/                       # 仕様書・設計書
│   ├── 0.作成仕様
│   ├── 1.フォルダ仕様
│   ├── 2.Godot EditorPlugin クラス設計
│   └── coding_standards.md
├── godot-mcp/                      # MCP サーバー
├── .gitignore
└── README.md
```


---

## 🎯 ロードマップ

### Phase 1: 基盤構築 ✅
- [x] 仕様策定
- [x] Godot MCP 導入
- [x] コーディング規約策定
- [x] チーム作業ガードレール策定
- [x] EditorPlugin 基本実装（plugin.cfg, SkillTreeMakerPlugin）
- [x] PackRepository 実装（Pack の作成・保存・読み込み）
- [x] CanvasView 実装（ノード/エッジ描画・ドラッグ移動）

### Phase 2: コア機能 ✅
- [x] SkillTreeModel（ノード/エッジ/グループの CRUD）
- [x] SelectionModel（選択状態管理）
- [x] ToolState（Grid/Snap/ズーム状態管理）
- [x] ThemeResolver（テーマ読み込み・解決）
- [x] Validator（循環参照チェック等）
- [x] RuntimeExporter（runtime.json 生成）

### Phase 3: エディタ UI ✅
- [x] HierarchyPanel（ツリー構造の階層表示）
- [x] InspectorPanel（ノード/エッジ/グループ/ツリーのプロパティ編集）
- [x] CanvasContextMenu（右クリックメニュー）
- [x] PackCreationDialog（Pack 作成ダイアログ）
- [x] キーボードショートカット（Delete, Ctrl+S, Ctrl+Z 等）
- [x] SkillTreeMakerDock（全パネル統合・コーディネータ）

### Phase 4: ユーザビリティ・管理機能 ✅
- [x] Open Pack（既存 Pack の再開封）
- [x] Grid/Snap ツールバーコントロール
- [x] グループ管理（追加・削除・ノード移動）
- [x] テーマプロパティ編集・保存

### Phase 5: 拡張機能（未着手）
- [ ] SkillTreeViewer ランタイム実装
- [ ] PackLoader 実装
- [ ] アニメーションシステム
- [ ] プレビューモード
- [ ] サンプルパック作成
- [ ] ドキュメント整備

---

## 🤝 貢献

このプロジェクトは現在、個人開発プロジェクトです。

---

## 📝 ライセンス

このプロジェクトは [MIT License](LICENSE) の下でライセンスされています。

詳細は [LICENSE](LICENSE) ファイルをご覧ください。

---

## 📚 参考リソース

- [Godot Engine Documentation](https://docs.godotengine.org/)
- [Godot MCP GitHub](https://github.com/bradypp/godot-mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)

---

**Author**: nekosan
**Last Updated**: 2026-02-18
