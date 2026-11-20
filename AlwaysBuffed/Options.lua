local _, A = ...
local L = A.L

local theme = A.theme
local color = theme.colors
local textureColors, vertexColors, textColors, textLines = {}, {}, {}, {}
local panel, activePage = nil, "shopping"
local width, sidebarWidth = 1022, 254
local contentInset, contentRight = 24, 34
local contentWidth = width - sidebarWidth - contentInset - contentRight
local headerHeight, rowHeight, tableHeaderHeight = 66, 52, 34
local groupHeaderHeight = 35
local summaryY = 138
local summaryCellWidth = math.floor(contentWidth * 0.312)
local empty = "–"
local modifierKeys = {
    LSHIFT = true,
    RSHIFT = true,
    SHIFT = true,
    LCTRL = true,
    RCTRL = true,
    CTRL = true,
    LALT = true,
    RALT = true,
    ALT = true,
}
local navigationLabels = {
    elixirRegen = L["Regen Elixir"],
    scrollFamiliar = L["Familiar Scroll"],
    sleepingBag = L["Sleeping Bag"],
}
local sidebarSections = {
    { "leveling", L["Leveling staples"] },
    { "spec", L["For your spec"] },
    { "other", L["Other buffs"] },
    { "situational", L["Situational"] },
    { "reminders", L["Reminders"] },
}
local situationalBuffs = {
    flask = true, elixirBlastedLands = true, elixirArthas = true, elixirResistance = true,
    crystalSpire = true, foodChili = true, elixirFestival = true, draughtWaterBreathing = true,
    draughtWaterWalking = true, draughtDetection = true,
}
local rankingGroups = {
    { "best", L["Best for your spec"] },
    { "utility", L["Utility"] },
    { "notUseful", L["Not useful"] },
}

local function navigationLabel(category)
    return navigationLabels[category.key] or category.shortLabel or category.label
end

local function tintTexture(tex, tint)
    textureColors[tex] = tint
    tex:SetColorTexture(unpack(tint))
end

local function tintVertex(tex, tint)
    vertexColors[tex] = tint
    tex:SetVertexColor(unpack(tint))
end

local function tintLabel(text, tint)
    textColors[text] = tint
    text:SetTextColor(unpack(tint))
end

local function texture(parent, layer, tint)
    local tex = parent:CreateTexture(nil, layer)
    if tint then
        tintTexture(tex, tint)
    end
    return tex
end

local function fill(parent, layer, tint)
    local tex = texture(parent, layer, tint)
    tex:SetAllPoints()
    return tex
end

local function line(parent, offsetX, offsetY, rightInset)
    local tex = texture(parent, "ARTWORK", color.line)
    tex:SetHeight(1)
    tex:SetPoint("TOPLEFT", offsetX, -offsetY)
    tex:SetPoint("TOPRIGHT", -rightInset, -offsetY)
    return tex
end

local function sizeLabel(text, lines)
    local _, size = text:GetFont()
    text:SetHeight(math.ceil(size * 1.12 * lines))
end

local function label(parent, size, tint, justify, strong, lines)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    theme.Font(text, size, strong)
    tintLabel(text, tint or color.text)
    text:SetJustifyH(justify or "LEFT")
    text:SetJustifyV(lines and "TOP" or "MIDDLE")
    text:SetWordWrap(lines ~= nil)
    text:SetMaxLines(lines or 1)
    textLines[text] = lines or 1
    sizeLabel(text, lines or 1)
    return text
end

local function hideTooltip(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

local function truncatedText(text)
    return text and text.IsTruncated and text:IsTruncated() and text:GetText()
end

local function showHint(owner)
    local title = truncatedText(owner.title)
    local hint = owner.hint or truncatedText(owner.description)
    if not title and not hint then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title or hint, 1, 1, 1, 1, true)
    if title and hint then
        GameTooltip:AddLine(hint, color.muted[1], color.muted[2], color.muted[3], true)
    end
    GameTooltip:Show()
end

local function showItem(owner)
    local row = owner.itemRow
    if not row then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
    if row.item.spell then
        GameTooltip:SetSpellByID(row.item.spell)
    elseif GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(row.item.id)
    else
        GameTooltip:SetHyperlink("item:" .. row.item.id)
    end
    if row.item.note then
        GameTooltip:AddLine(row.item.note, color.muted[1], color.muted[2], color.muted[3], true)
    end
    if row.reason then
        GameTooltip:AddLine(row.reason, color.gold[1], color.gold[2], color.gold[3], true)
    end
    GameTooltip:Show()
end

local function paintButton(btn)
    tintTexture(btn.bg, btn.selected and color.mint or color.edge)
    tintTexture(btn.face, btn.hovered and color.hover or (btn.selected and color.selected or color.raised))
    tintLabel(btn.title, btn.selected and color.mint or color.text)
end

local function button(parent, widthPixels, height, text, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(widthPixels, height)
    btn.bg = fill(btn, "BACKGROUND", color.edge)
    btn.face = texture(btn, "BORDER", color.raised)
    btn.face:SetPoint("TOPLEFT", 1, -1)
    btn.face:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.title = label(btn, 14, color.text, "CENTER", true)
    btn.title:SetPoint("LEFT", 4, 0)
    btn.title:SetPoint("RIGHT", -4, 0)
    btn.title:SetText(text)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        self.hovered = true
        paintButton(self)
        showHint(self)
    end)
    btn:SetScript("OnLeave", function(self)
        self.hovered = false
        paintButton(self)
        hideTooltip(self)
    end)
    btn:SetScript("OnHide", btn:GetScript("OnLeave"))
    btn:SetScript("OnDisable", function(self)
        self.hovered = false
        paintButton(self)
        self:SetAlpha(0.52)
    end)
    btn:SetScript("OnEnable", function(self)
        self:SetAlpha(1)
    end)
    return btn
end

local function selectButton(btn, selected)
    btn.selected = selected
    paintButton(btn)
end

local function check(btn, checked)
    btn.checked = checked
    tintTexture(btn.box, (checked or btn.hovered) and color.mint or color.edge)
    tintTexture(btn.face, checked and color.mint or color.raised)
    btn.check:SetShown(checked and true or false)
end

local function checkbox(parent, widthPixels, text, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(widthPixels, 30)
    btn:SetHitRectInsets(-3, -3, -2, -2)
    btn.box = texture(btn, "ARTWORK", color.edge)
    btn.box:SetSize(17, 17)
    btn.box:SetPoint("LEFT", 1, 0)
    btn.face = texture(btn, "OVERLAY", color.raised)
    btn.face:SetPoint("TOPLEFT", btn.box, 1, -1)
    btn.face:SetPoint("BOTTOMRIGHT", btn.box, -1, 1)
    btn.check = texture(btn, "OVERLAY")
    btn.check:SetDrawLayer("OVERLAY", 1)
    btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    tintVertex(btn.check, color.ink)
    btn.check:SetSize(19, 19)
    btn.check:SetPoint("CENTER", btn.box, 0.5, 0)
    if text then
        btn.title = label(btn, 15, color.text, "LEFT", true)
        btn.title:SetPoint("LEFT", btn.box, "RIGHT", 8, 0)
        btn.title:SetPoint("RIGHT")
        btn.title:SetText(text)
    end
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        self.hovered = true
        check(self, self.checked)
        showHint(self)
    end)
    btn:SetScript("OnLeave", function(self)
        self.hovered = false
        check(self, self.checked)
        hideTooltip(self)
    end)
    btn:SetScript("OnHide", btn:GetScript("OnLeave"))
    return btn
end

local function scrollArea(parent, x, y, right, bottom)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", x, -y)
    scroll:SetPoint("BOTTOMRIGHT", -right, bottom)
    scroll:SetClipsChildren(true)
    scroll:EnableMouseWheel(true)

    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(1, 1)
    scroll:SetScrollChild(body)

    local bar = CreateFrame("Slider", nil, parent)
    bar:SetOrientation("VERTICAL")
    bar:EnableMouse(true)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, -1)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 1)
    bar:SetWidth(8)
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    local rail = texture(bar, "BACKGROUND", color.line)
    rail:SetPoint("TOP", bar, "TOP", 0, 0)
    rail:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    rail:SetWidth(2)
    local thumb = texture(bar, "ARTWORK", color.edge)
    thumb:SetSize(6, 32)
    bar:SetThumbTexture(thumb)
    bar:SetScript("OnEnter", function()
        tintTexture(thumb, color.mint)
    end)
    bar:SetScript("OnLeave", function()
        tintTexture(thumb, color.edge)
    end)
    bar:SetScript("OnHide", bar:GetScript("OnLeave"))
    bar:SetScript("OnValueChanged", function(_, value)
        scroll:SetVerticalScroll(value)
    end)

    local function updateRange()
        local height = scroll:GetHeight()
        local maxValue = math.max(0, body:GetHeight() - height)
        bar:SetMinMaxValues(0, maxValue)
        bar:SetValue(math.min(scroll:GetVerticalScroll(), maxValue))
        bar:SetShown(maxValue > 1)
        thumb:SetHeight(math.max(22, height * height / math.max(1, body:GetHeight())))
    end
    local function onWheel(_, delta)
        local _, maxValue = bar:GetMinMaxValues()
        bar:SetValue(math.max(0, math.min(maxValue, bar:GetValue() - delta * 80)))
    end
    scroll:SetScript("OnMouseWheel", onWheel)
    bar:EnableMouseWheel(true)
    bar:SetScript("OnMouseWheel", onWheel)
    scroll:SetScript("OnSizeChanged", function(self, newWidth)
        if newWidth > 0 then
            body:SetWidth(newWidth)
        end
        updateRange()
    end)
    body:SetScript("OnSizeChanged", updateRange)
    scroll.bar = bar
    scroll.updateRange = updateRange
    return scroll, body
