-- Run from the workspace root with Lua 5.1.
local A = {}
local function loadAddon(name)
    assert(loadfile("AlwaysBuffed/" .. name .. ".lua"))("AlwaysBuffed", A)
end

GetLocale = function() return "deDE" end
C_Intl = {FoldCase = function(value) return (value:gsub("Ä", "ä"):lower()) end}
loadAddon("Locale")
A.L["Food"] = "Essen"
A.L["Main-Hand Poison"] = "Haupthandgift"
A.L["Beast Mastery"] = "Tierherrschaft"
A.L["Agi"] = "Bewegl."
A.L["Agility"] = "Beweglichkeit"
A.L["Level %d"] = "Stufe %d"
A.L["Bag food fallback"] = "Einfaches Essen aus der Tasche"
A.L["Camp Benefits"] = "Lagervorteile"

for _, name in ipairs({"Catalog", "Categories", "Profiles", "Planner", "Game"}) do loadAddon(name) end

local category = A.categories[1]
local hunter = A.profiles.HUNTER[1]
assert(category.key == "food" and category.label == "Essen")
assert(hunter.key == "beastMastery" and hunter.label == "Tierherrschaft")
A.ApplyClassLabels("ROGUE")
for _, entry in ipairs(A.categories) do
    if entry.key == "imbue" then assert(entry.label == "Haupthandgift") end
end

local catalog = {
    {id = 9001, name = "Apple", level = 5, stats = {agi = 3}, auras = {1001}},
    {id = 9002, name = "Berry", level = 5, stats = {agi = 3}},
}
local nativeItems = {[9001] = "Äpfel", [9002] = "Beeren", [9003] = "Brot", [9004] = "Wasser", [9005] = "Käse"}
local nativeSpells = {[1001] = "Satt", [433] = "Essen", [8017] = "Felsbeißer"}
local requested = {}
GetInventoryItemID = function() end
GetTime = function() return 100 end
C_Item = {
    IsItemDataCachedByID = function(id) return nativeItems[id] ~= nil end,
    GetItemInfo = function(id) return nativeItems[id], nil, nil, nil, 5 end,
    GetItemInfoInstant = function() return nil, nil, nil, nil, 42, 0, 5 end,
    RequestLoadItemDataByID = function(id) requested[id] = true end,
    GetItemCount = function() return 1 end,
    GetItemSpell = function(id)
        if id == 9003 then return nil, 433 end
        if id == 9005 then return "Essen", 434 end
        return "Trinken", 430
    end,
}
C_Spell = {
    GetSpellInfo = function(id) return {name = nativeSpells[id], iconID = 43} end,
    GetSpellName = function(id) return nativeSpells[id] end,
}
C_SpellBook = {IsSpellKnown = function() return true end}
local function foodPlan(level)
    return A.PlanCategory(category, catalog, A.game.Context("HUNTER", level), {}, hunter)
end
local plan = foodPlan(10)
assert(plan.bag.item.id == 9001 and plan.bag.name == "Äpfel", "locale does not change the ranked choice")
assert(A.MatchesItemSearch(plan.bag, "  ÄPFEL  "), "case-folded localized item names are searchable")
assert(A.MatchesItemSearch(plan.bag, "äpfel"), "lowercase query matches the native uppercase name")
assert(A.MatchesItemSearch(plan.bag, "Bewegl."), "the abbreviated localized stat label is searchable")
assert(A.MatchesItemSearch(plan.bag, "Beweglichkeit"), "the full localized stat name is searchable")
assert(foodPlan(1).rows[1].reason == "Stufe 5", "the level restriction formats a localized template")
nativeItems[9001] = nil
assert(foodPlan(10).bag.name == "Apple" and requested[9001], "uncached item uses its catalog name and requests data")
assert(A.game.ItemArrived(9001))
nativeItems[9001] = "Äpfel"
assert(foodPlan(10).bag.name == "Äpfel", "loaded item data supplies its name in the client locale")
local spell = A.game.Context("SHAMAN", 10).info({id = 8017, spell = 8017})
assert(spell.name == "Felsbeißer" and spell.icon == 43)

NUM_BAG_SLOTS = 0
C_Container = {GetContainerNumSlots = function() return 3 end, GetContainerItemID = function(_, slot) return 9002 + slot end}
local extras = A.game.FoodWithBagFallback(catalog)
assert(#extras == 4 and extras[1].id == 9003 and extras[2].id == 9005, "food recognizes both IDs and localized rank names")
assert(extras[1].name == "Brot" and extras[1].note == "Einfaches Essen aus der Tasche")

local auras = {[1001] = {spellId = 1001, expirationTime = 200}}
local name, expires = A.game.ActiveEffect(category, foodPlan(10).rows, auras, {}, true)
assert(name == "Satt" and expires == 200, "an unreadable aura name falls back to its localized spell ID")
auras[1001].name = "Gut genährt"
assert(A.game.ActiveEffect(category, foodPlan(10).rows, auras, {}, true) == "Gut genährt")
local camp
for _, entry in ipairs(A.categories) do
    if entry.key == "campfire" then camp = entry end
end
C_UnitAuras = {GetPlayerAuraBySpellID = function(id) return {spellId = id, expirationTime = 200} end}
assert(A.game.ActiveEffect(camp, {}, {}, {}, true) == "Lagervorteile", "unavailable native names use the localized aura fallback")
print("Localized categories, profiles, planner, item cache, spell names, bag food, and active auras passed.")
