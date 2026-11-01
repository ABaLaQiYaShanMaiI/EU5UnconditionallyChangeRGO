# 在「开发模式（Junction）」与「发布副本」之间切换，便于创意工坊上传
#
#   -Install  备份当前 Junction 为 UnconditionallyChangeRGO.dev，换上 dist 里的干净副本
#   -Restore  删除干净副本，恢复 .dev 的 Junction
#
# 依赖：先运行 tools\build_release.ps1 生成 dist

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
$backup = Join-Path $modDir ($modName + '.dev')
$marker = Join-Path $target '.rgo-release'

if ($Install -and $Restore) { throw '一次只能用一个开关' }

if ($Install) {
    if (-not (Test-Path -LiteralPath $distDir)) { throw "找不到 dist 目录，请先运行 tools\build_release.ps1" }
    if (-not (Test-Path -LiteralPath $target)) { throw "找不到当前 mod 目录: $target" }
    if (Test-Path -LiteralPath $backup) { throw "已存在备份目录 $backup，请先运行 -Restore" }

    Write-Host '[1/3] 备份当前 mod 目录（Junction）...'
    Rename-Item -LiteralPath $target -NewName ($modName + '.dev') -Force

    Write-Host '[2/3] 复制干净副本 ...'
    Copy-Item -LiteralPath $distDir -Destination $target -Recurse -Force

    Write-Host '[3/3] 写入发布标记 ...'
    Set-Content -LiteralPath (Join-Path $target '.rgo-release') -Value "release build of $modName" -Encoding UTF8

    Write-Host ''
    Write-Host '已切换到发布副本。现在打开启动器上传到创意工坊。'
    Write-Host '上传完成后运行： powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Restore'
    return
}

if ($Restore) {
    if (-not (Test-Path -LiteralPath $target)) { throw "找不到 mod 目录: $target" }
    if (-not (Test-Path -LiteralPath $marker)) { throw '目标不是发布副本（缺少 .rgo-release 标记），拒绝删除' }
    if (-not (Test-Path -LiteralPath $backup)) { throw "找不到备份目录 $backup，无法恢复开发模式" }

    Write-Host '[1/2] 删除发布副本 ...'
    Remove-Item -LiteralPath $target -Recurse -Force

    Write-Host '[2/2] 恢复开发模式（Junction）...'
    Rename-Item -LiteralPath $backup -NewName $modName -Force

    Write-Host ''
    Write-Host '已恢复开发模式（mod 目录重新指向仓库）。'
    return
}

Write-Host '用法：'
Write-Host '  powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Install'
Write-Host '  powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Restore'
