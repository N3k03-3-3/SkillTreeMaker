---
name: Designer Guardrails
description: Design guidelines and asset management rules for SkillTreeMaker project
---

# Designer Guardrails for SkillTreeMaker

このスキルは、SkillTreeMaker プロジェクトでデザイン・アセット作成を行う際の**必須ガードレール**を定義します。

---

## 🎯 役割と責務

### デザイナーの責務

1. **UI/UX デザイン**: ツールとゲーム内表示のインターフェース設計
2. **アセット作成**: テクスチャ、アイコン、エフェクト素材の制作
3. **テーマ管理**: 見た目のスタイルとプリセット定義
4. **ドキュメント**: デザインガイドラインと素材仕様書の作成

---

## 📁 アセット管理ルール

### ディレクトリ構造

すべてのデザインアセットは以下の構造に従って配置してください：

```
SkillTreePacks/<PackName>/
├── theme/
│   ├── textures/          # UI テクスチャ
│   ├── ninepatch/         # 9スライス素材
│   ├── fonts/             # フォント
│   └── vfx/               # エフェクト
└── icons/                 # スキルアイコン
```

### 命名規則

#### ファイル名（必須）

すべてのアセットファイルは **snake_case** で命名：

```
✅ 正しい例:
- node_base.png
- window_frame_9slice.png
- skill_fire_slash.png
- bg_space_dark.png

❌ 間違い例:
- NodeBase.png          # PascalCase は不可
- window-frame.png      # ハイフンは不可
- skill火炎斬り.png     # 日本語は不可
- bg space.png          # スペースは不可
```

#### 命名パターン

| アセットタイプ | パターン | 例 |
|--------------|---------|-----|
| **背景** | `bg_<説明>.png` | `bg_space_dark.png` |
| **ノード** | `node_<状態/種類>.png` | `node_locked.png` |
| **ウィンドウ** | `window_<部位>.png` | `window_frame_9slice.png` |
| **アイコン** | `skill_<名前>.png` | `skill_fire_slash.png` |
| **エフェクト** | `vfx_<種類>.png` | `vfx_glow.png` |
| **フォント** | `font_<名前>.tres` | `font_main.tres` |

---

## 🎨 アセット仕様

### テクスチャ仕様（必須）

#### 画像フォーマット

| 用途 | フォーマット | 理由 |
|------|-------------|------|
| **UI要素** | PNG（32bit RGBA） | 透過が必要 |
| **背景** | PNG または WebP | 透過が不要な場合は WebP も可 |
| **アイコン** | PNG（32bit RGBA） | 透過が必須 |
| **エフェクト** | PNG（32bit RGBA） | 加算合成に対応 |

#### 解像度ガイドライン

| 要素 | 推奨サイズ | 備考 |
|------|-----------|------|
| **ノードアイコン** | 64x64 px | 48x48 で表示（余白確保） |
| **スキルアイコン** | 128x128 px | 高解像度対応 |
| **背景** | 1920x1080 px | Full HD 基準 |
| **ウィンドウ枠** | 可変（9スライス） | 最小 64x64 px |
| **エフェクト** | 128x128 px | スケーラブル |

#### 最適化ルール

- ✅ **ファイルサイズ**: 単一ファイル 1MB 以下
- ✅ **圧縮**: PNG を最適化ツールで圧縮（TinyPNG 等）
- ✅ **透過**: 不要な透過チャンネルは削除
- ✅ **解像度**: 必要以上に大きくしない

```bash
# 推奨ツール: pngquant
pngquant --quality=80-95 input.png -o output.png
```

---

## 🖼️ 9スライス（NinePatch）仕様

### 作成ルール

9スライスは Godot の NinePatchRect で使用します。

#### ファイル命名

```
<element>_9slice.png
```

例: `window_frame_9slice.png`, `button_9slice.png`

#### マージン設定

Godot エディタで設定するマージンを `theme.json` に記載：

```json
{
  "window": {
    "frame_9slice": "ninepatch/window_frame_9slice.png",
    "patch_margin": {
      "left": 16,
      "top": 16,
      "right": 16,
      "bottom": 16
    }
  }
}
```

