local _, A = ...
local L = A.L

local BINDING = "ALWAYSBUFFED_TOGGLE_WHEEL"
local TWO_PI = 2 * math.pi
local DIAMETER, INNER, OUTER = 352, 64, 176
local TILE_SIZE = 40
local OPEN_TIME, CLOSE_TIME = 0.25, 0.12
local ATLAS_PATH = "Interface\\AddOns\\AlwaysBuffed\\Media\\Wheel"
local ATLAS_SIZE, CELL_SIZE, MASK_RADIUS = 2048, 320, 112
local COLUMNS, DISC = 6, 35
local COLORS = A.theme.colors
local wheel, ringArt, preview, bindingOwner, escapeOwner, escapeButton
local reveal, screenFit = 0, 1
local art, buttons, inputs, inputPool = {}, {}, {}, {}
local entries, selected, mode, held, originX, originY, bindingSignature, statusAt
local bindingsUpdating, bindingsWaiting

BINDING_HEADER_ALWAYSBUFFED = "AlwaysBuffed"
BINDING_NAME_ALWAYSBUFFED_TOGGLE_WHEEL = L["Hold buff wheel"]

local function cursorPosition(frame)
    local scale = frame:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function sector(x, y, count)
    local step = TWO_PI / count
    local angle = (math.atan2(x, y) + step / 2) % TWO_PI
    local edge = angle % step
    return math.floor(angle / step) + 1, math.min(edge, step - edge)
end

