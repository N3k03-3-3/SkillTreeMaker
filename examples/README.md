# Sample Packs

SkillTreeMaker のサンプルパックです。

## warrior_pack

RPG 戦士クラスのスキルツリーサンプル。

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

### ノード一覧 (8個)

| ID | 名前 | コスト | 前提条件 |
|----|------|--------|---------|
| n_power_strike | Power Strike | 1 SP | - |
| n_whirlwind | Whirlwind | 2 SP | Power Strike |
| n_charge | Charge | 2 SP | Power Strike |
| n_execute | Execute | 3 SP | Whirlwind |
| n_berserker | Berserker Rage | 5 SP | Execute + Charge |
| n_shield_block | Shield Block | 1 SP | - |
| n_fortify | Fortify | 2 SP | Shield Block |
| n_iron_will | Iron Will | 3 SP | Fortify |

### 使い方

#### エディタで開く
1. SkillTreeMaker Dock の "Open Pack" をクリック
2. `examples/warrior_pack` フォルダを選択

#### ランタイムで使う
```gdscript
var viewer: SkillTreeViewer = SkillTreeViewer.new()
add_child(viewer)
viewer.load_pack("res://examples/warrior_pack")
```
