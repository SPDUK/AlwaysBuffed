-- A fresh login with the release TOC and saved settings from before the category split.
local function noop() end
local frames, class = {}, "ROGUE"
local frameMethods = { SetPoint=noop, SetText=noop, SetSize=noop, SetFont=function() return true end,
    RegisterEvent=noop, RegisterUnitEvent=noop, SetScript=function(self, key, fn) self[key] = fn end }
function CreateFrame()
    local frame = setmetatable({}, {__index=frameMethods})
    frames[#frames + 1] = frame
    return frame
end
frameMethods.CreateFontString = CreateFrame
Settings = {RegisterCanvasLayoutCategory=noop, RegisterAddOnCategory=noop}
SlashCmdList = {}
function UnitClass() return class, class end
function UnitLevel() return 32 end
function GetLocale() return "enUS" end
function GetTime() return 1000 end
function InCombatLockdown() return false end
function GetInventoryItemID() return 99 end
NUM_BAG_SLOTS = 4
Enum = {WeaponSlot={MainHand=0, OffHand=1}, ItemEnchantType={Temporary=1, Imbue=2}}
C_Container = {GetContainerNumSlots=function() return 0 end}
C_Spell = {GetSpellName=function(id) return tostring(id) end, GetSpellInfo=noop}
C_SpellBook = {IsSpellKnown=function() return false end}
C_ClassTalents = {GetActiveConfigID=noop}
C_SkillInfo = {GetSkillLineInfoByID=noop}
C_UnitAuras = {GetAuraDataByIndex=noop}
C_Item = {
    IsItemDataCachedByID=function() return false end, RequestLoadItemDataByID=noop,
    GetItemInfoInstant=function() return nil, nil, nil, nil, 1, 2, 15 end,
    GetItemCount=function() return 0 end, GetWeaponEnchantInfo=function() return {} end,
}

local A = {}
for line in io.lines("AlwaysBuffed/AlwaysBuffed.toc") do
    local entry = line:match("^%s*([%w_/]+%.lua)%s*$")
    if entry then assert(loadfile("AlwaysBuffed/" .. entry))("AlwaysBuffed", A) end
end
local event = assert(frames[#frames].OnEvent)
-- The Lua model and client adapter are exercised here. Widget behavior has separate suites.
A.InitActions, A.InitWheel, A.RefreshActions, A.RefreshOptions, A.RefreshWheel = noop, noop, noop, noop, noop
local preferences = {
    combat = {elixir={pin=12820, cheapest=true}, imbueOffhand={pin=2892}, buffDrinks={enabled=true, pin=21151}},
    subtlety = {elixir={pin=246948, enabled=false}, elixirAttackPower={pin=12460}, buffDrinks={enabled=false}},
}
AlwaysBuffedDB = {preferences=preferences, profile="combat"}
event(nil, "PLAYER_LOGIN")
assert(A.state.class == "ROGUE" and A.state.profile.key == "combat")
assert(A.db.barOrientation == "horizontal" and A.db.mouseoverOnly == false)
assert(A.db.preferences.combat.elixir.pin == nil)
assert(A.db.preferences.combat.elixirAttackPower.pin == 12820)
assert(A.db.preferences.combat.elixirAttackPower.enabled and A.db.preferences.combat.elixirAttackPower.cheapest)
assert(A.db.preferences.subtlety.elixirAttackPower.pin == 12460)
assert(A.db.preferences.combat.imbueOffhand.pin == 2892)
assert(not A.db.preferences.combat.buffDrinks and not A.db.preferences.subtlety.buffDrinks)
assert(not A.state.categories.buffDrinks)
for _, category in ipairs(A.categories) do
    assert(A.state.categories[category.key], category.key)
    if category.key == "imbueOffhand" then assert(category.label == "Off-Hand Poison") end
end
assert(A.state.categories.imbue.tracked and A.state.categories.imbueOffhand.tracked)
A.db.barOrientation, A.db.mouseoverOnly = "vertical", true
event(nil, "PLAYER_LOGIN")
assert(A.db.barOrientation == "vertical" and A.db.mouseoverOnly == true)
A.db.barOrientation = "unknown"
event(nil, "PLAYER_LOGIN")
assert(A.db.barOrientation == "horizontal")
assert(A.db.preferences.combat.elixirAttackPower.pin == 12820)
print("Release TOC, cold login and per-profile preference migration passed.")

class = "HUNTER"
local level, carried, after = 20, {[3664] = 6}
UnitLevel = function() return level end
C_Item.GetItemCount = function(id) return carried[id] or 0 end
C_Timer = {After = function(_, f) after = f end}
AlwaysBuffedDB = { profile = "survival" }
event(nil, "PLAYER_LOGIN")
local function food() return A.state.categories.food end
assert(food().bag.item.id == 3664 and not food().upgrade)
event(nil, "PLAYER_LEVEL_UP", 30)
assert(after)()
assert(A.state.level == 30 and food().upgrade.item.id == 20074 and food().bag.item.id == 3664)
level, carried[20074] = 30, 2
event(nil, "BAG_UPDATE_DELAYED")
after()
assert(food().bag.item.id == 20074 and not food().upgrade)
print("Level-up and bag events promoted and cleared a Survival hunter's food upgrade.")
