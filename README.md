# 原产物无限制全修改 / Unconditionally Change RGO

EU5（Europa Universalis V）模组：在局势面板里随时修改本国任意地点的**原材料**，免费或按市场实时价格收费，可选冷却、制成品与地理条件开关。

- **7 个分类**：矿物 / 采集 / 经济作物 / 食物 / 种植园 / 狩猎林业 / 制成品
- **分类成员在运行时按货物自身属性判定**（`goods_category` / `goods_method` / `is_food`），
  其它模组或游戏更新新增的原材料会自动出现在对应分类里，不需要重建本模组
- **11 种官方语言**：English、Português (Brasil)、Français、Deutsch、Español、Polski、Русский、Türkçe、日本語、한국어、简体中文

## 功能

| 内容 | 说明 |
|---|---|
| 7 个分类按钮 | 点一次 → 选原材料 → 选地点，仅限本国地点。每个分类的货物清单在**运行时**按货物字段筛选（见下方「兼容性说明」），所以模组 / 版本新增的货物也会出现 |
| 花费开关 | 开启时按所选货物在该地点市场的实时价格分六档收费：5 / 10 / 16 / 24 / 34 / 50 金；关闭则完全免费 |
| 冷却开关 | 开启时每次修改挂 6 个月冷却；关闭会**立即清除**正在运行的冷却 |
| 制成品开关 | 默认关闭。制成品由建筑产出，作为原材料属非原生玩法，可能影响建筑产出 |
| 地理条件开关 | 默认关闭。关闭时本国任意地点都能改成任意原材料，不检查原版地理条件（地点列表会包含全部本国地点）；开启后只列出原版允许该货物的地点（气候 / 植被 / 地形 / 区域） |

面板使用引擎内建的 `situation_card_actions` 卡片（原生卡片背景与「主要行动」标题），并覆盖它内部的 `situation_card_action_list` 自己排列按钮（原版 `gui/panels/situation/black_death.gui` 就是这么做的；注意不能在实例上覆盖 `actions_override`，该类型自己已经覆盖过它，会静默失效）：**分类两列（最多 4 行）→ 18px 间隔 → 开关两列（2 行）**。悬停任意开关，提示里会显示「当前：开启/关闭」以及点击后的结果。

> 为什么不直接把按钮放在默认列表里：默认实现会把所有动作平铺成一长列，既无法插入间隔，也占满整屏高度。

## 安装

### 方式一：创意工坊

1. 订阅工坊
2. 启动器播放集里勾选本模组

### 方式二：手动安装 / 网盘安装包

1. 仓库根目录运行 `tools\build_share.ps1`，生成
   `dist\UnconditionallyChangeRGO_v<版本>_网盘安装包.zip`
2. 把包里这**两样东西一起**解压到 EU5 的 mod 目录：
   `…/Documents/Paradox Interactive/Europa Universalis V/mod/`
   （「文档」被 OneDrive 接管时是 `…/OneDrive/文档/Paradox Interactive/Europa Universalis V/mod/`；
   不知道在哪就点启动器「模组」页的「打开模组文件夹」）
   - `UnconditionallyChangeRGO/`（文件夹）
   - `UnconditionallyChangeRGO.mod`（文件，必须和文件夹同级）
3. 启动器播放集里勾选本模组

> **为什么必须有 `.mod` 文件**：启动器只扫描 `mod\*.mod` 来发现模组，文件夹里虽然有
> `descriptor.mod`，但那只在目录内部、不会被扫到。所以 `build_release.ps1` 产出的
> 创意工坊 zip（只有文件夹）不能直接发给玩家，会「装了但启动器里没有」；
> 网盘分享请用 `build_share.ps1` 的产物（附带 `.mod` 和安装说明）。
> 也正因为两份内容相同，工坊版和手动版**不要同时启用**。

## 配置（改默认值）

所有数值只有一个真值源：**`tools/rgo_common.ps1`**

