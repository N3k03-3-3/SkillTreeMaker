# SkillTreeMaker API Reference

ゲームランタイムで使用するクラスの API リファレンスです。

---

## 目次

- [PackLoader](#packloader)
- [SkillTreeState](#skilltreestate)
- [SkillTreeViewer](#skilltreeviewer)
- [NodeAnimationState](#nodeanimationstate)
- [RuntimeExporter](#runtimeexporter)

---

## PackLoader

`extends RefCounted`

ゲームランタイム用の Pack ローダー。`runtime.json` と `theme.json` を読み込み、スキルツリー表示に必要なデータ一式を返す。

### 定数

| 定数名 | 型 | 値 | 説明 |
|--------|----|----|------|
| `RUNTIME_FILE` | `String` | `"runtime.json"` | ランタイムデータのファイル名 |
| `SUPPORTED_SCHEMA_VERSION` | `int` | `1` | サポートするスキーマバージョン |

### メソッド

#### `load_pack(pack_root: String) -> Dictionary`

runtime.json とテーマを一括で読み込む。

- **引数**: `pack_root` - Pack ルートディレクトリのパス（例: `"res://SkillTreePacks/warrior"`）
- **戻り値**: `{"runtime": Dictionary, "theme": Dictionary}`。失敗時は空の Dictionary
- **備考**: 内部で `ThemeResolver` を生成してテーマを解決する

#### `load_runtime(pack_root: String) -> Dictionary`

runtime.json のみを読み込んでパースする。

- **引数**: `pack_root` - Pack ルートディレクトリのパス
- **戻り値**: runtime.json の Dictionary。失敗時は空の Dictionary
- **備考**: スキーマバージョンが `SUPPORTED_SCHEMA_VERSION` と一致しない場合はエラー

#### `get_theme_resolver() -> ThemeResolver`

内部の ThemeResolver インスタンスを取得する。

- **戻り値**: `ThemeResolver`。`load_pack()` 未実行なら `null`

#### `resolve_asset(relative_path: String) -> String`

アセットの相対パスを絶対パスに解決する。

- **引数**: `relative_path` - テーマからの相対パス
- **戻り値**: 解決された絶対パス。ThemeResolver 未初期化なら空文字列

---

## SkillTreeState

`extends RefCounted`

ゲームランタイムでのスキルツリー状態管理。ノードのアンロック状態を管理し、requires チェックと状態遷移ロジックを提供する。

**重要**: コスト消費はゲーム側の責務であり、本クラスでは行わない。

### シグナル

| シグナル | 引数 | 説明 |
|---------|------|------|
| `node_state_changed` | `node_id: String, new_state: int` | ノードの状態が変化したとき |
| `state_reset` | なし | 全状態がリセットされたとき |

### 列挙型

#### `NodeState`

| 値 | 説明 |
|----|------|
| `LOCKED` | 前提未達成でアンロック不可 |
| `CAN_UNLOCK` | 前提達成済み、コストを払えばアンロック可 |
| `UNLOCKED` | アンロック済み |

### 定数

| 定数名 | 型 | 値 | 説明 |
|--------|----|----|------|
| `SAVE_VERSION` | `int` | `1` | セーブデータのバージョン |
| `SAVE_KEY_VERSION` | `String` | `"version"` | セーブデータのバージョンキー |
| `SAVE_KEY_UNLOCKED` | `String` | `"unlocked"` | セーブデータのアンロック済みノードキー |

### メソッド

#### `initialize(runtime_data: Dictionary) -> void`

runtime データからステートを初期化する。すべてのノードを LOCKED にし、entry_node と requires が空のノードを CAN_UNLOCK にする。

- **引数**: `runtime_data` - runtime.json の Dictionary

#### `get_node_state(node_id: String) -> NodeState`

指定ノードの現在の状態を取得する。

- **引数**: `node_id` - ノード ID
- **戻り値**: `NodeState` 値。存在しないノードは `LOCKED`

#### `can_unlock(node_id: String) -> bool`

指定ノードがアンロック可能か判定する。

- **引数**: `node_id` - ノード ID
- **戻り値**: 状態が `CAN_UNLOCK` なら `true`

#### `get_unlock_cost(node_id: String) -> Dictionary`

指定ノードのアンロックコスト情報を取得する。

- **引数**: `node_id` - ノード ID
- **戻り値**: `{"type": String, "value": int}`。取得できない場合は空 Dictionary

#### `unlock_node(node_id: String) -> bool`

指定ノードをアンロックする。前提条件チェック（requires）は行うが、コスト消費はゲーム側の責務。

- **引数**: `node_id` - ノード ID
- **戻り値**: アンロック成功なら `true`
- **備考**: 成功時に `node_state_changed` シグナルを発火し、後続ノードの CAN_UNLOCK を更新

#### `get_unlocked_nodes() -> Array[String]`

アンロック済みノード ID の配列を取得する。

- **戻り値**: `UNLOCKED` 状態のノード ID 配列

#### `get_all_states() -> Dictionary`

全ノード ID と状態のペアを取得する。

- **戻り値**: `{node_id: NodeState}` の Dictionary

#### `serialize() -> Dictionary`

現在の状態をセーブ用 Dictionary にシリアライズする。

- **戻り値**: `{"version": 1, "unlocked": ["node_id_1", ...]}`

#### `deserialize(save_data: Dictionary, runtime_data: Dictionary) -> void`

セーブデータから状態を復元する。

- **引数**:
  - `save_data` - `serialize()` で生成された Dictionary
  - `runtime_data` - runtime.json の Dictionary
- **備考**: 内部で `initialize()` を呼んでから unlocked ノードを復元する

#### `reset() -> void`

全状態を初期状態にリセットする。

- **備考**: `state_reset` シグナルを発火する

---

## SkillTreeViewer

`extends Control`

ゲームランタイム用スキルツリービューア。ノード/エッジ/説明パネルを描画し、パン/ズーム操作とノードの選択・アンロックを提供する。

### シグナル

| シグナル | 引数 | 説明 |
|---------|------|------|
| `node_clicked` | `node_id: String` | ノードがクリックされたとき |
| `node_unlock_requested` | `node_id: String` | ノードのアンロックが要求されたとき（ダブルクリック） |
| `node_hovered` | `node_id: String` | ノード上にマウスホバーしたとき |
| `node_hover_exited` | なし | ノードからマウスが離れたとき |

### 主要定数

| 定数名 | 型 | 値 | 説明 |
|--------|----|----|------|
| `DEFAULT_NODE_SIZE` | `Vector2` | `(64, 64)` | ノードのデフォルト描画サイズ |
| `ZOOM_STEP` | `float` | `0.1` | ズームステップ |
| `ZOOM_MIN` | `float` | `0.3` | 最小ズーム |
| `ZOOM_MAX` | `float` | `3.0` | 最大ズーム |
| `INFO_PANEL_WIDTH` | `float` | `250.0` | 説明パネル幅 |

色定数（`COLOR_LOCKED`, `COLOR_CAN_UNLOCK`, `COLOR_UNLOCKED` など）やフォントサイズ定数も多数定義されている。詳細はソースコード参照。

### メソッド

#### `load_pack(pack_root: String) -> bool`

Pack をファイルから読み込んでビューアを初期化する。

- **引数**: `pack_root` - Pack ルートディレクトリのパス
- **戻り値**: 読み込み成功なら `true`
- **備考**: 内部で `PackLoader` と `SkillTreeState` を生成・初期化する

#### `load_pack_from_data(runtime_data: Dictionary, theme_data: Dictionary) -> bool`

Pack をメモリ内データから読み込んでビューアを初期化する（プレビュー用）。

- **引数**:
  - `runtime_data` - runtime.json 互換の Dictionary
  - `theme_data` - theme.json 互換の Dictionary
- **戻り値**: 初期化成功なら `true`
- **備考**: `PackLoader` を経由せず Dictionary を直接受け取る

#### `load_save_data(save_data: Dictionary) -> void`

既存のセーブデータから状態を復元する。

- **引数**: `save_data` - `SkillTreeState.serialize()` で生成された Dictionary
- **前提**: `load_pack()` または `load_pack_from_data()` で初期化済みであること

#### `get_save_data() -> Dictionary`

現在の状態をセーブ用にシリアライズする。

- **戻り値**: セーブデータ Dictionary。State 未初期化なら空 Dictionary

#### `get_state() -> SkillTreeState`

内部の SkillTreeState への直接参照を取得する。

- **戻り値**: `SkillTreeState` インスタンス。未初期化なら `null`

#### `focus_node(node_id: String) -> void`

指定ノードにカメラをフォーカスする。

- **引数**: `node_id` - フォーカスするノード ID

#### `reset_camera() -> void`

カメラをリセットする（位置を原点、ズームを 1.0 に戻す）。

### 操作

| 操作 | 動作 |
|------|------|
| 左クリック | ノード選択（説明パネル表示） |
| ダブルクリック | アンロック要求（CAN_UNLOCK 時） |
| 中ボタンドラッグ | パン（視点移動） |
| マウスホイール | ズームイン/アウト |

### アニメーション

SkillTreeViewer は内部で `NodeAnimationState` を使い、以下のアニメーションを自動的に再生する:

- **アンロックアニメーション**: スケール膨張→収縮（0.4秒） + 白フラッシュ
- **ホバーエフェクト**: lerp による 1.08x スケール遷移
- **CAN_UNLOCK パルス**: sin 波で枠 alpha を変調（1.5秒周期）
- **エッジ色遷移**: locked→active の色アニメーション（0.3秒）

アニメーション中のみ `_process()` が有効になり、アイドル時は `set_process(false)` でパフォーマンスを最適化している。

---

## NodeAnimationState

`extends RefCounted`

単一ノードのアニメーション状態を保持する。`_process()` で毎フレーム更新され、`_draw()` で参照される。

### 定数

| 定数名 | 型 | 値 | 説明 |
|--------|----|----|------|
| `UNLOCK_DURATION` | `float` | `0.4` | アンロックアニメーション時間（秒） |
| `UNLOCK_SCALE_PEAK` | `float` | `1.3` | アンロック時の最大スケール倍率 |
| `HOVER_SCALE_TARGET` | `float` | `1.08` | ホバー時の目標スケール倍率 |
| `HOVER_LERP_SPEED` | `float` | `10.0` | ホバーの補間速度 |
| `PULSE_PERIOD` | `float` | `1.5` | CAN_UNLOCK パルス周期（秒） |
| `PULSE_ALPHA_MIN` | `float` | `0.4` | パルス最小 alpha |
| `PULSE_ALPHA_MAX` | `float` | `1.0` | パルス最大 alpha |
| `EDGE_TRANSITION_DURATION` | `float` | `0.3` | エッジ色遷移時間（秒） |

### プロパティ

| プロパティ | 型 | デフォルト | 説明 |
|-----------|----|---------|----|
| `unlock_progress` | `float` | `-1.0` | アンロック進行度（-1.0=非アクティブ, 0.0~1.0=進行中） |
| `current_scale` | `float` | `1.0` | 現在のスケール倍率 |
| `is_hovered` | `bool` | `false` | ホバー中か |
| `pulse_time` | `float` | `0.0` | パルス用経過時間 |

### メソッド

#### `start_unlock() -> void`

アンロックアニメーションを開始する。

#### `update(delta: float, is_can_unlock: bool) -> bool`

毎フレーム更新する。アンロック・ホバー・パルスの 3 種類のアニメーションを処理。

- **引数**:
  - `delta` - フレーム間隔（秒）
  - `is_can_unlock` - CAN_UNLOCK 状態か
- **戻り値**: 再描画が必要なら `true`

#### `get_pulse_alpha() -> float`

パルス進行度から枠の alpha 値を取得する。

- **戻り値**: `PULSE_ALPHA_MIN` ~ `PULSE_ALPHA_MAX` の値

#### `is_animating(is_can_unlock: bool) -> bool`

アニメーションが進行中かどうかを判定する。

- **引数**: `is_can_unlock` - CAN_UNLOCK 状態か
- **戻り値**: アニメーション中なら `true`

---

## RuntimeExporter

`extends RefCounted`

runtime.json の書き出しとアセットコピーを行うサービス。エディタ側で使用するクラスだが、`build_runtime()` はプレビューモードでも利用される。

### 定数

| 定数名 | 型 | 値 | 説明 |
|--------|----|----|------|
| `RUNTIME_FILE` | `String` | `"runtime.json"` | ランタイムデータのファイル名 |
| `SCHEMA_VERSION` | `int` | `1` | スキーマバージョン |

### メソッド

#### `setup(theme_resolver: ThemeResolver, validator: Validator) -> void`

依存サービスを設定する。

- **引数**:
  - `theme_resolver` - ThemeResolver インスタンス
  - `validator` - Validator インスタンス

#### `build_runtime(model: SkillTreeModel) -> Dictionary`

モデルからランタイムデータを構築する。ディスク I/O なしでインメモリにデータを生成。

- **引数**: `model` - ソース SkillTreeModel
- **戻り値**: runtime.json 形式の Dictionary。失敗時は空の Dictionary
- **備考**: `editor_state` や `draft` は含まない

#### `write_runtime(pack_root: String, model: SkillTreeModel) -> Validator.ValidationReport`

バリデーション → 構築 → JSON 書き出しを一連で行う。

- **引数**:
  - `pack_root` - Pack ルートディレクトリのパス
  - `model` - ソースモデル
- **戻り値**: `ValidationReport`（エラーなしなら `has_errors() == false`）
- **備考**: バリデーションエラーがある場合は書き出しを中止。警告のみなら続行

#### `copy_assets(pack_root: String, model: SkillTreeModel) -> int`

参照アセットを Pack フォルダへコピーする。

- **引数**:
  - `pack_root` - Pack ルートディレクトリのパス
  - `model` - アセット参照を持つモデル
- **戻り値**: コピーされたファイル数

---

## データフォーマット

### runtime.json

```json
{
  "schema_version": 1,
  "tree": {
    "id": "warrior",
    "display_name_key": "Warrior",
    "description_key": "A melee combat skill tree.",
    "theme_ref": "theme/theme.json",
    "entry_node_id": "n_power_strike",
    "layout": {
      "coordinate_space": "group_local",
      "groups": [
        {"id": "offense", "center": {"x": 0.0, "y": 0.0}},
        {"id": "defense", "center": {"x": 300.0, "y": 0.0}}
      ]
    }
  },
  "nodes": [
    {
      "id": "n_power_strike",
      "group_id": "offense",
      "pos": {"x": 0.0, "y": 0.0},
      "name_key": "Power Strike",
      "desc_key": "A powerful melee attack.",
      "icon_path": "",
      "style": {"preset": "node_default", "overrides": {}},
      "unlock": {"cost": {"type": "sp", "value": 1}, "requires": []},
      "payload": {"effect_id": "power_strike", "damage_multiplier": 1.5}
    }
  ],
  "edges": [
    {"from": "n_power_strike", "to": "n_whirlwind", "style_preset": "edge_default"}
  ]
}
```

### セーブデータ

`SkillTreeState.serialize()` が返すフォーマット:

```json
{
  "version": 1,
  "unlocked": ["n_power_strike", "n_whirlwind"]
}
```

### theme.json

```json
{
  "schema_version": 1,
  "background": {
    "texture": "",
    "tint": "#1A1A22",
    "parallax": {"enabled": false}
  },
  "window": {
    "frame_9slice": "",
    "padding": {"l": 24, "t": 24, "r": 24, "b": 24}
  },
  "node_presets": {
    "node_default": {
      "base_texture": "",
      "size": 64,
      "states": {
        "locked": {"overlay": "", "glow": false, "glow_color": ""},
        "can_unlock": {"overlay": "", "glow": true, "glow_color": "#6699DD"},
        "unlocked": {"overlay": "", "glow": true, "glow_color": "#66CC77"}
      }
    }
  },
  "edge_presets": {
    "edge_default": {
      "width": 3,
      "color_locked": "#334455",
      "color_active": "#6699DD"
    }
  },
  "effects": {},
  "fonts": {}
}
```
