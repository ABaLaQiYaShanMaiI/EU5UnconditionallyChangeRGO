# ============================================================
# 共享数据层（被 generate_rgo_actions.ps1 / generate_rgo_localization.ps1 引用）
#   - 原版货物解析与分组
#   - 价格阶梯 / 冷却月数 / 排除货物 的唯一真值源
# 修改这里的数值后，重跑两个生成器即可同步脚本与 11 种语言的文案。
# ============================================================

# ---------- 价格 ----------
# 基础价（in_game/common/prices/00_rgo_prices.txt 里的 gold）
$RGO_BASE_PRICE = 10

# 六档市场价阶梯：threshold 为“市场价低于此值”，factor 为价格系数
# 最终花费 = $RGO_BASE_PRICE x factor -> 5 / 10 / 16 / 24 / 34 / 50 金
$RGO_PRICE_TIERS = @(
    [pscustomobject]@{ tier = 1; threshold = 0.75; factor = 0.5; gold = 5  }
    [pscustomobject]@{ tier = 2; threshold = 1.5;  factor = 1;   gold = 10 }
    [pscustomobject]@{ tier = 3; threshold = 2.5;  factor = 1.6; gold = 16 }
    [pscustomobject]@{ tier = 4; threshold = 3.5;  factor = 2.4; gold = 24 }
    [pscustomobject]@{ tier = 5; threshold = 6;    factor = 3.4; gold = 34 }
    [pscustomobject]@{ tier = 6; threshold = $null; factor = 5;  gold = 50 }
)

# ---------- 冷却 ----------
$RGO_COOLDOWN_MONTHS = 6

# ---------- 默认值开关（与 in_game/common/scripted_triggers/00_rgo_config.txt 对齐） ----------
$RGO_DEFAULT_COST = 'no'
$RGO_DEFAULT_COOLDOWN = 'no'
$RGO_DEFAULT_CATEGORIES = [ordered]@{
    mining     = 'yes'
    gathering  = 'yes'
    crops      = 'yes'
    food       = 'yes'
    plantation = 'yes'
    wild       = 'yes'
    produced   = 'no'    # 制成品默认关闭：建筑产出，作为原材料属非原生玩法
}

# ---------- 货物排除表 ----------
# 奴隶虽属原版 produced 分类，但不是“制成品”，作为地块原材料也不合逻辑，故排除。
$RGO_EXCLUDED_GOODS = @('slaves_goods')

# 分类显示顺序（同时决定 generic_actions 的按钮顺序，GUI 前 N 个视为分类）
$RGO_GROUP_ORDER = @('mining', 'gathering', 'crops', 'food', 'plantation', 'wild', 'produced')

# ---------- 路径 ----------
function Get-RgoGoodsRoot {
    param([string]$GoodsRoot)

    $candidates = @()
    if ($GoodsRoot) { $candidates += $GoodsRoot }
    if ($env:EU5_GOODS_ROOT) { $candidates += $env:EU5_GOODS_ROOT }
    # 常见 Steam 安装位置（仅作兜底，推荐用 -GoodsRoot 或环境变量 EU5_GOODS_ROOT）
    $candidates += @(
        'D:\Steam\steamapps\common\Europa Universalis V\game\in_game\common\goods'
        'C:\Program Files (x86)\Steam\steamapps\common\Europa Universalis V\game\in_game\common\goods'
        'C:\Program Files\Steam\steamapps\common\Europa Universalis V\game\in_game\common\goods'
        'E:\Steam\steamapps\common\Europa Universalis V\game\in_game\common\goods'
    )

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path }
    }
    throw "找不到原版 goods 目录。请用 -GoodsRoot '<路径>' 指定，或设置环境变量 EU5_GOODS_ROOT。"
}

function Get-RgoGameRoot {
    param([string]$GoodsRoot)
    # <game>\in_game\common\goods -> <game>
    return (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $GoodsRoot)))
}


# ---------- 原版货物解析 ----------
function Get-RgoGoodsRows {
    param([string]$GoodsRoot)

    $rows = @()
    # 只读货物定义文件（排除 readme / 以下划线开头的说明文件）
    $files = @(Get-ChildItem -LiteralPath $GoodsRoot -File -Filter *.txt |
        Where-Object { $_.Name -notmatch '^(readme|_)' } | Sort-Object Name)
    if ($files.Count -eq 0) { throw "goods 目录里没有可解析的 .txt: $GoodsRoot" }

    foreach ($f in $files) {
        $cur = $null
        $cat = 'raw_material'
        $method = 'farming'
        foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
            # 顶层定义：id = {
            if ($line -cmatch '^([a-z_0-9]+)\s*=\s*\{') {
                if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $method; file = $f.Name } }
                $cur = $Matches[1]; $cat = 'raw_material'; $method = 'farming'
            }
            elseif ($line -cmatch '^\s+category\s*=\s*([a-z_]+)') { $cat = $Matches[1] }
            elseif ($line -cmatch '^\s+method\s*=\s*([a-z_]+)') { $method = $Matches[1] }
        }
        if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $method; file = $f.Name } }
    }
    if ($rows.Count -eq 0) { throw "解析原版货物失败: $GoodsRoot" }
    return $rows
}

