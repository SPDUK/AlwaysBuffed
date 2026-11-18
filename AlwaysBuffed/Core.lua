local addon, A = ...
local events = CreateFrame("Frame")
local G = A.game
local ready, queued, needPlan, auctionSubscribed, talentPoints
local announcedLevel
local reminderTimer, reminderDeadline
local combatAuras, combatWeapons, removedAuras = false, false, {}
local defaults = {profile = "auto", showBar = true, showWheel = true, showMinimap = true,
    locked = false, reminders = false, collapsed = false, highlightMissing = false,
    barOrientation = "horizontal", mouseoverOnly = false, barScale = 1, wheelScale = 1, fontScale = 1}

local function paint()
    if ready then
        A.RefreshActions()
        A.InitWheel()
        A.RefreshWheel()
        A.RefreshOptions()
    end
end

local function refreshEffect(category, plan, ids, names, complete, weapons, removed)
    local changed = false
    local name, expires, icon, spellID, duration, absent, stacks, timed, instance =
        G.ActiveEffect(category, plan.rows, ids, names, complete, weapons)
    if name and not timed and plan.activeSpellID == spellID
        and (not instance or not plan.activeInstanceID or plan.activeInstanceID == instance) then
        expires = plan.expires
    end
    local violet = category.key == "campfire" and duration == 7200 or nil
    local expiresChanged = plan.expires ~= expires
    if category.kind == "weapon" and plan.expires and expires and plan.activeInstanceID == instance then
        expiresChanged = math.abs(plan.expires - expires) >= 1
    end
    local wasRemoved = category.kind ~= "weapon" and plan.activeInstanceID and removed and removed[plan.activeInstanceID]
    if (name or absent or wasRemoved) and (plan.active ~= name or expiresChanged
        or plan.activeIcon ~= icon or plan.activeSpellID ~= spellID or plan.violetCamp ~= violet
        or plan.activeStacks ~= stacks or plan.activeInstanceID ~= instance) then
        plan.active, plan.expires, plan.activeIcon, plan.activeSpellID, plan.violetCamp = name, expires, icon, spellID, violet
        plan.activeStacks, plan.activeInstanceID = stacks, instance
        changed = true
    end
    if category.kind == "reminder" then
        local pending, endTime, pendingIcon, pendingSpellID, _, pendingAbsent, _, pendingTimed, pendingInstance =
            G.PendingEffect(category, ids, complete)
        if pending and not pendingTimed and plan.pendingSpellID == pendingSpellID
            and (not pendingInstance or not plan.pendingInstanceID or plan.pendingInstanceID == pendingInstance) then
            endTime = plan.pendingExpires
        end
        local pendingRemoved = plan.pendingInstanceID and removed and removed[plan.pendingInstanceID]
        if (pending or pendingAbsent or pendingRemoved) and (plan.pending ~= pending or plan.pendingExpires ~= endTime
            or plan.pendingIcon ~= pendingIcon or plan.pendingSpellID ~= pendingSpellID or plan.pendingInstanceID ~= pendingInstance) then
            plan.pending, plan.pendingExpires = pending, endTime
            plan.pendingIcon, plan.pendingSpellID, plan.pendingInstanceID = pendingIcon, pendingSpellID, pendingInstance
            changed = true
        end
        local wasTracked = plan.tracked
        A.UpdateReminderVisibility(category, plan)
        changed = changed or plan.tracked ~= wasTracked
    end
    return changed
end

local function effects(readAuras, readWeapons, removed)
    local locked = InCombatLockdown()
    local changed, nextExpiry, now = false, math.huge
    local ids, names, complete
    if readAuras then ids, names, complete = G.AuraIndex() end
    local weapons = {}
    for _, category in ipairs(A.categories) do
        local plan = A.state.categories[category.key]
        local relevant = not locked or (plan.tracked and plan.applicable) or plan.reminderEnabled
        local readEffect = category.kind == "weapon" and readWeapons or category.kind ~= "weapon" and readAuras
        if relevant and readEffect and refreshEffect(category, plan, ids, names, complete, weapons, removed) then
            changed = true
        end
        if plan.reminderEnabled and (plan.expires or plan.pendingExpires) then
            now = now or GetTime()
            if plan.expires and plan.expires > now then nextExpiry = math.min(nextExpiry, plan.expires) end
            if plan.pendingExpires and plan.pendingExpires > now then nextExpiry = math.min(nextExpiry, plan.pendingExpires) end
        end
    end
    if locked then return changed end
    local deadline = nextExpiry < math.huge and nextExpiry or nil
    if deadline ~= reminderDeadline then
        if reminderTimer then reminderTimer:Cancel() end
        reminderTimer, reminderDeadline = nil, deadline
        if deadline then
            reminderTimer = C_Timer.NewTimer(math.max(0, deadline - GetTime()), function()
                reminderTimer, reminderDeadline = nil, nil
                if ready and not InCombatLockdown() and effects(true, false) then paint() end
            end)
        end
    end
    return changed
end

local effectFields = {"active", "expires", "activeIcon", "activeSpellID", "activeStacks", "activeInstanceID",
    "violetCamp", "pending", "pendingExpires", "pendingIcon", "pendingSpellID", "pendingInstanceID"}

