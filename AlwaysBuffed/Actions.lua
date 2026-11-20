local _, A = ...
local L = A.L

local T, C = A.theme, A.theme.colors
local addonIcon = "Interface\\AddOns\\AlwaysBuffed\\Media\\AlwaysBuffed"
A.barShortcutName = "AlwaysBuffedBarShortcut"
local BAR_SIZE, GAP = 40, 4
local GRIP_SIZE = BAR_SIZE + 2 * GAP
local bar, tray, grip, minimap
local missingCount, activeCount = 0, 0
local buttons, tints = {}, {}
local layoutKey, currentScale, hoverMode, hoverAlpha
local revealFromKey

local function solid(frame, layer, color, alpha, sublevel)
    local tex = frame:CreateTexture(nil, layer, nil, sublevel or 0)
    tints[#tints + 1] = { tex, color, alpha or 1 }
    tex:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return tex
end

local function inset(texture, frame, amount)
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", amount, -amount)
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -amount, amount)
end

local function backdrop(frame, color, alpha)
    solid(frame, "BACKGROUND", C.edge, alpha):SetAllPoints()
    inset(solid(frame, "BORDER", color, alpha), frame, 1)
end

local function tileFace(frame, size)
    local face = solid(frame, "BORDER", C.edge, 1, 1)
    face:SetSize(size, size)
    face:SetPoint("CENTER")
    return face
end

local function tileArtwork(frame, tile)
    local keyline = frame:CreateTexture(nil, "BORDER", nil, 3)
    keyline:SetColorTexture(0.06, 0.055, 0.045, 1)
    inset(keyline, tile, 2)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    inset(icon, tile, 3)
    return icon
end

local function font(frame, size, flags, maxSize)
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    T.Font(fs, size, true, flags, maxSize)
    return fs
end

local function gripCounter(frame, corner, offset)
    local label = font(frame, 11, "OUTLINE", 11)
    label:SetPoint(corner, frame, corner, offset, 2)
    label:SetHeight(13)
    label.backing = solid(frame, "ARTWORK", C.panel, 0.96, 1)
    inset(label.backing, label, -1)
    return label
end

local function showTooltip(button)
    local selected = button.displayRow
    local item = selected and selected.item
    local now = GetTime()
    local state = button.state or {}
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.category.kind == "reminder" then
        local name, detail, mode = A.ReminderStatus(button.category, state, now)
        GameTooltip:SetText(name)
        GameTooltip:AddLine(detail, unpack(mode == "active" and A.activeBorderColor or C.muted))
        if mode == "active" and state.activeSpellID then
            local description = C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(state.activeSpellID)
            if (not issecretvalue or not issecretvalue(description)) and description and description ~= "" then
                GameTooltip:AddLine(description, 1, 1, 1, true)
            end
        elseif mode == "missing" then
            GameTooltip:AddLine(state.reminderReason or (item and item.note) or L["Use a nearby campsite."], 1, 1, 1, true)
        end
        if state.bag then
            local itemName = state.bag.name or state.bag.item.name or button.category.label
            GameTooltip:AddLine(L["Click to use %s."]:format(itemName), 0.84, 0.84, 0.84, true)
        end
    else
        if item and item.spell then
            GameTooltip:SetSpellByID(item.spell)
        elseif item and item.id then
            GameTooltip:SetHyperlink("item:" .. item.id)
        else
            GameTooltip:SetText(button.category.label)
        end
        if button.category.slot and item then GameTooltip:AddLine(button.category.label, 0.84, 0.84, 0.84) end
        if A.EffectIsCurrent(state.active, state.expires, now) then
            local text = L["Active: %s"]:format(state.active)
            if state.expires and state.expires > now then text = text .. " (" .. A.BuffDuration(state.expires - now) .. ")" end
            GameTooltip:AddLine(text, unpack(A.activeBorderColor))
        end
        if button.actionType == "item" and button.count > 0 then
            GameTooltip:AddLine(L["%d in your bags"]:format(button.count), 1, 1, 1)
        end
        if button.ready then
            local hint = L["Click to use."]
            if item and item.spell and button.category.slot then
                hint = L["Click to cast. Shaman imbues may choose a hand automatically."]
            elseif button.category.slot then
                hint = button.category.slot == 17 and L["Apply to your off hand."] or L["Apply to your main hand."]
            end
            GameTooltip:AddLine(hint, 0.84, 0.84, 0.84, true)
        else
            GameTooltip:AddLine(L["None in your bags"], 0.84, 0.84, 0.84)
        end
    end
    local key = A.GetBuffBinding(button.category.key)
    if key then GameTooltip:AddLine(L["Shortcut: %s"]:format(GetBindingText(key, "KEY_")), 1, 1, 1) end
    if state.upgrade then
        GameTooltip:AddLine(L["Upgrade available: %s"]:format(state.upgrade.name), unpack(C.mint))
        GameTooltip:AddLine(L["Right-click to view the upgrade."], unpack(C.muted))
    else
        GameTooltip:AddLine(L["Right-click for this category."], unpack(C.muted))
    end
    if button.waiting then
        GameTooltip:AddLine(L["The selected action updates after combat."], unpack(C.muted))
    end
    GameTooltip:Show()
