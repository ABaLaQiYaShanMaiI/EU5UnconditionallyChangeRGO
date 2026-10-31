# 生成 in_game/common/generic_actions/00_rgo_actions.txt
# 数据来源：EU5 原版 common\goods\*.txt（游戏新增货物后重跑本脚本即可）
# 用法：powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_actions.ps1"

$ErrorActionPreference = 'Stop'

$modRoot   = Split-Path -Parent $PSScriptRoot
$goodsRoot = 'D:\Steam\steamapps\common\Europa Universalis V\game\in_game\common\goods'
$outFile   = Join-Path $modRoot 'in_game\common\generic_actions\00_rgo_actions.txt'

if (-not (Test-Path $goodsRoot)) { throw "找不到原版 goods 目录: $goodsRoot" }

# ---------- 1. 解析原版货物 ----------
$rows = @()
foreach ($n in @('00_raw_materials.txt','01_plantation_goods.txt','02_produced_goods.txt','03_food.txt','04_special.txt')) {
    $p = Join-Path $goodsRoot $n
    if (-not (Test-Path $p)) { continue }
    $cur = $null; $cat = 'raw_material'; $meth = 'farming'
    foreach ($line in Get-Content $p) {
        if ($line -cmatch '^([a-z_0-9]+)\s*=\s*\{') {
            if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $meth; file = $n } }
            $cur = $Matches[1]; $cat = 'raw_material'; $meth = 'farming'
        }
        elseif ($line -cmatch '^\s+category\s*=\s*([a-z_]+)') { $cat  = $Matches[1] }
        elseif ($line -cmatch '^\s+method\s*=\s*([a-z_]+)')   { $meth = $Matches[1] }
    }
    if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $meth; file = $n } }
}

function Pick($filter) {
    @($rows | Where-Object $filter | ForEach-Object { $_.id } | Sort-Object -Unique)
}

$groups = [ordered]@{}
$groups['mining']     = Pick { $_.method -eq 'mining' }
$groups['gathering']  = Pick { $_.method -eq 'gathering' }
$groups['crops']      = Pick { $_.file -eq '00_raw_materials.txt' -and $_.method -eq 'farming' }
$groups['food']       = Pick { $_.file -eq '03_food.txt' -and $_.method -eq 'farming' }
$groups['plantation'] = Pick { $_.file -eq '01_plantation_goods.txt' }
$groups['wild']       = Pick { $_.method -eq 'hunting' -or $_.method -eq 'forestry' }
$groups['industry']   = Pick { $_.cat -eq 'produced' }

foreach ($k in $groups.Keys) {
    if ($groups[$k].Count -eq 0) { throw "分类 $k 为空，解析失败" }
}

# ---------- 2. 公共片段 ----------
$situationStep = @"
	select_trigger = {
		looking_for_a = situation
		target_flag = recipient
		name = "choose_situation"
		column = { data = name }
		visible = {
			situation:UnconditionallyChangeRGO = this
			situation_is_active = yes
		}
	}
"@

$locationStep = @"
	# 3) 选地块：仅本国地块
	select_trigger = {
		looking_for_a = location
		target_flag = target_location
		name = "select_location"
		map_mode = raw_material
		column = { data = name }
		column = { data = raw_material }
		interaction_source_list = {
			scope:actor = {
				every_owned_location = {
					add_to_list = source
				}
			}
		}
	}
"@

function GoodsStep($ids) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("	# 2) 选原产物：本分类 $($ids.Count) 种")
    [void]$sb.AppendLine("	select_trigger = {")
    [void]$sb.AppendLine("		looking_for_a = goods")
    [void]$sb.AppendLine("		target_flag = target_good")
    [void]$sb.AppendLine("		name = `"select_goods`"")
    [void]$sb.AppendLine("		column = { data = name }")
    [void]$sb.AppendLine("		interaction_source_list = {")
    [void]$sb.AppendLine("			every_goods = {")
    [void]$sb.AppendLine("				limit = {")
    [void]$sb.AppendLine("					OR = {")
    foreach ($id in $ids) { [void]$sb.AppendLine("						this = goods:$id") }
    [void]$sb.AppendLine("					}")
    [void]$sb.AppendLine("				}")
    [void]$sb.AppendLine("				add_to_list = source")
    [void]$sb.AppendLine("			}")
    [void]$sb.AppendLine("		}")
    [void]$sb.AppendLine("	}")
    return $sb.ToString()
}

# ---------- 3. 变更动作 ----------
$out = New-Object System.Text.StringBuilder
[void]$out.AppendLine('########################################################################')
[void]$out.AppendLine('# 本文件由 tools\generate_rgo_actions.ps1 自动生成，请勿手改')
[void]$out.AppendLine('# 七大分类：矿物 / 采集 / 经济作物 / 食物 / 种植园 / 狩猎林业 / 工业品')
[void]$out.AppendLine('########################################################################')
[void]$out.AppendLine('')

foreach ($g in $groups.Keys) {
    $ids = $groups[$g]
    [void]$out.AppendLine("RGO_change_$g = {")
    [void]$out.AppendLine("	type = situation")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	ai_tick = never")
    [void]$out.AppendLine("	automation_tick = never")
    [void]$out.AppendLine("	show_message = no")
    [void]$out.AppendLine("	show_message_to_target = no")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	# 花费 = 基础价 x 所选货物的市场价系数（开关关闭时系数为 0，即免费）")
    [void]$out.AppendLine("	price = price:rgo_change")
    [void]$out.AppendLine("	price_modifier = {")
    [void]$out.AppendLine("		if = {")
    [void]$out.AppendLine("			limit = {")
    [void]$out.AppendLine("				scope:actor ?= { RGO_opt_cost = yes }")
    [void]$out.AppendLine("			}")
    [void]$out.AppendLine("			value = `"scope:target_good.price_in_market(scope:target_location.market)`"")
    [void]$out.AppendLine("			multiply = 0.5")
    [void]$out.AppendLine("			min = 0.5")
    [void]$out.AppendLine("			max = 6")
    [void]$out.AppendLine("		}")
    [void]$out.AppendLine("		else = {")
    [void]$out.AppendLine("			value = 0")
    [void]$out.AppendLine("		}")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	# 分类开关：关闭后本按钮消失")
    [void]$out.AppendLine("	potential = {")
    [void]$out.AppendLine("		scope:actor ?= {")
    [void]$out.AppendLine("			RGO_cat_" + $g + "_enabled = yes")
    [void]$out.AppendLine("		}")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	# 冷却开关：开启且冷却未结束时按钮不可用")
    [void]$out.AppendLine("	allow = {")
    [void]$out.AppendLine("		scope:actor ?= {")
    [void]$out.AppendLine("			NOT = { has_country_modifier = rgo_change_cooldown }")
    [void]$out.AppendLine("		}")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("")
    [void]$out.AppendLine($situationStep)
    [void]$out.AppendLine((GoodsStep $ids))
    [void]$out.AppendLine($locationStep)
    [void]$out.AppendLine("	effect = {")
    [void]$out.AppendLine("		RGO_apply_change = yes")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("}")
    [void]$out.AppendLine("")
}

