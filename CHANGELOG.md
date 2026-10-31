# Changelog

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

### 界面
- 局势面板新增「分类」标题，与「开关」分组对称
- 分组的切片数字改由生成器自动同步（新增分类后无需手改 GUI）

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