end

local function makeAction(parent, category, size)
    local button = CreateFrame("Button", "AlwaysBuffedAction_" .. category.key, parent, "SecureActionButtonTemplate")
    button.category = category
    button:SetSize(size, size)
    button:SetAttribute("useOnKeyDown", false)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("PostClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            local plan = A.state.categories[category.key]
            local upgrade = plan and plan.upgrade
            A.OpenCategory(category.key, upgrade and upgrade.item.id)
        end
    end)
    backdrop(button, C.sidebar)
    local face = tileFace(button, size)
    local rim = solid(button, "BORDER", A.activeBorderColor, 1, 2)
    rim:SetAllPoints(face)
    rim:Hide()
    button.activeBorder = rim
    button.icon = tileArtwork(button, face)
    button.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)

    -- Fixed-size icons reserve one center line and two lower corners.
    -- Bar scale enlarges all three labels together with their artwork.
    button.countText = font(button, 15, "OUTLINE", 15)
    button.countText:SetPoint("BOTTOMLEFT", 3, 3)
    button.countText:SetTextColor(1, 1, 1)

    local mark = CreateFrame("Frame", nil, button)
    mark:SetSize(11, 11)
    mark:SetPoint("TOPRIGHT", -2, -2)
    solid(mark, "BACKGROUND", C.ink):SetAllPoints()
    inset(solid(mark, "BORDER", C.mint), mark, 1)
    local across = solid(mark, "ARTWORK", C.ink)
    across:SetSize(7, 2)
    across:SetPoint("CENTER")
    local upright = solid(mark, "ARTWORK", C.ink)
    upright:SetSize(2, 7)
    upright:SetPoint("CENTER")
    mark:Hide()
    button.upgradeMark = mark
    button.timeText = font(button, 15, "OUTLINE", 15)
    button.timeText:SetTextColor(1, 1, 1)
    button.timeText:SetPoint("CENTER", 0, 3)
    if category.slot then
        local hand = font(button, 10, "OUTLINE", 10)
        hand:SetPoint("BOTTOMRIGHT", -3, 4)
        hand:SetText(category.slot == 17 and L["OH"] or L["MH"])
        button.handText = hand
    end
    inset(solid(button, "HIGHLIGHT", C.text, 0.16), button, 1)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)

    button:Hide()
    return button
end

local function actionFor(row)
    local item = row and row.item
    if not item then return nil, nil end
    if item.spell then return "spell", item.spell end
    if item.id and (row.count or 0) > 0 then return "item", item.id end
    return nil, nil
end

function A.SetAction(button, category, row)
    if InCombatLockdown() then return end
    local kind, id = actionFor(row)
    local target = kind and category.slot
    local unit = kind and (category.selfTarget or row.item.selfTarget or category.key:match("^scroll")) and "player" or nil
    if id ~= button.actionID or kind ~= button.actionType or target ~= button.actionSlot or unit ~= button.actionUnit then
        button:SetAttribute("*type1", kind)
        button:SetAttribute("*item1", kind == "item" and "item:" .. id or nil)
        button:SetAttribute("*spell1", kind == "spell" and id or nil)
        button:SetAttribute("*unit1", unit)
        button:SetAttribute("*target-slot1", target)
        button.actionID, button.actionType, button.actionSlot, button.actionUnit = id, kind, target, unit
    end
    button.actionRow = row
    return kind, id
end

