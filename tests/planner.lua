-- Run from the workspace root with Lua 5.1: lua tests/planner.lua
local A = {}
local function loadAddon(filename)
    assert(loadfile("AlwaysBuffed/" .. filename .. ".lua"))("AlwaysBuffed", A)
end
loadAddon("Locale")
loadAddon("Planner")
loadAddon("Game")
loadAddon("Profiles")
loadAddon("Catalog")

local checks = 0
local function equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local food = {key = "food", kind = "food", icon = 1}
local foods = {
    {id = 11, name = "Feast", level = 35, stats = {agi = 20}},
    {id = 12, name = "Steak", level = 25, stats = {agi = 12}},
    {id = 13, name = "Soup", level = 15, stats = {agi = 8}},
    {id = 14, name = "Pie", level = 1, stats = {agi = 4}},
    {id = 15, name = "Bread", level = 25, stats = {}, isBasic = true},
}
local inv, prices = {[13]=2, [14]=1, [15]=1}, {[12]=75, [13]=15, [15]=1}
local ctx = {class = "HUNTER", level = 30, reminders = true, known = function() return false end,
    skill = function() return 0 end, info = function(item)
        return {count = inv[item.id], price = prices[item.id]}
    end}
local hunter = A.profiles.HUNTER[1]
local function plan(prefs) return A.PlanCategory(food, foods, ctx, prefs or {}, hunter) end
equal(plan().buy.item.id, 12, "shop independent of ownership")
equal(plan().bag.item.id, 13, "best owned")
equal(plan().rows[#foods].item.id, 11, "next level locked")
equal(plan({pin=14}).bag.item.id, 14, "owned pin wins")
equal(plan({pin=14, cheapest=true}).buy.item.id, 14, "pin wins over budget")
equal(plan({cheapest=true}).buy.item.id, 13, "cheapest priced buff")
equal(plan({cheapest=true}).bag.item.id, 13, "budget mode keeps best bag action")
prices[12], prices[13] = nil, nil
equal(plan({cheapest=true}).buy.item.id, 12, "no prices falls back to best")
equal(plan({pin=11}).buy.item.id, 12, "locked pin deferred")
inv[13] = nil
equal(plan().bag.item.id, 14, "exhausted stack")
inv[14] = nil
equal(plan().bag.item.id, 15, "plain food last")
inv[15] = nil
equal(plan().bag, nil, "no action with empty bags")
ctx.level = 35
equal(plan().buy.item.id, 11, "new level unlocks upgrade")
equal(plan({enabled=false}).tracked, false, "explicit opt-out survives preset")
local boundFood = {id=16, name="Quest steak", level=1, ownedOnly=true, stats={agi=99}}
foods[#foods+1] = boundFood
equal(plan().rows[1].item.id,11,"unowned quest duplicate stays below obtainable choices")
inv[16] = 1
equal(plan().bag.item.id,16,"owned special copy can be eaten")
equal(plan().buy.item.id,11,"bound special copy is never a shopping target")
foods[#foods+1] = {id=17,name="Experience food",level=1,stats={xp=100}}
ctx.level = 60
equal(plan().buy.item.id,11,"kill experience has no value at the level cap")
ctx.level = 35

local survival = A.profiles.HUNTER[3]
local buildItems = {
    {id=90, name="Spiced Skewers", stats={agi=7, xp=5}, level=5},
    {id=91, name="Fortifying Stew", stats={sta=12, xp=5}, level=5},
    {id=92, name="Caster Tea", stats={int=14}, level=5},
    {id=93, name="Mystical Drink", stats={mp5=12}, level=5, note="Restores your energy?"},
    {id=94, name="Plain Bread", stats={}, level=5, isBasic=true},
    {id=95, name="Healing draught", stats={heal=10}, level=5, note="Refreshes the bearer."},
    {id=96, name="Wisdom Pudding", stats={int=9, xp=5}, level=5},
}
inv[91], inv[92], inv[93], inv[94] = 2, 1, 1, 1
prices[90], prices[91], prices[92] = 40, 20, 1
local function buildPlan(profile, prefs)
    return A.PlanCategory(food, buildItems, ctx, prefs or {}, profile)
end
local function rowsByID(rows)
    local result = {}
    for _, row in ipairs(rows) do result[row.item.id] = row end
    return result
end
local build = buildPlan(survival)
local rows = rowsByID(build.rows)
equal(rows[90].group,"best","Survival benefits directly from Agility")
equal(rows[91].group,"utility","Survival benefits situationally from Stamina")
equal(rows[92].group,"notUseful","Survival does not recommend Intellect for its build")
equal(rows[93].group,"notUseful","pure mana regeneration is not useful to melee Survival")
equal(rows[96].group,"utility","off-stat food with kill XP remains useful while leveling")
equal(build.buy.item.id,90,"primary effect wins the ordinary shopping choice")
equal(build.bag.item.id,91,"owned useful food beats a mismatched stat and basic food")
equal(buildPlan(survival,{cheapest=true}).buy.item.id,91,"cheapest mode skips non-useful items")
equal(buildPlan(survival,{pin=92}).buy.item.id,92,"explicit pin can override build relevance when usable")
equal(buildPlan(survival,{pin=92}).bag.item.id,92,"explicit pin controls the carried action")
inv[91] = nil
equal(buildPlan(survival).bag.item.id,94,"basic food falls back before a mismatched effect")
inv[96] = 1
equal(buildPlan(survival).bag.item.id,96,"owned off-stat XP food takes priority over plain food")
ctx.level = 60
equal(rowsByID(buildPlan(survival).rows)[96].group,"notUseful","off-stat food loses its XP utility at cap")
equal(buildPlan(survival).bag.item.id,94,"plain food falls back before off-stat food at cap")
ctx.level = 35
equal(rowsByID(buildPlan(hunter).rows)[93].group,"utility","Beast Mastery considers mana regeneration situational")
equal(rowsByID(buildPlan(A.profiles.HUNTER[2]).rows)[92].group,"best","Marksmanship converts Intellect into attack power")
equal(A.MatchesItemSearch(rows[93],"ManA rEGEN"),true,"search matches mana regeneration synonyms")
equal(A.MatchesItemSearch(rows[95],"healing power"),true,"search matches healing synonyms")
equal(A.MatchesItemSearch(rows[93],"energy?"),true,"search keeps punctuation literal")
equal(A.MatchesItemSearch(rows[93],"energy."),false,"search does not apply Lua pattern metacharacters")
equal(A.MatchesItemSearch(rows[90],"   SPIcEd  "),true,"search ignores surrounding spaces and case")

local wep = {key="weapon",kind="weapon",slot=16}
local stone = {id=1,name="Sharpen",level=1,weapon="sharp",stats={weapon=2}}
local weight = {id=2,name="Weight",level=1,weapon="blunt",stats={weapon=2}}
local stones = {stone,weight}
inv[1], inv[2] = 1, 1
ctx.weapons = {[16] = "sharp"}
equal(A.PlanCategory(wep, stones, ctx, {pin=2}, survival).bag.item.id, 1, "incompatible pin skipped")
ctx.weapons[16] = "blunt"
equal(A.PlanCategory(wep, stones, ctx, {}, survival).buy.item.id, 2, "weapon swap")
ctx.weapons[16] = nil
equal(A.PlanCategory(wep, stones, ctx, {}, survival).buy, nil, "no weapon")

local categories = {}
for _, category in ipairs(A.categories) do categories[category.key] = category end
local sword, mace, shield = 101, 102, 103
local equipped = {[16] = sword, [17] = mace}
local itemTypes = {[sword] = {2, 7}, [mace] = {2, 4}, [shield] = {4, 6}}
local enchants = {}
local bagCounts = {[12404] = 2, [12643] = 1, [6947] = 3, [2892] = 4}
GetInventoryItemID = function(_, slot) return equipped[slot] end
GetTime = function() return 1000 end
C_Item = {
    GetItemInfoInstant = function(id) return nil, nil, nil, nil, nil, unpack(itemTypes[id]) end,
    IsItemDataCachedByID = function() return true end,
    GetItemInfo = function() end,
    GetItemCount = function(id) return bagCounts[id] or 0 end,
    GetWeaponEnchantInfo = function(slot) return enchants[slot] end,
}
C_SpellBook = {IsSpellKnown = function() return false end}
Enum = {WeaponSlot = {MainHand = 0, OffHand = 1}, ItemEnchantType = {Temporary = 2, Imbue = 3}}

local game, rogue = A.game, A.profiles.ROGUE[1]
A.state, A.db = {profile = rogue}, {preferences = {}}
A.Prefs("imbue").pin, A.Prefs("imbueOffhand").pin = 6947, 2892
local function handPlan(key)
    return A.PlanCategory(categories[key], A.catalog[key], game.Context("ROGUE", 35, false), A.Prefs(key), rogue)
end
local function handEffect(key)
    return game.ActiveEffect(categories[key], handPlan(key).rows, {}, {})
end
equal(handPlan("weapon").bag.item.id, 12404, "sharp main-hand stone")
equal(handPlan("weaponOffhand").bag.item.id, 12643, "blunt off-hand stone")
equal(handPlan("weaponOffhand").tracked, true, "dual-wield default shows off-hand stones")
equal(handPlan("imbue").buy.item.id, 6947, "main-hand poison shopping pin")
equal(handPlan("imbueOffhand").buy.item.id, 2892, "off-hand poison shopping pin")
equal(handPlan("imbue").bag.count, 3, "main-hand poison stock")
equal(handPlan("imbueOffhand").bag.count, 4, "off-hand poison stock")
equal(handPlan("imbueOffhand").tracked, true, "rogue default shows off-hand poisons")
bagCounts[2892] = nil
equal(handPlan("imbueOffhand").buy.item.id, 2892, "off-hand shopping pin survives empty stack")
equal(handPlan("imbueOffhand").bag.item.id, 6947, "off-hand fallback after its pinned poison runs out")
bagCounts[2892] = 4
A.Prefs("imbueOffhand").enabled = false
equal(handPlan("imbueOffhand").tracked, false, "off-hand poison opt-out applies independently")
equal(handPlan("imbue").tracked, true, "off-hand opt-out preserves main-hand poison tracking")
A.Prefs("imbueOffhand").enabled = nil

local function enchant(kind, id, left)
    return {hasEnchant = true, enchantType = Enum.ItemEnchantType[kind], enchantID = id, timeLeft = left}
end
enchants[0] = {enchant("Temporary", 1643, 45000), enchant("Imbue", 323, 12000)}
enchants[1] = {enchant("Temporary", 1703, 0)}
local name, expires = handEffect("imbue")
equal(name, "Instant Poison", "main-hand poison is identified")
equal(expires, 1012, "main-hand poison timer")
equal(handEffect("weapon"), "Dense Sharpening Stone", "main-hand stone and poison coexist")
equal(handEffect("weaponOffhand"), nil, "expired off-hand stone is inactive")
equal(handEffect("imbueOffhand"), nil, "uncoated off hand stays inactive")
enchants[1] = {enchant("Temporary", 1703, 27000), enchant("Imbue", 7, 18000)}
name, expires = handEffect("imbueOffhand")
equal(name, "Deadly Poison", "each hand reports its own active poison")
equal(expires, 1018, "off-hand poison timer")
name, expires = handEffect("weaponOffhand")
equal(name, "Dense Weightstone", "off-hand stone and poison coexist")
equal(expires, 1027, "off-hand stone timer remains separate")

equipped[16], equipped[17] = mace, sword
enchants[0], enchants[1] = enchants[1], enchants[0]
equal(handPlan("weapon").bag.item.id, 12643, "main-hand stone changes after weapon swap")
equal(handPlan("weaponOffhand").bag.item.id, 12404, "off-hand stone changes after weapon swap")
equal(handEffect("imbue"), "Deadly Poison", "active poison follows the equipped weapon")
equal(handPlan("imbueOffhand").bag.item.id, 2892, "poison pin stays with the hand")
equipped[17] = shield
equal(handPlan("weaponOffhand").tracked, false, "shield hides off-hand stones")
equal(handPlan("imbueOffhand").bag, nil, "shield prevents off-hand poison actions")
equal(handEffect("imbueOffhand"), nil, "shield excludes stale off-hand effects")
equipped[17] = nil
equal(handPlan("imbueOffhand").applicable, false, "missing off-hand weapon is inapplicable")
equal(handPlan("imbueOffhand").tracked, false, "single weapon hides off-hand poison")
equal(handPlan("imbueOffhand").buy, nil, "single weapon leaves no off-hand shopping entry")
equal(A.Prefs("imbueOffhand").pin, 2892, "removing a weapon retains its hand's pin")
equal(handPlan("imbue").tracked, true, "single weapon keeps main-hand poison")

-- Spot-check an actual Forever catalog choice for each named preset.
-- The final columns are the preferred and comparison item IDs from that category.
local specChoices = {
    {"WARRIOR", "arms", "weapon", 12404, 20749},
    {"WARRIOR", "fury", "elixir", 13452, 9206},
    {"WARRIOR", "protection", "elixirDefense", 250329, 13445},
    {"PALADIN", "retribution", "elixir", 21546, 9206},
    {"PALADIN", "holy", "elixir", 250333, 21546},
    {"PALADIN", "protection", "elixirDefense", 250329, 250335},
    {"HUNTER", "beastMastery", "elixir", 13452, 9179},
    {"HUNTER", "marksmanship", "elixir", 250328, 13452},
    {"HUNTER", "survival", "weapon", 3824, 20748},
    {"ROGUE", "combat", "weapon", 12404, 20749},
    {"ROGUE", "assassination", "imbue", 20844, 3776},
    {"ROGUE", "subtlety", "elixir", 9187, 9206},
    {"PRIEST", "shadow", "elixir", 9264, 21546},
    {"PRIEST", "discipline", "elixir", 21546, 9187},
    {"PRIEST", "holy", "elixir", 250333, 13454},
    {"SHAMAN", "enhancement", "imbue", 16362, 16342},
    {"SHAMAN", "elemental", "elixir", 250343, 13454},
    {"SHAMAN", "restoration", "elixirRegen", 250341, 20004},
    {"MAGE", "frost", "imbue", 277501, 277500},
    {"MAGE", "arcane", "elixir", 13454, 17708},
    {"MAGE", "fire", "elixir", 6373, 17708},
    {"WARLOCK", "affliction", "imbue", 13603, 13701},
    {"WARLOCK", "demonology", "imbue", 13700, 13602},
    {"WARLOCK", "destruction", "imbue", 13701, 13603},
    {"DRUID", "feral", "weapon", 12404, 20749},
    {"DRUID", "balance", "elixir", 250343, 9264},
    {"DRUID", "restoration", "weapon", 20748, 12404},
    {"DRUID", "bear", "elixirDefense", 250329, 250335},
}

local function fixtureContext(class, kind, subclass)
    return {class = class, level = 60, weapons = {[16] = kind}, weaponSubclasses = {[16] = subclass},
        info = function() return {count = 1} end, known = function() return true end,
        skill = function() return 300 end}
end

local levelingLevel = 20
local levelingBags = { [3664] = 1, [3390] = 1 }
local levelingPrices = { [2684] = 1 }
local function levelingPlan(key, prefs)
    local context = fixtureContext("HUNTER", "sharp", 7)
    context.level = levelingLevel
    context.info = function(item) return { count = levelingBags[item.id], price = levelingPrices[item.id] } end
    return A.PlanCategory(categories[key], A.catalog[key], context, prefs or {}, survival)
end
equal(levelingPlan("food").upgrade, nil, "Lv20 Survival carries its recommended food")
equal(levelingPlan("elixir").upgrade, nil, "Lv20 Survival carries its recommended elixir")
equal(levelingPlan("food", {pin=20074}).upgrade, nil, "a level-locked desired buy doesn't warn")
levelingLevel = 30
local stewUpgrade = levelingPlan("food")
equal(stewUpgrade.bag.item.id, 3664, "food upgrade leaves Crocolisk Gumbo usable")
equal(stewUpgrade.upgrade and stewUpgrade.upgrade.item.id, 20074, "Lv30 Survival recommends Heavy Crocolisk Stew")
equal(stewUpgrade.upgrade, stewUpgrade.buy, "upgrade uses the actual recommended row")
equal(levelingPlan("elixir").upgrade.item.id, 8949, "Lv30 Survival recommends Elixir of Agility")
equal(levelingPlan("food").upgrade.item.id, 20074, "replanning on the same level keeps the upgrade")
equal(levelingPlan("food", {pin=3664}).upgrade, nil, "tracking a carried choice clears its upgrade")
equal(levelingPlan("food", {pin=3728, cheapest=true}).upgrade.item.id, 3728, "explicit desired buy supersedes budget")
equal(levelingPlan("food", {cheapest=true}).upgrade, nil, "a cheaper but weaker buy is not an upgrade")
levelingPrices = { [3728] = 1 }
equal(levelingPlan("food", {cheapest=true}).upgrade.item.id, 3728, "an improved budget buy can warn")
equal(levelingPlan("food", {enabled=false}).upgrade, nil, "disabled category has no upgrade")
equal(levelingPlan("scrollFamiliar", {enabled=true}).upgrade, nil, "class-blocked category has no upgrade")
levelingBags[20074] = 1
equal(levelingPlan("food").upgrade, nil, "obtaining the suggested item clears the upgrade")
levelingLevel, levelingBags = 20, { [1017] = 1 }
equal(levelingPlan("food").buy.item.id, 3664, "name tie selects Crocolisk Gumbo over Seasoned Wolf Kabob")
equal(levelingPlan("food").upgrade, nil, "unowned equivalent food doesn't warn")
levelingBags = { [4541] = 1 }
equal(levelingPlan("food").bag.item.id, 4541, "plain bread remains usable")
equal(levelingPlan("food").upgrade.item.id, 3664, "useful food can upgrade plain bread")
levelingBags = {}
equal(levelingPlan("food").upgrade.item.id, 3664, "newly loaded empty bags can show a useful first buy")
equal(levelingPlan("food", {pin=2682}).upgrade.item.id, 2682, "useful XP-only desired buy can fill an empty slot")
levelingLevel = 60
equal(levelingPlan("food", {pin=2682}).upgrade, nil, "irrelevant desired buy at cap doesn't warn")

local upgradeContext = fixtureContext("HUNTER")
upgradeContext.info = function(item) return {count = item.id == 911 and 1 or 0} end
local foodByGroup = {
    {id=910, name="Agility food", level=1, stats={agi=1}},
    {id=911, name="Stamina food", level=1, stats={sta=60}},
}
local groupUpgrade = A.PlanCategory(food, foodByGroup, upgradeContext, {}, survival)
equal(groupUpgrade.buy.score < groupUpgrade.bag.score, true, "utility fixture has a higher raw score")
equal(groupUpgrade.upgrade.item.id, 910, "a better profile group takes priority over raw score")
upgradeContext.info = function(item) return {count = item.id == 910 and 1 or 0} end
equal(A.PlanCategory(food, foodByGroup, upgradeContext, {pin=911}, survival).upgrade, nil,
    "a stronger raw utility score doesn't upgrade a primary buff")

local trackedChoices = {
    {id=920, name="Chosen budget option", level=1, stats={agi=5}},
    {id=921, name="Previously offered premium option", level=1, stats={agi=20}},
    {id=922, name="Equivalent new option", level=25, stats={agi=5}},
    {id=923, name="Stronger new budget option", level=30, stats={agi=10}},
    {id=924, name="Available only when carried", level=30, stats={agi=10}, ownedOnly=true},
}
local trackedPrefs = {cheapest=true}
local owned = {[920]=1}
local prices = {[920]=10, [921]=500, [922]=30, [923]=50}
upgradeContext.info = function(item) return {count=owned[item.id], price=prices[item.id]} end
local function trackedPlan()
    return A.PlanCategory(food, trackedChoices, upgradeContext, trackedPrefs, survival)
end
upgradeContext.level = 20
A.SetTrackedItem(trackedPrefs, 920, trackedPlan())
equal(trackedPlan().upgrade, nil, "tracking acknowledges the premium item already available")
upgradeContext.level = 25
equal(trackedPlan().upgrade, nil, "a new item equal to the tracked choice does not alert")
upgradeContext.level = 30
local seenUpgrade = trackedPlan()
equal(seenUpgrade.upgrade and seenUpgrade.upgrade.item.id, 923,
    "an ignored premium item cannot silence a new upgrade over the tracked choice")
equal(seenUpgrade.bag.item.id, 920, "the manual action is unchanged even with an alert")
owned[924] = 1
equal(trackedPlan().upgrade, nil, "an equivalent carried item clears the alert without replacing the pin")
owned[924] = nil
trackedPrefs.enabled = false
equal(trackedPlan().upgrade, nil, "inactive tracked categories do not alert")
trackedPrefs.enabled = true
A.SetTrackedItem(trackedPrefs, 920, trackedPlan())
equal(trackedPlan().upgrade, nil, "keeping the budget choice acknowledges its new upgrade and the premium option stays quiet")
equal(trackedPlan().bag.item.id, 920, "acknowledgment preserves the originally tracked budget choice")

for _, example in ipairs(specChoices) do
    local class, key, category, preferred, alternative = unpack(example)
    local profile = A.SelectProfile(A.profiles[class], key, {})
    assert(profile.key == key, class .. " " .. key)
    local items = {}
    for _, item in ipairs(A.catalog[category]) do
        if item.id == preferred or item.id == alternative then items[#items + 1] = item end
    end
    assert(#items == 2, class .. " " .. key .. " catalog fixture")
    local context = class == "MAGE" and fixtureContext(class, "blunt", 10) or fixtureContext(class, "sharp", 7)
    local choices = A.PlanCategory(categories[category], items, context, {}, profile)
    equal(choices.bag and choices.bag.item.id, preferred, class .. " " .. key .. " build choice")
end

local mageArcane = A.SelectProfile(A.profiles.MAGE, "arcane", {})
local function mageImbues(kind, subclass)
    return A.PlanCategory(categories.imbue, A.catalog.imbue, fixtureContext("MAGE", kind, subclass), {}, mageArcane)
end
local mageStaffPlan = mageImbues("blunt", 10)
local staffRows = rowsByID(mageStaffPlan.rows)
local daggerRows = rowsByID(mageImbues("sharp", 15).rows)
equal(mageStaffPlan.tracked, true, "Mage main-hand Comprehension is tracked by default")
equal(mageArcane.tracked.scrollFamiliar, true, "Mage Familiar is tracked by default")
equal(staffRows[277486].group,"best","Arcane Missile proc directly contributes damage")
equal(staffRows[277486].eligible,true,"Striking can be applied to a staff")
equal(A.MatchesItemSearch(staffRows[277486], "ARCanE MissIlE"),true,"search matches the Mage damage proc name")
equal(mageStaffPlan.buy.item.id,277502,"spell crit ranks ahead of a small cooldown-limited proc")
equal(staffRows[277498].eligible,false,"staff cannot use the dagger-specific Manablade")
equal(daggerRows[277498].eligible,true,"dagger can use its mana proc scroll")
equal(daggerRows[277498].group,"utility","conditional mana restoration remains a utility effect")
equal(daggerRows[277489].eligible,false,"a sharp dagger cannot use a sword-only imbue")

for _, category in ipairs(A.categories) do
    if category.profession then
        local class = category.class or "HUNTER"
        local context = fixtureContext(class, "fishingPole", 20)
        local list = A.PlanCategory(category, A.catalog[category.key], context, {}, A.profiles[class][1])
        equal(list.enabled, false, category.key .. " starts unchecked")
        for _, row in ipairs(list.rows) do
            equal(row.group, "utility", category.key .. " ranks profession items as Utility")
        end
    end
end
local fishingContext = fixtureContext("HUNTER", "fishingPole", 20)
local function lurePlan(prefs)
    return A.PlanCategory(categories.fishingLure, A.catalog.fishingLure, fishingContext, prefs or {}, hunter)
end
equal(lurePlan().bag.item.id, 6533, "the strongest eligible lure still wins within Utility")
equal(lurePlan({pin = 6529}).bag.item.id, 6529, "a pin still overrides the profession ranking")

local rem = {key="sleepingBag",kind="reminder"}
local camp = {key="campfire",kind="reminder"}
local bag = {id=3,name="Sleeping bag",level=1,maxLevel=59,requireOwned=true}
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).tracked,false,"unowned bag reminder")
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).reminderReason,"Requires Cozy Sleeping Bag in your bags.","unowned bag reason")
inv[3] = 1
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).tracked,true,"owned bag reminder")
equal(A.PlanCategory(rem,{bag},ctx,{enabled=false},hunter).tracked,false,"sleeping bag can be turned off separately")
equal(A.PlanCategory(camp,{},ctx,{enabled=true},hunter).tracked,true,"campfire reminder keeps its own setting")
equal(A.PlanCategory(rem,{bag},ctx,{},hunter).buy,nil,"quest reward excluded from shopping")
ctx.level = 60
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).tracked,false,"level cap reminder")
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).reminderReason,"Available through level 59.","level cap reason")
ctx.reminders = false
equal(A.PlanCategory(camp,{},ctx,{enabled=true},hunter).tracked,false,"master reminder toggle")
ctx.level = 35
equal(A.PlanCategory(rem,{bag},ctx,{enabled=true},hunter).tracked,false,"master hides an otherwise eligible sleeping bag")

