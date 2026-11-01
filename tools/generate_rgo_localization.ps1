# 生成 in_game/localization/<lang>/UnconditionallyChangeRGO_l_<lang>.yml（11 种官方语言）
#
# 货物清单与分类数量来自原版 common\goods\*.txt（经 tools\rgo_common.ps1 解析），
# 货物译名直接读取原版 goods_l_<lang>.yml，保证与游戏内术语完全一致。
#
# 用法（在仓库根目录执行）：
#   powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_localization.ps1"
#   powershell -ExecutionPolicy Bypass -File "tools\generate_rgo_localization.ps1" -Check
#   powershell ... -GoodsRoot "D:\...\game\in_game\common\goods"

param(
    [switch]$Check,
    [string]$GoodsRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'rgo_common.ps1')

$modRoot  = Split-Path -Parent $PSScriptRoot
$goodsDir = Get-RgoGoodsRoot -GoodsRoot $GoodsRoot
$gameRoot = Get-RgoGameRoot -GoodsRoot $goodsDir
$rows     = Get-RgoGoodsRows -GoodsRoot $goodsDir
$groups   = Get-RgoGroups -Rows $rows
Assert-RgoGroups -Rows $rows -Groups $groups

$catCount    = @($groups.Keys).Count
$toggleCount = $RGO_TOGGLE_COUNT
$tierText    = (($RGO_PRICE_TIERS | ForEach-Object { $_.gold }) -join ' / ')

# 游戏内官方语言（顺序与启动器一致）
$languages = @(
    'english', 'braz_por', 'french', 'german', 'spanish', 'polish',
    'russian', 'turkish', 'japanese', 'korean', 'simp_chinese'
)

$locales = [ordered]@{}

# ============================================================
# English
# ============================================================
$locales['english'] = @{
    situation       = 'Raw Materials'
    desc            = 'Change the raw material of any location you own - free of charge or at market price.'
    hintTitle       = 'Raw Materials'
    hintText        = "Raw Materials\n\nClick a category button, then pick a raw material and a location. Click a switch to toggle it.\n\n- Cost: pay the live market price of the chosen good in that market, on six tiers (about {tiers} gold). Off: everything is free.\n- Cooldown: every change starts a {months} month cooldown and the buttons grey out. Turning it off clears a running cooldown immediately.\n- Manufactured: off by default. Manufactured goods are made by buildings, so using them as raw materials is not vanilla behaviour and may break building output.\n\nHover a button to see which goods its category contains."
    stepGoods       = 'Select Raw Material'
    stepLocation    = 'Select Location'
    noGoods         = 'No raw materials available'
    noLocations     = 'No eligible locations available'
    cat             = [ordered]@{ mining = 'Mining'; gathering = 'Gathering'; crops = 'Cash Crops'; food = 'Food'; plantation = 'Plantation'; wild = 'Hunting'; produced = 'Manufactured' }
    catDesc         = [ordered]@{
        mining     = 'Mining goods ({n}): {goods}.'
        gathering  = 'Gathered goods ({n}): {goods}.'
        crops      = 'Cash crops and luxury raw materials ({n}): {goods}.'
        food       = 'Food goods ({n}): {goods}.'
        plantation = 'Plantation goods ({n}): {goods}.'
        wild       = 'Hunting and forestry goods ({n}): {goods}.'
        produced   = 'Manufactured goods ({n}): {goods}.\nNot vanilla behaviour and may break building output. Off by default - enable it with the switch below.'
    }
    toggle          = [ordered]@{ cost = 'Cost on/off'; cooldown = 'Cooldown on/off'; produced = 'Manufactured on/off' }
    toggleDesc      = [ordered]@{
        cost     = "On: charges the chosen good's live market price on six tiers (about {tiers} gold); when supply runs short the price moves up a tier. Off: completely free."
        cooldown = 'On: every change starts a {months} month cooldown. Off: no cooldown, and any running one is cleared immediately.'
        produced = 'Show or hide the Manufactured button. Off by default.'
    }
    stateOn         = 'Current: ON - click to turn it off'
    stateOff        = 'Current: OFF - click to turn it on'
    price           = 'Change Raw Material'
    modName         = 'Raw Material Cooldown'
    modDesc         = 'The raw material change is on cooldown; no further changes are possible until it expires.'
}

# ============================================================
# 简体中文
# ============================================================
$locales['simp_chinese'] = @{
    situation       = '原材料'
    desc            = '免费或按市场价，修改本国任意地点的原材料。'
    hintTitle       = '原材料'
    hintText        = "原材料\n\n上方 {cats} 个分类按钮：点一次后先选原材料，再选地点。下方 {toggles} 个开关：点一次切换一次。\n\n- 花费开关：开启后按所选货物在该地点市场的实时价格分六档收费（约 {tiers} 金）；供不应求时收费跳到更高一档。关闭则免费\n- 冷却开关：开启后每次修改产生 {months} 个月冷却，期间按钮变灰；关闭会立即清除冷却\n- 制成品开关：默认关闭。制成品是建筑产出，作为原材料属非原生玩法，可能影响建筑产出\n\n悬停任意按钮可看到该分类包含哪些货物。"
    stepGoods       = '选择原材料'
    stepLocation    = '选择地点'
    noGoods         = '没有可选的原材料'
    noLocations     = '没有符合条件的地点'
    cat             = [ordered]@{ mining = '矿物'; gathering = '采集'; crops = '经济作物'; food = '食物'; plantation = '种植园'; wild = '狩猎林业'; produced = '制成品' }
    catDesc         = [ordered]@{
        mining     = '改为矿物类（{n} 种）：{goods}。'
        gathering  = '改为采集类（{n} 种）：{goods}。'
        crops      = '改为经济作物 / 奢侈原料（{n} 种）：{goods}。'
        food       = '改为食物类（{n} 种）：{goods}。'
        plantation = '改为种植园作物（{n} 种）：{goods}。'
        wild       = '改为狩猎 / 林业类（{n} 种）：{goods}。'
        produced   = '改为制成品（{n} 种）：{goods}。\n非原生玩法，可能影响建筑产出。默认关闭，需先在下方开启。'
    }
    toggle          = [ordered]@{ cost = '花费开关'; cooldown = '冷却开关'; produced = '制成品开关' }
    toggleDesc      = [ordered]@{
        cost     = '开：按所选货物在该市场里的实时价格分六档收费（约 {tiers} 金）；供不应求导致价格上跳时，收费自动跳到更高一档。关：完全免费。'
        cooldown = '开：每次修改产生 {months} 个月冷却。关：无冷却，并立即清除当前冷却。'
        produced = '显示 / 隐藏「制成品」按钮。默认关闭。'
    }
    stateOn         = '当前：开启 —— 点击后关闭'
    stateOff        = '当前：关闭 —— 点击后开启'
    price           = '修改原材料'
    modName         = '原材料冷却'
    modDesc         = '原材料的修改仍在冷却中，冷却结束前无法再次修改。'
}

