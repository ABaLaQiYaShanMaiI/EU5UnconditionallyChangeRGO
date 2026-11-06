# 构建「网盘分享」安装包：dist\UnconditionallyChangeRGO_v<版本>_网盘安装包.zip
#
# 与 build_release.ps1 的区别：
#   build_release 产出的是「创意工坊用」的目录 / zip（只有模组文件夹）；
#   本脚本产出的是「给玩家手动安装」的包，额外把 UnconditionallyChangeRGO.mod
#   一起打进去 —— 没有这个 .mod 文件，启动器扫不到模组。
#
# 包内结构（解压到 mod 目录后直接就是启动器要的布局）：
#   UnconditionallyChangeRGO\          模组本体
#   UnconditionallyChangeRGO.mod       启动器识别用的描述文件
#   安装说明.txt                        给玩家的放置路径说明（放好后可删）
#
# 用法（仓库根目录）：
#   powershell -ExecutionPolicy Bypass -File "tools\build_share.ps1"
#   powershell ... -SkipValidation   跳过发布前校验
#   powershell ... -NoZip            只生成 dist\_share 目录，不打包（便于检查）
#
# 输出：
#   dist\UnconditionallyChangeRGO_v<版本>_网盘安装包.zip
#   dist\网盘分享说明.txt              可直接粘到网盘简介 / 群公告

