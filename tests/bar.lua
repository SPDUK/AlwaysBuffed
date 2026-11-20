-- Verify grip geometry across a collapse, resize, edge placement and a gear change.
local A = {
    state = { categories = {} },
    db = { showBar = true, barScale = 1, barX = -400, barY = -100 },
    categories = {},
}
local M, all = {}, {}
local locked, now, tick, cooldownReads = false, 1000, nil, 0
local bindings, overrides, opened, settings, wheel = {}, {}, {}, 0, 0
local shift = false
local secure = dofile("tests/secure-click.lua")
local function guard(frame, action, allowedInSnippet)
    assert(not locked or not frame.protected or (allowedInSnippet and secure.running),
        "protected " .. action .. " changed insecurely in combat on " .. (frame.name or "unnamed frame"))
end
function M:SetSize(w, h) guard(self, "size") self.w, self.h = w, h end
function M:SetWidth(w) guard(self, "width") self.w = w end
function M:SetHeight(h) guard(self, "height") self.h = h end
function M:GetWidth() return self.w or (self.allPoints and self.allPoints:GetWidth()) end
function M:GetHeight() return self.h or (self.allPoints and self.allPoints:GetHeight()) end
function M:SetScale(s) guard(self, "scale") self.scale = s end
function M:GetScale() return self.scale end
function M:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
function M:SetPoint(...)
    guard(self, "anchor")
    self.anchor = {...}
    self.allPoints = nil
    for i, existing in ipairs(self.points) do
        if existing[1] == self.anchor[1] then self.points[i] = self.anchor return end
    end
    self.points[#self.points + 1] = self.anchor
end
function M:ClearAllPoints() guard(self, "anchor") self.anchor, self.allPoints, self.points = nil, nil, {} end
function M:SetAllPoints(target)
    self:ClearAllPoints()
    self.allPoints = target or self.parent
end

local function fractions(point)
    local x = point:find("LEFT", 1, true) and 0 or point:find("RIGHT", 1, true) and 1 or 0.5
    local y = point:find("BOTTOM", 1, true) and 0 or point:find("TOP", 1, true) and 1 or 0.5
    return x, y
end

local function dimension(points, size)
    local first = points[1]
    if not first then return 0, size end
    for i = 2, #points do
        local point = points[i]
        if point[1] ~= first[1] then
            size = (point[2] - first[2]) / (point[1] - first[1])
            break
        end
    end
    return first[2] - first[1] * size, size
end

local function rect(frame)
    if frame == UIParent then return 0, 0, frame.w, frame.h end
    if frame.allPoints then return rect(frame.allPoints) end
    local scale = frame:GetEffectiveScale()
    local xPoints, yPoints = {}, {}
    for _, anchor in ipairs(frame.points) do
        local point, target, to, dx, dy = unpack(anchor)
        if type(target) ~= "table" then target, to, dx, dy = frame.parent, point, target, to end
        local x, y = fractions(point)
        local tx, ty = fractions(to or point)
        local left, bottom, w, h = rect(target)
        xPoints[#xPoints + 1] = {x, left + w * tx + (dx or 0) * scale}
        yPoints[#yPoints + 1] = {y, bottom + h * ty + (dy or 0) * scale}
    end
    local left, w = dimension(xPoints, (frame.w or (frame.text and frame:GetStringWidth()) or 0) * scale)
    local bottom, h = dimension(yPoints, (frame.h or 0) * scale)
    return left, bottom, w, h
end

function M:GetCenter()
    local x, y, w, h = rect(self)
    local scale = self:GetEffectiveScale()
    return (x + w / 2) / scale, (y + h / 2) / scale
end
function M:GetLeft() return self:GetCenter() - self.w / 2 end
function M:GetRight() return self:GetCenter() + self.w / 2 end
function M:GetTop() return select(2, self:GetCenter()) + self.h / 2 end
function M:SetScript(event, fn) self.scripts[event] = fn end
function M:RegisterEvent(event) self.events[event] = true end
function M:RegisterForClicks(...) guard(self, "click registration") self.clicks = {...} end
function M:SetShown(value) guard(self, "visibility", true) self.shown = value end
function M:Show() self:SetShown(true) end
function M:Hide() self:SetShown(false) end
function M:IsShown() return self.shown end
function M:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function M:IsMouseOver() return self.hovered end
function M:SetText(text) self.text = text end
function M:SetTextScale(scale) self.textScale = scale end
function M:GetStringWidth() return #(self.text or "") * 7 * (self.textScale or 1) end
function M:SetTexture(id) self.texture = id end
function M:SetAlpha(value) self.alpha = value end
function M:SetDesaturated(value) self.desaturated = value end
function M:SetAttribute(key, value) guard(self, "attribute", true) self[key] = value end
function M:GetAttribute(key) return self[key] end
M.SetFrameRef = secure.SetFrameRef
function M:SetColorTexture(r, g, b, a) self.paintAlpha = a or 1 end
function M:CreateTexture(_, layer, _, level)
    local region = CreateFrame("Texture", nil, self)
    region.layer, region.level = layer, level or 0
    return region
end
M.CreateFontString = M.CreateTexture
for name in ("SetTexCoord RegisterForDrag SetBlendMode SetVertexColor "
    .. "SetClampedToScreen SetFrameStrata SetTextColor SetJustifyH SetWordWrap EnableMouse"):gmatch("%S+") do
    M[name] = function() end
end
function CreateFrame(_, name, parent, template)
    local frame = setmetatable({name = name, template = template, scripts = {}, events = {}, points = {}, scale = 1,
        parent = parent, shown = true}, {__index = M})
    if template and template:find("Secure", 1, true) then
        assert(not locked, "protected frame created in combat")
        local ancestor = frame
        while ancestor and ancestor ~= UIParent do
            ancestor.protected = true
            ancestor = ancestor.parent
        end
    end
    if name then _G[name] = frame end
    all[#all + 1] = frame
    return frame
end
function GetTime() return now end
function IsShiftKeyDown() return shift end
function InCombatLockdown() return locked end
C_Timer = {NewTicker = function(_, callback) tick = callback end}
C_Container = {GetItemCooldown = function(id)
    assert(id == 211527)
    cooldownReads = cooldownReads + 1
    return 800, 10800, 1
end}
GameTooltip = {IsOwned = function() return false end}
UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1000, 600)
local tint = { 1, 1, 1 }
A.theme = {colors = setmetatable({}, {__index = function() return tint end}), Font = function() end, OnChange = function() end}
A.RefreshOptions = function() end
A.OpenCategory = function(key, id) opened[#opened + 1] = {key, id} end
A.ToggleOptions = function() settings = settings + 1 end
A.ToggleWheel = function() wheel = wheel + 1 end
local function dispatch(event)
    for _, f in ipairs(all) do
        if f.events[event] then f.scripts.OnEvent(f, event) end
    end
end
function GetCurrentBindingSet() return 2 end
function SaveBindings(set) assert(set == 2 and not locked) end
function GetBindingKey(command)
    local keys = {}
    for chord, action in pairs(bindings) do
        if action == command then keys[#keys + 1] = chord end
    end
    table.sort(keys)
    return unpack(keys)
end
function GetBindingAction(chord, withOverrides)
    return withOverrides and overrides[chord] or bindings[chord] or ""
end
function SetBinding(chord, command)
    assert(not locked, "native binding changed during combat")
    bindings[chord] = command
    dispatch("UPDATE_BINDINGS")
    return true
end
function ClearOverrideBindings()
    assert(not locked, "binding overrides cleared during combat")
    overrides = {}
end
function SetOverrideBindingClick(_, _, chord, target, button)
    assert(not locked, "binding override changed during combat")
    overrides[chord] = "CLICK " .. target .. ":" .. (button or "LeftButton")
end
for i = 1, 6 do
    local cat = { key = "category" .. i, label = "Buff " .. i, kind = "item", slot = i == 2 and 17 or nil }
    A.categories[i] = cat
    A.state.categories[cat.key] = { rows = {}, tracked = true, active = i == 1 and "Active" or nil }
end
for _, key in ipairs({"campfire", "sleepingBag"}) do
    A.categories[#A.categories + 1] = {key = key, kind = "reminder", icon = key == "campfire" and 7808144 or 133662,
        label = key == "campfire" and "Campfire" or "Cozy Sleeping Bag"}
    A.state.categories[key] = {rows = {}, tracked = false}
end
A.categories[#A.categories + 1] = {key = "fishingLure", label = "Fishing Lure", kind = "weapon", slot = 16, profession = "fishing"}
A.categories[#A.categories + 1] = {key = "fishingFood", label = "Fishing Food", kind = "food", profession = "fishing"}
assert(loadfile("AlwaysBuffed/Locale.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Categories.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Status.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/BuffBindings.lua"))("AlwaysBuffed", A)
A.InitActions()
local bar, grip = AlwaysBuffedBar, AlwaysBuffedBarFold
local tray
for _, f in ipairs(all) do
    if f.category then tray = f.parent end
end
local function toggle() secure.press(grip, "LeftButton", false) end
local function pressBinding(chord, down)
    local name, button = GetBindingAction(chord, true):match("^CLICK ([^:]+):(.+)$")
    assert(name and _G[name], "native binding must reach an initialized protected button")
    shift = chord:find("SHIFT-", 1, true) ~= nil
    secure.press(_G[name], button, down)
    shift = false
end
local x, y = bar:GetCenter()
local w, h = bar.w, bar.h
local icon = grip.icon
assert(tray.shown and icon and icon.shown and tray.anchor[1] == "TOPLEFT")
toggle()
assert(not tray.shown and icon.shown and bar.w == w and bar.h == h and not grip.missingGlow.shown)
assert(bar:GetCenter() == x and select(2, bar:GetCenter()) == y)
A.db.highlightMissing = true
A.RefreshActions()
assert(grip.missingGlow.shown and tonumber(grip.missingText.text) == 5)
A.state.categories.category2.applicable = false
A.RefreshActions()
assert(tonumber(grip.missingText.text) == 4)
assert(A.SetBarToggleBinding("SHIFT-F7"))
local preparedAnchor = tray.anchor
locked = true
toggle()
assert(not A.db.collapsed and tray.shown, "a physical click must expand immediately during combat")
assert(not grip.missingText.shown and not grip.missingGlow.shown)
assert(tray.anchor == preparedAnchor and not AlwaysBuffedAction_category2:IsVisible())
toggle()
assert(A.db.collapsed and not tray.shown and grip.missingText.text == "4" and grip.activeText.text == "1")
pressBinding("SHIFT-F7", true)
assert(not A.db.collapsed and tray.shown and settings == 0, "Shift binding expands without opening settings")
pressBinding("SHIFT-F7", false)
assert(not A.db.collapsed and tray.shown, "key release does not toggle a second time")
pressBinding("SHIFT-F7", true)
assert(A.db.collapsed and not tray.shown and grip.missingGlow.shown)
shift = true
toggle()
shift = false
assert(A.db.collapsed and not tray.shown and settings == 1, "physical shift-click preserves the settings gesture")
secure.press(grip, "RightButton", false)
assert(A.db.collapsed and wheel == 1, "right-click keeps its own wheel gesture")
pressBinding("SHIFT-F7", true)
assert(not A.db.collapsed and tray.shown)
locked = false
dispatch("PLAYER_REGEN_ENABLED")
assert(not A.db.collapsed and tray.shown and bar:GetCenter() == x and not grip.missingGlow.shown)
-- Saved position is the grip center. A near-right-edge bar must unfold to the left.
A.db.barAnchorX, A.db.barScale = 460, 1.25
A.db.barDirection, A.db.barOrientation = nil, "horizontal"
for _, state in pairs(A.state.categories) do state.tracked = false end
A.RefreshActions()
assert(A.db.barOrientation == "horizontal" and A.db.barDirection == nil, "empty layouts leave legacy growth pending")
for i = 1, 6 do A.state.categories["category" .. i].tracked = true end
A.RefreshActions()
assert(A.db.barDirection == "left" and A.db.barOrientation == nil, "legacy horizontal saves preserve their chosen side")
assert(tray.anchor[1] == "TOPRIGHT" and bar:GetCenter() * 1.25 == 960)
A.db.barDirection = "right"
A.RefreshActions()
assert(tray.anchor[1] == "TOPRIGHT" and A.db.barDirection == "right", "an edge fallback keeps the preference")
toggle()
toggle()
assert(tray.anchor[1] == "TOPRIGHT" and bar:GetCenter() * 1.25 == 960)
local first, second = AlwaysBuffedAction_category1, AlwaysBuffedAction_category2
assert(first.activeBorder.shown and not second.activeBorder.shown)
A.state.categories.category1.active = nil
A.state.categories.category2.applicable, A.state.categories.category2.active = true, "Test buff"
A.RefreshActions()
assert(not first.activeBorder.shown and second.activeBorder.shown)
-- Center the grip and leave enough room for all categories in a single column.
A.db.barAnchorX, A.db.barAnchorY, A.db.barScale = 0, 210, 1
A.db.barDirection = "down"
A.RefreshActions()
assert(tray.anchor[1] == "TOPLEFT" and tray.anchor[3] == "BOTTOMLEFT")
assert(first.anchor[4] == second.anchor[4] and first.anchor[5] > second.anchor[5])
local verticalX, verticalY = bar:GetCenter()
toggle()
toggle()
assert(bar:GetCenter() == verticalX and select(2, bar:GetCenter()) == verticalY)

local function near(a, b) return math.abs(a - b) < 0.01 end
local function center(frame)
    local left, bottom, width, height = rect(frame)
    return left + width / 2, bottom + height / 2
end

local function assertOutline(expanded)
    local outline = expanded and tray.outline or bar.outline
    assert(outline and outline:IsVisible(), "the exterior frame is visible in both states")
    local x, y, w, h = rect(bar)
    local left, bottom, right, top = x, y, x + w, y + h
    if expanded then
        local tx, ty, tw, th = rect(tray)
        left, bottom = math.min(left, tx), math.min(bottom, ty)
        right, top = math.max(right, tx + tw), math.max(top, ty + th)
    end
    local ox, oy, ow, oh = rect(outline)
    assert(near(ox, left) and near(oy, bottom) and near(ox + ow, right) and near(oy + oh, top),
        "painted exterior matches the visible handle and tray bounds")
    assert(ox >= -0.01 and oy >= -0.01 and ox + ow <= 1000.01 and oy + oh <= 600.01,
        "the exterior stays inside the viewport in the edge and wrap cases")
    local fill
    for _, child in ipairs(all) do
        if #child.points == 2 and child.points[1][2] == outline and child.points[2][2] == outline then
            fill = child
            break
        end
    end
    assert(fill, "one continuous panel fills the exterior")
    local px, py, pw, ph = rect(fill)
    local scale = bar:GetScale()
    assert(near(px, ox + scale) and near(py, oy + scale) and near(pw, ow - 2 * scale) and near(ph, oh - 2 * scale))
end

local function setLayout(direction, scale, x, y)
    if A.db.barScale == scale then
        A.db.barScale = scale - 0.01
        A.RefreshActions()
    end
    A.db.barDirection, A.db.barScale = direction, scale
    A.db.barAnchorX, A.db.barAnchorY = x, y
    A.RefreshActions()
end

local function assertPitch(direction, scale, wrapped)
    local gripX, gripY = center(grip.icon)
    local horizontal = direction == "left" or direction == "right"
    local step = (direction == "left" or direction == "down") and -1 or 1
    local gripAlong, gripAcross = gripY, gripX
    if horizontal then gripAlong, gripAcross = gripX, gripY end
    local bands = {}
    for _, button in ipairs(all) do
        if button.category and button:IsVisible() then
            local x, y = center(button)
            local along, across = y, x
            if horizontal then along, across = x, y end
            local key = math.floor(across * 100 + 0.5)
            bands[key] = bands[key] or {}
            table.insert(bands[key], along)
            if button == first then
                assert(near(across, gripAcross) and near(along, gripAlong + step * 44 * scale),
                    "the first tracked buff is adjacent to the grip in the selected direction")
            end
        end
    end
    local crossPositions = {}
    for cross, band in pairs(bands) do
        table.insert(crossPositions, cross / 100)
        table.sort(band)
        for i = 2, #band do assert(near(band[i] - band[i - 1], 44 * scale), "constant pitch between adjacent tiles") end
    end
    assert((#crossPositions > 1) == wrapped, "layout wraps only when expected")
    table.sort(crossPositions)
    for i = 2, #crossPositions do assert(near(crossPositions[i] - crossPositions[i - 1], 44 * scale)) end
end

for _, scenario in ipairs({{"right", -450, 0}, {"left", 450, 0},
    {"down", 0, 220}, {"up", 0, -220}}) do
    local direction, xOffset, yOffset = unpack(scenario)
    for _, scale in ipairs({0.75, 1, 1.50}) do
        setLayout(direction, scale, xOffset, yOffset)
        local gripX, gripY, gripW, gripH = rect(grip.icon)
        local _, _, actionW, actionH = rect(first.icon)
        local _, _, handleW, handleH = rect(bar)
        assert(near(handleW, 48 * scale) and near(handleH, 48 * scale))
        assert(near(gripW, actionW) and near(gripH, actionH) and near(gripW, 34 * scale))
        local cx, cy = center(bar)
        assert(near(cx, 500 + xOffset) and near(cy, 300 + yOffset))
        assert(near(gripX + gripW / 2, cx) and near(gripY + gripH / 2, cy))
        assert(tray.shown and not grip.missingText.backing.shown and not grip.activeText.backing.shown)
        assertOutline(true)
        assertPitch(direction, scale, false)
        toggle()
        assert(not tray.shown and grip.icon.shown and grip.missingText.backing.shown and grip.activeText.backing.shown)
        assertOutline(false)
        local foldedX, foldedY, foldedW, foldedH = rect(grip.icon)
        assert(near(foldedX, gripX) and near(foldedY, gripY) and near(foldedW, gripW) and near(foldedH, gripH))
        for _, region in ipairs(all) do
            if region.parent == grip and region.shown and region.layer == "ARTWORK"
                and region.level > grip.icon.level and (region.paintAlpha or 0) > 0.8 then
                local x, y, w, h = rect(region)
                assert(x + w <= cx or x >= cx or y + h <= gripY or y >= gripY + gripH,
                    "collapsed counters must leave the artwork visible down the center")
            end
        end
        toggle()
    end
end

A.state.categories.campfire.tracked, A.state.categories.sleepingBag.tracked = true, true
-- The preferred edge fits one tile per row, but there is room for only four rows.
setLayout("right", 1.5, 390, 0)
assert(A.db.barDirection == "right", "overflow keeps the selected growth direction")
assertOutline(true)
assertPitch("left", 1.5, false)
setLayout("right", 1.5, 20, -8)
local fixedAnchor = bar.anchor
for _, direction in ipairs({"right", "left", "down", "up"}) do
    A.db.barDirection = direction
    A.RefreshActions()
    assert(bar.anchor == fixedAnchor, "direction changes keep the grip at the saved anchor")
    assertOutline(true)
    assertPitch(direction, 1.5, true)
end
A.state.categories.campfire.tracked, A.state.categories.sleepingBag.tracked = false, false
setLayout("down", 1, 0, 210)

A.db.mouseoverOnly = true
A.RefreshActions()
assert(bar.alpha == 0 and bar.scripts.OnUpdate)
tray.hovered = true
bar.scripts.OnUpdate()
assert(bar.alpha == 1)
tray.hovered = nil
bar.scripts.OnUpdate()
assert(bar.alpha == 0)
bar.hovered = true
bar.scripts.OnUpdate()
assert(bar.alpha == 1)
bar.hovered, grip.dragX = nil, 20
bar.scripts.OnUpdate()
assert(bar.alpha == 1)
grip.dragX = nil
A.db.mouseoverOnly = false
A.RefreshActions()
assert(bar.alpha == 1 and not bar.scripts.OnUpdate)

local sleep, camp = AlwaysBuffedAction_sleepingBag, AlwaysBuffedAction_campfire
local resting, camping = A.state.categories.sleepingBag, A.state.categories.campfire
resting.tracked, resting.bag = true, {item = {id = 211527, name = "Cozy Sleeping Bag"}, count = 1, icon = 17}
resting.active, resting.expires, resting.activeIcon, resting.activeStacks = "Well-Rested ×3", now + 7199, 90, 3
camping.tracked, camping.active, camping.activeIcon = true, "Camp Benefits", 35
camping.expires, camping.violetCamp = now + 6120, true
camping.bag = {item = {id = 279974, name = "Expert Campfire Kit"}, count = 1, icon = 22}
A.RefreshActions()
assert(sleep.w == first.w and camp.w == sleep.h and camp.h == sleep.w and sleep.anchor[5] < camp.anchor[5])
assert(tray.w == sleep.w + 8 and not sleep.nameText and not camp.nameText)
assert(sleep.timeText.anchor[1] == "CENTER" and sleep.countText.anchor[1] == "BOTTOMLEFT")
assert(sleep.activeBorder.shown and sleep.countText.text == "3" and sleep.timeText.text == "2h")
assert(sleep.icon.texture == 90 and cooldownReads == 0)
assert(camp.activeBorder.shown and camp.icon.texture == 35 and camp.countText.text == "" and camp.timeText.text == "2h")
resting.activeStacks = 1
tick()
assert(sleep.countText.text == "" and cooldownReads == 0)
local actionID = sleep.actionID
locked, now = true, now + 7201
tick()
assert(not sleep.activeBorder.shown and sleep.countText.text == "" and sleep.timeText.text == "57m")
assert(sleep.icon.texture == 17 and cooldownReads == 1 and sleep.actionID == actionID)
assert(not camp.activeBorder.shown and camp.timeText.text == "" and camp.icon.texture == camp.category.icon)
assert(camp.icon.desaturated and camp.icon.alpha == 0.8 and camp["*type1"] == "item" and camp["*item1"] == "item:279974")
camping.pending, camping.pendingExpires, camping.pendingIcon = "Welcoming Campfire", now + 30, 18
tick()
assert(not camp.activeBorder.shown and camp.icon.texture == camp.category.icon and camp.timeText.text == "")
locked = false
A.db.barAnchorY, A.db.barScale = -190, 0.95
A.db.barDirection, A.db.barOrientation = nil, "vertical"
A.RefreshActions()
assert(A.db.barDirection == "up" and A.db.barOrientation == nil, "legacy vertical saves preserve their chosen side")
assert(tray.anchor[1] == "BOTTOMLEFT" and tray.anchor[3] == "TOPLEFT")
assert(first.anchor[5] < second.anchor[5] and camp.anchor[5] < sleep.anchor[5], "upward opening grows away from the grip")
A.db.barDirection = "right"
A.RefreshActions()
assert(sleep.w == camp.w and sleep.w == first.w and sleep.h == first.h)
camping.bag = nil
A.RefreshActions()
assert(camp.icon.desaturated and camp.icon.alpha < 0.8 and not camp["*item1"])
-- A right-click inspects the current recommendation without touching the secure use action.
local stock = {item = {id = 3664}, name = "Crocolisk Gumbo", count = 19, icon = 11}
local newer = {item = {id = 20074}, name = "Heavy Crocolisk Stew", count = 0, icon = 12}
local entry = A.state.categories.category1
entry.bag, entry.upgrade = stock, newer
SetBinding("CTRL-1", "ALWAYSBUFFED_USE_CATEGORY1")
SetBinding("F1", "ALWAYSBUFFED_USE_CATEGORY2")
A.RefreshActions()
assert(first.upgradeMark:IsShown() and first["*item1"] == "item:3664" and not first["*type2"])
assert(first.clicks[2] == "RightButtonUp" and first.countText.text == "19")
assert(first.countText.anchor[1] == "BOTTOMLEFT" and first.timeText.anchor[1] == "CENTER")
assert(second.handText.anchor[1] == "BOTTOMRIGHT" and second.handText.text == "OH")
assert(not first.bindingText and not second.bindingText, "chords stay out of the HUD")
first.scripts.PostClick(first, "LeftButton")
assert(#opened == 0)
first.scripts.PostClick(first, "RightButton")
assert(#opened == 1 and opened[1][1] == "category1" and opened[1][2] == 20074)
entry.upgrade = nil
A.RefreshActions()
assert(not first.upgradeMark:IsShown())
first.scripts.PostClick(first, "RightButton")
assert(#opened == 2 and opened[2][2] == nil)
SetBinding("CTRL-1")
A.RefreshActions()
assert(first.countText.anchor[1] == "BOTTOMLEFT", "the count stays in place when unbound")
A.db.mouseoverOnly, A.db.collapsed = true, true
A.RefreshActions()
assert(not tray.shown and bar.alpha == 0)
locked = true
pressBinding("SHIFT-F7", true)
assert(tray.shown and bar.alpha == 1)
bar.scripts.OnUpdate()
assert(bar.alpha == 1, "shortcut expansion is visible before the cursor reaches the bar")
tray.hovered = true
bar.scripts.OnUpdate()
tray.hovered = false
bar.scripts.OnUpdate()
assert(bar.alpha == 0)

-- Combat toggles reuse the already prepared secure tray and do not apply a new loadout.
local previousTrayAnchor, previousFirstAnchor = tray.anchor, first.anchor
entry.bag = {item = {id = 20074}, count = 2, icon = 12}
A.state.categories.category2.applicable = false
A.db.barDirection, A.db.barScale = "up", 1.25
A.RefreshActions()
assert(first["*item1"] == "item:3664" and first.icon.texture == 11 and second:IsVisible())
assert(tray.anchor == previousTrayAnchor and first.anchor == previousFirstAnchor and bar:GetScale() == 0.95)
pressBinding("SHIFT-F7", true)
assert(A.db.collapsed and not tray.shown and grip.missingText.shown)
assertOutline(false)
pressBinding("SHIFT-F7", true)
assert(not A.db.collapsed and tray.shown and not grip.missingText.shown and bar.alpha == 1)
assert(first["*item1"] == "item:3664" and second:IsVisible() and tray.anchor == previousTrayAnchor)
assertOutline(true)
locked = false
dispatch("PLAYER_REGEN_ENABLED")
A.RefreshActions() -- Core refreshes the fully planned loadout after regen.
assert(not A.db.collapsed and tray.shown and bar:GetScale() == 1.25)
assert(first["*item1"] == "item:20074" and first.icon.texture == 12 and not second:IsVisible())
assert(tray.anchor ~= previousTrayAnchor)

-- Native shortcut stays available even when the HUD itself is hidden.
A.db.showBar = false
A.RefreshActions()
assert(not bar:IsVisible())
locked = true
pressBinding("SHIFT-F7", false)
assert(not bar:IsVisible())
pressBinding("SHIFT-F7", true)
assert(A.db.showBar and not A.db.collapsed and bar:IsVisible() and tray:IsVisible() and bar.alpha == 1)
AlwaysBuffed_ToggleBar()
assert(A.db.collapsed and tray:IsVisible(), "legacy scripted toggles defer protected changes in combat")
locked = false
A.RefreshActions()
assert(not tray:IsVisible())
AlwaysBuffed_ToggleBar()
assert(not A.db.collapsed and tray:IsVisible(), "legacy scripted toggles apply immediately outside combat")
local lure, fishingFood = AlwaysBuffedAction_fishingLure, AlwaysBuffedAction_fishingFood
local gripAnchor, liveScale = bar.anchor, bar:GetScale()
A.state.categories.fishingLure = {tracked = true, bag = {item = {id = 6532}, count = 1, icon = 28}}
A.state.categories.fishingFood = {tracked = true, bag = {item = {id = 33867}, count = 1, icon = 29}}
A.RefreshActions()
assert(not lure:IsVisible() and not lure["*item1"], "combat loadout excludes and disarms the lure")
A.db.collapsed = true
A.state.barProfession = "fishing"
A.RefreshActions()
assert(bar.anchor == gripAnchor and bar:GetScale() == liveScale and A.db.barDirection == "up")
assert(grip.missingText.text == "2" and grip.activeText.text == "0", "folded grip counts only the selected profession")
assert(not first:IsVisible() and not first["*item1"], "switching disarms the previous tray")
locked = true
toggle()
assert(lure:IsVisible() and fishingFood:IsVisible() and not first:IsVisible())
assert(lure["*item1"] == "item:6532" and lure["*target-slot1"] == 16, "the secure toggle opens the prepared fishing loadout")
toggle()
assert(grip.missingText.text == "2" and not lure:IsVisible())
locked = false
A.state.barProfession = nil
A.RefreshActions()
toggle()
assert(first:IsVisible() and first["*item1"] == "item:20074" and not lure:IsVisible() and not lure["*item1"])
assert(bar.anchor == gripAnchor and bar:GetScale() == liveScale and A.db.barDirection == "up")
A.state.barProfession = "herbalism"
A.RefreshActions()
assert(bar:IsVisible() and not tray:IsShown() and not first:IsShown() and not first["*item1"],
    "an empty profession keeps the grip and clears the previous actions")
toggle()
toggle()
assert(bar:IsVisible() and not tray:IsShown(), "the secure toggle cannot reveal a previous loadout on an empty bar")
print("Buff bar passed: secure combat clicks and key routing, deferred loadout, stable geometry, hover and aura timers.")