| 常量 | 作用 |
|---|---|
| `$RGO_BASE_PRICE` | 基础价（与 `common/prices/00_rgo_prices.txt` 的 `gold` 对应） |
| `$RGO_PRICE_TIERS` | 六档市场价阈值与系数 |
| `$RGO_COOLDOWN_MONTHS` | 冷却月数 |
| `$RGO_DEFAULT_COST` / `$RGO_DEFAULT_COOLDOWN` | 花费 / 冷却的默认开关 |
| `$RGO_DEFAULT_GEO` | 地理条件限制的默认开关（`no` = 不限地理条件，默认） |
| `$RGO_TOGGLES` | 四个开关的 id / 国家变量 / 判定触发器 / 默认值 / 关闭清理（顺序 = 面板按钮顺序） |
| `$RGO_DEFAULT_CATEGORIES` | 七个分类默认是否显示 |
| `$RGO_EXCLUDED_GOODS` | 排除的货物（默认排除奴隶，它不是制成品）；这是除种植园外唯一的静态货物清单 |
| `Get-RgoGroupFilterLines` | 每个分类的运行时判定规则（`goods_category` / `goods_method` / `is_food`），生成到 `00_rgo_config.txt` 的 `RGO_goods_in_<分类>` |

> **为什么分类不写死货物 id**：写死清单会让「其它模组新增的货物」和「游戏更新新增的货物」永远选不到。
> 现在改用货物自身字段判定（原版 `common/goods` 的 `category` / `method` / `food`）：
> 采矿→矿物、采集→采集、农耕且非食物非种植园→经济作物、农耕且提供食物→食物、
> 除采矿/采集/农耕以外的原材料→狩猎林业、`category = produced` 且非奴隶→制成品。
> 只有「种植园」没有可判定字段，仍按 `01_plantation_goods.txt` 生成静态清单；
> 其它模组新增的种植园类作物会落到「经济作物」（照样能改，只是按钮不同），
> 想单列进种植园就把它写进 `01_plantation_goods.txt` 后重跑生成器。

改完后重跑两个生成器即可同步**脚本、价格阶梯和 11 种语言的文案**，并校验 GUI 的切片数字与开关数量一致：

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
| `in_game/common/scripted_triggers/00_rgo_config.txt` | `generate_rgo_actions.ps1`（含开关判定、价格阶梯、地理门控与 `RGO_goods_in_<分类>` 货物判定） |
| `in_game/gui/panels/situation/UnconditionallyChangeRGO.gui` | 不由生成器改写；生成器只校验它没有覆盖原生卡片、没有自绘动作列表，且两列切片与行数和开关/分类数量一致 |
| `in_game/localization/<lang>/UnconditionallyChangeRGO_l_<lang>.yml` | `generate_rgo_localization.ps1` |

手写文件（`00_rgo_effects.txt`、`00_rgo_prices.txt`、局势、提示、GUI 模板）不受生成器覆盖，但生成器会校验其中与 `rgo_common.ps1` 重复的常量（冷却月数、基础价），不一致会直接报错。

## 校验与维护脚本

| 脚本 | 作用 |
|---|---|
| `tools/build_release.ps1` | 生成创意工坊上传用的干净目录：`dist\UnconditionallyChangeRGO`、`dist\UnconditionallyChangeRGO.mod`、`dist\UnconditionallyChangeRGO_v<版本>.zip`（**不含** `.mod`，只给工坊用） |
| `tools/build_share.ps1` | 生成网盘分享包 `dist\UnconditionallyChangeRGO_v<版本>_网盘安装包.zip`（文件夹 + `.mod` + 安装说明），自检压缩包根层结构与文件数，并输出 SHA256 和 `dist\网盘分享说明.txt` |
| `tools/validate_mod.ps1` | 全量校验：生成物是否最新、11 种语言键集合是否一致、脚本引用的键是否都有本地化、括号是否平衡、UTF-8 BOM 是否齐全、动作/开关数量、分类是否走动态判定、模拟新增货物能否正确归类 |
| `tools/test_dynamic_goods.ps1` | 兼容性自检：把原版 `common/goods` 复制到临时目录并追加一个模拟 mod 的货物文件，断言新货物仍落到预期分类（采矿/采集/农耕/食物/林业/制成品），不启动游戏 |
| `tools/ensure_utf8_bom.ps1` | 给 `.ps1` / `.txt` / `.gui` / `.yml` 补 UTF-8 BOM（Windows PowerShell 5.1 无 BOM 时会按 ANSI 解析导致中文乱码） |
| `tools/toggle_mod.ps1` | 一键停用 / 恢复本模组，用于 A/B 隔离排错 |

