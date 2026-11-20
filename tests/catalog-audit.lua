-- Run with Lua 5.1 from the repository root.
local A = { theme = { colors = {} } }
for _, name in ipairs({"Locale", "Catalog", "Categories", "Profiles", "Planner", "Game", "Actions"}) do
    assert(loadfile("AlwaysBuffed/" .. name .. ".lua"))("AlwaysBuffed", A)
end

local categories, wheelSizes = {}, {}
local retiredDrinks = {[17048] = true, [20709] = true, [21114] = true, [21151] = true, [287972] = true,
    [18269] = true, [18284] = true}
for _, category in ipairs(A.categories) do
    assert(not categories[category.key], "duplicate category " .. category.key)
    assert(A.catalog[category.key] and #A.catalog[category.key] > 0)
    categories[category.key] = category
    local bar = category.profession or "combat"
    wheelSizes[bar] = (wheelSizes[bar] or 0) + 1
    for _, item in ipairs(A.catalog[category.key]) do
        assert(not retiredDrinks[item.id], "the retired drink must not appear in any category")
    end
end
for bar, count in pairs(wheelSizes) do
    assert(count <= 35, bar .. " wheel exceeds the available atlas masks")
end
assert(not categories.buffDrinks and not A.catalog.buffDrinks, "Buff Drinks is absent")

local activeGear = {[16] = 700001, [17] = 700002}
local gearTypes = {[700001] = {2, 10}, [700002] = {4, 6}, [700003] = {2, 15}, [700004] = {2, 7}}
local inBags = {}
local activeEnchants = {}
Enum = { WeaponSlot = {MainHand = 0, OffHand = 1}, ItemEnchantType = {Temporary = 1, Imbue = 2} }
function GetInventoryItemID(_, slot) return activeGear[slot] end
function GetTime() return 500 end
function InCombatLockdown() return false end
C_Item = {
    GetItemInfoInstant = function(id)
        local gear = gearTypes[id]
        return nil, nil, nil, nil, nil, gear and gear[1], gear and gear[2]
    end,
    IsItemDataCachedByID = function() return true end,
    GetItemInfo = function() end,
    GetItemCount = function(id) return inBags[id] or 0 end,
    GetWeaponEnchantInfo = function(slot) return activeEnchants[slot] end,
}
C_SpellBook = { IsSpellKnown = function() return false end }
C_SkillInfo = { GetSkillLineInfoByID = function() end }

local function plan(key, class, level, preferences)
    return A.PlanCategory(categories[key], A.catalog[key], A.game.Context(class, level, true),
        preferences or {}, A.profiles[class][1])
end

-- A staff can use a direct spell-damage proc and oil independently. An armor
-- item in the off hand cannot be recommended as a weapon target.
inBags = {[277486] = 1, [20744] = 1, [277488] = 1, [275069] = 1}
local imbue = plan("imbue", "MAGE", 25)
local oil = plan("weapon", "MAGE", 25)
assert(imbue.tracked and imbue.bag.item.id == 277486 and imbue.bag.group == "best")
assert(oil.tracked and oil.bag.item.id == 20744)
assert(plan("scrollFamiliar", "MAGE", 25).bag.item.id == 275069)
assert(not plan("imbueOffhand", "MAGE", 25).applicable)
assert(not A.CategoryForClass(categories.scrollFamiliar, "ROGUE"))
for _, row in ipairs(imbue.rows) do
    if row.item.id == 277488 then assert(not row.eligible) end
end

-- The same slots change independently when the active weapon is swapped.
activeGear[16] = 700003
assert(plan("imbue", "MAGE", 25).bag.item.id == 277488)
assert(plan("weapon", "MAGE", 25).bag.item.id == 20744)
activeGear[16], activeGear[17] = 700004, 700003
inBags = {[2862] = 2, [6947] = 2, [3775] = 1}
local mainStone = plan("weapon", "ROGUE", 25)
local offStone = plan("weaponOffhand", "ROGUE", 25)
local mainPoison = plan("imbue", "ROGUE", 25)
local offPoison = plan("imbueOffhand", "ROGUE", 25, {pin = 3775})
assert(mainStone.bag.item.id == 2862 and offStone.bag.item.id == 2862)
assert(mainPoison.bag.item.id == 6947 and offPoison.bag.item.id == 3775)
assert(offPoison.bag.group == "utility")
assert(A.MatchesItemSearch(offPoison.bag, "movement slow"))

activeEnchants[0] = {
    {hasEnchant = true, enchantType = 1, timeLeft = 10000, enchantID = 40},
    {hasEnchant = true, enchantType = 2, timeLeft = 20000, enchantID = 323},
}
activeEnchants[1] = {
    {hasEnchant = true, enchantType = 1, timeLeft = 30000, enchantID = 40},
    {hasEnchant = true, enchantType = 2, timeLeft = 40000, enchantID = 22},
}
assert(A.game.ActiveEffect(categories.weapon, mainStone.rows) == "Rough Sharpening Stone")
assert(A.game.ActiveEffect(categories.imbue, mainPoison.rows) == "Instant Poison")
assert(A.game.ActiveEffect(categories.weaponOffhand, offStone.rows) == "Rough Sharpening Stone")
local active, expires = A.game.ActiveEffect(categories.imbueOffhand, offPoison.rows)
assert(active == "Crippling Poison" and expires == 540)

-- AP choices share a selector, while the other maintained buffs keep their
-- own selectors. Bound quest items can be used from bags, never shopped.
inBags = {[12820] = 1, [12460] = 1, [12217] = 1, [249865] = 1, [21151] = 1, [8412] = 1, [11567] = 1}
local attackPower = plan("elixirAttackPower", "ROGUE", 55)
assert(attackPower.bag.item.id == 12460 and attackPower.buy.item.auras[1] == 17038)
assert(plan("foodChili", "ROGUE", 55).bag.item.id == 12217)
local tea = plan("food", "PRIEST", 55).bag
assert(tea.item.id == 249865 and tea.item.auras[1] == 1249927, "a real Well Fed tea is still selectable")
assert(plan("elixirBlastedLands", "ROGUE", 55).bag.item.id == 8412)
assert(not plan("elixirBlastedLands", "ROGUE", 55).buy)
local crystal = plan("crystalSpire", "ROGUE", 55).bag
local attrs = {}
local button = { SetAttribute = function(_, key, value) attrs[key] = value end }
A.SetAction(button, categories.crystalSpire, crystal)
assert(attrs["*unit1"] == "player" and not attrs["*target-slot1"])
A.SetAction(button, categories.imbueOffhand, offPoison.bag)
assert(not attrs["*unit1"] and attrs["*target-slot1"] == 17)

-- Feed skill and bag changes through Game.Context into the secure button.
inBags = { [279981] = 1, [279961] = 1, [279974] = 1 }
local cooking
C_SkillInfo.GetSkillLineInfoByID = function(id)
    if id == 185 and cooking then return { rank = cooking } end
end
for _, fixture in ipairs({ {220, 279974}, {219, 279961}, {89, 279981}, {} }) do
    cooking = fixture[1]
    local kit = plan("campfire", "ROGUE", 25).bag
    A.SetAction(button, categories.campfire, kit)
    local expectedItem = fixture[2] and "item:" .. fixture[2]
    assert(attrs["*item1"] == expectedItem and not attrs["*spell1"])
    assert(attrs["*unit1"] == (expectedItem and "player") and not attrs["*target-slot1"])
end
print("catalog audit tests passed")
