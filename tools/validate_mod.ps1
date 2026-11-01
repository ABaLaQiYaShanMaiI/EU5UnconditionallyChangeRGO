$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
# 数量、开关表、默认值的唯一真值源
. (Join-Path $PSScriptRoot 'rgo_common.ps1')
$catCount = @($RGO_GROUP_ORDER).Count
$fail = 0

function Check($name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host ("[PASS] " + $name) }
    else { Write-Host ("[FAIL] " + $name + " " + $detail); $script:fail++ }
}

# 1. generated files up to date
& "$PSScriptRoot\generate_rgo_actions.ps1" -Check | Out-Null
Check "generate_rgo_actions -Check" $?
& "$PSScriptRoot\generate_rgo_localization.ps1" -Check | Out-Null
Check "generate_rgo_localization -Check" $?

# 2. localization key parity + line format
$langs = @('english', 'braz_por', 'french', 'german', 'spanish', 'polish', 'russian', 'turkish', 'japanese', 'korean', 'simp_chinese')
$keySets = @{}
$badLines = @()
$placeholders = @()
foreach ($l in $langs) {
    $p = Join-Path $root ("in_game\localization\{0}\UnconditionallyChangeRGO_l_{0}.yml" -f $l)
    Check ("loc file exists: " + $l) (Test-Path $p)
    $keys = @()
    foreach ($line in [System.IO.File]::ReadAllLines($p)) {
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
        if ($line -match '^\s*l_[a-z_]+:\s*$') { continue }
        if ($line -notmatch '^\s*([A-Za-z_0-9]+):\d*\s+".*"\s*$') { $badLines += ($l + ': ' + $line); continue }
        $keys += $Matches[1]
        if ($line -match '\{[a-z]+\}') { $placeholders += ($l + ': ' + $line) }
    }
    $keySets[$l] = @($keys | Sort-Object)
}
$ref = $keySets['english']
foreach ($l in $langs) {
    $diff = Compare-Object $ref $keySets[$l]
    Check ("loc key parity: " + $l) ($null -eq $diff) (($diff | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ', ')
}
Check "loc lines well formed" ($badLines.Count -eq 0) ($badLines -join ' | ')
Check "no unresolved placeholders" ($placeholders.Count -eq 0) ($placeholders -join ' | ')

# 3. stale identifiers / old keys
$stale = @('RGO_opt_cost', 'RGO_opt_cooldown', 'RGO_cat_industry', 'RGO_change_industry', 'RGO_toggle_cat_industry', 'trigger_no_', 'RGO_CARD_TITLE', 'RGO_cat_mining_enabled', 'rgo_opt_')
$hits = @()
foreach ($f in (Get-ChildItem (Join-Path $root 'in_game') -Recurse -File)) {
    # (no-op)
    if ($f.Extension -notin @('.txt', '.gui', '.yml', '.mod')) { continue }
    $text = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($s in $stale) {
        if ($text.Contains($s)) { $hits += ($f.Name + ' -> ' + $s) }
    }
}
Check "no stale identifiers" ($hits.Count -eq 0) ($hits -join ' | ')

$bareSelect = @()
foreach ($f in (Get-ChildItem (Join-Path $root 'in_game\localization') -Recurse -File)) {
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
        if ($line -match '^\s*(select_goods|select_location):') { $bareSelect += $f.Name }
    }
}
Check "no bare select_* keys" ($bareSelect.Count -eq 0) ($bareSelect -join ', ')

# 3b. localization header must start at column 0; none_available_msg_key needs @trigger_no!
$badHeader = @()
$badNoKey = @()
foreach ($l in $langs) {
    $p = Join-Path $root ("in_game\localization\{0}\UnconditionallyChangeRGO_l_{0}.yml" -f $l)
    $first = [System.IO.File]::ReadAllLines($p)[0]
    if ($first -notmatch '^l_[a-z_]+:\s*$') { $badHeader += ($l + ': [' + $first + ']') }
    $text = [System.IO.File]::ReadAllText($p)
    if ($text -notmatch 'RGO_no_goods_available:0\s+"@trigger_no!') { $badNoKey += ($l + ':goods') }
    if ($text -notmatch 'RGO_no_locations_available:0\s+"@trigger_no!') { $badNoKey += ($l + ':locations') }
}
Check "loc header starts at column 0" ($badHeader.Count -eq 0) ($badHeader -join ' | ')
Check "no-target keys use @trigger_no!" ($badNoKey.Count -eq 0) ($badNoKey -join ' | ')

