# 把 dist 里的干净发布副本部署到游戏 mod 目录（本地测试与创意工坊上传用的都是这一份）。
#
# 与 switch_to_release.ps1 的分工：
#   switch_to_release.ps1 -Install   开发模式（Junction）→ 干净副本（把 Junction 备份成 .dev）
#   switch_to_release.ps1 -Restore   干净副本 → 开发模式 Junction
#   deploy_local.ps1（本脚本）        刷新「干净副本」的内容，不动 .dev 的 Junction 备份
#
# 安全约束：
#   - 目标是 Junction / 符号链接时拒绝执行（避免误删仓库内容），请改用 switch_to_release.ps1
#   - 替换前先把旧目录改名成 .bak-<时间戳>，校验新副本与 dist 完全一致后才删除备份
#
# 用法（在仓库根目录执行）：
#   powershell -ExecutionPolicy Bypass -File "tools\deploy_local.ps1"
#   powershell ... -SkipBuild     不重新构建 dist，直接部署现有 dist

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$modName = 'UnconditionallyChangeRGO'
$distDir = Join-Path $root ('dist\' + $modName)
$distMod = Join-Path $root ('dist\' + $modName + '.mod')
$metaPath = Join-Path $root ('.metadata\metadata.json')

if (-not $SkipBuild) {
    Write-Host '[1/4] 构建 dist（含校验 + 打包）...'
    & (Join-Path $PSScriptRoot 'build_release.ps1') | Out-Null
    if (-not $?) { throw 'build_release.ps1 失败，已中止部署' }
}
else {
    Write-Host '[1/4] 跳过构建'
}

if (-not (Test-Path -LiteralPath $distDir)) { throw "找不到 dist 目录: $distDir（先运行 build_release.ps1）" }
if (-not (Test-Path -LiteralPath $distMod)) { throw "找不到 mod 描述文件: $distMod" }

$version = '?'
if (Test-Path -LiteralPath $metaPath) {
    $version = (Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json).version
}

# 定位游戏 mod 目录（兼容 OneDrive 重定向）
$modDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Europa Universalis V\mod'
if (-not (Test-Path -LiteralPath $modDir)) {
    $alt = Join-Path $env:USERPROFILE 'OneDrive\文档\Paradox Interactive\Europa Universalis V\mod'
    if (Test-Path -LiteralPath $alt) { $modDir = $alt }
}
if (-not (Test-Path -LiteralPath $modDir)) { throw "找不到 EU5 mod 目录: $modDir" }

$target = Join-Path $modDir $modName
$modFile = Join-Path $modDir ($modName + '.mod')
Write-Host ('[2/4] 目标: ' + $target)

# 安全：Junction / 符号链接一律拒绝（删除它会波及仓库）
if (Test-Path -LiteralPath $target) {
    $item = Get-Item -LiteralPath $target -Force
    if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
        throw ('目标是 ' + $item.LinkType + '（指向 ' + ($item.Target -join '; ') + '），拒绝删除。请改用 switch_to_release.ps1 -Install')
    }
}

# 旧副本先改名备份，校验通过后再删除
$backup = $null
if (Test-Path -LiteralPath $target) {
    $backup = Join-Path $modDir ($modName + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Rename-Item -LiteralPath $target -NewName (Split-Path -Leaf $backup)
    Write-Host ('      旧副本已备份为 ' + (Split-Path -Leaf $backup))
}

Copy-Item -LiteralPath $distDir -Destination $target -Recurse -Force
Copy-Item -LiteralPath $distMod -Destination $modFile -Force
Set-Content -LiteralPath (Join-Path $target '.rgo-release') -Value ('release build of ' + $modName + ' ' + $version) -Encoding UTF8

# 校验：部署目录必须与 dist 逐文件一致
Write-Host '[3/4] 校验部署结果 ...'
$diff = @()
$files = @(Get-ChildItem -LiteralPath $distDir -Recurse -File)
foreach ($f in $files) {
    $rel = $f.FullName.Substring($distDir.Length)
    $other = Join-Path $target $rel
    if (-not (Test-Path -LiteralPath $other)) { $diff += ('missing:' + $rel) }
    elseif ((Get-FileHash -LiteralPath $other).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) { $diff += ('hash:' + $rel) }
}
if ($diff.Count -gt 0) {
    throw ('部署校验失败（' + $diff.Count + ' 项）: ' + (($diff | Select-Object -First 5) -join ', ') + '。备份保留在 ' + $backup)
}
if ($backup -and (Test-Path -LiteralPath $backup)) { Remove-Item -LiteralPath $backup -Recurse -Force }

$modVersion = '?'
if (Test-Path -LiteralPath $modFile) { if ((Get-Content -LiteralPath $modFile -Raw) -match 'version="([^"]+)"') { $modVersion = $Matches[1] } }

Write-Host ('[4/4] 已部署 ' + $files.Count + ' 个文件，版本 ' + $version + '（启动器 .mod: ' + $modVersion + '）')
Write-Host ''
Write-Host '下一步：'
Write-Host '  1) 启动器 → 模组：确认「原产物无限制全修改」已勾进播放集（列表里应是刚才的版本）'
Write-Host '  2) 进游戏测试；有报错就看 文档\Paradox Interactive\Europa Universalis V\logs\error.log'
Write-Host '  3) 测试通过后可直接在启动器里「上传/更新」创意工坊（当前目录就是干净副本）'
Write-Host '  4) 想回到开发模式（Junction → 仓库）：'
Write-Host '       powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Restore'