local function updateStatus(button, now)
    local state = button.state
    if not state then return end
    local active = A.EffectIsCurrent(state.active, state.expires, now)
    button.activeBorder:SetShown(active)
    local texture = button.displayRow and button.displayRow.icon or button.category.icon or 134400
    local available = button.ready or active
    local endsAt = active and state.expires
    if button.category.kind == "reminder" then
        local stacks = active and state.activeStacks
        button.countText:SetText(stacks and stacks > 1 and tostring(stacks) or "")
        if active then
            texture = state.activeIcon or texture
        elseif button.category.key == "campfire" then
            texture, available = button.category.icon, false
        else
            local _, _, readyAt = A.ReminderCooldown(button.category, state.bag, now)
            endsAt = readyAt
            available = button.ready and not readyAt
        end
    end
    button.timeText:SetText(endsAt and endsAt > now and A.BuffDuration(endsAt - now, true) or "")
    if button.texture ~= texture then
        button.texture = texture
        button.icon:SetTexture(texture)
    end
    local faded = not available
    if button.faded ~= faded then
        button.faded = faded
        button.icon:SetDesaturated(faded)
    end
    local alpha = 1
    if faded then
        alpha = button.category.key == "campfire" and button.ready and 0.8 or 0.48
    end
    if button.iconAlpha ~= alpha then
        button.iconAlpha = alpha
        button.icon:SetAlpha(alpha)
    end
end

local function paintAction(button, categoryState, locked)
    local row = categoryState.bag
    local kind, id = actionFor(row)
    if not locked then A.SetAction(button, button.category, row) end

    button.waiting = kind ~= button.actionType or id ~= button.actionID
    if button.waiting then
        row = nil
        if button.actionID then
            for _, candidate in ipairs(categoryState.rows or {}) do
                local item = candidate.item
                local matches = item and (
                    (button.actionType == "spell" and item.spell == button.actionID)
                    or (button.actionType == "item" and item.id == button.actionID)
                )
                if matches then
                    row = candidate
                    break
                end
            end
        end
    end
    local display = row or button.actionRow or categoryState.buy or (categoryState.rows and categoryState.rows[1])
    button.displayRow = display
    button.state = categoryState
    button.count = row and row.count or 0
    button.ready = button.actionType == "spell" or (button.actionType == "item" and button.count > 0)
    if button.category.kind ~= "reminder" then
        button.countText:SetText(button.actionType ~= "spell" and tostring(button.count) or "")
        if button.handText then
            button.countText:SetTextScale(1)
            local width = button.countText:GetStringWidth()
            local room = BAR_SIZE - 8 - button.handText:GetStringWidth()
            if width > room and room > 0 then button.countText:SetTextScale(room / width) end
        end
    end
    button.upgradeMark:SetShown(categoryState.upgrade ~= nil)
    updateStatus(button, GetTime())
    if GameTooltip:IsOwned(button) then showTooltip(button) end
end

local function setBarPosition(x, y)
    bar:ClearAllPoints()
    local scale = bar:GetScale()
    bar:SetPoint("CENTER", UIParent, "CENTER", x / scale, y / scale)
end

local function stopBarDrag(self)
    if not self.dragX then return end
    self:SetScript("OnUpdate", nil)
    local x, y = bar:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    A.db.barAnchorX, A.db.barAnchorY = x * bar:GetScale() - centerX, y * bar:GetScale() - centerY
    self.dragX, self.dragY = nil, nil
    if not InCombatLockdown() then A.RefreshActions() end
end

local function startBarDrag(self)
    if A.db.locked or InCombatLockdown() then return end
    local scale = UIParent:GetEffectiveScale()
    local x, y = bar:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    self.dragX, self.dragY = x * bar:GetScale() - cursorX / scale, y * bar:GetScale() - cursorY / scale
    self:SetScript("OnUpdate", function(handle)
        if A.db.locked or InCombatLockdown() then stopBarDrag(handle) return end
        local px, py = GetCursorPosition()
        local centerX, centerY = UIParent:GetCenter()
        setBarPosition(px / scale + handle.dragX - centerX, py / scale + handle.dragY - centerY)
    end)
end

local function launchTooltip(self, help)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("AlwaysBuffed", unpack(C.text))
    GameTooltip:AddLine(L["Left-click to open settings."], unpack(C.muted))
    if A.db.showWheel then GameTooltip:AddLine(L["Right-click to open the buff wheel."], unpack(C.muted)) end
    if help then GameTooltip:AddLine(help, unpack(C.muted)) end
    GameTooltip:Show()
end

