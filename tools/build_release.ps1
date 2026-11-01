# 构建创意工坊上传用的干净目录：dist\UnconditionallyChangeRGO
#
# 只复制游戏运行需要的文件，排除 tools / 文档 / .git 等开发文件。
# 用法（仓库根目录）：
#   powershell -ExecutionPolicy Bypass -File "tools\build_release.ps1"
#   powershell ... -NoZip           # 只生成文件夹，不打包
#   powershell ... -SkipValidation  # 跳过发布前校验
#
# 输出：
#   dist\UnconditionallyChangeRGO\            可直接上传 / 安装的 mod 目录
#   dist\UnconditionallyChangeRGO.mod         本地安装用描述文件
#   dist\UnconditionallyChangeRGO_v<版本>.zip 压缩包（默认生成）

param(
    [switch]$NoZip,
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $root 'dist'
$modName = 'UnconditionallyChangeRGO'
$outDir = Join-Path $distRoot $modName

# ---------- 1. 读取并校验元数据 ----------
$metaPath = Join-Path $root '.metadata\metadata.json'
if (-not (Test-Path -LiteralPath $metaPath)) { throw "找不到元数据: $metaPath" }
$meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
if ($meta.id -ne $modName) { throw "metadata.id ($($meta.id)) 与目录名 ($modName) 不一致" }
$version = $meta.version
if (-not $version) { throw 'metadata.json 里没有 version' }

$descriptor = Join-Path $root 'descriptor.mod'
if (-not (Test-Path -LiteralPath $descriptor)) { throw "找不到 descriptor.mod" }
$descText = [System.IO.File]::ReadAllText($descriptor)
if ($descText -notmatch ('version="' + [regex]::Escape($version) + '"')) {
    throw "descriptor.mod 的 version 与 metadata.json ($version) 不一致"
}

# ---------- 2. 发布前校验 ----------
if (-not $SkipValidation) {
    Write-Host '[1/4] 运行 validate_mod.ps1 ...'
    & (Join-Path $PSScriptRoot 'validate_mod.ps1') | Out-Null
    if (-not $?) { throw 'validate_mod.ps1 未通过，已中止构建' }
    Write-Host '      校验通过'
}
else {
    Write-Host '[1/4] 已跳过校验'
}

# ---------- 3. 生成干净目录 ----------
Write-Host ('[2/4] 构建 dist 目录（版本 ' + $version + '）...')
if (Test-Path -LiteralPath $outDir) { Remove-Item -LiteralPath $outDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $outDir '.metadata') | Out-Null

# 游戏数据（只复制这两个根目录）
foreach ($dir in @('in_game', 'main_menu')) {
    $src = Join-Path $root $dir
    if (-not (Test-Path -LiteralPath $src)) { continue }
    Copy-Item -LiteralPath $src -Destination (Join-Path $outDir $dir) -Recurse -Force
}

# 描述文件
Copy-Item -LiteralPath $descriptor -Destination (Join-Path $outDir 'descriptor.mod') -Force

# 元数据 + 缩略图（picture 字段指向 thumbnail.png，必须放在 .metadata 里）
Copy-Item -LiteralPath $metaPath -Destination (Join-Path $outDir '.metadata\metadata.json') -Force
$thumb = Join-Path $root 'thumbnail.png'
if (-not (Test-Path -LiteralPath $thumb)) { throw '缺少 thumbnail.png' }
Copy-Item -LiteralPath $thumb -Destination (Join-Path $outDir '.metadata\thumbnail.png') -Force
Copy-Item -LiteralPath $thumb -Destination (Join-Path $outDir 'thumbnail.png') -Force

# 同时给一份本地安装用的 .mod（与启动器生成的一致）
$modFile = @(
    ('version="' + $version + '"')
    'tags={'
    "`t`"Utilities`""
    "`t`"Trade and Economics`""
    '}'
    ('name="' + $meta.name + '"')
    'supported_version="1.*.*"'
    ('path="mod/' + $modName + '"')
    'picture="thumbnail.png"'
    ''
) -join "`r`n"
[System.IO.File]::WriteAllText((Join-Path $distRoot ($modName + '.mod')), $modFile, (New-Object System.Text.UTF8Encoding($true)))

# ---------- 4. 自检 + 打包 ----------
Write-Host '[3/4] 检查输出内容 ...'
$forbidden = @('tools', '.git', '.gitignore', '.gitattributes', 'README.md', 'CHANGELOG.md', 'LICENSE', 'dist')
$bad = @()
foreach ($f in (Get-ChildItem -LiteralPath $outDir -Recurse -Force)) {
    $rel = $f.FullName.Substring($outDir.Length + 1)
    foreach ($p in $forbidden) {
        if ($rel -eq $p -or $rel -like ($p + '\*') -or $f.Name -eq $p) { $bad += $rel }
    }
}
if ($bad.Count -gt 0) { throw ('输出目录混入了开发文件: ' + ($bad -join ', ')) }

$files = @(Get-ChildItem -LiteralPath $outDir -Recurse -File)
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum
$noBom = @()
foreach ($f in $files) {
    if ($f.Extension -notin @('.txt', '.gui', '.yml')) { continue }
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    if (-not ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)) { $noBom += $f.Name }
}
if ($noBom.Count -gt 0) { Write-Warning ('以下文件缺少 UTF-8 BOM: ' + ($noBom -join ', ')) }

