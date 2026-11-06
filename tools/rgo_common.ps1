# ============================================================
# 共享数据层（被 generate_rgo_actions.ps1 / generate_rgo_localization.ps1 引用）
#   - 原版货物解析与分组
#   - 分类判定规则（运行时按货物自身字段动态判定，兼容模组/版本新增货物）
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
# 地理条件开关：no = 不限地理条件（本国任意地点都能改成任意原材料）
#               yes = 只列出原版允许该货物的地点（货物 location_potential：气候/植被/地形/区域）
$RGO_DEFAULT_GEO = 'no'
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

# ---------- 开关表（顺序 = 面板按钮顺序，全部排在分类按钮之后） ----------
#   id      : generic action 的 RGO_toggle_<id>，同时决定本地化键 RGO_toggle_<id> 与 _desc
#   var     : 玩家点开关时写入的国家变量（有变量则以变量为准）
#   check   : 判断开关是否开启的 scripted trigger（生成在 00_rgo_config.txt）
#   default : 没有变量时使用的文件级默认值触发器
#   cleanup : 关闭开关时要顺手清理的东西（没有则 $null）
$RGO_TOGGLES = @(
    [pscustomobject]@{ id = 'cost';     var = 'rgo_var_cost';     check = 'RGO_cost_enabled';         default = 'RGO_cfg_cost_default';         cleanup = $null }
    [pscustomobject]@{ id = 'cooldown'; var = 'rgo_var_cooldown'; check = 'RGO_cooldown_enabled';     default = 'RGO_cfg_cooldown_default';     cleanup = 'remove_country_modifier = rgo_change_cooldown' }
    [pscustomobject]@{ id = 'produced'; var = 'rgo_var_produced'; check = 'RGO_cat_produced_enabled'; default = 'RGO_cfg_cat_produced_default'; cleanup = $null }
    [pscustomobject]@{ id = 'geo';      var = 'rgo_var_geo';      check = 'RGO_geo_enabled';          default = 'RGO_cfg_geo_default';          cleanup = $null }
)
$RGO_TOGGLE_IDS   = @($RGO_TOGGLES | ForEach-Object { $_.id })
$RGO_TOGGLE_COUNT = @($RGO_TOGGLES).Count

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
    # 仅供开发时定位原版文件（生成器本身只读 goods 目录）
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
        $food = 0.0
        foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
            # 顶层定义：id = {
            if ($line -cmatch '^([a-z_0-9]+)\s*=\s*\{') {
                if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $method; food = $food; file = $f.Name } }
                $cur = $Matches[1]; $cat = 'raw_material'; $method = 'farming'; $food = 0.0
            }
            elseif ($line -cmatch '^\s+category\s*=\s*([a-z_]+)') { $cat = $Matches[1] }
            elseif ($line -cmatch '^\s+method\s*=\s*([a-z_]+)') { $method = $Matches[1] }
            elseif ($line -cmatch '^\s+food\s*=\s*([0-9.]+)') { $food = [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture) }
        }
        if ($cur) { $rows += [pscustomobject]@{ id = $cur; cat = $cat; method = $method; food = $food; file = $f.Name } }
    }
    if ($rows.Count -eq 0) { throw "解析原版货物失败: $GoodsRoot" }
    return $rows
}

