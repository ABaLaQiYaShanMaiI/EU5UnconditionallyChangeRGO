$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
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
$referenced += @('RGO_GROUP_CATEGORIES', 'RGO_GROUP_SWITCHES', 'rgo_change', 'UnconditionallyChangeRGO', 'hint_UnconditionallyChangeRGO')
$referenced += ($referenced | Where-Object { $_ -like 'RGO_change_*' } | ForEach-Object { $_ + '_desc' })
$referenced += ($referenced | Where-Object { $_ -like 'RGO_toggle_*' } | ForEach-Object { $_ + '_desc' })
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
$slices = @([regex]::Matches($gui, "'\(int32\)(\d+)'") | ForEach-Object { $_.Groups[1].Value })
Check ("action count = " + $actions) ($actions -eq 7)
Check ("toggle count = " + $toggles) ($toggles -eq 3)
Check ("gui slices = " + ($slices -join '/')) (($slices.Count -eq 2) -and ($slices[0] -eq '7') -and ($slices[1] -eq '7'))

Write-Host ''
if ($fail -eq 0) { Write-Host "ALL CHECKS PASSED" } else { Write-Host ("FAILED: " + $fail); exit 1 }