# 4. every key referenced by script exists in every language
$scriptText = ''
foreach ($f in (Get-ChildItem (Join-Path $root 'in_game') -Recurse -File -Include *.txt, *.gui)) {
    if ($f.Directory.Name -eq 'localization') { continue }
    $scriptText += [System.IO.File]::ReadAllText($f.FullName) + "`n"
}
$referenced = @()
$referenced += [regex]::Matches($scriptText, '(?m)^\s*name = "([A-Za-z_0-9]+)"') | ForEach-Object { $_.Groups[1].Value }
$referenced += [regex]::Matches($scriptText, 'none_available_msg_key = "([A-Za-z_0-9]+)"') | ForEach-Object { $_.Groups[1].Value }
$referenced += [regex]::Matches($scriptText, '(?m)^RGO_change_[a-z_]+ = \{') | ForEach-Object { $_.Value.Replace(' = {', '') }
$referenced += [regex]::Matches($scriptText, '(?m)^RGO_toggle_[a-z_]+ = \{') | ForEach-Object { $_.Value.Replace(' = {', '') }
$referenced += @('rgo_change', 'UnconditionallyChangeRGO', 'hint_UnconditionallyChangeRGO', 'RGO_toggle_state_on', 'RGO_toggle_state_off', 'RGO_CARD_HEADER')
$referenced += ($referenced | Where-Object { $_ -like 'RGO_change_*' } | ForEach-Object { $_ + '_desc' })
$referenced += ($referenced | Where-Object { $_ -like 'RGO_toggle_*' -and $_ -notlike 'RGO_toggle_state_*' } | ForEach-Object { $_ + '_desc' })
$referenced += @('UnconditionallyChangeRGO_desc', 'hint_UnconditionallyChangeRGO_hint_text', 'STATIC_MODIFIER_NAME_rgo_change_cooldown', 'STATIC_MODIFIER_DESC_rgo_change_cooldown')
$referenced += ($referenced | Where-Object { $_ -eq 'choose_situation' } | ForEach-Object { $_ })
$referenced = @($referenced | Where-Object { $_ -ne 'choose_situation' } | Sort-Object -Unique)
$missingKeys = @()
foreach ($l in $langs) {
    foreach ($k in $referenced) {
        if ($keySets[$l] -notcontains $k) { $missingKeys += ($l + ':' + $k) }
    }
}
Check ("all referenced keys localized (" + $referenced.Count + " keys x 11 langs)") ($missingKeys.Count -eq 0) ($missingKeys -join ', ')

# 5. brace balance + BOM
$unbalanced = @()
$noBom = @()
foreach ($f in (Get-ChildItem (Join-Path $root 'in_game') -Recurse -File -Include *.txt, *.gui, *.yml)) {
    $text = [System.IO.File]::ReadAllText($f.FullName)
    $lines = $text -split "`r?`n"
    $open = 0
    foreach ($line in $lines) {
        $code = $line -replace '#.*$', ''
        $open += ([regex]::Matches($code, '\{')).Count
        $open -= ([regex]::Matches($code, '\}')).Count
    }
    if ($open -ne 0) { $unbalanced += ($f.Name + '=' + $open) }
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) { $noBom += $f.Name }
}
Check "braces balanced" ($unbalanced.Count -eq 0) ($unbalanced -join ', ')
Check "UTF-8 BOM present" ($noBom.Count -eq 0) ($noBom -join ', ')

