# Changelog

All notable changes to SkillTreeMaker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Phase 1: 基盤構築
- 仕様策定
- Godot MCP 導入
- コーディング規約策定
- チーム作業ガードレール策定

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

[Unreleased]: https://github.com/yourusername/SkillTreeMaker/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/SkillTreeMaker/releases/tag/v0.1.0