# ---------- 4. 设置开关动作 ----------
$settings = @(
    @{ tag = 'cost';           trig = 'RGO_opt_cost';                var = 'rgo_opt_cost';           extra = $null },
    @{ tag = 'cooldown';       trig = 'RGO_opt_cooldown';            var = 'rgo_opt_cooldown';       extra = 'remove_country_modifier = rgo_change_cooldown' },
    @{ tag = 'cat_mining';     trig = 'RGO_cat_mining_enabled';      var = 'rgo_cat_mining';         extra = $null },
    @{ tag = 'cat_gathering';  trig = 'RGO_cat_gathering_enabled';   var = 'rgo_cat_gathering';      extra = $null },
    @{ tag = 'cat_crops';      trig = 'RGO_cat_crops_enabled';       var = 'rgo_cat_crops';          extra = $null },
    @{ tag = 'cat_food';       trig = 'RGO_cat_food_enabled';        var = 'rgo_cat_food';           extra = $null },
    @{ tag = 'cat_plantation'; trig = 'RGO_cat_plantation_enabled';  var = 'rgo_cat_plantation';     extra = $null },
    @{ tag = 'cat_wild';       trig = 'RGO_cat_wild_enabled';        var = 'rgo_cat_wild';           extra = $null },
    @{ tag = 'cat_industry';   trig = 'RGO_cat_industry_enabled';    var = 'rgo_cat_industry';       extra = $null }
)

[void]$out.AppendLine('########################################################################')
[void]$out.AppendLine('# 设置开关：点一次切换一次，免费')
[void]$out.AppendLine('########################################################################')
[void]$out.AppendLine('')

foreach ($s in $settings) {
    [void]$out.AppendLine("RGO_toggle_$($s.tag) = {")
    [void]$out.AppendLine("	type = situation")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	ai_tick = never")
    [void]$out.AppendLine("	automation_tick = never")
    [void]$out.AppendLine("	show_message = no")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	potential = {")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("	allow = {")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("")
    [void]$out.AppendLine($situationStep)
    [void]$out.AppendLine("	effect = {")
    [void]$out.AppendLine("		scope:actor ?= {")
    [void]$out.AppendLine("			if = {")
    [void]$out.AppendLine("				limit = {")
    [void]$out.AppendLine("					$($s.trig) = yes")
    [void]$out.AppendLine("				}")
    [void]$out.AppendLine("				set_variable = {")
    [void]$out.AppendLine("					name = $($s.var)")
    [void]$out.AppendLine("					value = 0")
    [void]$out.AppendLine("				}")
    if ($s.extra) { [void]$out.AppendLine("				$($s.extra)") }
    [void]$out.AppendLine("			}")
    [void]$out.AppendLine("			else = {")
    [void]$out.AppendLine("				set_variable = {")
    [void]$out.AppendLine("					name = $($s.var)")
    [void]$out.AppendLine("					value = 1")
    [void]$out.AppendLine("				}")
    [void]$out.AppendLine("			}")
    [void]$out.AppendLine("		}")
    [void]$out.AppendLine("	}")
    [void]$out.AppendLine("}")
    [void]$out.AppendLine("")
}

# ---------- 5. 写出（UTF-8 BOM） ----------
$dir = Split-Path -Parent $outFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
[System.IO.File]::WriteAllText($outFile, $out.ToString(), (New-Object System.Text.UTF8Encoding($true)))

Write-Host "已生成: $outFile"
foreach ($k in $groups.Keys) {
    Write-Host ("  {0,-11} {1,3} 种: {2}" -f $k, $groups[$k].Count, ($groups[$k] -join ', '))
}
Write-Host ("动作数: {0}（变更 {1} + 设置 {2}）" -f ($groups.Count + $settings.Count), $groups.Count, $settings.Count)
