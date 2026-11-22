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
function strtrim(text) return text:match("^%s*(.-)%s*$") end
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
    combat = {elixir={pin=12820, cheapest=true}, imbueOffhand={pin=2892}, buffDrinks={enabled=true, pin=21151},
        herbalismDraught={pin=250326}, miningDraught={enabled=false}, herbalismTea={pin=10841}},
    subtlety = {elixir={pin=246948, enabled=false}, elixirAttackPower={pin=12460}, buffDrinks={enabled=false},
        miningDraught={pin=250326}, herbalismDraught={enabled=false}},
}
AlwaysBuffedDB = {preferences=preferences, profile="combat", barMode="mining"}
event(nil, "PLAYER_LOGIN")
local function chat(input)
    local alias, args = input:match("^(%S+)%s*(.*)$")
    for name, handler in pairs(SlashCmdList) do
        local prefix, index = "SLASH_" .. name, 1
        while _G[prefix .. index] do
            if _G[prefix .. index] == alias then return handler(args) end
            index = index + 1
        end
    end
    error("Unregistered slash command: " .. alias)
end

do
    local toggleOptions, toggleWheel = A.ToggleOptions, A.ToggleWheel
    local opened, wheeled = 0, 0
    A.ToggleOptions = function() opened = opened + 1 end
    A.ToggleWheel = function() wheeled = wheeled + 1 end
    for _, alias in ipairs({"/alwaysbuffed", "/ab"}) do
        chat(alias)
        chat(alias .. " wheel")
    end
    assert(opened == 2 and wheeled == 2, "both registered aliases dispatch to settings and the wheel")
    A.ToggleOptions, A.ToggleWheel = toggleOptions, toggleWheel
end
assert(A.state.class == "ROGUE" and A.state.profile.key == "combat")
assert(A.db.mouseoverOnly == false)
assert(A.db.preferences.combat.elixir.pin == nil)
assert(A.db.preferences.combat.elixirAttackPower.pin == 12820)
assert(A.db.preferences.combat.elixirAttackPower.enabled and A.db.preferences.combat.elixirAttackPower.cheapest)
assert(A.db.preferences.subtlety.elixirAttackPower.pin == 12460)
assert(A.db.preferences.combat.imbueOffhand.pin == 2892)
assert(not A.db.preferences.combat.buffDrinks and not A.db.preferences.subtlety.buffDrinks)
assert(not A.state.categories.buffDrinks)
assert(A.db.barMode == "auto" and not A.state.barProfession, "a saved Mining mode falls back to Automatic")
assert(A.db.preferences.combat.herbalismTea.pin == 10841)
for _, key in ipairs({"herbalismDraught", "miningDraught"}) do
    assert(not A.db.preferences.combat[key] and not A.db.preferences.subtlety[key] and not A.state.categories[key])
end
for _, category in ipairs(A.categories) do
    assert(A.state.categories[category.key], category.key)
    if category.key == "imbueOffhand" then assert(category.label == "Off-Hand Poison") end
end
assert(A.state.categories.imbue.tracked and A.state.categories.imbueOffhand.tracked)
A.db.barOrientation, A.db.mouseoverOnly = "vertical", true
event(nil, "PLAYER_LOGIN")
assert(A.db.barOrientation == "vertical" and A.db.mouseoverOnly == true)
A.db.barOrientation, A.db.barDirection = "unknown", "up"
event(nil, "PLAYER_LOGIN")
assert(A.db.barOrientation == nil and A.db.barDirection == "up")
assert(A.db.preferences.combat.elixirAttackPower.pin == 12820)
A.db.barDirection = "unknown"
event(nil, "PLAYER_LOGIN")
assert(A.db.barDirection == nil)
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

level, carried = 20, {[3664] = 6}
AlwaysBuffedDB = {profile = "survival", preferences = {survival = {food = {pin = 3664}}}}
event(nil, "PLAYER_LOGIN")
local trackedFood = A.Prefs("food")
assert(food().bag.item.id == 3664 and not food().upgrade, "an old pin is initialized without showing existing choices")
event(nil, "PLAYER_LEVEL_UP", 25)
after()
assert(food().upgrade and food().upgrade.item.id == 20074,
    "learning level 25 restores the upgrade badge even with tracked Crocolisk Gumbo")
assert(food().buy.item.id == 3664 and food().bag.item.id == 3664, "an upgrade does not replace the tracked action")
level = 25
event(nil, "PLAYER_LOGIN")
assert(food().upgrade and food().upgrade.item.id == 20074, "the alert persists across login")
carried[20074] = 1
event(nil, "BAG_UPDATE_DELAYED")
after()
assert(not food().upgrade and food().bag.item.id == 3664, "carrying the upgrade removes the badge without changing the action")
carried[20074] = nil
A.SetTrackedItem(trackedFood, 3664, food())
A.Update()
assert(not food().upgrade and trackedFood.pin == 3664, "keeping the current choice acknowledges the current options")
event(nil, "PLAYER_LEVEL_UP", 35)
after()
assert(food().upgrade and food().upgrade.item.id == 13932 and food().bag.item.id == 3664,
    "a stronger later unlock brings the badge back while the tracked item stays assigned")