# 6. counts
$actions = [regex]::Matches($scriptText, '(?m)^RGO_change_[a-z_]+ = \{').Count
$toggles = [regex]::Matches($scriptText, '(?m)^RGO_toggle_[a-z_]+ = \{').Count
$gui = [System.IO.File]::ReadAllText((Join-Path $root 'in_game\gui\panels\situation\UnconditionallyChangeRGO.gui'))
$catSlices = @([regex]::Matches($gui, "DataModelSubSpan\(ActionGroup\.GetActions, '\(int32\)(\d+)', '\(int32\)1'\)") | ForEach-Object { [int]$_.Groups[1].Value })
$toggleSlices = @([regex]::Matches($gui, "DataModelSubSpan\(ActionGroup\.GetActions, Subtract_int32\(GetDataModelSize\(ActionGroup\.GetActions\), '\(int32\)(\d+)'\), '\(int32\)1'\)") | ForEach-Object { [int]$_.Groups[1].Value })
$catRows = [int][Math]::Ceiling($catCount / 2)
$rowGuards = @([regex]::Matches($gui, 'GreaterThan_int32\(GetDataModelSize\(ActionGroup\.GetActions\), .\(int32\)(\d+).\)') | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object)
$expectedGuards = @(1..($catRows - 1) | ForEach-Object { $RGO_TOGGLE_COUNT + 2 * $_ } | Sort-Object)
Check ("gui: category rows gated " + ($expectedGuards -join '/')) (($rowGuards.Count -eq $expectedGuards.Count) -and ($null -eq (Compare-Object $expectedGuards $rowGuards)))
$catGaps = @(0..($catCount - 1) | Where-Object { $catSlices -notcontains $_ })
$toggleGaps = @(1..$RGO_TOGGLE_COUNT | Where-Object { $toggleSlices -notcontains $_ })
Check ("action count = " + $actions) ($actions -eq $catCount)
Check ("toggle count = " + $toggles) ($toggles -eq $RGO_TOGGLE_COUNT)
Check "gui: no hardcoded index slicing" (-not ($gui -match 'DataModel(First|SkipFirst)\(ActionGroup\.GetActions'))
Check "gui: overrides action list" ($gui -match 'blockoverride\s+"situation_card_action_list"')
Check "gui: native card disabled" ($gui -match 'blockoverride\s+"situation_panel_main_actions"')
Check "gui: group gap present" ($gui -match 'size = \{ -1 18 \}')
Check "gui: card header overridden" (($gui -match 'blockoverride\s+"card_header_text"') -and ($gui -match 'blockoverride\s+"card_header_icon"'))
Check ("gui: two-column categories = " + $catCount) (($catSlices.Count -eq $catCount) -and ($catGaps.Count -eq 0))
Check ("gui: two-column switches = " + $RGO_TOGGLE_COUNT) (($toggleSlices.Count -eq $RGO_TOGGLE_COUNT) -and ($toggleGaps.Count -eq 0))

# 7. gameplay guards: AI disabled, location validity, geo switch, price cost-modifier type
$actionsText = [System.IO.File]::ReadAllText((Join-Path $root 'in_game\common\generic_actions\00_rgo_actions.txt'))
$togglesText = [System.IO.File]::ReadAllText((Join-Path $root 'in_game\common\generic_actions\01_rgo_toggles.txt'))
$configText  = [System.IO.File]::ReadAllText((Join-Path $root 'in_game\common\scripted_triggers\00_rgo_config.txt'))
$allActions = $actionsText + "`n" + $togglesText
$aiNever = [regex]::Matches($allActions, '(?m)^\tai_tick = never').Count
$autoNever = [regex]::Matches($allActions, '(?m)^\tautomation_tick = never').Count
$expectedActions = $catCount + $RGO_TOGGLE_COUNT
Check ("AI disabled: ai_tick=never x" + $aiNever) ($aiNever -eq $expectedActions)
Check ("AI disabled: automation_tick=never x" + $autoNever) ($autoNever -eq $expectedActions)
Check "no ai_will_do / ai_prerequisite" (-not ($allActions -match 'ai_will_do|ai_prerequisite|player_automated_category'))
$geoGateCalls = [regex]::Matches($actionsText, 'RGO_geo_allows_target = yes').Count
Check ("geo gate used by every action x" + $geoGateCalls) ($geoGateCalls -eq $catCount)
Check "geo gate keeps vanilla location_potential" ($configText -match 'is_goods_valid_for_location = scope:target_good')
Check "geo gate honours the geo switch" (($configText -match '(?m)^RGO_geo_allows_target = \{') -and ($configText -match 'RGO_geo_enabled = yes'))
Check "geo restriction off by default" ($configText -match 'RGO_cfg_geo_default = \{ always = no \}')
Check "location filtered by current raw material" ([regex]::Matches($actionsText, 'NOT = \{ raw_material \?= scope:target_good \}').Count -eq $catCount)
$modType = Join-Path $root 'main_menu\common\modifier_type_definitions\00_rgo_modifier_types.txt'
Check "price cost-modifier type defined" ((Test-Path $modType) -and ([System.IO.File]::ReadAllText($modType) -match 'rgo_change_cost_modifier'))
Check "gui: hint button present" ($gui -match "selected_hint = hint_UnconditionallyChangeRGO")
Check "loc: switch state keys present" (@(foreach ($l in $langs) {
            $p = Join-Path $root ("in_game\localization\{0}\UnconditionallyChangeRGO_l_{0}.yml" -f $l)
            $text = [System.IO.File]::ReadAllText($p)
            if (-not ($text -match 'RGO_toggle_state_on:0' -and $text -match 'RGO_toggle_state_off:0')) { $l }
        }).Count -eq 0)

Write-Host ''
if ($fail -eq 0) { Write-Host "ALL CHECKS PASSED" } else { Write-Host ("FAILED: " + $fail); exit 1 }
