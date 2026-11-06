# 生成 in_game/common/generic_actions/00_rgo_actions.txt（7 个分类动作）
#   与 in_game/common/generic_actions/01_rgo_toggles.txt + 00_rgo_config.txt
# 同时校验 GUI 的分组方式（不能再用写死的 DataModelFirst/SkipFirst 切片）。
#
# 分类成员不再写死货物 id：动作里只调用 RGO_goods_in_<分类>，
# 由 00_rgo_config.txt 按货物自身字段（goods_category / goods_method / is_food）
# 动态判定，因此其它模组或游戏更新新增的货物会自动出现。
#
# 数据来源：原版 common\goods\*.txt（只用于报告数量与种植园静态清单）；
#           价格阶梯 / 冷却 / 默认值 / 判定规则见 tools\rgo_common.ps1
#
# 用法（在仓库根目录执行）：
#   powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1"
#   powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1" -Check
#   powershell ... -GoodsRoot "D:\...\game\in_game\common\goods"

param(
    [switch]$Check,
    [string]$GoodsRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'rgo_common.ps1')

$modRoot  = Split-Path -Parent $PSScriptRoot
$goodsDir = Get-RgoGoodsRoot -GoodsRoot $GoodsRoot
$rows     = Get-RgoGoodsRows -GoodsRoot $goodsDir
$groups   = Get-RgoGroups -Rows $rows
Assert-RgoGroups -Rows $rows -Groups $groups

$catCount    = @($groups.Keys).Count
$actionsFile = Join-Path $modRoot 'in_game\common\generic_actions\00_rgo_actions.txt'
$togglesFile = Join-Path $modRoot 'in_game\common\generic_actions\01_rgo_toggles.txt'
$guiFile     = Join-Path $modRoot 'in_game\gui\panels\situation\UnconditionallyChangeRGO.gui'
$configFile  = Join-Path $modRoot 'in_game\common\scripted_triggers\00_rgo_config.txt'

# 开关表：统一来自 tools/rgo_common.ps1 的 $RGO_TOGGLES（顺序 = 面板按钮顺序）
#   字段：id / var / check / default / cleanup
$toggleDefs = $RGO_TOGGLES

function Add-SituationStep($sb) {
    Add-RgoLine $sb 1 '# 1) 选局势：GUI 已代入 recipient，正常流程会自动跳过这一步'
    Add-RgoLine $sb 1 'select_trigger = {'
    Add-RgoLine $sb 2 'looking_for_a = situation'
    Add-RgoLine $sb 2 'target_flag = recipient'
    Add-RgoLine $sb 2 'name = "choose_situation"'
    Add-RgoLine $sb 2 'column = { data = name }'
    Add-RgoLine $sb 2 'visible = {'
    Add-RgoLine $sb 3 'situation:UnconditionallyChangeRGO = this'
    Add-RgoLine $sb 3 'situation_is_active = yes'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
}

function Add-GoodsStep($sb, $group) {
    Add-RgoLine $sb 1 '# 2) 选原材料：运行时按货物自身字段动态筛选（见 00_rgo_config.txt 的 RGO_goods_in_*）'
    Add-RgoLine $sb 1 'select_trigger = {'
    Add-RgoLine $sb 2 'looking_for_a = goods'
    Add-RgoLine $sb 2 'target_flag = target_good'
    Add-RgoLine $sb 2 'name = "RGO_select_goods"'
    Add-RgoLine $sb 2 'column = { data = name }'
    Add-RgoLine $sb 2 'none_available_msg_key = "RGO_no_goods_available"'
    Add-RgoLine $sb 2 'cache_targets = yes'
    Add-RgoLine $sb 2 'cache_interaction_source_list = yes'
    Add-RgoLine $sb 2 'interaction_source_list = {'
    Add-RgoLine $sb 3 'every_goods = {'
    Add-RgoLine $sb 4 'limit = {'
    Add-RgoLine $sb 5 ('RGO_goods_in_' + $group + ' = yes')
    Add-RgoLine $sb 4 '}'
    Add-RgoLine $sb 4 'add_to_list = source'
    Add-RgoLine $sb 3 '}'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
}