function Get-RgoGroups {
    param($Rows)

    function Pick([scriptblock]$filter) {
        @($Rows | Where-Object $filter | ForEach-Object { $_.id } | Sort-Object -Unique)
    }

    # 这里的判定规则必须与运行时生成的 RGO_goods_in_<分类> 一致
    # （见 Get-RgoGroupFilterLines）。原版数据下两者结果相同，生成器的报告与
    # 完整性断言才有意义；运行时则不受写死的货物 id 清单限制。
    $plantationIds = @(Pick { $_.file -eq '01_plantation_goods.txt' })

    $groups = [ordered]@{}
    $groups['mining']     = @(Pick { $_.cat -eq 'raw_material' -and $_.method -eq 'mining' })
    $groups['gathering']  = @(Pick { $_.cat -eq 'raw_material' -and $_.method -eq 'gathering' })
    $groups['crops']      = @(Pick { $_.cat -eq 'raw_material' -and $_.method -eq 'farming' -and $_.food -le 0 -and $plantationIds -notcontains $_.id })
    $groups['food']       = @(Pick { $_.cat -eq 'raw_material' -and $_.method -eq 'farming' -and $_.food -gt 0 })
    $groups['plantation'] = @($plantationIds)
    $groups['wild']       = @(Pick { $_.cat -eq 'raw_material' -and $_.method -notin @('mining', 'gathering', 'farming') })
    $groups['produced']   = @(Pick { $_.cat -eq 'produced' } | Where-Object { $RGO_EXCLUDED_GOODS -notcontains $_ })

    # 顺序固定为 $RGO_GROUP_ORDER
    $ordered = [ordered]@{}
    foreach ($k in $RGO_GROUP_ORDER) { $ordered[$k] = @($groups[$k]) }
    return $ordered
}

# ---------- 分类判定规则（动态：兼容其它模组 / 游戏更新新增的货物） ----------
# 每个分类都会在 in_game/common/scripted_triggers/00_rgo_config.txt 里生成一个
# RGO_goods_in_<分类> 触发器（root = goods 作用域），只读货物自身字段：
#   goods_category : raw_material / produced
#   goods_method   : mining / farming / hunting / gathering / forestry
#   is_food        : 该货物是否提供食物
# 因此其它模组或游戏更新新增的货物，只要字段合法就会自动进入对应分类，
# 不需要重新生成、也不会被写死的货物 id 清单漏掉。
#
# 两处例外（原版没有可判定的字段，只能用生成时的静态清单）：
#   1) 种植园：只能取原版 01_plantation_goods.txt 的货物
#   2) 排除货物：$RGO_EXCLUDED_GOODS（奴隶不是制成品）
function Get-RgoGroupFilterLines {
    param([string]$Group, $Groups)

    switch ($Group) {
        'mining' { return @(
                'goods_category = raw_material'
                'goods_method = mining'
            ) }
        'gathering' { return @(
                'goods_category = raw_material'
                'goods_method = gathering'
            ) }
        # 经济作物 = 农耕类原材料里既不是食物、也不是种植园作物的部分
        'crops' { return @(
                'goods_category = raw_material'
                'goods_method = farming'
                'NOT = { is_food = yes }'
                'NOT = { RGO_goods_in_plantation = yes }'
            ) }
        # 食物 = 农耕类原材料里提供食物的部分（鱼类/野味等按原版仍是采集/狩猎）
        'food' { return @(
                'goods_category = raw_material'
                'goods_method = farming'
                'is_food = yes'
            ) }
        'plantation' {
            $ids = @($Groups['plantation'])
            if ($ids.Count -eq 0) { throw '种植园分类为空，无法生成静态清单（请检查 01_plantation_goods.txt）' }
            $list = ($ids | ForEach-Object { 'this = goods:' + $_ }) -join ' '
            return @(
                'goods_category = raw_material'
                'goods_method = farming'
                ('OR = { ' + $list + ' }')
            )
        }
        # 狩猎林业 = 原材料里不是采矿/采集/农耕的其余部分
        # （这样 hunting / forestry 以及将来新增的采集方式都不会漏，且不必写死 forestry）
        'wild' { return @(
                'goods_category = raw_material'
                'NOT = { goods_method = mining }'
                'NOT = { goods_method = gathering }'
                'NOT = { goods_method = farming }'
            ) }
        # 制成品 = 分类为 produced 的货物，排除奴隶
        'produced' {
            if (@($RGO_EXCLUDED_GOODS).Count -eq 0) { return @('goods_category = produced') }
            $list = ($RGO_EXCLUDED_GOODS | ForEach-Object { 'this = goods:' + $_ }) -join ' '
            return @(
                'goods_category = produced'
                ('NOT = { OR = { ' + $list + ' } }')
            )
        }
        default { throw ("未知分类: " + $Group) }
    }
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