function A.Update()
    local state = A.state
    local level = UnitLevel("player")
    if announcedLevel and level >= announcedLevel then announcedLevel = nil end
    state.level = announcedLevel or level
    local choices = A.profiles[state.class] or {A.defaultProfile}
    if not talentPoints then talentPoints = G.TalentPoints() end
    state.profile = A.SelectProfile(choices, A.db.profile, talentPoints)
    if ready and InCombatLockdown() then
        needPlan = true
        A.RefreshOptions()
        return
    end
    local ctx = G.Context(state.class, state.level, A.db.reminders)
    for _, category in ipairs(A.categories) do
        local catalog = A.catalog[category.key]
        if category.kind == "food" then catalog = G.FoodWithBagFallback(catalog) end
        local previous = state.categories[category.key]
        local plan = A.PlanCategory(category, catalog, ctx, A.Prefs(category.key), state.profile)
        if previous then
            for _, field in ipairs(effectFields) do plan[field] = previous[field] end
        end
        state.categories[category.key] = plan
    end
    effects(true, true)
    paint()
end

local function flush()
    queued = false
    if not ready then return end
    local auras, weapons, removed = combatAuras, combatWeapons, removedAuras
    combatAuras, combatWeapons, removedAuras = false, false, {}
    if InCombatLockdown() then
        if (auras or weapons) and effects(auras, weapons, removed) then A.RefreshGripCounts() end
        return
    end
    if needPlan then
        needPlan = false
        A.Update()
    elseif effects(true, true, removed) then
        paint()
    end
end

local function queue(full, auras, weapons)
    needPlan = full or needPlan
    combatAuras, combatWeapons = combatAuras or auras, combatWeapons or weapons
    if queued or not ready or (InCombatLockdown() and not (combatAuras or combatWeapons)) then return end
    queued = true
    C_Timer.After(0.12, flush)
end

local function subscribePrices()
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not auctionSubscribed and api and api.RegisterForDBUpdate then
        api.RegisterForDBUpdate(addon, function() queue(true) end)
        auctionSubscribed = true
    end
end

local function registerSettings()
    local panel = CreateFrame("Frame")
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -20)
    title:SetText(addon)
    A.theme.Font(title, 21, true)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(180, 28)
    button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    button:SetText("Open AlwaysBuffed")
    button:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        A.ToggleOptions()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(panel, addon)
    Settings.RegisterAddOnCategory(category)
end

local function migratePreferences(preferences)
    for _, oldProfile in pairs(preferences) do
        local profileValid = type(oldProfile) == "table"
        if profileValid then oldProfile.buffDrinks = nil end
        local old = profileValid and oldProfile.elixir
        if type(old) == "table" and (old.pin == 12820 or old.pin == 246948) then
            local ap = oldProfile.elixirAttackPower
            if type(ap) ~= "table" then
                ap = {}
                oldProfile.elixirAttackPower = ap
            end
            if ap.pin == nil then
                ap.pin = old.pin
                if ap.enabled == nil then ap.enabled = old.enabled ~= false end
                if ap.cheapest == nil then ap.cheapest = old.cheapest end
            end
            old.pin = nil
        end
    end
end

local function login()
    if type(AlwaysBuffedDB) ~= "table" then AlwaysBuffedDB = {} end
    A.db = AlwaysBuffedDB
    for key, value in pairs(defaults) do
        if type(A.db[key]) ~= type(value) then A.db[key] = value end
    end
    if A.db.barOrientation ~= "vertical" then A.db.barOrientation = "horizontal" end
    for key, bounds in pairs({barScale={0.75, 1.50}, wheelScale={0.75, 1.50}, fontScale={0.85, 1.25}}) do
        A.db[key] = math.max(bounds[1], math.min(bounds[2], A.db[key]))
    end
    if type(A.db.preferences) ~= "table" then A.db.preferences = {} end
    migratePreferences(A.db.preferences)
    local _, class = UnitClass("player")
    A.state = {class = class, categories = {}}
    A.ApplyClassLabels(class)
    A.theme.Refresh()
    A.Update()
    A.InitActions()
    A.InitWheel()
    ready = true
    registerSettings()
    subscribePrices()
    paint()
end

local function slash(message)
    if not ready then return end
    local command = strtrim(message or ""):lower()
    if command == "wheel" then
        A.ToggleWheel()
    elseif command == "unlock" or command == "lock" then
        A.db.locked = command == "lock"
        A.RefreshActions()
        A.RefreshOptions()
    else
        A.ToggleOptions()
    end
end

SLASH_ALWAYSBUFFED1 = "/alwaysbuffed"
SLASH_ALWAYSBUFFED2 = "/ab"
SlashCmdList.ALWAYSBUFFED = slash

events:SetScript("OnEvent", function(_, event, arg, success)
    if event == "PLAYER_LOGIN" then
        login()
    elseif event == "ADDON_LOADED" then
        if arg == "Auctionator" and ready then subscribePrices() queue(true) end
    elseif ready then
        if event == "UNIT_AURA" then
            if arg == "player" then
                G.RemovedAuras(success, removedAuras)
                queue(false, true, true)
            end
        elseif event == "PLAYER_LEVEL_UP" then
            -- The level-up event can precede the new value of UnitLevel.
            announcedLevel = tonumber(arg)
            queue(true)
        elseif event == "UNIT_INVENTORY_CHANGED" then
            if arg == "player" then queue(true, false, true) end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            queue(true, false, arg == 16 or arg == 17)
        elseif event == "ITEM_DATA_LOAD_RESULT" then
            if G.ItemArrived(arg) and success then queue(true) end
        else
            if event == "TRAIT_CONFIG_UPDATED" or event == "ACTIVE_COMBAT_CONFIG_CHANGED"
                or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TALENT_UPDATE" then
                talentPoints = nil
            end
            queue(true)
        end
    end
end)
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "SKILL_LINES_CHANGED",
    "TRAIT_CONFIG_UPDATED", "ACTIVE_COMBAT_CONFIG_CHANGED", "PLAYER_TALENT_UPDATE", "ITEM_DATA_LOAD_RESULT",
    "AUCTION_HOUSE_CLOSED", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED"}) do
    events:RegisterEvent(event)
end
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