function Add-LocationStep($sb) {
    Add-RgoLine $sb 1 '# 3) 选地块：仅本国地块；地理条件开关开启时还要求该货物能作为此地原材料'
    Add-RgoLine $sb 1 'select_trigger = {'
    Add-RgoLine $sb 2 'looking_for_a = location'
    Add-RgoLine $sb 2 'target_flag = target_location'
    Add-RgoLine $sb 2 'name = "RGO_select_location"'
    Add-RgoLine $sb 2 'map_mode = raw_material'
    Add-RgoLine $sb 2 'column = { data = name }'
    Add-RgoLine $sb 2 'column = { data = raw_material }'
    Add-RgoLine $sb 2 'none_available_msg_key = "RGO_no_locations_available"'
    Add-RgoLine $sb 2 'interaction_source_list = {'
    Add-RgoLine $sb 3 'scope:actor = {'
    Add-RgoLine $sb 4 'every_owned_location = {'
    Add-RgoLine $sb 5 'add_to_list = source'
    Add-RgoLine $sb 4 '}'
    Add-RgoLine $sb 3 '}'
    Add-RgoLine $sb 2 '}'
    # 候选地块的两个条件：
    #   RGO_geo_allows_target —— 地理条件开关（默认关闭 = 恒为 yes，本国任意地点都能选；
    #                            开启时才走原版 is_goods_valid_for_location，
    #                            即货物 location_potential 里的气候/植被/地形/区域限制）
    #   排除已经是该货物的地块，避免花冤枉钱
    Add-RgoLine $sb 2 'visible = {'
    Add-RgoLine $sb 3 'RGO_geo_allows_target = yes'
    Add-RgoLine $sb 3 'NOT = { raw_material ?= scope:target_good }'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
}

# ============================================================
# 1. 分类动作
# ============================================================
$sb = New-Object System.Text.StringBuilder
Add-RgoLine $sb 0 '########################################################################'
Add-RgoLine $sb 0 '# 本文件由 tools\generate_rgo_actions.ps1 自动生成，请勿手改'
Add-RgoLine $sb 0 '# 七个分类：矿物 / 采集 / 经济作物 / 食物 / 种植园 / 狩猎林业 / 制成品'
Add-RgoLine $sb 0 '# 每个分类的货物清单由 00_rgo_config.txt 的 RGO_goods_in_<分类> 动态判定，'
Add-RgoLine $sb 0 '# 因此其它模组 / 游戏更新新增的货物会自动出现在列表里（无需重建本模组）'
Add-RgoLine $sb 0 '# 价格阶梯、冷却月数、分类默认值、判定规则统一在 tools\rgo_common.ps1 里维护'
Add-RgoLine $sb 0 '########################################################################'
Add-RgoLine $sb 0 ''

foreach ($g in $groups.Keys) {
    Add-RgoLine $sb 0 ('RGO_change_' + $g + ' = {')
    Add-RgoLine $sb 1 'type = situation'
    Add-RgoLine $sb 0 ''
    Add-RgoLine $sb 1 'ai_tick = never'
    Add-RgoLine $sb 1 'automation_tick = never'
    Add-RgoLine $sb 1 'show_message = no'
    Add-RgoLine $sb 1 'show_message_to_target = no'
    Add-RgoLine $sb 0 ''

    # 价格：基础价 x 市场价系数；六档阈值统一放在 00_rgo_config.txt
    # 每个分支都必须带 desc：引擎要求“非 1 的倍率”提供 ScaleReason，
    # 否则打开确认框时 error.log 会断言失败：
    #   Using Price rgo_change, Scale is not VONE, should be using a ScaleReason here
    Add-RgoLine $sb 1 ('# 花费 = price:rgo_change（' + $RGO_BASE_PRICE + ' 金）x 市场价系数；花费开关关闭或地点无市场 => 0（免费）')
    Add-RgoLine $sb 1 '# 每个倍率都带 desc（ScaleReason），供确认框解释收费理由'
    Add-RgoLine $sb 1 'price = price:rgo_change'
    Add-RgoLine $sb 1 'price_modifier = {'
    for ($i = 0; $i -lt $RGO_PRICE_TIERS.Count; $i++) {
        $t = $RGO_PRICE_TIERS[$i]
        $kw = if ($i -eq 0) { 'if' } else { 'else_if' }
        $factor = $t.factor.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        Add-RgoLine $sb 2 ($kw + ' = {')
        Add-RgoLine $sb 3 ('limit = { RGO_price_tier_' + $t.tier + ' = yes }')
        Add-RgoLine $sb 3 ('add = { desc = "RGO_PRICE_TIER" value = ' + $factor + ' }')
        Add-RgoLine $sb 2 '}'
    }
    Add-RgoLine $sb 2 'else = {'
    Add-RgoLine $sb 3 'add = { desc = "RGO_PRICE_FREE" value = 0 }'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
    Add-RgoLine $sb 0 ''

    # 分类开关
    Add-RgoLine $sb 1 '# 分类开关：关闭后本按钮不再出现'
    Add-RgoLine $sb 1 'potential = {'
    Add-RgoLine $sb 2 'scope:actor ?= {'
    if ($g -eq 'produced') {
        Add-RgoLine $sb 3 'RGO_cat_produced_enabled = yes'
    }
    else {
        Add-RgoLine $sb 3 ('RGO_cfg_cat_' + $g + '_default = yes')
    }
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
    Add-RgoLine $sb 0 ''

    # 冷却
    Add-RgoLine $sb 1 '# 冷却开关：冷却未结束时按钮不可用'
    Add-RgoLine $sb 1 'allow = {'
    Add-RgoLine $sb 2 'scope:actor ?= {'
    Add-RgoLine $sb 3 'NOT = { has_country_modifier = rgo_change_cooldown }'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
    Add-RgoLine $sb 0 ''

    Add-SituationStep $sb
    Add-RgoLine $sb 0 ''
    Add-GoodsStep $sb $g
    Add-RgoLine $sb 0 ''
    Add-LocationStep $sb

    Add-RgoLine $sb 1 'effect = {'
    Add-RgoLine $sb 2 'RGO_apply_change = yes'
    Add-RgoLine $sb 1 '}'
    Add-RgoLine $sb 0 '}'
    Add-RgoLine $sb 0 ''
}