local function launchClick(_, button)
    if button == "LeftButton" then A.ToggleOptions() else A.ToggleWheel() end
end

local function placeMinimap()
    local angle = math.rad(tonumber(A.db.minimapAngle) or 218)
    local x, y = math.cos(angle), math.sin(angle)
    if GetMinimapShape and GetMinimapShape() == "SQUARE" then
        local side = math.max(math.abs(x), math.abs(y))
        x, y = x / side, y / side
    end
    minimap:SetPoint("CENTER", Minimap, "CENTER", x * Minimap:GetWidth() / 2, y * Minimap:GetHeight() / 2)
end

local function makeMinimap()
    if not Minimap then return end
    minimap = CreateFrame("Button", "AlwaysBuffedMinimapButton", Minimap)
    minimap:SetSize(31, 31)
    minimap:SetFrameStrata("MEDIUM")
    minimap:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    minimap:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimap:RegisterForDrag("LeftButton")
    minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local background = minimap:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(136467)
    background:SetSize(23, 23)
    background:SetPoint("CENTER", 0, 1)
    local border = minimap:CreateTexture(nil, "OVERLAY")
    border:SetTexture(136430)
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    local icon = minimap:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture(addonIcon)
    minimap:SetScript("OnClick", launchClick)
    minimap:SetScript("OnEnter", function(self) launchTooltip(self, L["Drag around the minimap to move."]) end)
    minimap:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimap:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX then return end
            local scale = Minimap:GetEffectiveScale()
            A.db.minimapAngle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX))
            placeMinimap()
        end)
    end)
    local function stopDrag(self) self:SetScript("OnUpdate", nil) end
    minimap:SetScript("OnDragStop", stopDrag)
    minimap:SetScript("OnHide", stopDrag)
    Minimap:HookScript("OnSizeChanged", placeMinimap)
    placeMinimap()
end


-- The grip has its own fixed dimensions. Its anchor never depends on the number
-- of actions, the missing indicator, or whether the adjacent tray is open.
local function positionGrip(count)
    local scale = A.db.barScale
    if currentScale == scale then return end
    currentScale = scale
    bar:SetScale(scale)
    if not tonumber(A.db.barAnchorX) then
        -- Older releases saved the center of the entire bar, including the icons.
        local oldWidth = A.db.collapsed and 76 or 43 + count * (BAR_SIZE + GAP)
        local viewWidth = UIParent:GetWidth()
        local center = tonumber(A.db.barX) or 0
        local left = math.max(-viewWidth / 2, math.min(center - oldWidth * scale / 2, viewWidth / 2 - oldWidth * scale))
        A.db.barAnchorX = left + GRIP_SIZE * scale / 2
        A.db.barAnchorY = tonumber(A.db.barY) or -185
    end
    setBarPosition(A.db.barAnchorX, tonumber(A.db.barAnchorY) or -185)
end