local function getSelection()
    -- Clicks follow the visible slices. Held gestures keep a fixed dead zone.
    local frame = mode == "preview" and ringArt or wheel
    local x, y = cursorPosition(frame)
    local cx, cy = frame:GetCenter()
    if not cx then return end

    local dx, dy = x - cx, y - cy
    local radius = math.sqrt(dx * dx + dy * dy)
    if mode == "hold" then
        -- The client leaves the system cursor in place. A gesture can start anywhere,
        -- and reaching the visible hub resets its origin to the middle of the wheel.
        if radius <= INNER then
            originX, originY = nil, nil
            return
        end
        if originX then
            dx, dy = x - originX, y - originY
            radius = math.sqrt(dx * dx + dy * dy)
        end
    elseif radius > OUTER then
        return
    end
    if radius <= INNER then return end

    local index, distanceToEdge = sector(dx, dy, #entries)
    if mode == "preview" and #entries > 1 and radius * math.sin(distanceToEdge) < 2.25 then return end
    return index, dx / radius, dy / radius, radius
end

local function colorFont(font, color)
    font:SetTextColor(unpack(color))
end

local function atlasTexture(layer, extension, sublevel)
    local texture = ringArt:CreateTexture(nil, layer, nil, sublevel)
    texture:SetTexture(ATLAS_PATH .. extension .. ".png")
    return texture
end

local function setMask(texture, cell, angle, size, x, y)
    local originU = ((cell % COLUMNS + 0.5) * CELL_SIZE) / ATLAS_SIZE
    local originV = ((math.floor(cell / COLUMNS) + 0.5) * CELL_SIZE) / ATLAS_SIZE
    local c = math.cos(angle) * MASK_RADIUS / ATLAS_SIZE
    local s = math.sin(angle) * MASK_RADIUS / ATLAS_SIZE
    texture:SetTexCoord(originU - c - s, originV + s - c, originU - c + s, originV + s + c,
        originU + c - s, originV - s - c, originU + c + s, originV - s + c)
    texture:SetSize(size, size)
    texture:SetPoint("CENTER", ringArt, "CENTER", x, y)
end

local function tint(texture, color, alpha)
    texture:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function makeFont(size, strong, flags, maxSize)
    local font = ringArt:CreateFontString(nil, "OVERLAY")
    A.theme.Font(font, size, strong, flags, maxSize)
    font:SetJustifyH("CENTER")
    return font
end

local function createSlice(index)
    local slice = {}
    slice.surface = atlasTexture("BACKGROUND", "Fill", 1)
    slice.outline = atlasTexture("BORDER", "Stroke", 1)
    slice.border = ringArt:CreateTexture(nil, "ARTWORK", nil, 1)
    slice.icon = ringArt:CreateTexture(nil, "ARTWORK", nil, 2)
    slice.icon:SetPoint("CENTER", slice.border)
    slice.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    slice.time = makeFont(15, true, "OUTLINE", 15)
    slice.time:SetTextColor(1, 1, 1)
    slice.hand = makeFont(10, true, "OUTLINE", 10)
    slice.hand:SetTextColor(1, 1, 1)
    buttons[index] = slice
    return slice
end

local function showSlice(slice, show)
    slice.surface:SetShown(show)
    slice.outline:SetShown(show)
    slice.border:SetShown(show)
    slice.icon:SetShown(show)
    slice.time:SetShown(show)
    slice.hand:SetShown(show)
end

local function paintSlice(slice, entry, isSelected)
    tint(slice.surface, isSelected and COLORS.selected or COLORS.raised, isSelected and 1 or 0.94)
    tint(slice.outline, isSelected and COLORS.mint or COLORS.line)
    local edge = entry.active and A.activeBorderColor or (isSelected and COLORS.mint or COLORS.edge)
    slice.border:SetColorTexture(unpack(edge))
    local unbuffedCamp = entry.category.key == "campfire" and not entry.active
    slice.icon:SetTexture(unbuffedCamp and entry.category.icon or entry.statusIcon or entry.icon)
    local visible = not unbuffedCamp and entry.statusMode ~= "cooldown" and (entry.row or entry.active)
    slice.icon:SetDesaturated(not visible)
    slice.icon:SetAlpha(visible and 1 or (unbuffedCamp and entry.row and 0.8 or 0.48))
    slice.time:SetText(entry.time)
    if entry.time then
        slice.time:SetTextScale(1)
        local size = slice.border:GetWidth()
        local width = math.max(1, slice.time:GetStringWidth())
        slice.time:SetTextScale(math.min(size / TILE_SIZE, (size - 6) / width))
    end
end

local function paintCenter(entry)
    if entry then
        art.title:SetText(entry.statusName or entry.name)
        colorFont(art.title, COLORS.text)
        art.detail:SetText(entry.statusDetail or entry.detail)
        local highlighted = entry.active or entry.statusMode == "pending" or entry.statusMode == "cooldown"
        colorFont(art.detail, highlighted and COLORS.gold or COLORS.muted)
    else
        art.title:SetText(L["Buff wheel"])
        colorFont(art.title, COLORS.text)
        art.detail:SetText(mode == "hold" and L["Move to choose"] or L["Click a slice"])
        colorFont(art.detail, COLORS.muted)
    end
end

local function readStatus(entry, now)
    local state = A.state.categories[entry.category.key] or {}
    local active, icon, statusMode, time = entry.active, entry.statusIcon, entry.statusMode, entry.time
    entry.active = A.EffectIsCurrent(state.active, state.expires, now)
    entry.time = entry.active and state.expires and state.expires > now and A.BuffDuration(state.expires - now, true) or nil
    if entry.reminder then
        entry.statusName, entry.statusDetail, entry.statusMode, entry.statusIcon =
            A.ReminderStatus(entry.category, state, now)
    elseif entry.active then
        entry.statusDetail = entry.time and L["Active  ·  %s left"]:format(entry.time) or L["Active"]
    else
        entry.statusDetail = nil
    end
    return active ~= entry.active or icon ~= entry.statusIcon or statusMode ~= entry.statusMode or time ~= entry.time
end

local function refreshStatuses(now)
    for index, entry in ipairs(entries) do
        if readStatus(entry, now) then
            paintSlice(buttons[index], entry, index == selected)
        end
    end
    if selected then paintCenter(entries[selected]) end
    statusAt = now + 1
end

local function updateSelection()
    local now = GetTime()
    if now >= statusAt then refreshStatuses(now) end
    local index, x, y, radius = getSelection()
    if index ~= selected then
        if selected then paintSlice(buttons[selected], entries[selected], false) end
        if index then paintSlice(buttons[index], entries[index], true) end
        selected = index
        paintCenter(entries[index])
    end

    if mode == "hold" and index then
        radius = math.min(radius, OUTER - 10)
        art.pointer:SetPoint("CENTER", ringArt, "CENTER", x * radius, y * radius)
        art.pointer:Show()
    else
        art.pointer:Hide()
    end
end

local function snapshot()
    local tracked = {}
    for _, category in ipairs(A.categories) do
        local state = A.state.categories[category.key]
        if state and state.tracked ~= false and state.applicable ~= false and A.OnActiveBar(category) then
            local row = state.bag
            local display = row or state.buy or (state.rows and state.rows[1])
            local entry = {
                category = category,
                row = row,
                reminder = category.kind == "reminder",
                icon = display and display.icon or category.icon or 134400,
                name = row and row.name or category.label,
            }
            if row and (row.count or 0) > 0 then
                entry.detail = L["%d in bags"]:format(row.count)
            elseif row then
                entry.detail = L["Ready"]
            else
                entry.detail = entry.reminder and L["Reminder only"] or L["None in bags"]
            end
            tracked[#tracked + 1] = entry
        end
    end
    return tracked
end

local function paintReveal()
    local remaining = 1 - reveal
    local scale = wheel:GetScale() * (1 + 0.25 * remaining * remaining)
    ringArt:SetScale(math.min(scale, screenFit))
    ringArt:SetAlpha(reveal)
end

local function hideArt()
    reveal = 0
    ringArt:Hide()
    ringArt:SetScript("OnUpdate", nil)
end

local function animateRing(self, elapsed)
    if mode then
        reveal = math.min(1, reveal + elapsed / OPEN_TIME)
    else
        reveal = math.max(0, reveal - elapsed / CLOSE_TIME)
    end
    paintReveal()
    if not mode and reveal == 0 then
        hideArt()
    elseif mode and reveal == 1 then
        self:SetScript("OnUpdate", nil)
    end
end

local function resize()
    local width, height = UIParent:GetSize()
    local scale = tonumber(A.db.wheelScale) or 1
    screenFit = math.min((width - 16) / DIAMETER, (height - 16) / DIAMETER)
    wheel:SetScale(math.min(math.max(scale, 0.5), screenFit))
    paintReveal()
end

local function layout()
    local count = #entries
    local now = GetTime()
    local step = TWO_PI / count
    local iconRadius = (INNER + OUTER) / 2
    local iconSize = TILE_SIZE
    if count > 1 then
        -- Allow room for the diagonal of an upright tile inside an angled slice.
        local span = 2 * math.sin(step / 2)
        local diagonal = TILE_SIZE * math.sqrt(2)
        iconRadius = math.min(OUTER - diagonal / 2 - 2, math.max(iconRadius, (diagonal + 4) / span))
        iconSize = math.min(TILE_SIZE, (iconRadius * span - 4) / math.sqrt(2))
    end
    local textScale = iconSize / TILE_SIZE
    for index, entry in ipairs(entries) do
        local slice = buttons[index] or createSlice(index)
        local angle = (index - 1) * step
        setMask(slice.surface, count - 1, angle, DIAMETER, 0, 0)
        setMask(slice.outline, count - 1, angle, DIAMETER, 0, 0)
        local x, y = math.sin(angle), math.cos(angle)
        slice.border:SetSize(iconSize, iconSize)
        slice.border:SetPoint("CENTER", ringArt, "CENTER", x * iconRadius, y * iconRadius)
        slice.icon:SetSize(iconSize - 4, iconSize - 4)
        slice.time:SetPoint("CENTER", slice.border, "CENTER", 0, 3 * textScale)
        slice.hand:SetTextScale(textScale)
        slice.hand:SetPoint("BOTTOMRIGHT", slice.border, "BOTTOMRIGHT", -3 * textScale, 4 * textScale)
        slice.hand:SetText(A.HandLabel(entry.category.slot))
        readStatus(entry, now)
        paintSlice(slice, entry, false)
        showSlice(slice, true)
    end
    for index = count + 1, #buttons do showSlice(buttons[index], false) end
    tint(art.base, COLORS.sidebar, 0.88)
    tint(art.hub, COLORS.panel)
    tint(art.hubEdge, COLORS.edge)
    tint(art.pointer, COLORS.mint)
    art.pointer:Hide()
    paintCenter(nil)
    statusAt = now + 1
end

local function closeWheel()
    if not mode then return end
    mode, selected, entries, originX, originY = nil, nil, nil, nil, nil
    wheel:Hide()
    if reveal == 0 or InCombatLockdown() or not A.db.showWheel then
        hideArt()
    else
        ringArt:SetScript("OnUpdate", animateRing)
    end
    if not InCombatLockdown() then
        preview:Hide()
        ClearOverrideBindings(escapeOwner)
    end
end

local function openWheel(nextMode)
    if InCombatLockdown() then return false, L["The buff wheel opens outside combat."] end
    if not A.db.showWheel then return false, L["The buff wheel is disabled."] end

    local tracked = snapshot()
    if #tracked == 0 then return false, L["Track a buff category to open the wheel."] end
    if mode then closeWheel() end
    mode, entries = nextMode, tracked
    resize()
    layout()
    wheel:Show()
    ringArt:SetScript("OnUpdate", animateRing)
    ringArt:Show()
    if mode == "hold" then
        local x, y = cursorPosition(wheel)
        local cx, cy = wheel:GetCenter()
        if not cx or (x - cx) ^ 2 + (y - cy) ^ 2 > INNER ^ 2 then
            originX, originY = x, y
        end
    else
        preview:Show()
    end
    SetOverrideBindingClick(escapeOwner, true, "ESCAPE", escapeButton:GetName())
    return true
end

local function armAction(button)
    if InCombatLockdown() or not A.db.showWheel then return end
    local entry = entries[getSelection()]
    if not entry or not entry.row or not A.OnActiveBar(entry.category) then return end

    -- Keep the displayed action stable throughout a gesture. A changed bag choice
    -- or disabled category invalidates it instead of sending a different action.
    local state = A.state.categories[entry.category.key]
    local row = state and state.bag
    if state and state.tracked ~= false and state.applicable ~= false and row
        and row.item.id == entry.row.item.id and row.item.spell == entry.row.item.spell then
        A.SetAction(button, entry.category, row)
    end
end

local function releaseAction(button)
    if not InCombatLockdown() then A.SetAction(button, nil, nil) end
    closeWheel()
end

local function baseKey(key)
    -- Binding modifier prefixes end in a hyphen. The last key may itself be "-".
    local base = key
    for _, prefix in ipairs({ "ALT-", "CTRL-", "SHIFT-", "META-" }) do
        if base:sub(1, #prefix) == prefix then base = base:sub(#prefix + 1) end
    end
    return base
end

local function supportsHold(key)
    local base = baseKey(key)
    return base ~= "MOUSEWHEELUP" and base ~= "MOUSEWHEELDOWN" and base ~= "ESCAPE"
end

local function pollRelease()
    local polling
    for _, input in ipairs(inputPool) do
        if input.down and input.poll then
            if IsKeyDown(input.base, true) then
                polling = true
            else
                input.down = nil
                if held == input then
                    held = nil
                    if mode == "hold" then closeWheel() end
                end
            end
        end
    end
    if not polling then bindingOwner:SetScript("OnUpdate", nil) end
end

local function makeInput(key)
    local button = CreateFrame("Button", "AlwaysBuffedWheelBinding" .. (#inputPool + 1), UIParent,
        "SecureActionButtonTemplate")
    button:EnableMouse(false)
    button:SetSize(1, 1)
    button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -20, 20)
    button:SetAlpha(0)
    button:SetAttribute("useOnKeyDown", false)
    button:RegisterForClicks("AnyDown", "AnyUp")

    local input = { button = button, base = baseKey(key) }
    button:SetScript("PreClick", function(self, _, down)
        if down then
            if input.down then return end
            input.down = true
            input.poll = IsKeyDown and IsKeyDown(input.base, true)
            if input.poll then bindingOwner:SetScript("OnUpdate", pollRelease) end
            if not held and openWheel("hold") then held = input end
        elseif held == input and mode == "hold" then
            armAction(self)
        end
    end)
    button:SetScript("PostClick", function(self, _, down)
        if down then return end
        input.down = nil
        if held == input then
            held = nil
            if mode == "hold" then releaseAction(self) end
        end
    end)
    inputPool[#inputPool + 1] = input
    inputs[key] = input
    return input
end

local function updateBindings()
    if not bindingOwner or bindingsUpdating then return end
    if InCombatLockdown() then
        bindingsWaiting = true
        return
    end

    local keys = { GetBindingKey(BINDING) }
    local signature = table.concat(keys, "\n")
    bindingsWaiting = false
    if bindingSignature == signature then return end
    bindingSignature = signature
    bindingsUpdating = true
    if mode == "hold" then closeWheel() end
    held = nil
    for _, input in ipairs(inputPool) do input.down = nil end
    ClearOverrideBindings(bindingOwner)
    for _, key in ipairs(keys) do
        if supportsHold(key) then
            local input = inputs[key] or makeInput(key)
            SetOverrideBindingClick(bindingOwner, false, key, input.button:GetName())
        end
    end
    bindingsUpdating = nil
end

function A.GetWheelBinding()
    return (GetBindingKey(BINDING))
end

function A.SetWheelBinding(key)
    if InCombatLockdown() then return false, L["Change the wheel binding after combat."] end
    if key == "" then key = nil end
    if key then
        if not supportsHold(key) then return false, L["Choose a key or mouse button you can hold."] end
        local action = GetBindingAction(key, true)
        if action and action ~= "" and action ~= BINDING and not A.IsRetiredBuffBinding(action)
            and not action:match("^CLICK AlwaysBuffedWheelBinding%d+") then
            local name = _G["BINDING_NAME_" .. action] or action
            return false, L["%s is already bound to %s."]:format(key, name)
        end
        if not SetBinding(key, BINDING) then return false, L["That key cannot be bound to the buff wheel."] end
    end
    for _, old in ipairs({ GetBindingKey(BINDING) }) do
        if old ~= key then SetBinding(old) end
    end
    SaveBindings(GetCurrentBindingSet())
    updateBindings()
    return true
end

function A.ToggleWheel()
    if mode then
        closeWheel()
        return true
    end
    if not wheel then return false, L["The buff wheel is unavailable."] end
    return openWheel("preview")
end

function A.RefreshWheel()
    if not mode then return end
    if not A.db.showWheel or InCombatLockdown() then
        closeWheel()
    elseif mode == "preview" then
        entries, selected = snapshot(), nil
        if #entries == 0 then
            closeWheel()
        else
            resize()
            layout()
            updateSelection()
        end
    elseif not A.OnActiveBar(entries[1].category) then
        closeWheel()
    else
        refreshStatuses(GetTime())
    end
end

function A.InitWheel()
    if wheel or InCombatLockdown() then return end

    wheel = CreateFrame("Frame", "AlwaysBuffedWheel", UIParent)
    wheel:SetFrameStrata("FULLSCREEN_DIALOG")
    wheel:SetSize(DIAMETER, DIAMETER)
    wheel:SetPoint("CENTER", UIParent, "CENTER")
    wheel:Hide()
    wheel:SetScript("OnHide", closeWheel)
    wheel:SetScript("OnUpdate", updateSelection)
    -- The artwork can finish fading after the input frame releases the shortcut or click.
    ringArt = CreateFrame("Frame", nil, UIParent)
    ringArt:SetFrameStrata("FULLSCREEN_DIALOG")
    ringArt:SetSize(DIAMETER, DIAMETER)
    ringArt:SetPoint("CENTER", UIParent, "CENTER")
    ringArt:EnableMouse(false)
    ringArt:Hide()

    art.base = atlasTexture("BACKGROUND", "Fill", 0)
    setMask(art.base, DISC, 0, DIAMETER, 0, 0)
    art.hub = atlasTexture("BACKGROUND", "Fill", 2)
    art.hubEdge = atlasTexture("BORDER", "Stroke", 2)
    setMask(art.hub, DISC, 0, INNER * 2, 0, 0)
    setMask(art.hubEdge, DISC, 0, INNER * 2, 0, 0)
    art.title = makeFont(15, true)
    art.title:SetWidth(104)
    art.title:SetPoint("BOTTOM", ringArt, "CENTER", 0, 3)
    art.title:SetMaxLines(2)
    art.detail = makeFont(11, false)
    art.detail:SetWidth(104)
    art.detail:SetPoint("TOP", ringArt, "CENTER", 0, -6)
    art.detail:SetMaxLines(2)
    art.pointer = atlasTexture("OVERLAY", "Fill", 3)
    setMask(art.pointer, DISC, 0, 8, 0, 0)

    preview = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    preview:SetFrameStrata("FULLSCREEN_DIALOG")
    preview:SetAllPoints(UIParent)
    preview:EnableMouse(true)
    preview:SetAttribute("useOnKeyDown", false)
    preview:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    preview:SetScript("PreClick", function(self, button)
        if mode == "preview" and button == "LeftButton" then armAction(self) end
    end)
    preview:SetScript("PostClick", function(self)
        if mode == "preview" then releaseAction(self) end
    end)
    preview:SetScript("OnHide", function()
        if mode == "preview" then closeWheel() end
    end)
    preview:Hide()
    preview:SetAttribute("_onstate-combat", [[ if newstate == "combat" then self:Hide() end ]])
    RegisterStateDriver(preview, "combat", "[combat] combat; idle")

    bindingOwner = CreateFrame("Frame")
    escapeOwner = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    escapeOwner:SetAttribute("_onstate-combat", [[ if newstate == "combat" then self:ClearBindings() end ]])
    RegisterStateDriver(escapeOwner, "combat", "[combat] combat; idle")
    escapeButton = CreateFrame("Button", "AlwaysBuffedWheelCancel", UIParent)
    escapeButton:EnableMouse(false)
    escapeButton:RegisterForClicks("AnyDown")
    escapeButton:SetScript("OnClick", closeWheel)

    bindingOwner:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_BINDINGS" then
            updateBindings()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if bindingsWaiting then updateBindings() end
            if not mode then
                preview:Hide()
                ClearOverrideBindings(escapeOwner)
            end
        else
            closeWheel()
            hideArt()
        end
    end)
    bindingOwner:RegisterEvent("UPDATE_BINDINGS")
    bindingOwner:RegisterEvent("PLAYER_REGEN_ENABLED")
    bindingOwner:RegisterEvent("PLAYER_REGEN_DISABLED")
    bindingOwner:RegisterEvent("PLAYER_LEAVING_WORLD")
    A.theme.OnChange(function()
        if mode == "preview" then
            A.RefreshWheel()
        elseif mode == "hold" then
            local previous = selected
            layout()
            selected = nil
            if previous then updateSelection() end
        end
    end)
    updateBindings()
end