print("Tracked food preserves its action across unlocks, acquiring upgrades, acknowledgment, and reload.")

-- Load the profession feature through the same event frame and catalog as a player.
class, level = "ROGUE", 32
local dagger, pole, uncachedDagger, fishingHat, fishingBoots = 2092, 6256, 2494, 259846, 19969
local gear, subclasses = {[16] = dagger, [17] = dagger}, {[dagger] = 15, [pole] = 20}
local itemRequests, auras = {}, {}
local now, fishingSkill, locked = 1000, 1, false
local cooldownStart, cooldownDuration, gearTimer
local refreshes = 0
function GetTime() return now end
function InCombatLockdown() return locked end
function GetInventoryItemID(_, slot) return gear[slot] end
function GetInventoryItemCooldown(_, slot)
    assert(slot == 1, "read the cooldown from the hat's equipment slot")
    return cooldownStart or 0, cooldownDuration or 0
end
function C_Item.GetItemInfoInstant(id)
    if id == uncachedDagger and not subclasses[id] then return end
    return nil, nil, nil, nil, 1, subclasses[id] and 2 or 0, subclasses[id] or 0
end
function C_Item.RequestLoadItemDataByID(id) itemRequests[id] = true end
function C_SkillInfo.GetSkillLineInfoByID(id)
    return id == 356 and {rank = fishingSkill} or nil
end
function C_UnitAuras.GetAuraDataByIndex(_, index) return auras[index] end
function C_Spell.GetSpellName(id) return id == 19705 and "Well Fed" or tostring(id) end
function C_Timer.NewTimer(delay, callback)
    gearTimer = {delay = delay, fire = callback, Cancel = noop}
    return gearTimer
end
A.RefreshActions = function() refreshes = refreshes + 1 end
A.RefreshGripCounts = noop
carried = {[6529] = 2, [6530] = 1, [6533] = 1, [4594] = 1, [fishingBoots] = 1}

local function temporary(id)
    return {hasEnchant = true, enchantType = Enum.ItemEnchantType.Temporary, enchantID = id, timeLeft = 60000}
end
local poison = {hasEnchant = true, enchantType = Enum.ItemEnchantType.Imbue, enchantID = 323, timeLeft = 100000}
local mainEnchants, offEnchants = {temporary(40), poison}, {temporary(40)}
function C_Item.GetWeaponEnchantInfo(hand)
    return hand == Enum.WeaponSlot.MainHand and mainEnchants or offEnchants
end

local function process(name, ...)
    assert(not after, "flush any previous event before processing " .. name)
    event(nil, name, ...)
    local callback = assert(after, "expected a queued update for " .. name)
    after = nil
    callback()
end
local function plan(key) return assert(A.state.categories[key]) end
local function lure() return plan("fishingLure") end
local function rowFor(category, id)
    for _, row in ipairs(plan(category).rows) do
        if row.item.id == id then return row end
    end
    error("missing catalog row " .. id .. " in " .. category)
end

AlwaysBuffedDB, after = {barMode = "comprehension", fishingGearItemID = -1}, nil
event(nil, "PLAYER_LOGIN")
assert(A.db.barMode == "auto" and not A.db.fishingGearItemID, "invalid saved mode and equipment marker are reset")
assert(not A.state.barProfession, "a melee loadout uses the combat bar automatically")
assert(plan("weapon").active == "Rough Sharpening Stone" and plan("imbue").active == "Instant Poison")
assert(not lure().applicable and not lure().active and not lure().bag, "combat weapons cannot receive or report a lure")
A.SetBarMode("comprehension")
assert(A.db.barMode == "auto", "a Rogue cannot select the Mage bar")

