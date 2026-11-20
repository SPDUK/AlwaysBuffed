-- Exercise the collapsed grip through the real Actions tick and refresh paths.
local methods = {}
local locked, now, tick, recolor = false, 1000
local secure = dofile("tests/secure-click.lua")
local function geometry() assert(not locked, "grip layout rebuilt during combat") end
function methods:SetSize(w, h) geometry() self.w, self.h = w, h end
function methods:SetWidth(w) geometry() self.w = w end
function methods:GetWidth() return self.w end
function methods:GetHeight() return self.h end
function methods:SetScale(scale) geometry() self.scale = scale end
function methods:GetScale() return self.scale end
function methods:SetPoint(...) geometry() self.anchor = {...} end
function methods:GetCenter()
    return 500 / self.scale + (self.anchor and self.anchor[4] or 0),
        300 / self.scale + (self.anchor and self.anchor[5] or 0)
end
function methods:GetLeft() return self:GetCenter() - self.w / 2 end
function methods:GetRight() return self:GetCenter() + self.w / 2 end
function methods:GetTop() return select(2, self:GetCenter()) + self.h / 2 end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:SetText(value) self.text = value end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:SetVertexColor(...) self.tint = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetShown(shown)
    if locked and not secure.running then
        assert(self.kind == "Texture" or self.kind == "FontString", "frame visibility was changed in combat")
    end
    self.shown = shown
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetAttribute(name, value)
    assert(not locked or secure.running, "secure action was changed in combat")
    self.attributes[name] = value
end
function methods:GetAttribute(name) return self.attributes[name] end
methods.SetFrameRef = secure.SetFrameRef
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end

for word in ([[
    SetAllPoints SetAlpha SetTexCoord SetBlendMode RegisterForDrag EnableMouse
    RegisterEvent SetClampedToScreen SetFrameStrata SetColorTexture SetTextScale
    SetHeight ClearAllPoints SetDesaturated SetJustifyH
]]):gmatch("%S+") do methods[word] = function() end end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({kind = kind, parent = parent, template = template, scale = 1, shown = true,
        scripts = {}, attributes = {}, protected = template and template:find("Secure", 1, true)}, {__index = methods})
    if name then _G[name] = frame end
    return frame
end

function GetTime() return now end
function InCombatLockdown() return locked end
function IsShiftKeyDown() return false end
C_Timer = {NewTicker = function(_, callback) tick = callback end}
GameTooltip = {
    SetOwner = function(self, owner) self.owner = owner end,
    IsOwned = function(self, owner) return self.owner == owner end,
    SetText = function(self, title) self.title, self.lines = title, {} end,
    AddLine = function(self, line) self.lines[#self.lines + 1] = line end,
    Show = function() end,
}
UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1000, 600)

local generic = {1, 1, 1}
local colors = setmetatable({missing = {0.92, 0.65, 0.64}, muted = {0.7, 0.7, 0.7}},
    {__index = function() return generic end})
local A = {
    db = {showBar = true, collapsed = true, barScale = 1},
    categories = {
        {key = "weapon", kind = "weapon", slot = 16},
        {key = "weaponOffhand", kind = "weapon", slot = 17},
        {key = "campfire", kind = "reminder"},
        {key = "food", kind = "food"},
        {key = "elixir", kind = "item"},
    },
    state = {categories = {
        weapon = {tracked = true, active = "Sharpened", expires = 1001},
        weaponOffhand = {tracked = true},
        campfire = {tracked = true, pending = "Welcoming Campfire"},
        food = {tracked = true, applicable = false},
        elixir = {tracked = false},
    }},
    theme = {colors = colors, Font = function() end, OnChange = function(callback) recolor = callback end},
    GetBuffBinding = function() end,
    RefreshOptions = function() end, InitBuffBindings = function() end, RefreshBuffBindings = function() end,
}

assert(loadfile("AlwaysBuffed/Locale.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Categories.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Status.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)
A.InitActions()
local bar, grip = AlwaysBuffedBar, AlwaysBuffedBarFold
local anchor = bar.anchor
assert(bar.w == 48 and bar.h == 48 and grip.icon.shown)
assert(grip.missingText.anchor[1] == "BOTTOMLEFT" and grip.activeText.anchor[1] == "BOTTOMRIGHT")
assert(grip.missingText.backing.shown and grip.activeText.backing.shown and bar.outline.anchor[2] == bar)
assert(grip.missingText.text == "2" and grip.activeText.text == "1")
assert(grip.missingText.textColor[2] == colors.missing[2] and grip.activeText.textColor[2] == colors.mint[2])
assert(grip.missingText.shown and grip.activeText.shown and grip.countDivider.shown)
assert(not grip.missingGlow.shown)
grip.scripts.OnEnter(grip)
assert(GameTooltip.lines[2] == "2 missing" and GameTooltip.lines[3] == "1 active")

A.db.highlightMissing = true
A.RefreshGripCounts()
assert(grip.missingGlow.shown and grip.missingGlow.texture:match("UI%-ActionButton%-Border"))
colors.missing[1] = 0.91
recolor()
assert(grip.missingGlow.tint[1] == 0.91 and grip.missingText.textColor[1] == 0.91)

locked, now = true, 1001
tick()
assert(grip.missingText.text == "3" and grip.activeText.text == "0")
assert(GameTooltip.lines[2] == "3 missing" and GameTooltip.lines[3] == "0 active")
assert(bar.anchor == anchor)
secure.press(grip, "LeftButton", false)
assert(not A.db.collapsed and AlwaysBuffedAction_weapon:IsVisible(), "the initially folded tray was prepared before combat")
assert(not grip.missingText.shown and GameTooltip.lines[1] == "Click to collapse the buff bar.")
secure.press(grip, "LeftButton", false)
assert(A.db.collapsed and not AlwaysBuffedAction_weapon:IsVisible() and grip.missingText.text == "3")
assert(GameTooltip.lines[1] == "Click to expand the buff bar." and GameTooltip.lines[2] == "3 missing")
locked = false

for _, state in pairs(A.state.categories) do state.tracked = false end
A.RefreshActions()
assert(bar.shown and grip.missingText.shown and grip.activeText.shown)
assert(grip.missingText.text == "0" and grip.activeText.text == "0" and not grip.missingGlow.shown)
assert(grip.missingText.textColor[1] == colors.muted[1], "zero missing uses the quiet count color")
locked = true
secure.press(grip, "LeftButton", false)
assert(not A.db.collapsed and not AlwaysBuffedAction_weapon:IsVisible(), "an empty tray stays hidden on expansion")
assert(bar.shown and bar.anchor == anchor)
assert(not grip.missingText.backing.shown and not grip.activeText.backing.shown)
assert(not grip.missingText.shown and not grip.activeText.shown and not grip.countDivider.shown)
assert(GameTooltip.lines[2] ~= "0 missing")
print("Collapsed grip size, counts, combat expiry and initially folded or empty secure tray passed.")
