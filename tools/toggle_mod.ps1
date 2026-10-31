# 一键启用 / 停用本 mod（用于 A/B 隔离测试）
# 用法：powershell -ExecutionPolicy Bypass -File "tools\toggle_mod.ps1"
# 停用后启动游戏 = 纯原版；再运行一次 = 恢复启用

$ErrorActionPreference = 'Stop'
$modName = 'UnconditionallyChangeRGO'

# 优先用系统“文档”目录，OneDrive 重定向时回退到 OneDrive 路径
$userMod = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Paradox Interactive\Europa Universalis V\mod"
if (-not (Test-Path -LiteralPath $userMod)) {
    $alt = Join-Path $env:USERPROFILE "OneDrive\文档\Paradox Interactive\Europa Universalis V\mod"
    if (Test-Path -LiteralPath $alt) { $userMod = $alt }
}
if (-not (Test-Path -LiteralPath $userMod)) {
    throw "找不到 EU5 mod 目录，请手动确认：$userMod"
}

$link    = Join-Path $userMod $modName
$modFile = Join-Path $userMod ($modName + '.mod')
$disabled = Join-Path $userMod ($modName + '.disabled')
$modFileDisabled = Join-Path $userMod ($modName + '.mod.disabled')

if (Test-Path -LiteralPath $link) {
    Rename-Item -LiteralPath $link -NewName ($modName + '.disabled') -Force
    if (Test-Path -LiteralPath $modFile) { Rename-Item -LiteralPath $modFile -NewName ($modName + '.mod.disabled') -Force }
    Write-Host '⏸  已停用本 mod —— 现在启动游戏是纯原版，请观察是否仍然"未响应"。'
}
else {
    if (-not (Test-Path -LiteralPath $disabled)) { throw "没有找到可恢复的 $($modName).disabled，请手动检查：$userMod" }
    Rename-Item -LiteralPath $disabled -NewName $modName -Force
    if (Test-Path -LiteralPath $modFileDisabled) { Rename-Item -LiteralPath $modFileDisabled -NewName ($modName + '.mod') -Force }
    Write-Host '▶  已重新启用本 mod —— 记得在启动器播放集里勾选它。'
}

Write-Host ''
Write-Host '当前 mod 目录：'
Get-ChildItem $userMod | Select-Object Name | ForEach-Object { '  ' + $_.Name }