gear[16], mainEnchants = pole, {temporary(263), poison}
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(A.db.barMode == "auto" and not A.state.barProfession, "a pole alone leaves the Combat bar active")
A.Prefs("fishingCoin").enabled = true
A.Update()
assert(A.state.barProfession == "fishing" and not plan("fishingCoin").bag, "one enabled Fishing buff suffices even with no item")
A.db.profile = "subtlety"
A.Update()
assert(not A.state.barProfession, "an opt-in on another profile cannot switch this profile's bar")
A.db.profile = "auto"
A.Update()
assert(A.state.barProfession == "fishing", "returning to the opted-in profile uses the already-equipped pole")
assert(lure().bag.item.id == 6529 and lure().active == "+25 Fishing" and lure().expires == 1060)
assert(not plan("weapon").active and not plan("imbue").active, "the pole clears the old main-hand combat enchants")
assert(plan("weaponOffhand").active == "Rough Sharpening Stone", "the other hand keeps its own enchant")
assert(rowFor("fishingLure", 6530).reason == "Requires Fishing 50")
assert(rowFor("fishingLure", 6533).reason == "Requires Fishing 100")
fishingSkill = 55
process("SKILL_LINES_CHANGED")
assert(lure().bag.item.id == 6530, "gaining Fishing skill promotes the strongest eligible carried lure")
fishingSkill = 100
process("SKILL_LINES_CHANGED")
assert(lure().bag.item.id == 6533, "a +100 fishing lure outranks the lower bonuses")
mainEnchants = {temporary(40), poison}
process("UNIT_INVENTORY_CHANGED", "player")
assert(not lure().active and not plan("weapon").active and not plan("imbue").active,
    "an unrelated enchant reported on a pole is neither a recognized lure nor a combat enchant")

local normalMeal = {spellId = 19705, name = "Well Fed", duration = 900, expirationTime = 1600, auraInstanceID = 1}
local fishingMeal = {spellId = 1249521, name = "Well Fed", duration = 900, expirationTime = 1900, auraInstanceID = 2}
auras = {normalMeal}
process("UNIT_AURA", "player")
assert(not plan("fishingFood").active and plan("food").active == "Well Fed",
    "ordinary Well Fed does not activate the fishing food slot")
auras = {fishingMeal, normalMeal}
process("UNIT_AURA", "player")
assert(plan("fishingFood").bag.item.id == 4594 and plan("fishingFood").activeSpellID == 1249521
    and plan("fishingFood").expires == 1900, "same-name auras cannot obscure the native fishing food spell and expiry")
auras = {normalMeal}
process("UNIT_AURA", "player", {removedAuraInstanceIDs = {2}})
assert(not plan("fishingFood").active and plan("food").active, "fishing food clears while ordinary Well Fed remains")

gear[16] = uncachedDagger
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(itemRequests[uncachedDagger] and A.state.barProfession == "fishing", "unknown gear does not eject the fishing bar")
subclasses[uncachedDagger] = 15
process("ITEM_DATA_LOAD_RESULT", uncachedDagger, true)
assert(not A.state.barProfession and plan("weapon").active == "Rough Sharpening Stone",
    "late item metadata restores the combat bar and the ordinary enchant")

local beforeCombat = refreshes
locked, gear[16] = true, pole
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(not A.state.barProfession and refreshes == beforeCombat, "auto equipment changes defer bar and action rebuilds in combat")
locked = false
process("PLAYER_REGEN_ENABLED")
assert(A.state.barProfession == "fishing" and refreshes > beforeCombat, "leaving combat applies the deferred equipment change")
locked, beforeCombat = true, refreshes
A.SetBarMode("combat")
assert(A.db.barMode == "combat" and A.state.barProfession == "fishing" and refreshes == beforeCombat,
    "manual mode is saved while the effective bar stays fixed in combat")
locked = false
process("PLAYER_REGEN_ENABLED")
assert(not A.state.barProfession and refreshes > beforeCombat, "leaving combat activates the saved Combat mode over the pole")
A.SetBarMode("mining")
assert(A.db.barMode == "combat" and not A.state.barProfession, "retired Mining mode cannot be selected")

gear[16] = dagger
A.SetBarMode("auto")
chat(("/alwaysbuffed fishgear |cffffffff|Hitem:%d:0|h[Nat Pagle's Extreme Anglin' Boots]|h|r"):format(fishingBoots))
assert(A.db.fishingGearItemID == fishingBoots and not A.state.barProfession, "merely carrying marked gear does not activate Fishing")
gear[8] = fishingBoots
process("PLAYER_EQUIPMENT_CHANGED", 8)
assert(A.state.barProfession == "fishing" and not lure().applicable, "marked equipment activates Fishing without turning a dagger into a pole")
A.Prefs("fishingCoin").enabled = false
A.Update()
assert(not A.state.barProfession, "marked equipment also needs an enabled Fishing buff")
A.Prefs("fishingLure").enabled = true
A.Update()
assert(A.state.barProfession == "fishing", "an enabled lure counts even when the marked gear is not a pole")
A.SetBarMode("combat")
assert(not A.state.barProfession, "manual Combat overrides marked gear as well")
A.SetBarMode("auto")
assert(A.state.barProfession == "fishing", "restoring auto uses the currently marked equipment")
gear[8] = nil
process("PLAYER_EQUIPMENT_CHANGED", 8)
assert(not A.state.barProfession, "taking off the marked item returns to combat")
chat("/ab fishgear clear")
gear[8] = fishingBoots
process("PLAYER_EQUIPMENT_CHANGED", 8)
assert(not A.db.fishingGearItemID and not A.state.barProfession, "clearing the marker stops the item from switching the bar")