# ============================================================
# Русский
# ============================================================
$locales['russian'] = @{
    situation       = 'Ресурсы'
    desc            = 'Меняет сырьё любой принадлежащей вам территории: бесплатно или по рыночной цене.'
    hintTitle       = 'Ресурсы'
    hintText        = "Ресурсы\n\nНажмите кнопку категории, затем выберите сырьё и территорию. Переключатели срабатывают по нажатию.\n\n- Стоимость: оплата по текущей рыночной цене выбранного товара на рынке этой территории, шесть уровней (примерно {tiers} золота). Выкл.: всё бесплатно.\n- Перезарядка: каждое изменение даёт {months} месяцев перезарядки, кнопки становятся неактивными. Выключение сразу снимает текущую перезарядку.\n- Изделия: по умолчанию выключено. Изделия производят здания, поэтому использование их как сырья не является ванильным поведением и может нарушить производство.\n\nНаведите курсор на кнопку, чтобы увидеть список товаров категории."
    stepGoods       = 'Выбрать сырьё'
    stepLocation    = 'Выбрать территорию'
    noGoods         = 'Нет доступного сырья'
    noLocations     = 'Нет подходящих территорий'
    cat             = [ordered]@{ mining = 'Добыча'; gathering = 'Сбор'; crops = 'Технические культуры'; food = 'Продовольствие'; plantation = 'Плантации'; wild = 'Охота и лес'; produced = 'Изделия' }
    catDesc         = [ordered]@{
        mining     = 'Добываемое сырьё ({n}): {goods}.'
        gathering  = 'Собираемое сырьё ({n}): {goods}.'
        crops      = 'Технические культуры и роскошь ({n}): {goods}.'
        food       = 'Продовольствие ({n}): {goods}.'
        plantation = 'Плантационные культуры ({n}): {goods}.'
        wild       = 'Охотничье и лесное сырьё ({n}): {goods}.'
        produced   = 'Изделия ({n}): {goods}.\nНе ванильное поведение, может нарушить производство. По умолчанию выключено.'
    }
    toggle          = [ordered]@{ cost = 'Стоимость вкл/выкл'; cooldown = 'Перезарядка вкл/выкл'; produced = 'Изделия вкл/выкл' }
    toggleDesc      = [ordered]@{
        cost     = 'Вкл.: плата по текущей рыночной цене товара, шесть уровней (примерно {tiers} золота); при нехватке предложения уровень повышается. Выкл.: бесплатно.'
        cooldown = 'Вкл.: каждое изменение даёт {months} месяцев перезарядки. Выкл.: перезарядки нет, текущая снимается сразу.'
        produced = 'Показать или скрыть кнопку «Изделия». По умолчанию выключено.'
    }
    stateOn         = 'Сейчас: ВКЛ. - нажмите, чтобы выключить'
    stateOff        = 'Сейчас: ВЫКЛ. - нажмите, чтобы включить'
    price           = 'Изменить сырьё'
    modName         = 'Перезарядка сырья'
    modDesc         = 'Изменение сырья на перезарядке; новые изменения невозможны до её окончания.'
}


# ============================================================
# Français
# ============================================================
$locales['french'] = @{
    situation       = 'Matières premières'
    desc            = "Change la matière première de n'importe quel lieu vous appartenant, gratuitement ou au prix du marché."
    hintTitle       = 'Matières premières'
    hintText        = "Matières premières\n\nCliquez sur une catégorie, puis choisissez une matière première et un lieu. Les interrupteurs se basculent au clic.\n\n- Coût : paie le prix réel du marché local, en six paliers (environ {tiers} or). Désactivé : tout est gratuit.\n- Recharge : chaque changement impose {months} mois de recharge et grise les boutons. La désactiver annule immédiatement la recharge en cours.\n- Produits manufacturés : désactivé par défaut. Ils sont fabriqués par des bâtiments ; les utiliser comme matières premières n'est pas le comportement vanilla et peut perturber la production.\n\nSurvolez un bouton pour voir les biens de sa catégorie."
    stepGoods       = 'Choisir une matière première'
    stepLocation    = 'Choisir un lieu'
    noGoods         = 'Aucune matière première disponible'
    noLocations     = 'Aucun lieu éligible'
    cat             = [ordered]@{ mining = 'Mines'; gathering = 'Cueillette'; crops = 'Cultures commerciales'; food = 'Nourriture'; plantation = 'Plantations'; wild = 'Chasse et forêt'; produced = 'Produits manufacturés' }
    catDesc         = [ordered]@{
        mining     = 'Biens miniers ({n}) : {goods}.'
        gathering  = 'Biens de cueillette ({n}) : {goods}.'
        crops      = 'Cultures commerciales et matières premières de luxe ({n}) : {goods}.'
        food       = 'Biens alimentaires ({n}) : {goods}.'
        plantation = 'Biens de plantation ({n}) : {goods}.'
        wild       = 'Biens de chasse et de forêt ({n}) : {goods}.'
        produced   = 'Produits manufacturés ({n}) : {goods}.\nComportement non vanilla, peut perturber la production. Désactivé par défaut.'
    }
    toggle          = [ordered]@{ cost = 'Coût act./dés.'; cooldown = 'Recharge act./dés.'; produced = 'Manufacturés act./dés.' }
    toggleDesc      = [ordered]@{
        cost     = "Activé : facture le prix réel du marché local en six paliers (environ {tiers} or) ; en cas de pénurie, le palier augmente. Désactivé : entièrement gratuit."
        cooldown = "Activé : chaque changement impose {months} mois de recharge. Désactivé : aucune recharge, et celle en cours est annulée immédiatement."
        produced = "Affiche ou masque le bouton Manufacturés. Désactivé par défaut."
    }
    stateOn         = 'Actuellement : ACTIVÉ - cliquez pour désactiver'
    stateOff        = 'Actuellement : DÉSACTIVÉ - cliquez pour activer'
    price           = 'Changer la matière première'
    modName         = 'Recharge des matières premières'
    modDesc         = "Le changement de matière première est en recharge ; aucune modification n'est possible avant son expiration."
}


