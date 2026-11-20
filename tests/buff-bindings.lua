-- Native bindings are modeled here; the real secure action attributes come from Actions.lua.
local A = { theme = { colors = {} } }
for _, name in ipairs({"Locale", "Catalog", "Categories", "Status", "Actions", "BuffBindings"}) do
    assert(loadfile("AlwaysBuffed/" .. name .. ".lua"))("AlwaysBuffed", A)
end
A.ApplyClassLabels("ROGUE")
A.db = { showBar = false, collapsed = true }
A.state = { categories = {} }
local states = A.state.categories

local function carry(key, id, spell)
    states[key] = {tracked = true, applicable = true, bag = {item = {id = id, spell = spell}, count = 2}}
end
carry("food", 787)
carry("imbueOffhand", 6947)
carry("sleepingBag", 211527)

local function command(key) return "ALWAYSBUFFED_USE_" .. key:upper() end
local BAR = "ALWAYSBUFFED_TOGGLE_BAR"
local RETIRED = command("buffDrinks")
local RETIRED_HERBS = command("herbalismDraught")
local RETIRED_MINING = command("miningDraught")
local file = assert(io.open("AlwaysBuffed/Bindings.xml"))
local xml = file:read("*a")
file:close()
for _, category in ipairs(A.categories) do
    assert(xml:find('name="' .. command(category.key) .. '"', 1, true), category.key .. " lacks a native command")
