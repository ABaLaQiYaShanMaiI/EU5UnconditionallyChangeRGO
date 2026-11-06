# 一键启用 / 停用本 mod（用于 A/B 隔离测试）
# 用法：powershell -ExecutionPolicy Bypass -File "tools\toggle_mod.ps1"
# 停用后启动游戏 = 纯原版；再运行一次 = 恢复启用
#
# 停用时把模组文件夹移到 mod 目录之外（<用户数据>\_rgo_disabled\）：
#   游戏会挂载 mod 目录下含 in_game / main_menu 的子文件夹，
#   留在 mod 目录里（例如改名成 .disabled）仍然会被当成模组加载，A/B 测试无效。

$ErrorActionPreference = 'Stop'
$modName = 'UnconditionallyChangeRGO'

# 优先用系统“文档”目录，OneDrive 重定向时回退到 OneDrive 路径
$userMod = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Europa Universalis V\mod'
if (-not (Test-Path -LiteralPath $userMod)) {
    $alt = Join-Path $env:USERPROFILE 'OneDrive\文档\Paradox Interactive\Europa Universalis V\mod'
    if (Test-Path -LiteralPath $alt) { $userMod = $alt }
}
if (-not (Test-Path -LiteralPath $userMod)) {
    throw "找不到 EU5 mod 目录，请手动确认：$userMod"
}

$link = Join-Path $userMod $modName
$modFile = Join-Path $userMod ($modName + '.mod')
$modFileDisabled = Join-Path $userMod ($modName + '.mod.disabled')

$userRoot = Split-Path -Parent $userMod
$backupRoot = Join-Path $userRoot '_rgo_disabled'
$backup = Join-Path $backupRoot $modName
$junctionRecord = Join-Path $backupRoot 'junction-target.txt'

if (Test-Path -LiteralPath $link) {
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    if (Test-Path -LiteralPath $backup) { throw "已存在停用备份，请先手动检查：$backup" }

    $item = Get-Item -LiteralPath $link -Force
    if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
        # 只删链接，不动仓库
        Set-Content -LiteralPath $junctionRecord -Value ($item.Target -join ';') -Encoding UTF8
        $item.Attributes = [System.IO.FileAttributes]('Directory, ReparsePoint')
        cmd /c rmdir "$link" 2>&1 | Out-Null
        if (Test-Path -LiteralPath $link) { throw ('删除 Junction 失败: ' + $link) }
    }
    else {
        Move-Item -LiteralPath $link -Destination $backup
    }
    if (Test-Path -LiteralPath $modFile) { Move-Item -LiteralPath $modFile -Destination $modFileDisabled -Force }
    Write-Host '⏸  已停用本 mod —— 现在启动游戏是纯原版（模组已移到 _rgo_disabled，不在 mod 目录里）。'
}
else {
    if (Test-Path -LiteralPath $junctionRecord) {
        $target = (Get-Content -LiteralPath $junctionRecord -Raw).Trim()
        if (-not (Test-Path -LiteralPath $target)) { throw ('Junction 指向的仓库不存在: ' + $target) }
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        Remove-Item -LiteralPath $junctionRecord -Force
    }
    elseif (Test-Path -LiteralPath $backup) {
        Move-Item -LiteralPath $backup -Destination $link
    }
    else {
        throw "没有找到可恢复的备份，请手动检查：$backupRoot"
    }
    if (Test-Path -LiteralPath $modFileDisabled) { Move-Item -LiteralPath $modFileDisabled -Destination $modFile -Force }
    Write-Host '▶  已重新启用本 mod —— 记得在启动器播放集里勾选它。'
}

Write-Host ''
Write-Host '当前 mod 目录：'
Get-ChildItem $userMod | Select-Object Name | ForEach-Object { '  ' + $_.Name }
