# 模拟「其它模组新增货物 / 游戏更新新增货物」，验证分类判定规则仍然正确。
#
# 做法：把原版 common\goods\*.txt 复制到临时目录，再追加一个模拟 mod 的货物文件，
#       然后用 tools\rgo_common.ps1 解析 + 归类，断言新货物落到预期分类。
#
# 说明：运行时真正的筛选由 in_game/common/scripted_triggers/00_rgo_config.txt 的
#       RGO_goods_in_<分类> 完成；本脚本验证的是同一套规则在数据层的映射结果，
#       用于改动规则后快速回归（不需要启动游戏）。
#
# 用法（在仓库根目录执行）：
#   powershell -ExecutionPolicy Bypass -File "tools\test_dynamic_goods.ps1"
#   powershell ... -GoodsRoot "D:\...\game\in_game\common\goods"

param(
    [string]$GoodsRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'rgo_common.ps1')

$vanilla = Get-RgoGoodsRoot -GoodsRoot $GoodsRoot
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('rgo_goods_test_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$fail = 0
function Check($name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host ("[PASS] " + $name) }
    else { Write-Host ("[FAIL] " + $name + " " + $detail); $script:fail++ }
}

try {
    # 1. 复制原版货物定义
    foreach ($f in Get-ChildItem -LiteralPath $vanilla -File -Filter *.txt | Where-Object { $_.Name -notmatch '^(readme|_)' }) {
        Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $tmp $f.Name) -Force
    }

    # 2. 追加一个「其它模组」的货物文件：覆盖四种采集方式 + 食物 + 制成品
    $extra = @'
# 仅用于自检的模拟 mod 货物（不参与正式生成）
test_mod_ore = {
	method = mining
	category = raw_material
	default_market_price = 2
}

test_mod_dye = {
	method = gathering
	category = raw_material
	default_market_price = 2
}

test_mod_hemp = {
	method = farming
	category = raw_material
	default_market_price = 2
}

test_mod_grain = {
	method = farming
	category = raw_material
	food = 6
}

test_mod_resin = {
	method = forestry
	category = raw_material
	default_market_price = 1
}

test_mod_new_cloth = {
	method = farming
	category = produced
	default_market_price = 4
}
'@
    [System.IO.File]::WriteAllText((Join-Path $tmp '99_test_mod_goods.txt'), $extra, (New-Object System.Text.UTF8Encoding($true)))

    # 3. 解析 + 归类
    $rows = Get-RgoGoodsRows -GoodsRoot $tmp
    $groups = Get-RgoGroups -Rows $rows
    Assert-RgoGroups -Rows $rows -Groups $groups

    Check "新增采矿货物 -> 矿物" ($groups['mining'] -contains 'test_mod_ore')
    Check "新增采集货物 -> 采集" ($groups['gathering'] -contains 'test_mod_dye')
    Check "新增农耕非食物货物 -> 经济作物" ($groups['crops'] -contains 'test_mod_hemp')
    Check "新增农耕食物货物 -> 食物" ($groups['food'] -contains 'test_mod_grain')
    Check "新增林业货物 -> 狩猎林业" ($groups['wild'] -contains 'test_mod_resin')
    Check "新增制成品 -> 制成品" ($groups['produced'] -contains 'test_mod_new_cloth')
    Check "新货物没有被重复归类" (
        (@('test_mod_ore', 'test_mod_dye', 'test_mod_hemp', 'test_mod_grain', 'test_mod_resin', 'test_mod_new_cloth') |
            ForEach-Object { $id = $_; @($groups.Values | Where-Object { $_ -contains $id }).Count } |
            Where-Object { $_ -ne 1 }).Count -eq 0)

    # 4. 判定规则本身必须只依赖货物字段（种植园/奴隶除外）
    $staticOk = $true
    foreach ($g in $RGO_GROUP_ORDER) {
        $lines = Get-RgoGroupFilterLines -Group $g -Groups $groups
        if (@($lines).Count -eq 0) { $staticOk = $false; Write-Host ("  分类 $g 没有判定规则") }
        if ($g -notin @('plantation', 'produced') -and ($lines -match 'this = goods:')) {
            $staticOk = $false; Write-Host ("  分类 $g 仍写死了货物 id")
        }
        if ($g -notin @('produced') -and -not ($lines -match 'goods_category = raw_material')) {
            $staticOk = $false; Write-Host ("  分类 $g 缺少 goods_category = raw_material")
        }
    }
    Check "判定规则动态（仅种植园/奴隶用静态清单）" $staticOk
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($fail -eq 0) { Write-Host 'ALL CHECKS PASSED' } else { Write-Host ("FAILED: " + $fail); exit 1 }
