# 生成 in_game/common/generic_actions/00_rgo_actions.txt（7 个分类动作）
#   与 in_game/common/generic_actions/01_rgo_toggles.txt（3 个开关）
# 同时把 GUI 里的分类切片数字（DataModelFirst / DataModelSkipFirst）同步为当前分类数。
#
# 数据来源：原版 common\goods\*.txt；价格阶梯 / 冷却 / 默认值见 tools\rgo_common.ps1
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

# 开关表：id / 国家变量名 / 判定用 scripted trigger / 关闭时要清理的东西
$toggleDefs = @(
    [pscustomobject]@{ id = 'cost';     var = 'rgo_var_cost';     check = 'RGO_cost_enabled';       cleanup = $null }
    [pscustomobject]@{ id = 'cooldown'; var = 'rgo_var_cooldown'; check = 'RGO_cooldown_enabled';   cleanup = 'remove_country_modifier = rgo_change_cooldown' }
    [pscustomobject]@{ id = 'produced'; var = 'rgo_var_produced'; check = 'RGO_cat_produced_enabled'; cleanup = $null }
)

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

function Add-GoodsStep($sb, $ids) {
    Add-RgoLine $sb 1 ('# 2) 选原材料：本分类 ' + $ids.Count + ' 种')
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
    Add-RgoLine $sb 5 'OR = {'
    foreach ($id in $ids) { Add-RgoLine $sb 6 ('this = goods:' + $id) }
    Add-RgoLine $sb 5 '}'
    Add-RgoLine $sb 4 '}'
    Add-RgoLine $sb 4 'add_to_list = source'
    Add-RgoLine $sb 3 '}'
    Add-RgoLine $sb 2 '}'
    Add-RgoLine $sb 1 '}'
}

function Add-LocationStep($sb) {
    Add-RgoLine $sb 1 '# 3) 选地块：仅本国地块'
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
    Add-RgoLine $sb 1 '}'
}

# ============================================================
# 1. 分类动作
# ============================================================
$sb = New-Object System.Text.StringBuilder
Add-RgoLine $sb 0 '########################################################################'
Add-RgoLine $sb 0 '# 本文件由 tools\generate_rgo_actions.ps1 自动生成，请勿手改'
Add-RgoLine $sb 0 '# 七个分类：矿物 / 采集 / 经济作物 / 食物 / 种植园 / 狩猎林业 / 制成品'
Add-RgoLine $sb 0 '# 货物清单来自原版 common\goods\*.txt；新增或改动货物后重跑生成器即可'
Add-RgoLine $sb 0 '# 价格阶梯、冷却月数、分类默认值统一在 tools\rgo_common.ps1 里维护'
Add-RgoLine $sb 0 '########################################################################'
Add-RgoLine $sb 0 ''