#### チェックリスト

- [ ] 四隅のコーナーが正方形
- [ ] 辺の部分が繰り返し可能
- [ ] 中央部分が透過または繰り返し可能
- [ ] マージン値を `theme.json` に記載

---

## 🎭 テーマシステム

### theme.json の管理

デザイナーは `theme.json` で見た目を定義します。

#### プリセット定義

```json
{
  "schema_version": 1,
  
  "background": {
    "texture": "textures/bg_space.png",
    "tint": "#FFFFFF",
    "parallax": {
      "enabled": false
    }
  },
  
  "node_presets": {
    "node_default": {
      "base_texture": "textures/node_base.png",
      "size": 48,
      "states": {
        "locked": {
          "overlay": "textures/node_locked.png",
          "glow": false,
          "tint": "#888888"
        },
        "can_unlock": {
          "overlay": "textures/node_unlocked.png",
          "glow": true,
          "glow_color": "#88CCFF"
        },
        "unlocked": {
          "overlay": "textures/node_unlocked.png",
          "glow": true,
          "glow_color": "#FFD27D"
        }
      }
    }
  }
}
```

### カラーパレット

プロジェクトで使用する色は統一してください：

```json
{
  "colors": {
    "primary": "#88CCFF",
    "secondary": "#FFD27D",
    "locked": "#888888",
    "error": "#FF6B6B",
    "success": "#51CF66"
  }
}
```

---

## 🌈 デザインガイドライン

### UI/UX 原則

#### 1. 一貫性（Consistency）

- 同じ機能には同じビジュアル
- 色の意味を統一（例: 青=選択可能、灰=ロック）

#### 2. フィードバック（Feedback）

- ホバー時に視覚的変化
- クリック時にアニメーション
- 状態変化を明確に表示

#### 3. 可読性（Readability）

- フォントサイズ最小 14px
- コントラスト比 4.5:1 以上（WCAG AA準拠）
- 背景とテキストの明度差を確保

#### 4. アクセシビリティ（Accessibility）

- 色だけで情報を伝えない（アイコン併用）
- 十分なクリック領域（最小 44x44 px）
- スクリーンリーダー対応（alt テキスト）

---

## 🎬 アニメーション・エフェクト

### エフェクト素材

#### グロー（Glow）

```
ファイル: vfx/glow.png
サイズ: 128x128 px
フォーマット: PNG（32bit RGBA）
ブレンドモード: Add（加算合成）
```

#### パーティクル

```
ファイル: vfx/particle_<種類>.png
サイズ: 64x64 px（1粒子）
フォーマット: PNG（32bit RGBA）
構成: スプライトシート可
```

### アニメーション仕様

| アニメーション | 時間 | イージング |
|--------------|------|----------|
| **ノード出現** | 0.3秒 | Ease Out |
| **ホバー** | 0.15秒 | Linear |
| **アンロック** | 0.5秒 | Ease Out Elastic |
| **選択** | 0.2秒 | Ease Out |

---

## 📝 ドキュメント要件

### デザイン仕様書

新しいテーマやアセットセットを作成した場合、以下を記載したドキュメントを作成してください：

```markdown
# [テーマ名] デザイン仕様

## 概要
- テーマの目的とコンセプト
- 対象ゲームジャンル

## カラーパレット
- Primary: #88CCFF
- Secondary: #FFD27D
- ...

## アセットリスト
| ファイル名 | 用途 | サイズ |
|-----------|------|--------|
| bg_space.png | 背景 | 1920x1080 |
| ...

## 使用フォント
- Main: Noto Sans JP
- ...

## 参考資料
- デザインモックアップ
- カラーパレット画像
```

---

## 🚫 禁止事項

### ❌ やってはいけないこと

#### 1. 無断での著作物使用

- ❌ インターネットから無断転載
- ❌ 他ゲームのアセット流用
- ✅ 自作またはライセンス確認済み素材のみ

#### 2. 不適切なファイル形式

