-- Exercise the real Core event flow with the Forever aura APIs and a clock fixture.
local function noop() end
local now, locked, scans, directReads, paints, gripPaints = 100, false, 0, 0, 0, 0
local bags, targeted, scanned, timers = {}, {}, {}, {}
local handItems, handEnchants, enchantReads = {[16] = 101, [17] = 102}, {{}, {}}, {0, 0}
local secret = {}
local event
local frame = {RegisterEvent = noop, RegisterUnitEvent = noop, CreateFontString = function() end,
    SetScript = function(_, script, handler) if script == "OnEvent" then event = handler end end}
CreateFrame = function() return frame end
SlashCmdList = {}
NUM_BAG_SLOTS = 0
UnitClass = function() return "Rogue", "ROGUE" end
UnitLevel = function() return 32 end
InCombatLockdown = function() return locked end
GetTime = function() return now end
issecretvalue = function(value) return value == secret end
GetInventoryItemID = function(_, slot) return handItems[slot] end
C_Container = {GetContainerNumSlots = function() return 0 end}
C_Spell = {GetSpellName = function(id) return tostring(id) end, GetSpellInfo = noop}
C_SpellBook = {IsSpellKnown = noop}
C_ClassTalents = {GetActiveConfigID = noop}
C_SkillInfo = {GetSkillLineInfoByID = noop}
Enum = {WeaponSlot = {MainHand = 1, OffHand = 2}, ItemEnchantType = {Temporary = 1, Imbue = 2}}
C_Item = {IsItemDataCachedByID = function() return true end, GetItemInfo = noop,
    GetItemCount = function(id) return bags[id] or 0 end,
    GetItemInfoInstant = function() return nil, nil, nil, nil, nil, 2, 15 end,
    GetWeaponEnchantInfo = function(hand)
        enchantReads[hand] = enchantReads[hand] + 1
        return handEnchants[hand]
    end}