Write-Host ('      文件 ' + $files.Count + ' 个，合计 ' + [Math]::Round($totalSize / 1KB, 1) + ' KB')
foreach ($f in ($files | Sort-Object FullName)) {
    Write-Host ('        ' + $f.FullName.Substring($outDir.Length + 1))
}

if (-not $NoZip) {
    Write-Host '[4/4] 打包 ...'
    $zip = Join-Path $distRoot ($modName + '_v' + $version + '.zip')
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path $outDir -DestinationPath $zip -CompressionLevel Optimal
    Write-Host ('      ' + $zip + '  (' + [Math]::Round((Get-Item $zip).Length / 1KB, 1) + ' KB)')
}

# 上传说明（放在 dist 根目录，不会被打包进 mod）
$uploadDoc = @'
原产物无限制全修改 — 创意工坊「更新」说明（版本 __VERSION__）
================================================================

目标：更新已经发布的作品
  https://steamcommunity.com/sharedfiles/filedetails/?id=3682897240
  不要新建条目。

一、目录说明
  dist\UnconditionallyChangeRGO\                  干净 mod 目录（只含游戏运行文件，__FILES__ 个文件 / 约 __SIZE__ KB）
  dist\UnconditionallyChangeRGO.mod               本地安装用描述文件
  dist\UnconditionallyChangeRGO_v__VERSION__.zip  备份 / 手动上传用

二、为什么要用这份干净目录
  游戏 mod 目录是 Junction，指向开发仓库（含 .git 659 KB、tools 90 KB、文档等）。
  上一版工坊包是 1.222 MB，正是把 .git / tools 一起上传了；这次的干净包只有约 __SIZE__ KB。
  直接从 Junction 上传会继续把开发文件打进去，所以请用 dist 里的副本。

三、更新步骤（推荐）
  1) 关闭游戏与启动器。
  2) 仓库根目录运行：
       powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Install
     它把 mod 目录的 Junction 备份为 UnconditionallyChangeRGO.dev，并换成干净副本。
  3) 打开启动器 → 模组 → 选中「原产物无限制全修改」（应显示已发布状态）→ 上传/更新。
     上传对话框里：
       - 标题保持原来的三语标题（原产物无限制全修改-Unconditionally Change RGO-Неограниченное изменение сырья）
       - 描述先确认仍是原来的长文，别被 metadata 的短描述覆盖（可先复制一份备份）
       - 标签保持 Utilities / Trade and Economics
       - 缩略图用 dist\.metadata\thumbnail.png
  4) 上传完成后到工坊页面确认：
       - URL 仍是 id=3682897240
       - 「Updated」时间变成刚才
       - File Size 从 1.222 MB 降到约 __SIZE__ KB
  5) 恢复开发模式：
       powershell -ExecutionPolicy Bypass -File "tools\switch_to_release.ps1" -Restore

四、红线（避免变成新条目 / 丢内容）
  - 不要修改 .metadata\metadata.json 里的 id（UnconditionallyChangeRGO）与 name
  - 不要重命名 mod 文件夹（启动器按路径绑定已发布条目）
  - 若启动器只提供「新建/上传为新作品」而没有「更新」，先停止上传，说明条目绑定丢了

五、手工更新（不用脚本）
  1) 把原 Junction 改名备份，例如 UnconditionallyChangeRGO.dev
  2) 把 dist\UnconditionallyChangeRGO 整个复制到
     …\Documents\Paradox Interactive\Europa Universalis V\mod\UnconditionallyChangeRGO
  3) 确保 mod 目录下有 UnconditionallyChangeRGO.mod（可用 dist 里的那份）
  4) 启动器上传后，删除复制出来的目录，把 .dev 改回原名
'@
$uploadDoc = $uploadDoc.Replace('__VERSION__', $version).Replace('__FILES__', [string]$files.Count).Replace('__SIZE__', [string][Math]::Round($totalSize / 1KB, 1))
[System.IO.File]::WriteAllText((Join-Path $distRoot 'UPLOAD-说明.txt'), $uploadDoc, (New-Object System.Text.UTF8Encoding($true)))

Write-Host ''
Write-Host ('完成：' + $outDir)
Write-Host ('版本：' + $version + '    上传前请先看 dist\UPLOAD-说明.txt')