提交前推荐：

```powershell
powershell -ExecutionPolicy Bypass -File "tools\validate_mod.ps1"
```

## 兼容性说明

- 只影响本国地点，不改地点归属、不改建筑产出公式。
- 选择地点时不会重复列出「已经是该货物」的地点，避免花冤枉钱。
- **兼容其它模组 / 版本新增的原材料**（v1.0.8 起）：分类不写死货物 id，
  每个分类动作只调用 `00_rgo_config.txt` 的 `RGO_goods_in_<分类>`，
  由游戏在运行时按货物自身字段判定
  （`goods_category` = `raw_material` / `produced`、`goods_method` = `mining` / `farming` /
  `hunting` / `gathering` / `forestry`、`is_food`）。
  因此玩家装了增加原产物的模组，或游戏更新加入了新货物，**不用等本模组更新**，
  新货物就会出现在对应分类里；新货物的名字与图标由它自己的模组提供。
- 规则细节：采矿→矿物；采集→采集；农耕且不是食物、也不在种植园清单→经济作物；
  农耕且提供食物→食物；除采矿/采集/农耕以外的原材料（狩猎、林业等）→狩猎林业；
  `category = produced` 且非奴隶→制成品。
- 用到的原版触发器：`goods_category` / `goods_method` / `is_food`（goods 作用域，
  见原版 `common/trigger_localization/goods_triggers.txt`）。若将来版本改名，
  只需改 `tools/rgo_common.ps1` 的 `Get-RgoGroupFilterLines` 后重跑生成器。
- 两处静态清单（原版没有可判定字段）：
  - **种植园**按 `01_plantation_goods.txt` 生成；其它模组的种植园类作物会落到「经济作物」，照样能改。
  - **排除货物**（`$RGO_EXCLUDED_GOODS`，默认奴隶）写进 `RGO_goods_in_produced`。
- **地理条件**由「地理条件开关」控制，默认关闭。原版 `columbian_exchange` 是强制检查
  `is_goods_valid_for_location`（即货物 `location_potential` 里的气候 / 植被 / 地形 / 区域等静态条件）；
  本模组把它做成开关：关闭时本国任意地点都能改成任意原材料，开启后恢复原版限制。
  判定集中在 `00_rgo_config.txt` 的 `RGO_geo_allows_target`，7 个分类动作共用。
- 本 mod 不执行原版改原材料时的工人上限调整与繁荣度惩罚（「无条件修改」的定位）。
- 「制成品」分类是原版 `produced` 分类去掉奴隶；把建筑产出设为原材料属非原生玩法，默认关闭。
- 分类数量变化时不需要改界面：分类/开关用 `DataModelSubSpan` / `DataModelLast` 动态切片，按钮顺序 = `00_rgo_actions` → `01_rgo_toggles`。
- 分类与开关都用两列网格（`DataModelSubSpan` 按索引切片），两组之间留 18px 间隔；隐藏制成品时最后一行自然空掉，不会与开关混排。

## 版本

见 [CHANGELOG.md](CHANGELOG.md)。当前 **1.0.8**。

## License

MIT，见 [LICENSE](LICENSE)。
