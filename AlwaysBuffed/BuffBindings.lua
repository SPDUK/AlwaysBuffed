local _, A = ...

local PREFIX = "ALWAYSBUFFED_USE_"
local BAR_TOGGLE = "ALWAYSBUFFED_TOGGLE_BAR"
local RETIRED = "ALWAYSBUFFED_USE_BUFFDRINKS"
local categories, proxies = {}, {}
local installedTargets = {}
local owner, updating, signature, retiredPending

local function command(key)
    return PREFIX .. key:upper()
end

local function publishLabels()
    BINDING_HEADER_ALWAYSBUFFED = "AlwaysBuffed"
    BINDING_NAME_ALWAYSBUFFED_TOGGLE_BAR = "Toggle buff bar"
    for _, category in ipairs(A.categories) do
        categories[category.key] = category
        _G["BINDING_NAME_" .. command(category.key)] = "Use " .. category.label
    end
end

local function usesWheelStep(chord)
    return chord:match("MOUSEWHEELUP$") ~= nil or chord:match("MOUSEWHEELDOWN$") ~= nil
end

local function buttonName(key, chord)
    return "AlwaysBuffedHotkey_" .. key .. (usesWheelStep(chord) and "_Wheel" or "")
end

local function isOurClick(action, name)
    return name and (action == "CLICK " .. name or action == "CLICK " .. name .. ":LeftButton")
end

local function isOurAction(action, binding, name)
    return not action or action == "" or action == binding or isOurClick(action, name)
end

function A.IsRetiredBuffBinding(action)
    return action == RETIRED
end

local function removeRetiredBinding()
    if updating then return end
    retiredPending = InCombatLockdown()
    if retiredPending then return end
    local changed
    updating = true
    for _, chord in ipairs({ GetBindingKey(RETIRED) }) do
        if GetBindingAction(chord) == RETIRED and SetBinding(chord) then changed = true end
    end
    if changed then SaveBindings(GetCurrentBindingSet()) end
    updating = false
end

local function refreshAction(button, category)
    local states = A.state and A.state.categories
    local plan = states and states[category.key]
    local row = plan and plan.tracked and plan.applicable ~= false and plan.bag
    A.SetAction(button, category, row or nil)
end

local function ensureProxy(category, chord)
    local name = buttonName(category.key, chord)
    if proxies[name] then return name end

    local onDown = usesWheelStep(chord)
    local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    button:SetSize(1, 1)
    button:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -20, 20)
    button:SetAlpha(0)
    button:EnableMouse(false)
    button:SetAttribute("useOnKeyDown", onDown)
    button:RegisterForClicks(onDown and "AnyDown" or "AnyUp")
    button:Show()
    proxies[name] = { button = button, category = category }
    refreshAction(button, category)
    return name
end

local function updateOverrides()
    if not owner or updating or InCombatLockdown() then return end

    local desired, keys = {}, {}
    local function collect(binding, category)
        for _, chord in ipairs({ GetBindingKey(binding) }) do
            local target = category and buttonName(category.key, chord) or A.barShortcutName
            local effective = GetBindingAction(chord, true)
            if isOurAction(effective, binding, target) or isOurClick(effective, installedTargets[chord]) then
                desired[#desired + 1] = { category = category, chord = chord, target = target }
                keys[#keys + 1] = binding .. "=" .. chord
            end
        end
    end
    collect(BAR_TOGGLE)
    for _, category in ipairs(A.categories) do collect(command(category.key), category) end
    local nextSignature = table.concat(keys, "\n")
    if signature == nextSignature then return end

    signature, updating = nextSignature, true
    ClearOverrideBindings(owner)
    installedTargets = {}
    for _, entry in ipairs(desired) do
        if entry.category then ensureProxy(entry.category, entry.chord) end
        SetOverrideBindingClick(owner, false, entry.chord, entry.target)
        installedTargets[entry.chord] = entry.target
    end
    updating = false
end

function A.GetBuffBinding(key)
    if categories[key] then return (GetBindingKey(command(key))) end
end

function A.GetBarToggleBinding()
    return (GetBindingKey(BAR_TOGGLE))
end

local function setNativeBinding(binding, chord, proxy)
    if InCombatLockdown() then return false, "Change buff shortcuts after combat." end
    if chord == "" then chord = nil end

    local oldKeys = { GetBindingKey(binding) }
    if chord then
        local action = GetBindingAction(chord)
        local retired = A.IsRetiredBuffBinding(action)
        if retired or isOurAction(action, binding, proxy) then action = GetBindingAction(chord, true) end
        if not (retired and A.IsRetiredBuffBinding(action)) and not isOurAction(action, binding, proxy) then
            local label = _G["BINDING_NAME_" .. action] or action
            return false, ("%s is already bound to %s."):format(chord, label)
        end
    end

    updating = true
    if chord and not SetBinding(chord, binding) then
        updating = false
        return false, "That key cannot be bound."
    end
    for _, oldKey in ipairs(oldKeys) do
        if oldKey ~= chord then SetBinding(oldKey) end
    end
    SaveBindings(GetCurrentBindingSet())
    updating = false
    updateOverrides()
    return true
end

function A.SetBuffBinding(key, chord)
    if not categories[key] then return false, "Choose a buff category." end
    local proxy = chord and chord ~= "" and buttonName(key, chord)
    return setNativeBinding(command(key), chord, proxy)
end

function A.SetBarToggleBinding(chord)
    return setNativeBinding(BAR_TOGGLE, chord, A.barShortcutName)
end

function A.RefreshBuffBindings()
    if not owner or InCombatLockdown() then return end
    for _, entry in pairs(proxies) do refreshAction(entry.button, entry.category) end
end

function A.InitBuffBindings()
    if owner or InCombatLockdown() then return end
    publishLabels()
    owner = CreateFrame("Frame")
    owner:RegisterEvent("UPDATE_BINDINGS")
    owner:RegisterEvent("BINDINGS_LOADED")
    owner:RegisterEvent("PLAYER_REGEN_ENABLED")
    owner:SetScript("OnEvent", function(_, event)
        if event == "BINDINGS_LOADED" or (event == "PLAYER_REGEN_ENABLED" and retiredPending) then
            removeRetiredBinding()
        end
        updateOverrides()
        if event == "PLAYER_REGEN_ENABLED" then A.RefreshBuffBindings() end
    end)
    removeRetiredBinding()
    updateOverrides()
end

publishLabels()