local cooking, kits = 220, { [279981] = 1, [279961] = 1, [279974] = 1 }
local campContext = {
    class = "HUNTER", level = 25, reminders = true,
    skill = function(id) return id == 185 and cooking or 0 end,
    known = function() error("campfire placement should not require a recipe or legacy spell") end,
    info = function(item) return { count = kits[item.id] or 0 } end,
}
local function campPlan(prefs)
    return A.PlanCategory(categories.campfire, A.catalog.campfire, campContext, prefs or {}, hunter)
end
local campOrder = campPlan()
equal(campOrder.rows[1].item.id, 279974, "campfire list ranks capacity first")
equal(campOrder.rows[2].item.id, 279961, "Journeyman is the second campfire tier")
equal(campOrder.bag.item.id, 279974, "best carried usable kit is Expert")
equal(campOrder.bag.item.useSpell, 1307237, "Expert kit uses the Forever placement spell")
equal(campPlan({pin = 279981}).bag.item.id, 279981, "explicit usable camp kit pin wins")
equal(campOrder.buy, nil, "campfire kits stay out of the upkeep shopping list")
equal(campOrder.upgrade, nil, "reminders never warn for upgrades")
cooking = 219
equal(campPlan({pin = 279974}).bag.item.id, 279961, "unusable Expert pin falls back to Journeyman")
equal(campPlan().bag.item.useSpell, 1307252, "Journeyman uses the distinct placement spell")
cooking = 89
equal(campPlan().bag.item.id, 279981, "higher kits are skipped below Cooking 90")
equal(campPlan().bag.item.useSpell, 1307227, "Basic uses the modern kit placement spell")
cooking = 0
equal(campPlan().bag, nil, "carrying a kit without Cooking does not arm a campfire action")
equal(campPlan().reminderReason, "Train Cooking to place a campfire kit.", "untrained Cooking explains the missing action")
cooking, kits = 220, { [279981] = 1 }
equal(campPlan({pin = 279961}).bag.item.id, 279981, "an unowned pin falls back to carried Basic")
cooking, kits = 90, { [279974] = 1 }
equal(campPlan().reminderReason, "Requires Cooking 220.", "carried higher kit explains its exact requirement")
kits = {}
equal(campPlan().bag, nil, "cooking skill alone never arms a recipe or old spell")
equal(campPlan().reminderReason, "Carry a campfire kit or use a nearby campsite.", "missing kit guidance")