$actionsText = $sb.ToString()
Write-RgoTextFile -Path $actionsFile -Text $actionsText -CheckOnly:$Check


# ============================================================
# 2. 开关（数量与顺序来自 rgo_common.ps1 的 $RGO_TOGGLES）
# ============================================================
$tb = New-Object System.Text.StringBuilder
Add-RgoLine $tb 0 '# ============================================================'
Add-RgoLine $tb 0 ('# ' + $RGO_TOGGLE_COUNT + ' 个开关（与分类按钮同处局势面板的一张卡内，点击一次切换一次，免费）')
foreach ($d in $toggleDefs) {
    Add-RgoLine $tb 0 ('#   RGO_toggle_' + $d.id + '  ->  国家变量 ' + $d.var)
}
Add-RgoLine $tb 0 '# 本文件由 tools\generate_rgo_actions.ps1 自动生成，请勿手改'
Add-RgoLine $tb 0 '# 开关判定与默认值见 in_game/common/scripted_triggers/00_rgo_config.txt'
Add-RgoLine $tb 0 '# ============================================================'
Add-RgoLine $tb 0 ''

foreach ($d in $toggleDefs) {
    Add-RgoLine $tb 0 ('RGO_toggle_' + $d.id + ' = {')
    Add-RgoLine $tb 1 'type = situation'
    Add-RgoLine $tb 0 ''
    Add-RgoLine $tb 1 'ai_tick = never'
    Add-RgoLine $tb 1 'automation_tick = never'
    Add-RgoLine $tb 1 'show_message = no'
    Add-RgoLine $tb 0 ''
    Add-RgoLine $tb 1 '# 按钮挂在局势面板上，需要一个 recipient（本局势）'
    Add-RgoLine $tb 1 'select_trigger = {'
    Add-RgoLine $tb 2 'looking_for_a = situation'
    Add-RgoLine $tb 2 'target_flag = recipient'
    Add-RgoLine $tb 2 'name = "choose_situation"'
    Add-RgoLine $tb 2 'column = { data = name }'
    Add-RgoLine $tb 2 'visible = {'
    Add-RgoLine $tb 3 'situation:UnconditionallyChangeRGO = this'
    Add-RgoLine $tb 3 'situation_is_active = yes'
    Add-RgoLine $tb 2 '}'
    Add-RgoLine $tb 1 '}'
    Add-RgoLine $tb 0 ''
    Add-RgoLine $tb 1 '# 悬停时显示当前开/关状态（custom_tooltip 由触发器决定用哪一句）'
    Add-RgoLine $tb 1 'effect = {'
    Add-RgoLine $tb 2 'scope:actor ?= {'
    Add-RgoLine $tb 3 'if = {'
    Add-RgoLine $tb 4 ('limit = { ' + $d.check + ' = yes }')
    Add-RgoLine $tb 4 'custom_tooltip = { text = RGO_toggle_state_on }'
    Add-RgoLine $tb 3 '}'
    Add-RgoLine $tb 3 'else = {'
    Add-RgoLine $tb 4 'custom_tooltip = { text = RGO_toggle_state_off }'
    Add-RgoLine $tb 3 '}'
    Add-RgoLine $tb 0 ''
    Add-RgoLine $tb 3 '# 真正的状态切换放在 hidden_effect 里，避免 tooltip 出现变量噪音'
    Add-RgoLine $tb 3 'hidden_effect = {'
    Add-RgoLine $tb 4 'if = {'
    Add-RgoLine $tb 5 ('limit = { ' + $d.check + ' = yes }')
    Add-RgoLine $tb 5 'set_variable = {'
    Add-RgoLine $tb 6 ('name = ' + $d.var)
    Add-RgoLine $tb 6 'value = 0'
    Add-RgoLine $tb 5 '}'
    if ($d.cleanup) { Add-RgoLine $tb 5 $d.cleanup }
    Add-RgoLine $tb 4 '}'
    Add-RgoLine $tb 4 'else = {'
    Add-RgoLine $tb 5 'set_variable = {'
    Add-RgoLine $tb 6 ('name = ' + $d.var)
    Add-RgoLine $tb 6 'value = 1'
    Add-RgoLine $tb 5 '}'
    Add-RgoLine $tb 4 '}'
    Add-RgoLine $tb 3 '}'
    Add-RgoLine $tb 2 '}'
    Add-RgoLine $tb 1 '}'
    Add-RgoLine $tb 0 '}'
    Add-RgoLine $tb 0 ''
}