local function layoutActions(visible)
    if #visible == 0 then
        for _, button in pairs(buttons) do
            if button:IsShown() then button:Hide() end
        end
        layoutKey = nil
        return
    end
    local scale = bar:GetScale()
    local screenW, screenH = UIParent:GetWidth() / scale, UIParent:GetHeight() / scale
    local left, top = bar:GetLeft() or 0, bar:GetTop() or screenH
    local right, bottom = left + GRIP_SIZE, top - GRIP_SIZE
    local direction = A.db.barDirection
    local vertical = direction == "up" or direction == "down" or (not direction and A.db.barOrientation == "vertical")
    local pitch = BAR_SIZE + GAP
    local forwardSpace = vertical and bottom or screenW - right
    local backwardSpace = vertical and screenH - top or left
    if not direction then
        -- Preserve the side old horizontal and vertical layouts chose at this position.
        local forward = not A.db.barOrientation or #visible * pitch <= forwardSpace or forwardSpace >= backwardSpace
        if vertical then
            direction = forward and "down" or "up"
        else
            direction = forward and "right" or "left"
        end
        A.db.barDirection = direction
    end
    A.db.barOrientation = nil

    local forward = direction == "right" or direction == "down"
    local limit = forward and forwardSpace or backwardSpace
    local oppositeLimit = forward and backwardSpace or forwardSpace
    local crossForwardSpace = vertical and screenW - left or top
    local crossBackwardSpace = vertical and right or screenH - bottom
    local crossLines = math.max(1, math.floor((math.max(crossForwardSpace, crossBackwardSpace) - GAP) / pitch))
    -- Use the opposite side if wrapping toward the preferred edge would leave more tiles off screen.
    if #visible > math.floor(limit / pitch) * crossLines
        and math.floor(oppositeLimit / pitch) > math.floor(limit / pitch) then
        forward, limit = not forward, oppositeLimit
    end
    local keys = {}
    for i, cat in ipairs(visible) do
        keys[i] = cat.key
    end
    local key = table.concat(keys, ",") .. (vertical and "v" or "h") .. (forward and "+" or "-")
        .. (":%d:%d:%d:%d:%d"):format(limit, left, top, screenW, screenH)
    if key ~= layoutKey then
        layoutKey = key
        local perLine = math.min(#visible, math.max(1, math.floor(limit / pitch)))
        local lines = math.ceil(#visible / perLine)
        -- The padded grip already supplies the gap before the first action.
        local length, breadth = perLine * pitch, lines * pitch + GAP
        local width, height = vertical and breadth or length, vertical and length or breadth
        local crossForward = breadth <= crossForwardSpace or crossForwardSpace >= crossBackwardSpace
        local growRight, growDown
        if vertical then
            growRight, growDown = crossForward, forward
        else
            growRight, growDown = forward, crossForward
        end
        local xSide, ySide = growRight and "LEFT" or "RIGHT", growDown and "TOP" or "BOTTOM"
        local from = ySide .. xSide
        local to = vertical and ((growDown and "BOTTOM" or "TOP") .. xSide)
            or (ySide .. (growRight and "RIGHT" or "LEFT"))
        tray:ClearAllPoints()
        tray:SetPoint(from, bar, to, 0, 0)
        tray:SetSize(width, height)
        local farCorner = (growDown and "BOTTOM" or "TOP") .. (growRight and "RIGHT" or "LEFT")
        tray.outline:ClearAllPoints()
        tray.outline:SetPoint(from, bar, from, 0, 0)
        tray.outline:SetPoint(farCorner, tray, farCorner, 0, 0)
        for _, b in pairs(buttons) do b:Hide() end
        for i, cat in ipairs(visible) do
            local b = buttons[cat.key]
            b:ClearAllPoints()
            local along = (i - 1) % perLine
            local across = math.floor((i - 1) / perLine)
            local acrossOffset = GAP + across * pitch
            local x = vertical and acrossOffset or along * pitch
            local y = vertical and along * pitch or acrossOffset
            b:SetPoint(from, tray, from, growRight and x or -x, growDown and -y or y)
            b:Show()
        end
    end
end

local function updateHover()
    local over = grip.dragX or bar:IsMouseOver() or (tray:IsShown() and tray:IsMouseOver())
    if over then revealFromKey = nil end
    local alpha = (over or revealFromKey) and 1 or 0
    if hoverAlpha ~= alpha then
        hoverAlpha = alpha
        bar:SetAlpha(alpha)
    end
end

local function setHoverMode()
    local enabled = A.db.mouseoverOnly == true
    if hoverMode ~= enabled then
        hoverMode = enabled
        bar:SetScript("OnUpdate", enabled and updateHover or nil)
        if not enabled then
            hoverAlpha, revealFromKey = nil, nil
            bar:SetAlpha(1)
        end
    end
    if enabled then updateHover() end
end

-- Both hardware inputs toggle the same prepared tray. Only visibility changes
-- in combat; the protected action buttons keep their layout and assignments.
local toggleClick = [[
    local shortcut = self:GetAttribute("shortcut")
    if not shortcut and (button ~= "LeftButton" or IsShiftKeyDown()) then return end
    local bar, tray = self:GetFrameRef("bar"), self:GetFrameRef("tray")
    local collapsed = bar:IsShown() and not bar:GetAttribute("collapsed")
    bar:SetAttribute("collapsed", collapsed)
    if collapsed or not tray:GetAttribute("hasActions") then tray:Hide() else tray:Show() end
    bar:Show()
    self:CallMethod("FoldChanged", collapsed, shortcut)
]]

local function refreshVisibleStatuses()
    local now = GetTime()
    for _, button in pairs(buttons) do
        if button:IsShown() and button.state then
            updateStatus(button, now)
            if GameTooltip:IsOwned(button) then showTooltip(button) end
        end
    end
end

local function foldChanged(_, collapsed, shortcut)
    A.db.showBar, A.db.collapsed = true, collapsed
    revealFromKey = shortcut and not collapsed and A.db.mouseoverOnly
    A.RefreshGripCounts()
    if tray:IsShown() then refreshVisibleStatuses() end
    if hoverMode then updateHover() end
    A.RefreshOptions()
end

local function configureToggle(button, shortcut)
    button:SetFrameRef("bar", bar)
    button:SetFrameRef("tray", tray)
    button:SetAttribute("shortcut", shortcut)
    button:SetAttribute("_onclick", toggleClick)
    button.FoldChanged = foldChanged
end

-- Preserve the old callable binding for saved /run macros. A scripted call
-- during combat records the preference for the next out-of-combat layout.
function AlwaysBuffed_ToggleBar()
    if not A.db then return end
    A.db.collapsed = A.db.showBar and not A.db.collapsed
    A.db.showBar = true
    revealFromKey = not A.db.collapsed and A.db.mouseoverOnly
    if not InCombatLockdown() then A.RefreshActions() end
    A.RefreshOptions()
end

local function gripTooltip(self)
    local collapsed = bar:GetAttribute("collapsed")
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(A.state.barProfession and A.BarModeLabel(A.state.barProfession) or "AlwaysBuffed")
    GameTooltip:AddLine(collapsed and L["Click to expand the buff bar."] or L["Click to collapse the buff bar."])
    if collapsed then
        GameTooltip:AddLine(L["%d missing"]:format(missingCount), unpack(missingCount > 0 and C.missing or C.muted))
        GameTooltip:AddLine(L["%d active"]:format(activeCount), unpack(C.mint))
    end
    if not A.db.locked then GameTooltip:AddLine(L["Drag to move."]) end
    GameTooltip:AddLine(L["Shift-click for settings."])
    if A.db.showWheel then GameTooltip:AddLine(L["Right-click for the wheel."]) end
    GameTooltip:Show()
end

local function tintGrip()
    grip.activeText:SetTextColor(unpack(C.mint))
    grip.missingGlow:SetVertexColor(C.missing[1], C.missing[2], C.missing[3], 0.42)
end

function A.RefreshGripCounts()
    if not grip then return end
    local collapsed = bar:GetAttribute("collapsed") == true
    bar.outline:SetShown(not tray:IsShown())
    bar.fill:SetShown(not tray:IsShown())
    if collapsed then
        local now = GetTime()
        missingCount, activeCount = 0, 0
        for _, category in ipairs(A.categories) do
            local state = A.state.categories[category.key]
            if state and state.tracked and state.applicable ~= false and A.OnActiveBar(category) then
                if A.EffectIsCurrent(state.active, state.expires, now) then
                    activeCount = activeCount + 1
                else
                    missingCount = missingCount + 1
                end
            end
        end
        grip.missingText:SetText(tostring(missingCount))
        grip.missingText:SetTextColor(unpack(missingCount > 0 and C.missing or C.muted))
        grip.activeText:SetText(tostring(activeCount))
    end
    grip.missingText:SetShown(collapsed)
    grip.missingText.backing:SetShown(collapsed)
    grip.activeText:SetShown(collapsed)
    grip.activeText.backing:SetShown(collapsed)
    grip.countDivider:SetShown(collapsed)
    grip.missingGlow:SetShown(collapsed and A.db.highlightMissing == true and missingCount > 0)
    for _, dot in ipairs(grip.dragDots) do dot:SetShown(not collapsed) end
    if GameTooltip:IsOwned(grip) then gripTooltip(grip) end
end

function A.RefreshActions()
    local locked = InCombatLockdown()
    if not bar then
        if not locked then A.InitActions() end
        return
    end
    local visible = {}
    for _, category in ipairs(A.categories) do
        local plan = A.state.categories[category.key]
        local button = buttons[category.key]
        if locked then
            if plan and button:IsShown() then paintAction(button, plan, true) end
        elseif plan and plan.tracked and plan.applicable ~= false and A.OnActiveBar(category) then
            visible[#visible + 1] = category
            paintAction(button, plan, false)
        elseif button.actionRow then
            A.SetAction(button, category, nil)
        end
    end
    if minimap then minimap:SetShown(A.db.showMinimap) end
    A.RefreshBuffBindings()
    setHoverMode()
    if not locked then
        positionGrip(#visible)
        layoutActions(visible)
        bar:SetAttribute("collapsed", A.db.collapsed == true)
        tray:SetAttribute("hasActions", #visible > 0)
        tray:SetShown(#visible > 0 and not A.db.collapsed)
        bar:SetShown(A.db.showBar)
    end
    A.RefreshGripCounts()
    if hoverMode then updateHover() end
end

function A.InitActions()
    if bar or InCombatLockdown() then return end
    bar = CreateFrame("Frame", "AlwaysBuffedBar", UIParent, "SecureFrameTemplate")
    bar:SetSize(GRIP_SIZE, GRIP_SIZE)
    bar:SetClampedToScreen(true)
    bar:SetFrameStrata("MEDIUM")
    bar:Hide()
    bar.outline = solid(bar, "BACKGROUND", C.edge, 0.96)
    inset(bar.outline, bar, 0)
    bar.fill = solid(bar, "BORDER", C.panel, 0.96)
    inset(bar.fill, bar.outline, 1)
    tray = CreateFrame("Frame", nil, bar, "SecureFrameTemplate")
    tray.outline = solid(tray, "BACKGROUND", C.edge, 0.96)
    inset(solid(tray, "BORDER", C.panel, 0.96), tray.outline, 1)

    grip = CreateFrame("Button", "AlwaysBuffedBarFold", bar, "SecureHandlerClickTemplate")
    configureToggle(grip, false)
    grip:SetAllPoints()
    grip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    grip:RegisterForDrag("LeftButton")
    local face = tileFace(grip, BAR_SIZE)
    grip.icon = tileArtwork(grip, face)
    grip.icon:SetTexCoord(0, 1, 0, 1)
    grip.icon:SetTexture(addonIcon)
    grip.dragDots = {}
    for col = -1, 1 do
        local dot = solid(grip, "ARTWORK", C.muted, 0.85, 2)
        dot:SetSize(2, 2)
        dot:SetPoint("BOTTOM", face, "BOTTOM", col * 4, 5)
        grip.dragDots[#grip.dragDots + 1] = dot
    end
    grip.missingText = gripCounter(grip, "BOTTOMLEFT", 4)
    grip.activeText = gripCounter(grip, "BOTTOMRIGHT", -4)
    grip.countDivider = solid(grip, "ARTWORK", C.edge, 1, 2)
    grip.countDivider:SetPoint("BOTTOM", 0, 1)
    grip.countDivider:SetSize(1, 5)
    grip.missingGlow = grip:CreateTexture(nil, "BACKGROUND")
    grip.missingGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    grip.missingGlow:SetBlendMode("ADD")
    grip.missingGlow:SetSize(64, 64)
    grip.missingGlow:SetPoint("CENTER")
    tintGrip()
    solid(grip, "HIGHLIGHT", C.text, 0.13):SetAllPoints(face)
    grip:SetScript("PostClick", function(_, button)
        if button == "RightButton" then A.ToggleWheel()
        elseif IsShiftKeyDown() then A.ToggleOptions()
        end
    end)
    grip:SetScript("OnEnter", gripTooltip)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnDragStart", startBarDrag)
    grip:SetScript("OnDragStop", stopBarDrag)
    grip:SetScript("OnHide", stopBarDrag)

    for _, category in ipairs(A.categories) do
        buttons[category.key] = makeAction(tray, category, BAR_SIZE)
    end
    -- The shortcut can restore a hidden bar, so its target lives outside it.
    local shortcut = CreateFrame("Button", A.barShortcutName, UIParent, "SecureHandlerClickTemplate")
    shortcut:SetSize(1, 1)
    shortcut:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -20, 20)
    shortcut:EnableMouse(false)
    shortcut:RegisterForClicks("AnyDown")
    configureToggle(shortcut, true)
    makeMinimap()
    A.InitBuffBindings()
    T.OnChange(function()
        for _, entry in ipairs(tints) do
            local c = entry[2]
            entry[1]:SetColorTexture(c[1], c[2], c[3], entry[3])
        end
        tintGrip()
        A.RefreshActions()
    end)
    C_Timer.NewTicker(1, function()
        if bar:IsVisible() and bar:GetAttribute("collapsed") then
            A.RefreshGripCounts()
        elseif tray:IsVisible() then
            refreshVisibleStatuses()
        end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:SetScript("OnEvent", function()
        for _, b in pairs(buttons) do
            if b.category.key == "sleepingBag" and b:IsShown() then updateStatus(b, GetTime()) end
        end
    end)
    A.RefreshActions()
end
