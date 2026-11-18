-- Verify grip geometry across a collapse, resize, edge placement and a gear change.
local A = {
    state = { categories = {} },
    db = { showBar = true, barScale = 1, barX = -400, barY = -100 },
    categories = {},
}
local M, all = {}, {}
local locked, now, tick, cooldownReads = false, 1000, nil, 0
local bindings, opened = {}, {}
function M:SetSize(w, h) self.w, self.h = w, h end
function M:SetWidth(w) self.w = w end
function M:GetWidth() return self.w or (self.allPoints and self.allPoints:GetWidth()) end
function M:GetHeight() return self.h or (self.allPoints and self.allPoints:GetHeight()) end
function M:SetScale(s) self.scale = s end
function M:GetScale() return self.scale end
function M:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
function M:SetPoint(...)
    self.anchor = {...}
    self.allPoints = nil
    for i, existing in ipairs(self.points) do
        if existing[1] == self.anchor[1] then self.points[i] = self.anchor return end
    end
    self.points[#self.points + 1] = self.anchor
end
function M:ClearAllPoints() self.anchor, self.allPoints, self.points = nil, nil, {} end
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
    local left, w = dimension(xPoints, (frame.w or 0) * scale)
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
function M:RegisterForClicks(...) self.clicks = {...} end
function M:SetShown(value) self.shown = value end
function M:Show() self.shown = true end
function M:Hide() self.shown = false end
function M:IsShown() return self.shown end
function M:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function M:IsMouseOver() return self.hovered end
function M:SetText(text) self.text = text end
function M:SetTextScale(scale) self.textScale = scale end
function M:GetStringWidth() return #(self.text or "") * 7 * (self.textScale or 1) end
function M:SetTexture(id) self.texture = id end
function M:SetAlpha(value) self.alpha = value end
function M:SetDesaturated(value) self.desaturated = value end
function M:SetAttribute(key, value) self[key] = value end
function M:CreateTexture() return CreateFrame("Texture", nil, self) end
M.CreateFontString = M.CreateTexture
for name in ("SetTexCoord RegisterForDrag SetBlendMode SetVertexColor "
    .. "SetClampedToScreen SetFrameStrata SetColorTexture SetTextColor SetJustifyH SetWordWrap "
    .. "SetHeight"):gmatch("%S+") do M[name] = function() end end
function CreateFrame(_, name, parent)
    local frame = setmetatable({scripts = {}, events = {}, points = {}, scale = 1, parent = parent, shown = true}, {__index = M})
    if name then _G[name] = frame end
    all[#all + 1] = frame
    return frame
end
function GetTime() return now end
function IsShiftKeyDown() return false end
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
A.InitBuffBindings = function() end
A.RefreshBuffBindings = function() end
A.GetBuffBinding = function(key) return bindings[key] end
A.OpenCategory = function(key, id) opened[#opened + 1] = {key, id} end
local function dispatch(event)
    for _, f in ipairs(all) do
        if f.events[event] then f.scripts.OnEvent(f, event) end
    end
end
for i = 1, 6 do
    local cat = { key = "category" .. i, kind = "item", slot = i == 2 and 17 or nil }
    A.categories[i] = cat
    A.state.categories[cat.key] = { rows = {}, tracked = true, active = i == 1 and "Active" or nil }
end
for _, key in ipairs({"campfire", "sleepingBag"}) do
    A.categories[#A.categories + 1] = {key = key, kind = "reminder", icon = key == "campfire" and 7808144 or 133662,
        label = key == "campfire" and "Campfire" or "Cozy Sleeping Bag"}
    A.state.categories[key] = {rows = {}, tracked = false}
end
assert(loadfile("AlwaysBuffed/Status.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)
A.InitActions()
local bar, grip = AlwaysBuffedBar, AlwaysBuffedBarFold
local tray
for _, f in ipairs(all) do
    if f.category then tray = f.parent end
end
local function toggle() grip.scripts.OnClick(grip, "LeftButton") end
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
locked = true
toggle()
assert(A.db.collapsed and not tray.shown)
locked = false
dispatch("PLAYER_REGEN_ENABLED")
assert(tray.shown and bar:GetCenter() == x and not grip.missingGlow.shown)
-- Saved position is the grip center. A near-right-edge bar must unfold to the left.
A.db.barAnchorX, A.db.barScale = 460, 1.25
A.RefreshActions()
assert(tray.anchor[1] == "TOPRIGHT" and bar:GetCenter() * 1.25 == 960)
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
A.db.barOrientation = "vertical"
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
    assert(bar.outline, "both states share an exterior outline")
    local x, y, w, h = rect(bar)
    local left, bottom, right, top = x, y, x + w, y + h
    if expanded then
        local tx, ty, tw, th = rect(tray)
        left, bottom = math.min(left, tx), math.min(bottom, ty)
        right, top = math.max(right, tx + tw), math.max(top, ty + th)
    end
    local ox, oy, ow, oh = rect(bar.outline)
    assert(near(ox, left) and near(oy, bottom) and near(ox + ow, right) and near(oy + oh, top),
        "painted exterior matches the visible handle and tray bounds")
    assert(ox >= -0.01 and oy >= -0.01 and ox + ow <= 1000.01 and oy + oh <= 600.01,
        "the exterior stays inside the viewport in the edge and wrap cases")
    local fill
    for _, child in ipairs(all) do
        if #child.points == 2 and child.points[1][2] == bar.outline and child.points[2][2] == bar.outline then
            fill = child
            break
        end
    end
    assert(fill, "one continuous panel fills the exterior")
    local px, py, pw, ph = rect(fill)
    local scale = bar:GetScale()
    assert(near(px, ox + scale) and near(py, oy + scale) and near(pw, ow - 2 * scale) and near(ph, oh - 2 * scale))
end

local function setLayout(orientation, scale, x, y)
    if A.db.barScale == scale then
        A.db.barScale = scale - 0.01
        A.RefreshActions()
    end
    A.db.barOrientation, A.db.barScale = orientation, scale
    A.db.barAnchorX, A.db.barAnchorY = x, y
    A.RefreshActions()
end

local function assertPitch(orientation, scale, direction, wrapped)
    local gripX, gripY = center(grip.icon)
    local horizontal = orientation == "horizontal"
    local gripAlong, gripAcross = gripY, gripX
    if horizontal then gripAlong, gripAcross = gripX, gripY end
    local bands, adjacent = {}, false
    for _, button in ipairs(all) do
        if button.category and button:IsVisible() then
            local x, y = center(button)
            local along, across = y, x
            if horizontal then along, across = x, y end
            local key = math.floor(across * 100 + 0.5)
            bands[key] = bands[key] or {}
            table.insert(bands[key], along)
            if near(across, gripAcross) and near(along, gripAlong + direction * 44 * scale) then adjacent = true end
        end
    end
    assert(adjacent, "the first row or column continues the handle pitch")
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

for _, scenario in ipairs({{"horizontal", -450, 0, 1}, {"horizontal", 450, 0, -1},
    {"vertical", 0, 220, -1}, {"vertical", 0, -220, 1}}) do
    local orientation, xOffset, yOffset, direction = unpack(scenario)
    for _, scale in ipairs({0.75, 1, 1.50}) do
        setLayout(orientation, scale, xOffset, yOffset)
        local gripX, gripY, gripW, gripH = rect(grip.icon)
        local _, _, actionW, actionH = rect(first.icon)
        local _, _, handleW, handleH = rect(bar)
        assert(near(handleW, 48 * scale) and near(handleH, 48 * scale))
        assert(near(gripW, actionW) and near(gripH, actionH) and near(gripW, 34 * scale))
        local cx, cy = center(bar)
        assert(near(cx, 500 + xOffset) and near(cy, 300 + yOffset))
        assert(near(gripX + gripW / 2, cx) and near(gripY + gripH / 2, cy))
        assert(tray.shown and not grip.countBackdrop.shown)
        assertOutline(true)
        assertPitch(orientation, scale, direction, false)
        toggle()
        assert(not tray.shown and grip.icon.shown and grip.countBackdrop.shown)
        assertOutline(false)
        local foldedX, foldedY, foldedW, foldedH = rect(grip.icon)
        assert(near(foldedX, gripX) and near(foldedY, gripY) and near(foldedW, gripW) and near(foldedH, gripH))
        toggle()
    end
end

A.state.categories.campfire.tracked, A.state.categories.sleepingBag.tracked = true, true
setLayout("horizontal", 1.5, 0, 0)
assertOutline(true)
assertPitch("horizontal", 1.5, 1, true)
setLayout("horizontal", 1.5, 20, 0)
assertOutline(true)
assertPitch("horizontal", 1.5, -1, true)
setLayout("vertical", 1.5, 0, 0)
assertOutline(true)
assertPitch("vertical", 1.5, -1, true)
setLayout("vertical", 1.5, 0, -8)
assertOutline(true)
assertPitch("vertical", 1.5, 1, true)
A.state.categories.campfire.tracked, A.state.categories.sleepingBag.tracked = false, false
setLayout("vertical", 1, 0, 210)

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
A.RefreshActions()
assert(tray.anchor[1] == "BOTTOMLEFT" and tray.anchor[3] == "TOPLEFT")
assert(first.anchor[5] > second.anchor[5] and camp.anchor[5] > sleep.anchor[5], "upward opening preserves top-to-bottom order")
A.db.barOrientation = "horizontal"
A.RefreshActions()
assert(sleep.w == camp.w and sleep.w == first.w and sleep.h == first.h)
camping.bag = nil
A.RefreshActions()
assert(camp.icon.desaturated and camp.icon.alpha < 0.8 and not camp["*item1"])
-- A right-click inspects the current recommendation without touching the secure use action.
local stock = {item = {id = 3664}, name = "Crocolisk Gumbo", count = 19}
local newer = {item = {id = 20074}, name = "Heavy Crocolisk Stew", count = 0}
local entry = A.state.categories.category1
entry.bag, entry.upgrade = stock, newer
bindings.category1, bindings.category2 = "CTRL-1", "F1"
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
bindings.category1 = nil
A.RefreshActions()
assert(first.countText.anchor[1] == "BOTTOMLEFT", "the count stays in place when unbound")
A.db.mouseoverOnly, A.db.collapsed = true, true
A.ToggleBuffBar()
assert(tray.shown and bar.alpha == 1)
bar.scripts.OnUpdate()
assert(bar.alpha == 1, "shortcut expansion is visible before the cursor reaches the bar")
tray.hovered = true
bar.scripts.OnUpdate()
tray.hovered = false
bar.scripts.OnUpdate()
assert(bar.alpha == 0)
print("Buff bar passed: stable grip, both layouts, hover, active borders, aura precedence and timer expiry.")