$togglesText = $tb.ToString()
Write-RgoTextFile -Path $togglesFile -Text $togglesText -CheckOnly:$Check

# ============================================================
# 3. 开关与价格阶梯配置
# ============================================================
$cb = New-Object System.Text.StringBuilder
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 原产物全修改 —— 开关与价格阶梯配置'
Add-RgoLine $cb 0 '# 本文件由 tools\generate_rgo_actions.ps1 自动生成，请勿手改'
Add-RgoLine $cb 0 '# 真值源：tools\rgo_common.ps1（默认值、价格阈值与系数、冷却月数）'
Add-RgoLine $cb 0 '#'
Add-RgoLine $cb 0 '# 判定优先级：玩家在局势面板点开关会写入国家变量（rgo_var_*）；'
Add-RgoLine $cb 0 '#             有变量则以变量为准，没有变量才用下面的文件级默认值。'
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# --- 花费开关（yes = 按市场价收费 / no = 全部免费） ---'
Add-RgoLine $cb 0 ('RGO_cfg_cost_default = { always = ' + $RGO_DEFAULT_COST + ' }')
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 ('# --- 冷却开关（yes = 每次修改挂 ' + $RGO_COOLDOWN_MONTHS + ' 个月冷却 / no = 无冷却） ---')
Add-RgoLine $cb 0 ('RGO_cfg_cooldown_default = { always = ' + $RGO_DEFAULT_COOLDOWN + ' }')
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# --- 地理条件开关（yes = 只列出原版允许该货物的地点 / no = 不限地理条件） ---'
Add-RgoLine $cb 0 ('RGO_cfg_geo_default = { always = ' + $RGO_DEFAULT_GEO + ' }')
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# --- 七个分类的默认按钮开关 ---'
foreach ($k in $RGO_DEFAULT_CATEGORIES.Keys) {
    $name = 'RGO_cfg_cat_' + $k + '_default'
    Add-RgoLine $cb 0 (($name.PadRight(30)) + ' = { always = ' + $RGO_DEFAULT_CATEGORIES[$k] + ' }')
}
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 运行时判定（root 均为国家，可在任何国家作用域里直接调用）'
Add-RgoLine $cb 0 '# ============================================================'