foreach ($g in $groups.Keys) {
    $ids = $groups[$g]

    Add-RgoLine $sb 0 ('RGO_change_' + $g + ' = {')
    Add-RgoLine $sb 1 'type = situation'
    Add-RgoLine $sb 0 ''
    Add-RgoLine $sb 1 'ai_tick = never'
    Add-RgoLine $sb 1 'automation_tick = never'
    Add-RgoLine $sb 1 'show_message = no'
    Add-RgoLine $sb 1 'show_message_to_target = no'
    Add-RgoLine $sb 0 ''

    # 价格：基础价 x 市场价系数；六档阈值统一放在 00_rgo_config.txt
    Add-RgoLine $sb 1 ('# 花费 = price:rgo_change（' + $RGO_BASE_PRICE + ' 金）x 市场价系数；花费开关关闭或地点无市场 => 0（免费）')
    Add-RgoLine $sb 1 'price = price:rgo_change'
    Add-RgoLine $sb 1 'price_modifier = {'
    for ($i = 0; $i -lt $RGO_PRICE_TIERS.Count; $i++) {
        $t = $RGO_PRICE_TIERS[$i]
        $kw = if ($i -eq 0) { 'if' } else { 'else_if' }
        $factor = $t.factor.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        Add-RgoLine $sb 2 ($kw + ' = { limit = { RGO_price_tier_' + $t.tier + ' = yes } value = ' + $factor + ' }')
    }
    Add-RgoLine $sb 2 'else = {'
    Add-RgoLine $sb 3 'value = 0'
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
    Add-GoodsStep $sb $ids
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
# 2. 三个开关
# ============================================================
$tb = New-Object System.Text.StringBuilder
Add-RgoLine $tb 0 '# ============================================================'
Add-RgoLine $tb 0 '# 三个开关（与分类按钮同处局势面板的一张卡内，点击一次切换一次，免费）'
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
    Add-RgoLine $tb 1 '# 当前为开 -> 关闭；否则 -> 开启'
    Add-RgoLine $tb 1 'effect = {'
    Add-RgoLine $tb 2 'scope:actor ?= {'
    Add-RgoLine $tb 3 'if = {'
    Add-RgoLine $tb 4 ('limit = { ' + $d.check + ' = yes }')
    Add-RgoLine $tb 4 'set_variable = {'
    Add-RgoLine $tb 5 ('name = ' + $d.var)
    Add-RgoLine $tb 5 'value = 0'
    Add-RgoLine $tb 4 '}'
    if ($d.cleanup) { Add-RgoLine $tb 4 $d.cleanup }
    Add-RgoLine $tb 3 '}'
    Add-RgoLine $tb 3 'else = {'
    Add-RgoLine $tb 4 'set_variable = {'
    Add-RgoLine $tb 5 ('name = ' + $d.var)
    Add-RgoLine $tb 5 'value = 1'
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
Add-RgoLine $cb 0 '# --- 七个分类的默认按钮开关 ---'
foreach ($k in $RGO_DEFAULT_CATEGORIES.Keys) {
    $name = 'RGO_cfg_cat_' + $k + '_default'
    Add-RgoLine $cb 0 (($name.PadRight(30)) + ' = { always = ' + $RGO_DEFAULT_CATEGORIES[$k] + ' }')
}
Add-RgoLine $cb 0 ''
Add-RgoLine $cb 0 '# ============================================================'
Add-RgoLine $cb 0 '# 运行时判定（root 均为国家，可在任何国家作用域里直接调用）'
Add-RgoLine $cb 0 '# ============================================================'

$switchDefs = @(
    [pscustomobject]@{ trigger = 'RGO_cost_enabled';         var = 'rgo_var_cost';      default = 'RGO_cfg_cost_default' }
    [pscustomobject]@{ trigger = 'RGO_cooldown_enabled';     var = 'rgo_var_cooldown';  default = 'RGO_cfg_cooldown_default' }
    [pscustomobject]@{ trigger = 'RGO_cat_produced_enabled'; var = 'rgo_var_produced';  default = 'RGO_cfg_cat_produced_default' }
)
foreach ($s in $switchDefs) {
    Add-RgoLine $cb 0 ''
    Add-RgoLine $cb 0 ($s.trigger + ' = {')
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

$configText = $cb.ToString()
Write-RgoTextFile -Path $configFile -Text $configText -CheckOnly:$Check

# ============================================================
# 4. GUI 切片数字同步（分类数变化时不再需要手改 GUI）
# ============================================================
if (Test-Path -LiteralPath $guiFile) {
    $guiText = [System.IO.File]::ReadAllText($guiFile)
    $guiNew = [regex]::Replace($guiText, "'\(int32\)\d+'", "`'(int32)$catCount`'")
    Write-RgoTextFile -Path $guiFile -Text $guiNew -CheckOnly:$Check
    if ($guiNew -eq $guiText) {
        Write-Host ("[一致] GUI 切片数字 = " + $catCount)
    }
}
else {
    Write-Warning ("找不到 GUI 文件，跳过切片数字同步: " + $guiFile)
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
foreach ($k in $groups.Keys) {
    Write-Host ("  {0,-11} {1,3} 种  {2}" -f $k, $groups[$k].Count, ($groups[$k] -join ', '))
}
Write-Host ("分类动作 {0} 个 / 开关 {1} 个 / GUI 切片 {2}" -f $actionCount, $toggleCount, $catCount)

if ($actionCount -ne $catCount) { throw "分类动作数量（$actionCount）与分类数（$catCount）不一致" }
if ($toggleCount -ne $toggleDefs.Count) { throw "开关数量（$toggleCount）与开关表（$($toggleDefs.Count)）不一致" }
if ($Check) { Write-Host '校验通过：生成物与脚本数据一致。' }
