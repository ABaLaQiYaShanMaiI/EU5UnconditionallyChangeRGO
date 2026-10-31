# 生成「原产物开关」的决议文件 + 决议分类
# 输出：
#   in_game\common\decision_categories\00_rgo_categories.txt
#   in_game\common\decisions\00_rgo_switches.txt
# 用法：powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_switches.ps1"

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot

$catFile = Join-Path $modRoot 'in_game\common\decision_categories\00_rgo_categories.txt'
$decFile = Join-Path $modRoot 'in_game\common\decisions\00_rgo_switches.txt'

# tag（复用 loc 键） / 判定 trigger / 国家变量 / 关闭时的额外处理
$switches = @(
    @{ tag = 'RGO_toggle_cost';        trig = 'RGO_opt_cost';            var = 'rgo_opt_cost';        extra = $null },
    @{ tag = 'RGO_toggle_cooldown';    trig = 'RGO_opt_cooldown';        var = 'rgo_opt_cooldown';    extra = 'remove_country_modifier = rgo_change_cooldown' },
    @{ tag = 'RGO_toggle_cat_mining';  trig = 'RGO_cat_mining_enabled';  var = 'rgo_cat_mining';      extra = $null },
    @{ tag = 'RGO_toggle_cat_gathering'; trig = 'RGO_cat_gathering_enabled'; var = 'rgo_cat_gathering'; extra = $null },
    @{ tag = 'RGO_toggle_cat_crops';   trig = 'RGO_cat_crops_enabled';   var = 'rgo_cat_crops';       extra = $null },
    @{ tag = 'RGO_toggle_cat_food';    trig = 'RGO_cat_food_enabled';    var = 'rgo_cat_food';        extra = $null },
    @{ tag = 'RGO_toggle_cat_plantation'; trig = 'RGO_cat_plantation_enabled'; var = 'rgo_cat_plantation'; extra = $null },
    @{ tag = 'RGO_toggle_cat_wild';    trig = 'RGO_cat_wild_enabled';    var = 'rgo_cat_wild';        extra = $null },
    @{ tag = 'RGO_toggle_cat_industry'; trig = 'RGO_cat_industry_enabled'; var = 'rgo_cat_industry';  extra = $null }
)

# ---------- 决议分类 ----------
$cat = @"
# 由 tools\generate_rgo_switches.ps1 自动生成
rgo_switches = {
	name_key = RGO_DECISION_CATEGORY
	sort_order = 90
}
"@

# ---------- 决议本体 ----------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# 由 tools\generate_rgo_switches.ps1 自动生成：原产物开关（每个决议点击一次即切换）')
[void]$sb.AppendLine('# 与局势面板里的 7 个分类按钮分开：这里是「开关」，那里是「分类」')
[void]$sb.AppendLine('')

foreach ($s in $switches) {
    [void]$sb.AppendLine("$($s.tag) = {")
    [void]$sb.AppendLine("	decision_category = rgo_switches")
    [void]$sb.AppendLine("	image = `"gfx/interface/icons/situations/UnconditionallyChangeRGO.dds`"")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("	potential = {")
    [void]$sb.AppendLine("		always = yes")
    [void]$sb.AppendLine("	}")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("	allow = {")
    [void]$sb.AppendLine("		always = yes")
    [void]$sb.AppendLine("	}")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("	ai_will_do = {")
    [void]$sb.AppendLine("		value = 0")
    [void]$sb.AppendLine("	}")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("	option = {")
    [void]$sb.AppendLine("		name = $($s.tag).a")
    [void]$sb.AppendLine("		ai_chance = { value = 0 }")
    [void]$sb.AppendLine("		effect = {")
    [void]$sb.AppendLine("			if = {")
    [void]$sb.AppendLine("				limit = { $($s.trig) = yes }")
    [void]$sb.AppendLine("				set_variable = {")
    [void]$sb.AppendLine("					name = $($s.var)")
    [void]$sb.AppendLine("					value = 0")
    [void]$sb.AppendLine("				}")
    if ($s.extra) { [void]$sb.AppendLine("				$($s.extra)") }
    [void]$sb.AppendLine("			}")
    [void]$sb.AppendLine("			else = {")
    [void]$sb.AppendLine("				set_variable = {")
    [void]$sb.AppendLine("					name = $($s.var)")
    [void]$sb.AppendLine("					value = 1")
    [void]$sb.AppendLine("				}")
    [void]$sb.AppendLine("			}")
    [void]$sb.AppendLine("		}")
    [void]$sb.AppendLine("	}")
    [void]$sb.AppendLine("}")
    [void]$sb.AppendLine("")
}

# ---------- 一键重置 ----------
$resetVars = @('rgo_opt_cost','rgo_opt_cooldown','rgo_cat_mining','rgo_cat_gathering','rgo_cat_crops','rgo_cat_food','rgo_cat_plantation','rgo_cat_wild','rgo_cat_industry')

[void]$sb.AppendLine("RGO_toggle_reset = {")
[void]$sb.AppendLine("	decision_category = rgo_switches")
[void]$sb.AppendLine("	image = `"gfx/interface/icons/situations/UnconditionallyChangeRGO.dds`"")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("	potential = {")
[void]$sb.AppendLine("		always = yes")
[void]$sb.AppendLine("	}")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("	allow = {")
[void]$sb.AppendLine("		always = yes")
[void]$sb.AppendLine("	}")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("	ai_will_do = {")
[void]$sb.AppendLine("		value = 0")
[void]$sb.AppendLine("	}")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("	option = {")
[void]$sb.AppendLine("		name = RGO_toggle_reset.a")
[void]$sb.AppendLine("		ai_chance = { value = 0 }")
[void]$sb.AppendLine("		effect = {")
foreach ($v in $resetVars) {
    [void]$sb.AppendLine("			if = {")
    [void]$sb.AppendLine("				limit = { has_variable = $v }")
    [void]$sb.AppendLine("				remove_variable = $v")
    [void]$sb.AppendLine("			}")
}
[void]$sb.AppendLine("			remove_country_modifier = rgo_change_cooldown")
[void]$sb.AppendLine("		}")
[void]$sb.AppendLine("	}")
[void]$sb.AppendLine("}")

foreach ($p in @($catFile, $decFile)) {
    $d = Split-Path -Parent $p
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

[System.IO.File]::WriteAllText($catFile, $cat, (New-Object System.Text.UTF8Encoding($true)))
[System.IO.File]::WriteAllText($decFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))

Write-Host "已生成: $catFile"
Write-Host "已生成: $decFile"
Write-Host ("决议数: {0}（开关 {1} + 重置 1）" -f ($switches.Count + 1), $switches.Count)
