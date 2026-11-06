# 在「开发模式（Junction → 仓库）」与「发布副本」之间切换，便于创意工坊上传 / 网盘打包。
#
#   -Install  开发模式 → 干净副本（删除指向仓库的 Junction，复制 dist，写入 .rgo-release）
#   -Restore  干净副本 → 开发模式（删除副本，重建指向仓库的 Junction）
#
# 为什么不再用 UnconditionallyChangeRGO.dev 备份：
#   游戏会扫描 mod 目录下的子文件夹并挂载其中的 in_game / main_menu，
#   .dev 留在 mod 目录里会被当成「第二个同名模组」一起加载
#   （debug.log: Mounted Data: .../UnconditionallyChangeRGO.dev/in_game），
#   导致两份脚本互相覆盖。所以备份一律不放在 mod 目录里。
#
# 依赖：先运行 tools\build_release.ps1（或 tools\deploy_local.ps1）生成 dist

param(
    [switch]$Install,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$modName = 'UnconditionallyChangeRGO'
$distDir = Join-Path $root ('dist\' + $modName)

# 定位游戏 mod 目录（兼容 OneDrive 重定向）
$modDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Europa Universalis V\mod'
if (-not (Test-Path -LiteralPath $modDir)) {
    $alt = Join-Path $env:USERPROFILE 'OneDrive\文档\Paradox Interactive\Europa Universalis V\mod'
    if (Test-Path -LiteralPath $alt) { $modDir = $alt }
}
if (-not (Test-Path -LiteralPath $modDir)) { throw "找不到 EU5 mod 目录: $modDir" }

$target = Join-Path $modDir $modName
$marker = Join-Path $target '.rgo-release'

if ($Install -and $Restore) { throw '一次只能用一个开关' }

# 安全删除 Junction / 符号链接（只删链接，不动仓库）
function Remove-ModLink([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType -ne 'Junction' -and $item.LinkType -ne 'SymbolicLink') {
        throw ('不是 Junction / 符号链接，拒绝执行: ' + $Path)
    }
    # OneDrive 会把目录标成 ReadOnly，cmd 的 rmdir 会报 Access denied
    $item.Attributes = [System.IO.FileAttributes]('Directory, ReparsePoint')
    cmd /c rmdir "$Path" 2>&1 | Out-Null
    if (Test-Path -LiteralPath $Path) { throw ('删除链接失败: ' + $Path) }
}

if ($Install) {
    if (-not (Test-Path -LiteralPath $distDir)) { throw "找不到 dist 目录，请先运行 tools\build_release.ps1" }
    if (-not (Test-Path -LiteralPath $target)) { throw "找不到当前 mod 目录: $target" }

    $item = Get-Item -LiteralPath $target -Force
    if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
        Write-Host ('[1/2] 删除指向仓库的链接（' + ($item.Target -join '; ') + '）...')
        Remove-ModLink $target
    }
    elseif (-not (Test-Path -LiteralPath $marker)) {
        throw ('目标目录既不是 Junction，也没有 .rgo-release 标记，为安全起见不替换: ' + $target)
    }

    Write-Host '[2/2] 复制干净副本 ...'
    & (Join-Path $PSScriptRoot 'deploy_local.ps1') -SkipBuild
    if (-not $?) { throw 'deploy_local.ps1 失败' }
    return
}

if ($Restore) {
    if (-not (Test-Path -LiteralPath $target)) { throw "找不到 mod 目录: $target" }
    if (-not (Test-Path -LiteralPath $marker)) { throw '目标不是发布副本（缺少 .rgo-release 标记），拒绝删除' }

    Write-Host '[1/2] 删除发布副本 ...'
    Remove-Item -LiteralPath $target -Recurse -Force

    Write-Host ('[2/2] 重建 Junction → ' + $root)
    New-Item -ItemType Junction -Path $target -Target $root | Out-Null

    Write-Host ''
    Write-Host '已恢复开发模式（mod 目录重新指向仓库）。'
    Write-Host '提交发布前请再运行 tools\deploy_local.ps1（或 switch_to_release.ps1 -Install）。'
    return
}

Write-Host '用法：'
Write-Host '  powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Install'
Write-Host '  powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Restore'
