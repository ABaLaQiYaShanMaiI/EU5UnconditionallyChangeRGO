# 一键启用 / 停用本 mod（用于 A/B 隔离测试）
# 用法：powershell -ExecutionPolicy Bypass -File "tools\toggle_mod.ps1"
# 停用后启动游戏 = 纯原版；再运行一次 = 恢复启用

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
$userMod = Join-Path $env:USERPROFILE 'OneDrive\文档\Paradox Interactive\Europa Universalis V\mod'
$link    = Join-Path $userMod 'UnconditionallyChangeRGO'
$modFile = Join-Path $userMod 'UnconditionallyChangeRGO.mod'

if (Test-Path $link) {
    Rename-Item -LiteralPath $link -NewName 'UnconditionallyChangeRGO.disabled' -Force
    if (Test-Path $modFile) { Rename-Item -LiteralPath $modFile -NewName 'UnconditionallyChangeRGO.mod.disabled' -Force }
    Write-Host '⏸  已停用本 mod —— 现在启动游戏是纯原版，请观察是否仍然"未响应"。'
} else {
    Rename-Item -LiteralPath (Join-Path $userMod 'UnconditionallyChangeRGO.disabled') -NewName 'UnconditionallyChangeRGO' -Force
    $dis = Join-Path $userMod 'UnconditionallyChangeRGO.mod.disabled'
    if (Test-Path $dis) { Rename-Item -LiteralPath $dis -NewName 'UnconditionallyChangeRGO.mod' -Force }
    Write-Host '▶  已重新启用本 mod —— 记得在启动器播放集里勾选它。'
}

Write-Host ''
Write-Host '当前 mod 目录：'
Get-ChildItem $userMod | Select-Object Name | ForEach-Object { '  ' + $_.Name }