$switchDefs = $RGO_TOGGLES
foreach ($s in $switchDefs) {
    Add-RgoLine $cb 0 ''
    Add-RgoLine $cb 0 ($s.check + ' = {')
    Add-RgoLine $cb 1 'OR = {'
    Add-RgoLine $cb 2 'AND = {'
    Add-RgoLine $cb 3 ('has_variable = ' + $s.var)
    Add-RgoLine $cb 3 ('var:' + $s.var + ' > 0')
    Add-RgoLine $cb 2 '}'
    Add-RgoLine $cb 2 'AND = {'
    Add-RgoLine $cb 3 ('NOT = { has_variable = ' + $s.var + ' }')
    Add-RgoLine $cb 3 ($s.default + ' = yes')
    Add-RgoLine $cb 2 '}'
    Add-RgoLine $cb 1 '}'
    Add-RgoLine $cb 0 '}'
}

Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 地理条件限制（被各分类动作的「选地点」步骤调用）'
Add-RgoLine $cb 0 '#   开关关闭（默认）：恒为 yes —— 本国任意地点都能改成任意原材料'
Add-RgoLine $cb 0 '#   开关开启：沿用原版 is_goods_valid_for_location，即货物的 location_potential'
Add-RgoLine $cb 0 '#             （气候 / 植被 / 地形 / 区域等静态地理条件，原版在开局缓存）'
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 'RGO_geo_allows_target = {'
Add-RgoLine $cb 1 'OR = {'
Add-RgoLine $cb 2 'NOT = {'
Add-RgoLine $cb 3 'scope:actor ?= {'
Add-RgoLine $cb 4 'RGO_geo_enabled = yes'
Add-RgoLine $cb 3 '}'
Add-RgoLine $cb 2 '}'
Add-RgoLine $cb 2 'is_goods_valid_for_location = scope:target_good'
Add-RgoLine $cb 1 '}'
Add-RgoLine $cb 0 '}'

Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 价格阶梯（被各分类动作的 price_modifier 调用）'
Add-RgoLine $cb 0 '# RGO_chargeable：花费开关开启 + 地块处于某个市场内，才谈得上收费'
Add-RgoLine $cb 0 ('# 阈值(<) -> 系数：' + (($RGO_PRICE_TIERS | Where-Object { $null -ne $_.threshold } | ForEach-Object { $_.threshold.ToString([System.Globalization.CultureInfo]::InvariantCulture) }) -join ' / ') + '（其余为最高档） -> ' + (($RGO_PRICE_TIERS | ForEach-Object { $_.factor.ToString([System.Globalization.CultureInfo]::InvariantCulture) }) -join ' / '))
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 'RGO_chargeable = {'
Add-RgoLine $cb 1 'scope:actor ?= {'
Add-RgoLine $cb 2 'RGO_cost_enabled = yes'
Add-RgoLine $cb 1 '}'
Add-RgoLine $cb 1 'exists = scope:target_location.market'
Add-RgoLine $cb 0 '}'

foreach ($t in $RGO_PRICE_TIERS) {
    Add-RgoLine $cb 0 ''
    Add-RgoLine $cb 0 ('RGO_price_tier_' + $t.tier + ' = {')
    Add-RgoLine $cb 1 'RGO_chargeable = yes'
    if ($null -ne $t.threshold) {
        $thr = $t.threshold.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        Add-RgoLine $cb 1 ('"scope:target_good.price_in_market(scope:target_location.market)" < ' + $thr)
    }
    Add-RgoLine $cb 0 '}'
}

Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 货物分类判定（root = goods 作用域；被各分类动作的「选原材料」步骤调用）'
Add-RgoLine $cb 0 '#   动态判定：只读货物自身字段，不写死货物 id ——'
Add-RgoLine $cb 0 '#     goods_category = raw_material / produced'
Add-RgoLine $cb 0 '#     goods_method   = mining / farming / hunting / gathering / forestry'
Add-RgoLine $cb 0 '#     is_food        = 该货物是否提供食物'
Add-RgoLine $cb 0 '#   因此其它模组或游戏更新新增的货物会自动进入对应分类。'
Add-RgoLine $cb 0 '#   例外：种植园只能按原版 01_plantation_goods.txt 的清单（生成时写入）；'
Add-RgoLine $cb 0 '#         制成品排除 $RGO_EXCLUDED_GOODS（奴隶）。'
Add-RgoLine $cb 0 '# ============================================================'
foreach ($g in $groups.Keys) {
    Add-RgoLine $cb 0 ''
    Add-RgoLine $cb 0 ('RGO_goods_in_' + $g + ' = {')
    foreach ($line in (Get-RgoGroupFilterLines -Group $g -Groups $groups)) {
        Add-RgoLine $cb 1 $line
    }
    Add-RgoLine $cb 0 '}'
}