# ============================================================
# Deutsch
# ============================================================
$locales['german'] = @{
    situation       = 'Rohstoffe'
    desc            = 'Ändert den Rohstoff jedes Ortes in eurem Besitz - kostenlos oder zum Marktpreis.'
    hintTitle       = 'Rohstoffe'
    hintText        = "Rohstoffe\n\nKlickt auf eine Kategorie und wählt dann einen Rohstoff und einen Ort. Die Schalter lassen sich per Klick umlegen.\n\n- Kosten: zahlt den aktuellen Marktpreis der Ware am Markt des Ortes in sechs Stufen (etwa {tiers} Gold). Aus: alles kostenlos.\n- Abklingzeit: Jede Änderung erzeugt {months} Monate Abklingzeit, die Buttons werden ausgegraut. Beim Ausschalten wird eine laufende Abklingzeit sofort entfernt.\n- Fertigwaren: standardmäßig aus. Fertigwaren entstehen in Gebäuden; sie als Rohstoff zu nutzen ist kein Vanilla-Verhalten und kann die Gebäudeproduktion stören.\n\nFahrt über einen Button, um die Waren der Kategorie zu sehen."
    stepGoods       = 'Rohstoff wählen'
    stepLocation    = 'Ort wählen'
    noGoods         = 'Keine Rohstoffe verfügbar'
    noLocations     = 'Keine geeigneten Orte verfügbar'
    cat             = [ordered]@{ mining = 'Bergbau'; gathering = 'Sammeln'; crops = 'Marktfrüchte'; food = 'Nahrung'; plantation = 'Plantagen'; wild = 'Jagd und Forst'; produced = 'Fertigwaren' }
    catDesc         = [ordered]@{
        mining     = 'Bergbauwaren ({n}): {goods}.'
        gathering  = 'Sammelwaren ({n}): {goods}.'
        crops      = 'Marktfrüchte und Luxusrohstoffe ({n}): {goods}.'
        food       = 'Nahrungswaren ({n}): {goods}.'
        plantation = 'Plantagenwaren ({n}): {goods}.'
        wild       = 'Jagd- und Forstwaren ({n}): {goods}.'
        produced   = 'Fertigwaren ({n}): {goods}.\nKein Vanilla-Verhalten, kann die Gebäudeproduktion stören. Standardmäßig aus.'
    }
    toggle          = [ordered]@{ cost = 'Kosten an/aus'; cooldown = 'Abklingzeit an/aus'; produced = 'Fertigwaren an/aus' }
    toggleDesc      = [ordered]@{
        cost     = 'An: berechnet den aktuellen Marktpreis der Ware in sechs Stufen (etwa {tiers} Gold); bei Knappheit steigt die Stufe. Aus: völlig kostenlos.'
        cooldown = 'An: Jede Änderung erzeugt {months} Monate Abklingzeit. Aus: keine Abklingzeit, eine laufende wird sofort entfernt.'
        produced = 'Zeigt oder verbirgt den Button Fertigwaren. Standardmäßig aus.'
    }
    stateOn         = 'Aktuell: AN - klicken zum Ausschalten'
    stateOff        = 'Aktuell: AUS - klicken zum Einschalten'
    price           = 'Rohstoff ändern'
    modName         = 'Rohstoff-Abklingzeit'
    modDesc         = 'Die Rohstoffänderung hat Abklingzeit; bis zu deren Ende sind keine weiteren Änderungen möglich.'
}


# ============================================================
# Español
# ============================================================
$locales['spanish'] = @{
    situation       = 'Materias primas'
    desc            = 'Cambia la materia prima de cualquier lugar que poseas: gratis o a precio de mercado.'
    hintTitle       = 'Materias primas'
    hintText        = "Materias primas\n\nPulsa una categoría y elige después una materia prima y un lugar. Los interruptores se cambian con un clic.\n\n- Coste: cobra el precio real del mercado del lugar en seis tramos (unos {tiers} de oro). Desactivado: todo gratis.\n- Enfriamiento: cada cambio impone {months} meses de enfriamiento y los botones se atenúan. Al desactivarlo se elimina de inmediato el enfriamiento activo.\n- Manufacturas: desactivado por defecto. Se fabrican en edificios; usarlas como materia prima no es comportamiento vanilla y puede afectar a la producción.\n\nPasa el cursor por un botón para ver las mercancías de su categoría."
    stepGoods       = 'Elegir materia prima'
    stepLocation    = 'Elegir lugar'
    noGoods         = 'No hay materias primas disponibles'
    noLocations     = 'No hay lugares válidos'
    cat             = [ordered]@{ mining = 'Minería'; gathering = 'Recolección'; crops = 'Cultivos comerciales'; food = 'Alimentos'; plantation = 'Plantaciones'; wild = 'Caza y bosque'; produced = 'Manufacturas' }
    catDesc         = [ordered]@{
        mining     = 'Mercancías mineras ({n}): {goods}.'
        gathering  = 'Mercancías de recolección ({n}): {goods}.'
        crops      = 'Cultivos comerciales y materias primas de lujo ({n}): {goods}.'
        food       = 'Mercancías alimentarias ({n}): {goods}.'
        plantation = 'Mercancías de plantación ({n}): {goods}.'
        wild       = 'Mercancías de caza y bosque ({n}): {goods}.'
        produced   = 'Manufacturas ({n}): {goods}.\nComportamiento no vanilla, puede afectar a la producción. Desactivado por defecto.'
    }
    toggle          = [ordered]@{ cost = 'Coste on/off'; cooldown = 'Enfriamiento on/off'; produced = 'Manufacturas on/off' }
    toggleDesc      = [ordered]@{
        cost     = 'Activado: cobra el precio real del mercado en seis tramos (unos {tiers} de oro); si escasea, sube de tramo. Desactivado: totalmente gratis.'
        cooldown = 'Activado: cada cambio impone {months} meses de enfriamiento. Desactivado: sin enfriamiento y se elimina el actual al instante.'
        produced = 'Muestra u oculta el botón Manufacturas. Desactivado por defecto.'
    }
    stateOn         = 'Ahora: ACTIVADO - pulsa para desactivar'
    stateOff        = 'Ahora: DESACTIVADO - pulsa para activar'
    price           = 'Cambiar materia prima'
    modName         = 'Enfriamiento de materias primas'
    modDesc         = 'El cambio de materia prima está en enfriamiento; no se pueden hacer más cambios hasta que termine.'
}


