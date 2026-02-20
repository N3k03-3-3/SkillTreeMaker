# SkillTreeMaker 使い方ガイド

ゲームプロジェクトに SkillTreeMaker のスキルツリーを組み込む方法を解説します。

---

## 目次

1. [クイックスタート](#クイックスタート)
2. [エディタでパックを作成する](#エディタでパックを作成する)
3. [ゲーム内で表示する](#ゲーム内で表示する)
4. [アンロック処理を実装する](#アンロック処理を実装する)
5. [セーブ/ロード](#セーブロード)
6. [シグナルで連携する](#シグナルで連携する)
7. [カスタマイズ](#カスタマイズ)
8. [プレビューモード](#プレビューモード)
9. [サンプルパック](#サンプルパック)

---

## クイックスタート

### 1. プラグインを導入する

`addons/skill_tree_maker/` フォルダをプロジェクトにコピーし、**Project > Project Settings > Plugins** で有効化します。

### 2. パックを作成する

エディタ下部の **SkillTreeMaker** タブからパックを作成し、ノードとエッジを配置します。

### 3. ゲームで表示する

```gdscript
var viewer: SkillTreeViewer = SkillTreeViewer.new()
add_child(viewer)
viewer.size = get_viewport_rect().size
viewer.load_pack("res://SkillTreePacks/my_pack")
```

これだけでスキルツリーが表示され、パン/ズーム/ノード選択が動作します。

---

## エディタでパックを作成する

### パックの新規作成

1. エディタ下部の **SkillTreeMaker** タブを開く
2. **New Pack** ボタンをクリック
3. Pack ID、表示名、出力先ディレクトリを入力
4. **Create** をクリック

### ノードの追加と編集

1. キャンバス上で**右クリック** → **Add Node**
2. 左サイドの **Inspector** でプロパティを編集:
   - `name_key`: 表示名
   - `desc_key`: 説明文
   - `icon_path`: アイコンパス
   - `cost`: アンロックコスト（type と value）
   - `requires`: 前提ノード ID の配列
   - `payload`: ゲーム側で使う任意データ

### エッジ（接続）の作成

1. キャンバスで始点ノードを**右クリック** → **Connect**
2. 終点ノードをクリック

### グループの管理

- ノードをグループにまとめることで、レイアウトを整理できます
- **Hierarchy** パネルでグループの作成・ノードの移動が可能

### 保存とエクスポート

- **Ctrl+S** または **Save** ボタン: `pack.json` を保存（エディタ用）
- **Validate** ボタン: 循環参照・孤立ノード等のチェック
- **Export** ボタン: `runtime.json` を生成（ゲーム用）

---

## ゲーム内で表示する

### 基本的な組み込み

```gdscript
extends Control

var _viewer: SkillTreeViewer

func _ready() -> void:
    _viewer = SkillTreeViewer.new()
    _viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_viewer)

    # パックを読み込み
    var success: bool = _viewer.load_pack("res://SkillTreePacks/warrior")
    if not success:
        push_error("Failed to load skill tree pack")
```

### PackLoader を直接使う

SkillTreeViewer を使わず、データだけ取得する場合:

```gdscript
var loader: PackLoader = PackLoader.new()
var pack_data: Dictionary = loader.load_pack("res://SkillTreePacks/warrior")

var runtime_data: Dictionary = pack_data.get("runtime", {})
var theme_data: Dictionary = pack_data.get("theme", {})

# 独自の描画ロジックで使う
var nodes: Array = runtime_data.get("nodes", [])
for node: Dictionary in nodes:
    print(node.get("name_key", ""))
```

### 操作方法

SkillTreeViewer は以下の操作をデフォルトで提供します:

| 操作 | 動作 |
|------|------|
| **左クリック** | ノード選択（右側に説明パネル表示） |
| **ダブルクリック** | CAN_UNLOCK ノードのアンロック要求 |
| **中ボタンドラッグ** | パン（視点移動） |
| **マウスホイール** | ズームイン/アウト（0.3x ~ 3.0x） |

---

## アンロック処理を実装する

SkillTreeViewer のデフォルト動作では、ダブルクリックで即座にアンロックされます。ゲーム側でコスト消費などの追加ロジックを挟む場合は、シグナルを使います。

### コスト消費付きアンロック

```gdscript
extends Control

var _viewer: SkillTreeViewer
var _skill_points: int = 10

func _ready() -> void:
    _viewer = SkillTreeViewer.new()
    add_child(_viewer)
    _viewer.load_pack("res://SkillTreePacks/warrior")

    # デフォルトのダブルクリックアンロックを使う場合は
    # node_unlock_requested シグナルで追加処理を行う
    _viewer.node_unlock_requested.connect(_on_unlock_requested)

func _on_unlock_requested(node_id: String) -> void:
    var state: SkillTreeState = _viewer.get_state()
    if state == null:
        return

    # コスト取得
    var cost: Dictionary = state.get_unlock_cost(node_id)
    var cost_value: int = cost.get("value", 0)

    # コストチェック
    if _skill_points < cost_value:
        print("Not enough skill points!")
        return

    # コスト消費
    _skill_points -= cost_value
    print("Remaining SP: ", _skill_points)
```

### SkillTreeState を直接操作する

SkillTreeViewer を使わない場合:

```gdscript
var state: SkillTreeState = SkillTreeState.new()
state.initialize(runtime_data)

# 状態変化を監視
state.node_state_changed.connect(_on_state_changed)

# アンロック可能か確認
if state.can_unlock("n_power_strike"):
    var cost: Dictionary = state.get_unlock_cost("n_power_strike")
    # ゲーム側でコスト消費処理...
    state.unlock_node("n_power_strike")

func _on_state_changed(node_id: String, new_state: int) -> void:
    match new_state:
        SkillTreeState.NodeState.CAN_UNLOCK:
            print(node_id, " is now available!")
        SkillTreeState.NodeState.UNLOCKED:
            print(node_id, " unlocked!")
```

---

## セーブ/ロード

### SkillTreeViewer 経由

```gdscript
# セーブ
var save_data: Dictionary = _viewer.get_save_data()
# save_data を JSON でファイルに保存
# {"version": 1, "unlocked": ["n_power_strike", "n_whirlwind"]}

# ロード（パック読み込み済みの状態で）
_viewer.load_save_data(save_data)
```

### SkillTreeState 直接

```gdscript
# セーブ
var save_data: Dictionary = state.serialize()

# ロード
var new_state: SkillTreeState = SkillTreeState.new()
new_state.deserialize(save_data, runtime_data)
```

### セーブデータのフォーマット

```json
{
  "version": 1,
  "unlocked": ["n_power_strike", "n_whirlwind", "n_charge"]
}
```

軽量なフォーマットで、アンロック済みノードの ID リストのみを保存します。`LOCKED` / `CAN_UNLOCK` の状態はロード時に `requires` から自動再計算されます。

---

## シグナルで連携する

### SkillTreeViewer のシグナル

```gdscript
# ノードクリック（選択）
_viewer.node_clicked.connect(func(node_id: String) -> void:
    print("Selected: ", node_id)
)

# アンロック要求（ダブルクリック）
_viewer.node_unlock_requested.connect(func(node_id: String) -> void:
    print("Unlock requested: ", node_id)
)

# ホバー
_viewer.node_hovered.connect(func(node_id: String) -> void:
    # カスタムツールチップなど
    show_tooltip(node_id)
)

_viewer.node_hover_exited.connect(func() -> void:
    hide_tooltip()
)
```

### SkillTreeState のシグナル

```gdscript
var state: SkillTreeState = _viewer.get_state()

# ノード状態変化
state.node_state_changed.connect(func(node_id: String, new_state: int) -> void:
    if new_state == SkillTreeState.NodeState.UNLOCKED:
        # ゲーム内エフェクトの発動、パッシブ効果の適用など
        apply_skill_effect(node_id)
)

# 全状態リセット
state.state_reset.connect(func() -> void:
    print("All skills have been reset")
)
```

---

## カスタマイズ

### テーマでビジュアルを変える

`theme/theme.json` を編集してノードやエッジの見た目をカスタマイズできます。エディタの Inspector からも設定可能です。

```json
{
  "node_presets": {
    "node_default": {
      "size": 80,
      "states": {
        "locked": {"glow": false, "glow_color": ""},
        "can_unlock": {"glow": true, "glow_color": "#FFD700"},
        "unlocked": {"glow": true, "glow_color": "#00FF88"}
      }
    }
  },
  "edge_presets": {
    "edge_default": {
      "width": 4,
      "color_locked": "#333344",
      "color_active": "#FFD700"
    }
  }
}
```

### payload でゲームロジックと連携

各ノードの `payload` フィールドに任意の JSON データを格納できます。ゲーム側でノードごとの効果を実装する際に使用します。

```json
{
  "id": "n_fire_bolt",
  "payload": {
    "effect_id": "fire_bolt",
    "damage": 50,
    "mana_cost": 10,
    "element": "fire"
  }
}
```

```gdscript
# ゲーム側でペイロードを読む
var nodes: Array = runtime_data.get("nodes", [])
for node: Dictionary in nodes:
    var payload: Dictionary = node.get("payload", {})
    var effect_id: String = payload.get("effect_id", "")
    register_skill_effect(effect_id, payload)
```

### カメラ制御

```gdscript
# 特定ノードにフォーカス
_viewer.focus_node("n_berserker")

# カメラをリセット
_viewer.reset_camera()
```

---

## プレビューモード

エディタ上でゲーム内の見た目と操作を確認できるプレビューモードを備えています。

### 使い方

1. パックを開いた状態でツールバーの **Preview** ボタンをクリック
2. キャンバスがランタイムビューア（SkillTreeViewer）に切り替わる
3. CAN_UNLOCK ノードがパルスアニメーション表示
4. ダブルクリックでアンロックをテスト
5. **Edit** ボタンで元の編集画面に戻る

プレビュー中は Save / Validate / Export などの編集系ボタンが自動的に無効化されます。

---

## サンプルパック

`examples/warrior_pack` に RPG 戦士クラスのスキルツリーサンプルが含まれています。

### ツリー構造

```
[Offense Group]                    [Defense Group]
  Power Strike (entry)               Shield Block (entry)
   /         \                           |
Whirlwind   Charge                    Fortify
   |           |                         |
Execute        |                      Iron Will
   \         /
  Berserker Rage
```

### エディタで開く

1. SkillTreeMaker Dock の **Open Pack** をクリック
2. `examples/warrior_pack` フォルダを選択

### ランタイムで使う

```gdscript
var viewer: SkillTreeViewer = SkillTreeViewer.new()
add_child(viewer)
viewer.load_pack("res://examples/warrior_pack")
```

---

## トラブルシューティング

### パックが読み込めない

- `runtime.json` が存在するか確認してください
- エディタで **Export** を実行して `runtime.json` を生成してください
- `schema_version` が `1` であることを確認してください

### ノードが表示されない

- `runtime.json` 内の `nodes` 配列にノードが含まれているか確認してください
- ノードの `pos` フィールドが設定されているか確認してください

### セーブデータのロードが失敗する

- `load_pack()` でパックを先に読み込んでから `load_save_data()` を呼んでください
- セーブデータの `version` フィールドが `1` であることを確認してください

### アンロックできない

- `SkillTreeState.can_unlock()` で `true` が返るか確認してください
- ノードの `requires` に指定された全ノードが UNLOCKED 状態か確認してください
- コスト消費はゲーム側の責務です（SkillTreeState はコストチェックしません）