$configText = $cb.ToString()
Write-RgoTextFile -Path $configFile -Text $configText -CheckOnly:$Check

# ============================================================
# 4. GUI 一致性校验
# ============================================================
if (Test-Path -LiteralPath $guiFile) {
    $guiText = [System.IO.File]::ReadAllText($guiFile)
    if ($guiText -match 'DataModel(First|SkipFirst)\(ActionGroup\.GetActions') {
        throw 'GUI 仍用 DataModelFirst/SkipFirst 的写死切片，隐藏分类时会把开关挤进分类区'
    }
    if ($guiText -notmatch 'blockoverride\s+"situation_card_action_list"') {
        throw 'GUI 没有覆盖 situation_card_actions 内部的 situation_card_action_list（覆盖 actions_override 无效，它已被该类型自己覆盖过）'
    }
    if ($guiText -notmatch 'blockoverride\s+"situation_panel_main_actions"') {
        throw 'GUI 没有关闭 situation_panel_main_actions，会与自定义卡片重复渲染'
    }
    # 两列网格：分类逐个取索引 0..N-1，开关用 GetDataModelSize - k 反推起始索引
    # 数量变化时 GUI 的行数必须同步，否则多出的按钮不会显示（这里直接报错提醒）
    $missing = @()
    for ($i = 0; $i -lt $catCount; $i++) {
        $needle = "DataModelSubSpan(ActionGroup.GetActions, '(int32)$i', '(int32)1')"
        if (([regex]::Matches($guiText, [regex]::Escape($needle))).Count -ne 1) { $missing += ('分类 ' + ($i + 1)) }
    }
    for ($k = $RGO_TOGGLE_COUNT; $k -ge 1; $k--) {
        $needle = "DataModelSubSpan(ActionGroup.GetActions, Subtract_int32(GetDataModelSize(ActionGroup.GetActions), '(int32)$k'), '(int32)1')"
        if (([regex]::Matches($guiText, [regex]::Escape($needle))).Count -ne 1) { $missing += ('开关 -' + $k) }
    }
    if ($missing.Count -gt 0) {
        throw ('GUI 的两列切片与数据不一致（缺少或重复）: ' + ($missing -join ', ') + '。改完 rgo_common.ps1 后请同步 GUI 的行数。')
    }
    $expectedRows = [int]([Math]::Ceiling($catCount / 2) + [Math]::Ceiling($RGO_TOGGLE_COUNT / 2))
    $guiRows = ([regex]::Matches($guiText, '(?m)^\t+hbox = \{')).Count
    if ($guiRows -ne $expectedRows) {
        throw ('GUI 的行数是 ' + $guiRows + '，按两列布局应为 ' + $expectedRows + ' 行（分类 ' + $catCount + ' 个 + 开关 ' + $RGO_TOGGLE_COUNT + ' 个）')
    }
    # 分类行的可见性：第 r 行要求「可见分类数 >= 2r+1」，即可见分类数（size - 开关数）> 2r
    # 少了这个判断，分类被隐藏时该行会取到开关按钮（1.0.7 初版就把「花费开关」渲染了两遍）
    $catRows = [int][Math]::Ceiling($catCount / 2)
    for ($r = 1; $r -lt $catRows; $r++) {
        $threshold = $RGO_TOGGLE_COUNT + 2 * $r
        $needle = 'visible = "[GreaterThan_int32(GetDataModelSize(ActionGroup.GetActions), ' + "'(int32)$threshold'" + ')]"'
        if (([regex]::Matches($guiText, [regex]::Escape($needle))).Count -ne 1) {
            throw ('GUI 第 ' + ($r + 1) + ' 行缺少可见性判断 ' + $needle + '：分类被隐藏时这一行会取到开关按钮')
        }
    }
    Write-Host ('[一致] GUI：原生卡片 + actions_override 两列网格（分类 ' + $catCount + ' 个 → ' + [Math]::Ceiling($catCount / 2) + ' 行，开关 ' + $RGO_TOGGLE_COUNT + ' 个 → ' + [Math]::Ceiling($RGO_TOGGLE_COUNT / 2) + ' 行，中间留 18px 间隔）')
}
else {
    Write-Warning ("找不到 GUI 文件，跳过一致性校验: " + $guiFile)
}

# ============================================================
# 5. 手写文件一致性校验（防止常量漂移）
# ============================================================
$effectsFile = Join-Path $modRoot 'in_game\common\scripted_effects\00_rgo_effects.txt'
$pricesFile  = Join-Path $modRoot 'in_game\common\prices\00_rgo_prices.txt'