function Get-RgoGroups {
    param($Rows)

    function Pick([scriptblock]$filter) {
        @($Rows | Where-Object $filter | ForEach-Object { $_.id } | Sort-Object -Unique)
    }

    $groups = [ordered]@{}
    $groups['mining']     = @(Pick { $_.method -eq 'mining' })
    $groups['gathering']  = @(Pick { $_.method -eq 'gathering' })
    $groups['crops']      = @(Pick { $_.file -eq '00_raw_materials.txt' -and $_.method -eq 'farming' })
    $groups['food']       = @(Pick { $_.file -eq '03_food.txt' -and $_.method -eq 'farming' })
    $groups['plantation'] = @(Pick { $_.file -eq '01_plantation_goods.txt' })
    $groups['wild']       = @(Pick { $_.method -eq 'hunting' -or $_.method -eq 'forestry' })
    $groups['produced']   = @(Pick { $_.cat -eq 'produced' } | Where-Object { $RGO_EXCLUDED_GOODS -notcontains $_ })

    # 顺序固定为 $RGO_GROUP_ORDER
    $ordered = [ordered]@{}
    foreach ($k in $RGO_GROUP_ORDER) { $ordered[$k] = @($groups[$k]) }
    return $ordered
}

# ---------- 完整性断言 ----------
function Assert-RgoGroups {
    param($Rows, $Groups)

    $allIds = @($Groups.Values | ForEach-Object { $_ } | Sort-Object -Unique)
    foreach ($k in $Groups.Keys) {
        if ($Groups[$k].Count -eq 0) {
            throw "分类 $k 为空，原版货物结构可能已变化，请检查 goods 解析规则。"
        }
    }

    $missing = @($Rows | Where-Object {
            $allIds -notcontains $_.id -and $RGO_EXCLUDED_GOODS -notcontains $_.id
        } | ForEach-Object { $_.id })
    if ($missing.Count -gt 0) {
        throw ("以下货物没有被归入任何分类，请更新 Get-RgoGroups 或 RGO_EXCLUDED_GOODS: " + ($missing -join ', '))
    }

    $dupes = @($Groups.Values | ForEach-Object { $_ } | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($dupes.Count -gt 0) {
        throw ("以下货物被重复归类: " + ($dupes -join ', '))
    }

    $classified = $allIds.Count
    $excluded = @($Rows | Where-Object { $RGO_EXCLUDED_GOODS -contains $_.id }).Count
    if (($classified + $excluded) -ne @($Rows).Count) {
        throw "归类数量不一致: 原版 $($Rows.Count) 种，已归类 $classified 种，排除 $excluded 种。"
    }
}

# ---------- 原版货物译名 ----------
function Get-RgoGoodsNames {
    param([string]$GameRoot, [string]$Language)

    $file = Join-Path $GameRoot ("main_menu\localization\{0}\goods_l_{0}.yml" -f $Language)
    if (-not (Test-Path -LiteralPath $file)) { throw "找不到原版货物本地化文件: $file" }

    $names = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($file)) {
        $m = [regex]::Match($line, '^\s*([a-z_0-9]+):(?:\d+)?\s+"(.*)"\s*$')
        if ($m.Success) { $names[$m.Groups[1].Value] = $m.Groups[2].Value }
    }
    return $names
}

# ---------- 写文件（统一 UTF-8 BOM，与 Paradox 脚本一致） ----------
function Write-RgoTextFile {
    param([string]$Path, [string]$Text, [switch]$CheckOnly)

    if ($CheckOnly) {
        if (-not (Test-Path -LiteralPath $Path)) { throw "缺少文件: $Path" }
        $current = [System.IO.File]::ReadAllText($Path) -replace '^\uFEFF', ''
        if ($current -ne $Text) {
            throw "生成物已过期: $Path（运行不带 -Check 的生成器刷新）"
        }
        Write-Host ("[一致] " + (Split-Path -Leaf $Path))
        return
    }

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host ("[写入] " + (Split-Path -Leaf $Path))
}

# 生成脚本行：$Indent 个制表符 + 文本（空文本 => 空行）
function Add-RgoLine {
    param($Builder, [int]$Indent, [string]$Text)
    if ($Text -eq '') {
        [void]$Builder.Append("`r`n")
    }
    else {
        [void]$Builder.Append(("`t" * $Indent) + $Text + "`r`n")
    }
}