# ============================================================
# Polski
# ============================================================
$locales['polish'] = @{
    situation       = 'Surowce'
    desc            = 'Zmienia surowiec dowolnej należącej do was lokalizacji: bez opłat lub po cenie rynkowej.'
    hintTitle       = 'Surowce'
    hintText        = "Surowce\n\nKliknij kategorię, a następnie wybierz surowiec i lokalizację. Przełączniki zmieniają stan po kliknięciu.\n\n- Koszt: opłata według bieżącej ceny rynkowej towaru w sześciu progach (około {tiers} złota). Wył.: wszystko bezpłatnie.\n- Odnowienie: każde użycie daje {months} miesięcy odnowienia, a przyciski szarzeją. Wyłączenie natychmiast usuwa trwające odnowienie.\n- Wyroby: domyślnie wyłączone. Wyroby powstają w budynkach, więc użycie ich jako surowca nie jest zachowaniem vanilla i może zakłócić produkcję.\n\nNajedź na przycisk, aby zobaczyć towary w kategorii."
    stepGoods       = 'Wybierz surowiec'
    stepLocation    = 'Wybierz lokalizację'
    noGoods         = 'Brak dostępnych surowców'
    noLocations     = 'Brak odpowiednich lokalizacji'
    cat             = [ordered]@{ mining = 'Górnictwo'; gathering = 'Zbieractwo'; crops = 'Uprawy towarowe'; food = 'Żywność'; plantation = 'Plantacje'; wild = 'Łowiectwo i las'; produced = 'Wyroby' }
    catDesc         = [ordered]@{
        mining     = 'Surowce górnicze ({n}): {goods}.'
        gathering  = 'Surowce zbierane ({n}): {goods}.'
        crops      = 'Uprawy towarowe i surowce luksusowe ({n}): {goods}.'
        food       = 'Surowce żywnościowe ({n}): {goods}.'
        plantation = 'Surowce plantacyjne ({n}): {goods}.'
        wild       = 'Surowce łowieckie i leśne ({n}): {goods}.'
        produced   = 'Wyroby ({n}): {goods}.\nZachowanie inne niż vanilla, może zakłócić produkcję. Domyślnie wyłączone.'
    }
    toggle          = [ordered]@{ cost = 'Koszt wł./wył.'; cooldown = 'Odnowienie wł./wył.'; produced = 'Wyroby wł./wył.' }
    toggleDesc      = [ordered]@{
        cost     = 'Wł.: opłata według bieżącej ceny rynkowej w sześciu progach (około {tiers} złota); przy niedoborze próg rośnie. Wył.: całkowicie bezpłatnie.'
        cooldown = 'Wł.: każde użycie daje {months} miesięcy odnowienia. Wył.: brak odnowienia, a trwające jest natychmiast usuwane.'
        produced = 'Pokazuje lub ukrywa przycisk Wyroby. Domyślnie wyłączone.'
    }
    stateOn         = 'Teraz: WŁ. - kliknij, aby wyłączyć'
    stateOff        = 'Teraz: WYŁ. - kliknij, aby włączyć'
    price           = 'Zmień surowiec'
    modName         = 'Odnowienie surowców'
    modDesc         = 'Zmiana surowca jest w trakcie odnowienia; do jego końca nie można wykonać kolejnych zmian.'
}


# ============================================================
# Türkçe
# ============================================================
$locales['turkish'] = @{
    situation       = 'Hammaddeler'
    desc            = 'Sahip olduğunuz herhangi bir yerin hammaddesini ücretsiz veya piyasa fiyatıyla değiştirir.'
    hintTitle       = 'Hammaddeler'
    hintText        = "Hammaddeler\n\nBir kategoriye tıklayın, ardından hammaddeyi ve yeri seçin. Anahtarlar her tıklamada açılıp kapanır.\n\n- Maliyet: seçilen malın o yerin piyasasındaki güncel fiyatını altı kademede tahsil eder (yaklaşık {tiers} altın). Kapalı: her şey ücretsiz.\n- Bekleme: her değişiklik {months} ay bekleme başlatır ve düğmeler grileşir. Kapatmak süren beklemeyi hemen siler.\n- Mamul mallar: varsayılan olarak kapalı. Binalarda üretilirler; hammadde olarak kullanmak vanilla davranışı değildir ve üretimi bozabilir.\n\nKategorideki malları görmek için bir düğmenin üzerine gelin."
    stepGoods       = 'Hammadde seç'
    stepLocation    = 'Yer seç'
    noGoods         = 'Uygun hammadde yok'
    noLocations     = 'Uygun yer yok'
    cat             = [ordered]@{ mining = 'Madencilik'; gathering = 'Toplayıcılık'; crops = 'Ticari bitkiler'; food = 'Gıda'; plantation = 'Plantasyon'; wild = 'Avcılık ve orman'; produced = 'Mamul mallar' }
    catDesc         = [ordered]@{
        mining     = 'Madencilik malları ({n}): {goods}.'
        gathering  = 'Toplanan mallar ({n}): {goods}.'
        crops      = 'Ticari bitkiler ve lüks hammaddeler ({n}): {goods}.'
        food       = 'Gıda malları ({n}): {goods}.'
        plantation = 'Plantasyon malları ({n}): {goods}.'
        wild       = 'Avcılık ve orman malları ({n}): {goods}.'
        produced   = 'Mamul mallar ({n}): {goods}.\nVanilla davranışı değildir, üretimi bozabilir. Varsayılan olarak kapalı.'
    }
    toggle          = [ordered]@{ cost = 'Maliyet aç/kapa'; cooldown = 'Bekleme aç/kapa'; produced = 'Mamul mallar aç/kapa' }
    toggleDesc      = [ordered]@{
        cost     = 'Açık: güncel piyasa fiyatını altı kademede tahsil eder (yaklaşık {tiers} altın); arz yetmezse kademe yükselir. Kapalı: tamamen ücretsiz.'
        cooldown = 'Açık: her değişiklik {months} ay bekleme başlatır. Kapalı: bekleme yoktur ve süren bekleme hemen silinir.'
        produced = 'Mamul mallar düğmesini gösterir veya gizler. Varsayılan olarak kapalı.'
    }
    stateOn         = 'Şu an: AÇIK - kapatmak için tıklayın'
    stateOff        = 'Şu an: KAPALI - açmak için tıklayın'
    price           = 'Hammaddeyi değiştir'
    modName         = 'Hammadde beklemesi'
    modDesc         = 'Hammadde değişikliği beklemede; süre bitene kadar yeni değişiklik yapılamaz.'
}


