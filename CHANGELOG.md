# Changelog

All notable changes to SkillTreeMaker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.7.0] - 2026-02-20

### Added

#### Phase 6: 拡張機能
- プレビューモード: エディタ内でランタイム描画をテスト（Preview/Edit トグル）
- `SkillTreeViewer.load_pack_from_data()`: メモリ内データからの直接初期化（プレビュー用）
- `_initialize_from_data()` / `_reset_animation_states()`: 初期化ロジックの DRY リファクタ
- サンプルパック `examples/warrior_pack`: RPG 戦士クラス（8ノード・7エッジ・2グループ）
- プレビュー中の編集系ボタン一括無効化

---

## [0.6.0] - 2026-02-20

### Added

#### Phase 5: ランタイム機能
- `PackLoader`: runtime.json + theme.json の一括読み込み（スキーマバージョンチェック付き）
- `SkillTreeState`: ノード状態管理（LOCKED / CAN_UNLOCK / UNLOCKED）、requires チェック、serialize/deserialize
- `SkillTreeViewer`: Control ベースのスキルツリー描画（パン/ズーム、説明パネル、ダブルクリックアンロック）
- `NodeAnimationState`: ノード単位アニメーション値管理
- アンロックアニメーション（スケール膨張→収縮 + 白フラッシュ）
- ホバーエフェクト（lerp スケール遷移）
- CAN_UNLOCK パルス（sin 波で枠 alpha 変調）
- エッジ活性化アニメーション（locked→active 色遷移）
- `set_process(false)` によるアイドル時パフォーマンス最適化

---

## [0.5.0] - 2026-02-18

### Added

#### Phase 1: 基盤構築
- EditorPlugin 基本実装（`plugin.cfg`, `SkillTreeMakerPlugin`）
- `PackRepository`: Pack の作成・保存・読み込み
- `CanvasView`: ノード/エッジ描画、ドラッグ移動、ズーム、パン

#### Phase 2: コア機能
- `SkillTreeModel`: ノード/エッジ/グループの CRUD + シグナル駆動
- `SelectionModel`: 単一/複数選択の状態管理
- `ToolState`: Grid/Snap/ズーム設定管理
- `ThemeResolver`: テーマ JSON の読み込み・解決・保存
- `Validator`: 循環参照・孤立ノード等の構造バリデーション
- `RuntimeExporter`: ゲーム用 `runtime.json` 生成

#### Phase 3: エディタ UI
- `HierarchyPanel`: ツリー構造の階層表示（グループ/ノード/エッジ）
- `InspectorPanel`: ノード/エッジ/グループ/ツリーのプロパティ編集
- `CanvasContextMenu`: 右クリックメニュー（ノード追加/削除/接続等）
- `PackCreationDialog`: Pack 作成ダイアログ（ID/名前/出力先入力）
- `SkillTreeMakerDock`: 全パネル統合コーディネータ
- キーボードショートカット（Delete, Ctrl+S, Ctrl+Z 等）

#### Phase 4: ユーザビリティ・管理機能
- Open Pack ボタン（`EditorFileDialog` による既存 Pack 再開封）
- Grid/Snap ツールバーコントロール（`CheckButton` トグル）
- グループ管理（`GroupNameDialog` + 追加/削除/ノード移動）
- テーマプロパティ編集（背景 tint/texture, window padding, node size）
- テーマ保存（`save_theme()` で `theme.json` 書き出し）

---

## [0.1.0] - 2026-01-25

### Added
- プロジェクト初期セットアップ
- ドキュメント体系の確立
  - プロジェクト仕様書（`document/specification.md`）
  - コーディング規約（`document/coding_standards.md`）
  - 役割別ガードレール（`.agent/skills/`）
    - Programmer Guardrails
    - Code Reviewer Guardrails
    - Designer Guardrails
  - 開発ワークフロー（`.agent/workflows/feature-development.md`）
  - 貢献ガイド（`CONTRIBUTING.md`）
- Godot MCP 統合
  - godot-mcp サーバーインストール
  - `.cursor/mcp.json` 設定
- プロジェクト管理ファイル
  - README.md
  - LICENSE (MIT)
  - .gitignore
  - CHANGELOG.md

### Documentation
- 仕様書: Pack構造、JSON スキーマ、クラス設計
- コーディング規約: 命名規則、コメント規約、型アノテーション
- Skills: 役割別の必須チェックリストと禁止事項
- ワークフロー: 新機能開発プロセス

---

## Template for Future Releases

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- 新機能の追加

### Changed
- 既存機能の変更

### Deprecated
- 非推奨となった機能

### Removed
- 削除された機能

### Fixed
- バグ修正

### Security
- セキュリティ修正
```

---

[Unreleased]: https://github.com/N3k03-3-3/SkillTreeMaker/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/N3k03-3-3/SkillTreeMaker/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/N3k03-3-3/SkillTreeMaker/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/N3k03-3-3/SkillTreeMaker/compare/v0.1.0...v0.5.0
[0.1.0]: https://github.com/N3k03-3-3/SkillTreeMaker/releases/tag/v0.1.0