local trees = A.profiles.PALADIN
local holy, prot = trees[2], trees[3]
local points = {[holy.talentGroupID]=10,[prot.talentGroupID]=12}
equal(A.SelectProfile(trees,"auto",points),prot,"dominant committed tree")
equal(A.SelectProfile(trees,holy.key,points),holy,"manual tree wins")
equal(A.SelectProfile(trees,"auto",{}),trees[1],"untalented leveling preset")
A.state, A.db = {profile=holy}, {preferences={}}
A.Prefs("food").pin = 42
A.state.profile = prot
equal(A.Prefs("food").pin,nil,"separate profile preferences")
A.state.profile = holy
equal(A.Prefs("food").pin,42,"stored profile preferences")

local seen, total, profiles = {}, 0, 0
for _, category in ipairs(A.categories) do
    assert(not seen[category.key] and #A.catalog[category.key] > 0, category.key)
    seen[category.key] = true
    local unique = {}
    for _, item in ipairs(A.catalog[category.key]) do
        assert(type(item.id)=="number" and item.level >= 1 and item.name ~= "", category.key)
        assert(not unique[item.id], "duplicate row in " .. category.key .. ": " .. item.id)
        unique[item.id] = true
        total = total + 1
    end
end
for _, choices in pairs(A.profiles) do
    for _, profile in ipairs(choices) do
        for key in pairs(profile.tracked) do assert(seen[key], "unknown tracked category: "..key) end
        profiles = profiles + 1
    end
end
print(("%d planner checks passed; validated %d catalog rows and %d profiles."):format(checks,total,profiles))