# ============================================================
# 日本語
# ============================================================
$locales['japanese'] = @{
    situation       = '原材料'
    desc            = '自国が所有する任意の地点の原材料を、無料または市場価格で変更します。'
    hintTitle       = '原材料'
    hintText        = "原材料\n\nカテゴリボタンを押し、原材料と地点を選びます。スイッチはクリックするたびに切り替わります。\n\n- 費用：選択した財の現地市場価格を6段階で支払います（約 {tiers} 金）。オフならすべて無料。\n- クールダウン：変更ごとに {months} か月のクールダウンが発生し、ボタンが無効になります。オフにすると進行中のクールダウンは即座に解除されます。\n- 加工品：既定ではオフ。加工品は建物が生産するため、原材料として使うのは本来の仕様ではなく、建物の生産を壊す可能性があります。\n\nボタンにカーソルを合わせると、そのカテゴリの財が表示されます。"
    stepGoods       = '原材料を選択'
    stepLocation    = '地点を選択'
    noGoods         = '選択できる原材料がありません'
    noLocations     = '条件を満たす地点がありません'
    cat             = [ordered]@{ mining = '鉱物'; gathering = '採集'; crops = '商品作物'; food = '食糧'; plantation = 'プランテーション'; wild = '狩猟・林業'; produced = '加工品' }
    catDesc         = [ordered]@{
        mining     = '鉱物系（{n} 種）：{goods}。'
        gathering  = '採集系（{n} 種）：{goods}。'
        crops      = '商品作物・奢侈原材料（{n} 種）：{goods}。'
        food       = '食糧系（{n} 種）：{goods}。'
        plantation = 'プランテーション作物（{n} 種）：{goods}。'
        wild       = '狩猟・林業系（{n} 種）：{goods}。'
        produced   = '加工品（{n} 種）：{goods}。\n本来の仕様ではなく、建物の生産を壊す可能性があります。既定ではオフです。'
    }
    toggle          = [ordered]@{ cost = '費用 オン/オフ'; cooldown = 'クールダウン オン/オフ'; produced = '加工品 オン/オフ' }
    toggleDesc      = [ordered]@{
        cost     = 'オン：現地市場価格を6段階で請求します（約 {tiers} 金）。供給不足時は上の段階になります。オフ：完全無料。'
        cooldown = 'オン：変更ごとに {months} か月のクールダウン。オフ：クールダウンなし、進行中のものは即座に解除。'
        produced = '「加工品」ボタンの表示を切り替えます。既定ではオフ。'
    }
    stateOn         = '現在：オン - クリックでオフ'
    stateOff        = '現在：オフ - クリックでオン'
    price           = '原材料を変更'
    modName         = '原材料クールダウン'
    modDesc         = '原材料の変更はクールダウン中です。終了まで再変更できません。'
}


# ============================================================
# 한국어
# ============================================================
$locales['korean'] = @{
    situation       = '원자재'
    desc            = '보유한 모든 지역의 원자재를 무료 또는 시장 가격으로 변경합니다.'
    hintTitle       = '원자재'
    hintText        = "원자재\n\n분류 버튼을 누른 뒤 원자재와 지역을 선택하세요. 스위치는 클릭할 때마다 전환됩니다.\n\n- 비용: 선택한 상품의 해당 지역 시장 실시간 가격을 6단계로 지불합니다(약 {tiers} 골드). 끄면 전부 무료.\n- 재사용 대기: 변경할 때마다 {months}개월 대기 시간이 생기고 버튼이 비활성화됩니다. 끄면 진행 중인 대기도 즉시 해제됩니다.\n- 가공품: 기본적으로 꺼져 있습니다. 가공품은 건물이 생산하므로 원자재로 쓰는 것은 원작 동작이 아니며 건물 생산을 깨뜨릴 수 있습니다.\n\n버튼에 마우스를 올리면 해당 분류의 상품을 볼 수 있습니다."
    stepGoods       = '원자재 선택'
    stepLocation    = '지역 선택'
    noGoods         = '선택 가능한 원자재가 없습니다'
    noLocations     = '조건에 맞는 지역이 없습니다'
    cat             = [ordered]@{ mining = '광물'; gathering = '채집'; crops = '상품 작물'; food = '식량'; plantation = '플랜테이션'; wild = '수렵·임업'; produced = '가공품' }
    catDesc         = [ordered]@{
        mining     = '광물류({n}종): {goods}.'
        gathering  = '채집류({n}종): {goods}.'
        crops      = '상품 작물 및 사치 원자재({n}종): {goods}.'
        food       = '식량류({n}종): {goods}.'
        plantation = '플랜테이션 작물({n}종): {goods}.'
        wild       = '수렵·임업류({n}종): {goods}.'
        produced   = '가공품({n}종): {goods}.\n원작 동작이 아니며 건물 생산을 깨뜨릴 수 있습니다. 기본적으로 꺼져 있습니다.'
    }
    toggle          = [ordered]@{ cost = '비용 켜기/끄기'; cooldown = '재사용 대기 켜기/끄기'; produced = '가공품 켜기/끄기' }
    toggleDesc      = [ordered]@{
        cost     = '켜기: 실시간 시장 가격을 6단계로 청구합니다(약 {tiers} 골드). 공급이 부족하면 더 높은 단계가 적용됩니다. 끄기: 완전 무료.'
        cooldown = '켜기: 변경할 때마다 {months}개월 대기. 끄기: 대기 없음, 진행 중인 대기는 즉시 해제.'
        produced = '가공품 버튼을 표시하거나 숨깁니다. 기본적으로 꺼져 있습니다.'
    }
    stateOn         = '현재: 켜짐 - 클릭하면 꺼짐'
    stateOff        = '현재: 꺼짐 - 클릭하면 켜짐'
    price           = '원자재 변경'
    modName         = '원자재 재사용 대기'
    modDesc         = '원자재 변경이 재사용 대기 중입니다. 끝날 때까지 다시 변경할 수 없습니다.'
}