gear[16], carried[fishingHat], carried[6530], carried[6533] = pole, 1, nil, nil
fishingSkill = 1
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(rowFor("fishingLure", fishingHat).reason == "Must be equipped" and lure().bag.item.id == 6529,
    "a fishing hat in the bag is ineligible")
carried[fishingHat], gear[1] = nil, fishingHat
process("PLAYER_EQUIPMENT_CHANGED", 1)
assert(lure().bag.item.id == fishingHat, "a ready equipped hat wins over an equally strong consumable")
carried[6529] = nil
process("BAG_UPDATE_DELAYED")
assert(lure().bag.item.id == fishingHat, "the equipped hat can apply a lure without any bag items")
carried[6529], cooldownStart, cooldownDuration = 1, now, 10
process("BAG_UPDATE_COOLDOWN")
assert(rowFor("fishingLure", fishingHat).reason == "On cooldown" and lure().bag.item.id == 6529,
    "a cooling-down hat falls back to the available bag lure")
assert(gearTimer and gearTimer.delay == 10)
now, carried[6529] = now + 10, nil
gearTimer.fire()
assert(lure().bag.item.id == fishingHat, "the cooldown timer restores the equipped hat without another event")
print("Profession login, equipment switches, combat deferral, lure ranks and cooldowns, and fishing food auras passed.")

-- Owned sources and existing auras are independent. An empty inventory still
-- reports a known gathering buff, including one received from a shared camp.
level, carried = 40, {[10841] = 1}
A.SetBarMode("combat")
assert(plan("herbalismTea").bag.item.id == 10841 and not plan("herbalismTea").buy)
auras = {
    {spellId = 1249907, name = "Well Fed", duration = 900, expirationTime = now + 850},
    {spellId = 1280342, name = "Rare Fishing", duration = 3600, expirationTime = now + 3400},
}
process("UNIT_AURA", "player")
assert(plan("herbalismTea").activeSpellID == 1249907 and not plan("fishingFood").active)
assert(plan("fishingCamp").activeSpellID == 1280342 and not plan("fishingCamp").bag)
assert(not plan("comprehensionScroll").tracked, "only Mages have a Comprehension category")
class, carried, AlwaysBuffedDB = "MAGE", {[215257] = 1}, {barMode = "comprehension"}
auras = {{spellId = 435563, name = "Comprehension", duration = 3600, expirationTime = now + 3550}}
event(nil, "PLAYER_LOGIN")
local scroll = plan("comprehensionScroll")
assert(A.state.barProfession == "comprehension" and not scroll.tracked and scroll.bag.item.id == 215257)
A.Prefs("comprehensionScroll").enabled = true
event(nil, "PLAYER_LOGIN")
scroll = plan("comprehensionScroll")
assert(scroll.tracked, "the Mage's explicit opt-in survives login")
assert(scroll.activeSpellID == 435563 and scroll.expires == now + 3550)
print("Shared camp, Herbalism and Mage Comprehension tracking passed.")

-- Tea is a profession category on the default bar, including when upgrading
-- a character who used to select a standalone Herbalism bar.
local teaCategory
for _, category in ipairs(A.categories) do
    if category.key == "herbalismTea" then teaCategory = category end
end
local herbRanks = {}
function C_SkillInfo.GetSkillLineInfoByID(id)
    if herbRanks[id] then return {rank = herbRanks[id]} end
end
class, gear[16], carried, auras = "ROGUE", dagger, {}, {}
AlwaysBuffedDB = {barMode = "herbalism"}
event(nil, "PLAYER_LOGIN")
assert(A.db.barMode == "auto" and not A.state.barProfession, "a saved Herbalism bar migrates to Automatic")
assert(A.OnActiveBar(teaCategory) and not plan("herbalismTea").tracked, "untrained characters can opt in to Tea")
for _, id in ipairs({182, 2944}) do
    herbRanks = {[id] = 1}
    process("SKILL_LINES_CHANGED")
    assert(not plan("herbalismTea").tracked, "learning Herbalism leaves the Tea reminder off")
end
A.Prefs("herbalismTea").enabled = false
A.Update()
assert(not plan("herbalismTea").tracked, "opting out takes precedence over profession rank")
herbRanks, carried[10841] = {}, 1
A.Prefs("herbalismTea").enabled = true
A.Update()
assert(plan("herbalismTea").tracked and plan("herbalismTea").bag.item.id == 10841)
gear[16] = pole
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(not A.state.barProfession and A.OnActiveBar(teaCategory), "Herbalism alone does not opt into the Fishing bar")
gear[16] = dagger
process("PLAYER_EQUIPMENT_CHANGED", 16)
assert(not A.state.barProfession and A.OnActiveBar(teaCategory) and plan("herbalismTea").tracked)