if (Test-Path -LiteralPath $effectsFile) {
    $m = [regex]::Match([System.IO.File]::ReadAllText($effectsFile), 'months\s*=\s*(\d+)')
    if (-not $m.Success) { throw '00_rgo_effects.txt 里找不到 months = <数字>' }
    $months = [int]$m.Groups[1].Value
    if ($months -ne $RGO_COOLDOWN_MONTHS) {
        throw ("冷却月数不一致：00_rgo_effects.txt = $months，tools\rgo_common.ps1 = $RGO_COOLDOWN_MONTHS")
    }
}

if (Test-Path -LiteralPath $pricesFile) {
    $m = [regex]::Match([System.IO.File]::ReadAllText($pricesFile), 'gold\s*=\s*(\d+)')
    if (-not $m.Success) { throw '00_rgo_prices.txt 里找不到 gold = <数字>' }
    $gold = [int]$m.Groups[1].Value
    if ($gold -ne $RGO_BASE_PRICE) {
        throw ("基础价不一致：00_rgo_prices.txt = $gold，tools\rgo_common.ps1 = $RGO_BASE_PRICE")
    }
}
Write-Host '[校验] 手写文件的冷却月数与基础价与 rgo_common.ps1 一致'

# ============================================================
# 6. 汇总
# ============================================================
$actionCount = ([regex]::Matches($actionsText, '(?m)^RGO_change_[a-z_]+ = \{')).Count
$toggleCount = ([regex]::Matches($togglesText, '(?m)^RGO_toggle_[a-z_]+ = \{')).Count

Write-Host ''
Write-Host ("原版货物 {0} 种 -> {1} 个分类（排除: {2}）" -f $rows.Count, $catCount, ($RGO_EXCLUDED_GOODS -join ', '))
Write-Host '以下按原版数据统计；运行时按货物字段动态判定，其它模组 / 新版本的货物无需重建即可入选'
foreach ($k in $groups.Keys) {
    Write-Host ("  {0,-11} {1,3} 种  {2}" -f $k, $groups[$k].Count, ($groups[$k] -join ', '))
}
Write-Host ("分类动作 {0} 个 / 开关 {1} 个" -f $actionCount, $toggleCount)

# 每类必须调用自己的动态判定触发器，且动作里不能再出现写死的货物清单
foreach ($g in $groups.Keys) {
    $calls = ([regex]::Matches($actionsText, '(?m)^\t{5}RGO_goods_in_' + $g + ' = yes\r?$')).Count
    if ($calls -ne 1) { throw ("分类 $g 调用 RGO_goods_in_$g 的次数是 $calls（应为 1）") }
    if ($configText -notmatch ('(?m)^RGO_goods_in_' + $g + ' = \{')) { throw ("00_rgo_config.txt 缺少 RGO_goods_in_$g 判定触发器") }
}
if ($actionsText -match 'this = goods:') {
    throw '00_rgo_actions.txt 里仍有写死的货物清单（this = goods:），模组新增货物会被漏掉'
}

# 价格倍率必须带 ScaleReason（desc）：否则打开确认框时 error.log 会断言失败
$tierDesc = ([regex]::Matches($actionsText, 'desc = "RGO_PRICE_TIER"')).Count
$freeDesc = ([regex]::Matches($actionsText, 'desc = "RGO_PRICE_FREE"')).Count
$expectedTierDesc = $catCount * $RGO_PRICE_TIERS.Count
if ($tierDesc -ne $expectedTierDesc) {
    throw ('price_modifier 的档位 desc 数量是 ' + $tierDesc + '（应为 ' + $expectedTierDesc + '）：每个分类每一档都要 desc = "RGO_PRICE_TIER"')
}
if ($freeDesc -ne $catCount) {
    throw ('price_modifier 的免费 desc 数量是 ' + $freeDesc + '（应为 ' + $catCount + '）：每个分类的 else 都要 desc = "RGO_PRICE_FREE"')
}

if ($actionCount -ne $catCount) { throw "分类动作数量（$actionCount）与分类数（$catCount）不一致" }
if ($toggleCount -ne $toggleDefs.Count) { throw "开关数量（$toggleCount）与开关表（$($toggleDefs.Count)）不一致" }
if ($Check) { Write-Host '校验通过：生成物与脚本数据一致。' }