# ============================================================
# Português (Brasil)
# ============================================================
$locales['braz_por'] = @{
    situation       = 'Matérias-primas'
    desc            = 'Muda a matéria-prima de qualquer local que você possua: de graça ou pelo preço de mercado.'
    hintTitle       = 'Matérias-primas'
    hintText        = "Matérias-primas\n\nClique em uma categoria e escolha a matéria-prima e o local. Os interruptores alternam a cada clique.\n\n- Custo: cobra o preço real do mercado local em seis faixas (cerca de {tiers} de ouro). Desligado: tudo grátis.\n- Recarga: cada mudança gera {months} meses de recarga e os botões ficam cinzas. Desligar remove a recarga em andamento na hora.\n- Manufaturados: desligado por padrão. São produzidos por edifícios; usá-los como matéria-prima não é o comportamento vanilla e pode afetar a produção.\n\nPasse o mouse sobre um botão para ver os bens da categoria."
    stepGoods       = 'Escolher matéria-prima'
    stepLocation    = 'Escolher local'
    noGoods         = 'Nenhuma matéria-prima disponível'
    noLocations     = 'Nenhum local elegível'
    cat             = [ordered]@{ mining = 'Mineração'; gathering = 'Coleta'; crops = 'Culturas comerciais'; food = 'Alimentos'; plantation = 'Plantações'; wild = 'Caça e floresta'; produced = 'Manufaturados' }
    catDesc         = [ordered]@{
        mining     = 'Bens minerais ({n}): {goods}.'
        gathering  = 'Bens de coleta ({n}): {goods}.'
        crops      = 'Culturas comerciais e matérias-primas de luxo ({n}): {goods}.'
        food       = 'Bens alimentícios ({n}): {goods}.'
        plantation = 'Bens de plantação ({n}): {goods}.'
        wild       = 'Bens de caça e floresta ({n}): {goods}.'
        produced   = 'Manufaturados ({n}): {goods}.\nComportamento não vanilla, pode afetar a produção. Desligado por padrão.'
    }
    toggle          = [ordered]@{ cost = 'Custo lig/desl'; cooldown = 'Recarga lig/desl'; produced = 'Manufaturados lig/desl' }
    toggleDesc      = [ordered]@{
        cost     = 'Ligado: cobra o preço real do mercado em seis faixas (cerca de {tiers} de ouro); se faltar oferta, sobe de faixa. Desligado: totalmente grátis.'
        cooldown = 'Ligado: cada mudança gera {months} meses de recarga. Desligado: sem recarga, e a atual é removida na hora.'
        produced = 'Mostra ou oculta o botão Manufaturados. Desligado por padrão.'
    }
    stateOn         = 'Agora: LIGADO - clique para desligar'
    stateOff        = 'Agora: DESLIGADO - clique para ligar'
    price           = 'Mudar matéria-prima'
    modName         = 'Recarga de matérias-primas'
    modDesc         = 'A mudança de matéria-prima está em recarga; não é possível mudar novamente até acabar.'
}