param(
    [switch]$NoZip,
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $root 'dist'
$modName = 'UnconditionallyChangeRGO'
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

# ---------- 1. 元数据 ----------
$metaPath = Join-Path $root '.metadata\metadata.json'
if (-not (Test-Path -LiteralPath $metaPath)) { throw "找不到元数据: $metaPath" }
$meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
if ($meta.id -ne $modName) { throw "metadata.id ($($meta.id)) 与目录名 ($modName) 不一致" }
$version = $meta.version
if (-not $version) { throw 'metadata.json 里没有 version' }

# ---------- 2. 复用 build_release 生成干净目录 + .mod ----------
Write-Host '[1/5] 生成干净发布目录 ...'
$relArgs = @{ NoZip = $true }
if ($SkipValidation) { $relArgs['SkipValidation'] = $true }
& (Join-Path $PSScriptRoot 'build_release.ps1') @relArgs
if (-not $?) { throw 'build_release.ps1 未通过，已中止' }

$srcDir = Join-Path $distRoot $modName
$srcMod = Join-Path $distRoot ($modName + '.mod')
if (-not (Test-Path -LiteralPath $srcDir)) { throw "缺少发布目录: $srcDir" }
if (-not (Test-Path -LiteralPath $srcMod)) { throw "缺少本地安装描述文件: $srcMod（build_release.ps1 应生成它）" }
$descText = [System.IO.File]::ReadAllText((Join-Path $srcDir 'descriptor.mod'))
if ($descText -notmatch ('version="' + [regex]::Escape($version) + '"')) { throw 'descriptor.mod 的 version 与 metadata.json 不一致' }
$modText = [System.IO.File]::ReadAllText($srcMod)
if ($modText -notmatch ('path="mod/' + [regex]::Escape($modName) + '"')) { throw ".mod 的 path 不是 mod/$modName，启动器会找不到目录" }

# ---------- 3. 组装分享目录 ----------
Write-Host '[2/5] 组装分享目录（文件夹 + .mod + 安装说明）...'
$stage = Join-Path $distRoot '_share'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item -LiteralPath $srcDir -Destination (Join-Path $stage $modName) -Recurse -Force
Copy-Item -LiteralPath $srcMod -Destination (Join-Path $stage ($modName + '.mod')) -Force

$installDoc = @'
原产物无限制全修改 / Unconditionally Change RGO   v__VERSION__
Europa Universalis V 模组 —— 手动安装说明（大约 1 分钟）
================================================================

【一】压缩包里有什么
  UnconditionallyChangeRGO\        模组本体文件夹（名字不要改）
  UnconditionallyChangeRGO.mod     启动器识别用的描述文件（必须一起放，缺了启动器就看不到模组）
  安装说明.txt                      本文件（放好之后可以删掉）

【二】放到哪个文件夹
  目标文件夹是 EU5 的模组目录，没有的话就自己新建一个名为 mod 的文件夹：

    C:\Users\<你的用户名>\Documents\Paradox Interactive\Europa Universalis V\mod\

  如果「文档」被 OneDrive 接管，路径是：

    C:\Users\<你的用户名>\OneDrive\文档\Paradox Interactive\Europa Universalis V\mod\

  最保险的办法：打开 Paradox 启动器 → 模组 → 点「打开模组文件夹」，
  它跳出来的就是上面这个目录。

【三】放完应该长这样（层级别搞错）
  ...\Europa Universalis V\mod\
      ├ UnconditionallyChangeRGO\                 ← 文件夹
      │   ├ descriptor.mod
      │   ├ .metadata\
      │   ├ in_game\   （common / gui / gfx / localization）
      │   └ main_menu\
      └ UnconditionallyChangeRGO.mod              ← 文件，必须和文件夹同级

【四】安装步骤
  1. 完全退出游戏和 Paradox 启动器。
  2. 打开第【二】步那个 mod 文件夹。
  3. 把压缩包里的「UnconditionallyChangeRGO 文件夹」和「UnconditionallyChangeRGO.mod」
     一起复制进去；或者直接把压缩包解压到 mod 文件夹（解压到当前文件夹）。
  4. 启动游戏，在启动器「模组」页面把「原产物无限制全修改」勾进播放集，然后开始游戏。
  5. 进入游戏后，局势面板里会出现本模组的常驻卡片，本国任意地点的原材料随时可改。

【五】出问题先看这里
  · 启动器里看不到这个模组
      → UnconditionallyChangeRGO.mod 必须和 UnconditionallyChangeRGO 文件夹在同一层，
        不能塞进文件夹里面。
      → 解压后如果变成 mod\UnconditionallyChangeRGO\UnconditionallyChangeRGO\，
        说明多套了一层，把里层那个文件夹提上来一层即可。
      → 还是不行就完全退出启动器再打开（启动器只在启动时扫描 mod 目录）。

  · 同时订阅了创意工坊版本
      → 不要两份同时启用：工坊版和本手动版内容完全相同，重复加载会互相覆盖。
        二选一：取消工坊订阅用本包，或者删掉本包改用工坊版。

  · 想要卸载
      → 删掉 UnconditionallyChangeRGO 文件夹和 UnconditionallyChangeRGO.mod 两样东西就行，
        存档不受影响（存档里已经改过的原材料会保留）。

【六】版本信息
  版本 __VERSION__  ·  适用 EU5（supported_version 1.*.*）  ·  MIT 许可
  创意工坊同名作品与本包内容一致，本包只是多带了 .mod 文件，方便离线 / 网盘安装。
'@
$installDoc = $installDoc.Replace('__VERSION__', $version)
$installDoc = ($installDoc -replace "`r?`n", "`r`n")
[System.IO.File]::WriteAllText((Join-Path $stage '安装说明.txt'), $installDoc, $utf8Bom)

# 自检：分享目录根下只能有三样东西，且不能混入开发文件
$topNames = @(Get-ChildItem -LiteralPath $stage -Force | ForEach-Object { $_.Name } | Sort-Object)
$expectedTop = @($modName, ($modName + '.mod'), '安装说明.txt') | Sort-Object
$diff = Compare-Object $expectedTop $topNames
if ($null -ne $diff) { throw ('分享目录根内容不正确: ' + (($diff | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ', ')) }

$stageFiles = @(Get-ChildItem -LiteralPath $stage -Recurse -File -Force)
$forbidden = @('tools', '.git', '.gitignore', '.gitattributes', 'README.md', 'CHANGELOG.md', 'LICENSE', 'UPLOAD-说明.txt', '网盘分享说明.txt')
$bad = @()
foreach ($f in $stageFiles) {
    $rel = $f.FullName.Substring($stage.Length + 1)
    foreach ($p in $forbidden) {
        if ($rel -eq $p -or $rel -like ($p + '\*') -or $f.Name -eq $p) { $bad += $rel }
    }
}
if ($bad.Count -gt 0) { throw ('分享目录混入了开发文件: ' + ($bad -join ', ')) }

$totalSize = ($stageFiles | Measure-Object -Property Length -Sum).Sum

# ---------- 4. 打包 + 校验压缩包结构 ----------
$zip = Join-Path $distRoot ($modName + '_v' + $version + '_网盘安装包.zip')
if (-not $NoZip) {
    Write-Host '[3/5] 打包 ...'
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal

    Write-Host '[4/5] 校验压缩包结构 ...'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName })
    }
    finally { $archive.Dispose() }

    $zipTop = @($entries | ForEach-Object { ($_ -split '\\')[0] } | Sort-Object -Unique)
    $diff = Compare-Object $expectedTop $zipTop
    if ($null -ne $diff) { throw ('压缩包根层不正确（玩家解压后会多套一层或缺少 .mod）: ' + (($diff | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ', ')) }
    foreach ($need in @(($modName + '\descriptor.mod'), ($modName + '\.metadata\metadata.json'), ($modName + '\.metadata\thumbnail.png'))) {
        if ($entries -notcontains $need) { throw ('压缩包缺少必要文件: ' + $need) }
    }
    $zipFiles = @($entries | Where-Object { -not $_.EndsWith('\') })
    if ($zipFiles.Count -ne $stageFiles.Count) { throw ('压缩包文件数 ' + $zipFiles.Count + ' 与源目录 ' + $stageFiles.Count + ' 不一致') }
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    $zipKB = [Math]::Round((Get-Item -LiteralPath $zip).Length / 1KB, 1)
    Write-Host ('      根层: ' + ($zipTop -join ' / '))
    Write-Host ('      文件 ' + $zipFiles.Count + ' 个，压缩后 ' + $zipKB + ' KB')
    Write-Host ('      SHA256: ' + $hash)
}
else {
    Write-Host '[3/5] 已跳过打包（-NoZip）'
    Write-Host ('      分享目录: ' + $stage)
    $hash = '(未打包)'
    $zipKB = [Math]::Round($totalSize / 1KB, 1)
}

# ---------- 5. 生成网盘分享说明 ----------
Write-Host '[5/5] 写分享说明 ...'
$shareDoc = @'
网盘分享说明 —— 原产物无限制全修改 v__VERSION__
================================================================

一、需要上传的文件（dist 目录下）
  __ZIPNAME__
      __ZIPKB__ KB，__FILES__ 个文件，玩家解压即用
  SHA256（可选，贴在简介里方便玩家核对）
      __HASH__

  同目录的 UnconditionallyChangeRGO_v__VERSION__.zip 是创意工坊上传用的干净副本，
  里面只有模组文件夹、没有 .mod 文件，玩家解压后启动器扫不到，别拿它当网盘包。

二、玩家要放在哪个文件夹（可直接粘进网盘简介 / 群公告）
  Windows 版 EU5 的模组目录：

    C:\Users\<用户名>\Documents\Paradox Interactive\Europa Universalis V\mod\

  「文档」被 OneDrive 接管时：

    C:\Users\<用户名>\OneDrive\文档\Paradox Interactive\Europa Universalis V\mod\

  不会找的话：打开 Paradox 启动器 → 模组 → 「打开模组文件夹」，
  弹出来的就是目标目录（里面没有 mod 文件夹的话自己新建一个）。

三、玩家要做的事（三句话）
  1. 退出游戏和 Paradox 启动器。
  2. 把压缩包解压到上面那个 mod 文件夹，得到「UnconditionallyChangeRGO 文件夹」
     和「UnconditionallyChangeRGO.mod 文件」两样东西，两者必须同级。
  3. 启动游戏 → 启动器「模组」→ 把「原产物无限制全修改」勾进播放集 → 开游戏。

四、包内结构（脚本已自检）
  UnconditionallyChangeRGO\        模组本体（in_game / main_menu / descriptor.mod / .metadata）
  UnconditionallyChangeRGO.mod     启动器描述文件，path="mod/UnconditionallyChangeRGO"
  安装说明.txt                      玩家版说明，放在 mod 目录里也无害，可删

五、重新生成
  powershell -ExecutionPolicy Bypass -File "tools\build_share.ps1"
        加 -NoZip          只生成 dist\_share 目录，便于人工检查
        加 -SkipValidation 跳过发布前校验
'@
$shareDoc = $shareDoc.Replace('__VERSION__', $version).Replace('__ZIPNAME__', [System.IO.Path]::GetFileName($zip)).Replace('__ZIPKB__', [string]$zipKB).Replace('__FILES__', [string]$stageFiles.Count).Replace('__HASH__', $hash)
$shareDoc = ($shareDoc -replace "`r?`n", "`r`n")
[System.IO.File]::WriteAllText((Join-Path $distRoot '网盘分享说明.txt'), $shareDoc, $utf8Bom)

# 清理临时分享目录（-NoZip 时保留，方便人工检查）
if (-not $NoZip -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }

Write-Host ''
Write-Host ('完成：' + $zip)
Write-Host ('版本：' + $version + '    说明：' + (Join-Path $distRoot '网盘分享说明.txt'))