end

local function priceText(price)
    if price == nil then
        return empty
    end
    return GetMoneyString(price, true)
end

local function tracked(category)
    if category.kind == "reminder" and not A.db.reminders then
        return false
    end
    local pref = A.Prefs(category.key).enabled
    if pref ~= nil then
        return pref
    end
    return A.DefaultTracked(category, A.state.profile)
end

local function toggleTrack(category)
    local enabled = not tracked(category)
    if enabled and category.kind == "reminder" then
        A.db.reminders = true
    end
    A.Prefs(category.key).enabled = enabled
    A.Update()
end

local function activeText(state)
    local now = GetTime()
    if not A.EffectIsCurrent(state.active, state.expires, now) then return L["Missing"] end
    if not state.expires or state.expires <= 0 then return state.active end
    return L["%s  ·  %s left"]:format(state.active, A.BuffDuration(state.expires - now))
end

local function paintReminder(card, category, state, now)
    local name, detail, mode = A.ReminderStatus(category, state, now)
    if mode == "ready" or mode == "missing" then
        if category.key == "campfire" then
            name = state.bag and L["Campfire kit ready"] or L["Use a nearby campsite"]
            detail = L["Sit or craft nearby for one minute to gain Camp Benefits. You can share another player’s campfire."]
        elseif category.key == "sleepingBag" then
            name = state.reminderReason or (state.bag and L["Sleeping bag ready"] or L["Requires Cozy Sleeping Bag in your bags."])
            detail = L["Rest inside for up to three minutes to gain up to 3% bonus experience."]
        end
    end
    card.title:SetText(name)
    card.detail:SetText(detail)
    tintLabel(card.title, mode == "ready" and color.text or color.gold)
    card.statusAt = now + 1
end

local function stopCapture(frame)
    frame.capture:EnableKeyboard(false)
    frame.bindingTarget = nil
end

local function saveShortcut(frame, shortcut, key)
    stopCapture(frame)
    local success, reason = shortcut.setBinding(key)
    frame.bindingError = success == false and (reason or L["Could not update this shortcut."]) or nil
    frame.bindingErrorTarget = frame.bindingError and shortcut or nil
    A.RefreshOptions()
end

local function buildShortcut(frame, parent, getBinding, setBinding, status)
    local shortcut = { getBinding = getBinding, setBinding = setBinding, status = status }
    shortcut.pick = button(parent, 158, 31, L["Set shortcut"], function()
        if InCombatLockdown() then return end
        if frame.bindingTarget == shortcut then
            stopCapture(frame)
        else
            frame.category.search:ClearFocus()
            frame.bindingTarget = shortcut
            frame.capture:SetPropagateKeyboardInput(false)
            frame.capture:EnableKeyboard(true)
        end
        frame.bindingError = nil
        A.RefreshOptions()
    end)
    shortcut.clear = button(parent, 70, 31, L["Clear"], function()
        if not InCombatLockdown() then saveShortcut(frame, shortcut, nil) end
    end)
    shortcut.clear:SetPoint("LEFT", shortcut.pick, "RIGHT", 7, 0)
    return shortcut
end

local function paintShortcut(frame, shortcut, name, defaultStatus)
    local binding = shortcut.getBinding()
    local listening = frame.bindingTarget == shortcut
    local editable = not InCombatLockdown()
    local bindingText = binding and GetBindingText(binding)
    local errorText = frame.bindingErrorTarget == shortcut and frame.bindingError or nil
    shortcut.pick.title:SetText(listening and L["Cancel"] or bindingText or L["Set shortcut"])
    shortcut.pick.hint = bindingText and L["Change %s shortcut (%s)"]:format(name, bindingText) or L["Bind %s"]:format(name)
    selectButton(shortcut.pick, listening)
    shortcut.pick:SetEnabled(editable)
    shortcut.clear:SetEnabled(binding ~= nil and editable)
    shortcut.status:SetText(not editable and L["Shortcut and tracked action changes apply after combat."]
        or (listening and L["Press a key combination. Esc cancels."]) or errorText or defaultStatus)
    tintLabel(shortcut.status, errorText and editable and color.gold or color.muted)
end

local function navigate(key, upgradeItemID)
    local page = panel.category
    local search = page.search
    local state = A.state.categories[key]
    local upgrade = state and state.upgrade
    local reveal = upgrade and upgrade.eligible and upgrade.item.id == upgradeItemID
    search:ClearFocus()
    if activePage ~= key or (reveal and not A.MatchesItemSearch(upgrade, search:GetText() or "")) then
        search:SetText("")
    end
    if activePage ~= key or upgradeItemID ~= nil then
        panel.highlightItemID = reveal and upgradeItemID or nil
    end
    if reveal then
        local collapsed = page.collapsedGroups[key]
        if collapsed then collapsed[upgrade.group] = nil end
    end
    activePage = key
    stopCapture(panel)
    panel.bindingError = nil
    panel.scroll.bar:SetValue(0)
    A.RefreshOptions()
    local nav = panel.sidebarEntries[key]
    if nav then
        local view = panel.sidebarScroll
        local top = view:GetVerticalScroll()
        if nav.offset < top then
            view.bar:SetValue(nav.offset)
        elseif nav.offset + nav:GetHeight() > top + view:GetHeight() then
            view.bar:SetValue(nav.offset + nav:GetHeight() - view:GetHeight())
        end
    end
    if reveal and panel.highlightRowY then
        local view = panel.scroll
        view.updateRange()
        view.bar:SetValue(math.max(0, panel.highlightRowY - (view:GetHeight() - rowHeight) / 2))
    end
end

local function paintNav(nav)
    local selected = nav.key == activePage
    tintTexture(nav.bg, selected and color.selected or (nav.hovered and color.hover or color.sidebar))
    tintLabel(nav.title, selected and color.mint or color.text)
    nav.mark:SetShown(selected)
end

local function placeSidebarEntry(nav, y)
    nav:ClearAllPoints()
    nav:SetPoint("TOPLEFT", 8, -y)
    nav:SetPoint("TOPRIGHT", -8, -y)
    nav.offset = y
end

local function sidebarEntry(parent, text, icon, key, category)
    local nav = CreateFrame("Button", nil, parent)
    nav:SetHeight(34)
    nav.bg = fill(nav, "BACKGROUND", color.sidebar)
    nav.mark = texture(nav, "ARTWORK", color.mint)
    nav.mark:SetPoint("TOPLEFT")
    nav.mark:SetPoint("BOTTOMLEFT")
    nav.mark:SetWidth(1)
    local image = texture(nav, "ARTWORK")
    image:SetPoint("LEFT", 8, 0)
    image:SetSize(19, 19)
    image:SetTexture(icon)
    image:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    nav.title = label(nav, 15, color.text, "LEFT", true)
    nav.title:SetPoint("LEFT", image, "RIGHT", 9, 0)
    nav.title:SetPoint("RIGHT", category and -29 or -4, 0)
    nav.title:SetText(text)
    nav.key, nav.category, nav.inScroll = key, category, category ~= nil
    if category then
        nav.track = checkbox(nav, 21, nil, function()
            toggleTrack(category)
        end)
        nav.track:SetPoint("RIGHT", -3, 0)
    end
    nav:SetScript("OnEnter", function(self)
        self.hovered = true
        paintNav(self)
        showHint(self)
    end)
    nav:SetScript("OnLeave", function(self)
        self.hovered = false
        paintNav(self)
        hideTooltip(self)
    end)
    nav:SetScript("OnHide", nav:GetScript("OnLeave"))
    nav:SetScript("OnClick", function(self)
        navigate(self.key)
    end)
    return nav
end