# ============================================================
# 地理条件开关（新增开关：文案集中在这里，不改上面 11 份长模板）
#   toggle / desc : 按钮名与悬停说明
#   hint          : 追加到「提示」正文最后一段之前的条目（不用写开头的 "- "）
# 说明：默认关闭 = 不限地理条件；开启 = 只列出原版 location_potential 允许的地点
# ============================================================
$geoTexts = @{
    english = @{
        toggle = 'Geography on/off'
        desc   = 'On: only locations where the game itself allows this good (climate, vegetation, topography, region) are listed. Off: any owned location can take any raw material. Off by default.'
        hint   = 'Geography switch: off by default. When off, any owned location can take any raw material even if its climate, vegetation or terrain would not allow it in vanilla. When on, only the locations the game accepts for that good are listed.'
    }
    simp_chinese = @{
        toggle = '地理条件开关'
        desc   = '开：只列出原版允许该货物的地点（气候、植被、地形、区域等）。关：本国任意地点都能改成任意原材料。默认关闭。'
        hint   = '地理条件开关：默认关闭。关闭时本国任意地点都能改成任意原材料，即使原版的气候、植被、地形并不允许；开启后只列出原版允许该货物的地点。'
    }
    russian = @{
        toggle = 'География вкл/выкл'
        desc   = 'Вкл.: показываются только территории, где игра сама допускает этот товар (климат, растительность, рельеф, регион). Выкл.: любую свою территорию можно сделать любым сырьём. По умолчанию выключено.'
        hint   = 'География: по умолчанию выключено. Выкл.: любую свою территорию можно сделать любым сырьём, даже если климат, растительность или рельеф этого не допускают. Вкл.: только территории, допустимые в игре.'
    }
    french = @{
        toggle = 'Géographie act./dés.'
        desc   = "Activé : seuls les lieux où le jeu autorise ce bien (climat, végétation, relief, région) sont proposés. Désactivé : n'importe quel lieu vous appartenant accepte n'importe quelle matière première. Désactivé par défaut."
        hint   = "Géographie : désactivée par défaut. Désactivée, n'importe quel lieu vous appartenant accepte n'importe quelle matière première, même si le climat, la végétation ou le relief ne le permettent pas en vanilla. Activée, seuls les lieux acceptés par le jeu sont proposés."
    }
    german = @{
        toggle = 'Geografie an/aus'
        desc   = 'An: nur Orte, an denen das Spiel diese Ware zulässt (Klima, Vegetation, Gelände, Region), werden angeboten. Aus: jeder eigene Ort kann jeden Rohstoff erhalten. Standardmäßig aus.'
        hint   = 'Geografie: standardmäßig aus. Aus: jeder eigene Ort kann jeden Rohstoff erhalten, auch wenn Klima, Vegetation oder Gelände es in Vanilla nicht zulassen. An: nur Orte, die das Spiel zulässt.'
    }
    spanish = @{
        toggle = 'Geografía on/off'
        desc   = 'Activado: solo se ofrecen los lugares donde el juego permite ese bien (clima, vegetación, relieve, región). Desactivado: cualquier lugar propio puede recibir cualquier materia prima. Desactivado por defecto.'
        hint   = 'Geografía: desactivada por defecto. Desactivada, cualquier lugar propio puede recibir cualquier materia prima aunque el clima, la vegetación o el relieve no lo permitan en vanilla. Activada, solo se ofrecen los lugares aceptados por el juego.'
    }
    polish = @{
        toggle = 'Geografia wł./wył.'
        desc   = 'Wł.: pokazywane są tylko lokalizacje, w których gra dopuszcza ten towar (klimat, roślinność, ukształtowanie, region). Wył.: każda własna lokalizacja może otrzymać dowolny surowiec. Domyślnie wyłączone.'
        hint   = 'Geografia: domyślnie wyłączona. Wyłączona: każda własna lokalizacja może otrzymać dowolny surowiec, nawet jeśli klimat, roślinność lub ukształtowanie tego nie pozwalają. Włączona: tylko lokalizacje dopuszczane przez grę.'
    }
    turkish = @{
        toggle = 'Coğrafya aç/kapa'
        desc   = 'Açık: yalnızca oyunun bu malı kabul ettiği yerler (iklim, bitki örtüsü, arazi, bölge) listelenir. Kapalı: sahip olduğunuz her yer herhangi bir hammaddeye çevrilebilir. Varsayılan olarak kapalı.'
        hint   = 'Coğrafya: varsayılan olarak kapalı. Kapalıyken iklim, bitki örtüsü veya arazi izin vermese de her yer herhangi bir hammaddeye çevrilebilir. Açıkken yalnızca oyunun kabul ettiği yerler listelenir.'
    }
    japanese = @{
        toggle = '地理条件 オン/オフ'
        desc   = 'オン：その財を原材料にできる地点（気候・植生・地形・地域）だけが候補になります。オフ：自国のどの地点でも任意の原材料に変更できます。既定ではオフ。'
        hint   = '地理条件：既定ではオフ。オフなら気候・植生・地形が許さない場合でも自国のどの地点でも任意の原材料に変更できます。オンにすると原版で認められる地点だけが候補になります。'
    }
    korean = @{
        toggle = '지리 조건 켜기/끄기'
        desc   = '켜기: 게임이 해당 상품을 허용하는 지역(기후, 식생, 지형, 지방)만 표시됩니다. 끄기: 소유한 모든 지역을 어떤 원자재로든 바꿀 수 있습니다. 기본적으로 꺼져 있습니다.'
        hint   = '지리 조건: 기본적으로 꺼져 있습니다. 끄면 기후·식생·지형이 허용하지 않아도 모든 지역을 어떤 원자재로든 바꿀 수 있습니다. 켜면 원작에서 허용되는 지역만 표시됩니다.'
    }
    braz_por = @{
        toggle = 'Geografia lig/desl'
        desc   = 'Ligado: só são listados locais onde o jogo permite o bem (clima, vegetação, relevo, região). Desligado: qualquer local seu aceita qualquer matéria-prima. Desligado por padrão.'
        hint   = 'Geografia: desligada por padrão. Desligada, qualquer local seu aceita qualquer matéria-prima mesmo que o clima, a vegetação ou o relevo não permitam no vanilla. Ligada, só aparecem os locais aceitos pelo jogo.'
    }
}


# ============================================================
# 生成
# ============================================================
$catTextSep = @{ simp_chinese = '、'; japanese = '、'; korean = ', ' }

# 动作卡片标题（原版 situation_card_actions 的默认标题是 UI 库占位文字，必须覆盖）
$cardHeaders = @{
    english      = 'Raw Material Actions'
    braz_por     = 'Ações de matérias-primas'
    french       = 'Actions sur les matières premières'
    german       = 'Rohstoff-Aktionen'
    spanish      = 'Acciones de materias primas'
    polish       = 'Działania na surowcach'
    russian      = 'Действия с сырьём'
    turkish      = 'Hammadde işlemleri'
    japanese     = '原材料の操作'
    korean       = '원자재 작업'
    simp_chinese = '原材料操作'
}

function Add-LocLine($sb, [string]$text) {
    if ($text -eq '') { [void]$sb.Append("`r`n") }
    else { [void]$sb.Append(' ' + $text + "`r`n") }
}

function Resolve-RgoText([string]$text, [hashtable]$map) {
    foreach ($k in $map.Keys) { $text = $text.Replace('{' + $k + '}', [string]$map[$k]) }
    if ($text -match '\{[a-z]+\}') { throw ("本地化模板里还有未替换的占位符: " + $text) }
    return $text
}

# 在提示正文的最后一个空行（“悬停查看”说明之前）插入一条列表项
# 注意：正文里的换行是字面量 \n（两个字符），与 Paradox yml 一致
function Add-RgoGeoHintBullet([string]$Text, [string]$Bullet) {
    $sep = '\n\n'
    $idx = $Text.LastIndexOf($sep)
    if ($idx -lt 0) { throw ('提示正文里找不到空行，无法插入地理条件条目: ' + $Text) }
    return $Text.Substring(0, $idx) + '\n- ' + $Bullet + $Text.Substring($idx)
}

