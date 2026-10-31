# Changelog

## 1.0.5

### 修复
- **按钮错位 / 无法点击**：不再用 `fixedgridbox` 自绘整列按钮，改为使用引擎内建
  `situation_card_actions` 卡片的官方钩子 `actions_override`（布局写法取自原版 `gui/ui_library.gui`
  的「vertical buttons layout example」：`vbox` + `layoutpolicy_horizontal = expanding` + `size = { -1 30 }`），
  既保留原生卡片外观，又避免自绘网格命中区域与视觉位置错开
- **面板重复**：关闭 `situation_panel_main_actions`，同一面板只保留一组按钮
- **分类与开关的分隔**：放弃名称前缀「—」，改为在两个列表之间插入**一个按钮高度**的空白（`size = { 480 30 }`）
- **悬停查看开关状态**：开关动作的 `effect` 增加 `custom_tooltip`，
  由 `RGO_cost_enabled` / `RGO_cooldown_enabled` / `RGO_cat_produced_enabled` 触发器决定显示
  「当前：开启 —— 点击后关闭」还是「当前：关闭 —— 点击后开启」；
  真正的变量切换移入 `hidden_effect`，tooltip 不再出现变量设置噪音
- **卡片标题占位文字**：`situation_card_actions` 的默认标题是引擎 UI 库示例里的占位串
  `IOs Card important title header`（连图标都是示例用的拳头）。现按原版 `situations_actions` 的做法
  显式覆盖 `card_header_text` / `card_header_icon`，标题改用 11 种语言的「原材料操作 / Raw Material Actions」
- 分类/开关仍用 `DataModelSubSpan` + `DataModelLast` 动态切片，隐藏制成品按钮时不会错位

### 正确性（对照原版 columbian_exchange）
- **地块候选过滤**：选择地块时新增
  `is_goods_valid_for_location = scope:target_good`（该货物能否成为此地原材料，城市/地形等限制）
  与 `NOT = { raw_material ?= scope:target_good }`（排除已经是该货物的地块，避免白花钱）。
  之前会把城市等无法产出该原材料的地块也列出来，选中后等于白点
- **价格成本修正器类型**：新增 `main_menu/common/modifier_type_definitions/00_rgo_modifier_types.txt`，
  定义 `rgo_change_cost_modifier`，消除 error.log 中的
  `Missing modifier type for price. rgo_change_cost_modifier`
- 说明：本 mod 刻意不执行原版在改 RGO 前的 `change_max_raw_material_workers` / `change_prosperity`
  惩罚（「无条件修改」的定位），如需与原版一致的惩罚可另行开启

### 工程
- `generate_rgo_actions.ps1`：GUI 校验改为「必须使用 actions_override + 必须关闭原生卡片 +
  禁止 DataModelFirst/SkipFirst 写死切片」
- `validate_mod.ps1`：新增 actions_override / 间隔 / 开关状态键检查；修正 `_desc` 推导对
  `RGO_toggle_state_*` 的误判
- 新增 11 种语言的 `RGO_toggle_state_on` / `RGO_toggle_state_off`

## 1.0.4

### 多语言
- 新增 8 种官方语言：Português (Brasil)、Français、Deutsch、Español、Polski、Türkçe、日本語、한국어（原有 English / Русский / 简体中文），共 11 种
- 全部 11 种语言的货物名直接取自原版 `goods_l_<lang>.yml`，与原版术语一致
- 修正提示文案：「九个开关」→ 实际的 3 个开关；分类按钮数量改为由数据生成，不再写死
- 提示文本拆分为标题 `hint_UnconditionallyChangeRGO` 与正文 `_hint_text`，符合原版约定
- 本地化键全部加 `RGO_` 前缀（`RGO_select_goods` / `RGO_select_location` / `RGO_no_*_available`），
  不再覆盖原版 `SELECT_LOCATION` 等通用键
- 移除死键 `RGO_CARD_TITLE`、`trigger_no_rgo_goods`、`trigger_no_rgo_locations`；
  「无可选目标」改用引擎的 `none_available_msg_key`
- 术语与原版对齐：显示名「原产物」→「原材料」、「地块」→「地点」（与原版中文、日文、韩文的 location 用词一致）

### 日志修复（依据 error.log）
- 修复 `Invalid localization header indentation`：11 个语言文件的 `l_<lang>:` 语言头改为顶格
- 修复 `Key RGO_no_*_available doesn't exist or doesn't start with trigger_no icon`：
  「无可选目标」文案补上 `@trigger_no!` 图标前缀（与 `no_locations_available` 等原版键一致）

### 界面
- 修复面板重复：关闭引擎自带的「主要行动」卡片（`situation_panel_main_actions`），
  只保留一套「分类 / 开关」分组列表，不再出现两份按钮
- 修复分组错位：分类与开关改用 `DataModelSubSpan` / `DataModelLast` 动态切片
  （末尾 3 个固定为开关），制成品按钮默认隐藏时「花费开关」不会再被挤进分类
- 去掉自定义列表里的嵌套滚动条与固定尺寸，改由面板自带的滚动区域承载，不再出现双滚动条
- 局势面板新增「分类」标题，与「开关」分组对称

### 代码结构
- 新增 `tools/rgo_common.ps1`：货物解析、分组、价格阶梯、冷却、默认值的唯一真值源
- `00_rgo_actions.txt` / `01_rgo_toggles.txt` / `00_rgo_config.txt` 全部由生成器产出
- 价格阶梯从「每个动作 59 行」压缩为「每个动作 6 行 + 共享的 `RGO_price_tier_1..6` 触发器」，
  生成文件从 1004 行降到约 400 行
- 开关变量与触发器重命名，消除 `RGO_opt_cost` / `rgo_opt_cost` 仅大小写不同的歧义
  （变量：`rgo_var_cost` / `rgo_var_cooldown` / `rgo_var_produced`）
- 分类内部 id `industry` → `produced`，显示名改为「制成品 / Manufactured」，与原版 `produced` 分类对齐
- 制成品分类排除奴隶（`slaves_goods`）：货物总数 75 → 74
- 原材料选择步骤加入 `cache_targets` / `cache_interaction_source_list`，减少重复计算
- 删除 6 个仅透传默认值的 `RGO_cat_*_enabled` 触发器、3 组空的 `potential` / `allow` 块
- 生成器支持 `-Check`（校验生成物是否最新）、`-GoodsRoot`（自定义原版路径）、
  货物自动通配发现、归类完整性断言，并校验手写文件中的冷却月数与基础价

### 文档与元数据
- 新增 README、CHANGELOG、LICENSE（MIT）
- 新增 `tools/validate_mod.ps1`（键集合 / 括号 / BOM / 数量 / 生成物新鲜度全量校验）
  与 `tools/ensure_utf8_bom.ps1`（防止 PowerShell 5.1 按 ANSI 读取中文脚本）
- `metadata.json` 版本 1.0.1 → 1.0.4，描述按现状重写（74 种 / 7 类 / 制成品默认关闭），标签与 `descriptor.mod` 对齐
- `descriptor.mod` 补 `version` 字段，`picture` 指向实际存在的 `thumbnail.png`
- `toggle_mod.ps1` 改为自动定位文档目录（兼容 OneDrive 重定向），补错误提示

## 1.0.3
- 按钮分组与间距调整；花费改为六档市场阶梯价；修复变量未设置与价格缩放断言

## 1.0.2
- 开关回归局势面板（10 键单卡无滚动），移除决议方案

## 1.0.1
- 开关迁移至决议界面；修复变量触发与价格系数报错

## 1.0.0
- 创建 EU5 模组项目：EU5UnconditionallyChangeRGO