local function refreshSidebar(frame)
    local profile, plans = A.state.profile, A.state.categories
    local main = not plans.weapon or plans.weapon.applicable ~= false
    local offhand = not plans.weaponOffhand or plans.weaponOffhand.applicable ~= false
    if frame.sidebarProfile == profile and frame.sidebarMain == main and frame.sidebarOffhand == offhand then return end
    frame.sidebarProfile, frame.sidebarMain, frame.sidebarOffhand = profile, main, offhand

    local view, selected = frame.sidebarScroll, frame.sidebarEntries[activePage]
    local scroll = view:GetVerticalScroll()
    local position = selected and selected.offset and selected.offset - scroll
    local keepSelected = position and position < view:GetHeight() and position + selected:GetHeight() > 0
    local buckets = {}
    for _, section in ipairs(frame.sidebarSections) do
        buckets[section[1]] = {}
    end
    local classCount = 0
    for _, category in ipairs(A.categories) do
        local key = category.key
        local nav = frame.sidebarEntries[key]
        if nav then
            local section = "other"
            local available = not category.slot or (category.slot == 16 and main) or (category.slot == 17 and offhand)
            if category.profession then
                section = category.profession
            elseif category.kind == "reminder" then
                section = "reminders"
            elseif key == "food" or key == "elixir" then
                section = "leveling"
            elseif profile.tracked[key] and available then
                section = "spec"
            elseif situationalBuffs[key] then
                section = "situational"
            end
            if section == "spec" and (category.slotType == "imbue" or key == "scrollFamiliar") then
                classCount = classCount + 1
                table.insert(buckets.spec, classCount, nav)
            else
                table.insert(buckets[section], nav)
            end
        end
    end

    local order = { unpack(frame.fixedNavigation) }
    local y = 0
    for _, section in ipairs(frame.sidebarSections) do
        local key = section[1]
        local entries, title = buckets[key], frame.sidebarTitles[key]
        title:SetShown(#entries > 0)
        if #entries > 0 then
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", 16, -y - 9)
            y = y + 33
            for _, nav in ipairs(entries) do
                placeSidebarEntry(nav, y)
                order[#order + 1] = nav
                y = y + 36
            end
        end
    end
    frame.navigation = order
    frame.sidebarBody:SetHeight(y + 2)
    view.updateRange()
    view.bar:SetValue(keepSelected and selected.offset - position or scroll)
end

local function buildSidebar(frame)
    frame.fixedNavigation, frame.categoryByKey, frame.sidebarEntries, frame.sidebarTitles = {}, {}, {}, {}
    frame.sidebarSections = { unpack(sidebarSections) }
    frame.professionChoices = {}
    for _, profession in ipairs(A.professions) do
        if not profession.class or profession.class == A.state.class then
            frame.sidebarSections[#frame.sidebarSections + 1] = { profession.key, profession.label }
            frame.professionChoices[#frame.professionChoices + 1] = profession
        end
    end
    local fixed = CreateFrame("Frame", nil, frame)
    fixed:SetPoint("TOPLEFT", 4, -(headerHeight + 9))
    fixed:SetWidth(sidebarWidth - 16)
    for index, entry in ipairs({
        { L["General"], "Interface\\Icons\\INV_Misc_Gear_01", "general" },
        { L["Appearance"], "Interface\\Icons\\INV_Misc_Gem_Sapphire_02", "appearance" },
        { L["Shopping list"], "Interface\\Icons\\INV_Misc_Coin_02", "shopping" },
        { L["Professions"], "Interface\\Icons\\INV_Misc_Book_09", "professions" },
    }) do
        local nav = sidebarEntry(fixed, unpack(entry))
        placeSidebarEntry(nav, (index - 1) * 36)
        frame.fixedNavigation[index] = nav
    end
    local fixedHeight = #frame.fixedNavigation * 36
    fixed:SetHeight(fixedHeight)
    local scroll, body = scrollArea(frame, 4, headerHeight + 14 + fixedHeight, width - sidebarWidth + 12, 11)
    frame.sidebarScroll, frame.sidebarBody = scroll, body
    for _, section in ipairs(frame.sidebarSections) do
        local title = label(body, 13, color.muted, "LEFT", true)
        title:SetText(section[2])
        frame.sidebarTitles[section[1]] = title
    end
    for _, category in ipairs(A.categories) do
        if A.CategoryForClass(category, A.state.class) then
            frame.sidebarEntries[category.key] = sidebarEntry(body, navigationLabel(category), category.icon, category.key, category)
            frame.categoryByKey[category.key] = category
        end
    end
    refreshSidebar(frame)
end

local function textPair(parent, heading)
    local value = label(parent, 16, color.text, "LEFT", true)
    value:SetPoint("TOPLEFT", 14, -29)
    value:SetPoint("TOPRIGHT", -10, -29)
    local caption = label(parent, 12, color.muted, "LEFT", true)
    caption:SetPoint("TOPLEFT", 14, -9)
    caption:SetPoint("TOPRIGHT", -10, -9)
    caption:SetText(heading)
    local details = label(parent, 13, color.muted)
    details:SetPoint("BOTTOMLEFT", 14, 8)
    details:SetPoint("BOTTOMRIGHT", -10, 8)
    parent:SetScript("OnEnter", showItem)
    parent:SetScript("OnLeave", hideTooltip)
    parent:SetScript("OnHide", hideTooltip)
    return value, details, caption
end

local function dataColumn(parent, right, widthPixels, size, tint, lines)
    local col = label(parent, size, tint, "RIGHT", false, lines)
    col:SetJustifyV("MIDDLE")
    col:SetPoint("RIGHT", -right, 0)
    col:SetWidth(widthPixels)
    return col
end

local function buildTableHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(tableHeaderHeight)
    fill(header, "BACKGROUND", color.raised)
    header.item = label(header, 13, color.muted, "LEFT", true)
    header.item:SetPoint("LEFT", 14, 0)
    header.level = dataColumn(header, 295, 66, 13, color.muted, 2)
    header.bags = dataColumn(header, 223, 62, 13, color.muted, 2)
    header.price = dataColumn(header, 106, 110, 13, color.muted, 2)
    return header
end

local percentStats = { crit = true, spellCrit = true, weaponCrit = true, haste = true, xp = true, hit = true }
local procOils = { [3824] = true, [3829] = true }

local function statText(row, category, limit)
    if not row then
        return ""
    end
    local parts = {}
    local xp
    for stat, value in pairs(row.item.stats or {}) do
        local name = A.statLabels[stat]
        if name and value ~= 0 and not (stat == "weapon" and procOils[row.item.id]) then
            if stat == "xp" then
                xp = L["%+g%% %s"]:format(value, category.kind == "food" and L["kill XP"] or L["XP"])
            else
                local format = percentStats[stat] and L["%+g%% %s"] or L["%+g %s"]
                parts[#parts + 1] = format:format(value, name)
            end
        end
    end
    table.sort(parts)
    if xp then
        parts[#parts + 1] = xp
    end
    return table.concat(parts, "  ·  ", 1, math.min(limit or #parts, #parts))
end

local function paintRow(widget)
    tintTexture(widget.bg, widget.hovered and color.hover or widget.tint)
end

local function makeItemRow(parent)
    local widget = CreateFrame("Frame", nil, parent)
    widget:SetHeight(rowHeight)
    widget:EnableMouse(true)
    widget.tint = color.panel
    widget.bg = fill(widget, "BACKGROUND", color.panel)
    widget.upgradeMark = texture(widget, "ARTWORK", color.mint)
    widget.upgradeMark:SetPoint("TOPLEFT")
    widget.upgradeMark:SetPoint("BOTTOMLEFT")
    widget.upgradeMark:SetWidth(1)
    line(widget, 0, rowHeight - 1, 0)
    widget.rank = label(widget, 13, color.muted, "RIGHT")
    widget.rank:SetPoint("LEFT", 6, 0)
    widget.rank:SetWidth(23)
    widget.icon = texture(widget, "ARTWORK")
    widget.icon:SetPoint("LEFT", 40, 0)
    widget.icon:SetSize(31, 31)
    widget.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    widget.name = label(widget, 16, color.text, "LEFT", true)
    widget.name:SetPoint("TOPLEFT", 82, -7)
    widget.name:SetPoint("TOPRIGHT", -329, -7)
    widget.detail = label(widget, 13, color.muted)
    widget.detail:SetPoint("BOTTOMLEFT", 82, 7)
    widget.detail:SetPoint("BOTTOMRIGHT", -329, 7)
    widget.level = dataColumn(widget, 295, 38, 15, color.text)
    widget.bags = dataColumn(widget, 223, 62, 15, color.text)
    widget.price = dataColumn(widget, 106, 110, 15, color.gold)
    widget.action = button(widget, 87, 30, L["Track"], function()
        if widget.shopping then
            navigate(widget.category.key)
        else
            local key, itemID = widget.category.key, widget.itemRow.item.id
            local pref = A.Prefs(key)
            local pin = pref.pin ~= itemID and itemID or nil
            local plan = widget.category.kind ~= "reminder" and A.state.categories[key]
            A.SetTrackedItem(pref, pin, plan)
            A.Update()
        end
    end)
    widget.action:SetPoint("RIGHT", -8, 0)
    widget:SetScript("OnEnter", function(self)
        self.hovered = true
        paintRow(self)
        showItem(self)
    end)
    widget:SetScript("OnLeave", function(self)
        self.hovered = false
        paintRow(self)
        hideTooltip(self)
    end)
    widget:SetScript("OnHide", widget:GetScript("OnLeave"))
    return widget
end

local function renderRow(frame, index, y, category, row, pinned, shopping, hasMarket, rank)
    local widget = frame.itemWidgets[index]
    if not widget then
        widget = makeItemRow(frame.body)
        frame.itemWidgets[index] = widget
    end
    local alternating = index % 2 == 0 and color.raised or color.panel
    local upgrade = not shopping and frame.highlightItemID == row.item.id
    widget.tint, widget.category = (pinned or upgrade) and color.selected or alternating, category
    widget.shopping, widget.itemRow = shopping, row
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", 0, -y)
    widget:SetPoint("TOPRIGHT", 0, -y)
    paintRow(widget)
    widget.upgradeMark:SetShown(upgrade)
    if upgrade then frame.highlightRowY = y end
    widget.rank:SetText(shopping and "" or tostring(rank or index))
    widget.icon:SetTexture(shopping and category.icon or row.icon)
    widget.name:SetText(shopping and category.label or (row.name or row.item.name))
    tintLabel(widget.name, (pinned or upgrade) and color.mint or ((not row or row.eligible) and color.text or color.muted))
    if shopping then
        local stat = statText(row, category, 1)
        local detail = row and (row.name or row.item.name) or L["No eligible purchase yet"]
        widget.detail:SetText(stat ~= "" and L["%s  ·  %s"]:format(detail, stat) or detail)
        widget.level:SetText("")
        widget.action.hint = nil
    else
        local stat = statText(row, category)
        local detail = row.reason or (stat ~= "" and stat) or row.item.note or ""
        if row.level > A.state.level then
            detail = stat ~= "" and L["At level %d  ·  %s"]:format(row.level, stat) or L["At level %d"]:format(row.level)
        end
        widget.detail:SetText(upgrade and (detail ~= "" and L["Upgrade  ·  %s"]:format(detail) or L["Upgrade"]) or detail)
        widget.level:SetText(category.kind ~= "reminder" and row.level or "")
        if pinned then
            widget.action.hint = L["Use automatic selection for this category."]
        elseif not row.eligible then
            widget.action.hint = L["Prefer this choice when it becomes available."]
        elseif row.canBuy then
            widget.action.hint = L["Prefer this item for buying or applying this buff."]
        else
            widget.action.hint = L["Prefer this choice when applying the buff."]
        end
    end
    tintLabel(widget.detail, upgrade and color.mint or color.muted)
    tintLabel(widget.level, row and row.eligible and color.text or color.muted)
    widget.bags:SetText(row and not row.item.spell and (row.count or 0) or empty)
    tintLabel(widget.bags, row and row.count and row.count > 0 and color.mint or color.muted)
    widget.price:SetText(hasMarket and priceText(row and row.price) or "")
    tintLabel(widget.price, row and row.price ~= nil and color.gold or color.muted)
    widget.action.title:SetText(shopping and L["View"] or (pinned and L["Tracked"] or L["Track"]))
    selectButton(widget.action, pinned)
    widget:Show()
end

local function paintSearch(search)
    tintTexture(search.bg, search:HasFocus() and color.mint or color.edge)
    search.placeholder:SetShown(not search:HasFocus() and (search:GetText() or "") == "")
end

local function buildSearch(frame, page)
    local searchRow = CreateFrame("Frame", nil, page)
    searchRow:SetSize(contentWidth, 32)
    local search = CreateFrame("EditBox", nil, searchRow)
    search:SetSize(contentWidth - 190, 32)
    search:SetPoint("LEFT")
    search:SetAutoFocus(false)
    search:SetMaxLetters(128)
    search:SetTextInsets(10, 10, 0, 0)
    theme.Font(search, 15, false)
    textColors[search] = color.text
    search:SetTextColor(unpack(color.text))
    search.bg = fill(search, "BACKGROUND", color.edge)
    local face = texture(search, "BORDER", color.raised)
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    search.placeholder = label(search, 14, color.muted)
    search.placeholder:SetPoint("LEFT", 10, 0)
    search.placeholder:SetText(L["Search names, stats, or effects"])
    search:SetScript("OnEditFocusGained", function(self)
        paintSearch(self)
        if frame.bindingTarget then
            stopCapture(frame)
            A.RefreshOptions()
        end
    end)
    search:SetScript("OnEditFocusLost", paintSearch)
    search:SetScript("OnEscapePressed", search.ClearFocus)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    search:SetScript("OnTextChanged", function(self, typed)
        paintSearch(self)
        if typed then A.RefreshOptions() end
    end)
    local clear = button(searchRow, 70, 32, L["Clear"], function()
        search:SetText("")
        search:SetFocus()
        A.RefreshOptions()
    end)
    clear:SetPoint("LEFT", search, "RIGHT", 7, 0)
    clear.hint = L["Clear the search for this category."]
    searchRow.clear = clear
    searchRow.count = dataColumn(searchRow, 3, 106, 14, color.muted)
    page.searchRow, page.search = searchRow, search
end

local function paintDisclosure(header, expanded)
    if header.expanded == expanded then return end
    header.expanded = expanded
    local x1, y1, x2, y2, x3, y3 = 12, 4, 16, 0, 12, -4
    if expanded then x1, y1, x2, y2, x3, y3 = 10, 2, 14, -2, 18, 2 end
    header.start:SetStartPoint("LEFT", header, x1, y1)
    header.start:SetEndPoint("LEFT", header, x2, y2)
    header.finish:SetStartPoint("LEFT", header, x2, y2)
    header.finish:SetEndPoint("LEFT", header, x3, y3)
end

local function buildRankingGroups(page)
    page.groupHeaders, page.collapsedGroups = {}, {}
    for _, group in ipairs(rankingGroups) do
        local key, title = unpack(group)
        local header = button(page, contentWidth, groupHeaderHeight, title, function()
            local collapsed = page.collapsedGroups[activePage] or {}
            page.collapsedGroups[activePage] = collapsed
            collapsed[key] = not collapsed[key]
            A.RefreshOptions()
        end)
        header.title:ClearAllPoints()
        header.title:SetJustifyH("LEFT")
        header.title:SetPoint("LEFT", 29, 0)
        header.title:SetPoint("RIGHT", -51, 0)
        header.count = dataColumn(header, 12, 42, 14, color.muted)
        header.start = header:CreateLine(nil, "ARTWORK")
        header.finish = header:CreateLine(nil, "ARTWORK")
        header.start:SetThickness(1.5)
        header.finish:SetThickness(1.5)
        tintTexture(header.start, color.mint)
        tintTexture(header.finish, color.mint)
        page.groupHeaders[key] = header
    end
end

local function buildCategory(frame)
    local page = CreateFrame("Frame", nil, frame.body)
    page:SetPoint("TOPLEFT")
    page:SetPoint("TOPRIGHT")
    page:SetHeight(summaryY + 87)
    page.track = checkbox(page, 171, L["Enable category"], function()
        toggleTrack(frame.categoryByKey[activePage])
    end)
    page.track:SetPoint("TOPRIGHT", 0, -1)
    page.track.hint = L["Show this buff on the bar and wheel for this profile."]
    page.restore = button(page, 121, 29, L["Use profile"], function()
        A.Prefs(activePage).enabled = nil
        A.Update()
    end)
    page.restore:SetPoint("RIGHT", page.track, "LEFT", -9, 0)
    page.restore.hint = L["Use the selected profile’s default for enabling this buff."]

    local shortcutTitle = label(page, 16, color.text, "LEFT", true)
    shortcutTitle:SetPoint("TOPLEFT", 0, -72)
    shortcutTitle:SetText(L["Buff shortcut"])
    local shortcutStatus = label(page, 13, color.muted, "LEFT", false, 2)
    shortcutStatus:SetPoint("TOPLEFT", 0, -97)
    shortcutStatus:SetWidth(contentWidth - 244)
    page.shortcut = buildShortcut(frame, page, function() return A.GetBuffBinding(activePage) end,
        function(key) return A.SetBuffBinding(activePage, key) end, shortcutStatus)
    page.shortcut.pick:SetPoint("TOPRIGHT", -(page.shortcut.clear:GetWidth() + 7), -77)

    local reminder = CreateFrame("Frame", nil, page)
    reminder:SetPoint("TOPLEFT", 0, -summaryY)
    reminder:SetPoint("TOPRIGHT", 0, -summaryY)
    reminder:SetHeight(87)
    fill(reminder, "BACKGROUND", color.raised)
    reminder.title = label(reminder, 17, color.text, "LEFT", true)
    reminder.title:SetPoint("TOPLEFT", 14, -10)
    reminder.title:SetPoint("TOPRIGHT", -14, -10)
    reminder.detail = label(reminder, 14, color.muted, "LEFT", false, 2)
    reminder.detail:SetPoint("TOPLEFT", 14, -36)
    reminder.detail:SetWidth(contentWidth - 28)
    reminder:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if self.category and now >= self.statusAt then
            paintReminder(self, self.category, A.state.categories[self.category.key] or {}, now)
        end
    end)
    page.reminder = reminder

    local status = CreateFrame("Frame", nil, page)
    status:SetPoint("TOPLEFT", 0, -summaryY)
    status:SetPoint("TOPRIGHT", 0, -summaryY)
    status:SetHeight(78)
    fill(status, "BACKGROUND", color.raised)
    page.status = status
    for index, caption in ipairs({ L["Recommended buy"], L["Best in bags"], L["Next unlock"] }) do
        local cell = CreateFrame("Frame", nil, status)
        cell:SetPoint("TOPLEFT", summaryCellWidth * (index - 1), 0)
        cell:SetSize(index == 3 and contentWidth - 2 * summaryCellWidth or summaryCellWidth, 78)
        if index > 1 then
            local separator = texture(cell, "ARTWORK", color.line)
            separator:SetWidth(1)
            separator:SetPoint("TOPLEFT", 0, -9)
            separator:SetPoint("BOTTOMLEFT", 0, 9)
        end
        cell:EnableMouse(true)
        cell.value, cell.details, cell.caption = textPair(cell, caption)
        status[index] = cell
    end
    page.cheap = checkbox(page, 146, L["Lowest price"], function()
        local pref = A.Prefs(activePage)
        pref.cheapest = not pref.cheapest
        A.Update()
    end)
    page.cheap.hint =
        L["Recommend the least expensive eligible item priced by Auctionator. A tracked item takes priority."]
    page.showUnusable = checkbox(page, 218, L["Show unusable items"], function()
        local pref = A.Prefs(activePage)
        pref.showUnusable = not pref.showUnusable
        A.RefreshOptions()
    end)
    page.showUnusable.hint = L["Include items and spells you cannot currently use."]
    page.clear = button(page, 136, 30, L["Use automatic"], function()
        A.SetTrackedItem(A.Prefs(activePage))
        A.Update()
    end)
    page.clear.hint = L["Return to the profile’s ranking and price preferences."]
    page.rankTitle = label(page, 18, color.text, "LEFT", true)
    page.rankTitle:SetText(L["Item rankings"])
    buildSearch(frame, page)
    buildRankingGroups(page)
    return page
end

local function contentPage(frame, height)
    local page = CreateFrame("Frame", nil, frame.body)
    page:SetPoint("TOPLEFT", 0, -50)
    page:SetPoint("TOPRIGHT", 0, -50)
    page:SetHeight(height)
    return page
end

local function sectionTitle(parent, y, text)
    local title = label(parent, 18, color.mint, "LEFT", true)
    title:SetPoint("TOPLEFT", 0, -y)
    title:SetText(text)
end

local function buildProfessions(frame)
    local page = contentPage(frame, 1)
    page.modes, page.links = {}, {}
    sectionTitle(page, 0, L["Bar mode"])

    local choices = { { key = "auto", label = A.BarModeLabel("auto") }, { key = "combat", label = A.BarModeLabel("combat") } }
    for _, profession in ipairs(frame.professionChoices) do
        choices[#choices + 1] = profession
    end
    local rows = math.ceil(#choices / 5)
    local columns = math.ceil(#choices / rows)
    local modeWidth = math.floor((contentWidth - (columns - 1) * 8) / columns)
    for index, choice in ipairs(choices) do
        local key = choice.key
        local mode = button(page, modeWidth, 33, choice.label, function() A.SetBarMode(key) end)
        mode:SetPoint("TOPLEFT", ((index - 1) % columns) * (modeWidth + 8), -31 - math.floor((index - 1) / columns) * 41)
        page.modes[key] = mode
    end
    local y = 31 + rows * 41
    page.activeBar = label(page, 15, color.text, "LEFT", true)
    page.activeBar:SetPoint("TOPLEFT", 0, -y - 3)
    local help = label(page, 14, color.muted, "LEFT", false, 2)
    help:SetPoint("TOPLEFT", 0, -y - 29)
    help:SetWidth(contentWidth)
    help:SetText(L["Automatic switches between the combat and fishing bars based on equipped gear."])
    y = y + 84
    line(page, 0, y - 16, 0)
    local linkWidth = math.floor((contentWidth - 12) / 2)
    for _, profession in ipairs(frame.professionChoices) do
        sectionTitle(page, y, profession.label)
        y = y + 30
        local index = 0
        for _, category in ipairs(A.categories) do
            if category.profession == profession.key and frame.categoryByKey[category.key] then
                local key = category.key
                local link = button(page, linkWidth, 33, category.label, function() navigate(key) end)
                link:SetPoint("TOPLEFT", (index % 2) * (linkWidth + 12), -y - math.floor(index / 2) * 41)
                page.links[key] = link
                index = index + 1
            end
        end
        y = y + math.ceil(index / 2) * 41 + 20
    end
    page:SetHeight(y)
    return page
end

local function settingsCopy(parent, title, detail, right)
    local textWidth = parent:GetWidth() - right - 1
    local name = label(parent, 16, color.text, "LEFT", true)
    name:SetPoint("TOPLEFT", 1, -9)
    name:SetWidth(textWidth)
    name:SetText(title)
    local description = label(parent, 13, color.muted, "LEFT", false, 2)
    description:SetPoint("TOPLEFT", 1, -32)
    description:SetWidth(textWidth)
    description:SetText(detail)
    return description, name
end

local function buildGeneral(frame)
    local page = contentPage(frame, 705)
    local columns = {}
    local columnWidth = math.floor((contentWidth - 28) / 2)
    for index = 1, 2 do
        local column = CreateFrame("Frame", nil, page)
        column:SetPoint("TOPLEFT", (index - 1) * (columnWidth + 28), 0)
        column:SetSize(columnWidth, page:GetHeight())
        columns[index] = column
    end
    local function refreshControls()
        A.RefreshActions()
        A.RefreshWheel()
        A.RefreshOptions()
    end
    page.checks = {}
    local function setting(column, y, key, title, detail)
        local control = checkbox(column, columnWidth, nil, function()
            A.db[key] = not A.db[key]
            if key == "reminders" then
                A.Update()
            else
                refreshControls()
            end
        end)
        line(column, 0, y, 0)
        control:SetPoint("TOPLEFT", 0, -y - 1)
        -- Leave room for a title and two translated lines at the largest text size.
        control:SetHeight(72)
        control:SetHitRectInsets(0, 0, 0, 0)
        control:SetHighlightTexture(fill(control, "HIGHLIGHT", color.raised))
        control.box:ClearAllPoints()
        control.box:SetPoint("RIGHT", -5, 0)
        control.description, control.title = settingsCopy(control, title, detail, 31)
        page.checks[key] = control
        return y + control:GetHeight() + 2
    end
    local bar, wheel = columns[1], columns[2]
    sectionTitle(bar, 0, L["Buff bar"])
    local directionY = setting(bar, 29, "showBar", L["Show buff bar"], L["See tracked buffs and their remaining time."])
    line(bar, 0, directionY, 0)
    local directionTitle = label(bar, 16, color.text, "LEFT", true)
    directionTitle:SetPoint("TOPLEFT", 1, -directionY - 5)
    directionTitle:SetText(L["Icons grow"])
    page.directions = {}
    local directionWidth = math.floor((columnWidth - 18) / 4)
    for index, option in ipairs({ { "left", L["Left"] }, { "right", L["Right"] },
        { "up", L["Up"] }, { "down", L["Down"] } }) do
        local value, text = unpack(option)
        local control = button(bar, directionWidth, 25, text, function()
            A.db.barDirection = value
            refreshControls()
        end)
        control:SetPoint("TOPLEFT", (index - 1) * (directionWidth + 6), -directionY - 33)
        page.directions[value] = control
    end
    local barY = setting(bar, directionY + 63, "mouseoverOnly", L["Show on mouseover"], L["Reveal the bar on hover. Buff shortcuts still work."])
    barY = setting(bar, barY, "locked", L["Lock bar position"], L["Keep the bar anchored when you drag it."])
    barY = setting(bar, barY, "collapsed", L["Collapse buff bar"], L["In combat, use the checklist or its shortcut."])
    barY = setting(bar, barY, "highlightMissing", L["Glow when buffs are missing"], L["Add a subtle glow to the collapsed bar when a tracked buff is missing."])
    line(bar, 0, barY, 0)
    local barBinding = CreateFrame("Frame", nil, bar)
    barBinding:SetPoint("TOPLEFT", 0, -barY - 1)
    barBinding:SetSize(columnWidth, 112)
    local barStatus = settingsCopy(barBinding, L["Bar toggle shortcut"], "", 0)
    page.barShortcut = buildShortcut(frame, barBinding, A.GetBarToggleBinding, A.SetBarToggleBinding, barStatus)
    page.barShortcut.pick:SetPoint("BOTTOMLEFT", 0, 1)
    sectionTitle(bar, barY + 131, L["Minimap"])
    setting(bar, barY + 160, "showMinimap", L["Show minimap button"], L["Open settings or the wheel from the minimap."])

    sectionTitle(wheel, 0, L["Buff wheel"])
    local wheelY = setting(wheel, 29, "showWheel", L["Enable buff wheel"], L["Show tracked buffs in a centered wheel."])
    line(wheel, 0, wheelY, 0)
    local bindingBox = CreateFrame("Frame", nil, wheel)
    bindingBox:SetPoint("TOPLEFT", 0, -wheelY - 1)
    bindingBox:SetSize(columnWidth, 148)
    local shortcutStatus = settingsCopy(bindingBox, L["Wheel shortcut"], "", 0)
    page.shortcut = buildShortcut(frame, bindingBox, A.GetWheelBinding, A.SetWheelBinding, shortcutStatus)
    page.shortcut.pick:SetPoint("BOTTOMLEFT", 0, 42)
    page.preview = button(bindingBox, 99, 31, L["Preview"], function()
        stopCapture(frame)
        local success, reason = A.ToggleWheel()
        frame.bindingError = success == false and reason or nil
        frame.bindingErrorTarget = frame.bindingError and page.shortcut or nil
        A.RefreshOptions()
    end)
    page.preview:SetPoint("LEFT", page.shortcut.clear, "RIGHT", 7, 0)
    page.preview.hint = L["Open the wheel at screen center. Use the binding to select a buff on key release."]
    local hint = label(bindingBox, 13, color.muted, "LEFT", false, 2)
    hint:SetPoint("BOTTOMLEFT", 1, 1)
    hint:SetPoint("BOTTOMRIGHT", 0, 1)
    hint:SetText(L["Hold the shortcut, point at a buff, and release to use it."])

    sectionTitle(wheel, wheelY + 176, L["Utility reminders"])
    local linksY = setting(wheel, wheelY + 205, "reminders", L["Enable reminders"], L["Allow Campfire and Sleeping Bag reminders."])
    page.reminderLinks = {}
    for index, key in ipairs({ "campfire", "sleepingBag" }) do
        local category = frame.categoryByKey[key]
        if category then
            local link = button(wheel, 150, 31, navigationLabel(category), function() navigate(key) end)
            link:SetPoint("TOPLEFT", (index - 1) * 157, -linksY - 6)
            page.reminderLinks[key] = link
        end
    end
    return page
end

local function pickColor(key, paletteColor)
    local picker = ColorPickerFrame
    local previous = A.db[key]
    local r, g, b = paletteColor[1], paletteColor[2], paletteColor[3]
    local opening = true
    picker:SetupColorPickerAndShow({
        r = r, g = g, b = b, hasOpacity = false,
        swatchFunc = function()
            if opening then return end
            local red, green, blue = picker:GetColorRGB()
            if not previous and red == r and green == g and blue == b then
                A.db[key] = nil
            else
                A.db[key] = { red, green, blue }
            end
            theme.Refresh()
        end,
        cancelFunc = function()
            A.db[key] = previous
            theme.Refresh()
        end,
    })
    opening = false
end

local function refreshScale(key)
    if key == "fontScale" then
        theme.Refresh()
    else
        A.RefreshActions()
        A.RefreshWheel()
        A.RefreshOptions()
    end
end

local function scaleSlider(parent, key, minimum, maximum)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetPoint("RIGHT", -77, 0)
    slider:SetSize(194, 24)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    local rail = texture(slider, "BACKGROUND", color.edge)
    rail:SetPoint("LEFT")
    rail:SetPoint("RIGHT")
    rail:SetHeight(3)
    local thumb = texture(slider, "ARTWORK", color.mint)
    thumb:SetSize(12, 18)
    slider:SetThumbTexture(thumb)
    slider.value = dataColumn(parent, 8, 61, 16, color.text)
    slider:SetScript("OnValueChanged", function(self, value, userInput)
        self.value:SetText(L["%d%%"]:format(math.floor(value * 100 + 0.5)))
        if not userInput then return end
        A.db[key] = value
        refreshScale(key)
    end)
    return slider
end

local function buildAppearance(frame)
    local page = contentPage(frame, 425)
    local reset = button(page, 161, 30, L["Restore defaults"], function()
        A.db.customAccent, A.db.customBackground = nil, nil
        A.db.barScale, A.db.wheelScale, A.db.fontScale = 1, 1, 1
        theme.Refresh()
        A.RefreshActions()
        A.RefreshWheel()
    end)
    reset:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", 0, 15)
    reset.hint = L["Restore the class accent, slate background and default sizes."]

    sectionTitle(page, 0, L["Colors"])
    page.colors = {}
    for index, spec in ipairs({
        { "customAccent", L["Accent"], L["Class color"], color.accent, L["Use class color"] },
        { "customBackground", L["Background"], L["Slate"], color.panel, L["Use slate"] },
    }) do
        local key, title, defaultName, paletteColor, resetText = unpack(spec)
        local y = 29 + (index - 1) * 67
        line(page, 0, y, 0)
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", 0, -y - 1)
        row:SetSize(contentWidth, 65)
        row.mode = settingsCopy(row, title, defaultName, 298)
        row.defaultName = defaultName
        row.paletteColor = paletteColor
        row.reset = button(row, 141, 32, resetText, function()
            A.db[key] = nil
            theme.Refresh()
        end)
        row.reset:SetPoint("RIGHT", -1, 0)
        row.pick = button(row, 140, 32, L["Pick color"], function()
            pickColor(key, paletteColor)
        end)
        row.pick:SetPoint("RIGHT", row.reset, "LEFT", -8, 0)
        row.pick.title:ClearAllPoints()
        row.pick.title:SetPoint("LEFT", 30, 0)
        row.pick.title:SetPoint("RIGHT", -5, 0)
        row.swatch = texture(row.pick, "ARTWORK")
        row.swatch:SetSize(17, 17)
        row.swatch:SetPoint("LEFT", 9, 0)
        page.colors[key] = row
    end

    sectionTitle(page, 188, L["Scale"])
    page.scales = {}
    for index, spec in ipairs({
        { "barScale", L["Buff bar"], L["Resize the bar and its handle."], 0.75, 1.50 },
        { "wheelScale", L["Buff wheel"], L["Resize the wheel and its action slots."], 0.75, 1.50 },
        { "fontScale", L["Text size"], L["Resize text in AlwaysBuffed."], 0.85, 1.25 },
    }) do
        local key, title, detail, minimum, maximum = unpack(spec)
        local y = 218 + (index - 1) * 67
        line(page, 0, y, 0)
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", 0, -y - 1)
        row:SetSize(contentWidth, 65)
        settingsCopy(row, title, detail, 293)
        page.scales[key] = scaleSlider(row, key, minimum, maximum)
    end
    return page
end

local function buildProfilePicker(frame)
    local dismiss = CreateFrame("Button", nil, frame)
    dismiss:SetAllPoints()
    dismiss:SetFrameLevel(frame:GetFrameLevel() + 25)
    dismiss:SetScript("OnClick", function(self)
        self:Hide()
    end)
    dismiss:Hide()
    local menu = CreateFrame("Frame", nil, dismiss)
    menu:EnableMouse(true)
    menu:SetWidth(258)
    menu:SetFrameLevel(dismiss:GetFrameLevel() + 1)
    menu:SetPoint("TOPRIGHT", frame.profile, "BOTTOMRIGHT", 0, -5)
    fill(menu, "BACKGROUND", color.edge)
    local face = texture(menu, "BORDER", color.sidebar)
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.profileItems = {}
    frame.dismissMenu, frame.profileMenu = dismiss, menu
end

local function refreshProfile(frame)
    local profile = A.state.profile
    local mode = A.db.profile or "auto"
    frame.profile.title:SetText(mode == "auto" and L["Auto (%s)"]:format(profile.label) or profile.label)
    if not frame.dismissMenu:IsShown() then
        return
    end
    local choices = A.profiles[A.state.class] or {}
    for index = 1, #choices + 1 do
        local choice = choices[index - 1]
        local key = choice and choice.key or "auto"
        local item = frame.profileItems[index]
        if not item then
            item = button(frame.profileMenu, 246, 33, "", function(self)
                frame.dismissMenu:Hide()
                A.db.profile = self.key
                A.Update()
            end)
            item:SetPoint("TOPLEFT", 6, -6 - 37 * (index - 1))
            frame.profileItems[index] = item
        end
        item.key = key
        item.title:SetText(choice and choice.label or L["Auto (based on talents)"])
        selectButton(item, mode == key)
        item:Show()
    end
    for index = #choices + 2, #frame.profileItems do
        frame.profileItems[index]:Hide()
    end
    frame.profileMenu:SetHeight((#choices + 1) * 37 + 8)
end

local function setPanelSize(frame)
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if screenWidth < 1 or screenHeight < 1 then
        return
    end
    local usableHeight = math.max(1, screenHeight - 24)
    local scale = math.min(1, math.max(1, screenWidth - 24) / width, usableHeight / 430)
    frame:SetScale(scale)
    frame:SetSize(width, math.min(650, usableHeight / scale))
end

local function buildPanel()
    local frame = CreateFrame("Frame", "AlwaysBuffedOptionsPanel", UIParent)
    frame:Hide()
    frame:SetFrameStrata("DIALOG")
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    table.insert(UISpecialFrames, frame:GetName())
    fill(frame, "BACKGROUND", color.edge)
    local surface = texture(frame, "BORDER", color.panel)
    surface:SetPoint("TOPLEFT", 1, -1)
    surface:SetPoint("BOTTOMRIGHT", -1, 1)
    local side = texture(frame, "ARTWORK", color.sidebar)
    side:SetPoint("TOPLEFT", 1, -headerHeight)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(sidebarWidth - 1)
    local separator = texture(frame, "ARTWORK", color.line)
    separator:SetPoint("TOPLEFT", sidebarWidth, -headerHeight)
    separator:SetPoint("BOTTOMLEFT", sidebarWidth, 1)
    separator:SetWidth(1)
    line(frame, 1, headerHeight - 1, 1)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(headerHeight - 2)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local title = label(header, 29, color.text, "LEFT", true)
    title:SetPoint("LEFT", 20, 0)
    title:SetText(L["AlwaysBuffed"])
    local close = button(header, 70, 33, L["Close"], function()
        frame:Hide()
    end)
    close:SetPoint("RIGHT", -16, 0)
    local profileCaption = label(header, 14, color.muted, "RIGHT", true)
    frame.profile = button(header, 252, 33, "", function()
        stopCapture(frame)
        frame.category.search:ClearFocus()
        frame.dismissMenu:Show()
        A.RefreshOptions()
    end)
    frame.profile:SetPoint("RIGHT", close, "LEFT", -10, 0)
    frame.profile.hint = L["Choose the profile that ranks items and stores your buff preferences."]
    frame.profile.title:ClearAllPoints()
    frame.profile.title:SetPoint("LEFT", 8, 0)
    frame.profile.title:SetPoint("RIGHT", -24, 0)
    local arrowLeft = frame.profile:CreateLine(nil, "OVERLAY")
    tintTexture(arrowLeft, color.muted)
    arrowLeft:SetThickness(1.5)
    arrowLeft:SetStartPoint("RIGHT", frame.profile, -19, 2)
    arrowLeft:SetEndPoint("RIGHT", frame.profile, -15, -2)
    local arrowRight = frame.profile:CreateLine(nil, "OVERLAY")
    tintTexture(arrowRight, color.muted)
    arrowRight:SetThickness(1.5)
    arrowRight:SetStartPoint("RIGHT", frame.profile, -15, -2)
    arrowRight:SetEndPoint("RIGHT", frame.profile, -11, 2)
    profileCaption:SetPoint("RIGHT", frame.profile, "LEFT", -12, 0)
    profileCaption:SetText(L["Profile"])
    frame.keepTracked = button(header, 166, 33, L["Keep current item"], function()
        local pref = A.Prefs(activePage)
        A.SetTrackedItem(pref, pref.pin, A.state.categories[activePage])
        A.Update()
    end)
    frame.keepTracked:SetPoint("RIGHT", profileCaption, "LEFT", -18, 0)
    frame.keepTracked:Hide()

    buildSidebar(frame)
    frame.scroll, frame.body = scrollArea(frame, sidebarWidth + contentInset, headerHeight + 18, contentRight, 16)
    frame.heading = label(frame.body, 27, color.text, "LEFT", true)
    frame.subheading = label(frame.body, 15, color.muted, "LEFT", false, 2)
    frame.subheading:SetPoint("TOPLEFT", 0, -39)
    frame.subheading:SetWidth(contentWidth)
    frame.general = buildGeneral(frame)
    frame.professions = buildProfessions(frame)
    frame.appearance = buildAppearance(frame)
    frame.category = buildCategory(frame)
    frame.tableHeader = buildTableHeader(frame.body)
    frame.empty = label(frame.body, 15, color.muted, "LEFT", false, 2)
    frame.empty:SetPoint("TOPLEFT", 0, -85)
    frame.empty:SetWidth(contentWidth)
    frame.itemWidgets = {}

    frame.capture = CreateFrame("Frame", nil, frame)
    frame.capture:EnableKeyboard(false)
    frame.capture:SetScript("OnKeyDown", function(_, key)
        if not frame.bindingTarget or modifierKeys[key] then return end
        if key == "ESCAPE" then
            stopCapture(frame)
            A.RefreshOptions()
        else
            local binding = (IsAltKeyDown() and "ALT-" or "")
                .. (IsControlKeyDown() and "CTRL-" or "")
                .. (IsShiftKeyDown() and "SHIFT-" or "")
                .. key
            saveShortcut(frame, frame.bindingTarget, binding)
        end
    end)

    buildProfilePicker(frame)
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    frame:RegisterEvent("UI_SCALE_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UPDATE_BINDINGS")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            stopCapture(self)
            A.RefreshOptions()
        elseif event == "PLAYER_REGEN_ENABLED" or event == "UPDATE_BINDINGS" then
            A.RefreshOptions()
        elseif self:IsShown() then
            setPanelSize(self)
        end
    end)
    frame:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
        stopCapture(self)
        self.category.search:ClearFocus()
        self.dismissMenu:Hide()
        self.bindingError = nil
    end)
    setPanelSize(frame)
    return frame
end

local function renderGeneral(frame)
    frame.heading:SetText(L["General"])
    for key, control in pairs(frame.general.checks) do
        check(control, A.db[key])
    end
    local current = A.db.barDirection or (A.db.barOrientation == "vertical" and "down" or "right")
    for direction, control in pairs(frame.general.directions) do
        selectButton(control, direction == current)
    end
    paintShortcut(frame, frame.general.shortcut, L["buff wheel"], L["Also available in WoW Keybindings."])
    paintShortcut(frame, frame.general.barShortcut, L["buff bar"], L["Show or hide the buff bar."])
    frame.general.preview:SetEnabled(A.db.showWheel and not InCombatLockdown())
    return frame.general:GetHeight() + 58
end

local function renderAppearance(frame)
    frame.heading:SetText(L["Appearance"])
    local page = frame.appearance
    for key, row in pairs(page.colors) do
        local custom = A.db[key]
        local swatch = row.paletteColor
        row.swatch:SetColorTexture(swatch[1], swatch[2], swatch[3], 1)
        row.mode:SetText(custom and L["Custom color"] or row.defaultName)
        row.reset:SetEnabled(custom ~= nil)
    end
    for key, slider in pairs(page.scales) do
        slider:SetValue(tonumber(A.db[key]) or 1)
        slider.value:SetText(L["%d%%"]:format(math.floor(slider:GetValue() * 100 + 0.5)))
    end
    return page:GetHeight() + 58
end

local function renderProfessions(frame)
    local page = frame.professions
    frame.heading:SetText(L["Professions"])
    local mode = A.db.barMode or "auto"
    for key, control in pairs(page.modes) do
        selectButton(control, key == mode)
    end
    page.activeBar:SetText(L["Active bar: %s"]:format(A.BarModeLabel(A.state.barProfession)))
    return page:GetHeight() + 58
end

local function tableAt(frame, y, itemLabel, levelLabel, showPrice)
    local header = frame.tableHeader
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", 0, -y)
    header:SetPoint("TOPRIGHT", 0, -y)
    header.item:SetText(itemLabel)
    header.level:SetText(levelLabel)
    header.bags:SetText(L["In bags"])
    header.price:SetText(L["Auction price"])
    header.price:SetShown(showPrice)
    header:Show()
    return y + tableHeaderHeight
end

local function hasMarketItems(state)
    if state.buy then
        return true
    end
    for _, row in ipairs(state.rows) do
        if row.canBuy then
            return true
        end
    end
    return false
end

local function renderShopping(frame)
    frame.heading:SetText(L["Shopping list"])
    frame.subheading:SetText(L["Recommended buys by category. Unit prices come from Auctionator’s last scan."])
    local y, index = tableAt(frame, 74, L["Category / item"], "", true), 0
    for _, category in ipairs(A.categories) do
        local state = A.state.categories[category.key]
        if state and state.tracked and A.OnActiveBar(category) and A.CategoryForClass(category, A.state.class) and hasMarketItems(state) then
            index = index + 1
            renderRow(frame, index, y, category, state.buy, false, true, true)
            y = y + rowHeight
        end
    end
    if index == 0 then
        frame.tableHeader:Hide()
        frame.empty:SetText(L["Enable a category with auction items to see its recommendations here."])
    end
    return math.max(y + 6, 124), index
end

local function renderRankedItems(frame, category, rows, pref, y, hasMarket)
    local page = frame.category
    local typed = page.search:GetText() or ""
    local query = typed:match("^%s*(.-)%s*$")
    local searching = query ~= ""
    local buckets = { best = {}, utility = {}, notUseful = {} }
    local total = 0
    for _, row in ipairs(rows) do
        if (row.eligible or pref.showUnusable) and (not searching or A.MatchesItemSearch(row, query)) then
            local bucket = buckets[row.group]
            bucket[#bucket + 1] = row
            total = total + 1
        end
    end
    page.searchRow.clear:SetEnabled(typed ~= "")
    page.searchRow.count:SetText(searching and (total == 1 and L["%d result"] or L["%d results"]):format(total) or "")
    if total == 0 then
        for _, header in pairs(page.groupHeaders) do header:Hide() end
        frame.empty:ClearAllPoints()
        frame.empty:SetPoint("TOPLEFT", 0, -y - 12)
        if searching then
            frame.empty:SetText(pref.showUnusable and L["No items match your search."] or L["No usable items match your search."])
        else
            frame.empty:SetText(L["No usable items. Enable Show unusable items to browse this category."])
        end
        return y + 56, 0
    end

    y = tableAt(frame, y, L["Item"], category.kind == "reminder" and "" or L["Level"], hasMarket)
    local collapsed = page.collapsedGroups[category.key] or {}
    local used = 0
    for _, group in ipairs(rankingGroups) do
        local key = group[1]
        local header, bucket = page.groupHeaders[key], buckets[key]
        local expanded = not collapsed[key]
        header:SetShown(not searching or #bucket > 0)
        if header:IsShown() then
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 0, -y)
            header.count:SetText(tostring(#bucket))
            paintDisclosure(header, expanded)
            y = y + groupHeaderHeight
            if expanded then
                for rank, row in ipairs(bucket) do
                    used = used + 1
                    renderRow(frame, used, y, category, row, pref.pin == row.item.id, false, hasMarket, rank)
                    y = y + rowHeight
                end
            end
            y = y + 5
        end
    end
    return y + 6, used
end

local function renderCategory(frame, category)
    local page = frame.category
    local pref = A.Prefs(category.key)
    local state = A.state.categories[category.key] or { rows = {} }
    local upgrade = state.upgrade
    local pin = state.trackedItem
    local canKeep = pin ~= nil and pin.item.id == pref.pin and pin.eligible
        and upgrade ~= nil and pin.item.id ~= upgrade.item.id
    frame.keepTracked:SetShown(canKeep)
    if canKeep then
        frame.keepTracked.hint = L["Keep %s and dismiss upgrades available now."]:format(pin.name)
    end
    if frame.highlightItemID and (not upgrade or not upgrade.eligible or upgrade.item.id ~= frame.highlightItemID) then
        frame.highlightItemID = nil
    end
    frame.highlightRowY = nil
    frame.heading:SetText(category.label)
    local reminder = category.kind == "reminder"
    local enabled = tracked(category)
    local onActiveBar = not category.profession or A.OnActiveBar(category)
    local status = reminder and "" or activeText(state)
    if reminder and not A.db.reminders then
        status = L["Reminders are off. Enable this reminder to turn them on."]
    elseif not enabled then
        status = reminder and L["Reminder off for this profile"] or L["Category off for this profile"]
    elseif not onActiveBar then
        status = L["Shown on the %s bar."]:format(A.BarModeLabel(category.profession))
    elseif category.slot and #state.rows > 0 and state.applicable == false then
        if category.profession == "fishing" then
            status = L["Requires a fishing pole"]
        else
            status = category.slot == 17 and L["Equip a compatible off-hand weapon"] or L["Equip a compatible main-hand weapon"]
        end
    end
    frame.subheading:SetText(status)
    tintLabel(frame.subheading, enabled and onActiveBar and state.active and color.mint or color.muted)
    page.track.title:SetText(reminder and L["Enable reminder"] or L["Enable category"])
    if category.profession then
        page.track.hint = L["Show this category when its profession bar is active."]
    else
        page.track.hint = not A.db.reminders and reminder and L["Turn on reminders and enable this reminder for this profile."]
            or L["Show this buff on the bar and wheel for this profile."]
    end
    check(page.track, enabled)
    page.restore:SetShown(pref.enabled ~= nil)
    local shortcutStatus
    if not enabled then
        shortcutStatus = reminder and L["Enable this reminder to use its shortcut."] or L["Enable this category to use its shortcut."]
    elseif category.profession then
        shortcutStatus = L["Use this category’s selected item or spell while its profession bar is active."]
    else
        shortcutStatus = L["Use this category’s selected item or spell, even when the bar is hidden."]
    end
    paintShortcut(frame, page.shortcut, category.label, shortcutStatus)
    page.reminder:SetShown(reminder)
    local count = #state.rows
    local rankY = summaryY + (reminder and 102 or (count > 0 and 94 or 4))
    if reminder then
        page.reminder.category = category
        paintReminder(page.reminder, category, state, GetTime())
    end

    page.status:SetShown(not reminder and count > 0)
    page.searchRow:SetShown(count > 0)
    local hasMarket = hasMarketItems(state)
    page.cheap:SetShown(hasMarket)
    page.clear:SetShown(count > 0)
    check(page.cheap, pref.cheapest)
    check(page.showUnusable, pref.showUnusable == true)
    page.clear:SetEnabled(pref.pin ~= nil)

    page.rankTitle:ClearAllPoints()
    page.rankTitle:SetPoint("TOPLEFT", 0, -rankY - 4)
    page.rankTitle:SetText(category.key == "campfire" and L["Campfire kits"]
        or (category.key == "sleepingBag" and L["Sleeping bag"] or L["Item rankings"]))
    page.clear:ClearAllPoints()
    page.clear:SetPoint("TOPRIGHT", 0, -rankY)
    page.cheap:ClearAllPoints()
    page.cheap:SetPoint("RIGHT", page.clear, "LEFT", -12, 0)
    page.showUnusable:ClearAllPoints()
    if hasMarket then
        page.showUnusable:SetPoint("RIGHT", page.cheap, "LEFT", -8, 0)
    elseif count > 0 then
        page.showUnusable:SetPoint("RIGHT", page.clear, "LEFT", -12, 0)
    else
        page.showUnusable:SetPoint("TOPRIGHT", 0, -rankY)
    end
    page.rankTitle:SetPoint("TOPRIGHT", page.showUnusable, "TOPLEFT", -8, -4)
    page.searchRow:ClearAllPoints()
    page.searchRow:SetPoint("TOPLEFT", 0, -rankY - 40)

    if count == 0 then
        for _, header in pairs(page.groupHeaders) do header:Hide() end
        frame.empty:ClearAllPoints()
        frame.empty:SetPoint("TOPLEFT", 0, -rankY - 40)
        frame.empty:SetText(category.description or L["No matching items or spells for your class."])
        return rankY + 86, 0
    end

    local buy, bag = state.buy, state.bag
    local cells = page.status
    local showNextUnlock = not reminder and pref.showUnusable == true
    if cells[3]:IsShown() ~= showNextUnlock then
        local cellWidth = showNextUnlock and summaryCellWidth or contentWidth / 2
        cells[1]:SetWidth(cellWidth)
        cells[2]:SetWidth(cellWidth)
        cells[2]:ClearAllPoints()
        cells[2]:SetPoint("TOPLEFT", cellWidth, 0)
        cells[3]:SetShown(showNextUnlock)
    end
    local nextRow
    if showNextUnlock then
        for _, row in ipairs(state.rows) do
            if row.level and row.level > A.state.level and (not nextRow or row.level < nextRow.level) then
                nextRow = row
            end
        end
        cells[3].value:SetText(
            nextRow and L["Lv %d  ·  %s"]:format(nextRow.level, nextRow.name or nextRow.item.name) or L["All unlocked"]
        )
        cells[3].details:SetText(statText(nextRow, category, 1))
    end
    cells[1].itemRow, cells[2].itemRow, cells[3].itemRow = buy, bag, nextRow
    cells[1].caption:SetText(pin and buy == pin and L["Tracked item"] or L["Recommended buy"])
    cells[2].caption:SetText(pin and bag == pin and L["Selected in bags"] or L["Best in bags"])
    cells[1].value:SetText(buy and (buy.name or buy.item.name) or (hasMarket and L["None eligible"] or L["No auction items"]))
    tintLabel(cells[1].value, buy and color.mint or color.muted)
    if bag and bag.item.spell then
        cells[2].value:SetText(bag.name)
    else
        cells[2].value:SetText(bag and L["%s ×%d"]:format(bag.name or bag.item.name, bag.count) or L["None in bags"])
    end
    cells[1].details:SetText(statText(buy, category, 1))
    cells[2].details:SetText(statText(bag, category, 1))

    return renderRankedItems(frame, category, state.rows, pref, rankY + 80, hasMarket)
end

function A.RefreshOptions()
    if not panel or not panel:IsShown() or not A.state or not A.db then
        return
    end
    refreshSidebar(panel)
    local category = panel.categoryByKey[activePage]
    for _, nav in ipairs(panel.navigation) do
        paintNav(nav)
        if nav.category then
            local enabled = tracked(nav.category)
            check(nav.track, enabled)
            nav.track.hint = (enabled and L["Disable %s for this profile."] or L["Enable %s for this profile."]):format(navigationLabel(nav.category))
        end
    end
    refreshProfile(panel)
    panel.general:SetShown(activePage == "general")
    panel.appearance:SetShown(activePage == "appearance")
    panel.professions:SetShown(activePage == "professions")
    panel.category:SetShown(category ~= nil)
    if not category then panel.keepTracked:Hide() end
    panel.empty:ClearAllPoints()
    panel.empty:SetPoint("TOPLEFT", 0, -85)
    panel.empty:SetText("")
    panel.heading:ClearAllPoints()
    panel.heading:SetPoint("TOPLEFT")
    panel.heading:SetPoint("TOPRIGHT", category and -300 or -178, 0)
    panel.subheading:SetText("")
    tintLabel(panel.subheading, color.muted)
    panel.tableHeader:Hide()

    local height, used = 1, 0
    if category then
        height, used = renderCategory(panel, category)
    elseif activePage == "shopping" then
        height, used = renderShopping(panel)
    elseif activePage == "appearance" then
        height = renderAppearance(panel)
    elseif activePage == "professions" then
        height = renderProfessions(panel)
    else
        height = renderGeneral(panel)
    end
    for index = used + 1, #panel.itemWidgets do
        panel.itemWidgets[index]:Hide()
    end
    panel.body:SetHeight(height)
end

theme.OnChange(function()
    for tex, tint in pairs(textureColors) do
        tex:SetColorTexture(unpack(tint))
    end
    for tex, tint in pairs(vertexColors) do
        tex:SetVertexColor(unpack(tint))
    end
    for text, tint in pairs(textColors) do
        if textLines[text] then sizeLabel(text, textLines[text]) end
        text:SetTextColor(unpack(tint))
    end
    A.RefreshOptions()
end)

function A.ToggleOptions()
    if not A.state or not A.db then
        return
    end
    if not panel then
        panel = buildPanel()
    end
    if panel:IsShown() then
        panel:Hide()
    else
        setPanelSize(panel)
        panel:Show()
        A.RefreshOptions()
    end
end

function A.OpenCategory(key, upgradeItemID)
    if not A.state or not A.db then return end
    if not panel then panel = buildPanel() end
    if not panel.categoryByKey[key] then return end
    if not panel:IsShown() then
        setPanelSize(panel)
        panel:Show()
    end
    panel.dismissMenu:Hide()
    navigate(key, upgradeItemID)
end
