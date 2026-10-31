# 原产物无限制全修改 / Unconditionally Change RGO

EU5（Europa Universalis V）模组：在局势面板里随时修改本国任意地点的**原材料**，免费或按市场实时价格收费，可选冷却与制成品开关。

- 74 种货物，按 **7 个分类**分组：矿物 / 采集 / 经济作物 / 食物 / 种植园 / 狩猎林业 / 制成品
- **11 种官方语言**：English、Português (Brasil)、Français、Deutsch、Español、Polski、Русский、Türkçe、日本語、한국어、简体中文
- 货物清单与译名**直接取自原版** `common/goods` 与 `goods_l_<lang>.yml`，不会出现与原版不一致的术语

## 功能

| 内容 | 说明 |
|---|---|
| 7 个分类按钮 | 点一次 → 选原材料 → 选地点，仅限本国地点 |
| 花费开关 | 开启时按所选货物在该地点市场的实时价格分六档收费：5 / 10 / 16 / 24 / 34 / 50 金；关闭则完全免费 |
| 冷却开关 | 开启时每次修改挂 6 个月冷却；关闭会**立即清除**正在运行的冷却 |
| 制成品开关 | 默认关闭。制成品由建筑产出，作为原材料属非原生玩法，可能影响建筑产出 |

面板上方是「分类」分组、下方是「开关」分组，共 10 个按钮，单卡无滚动。

## 安装

1. 订阅工坊，或把整个文件夹放到
   `…/Documents/Paradox Interactive/Europa Universalis V/mod/UnconditionallyChangeRGO`
2. 同目录放 `UnconditionallyChangeRGO.mod`（仓库内 `descriptor.mod` 即模板）
3. 启动器播放集里勾选本模组

## 配置（改默认值）

所有数值只有一个真值源：**`tools/rgo_common.ps1`**

| 常量 | 作用 |
|---|---|
| `$RGO_BASE_PRICE` | 基础价（与 `common/prices/00_rgo_prices.txt` 的 `gold` 对应） |
| `$RGO_PRICE_TIERS` | 六档市场价阈值与系数 |
| `$RGO_COOLDOWN_MONTHS` | 冷却月数 |
| `$RGO_DEFAULT_COST` / `$RGO_DEFAULT_COOLDOWN` | 花费 / 冷却的默认开关 |
| `$RGO_DEFAULT_CATEGORIES` | 七个分类默认是否显示 |
| `$RGO_EXCLUDED_GOODS` | 排除的货物（默认排除奴隶，它不是制成品） |

改完后重跑两个生成器即可同步**脚本、价格阶梯、GUI 切片数字和 11 种语言的文案**：

```powershell
powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1"
powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_localization.ps1"
```

只校验生成物是否过期（适合提交前 / CI）：

```powershell
powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1" -Check
powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_localization.ps1" -Check
```

游戏不在默认 Steam 路径时：

```powershell
powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1" -GoodsRoot "D:\...\game\in_game\common\goods"
# 或设置环境变量 EU5_GOODS_ROOT
```

## 自动生成的文件（请勿手改）

| 文件 | 生成器 |
|---|---|
| `in_game/common/generic_actions/00_rgo_actions.txt` | `generate_rgo_actions.ps1` |
| `in_game/common/generic_actions/01_rgo_toggles.txt` | `generate_rgo_actions.ps1` |
| `in_game/common/scripted_triggers/00_rgo_config.txt` | `generate_rgo_actions.ps1` |
| `in_game/gui/panels/situation/UnconditionallyChangeRGO.gui` 中的两个切片数字 | `generate_rgo_actions.ps1` |
| `in_game/localization/<lang>/UnconditionallyChangeRGO_l_<lang>.yml` | `generate_rgo_localization.ps1` |

手写文件（`00_rgo_effects.txt`、`00_rgo_prices.txt`、局势、提示、GUI 模板）不受生成器覆盖，但生成器会校验其中与 `rgo_common.ps1` 重复的常量（冷却月数、基础价），不一致会直接报错。

## 校验与维护脚本

| 脚本 | 作用 |
|---|---|
| `tools/validate_mod.ps1` | 全量校验：生成物是否最新、11 种语言键集合是否一致、脚本引用的键是否都有本地化、括号是否平衡、UTF-8 BOM 是否齐全、动作/开关/GUI 切片数量是否正确 |
| `tools/ensure_utf8_bom.ps1` | 给 `.ps1` / `.txt` / `.gui` / `.yml` 补 UTF-8 BOM（Windows PowerShell 5.1 无 BOM 时会按 ANSI 解析导致中文乱码） |
| `tools/toggle_mod.ps1` | 一键停用 / 恢复本模组，用于 A/B 隔离排错 |

提交前推荐：

```powershell
powershell -ExecutionPolicy Bypass -File "tools\validate_mod.ps1"
```

## 兼容性说明

- 只影响本国地点，不改地点归属、不改建筑产出公式。
- 「制成品」分类是原版 `produced` 分类去掉奴隶；把建筑产出设为原材料属非原生玩法，默认关闭。
- 分类数量变化时 GUI 切片数字会自动同步，不再需要手改界面文件。

## 版本

见 [CHANGELOG.md](CHANGELOG.md)。当前 **1.0.4**。

## License

MIT，见 [LICENSE](LICENSE)。