- ❌ JPEG（UI要素に不適）
- ❌ BMP（ファイルサイズ大）
- ❌ GIF（品質低下）
- ✅ PNG（推奨）

#### 3. 命名規則違反

- ❌ 日本語ファイル名
- ❌ スペース含むファイル名
- ❌ 大文字始まりのファイル名
- ✅ snake_case 厳守

#### 4. 過度な高解像度

- ❌ 4K（3840x2160）背景（必要性なし）
- ❌ 512x512 アイコン（オーバースペック）
- ✅ 仕様に従った適切なサイズ

---

## 🔍 品質チェックリスト

アセット納品前に以下を確認してください：

### 必須チェック

- [ ] **ファイル名**: snake_case で命名
- [ ] **フォーマット**: PNG（32bit RGBA）
- [ ] **サイズ**: 仕様に準拠
- [ ] **ファイルサイズ**: 1MB 以下
- [ ] **配置場所**: 正しいディレクトリ
- [ ] **theme.json**: プリセット定義追加（必要な場合）

### 品質チェック

- [ ] **透過**: 不要な透過がない
- [ ] **圧縮**: 最適化済み
- [ ] **エッジ**: アンチエイリアス適切
- [ ] **色**: カラーパレット準拠
- [ ] **一貫性**: 既存アセットと調和

### ドキュメント

- [ ] **デザイン仕様書**: 作成済み（新規テーマの場合）
- [ ] **ライセンス**: 記載済み（外部素材使用時）
- [ ] **使用方法**: README 更新（必要な場合）

---

## 🛠️ 推奨ツール

### グラフィック制作

- **Photoshop** / **GIMP**: テクスチャ制作
- **Aseprite**: ピクセルアート
- **Figma**: UI モックアップ

### 最適化

- **TinyPNG**: PNG 圧縮
- **pngquant**: コマンドライン圧縮
- **ImageOptim** (Mac): 一括最適化

### カラーパレット

- **Coolors.co**: パレット生成
- **Adobe Color**: カラーホイール
- **Contrast Checker**: コントラスト確認

---

## 📐 モックアップ作成

### UI デザインフロー

1. **ワイヤーフレーム**: レイアウト確認
2. **モックアップ**: ビジュアルデザイン
3. **プロトタイプ**: インタラクション確認
4. **実装**: Godot への落とし込み

### デザインツール連携

Figma / Photoshop で作成したデザインは、以下の形式でエクスポート：

```
exports/
├── mockup_skill_tree_editor.png   # 全体モックアップ
├── assets/
│   ├── node_base.png
│   ├── window_frame_9slice.png
│   └── ...
└── specs/
    └── design_spec.md
```

---

## 🎓 学習リソース

### Godot UI デザイン

- [Godot UI System Tutorial](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [NinePatchRect Documentation](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html)

### デザイン理論

- [Material Design Guidelines](https://material.io/design)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### カラー理論

- [Color Theory for Designers](https://www.smashingmagazine.com/category/color-theory/)
- [WCAG Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)

---

## ✅ 納品チェックリスト

アセットを納品する際の最終確認：

- [ ] すべてのファイルが命名規則に準拠
- [ ] ファイルが正しいディレクトリに配置
- [ ] `theme.json` を更新（該当する場合）
- [ ] デザイン仕様書を作成（新規テーマの場合）
- [ ] ライセンス情報を記載（外部素材使用時）
- [ ] 品質チェック完了（解像度、ファイルサイズ、最適化）
- [ ] プログラマーへ使用方法を共有

---

## 📞 コミュニケーション

### プログラマーとの連携

- **実装前**: 仕様の相談・確認
- **実装中**: 進捗共有・調整
- **実装後**: 動作確認・調整

### フィードバック

デザインのフィードバックを受けた際は：

1. **理解**: なぜその指摘があるか理解
2. **検討**: 改善方法を考える
3. **提案**: 代替案があれば提示
4. **実装**: 合意した方向で修正

---

**美しく、一貫性のあるデザインは、ユーザー体験を大きく向上させます。これらのガードレールを守り、高品質なアセットを提供してください。**