$written = 0
foreach ($lang in $languages) {
    if (-not $locales.Contains($lang)) { throw "缺少语言模板: $lang" }
    $t = $locales[$lang]

    # 地理条件开关的文案（独立表）合并进当前语言的开关字典，后面的循环按 $RGO_TOGGLE_IDS 遍历
    if (-not $geoTexts.ContainsKey($lang)) { throw "缺少地理条件开关文案: $lang" }
    $geo = $geoTexts[$lang]
    $t.toggle['geo'] = $geo.toggle
    $t.toggleDesc['geo'] = $geo.desc

    # 该语言的官方货物译名
    $names = Get-RgoGoodsNames -GameRoot $gameRoot -Language $lang
    $missingNames = @($groups.Values | ForEach-Object { $_ } | Where-Object { -not $names.ContainsKey($_) })
    if ($missingNames.Count -gt 0) {
        throw ("语言 " + $lang + " 缺少以下货物的官方译名: " + ($missingNames -join ', '))
    }

    $sep = ', '
    if ($catTextSep.ContainsKey($lang)) { $sep = $catTextSep[$lang] }

    $hintMap = @{ tiers = $tierText; months = $RGO_COOLDOWN_MONTHS; cats = $catCount; toggles = $toggleCount }

    $sb = New-Object System.Text.StringBuilder
    # 语言头必须顶格（带缩进会被引擎判为 Invalid localization header indentation）
    [void]$sb.Append(('l_' + $lang + ':') + "`r`n")
    Add-LocLine $sb '# Generated by tools\generate_rgo_localization.ps1 - do not edit by hand'
    Add-LocLine $sb '# Goods names come from the vanilla goods_l_<lang>.yml; counts and lists from common\goods'
    Add-LocLine $sb ''
    Add-LocLine $sb '# Situation'
    Add-LocLine $sb ('UnconditionallyChangeRGO:0 "' + $t.situation + '"')
    Add-LocLine $sb ('UnconditionallyChangeRGO_desc:0 "' + $t.desc + '"')
    Add-LocLine $sb ''
    Add-LocLine $sb '# Scriptable hint: short title in the list, long text in _hint_text'
    Add-LocLine $sb ('hint_UnconditionallyChangeRGO:0 "' + $t.hintTitle + '"')
    $hintBody = Add-RgoGeoHintBullet -Text (Resolve-RgoText $t.hintText $hintMap) -Bullet $geo.hint
    Add-LocLine $sb ('hint_UnconditionallyChangeRGO_hint_text:0 "' + $hintBody + '"')
    Add-LocLine $sb ''
    Add-LocLine $sb '# Action card title (overrides the engine UI-library placeholder title)'
    Add-LocLine $sb ('RGO_CARD_HEADER:0 "' + $cardHeaders[$lang] + '"')
    Add-LocLine $sb ''
    Add-LocLine $sb '# Selection steps'
    Add-LocLine $sb ('RGO_select_goods:0 "' + $t.stepGoods + '"')
    Add-LocLine $sb ('RGO_select_location:0 "' + $t.stepLocation + '"')
    Add-LocLine $sb ('RGO_no_goods_available:0 "@trigger_no!' + $t.noGoods + '"')
    Add-LocLine $sb ('RGO_no_locations_available:0 "@trigger_no!' + $t.noLocations + '"')
    Add-LocLine $sb ''

    Add-LocLine $sb ('# Category buttons (' + $catCount + ')')
    foreach ($g in $groups.Keys) {
        $ids = $groups[$g]
        $goodsText = (($ids | ForEach-Object { $names[$_] }) -join $sep)
        $desc = Resolve-RgoText $t.catDesc[$g] @{ n = $ids.Count; goods = $goodsText }
        Add-LocLine $sb ('RGO_change_' + $g + ':0 "' + $t.cat[$g] + '"')
        Add-LocLine $sb ('RGO_change_' + $g + '_desc:0 "' + $desc + '"')
    }
    Add-LocLine $sb ''

    Add-LocLine $sb ('# Switches (' + $toggleCount + ')')
    foreach ($g in $RGO_TOGGLE_IDS) {
        $desc = Resolve-RgoText $t.toggleDesc[$g] $hintMap
        Add-LocLine $sb ('RGO_toggle_' + $g + ':0 "' + $t.toggle[$g] + '"')
        Add-LocLine $sb ('RGO_toggle_' + $g + '_desc:0 "' + $desc + '"')
    }
    Add-LocLine $sb ''
    Add-LocLine $sb '# Current state shown in the switch tooltip (chosen by trigger at hover time)'
    Add-LocLine $sb ('RGO_toggle_state_on:0 "' + $t.stateOn + '"')
    Add-LocLine $sb ('RGO_toggle_state_off:0 "' + $t.stateOff + '"')
    Add-LocLine $sb ''

    Add-LocLine $sb '# Price name (confirmation dialog)'
    Add-LocLine $sb ('rgo_change:0 "' + $t.price + '"')
    Add-LocLine $sb ''
    Add-LocLine $sb '# Cooldown static modifier'
    Add-LocLine $sb ('STATIC_MODIFIER_NAME_rgo_change_cooldown:0 "' + $t.modName + '"')
    Add-LocLine $sb ('STATIC_MODIFIER_DESC_rgo_change_cooldown:0 "' + $t.modDesc + '"')

    $outFile = Join-Path $modRoot ('in_game\localization\' + $lang + '\UnconditionallyChangeRGO_l_' + $lang + '.yml')
    Write-RgoTextFile -Path $outFile -Text $sb.ToString() -CheckOnly:$Check
    $written++
}

Write-Host ''
Write-Host ("已处理 {0} 种语言；分类 {1} 个，开关 {2} 个，货物 {3} 种" -f $written, $catCount, $toggleCount, (@($groups.Values | ForEach-Object { $_ }).Count))
foreach ($lang in $languages) { Write-Host ('  ' + $lang) }
if ($Check) { Write-Host '校验通过：11 种语言的本地化文件均为最新。' }