C_UnitAuras = {
    GetUnitAuras = function() scans = scans + 1 return scanned end,
    GetPlayerAuraBySpellID = function(spell) directReads = directReads + 1 return targeted[spell] end,
}
local function timer(delay, callback)
    local handle = {at = now + delay, callback = callback, Cancel = function(self) self.canceled = true end}
    timers[#timers + 1] = handle
    return handle
end
C_Timer = {After = timer, NewTimer = timer}

local function advance(seconds)
    local finish = now + seconds
    while true do
        local nextTimer
        for _, handle in ipairs(timers) do
            if not handle.canceled and handle.at <= finish and (not nextTimer or handle.at < nextTimer.at) then
                nextTimer = handle
            end
        end
        if not nextTimer then break end
        nextTimer.canceled = true
        now = nextTimer.at
        nextTimer.callback()
    end
    now = finish
end

local A = {}
for _, file in ipairs({"Locale", "Catalog", "Categories", "Profiles", "Planner", "Game", "Core"}) do
    assert(loadfile("AlwaysBuffed/" .. file .. ".lua"))("AlwaysBuffed", A)
end
local control = {SetPoint = noop, SetText = noop, SetSize = noop, SetScript = noop}
control.CreateFontString = function() return control end
CreateFrame = function() return control end
Settings = {RegisterCanvasLayoutCategory = noop, RegisterAddOnCategory = noop}
A.theme = {Font = noop, Refresh = noop}
A.InitActions, A.InitWheel, A.RefreshWheel, A.RefreshOptions = noop, noop, noop, noop
A.RefreshActions = function()
    assert(not locked, "aura events repaint action layout during combat")
    paints = paints + 1
end
A.RefreshGripCounts = function() gripPaints = gripPaints + 1 end
AlwaysBuffedDB = {reminders = true}
local function fire(name, unit, info) event(frame, name, unit, info) end
local function updateAuras() fire("UNIT_AURA", "player") advance(0.2) end
local function camp() return A.state.categories.campfire end
local function rest() return A.state.categories.sleepingBag end
local function aura(spell, name, icon, expiration, duration, stacks, instance)
    return {spellId = spell, name = name, icon = icon, expirationTime = expiration, duration = duration,
        applications = stacks, auraInstanceID = instance}
end
local function enchant(kind, id, time, icon)
    return {hasEnchant = true, enchantType = kind, enchantID = id, timeLeft = time, enchantIconID = icon}
end

fire("PLAYER_LOGIN")
assert(camp().tracked and not camp().bag, "shared campfire reminder needs no kit or Cooking")
assert(not rest().tracked and not rest().applicable, "inactive sleeping bag needs an owned action")

scanned = {aura(1283391, "Campfire Nearby", 1, 0, 0), aura(1229451, "Boosted Rest", 2, now + 300, 3600),
    aura(1225478, "Well Rested", 3, 0, 0), aura(1328362, "Violet Flames", 4, now + 90, 90)}
targeted[429960] = aura(429960, "Well-Rested Tracking Aura", 4, 0, 0)
updateAuras()
assert(not camp().active and not camp().pending, "proximity, Camp Tent cooldown, and violet fire visuals are separate")
assert(not rest().active and not rest().pending, "hidden sleep tracking aura and rested XP are separate")

scanned[#scanned + 1] = aura(1229739, "Warming up", 52, now + 54, 60)
updateAuras()
assert(camp().pending == "Warming up" and camp().pendingSpellID == 1229739 and camp().pendingIcon == 52)
assert(camp().pendingExpires > now and not camp().active, "Welcoming Campfire is progress only")
targeted[1289723] = aura(1289723, "Preparing camp", 53, now + 60, 60)
updateAuras()
assert(camp().pending == "Preparing camp" and camp().pendingSpellID == 1289723)

scanned, targeted = {}, {[1229741] = aura(1229741, "Campsite effect", 42, now + 3600, 3600)}
updateAuras()
assert(camp().active == "Campsite effect" and camp().activeIcon == 42 and camp().activeSpellID == 1229741)
assert(camp().expires == targeted[1229741].expirationTime and not camp().pending and not camp().violetCamp)
local violetExpiry = now + 45
targeted[1229741] = aura(1229741, "Campsite effect", 43, violetExpiry, 7200)
updateAuras()
assert(camp().activeIcon == 43 and camp().expires == violetExpiry and camp().violetCamp,
    "purple camp classification uses total duration and the actual icon")
targeted[1289723] = aura(1289723, "Preparing another camp", 53, now + 60, 60)
updateAuras()
assert(camp().active == "Campsite effect" and camp().pending == "Preparing another camp",
    "settling at another camp does not replace existing completed benefits")
targeted[1289723] = nil
targeted[1229741] = aura(1229741, "Campsite effect", secret, now + 7200, secret)
updateAuras()
assert(camp().active and camp().activeIcon == 7808144 and not camp().violetCamp,
    "a secret duration and long remaining time do not imply Violet Dust")

targeted[429959] = aura(429959, "Gut erholt", 90, now + 7200, 7200, 3)
updateAuras()
assert(rest().active == "Gut erholt ×3" and rest().activeIcon == 90 and rest().activeSpellID == 429959)
assert(rest().activeStacks == 3)
targeted[429959].applications = 2
updateAuras()
assert(rest().activeStacks == 2)
assert(rest().tracked and rest().applicable and not rest().bag, "a shared bag can grant Well-Rested without an owned item")
local previous = paints
A.Prefs("sleepingBag").enabled = false
A.Update()
assert(not rest().tracked and camp().tracked, "individual tracking opt-out stays independent")
A.Prefs("sleepingBag").enabled = true
A.db.reminders = false
A.Update()
assert(not rest().tracked and not camp().tracked and paints > previous, "master gates both reminders")
A.db.reminders = true
A.Update()

targeted[429959].expirationTime = now + 3
updateAuras()
advance(3)
assert(not rest().active and not rest().tracked, "expired aura object cannot keep a shared sleeping bag visible")
bags[211527] = 1
fire("BAG_UPDATE_DELAYED")
advance(0.2)
assert(rest().tracked and rest().bag.item.id == 211527, "owned bag remains actionable after expiry")

local expiration = now + 2
targeted[1229741] = aura(1229741, "Campsite effect", 80, expiration, 7200)
updateAuras()
locked = true
local cachedScans, cachedDirect, cachedPaints = scans, directReads, paints
advance(3)
assert(directReads == cachedDirect, "expiry does not rescan in combat")
targeted[429959] = aura(429959, "Well-Rested", 132802, now + 7200, 7200, 1)
updateAuras()
assert(rest().active == "Well-Rested" and directReads > cachedDirect, "readable reminder gains are observed in combat")
targeted[429959] = secret
updateAuras()
A.Update()
assert(rest().active == "Well-Rested", "helpful enumeration cannot prove absence of a hidden reminder aura")
scanned = {secret}
updateAuras()
assert(rest().active == "Well-Rested", "restricted values preserve the previous snapshot")
targeted[429959] = nil
updateAuras()
assert(not rest().active and not rest().activeStacks and rest().bag, "confirmed removal in combat clears the stack count and reveals the bag cooldown")
assert(scans > cachedScans and paints == cachedPaints, "readable combat effects refresh without action repaint")

local plans = A.state.categories
local elixirExpires = now + 120
scanned = {secret, aura(11328, "Agility", 72, elixirExpires, 3600, 1, 201),
    aura(19705, "19705", 73, 0, 0, 1, 202)}
handEnchants = {{enchant(1, 40, 70000, 74), enchant(2, 323, 60000, 75)}, {enchant(1, 40, 50000, 76)}}
local beforeScans, beforeGrip = scans, gripPaints
local beforeMain, beforeOff = enchantReads[1], enchantReads[2]
fire("UNIT_AURA", "player")
fire("UNIT_AURA", "player")
fire("UNIT_INVENTORY_CHANGED", "player")
assert(scans == beforeScans and enchantReads[1] == beforeMain, "combat event bursts should defer their queries")
advance(0.2)
assert(scans == beforeScans + 1 and gripPaints == beforeGrip + 1 and paints == cachedPaints,
    "one observed combat change refreshes grip counts without secure action work")
assert(enchantReads[1] == beforeMain + 1 and enchantReads[2] == beforeOff + 1, "two layers share a single query per hand")
assert(plans.elixir.active == "Agility" and plans.elixir.expires == elixirExpires and plans.elixir.activeIcon == 72,
    "an unreadable aura must not prevent subsequent ordinary buffs from being identified")
assert(plans.food.active and not plans.food.expires, "a readable timeless buff is active in combat")
assert(plans.weapon.active == "Rough Sharpening Stone" and plans.weapon.activeIcon == 74
    and plans.imbue.active == "Instant Poison" and plans.weaponOffhand.active == "Rough Sharpening Stone",
    "temporary and imbue layers on each hand update independently in combat")

scanned = {aura(11328, "Agility", 72, secret, secret, 1, 201), secret}
updateAuras()
assert(plans.elixir.expires == elixirExpires and plans.food.active,
    "partially readable snapshots preserve an existing timer or an unrelated unseen buff")
scanned = {secret}
fire("UNIT_AURA", "player", {removedAuraInstanceIDs = {secret, 201}})
advance(0.2)
assert(not plans.elixir.active and not plans.elixir.expires and plans.food.active,
    "removing the known aura instance clears only that effect, even in an incomplete scan")
scanned = {}
updateAuras()
assert(not plans.food.active, "complete scans observe early removals even without event details")

local offExpiry = plans.weaponOffhand.expires
handEnchants = {{enchant(2, 323, 55000, 75)}, secret}
beforeScans = scans
fire("PLAYER_EQUIPMENT_CHANGED", 17)
advance(0.2)
assert(scans == beforeScans and not plans.weapon.active and plans.imbue.active, "equipment changes only refresh hand state")
assert(plans.weaponOffhand.expires == offExpiry, "an unreadable off hand keeps its independent timer")
handItems[17] = nil
fire("UNIT_INVENTORY_CHANGED", "player")
advance(0.2)
assert(not plans.weaponOffhand.active and plans.imbue.active and paints == cachedPaints, "a confirmed unequip clears only that hand")
locked = false
fire("PLAYER_REGEN_ENABLED")
advance(0.2)
assert(not camp().active and not camp().activeIcon and not camp().activeSpellID and not camp().violetCamp and not camp().expires,
    "post-combat refresh clears completed aura metadata")

targeted[429959] = secret
scanned = {aura(429959, "Well-Rested", 132802, now + 2600, 7200, 2)}
updateAuras()
assert(rest().active == "Well-Rested ×2", "readable enumeration can recover from a restricted direct query")
print("Reminder auras passed: verified variants, identity and expiry, shared benefits, toggles and combat lock.")