end
assert(xml:find('name="ALWAYSBUFFED_TOGGLE_WHEEL"', 1, true))
assert(xml:match('<Binding name="' .. BAR .. '"[^>]*/>'), "native bar shortcut is registered for secure CLICK routing")
local _, total = xml:gsub('<Binding name=', '')
assert(total == #A.categories + 2, "class and profession categories, wheel and bar bindings are registered")
for _, binding in ipairs({RETIRED, RETIRED_HERBS, RETIRED_MINING}) do
    assert(not xml:find(binding, 1, true), binding .. " is absent from native settings")
end
local activeSet, savedSet = 2
local sets = {
    [1] = { H = "JUMP", K = RETIRED, N = RETIRED_MINING },
    [2] = {
        J = "JUMP", ["CTRL-R"] = "ALWAYSBUFFED_TOGGLE_WHEEL",
        F = command("food"), O = command("imbueOffhand"),
        ["SHIFT-O"] = command("imbueOffhand"),
        K = RETIRED, ["SHIFT-K"] = RETIRED, U = RETIRED_HERBS, ["SHIFT-U"] = RETIRED_HERBS, N = RETIRED_MINING,
    },
}
local frames, overrides, external = {}, {}, {}
local inCombat, failKey, hideRetired
local writes, saveWrites = 0, 0
local Frame = {}
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:RegisterEvent(name) self.events[name] = true end
function Frame:SetSize() end
function Frame:SetPoint() end
function Frame:SetAlpha(alpha) self.alpha = alpha end
function Frame:EnableMouse(value) self.mouse = value end
function Frame:SetAttribute(key, value)
    assert(not inCombat, "secure attribute change during combat")
    writes = writes + 1
    self.attrs[key] = value
end
function Frame:RegisterForClicks(edge) self.edge = edge end
function Frame:Show() self.shown = true end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({
        kind = kind, name = name, parent = parent, template = template,
        scripts = {}, events = {}, attrs = {},
    }, { __index = Frame })
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end

local function fire(event)
    for _, frame in ipairs(frames) do
        if frame.events[event] then frame.scripts.OnEvent(frame, event) end
    end
end
UIParent = CreateFrame("Frame")
function InCombatLockdown() return inCombat end
function GetCurrentBindingSet() return activeSet end
function GetBindingKey(binding)
    if hideRetired == binding then return end
    local keys = {}
    for chord, action in pairs(sets[activeSet]) do
        if action == binding then keys[#keys + 1] = chord end
    end
    table.sort(keys)
    return unpack(keys)
end
function GetBindingAction(chord, override)
    return override and (external[chord] or overrides[chord] and overrides[chord].action)
        or sets[activeSet][chord] or ""
end
function SetBinding(chord, action)
    assert(not inCombat, "binding changed during combat")
    if chord == failKey then return false end
    sets[activeSet][chord] = action
    fire("UPDATE_BINDINGS")
    return true
end
function SaveBindings(bindingSet)
    assert(bindingSet == activeSet, "only the active set is saved")
    savedSet, saveWrites = bindingSet, saveWrites + 1
end
function SetOverrideBindingClick(owner, _, chord, button, mouseButton)
    assert(not inCombat, "override changed during combat")
    overrides[chord] = {owner = owner, action = "CLICK " .. button .. ":" .. (mouseButton or "LeftButton")}
    fire("UPDATE_BINDINGS")
end
function ClearOverrideBindings(owner)
    assert(not inCombat, "override cleared during combat")
    for key, entry in pairs(overrides) do
        if entry.owner == owner then overrides[key] = nil end
    end
    fire("UPDATE_BINDINGS")
end

local function press(chord, down)
    local name = GetBindingAction(chord, true):match("^CLICK ([^:]+)")
    local button = name and _G[name]
    if button and button.shown and button.edge == (down and "AnyDown" or "AnyUp") then
        return button.attrs["*item1"] or button.attrs["*spell1"], button.attrs["*target-slot1"], button.attrs["*unit1"]
    end
end

external["SHIFT-U"] = "CLICK DifferentAddOn:LeftButton"
A.InitBuffBindings()
assert(saveWrites == 1 and savedSet == 2 and not sets[2].K and not sets[2]["SHIFT-K"])
assert(not sets[2].N and not sets[2].U and not sets[2]["SHIFT-U"], "retired hidden-node shortcuts are cleared")
assert(GetBindingAction("SHIFT-U", true) == external["SHIFT-U"] and sets[1].K == RETIRED and sets[1].N == RETIRED_MINING)
for _, key in ipairs({"buffDrinks", "herbalismDraught", "miningDraught"}) do
    assert(not A.GetBuffBinding(key) and not A.SetBuffBinding(key, "K"))
    assert(not _G["BINDING_NAME_" .. command(key)] and not _G["AlwaysBuffedHotkey_" .. key])
end
fire("BINDINGS_LOADED")
assert(saveWrites == 1, "loading an already clean set does not save")
inCombat, activeSet = true, 1
fire("BINDINGS_LOADED")
assert(sets[1].K == RETIRED and sets[1].N == RETIRED_MINING and saveWrites == 1,
    "loaded bindings are left alone during combat")
inCombat = false
fire("PLAYER_REGEN_ENABLED")
assert(not sets[1].K and not sets[1].N and sets[1].H == "JUMP" and saveWrites == 2 and savedSet == 1)
activeSet = 2
fire("BINDINGS_LOADED")
assert(saveWrites == 2)
hideRetired, sets[2].N = RETIRED_MINING, RETIRED_MINING
external.N = "CLICK DifferentAddOn:LeftButton"
assert(not A.SetBarToggleBinding("N") and sets[2].N == RETIRED_MINING, "a foreign override still blocks reuse")
external.N = nil
assert(A.SetBarToggleBinding("N") and sets[2].N == BAR, "retired key remains reusable if reverse lookup misses it")
assert(A.SetBarToggleBinding(nil) and not sets[2].N)
assert(BINDING_NAME_ALWAYSBUFFED_TOGGLE_BAR == "Toggle buff bar")
assert(A.GetBarToggleBinding() == nil, "bar toggle is unbound by default")
assert(BINDING_NAME_ALWAYSBUFFED_USE_IMBUEOFFHAND == "Use Off-Hand Poison")
assert(BINDING_NAME_ALWAYSBUFFED_USE_WEAPON == "Use Main-Hand Stones & Oils")
assert(BINDING_NAME_ALWAYSBUFFED_USE_FISHINGLURE == "Use Fishing Lure")
assert(A.GetBuffBinding("food") == "F")
assert(press("F", true) == nil and press("F", false) == "item:787")
local sharpened, slot = press("SHIFT-O", false)
assert(sharpened == "item:6947" and slot == 17)
assert(press("O", false) == "item:6947", "the native secondary key stays valid")
assert(AlwaysBuffedHotkey_food.parent == UIParent and not AlwaysBuffedHotkey_food.mouse)
assert(AlwaysBuffedHotkey_food.alpha == 0 and AlwaysBuffedHotkey_food.template == "SecureActionButtonTemplate")

local barClick = "CLICK AlwaysBuffedBarShortcut:LeftButton"
assert(not A.SetBarToggleBinding("J") and not A.SetBarToggleBinding("O") and not A.SetBarToggleBinding("CTRL-R"))
external.F7 = "CLICK DifferentAddOn:LeftButton"
assert(not A.SetBarToggleBinding("F7"))
external.F7 = nil
assert(A.SetBarToggleBinding("SHIFT-F7") and A.GetBarToggleBinding() == "SHIFT-F7")
assert(savedSet == 2 and GetBindingAction("SHIFT-F7") == BAR and GetBindingAction("SHIFT-F7", true) == barClick)
assert(A.SetBarToggleBinding("SHIFT-F7"), "rebinding the same chord accepts its own override")
assert(not A.SetBuffBinding("food", "SHIFT-F7") and press("F", false) == "item:787")
SetBinding("F6", BAR)
assert(A.GetBarToggleBinding() == "F6", "native changes update the primary chord")
assert(GetBindingAction("F6", true) == barClick and GetBindingAction("SHIFT-F7", true) == barClick)
external.F6 = "CLICK DifferentAddOn:LeftButton"
fire("UPDATE_BINDINGS")
assert(GetBindingAction("F6", true) == external.F6 and not overrides.F6)
external.F6 = nil
fire("UPDATE_BINDINGS")
assert(GetBindingAction("F6", true) == barClick)
failKey = "F8"
assert(not A.SetBarToggleBinding("F8") and A.GetBarToggleBinding() == "F6")
failKey = nil
assert(A.SetBarToggleBinding(nil) and A.GetBarToggleBinding() == nil)
assert(GetBindingAction("SHIFT-F7", true) == "" and GetBindingAction("F6", true) == "")
assert(A.SetBarToggleBinding("SHIFT-F7"))
SetBinding("SHIFT-F7", command("food"))
assert(not A.GetBarToggleBinding() and press("SHIFT-F7", false) == "item:787",
    "a native reassignment displaces the stale bar override immediately")
SetBinding("SHIFT-F7", BAR)
assert(A.GetBarToggleBinding() == "SHIFT-F7" and GetBindingAction("SHIFT-F7", true) == barClick,
    "a native reassignment from buff use reaches the bar immediately")

assert(not A.SetBuffBinding("food", "J") and not A.SetBuffBinding("food", "CTRL-R"))
assert(not A.SetBuffBinding("food", "O") and press("O", false) == "item:6947")
external.H = "CLICK DifferentAddOn:LeftButton"
assert(not A.SetBuffBinding("food", "H"))
external.H = nil
failKey = "F8"
assert(not A.SetBuffBinding("food", "F8") and press("F", false) == "item:787")
failKey = nil
assert(A.SetBuffBinding("food", "H") and savedSet == 2 and sets[1].H == "JUMP")
assert(press("F", false) == nil and press("H", false) == "item:787")
assert(sets[2]["CTRL-R"] == "ALWAYSBUFFED_TOGGLE_WHEEL" and sets[2].J == "JUMP")

external.H = "CLICK DifferentAddOn:LeftButton"
fire("UPDATE_BINDINGS")
assert(overrides.H == nil and GetBindingAction("H", true) == external.H)
external.H = nil
fire("UPDATE_BINDINGS")
assert(press("H", false) == "item:787")

-- Secure assignments are stable in combat. After regen, the new plan controls them.
local before = writes
inCombat = true
carry("food", 4592)
assert(not A.SetBuffBinding("food", "F9"))
assert(not A.SetBarToggleBinding(nil) and A.GetBarToggleBinding() == "SHIFT-F7")
A.RefreshBuffBindings()
fire("UPDATE_BINDINGS")
assert(writes == before and press("H", false) == "item:787")
assert(GetBindingAction("SHIFT-F7", true) == barClick)
inCombat = false
fire("PLAYER_REGEN_ENABLED")
assert(press("H", false) == "item:4592")

states.imbueOffhand.applicable = false
A.RefreshBuffBindings()
assert(press("O", false) == nil)
carry("imbueOffhand", 3775)
A.RefreshBuffBindings()
local crippling, changedSlot = press("O", false)
assert(crippling == "item:3775" and changedSlot == 17)
states.imbueOffhand.tracked = false
A.RefreshBuffBindings()
assert(press("O", false) == nil and press("SHIFT-O", false) == nil)

assert(A.SetBuffBinding("sleepingBag", "ALT-MOUSEWHEELUP"))
assert(press("ALT-MOUSEWHEELUP", true) == "item:211527")
assert(press("ALT-MOUSEWHEELUP", false) == nil)
carry("fishingLure", 6532)
assert(A.SetBuffBinding("fishingLure", "F10"))
assert(not press("F10", false), "profession shortcut is disarmed on the combat loadout")
A.state.barProfession = "fishing"
A.RefreshBuffBindings()
local lure, lureSlot = press("F10", false)
assert(lure == "item:6532" and lureSlot == 16)
carry("fishingCoin", 286732)
assert(A.SetBuffBinding("fishingCoin", "F11"))
local coin, coinSlot, coinUnit = press("F11", false)
assert(coin == "item:286732" and not coinSlot and not coinUnit, "the aimed fishing coin has no preset target")
assert(press("H", false) == "item:4592", "the ordinary food shortcut still works on a profession loadout")
states.fishingLure.applicable = false
A.RefreshBuffBindings()
assert(not press("F10", false), "the lure is disarmed when the plan loses a compatible pole")
carry("fishingLure", 6532)
A.RefreshBuffBindings()
assert(press("F10", false) == "item:6532")
A.state.barProfession = nil
A.RefreshBuffBindings()
assert(A.GetBuffBinding("fishingLure") == "F10" and not press("F10", false), "switching clears the action and keeps the native chord")
assert(A.SetBuffBinding("food", nil) and not A.GetBuffBinding("food") and press("H", false) == nil)
print("Direct buff bindings, native bar toggle, conflict checks, cached actions, and hand targets passed.")
