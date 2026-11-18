-- Exercise the collapsed grip through the real Actions tick and refresh paths.
local methods = {}
local locked, now, tick, recolor = false, 1000
function methods:SetSize(w, h) self.w, self.h = w, h end
function methods:SetWidth(w) self.w = w end
function methods:GetWidth() return self.w end
function methods:GetHeight() return self.h end
function methods:SetScale(scale) self.scale = scale end
function methods:GetScale() return self.scale end
function methods:SetPoint(...) self.anchor = {...} end
function methods:GetCenter()
    return 500 / self.scale + (self.anchor and self.anchor[4] or 0),
        300 / self.scale + (self.anchor and self.anchor[5] or 0)
end
function methods:GetLeft() return self:GetCenter() - self.w / 2 end
function methods:GetTop() return select(2, self:GetCenter()) + self.h / 2 end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:SetText(value) self.text = value end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:SetVertexColor(...) self.tint = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetTexture(value) self.texture = value end
function methods:SetShown(shown)
    if locked then
        assert(self.kind == "Texture" or self.kind == "FontString", "frame visibility was changed in combat")
    end
    self.shown = shown
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetAttribute() assert(not locked, "secure action was changed in combat") end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end

for word in ([[
    SetAllPoints SetAlpha SetTexCoord SetBlendMode RegisterForClicks RegisterForDrag
    RegisterEvent SetClampedToScreen SetFrameStrata SetColorTexture SetTextScale
    SetHeight ClearAllPoints SetDesaturated SetJustifyH
]]):gmatch("%S+") do methods[word] = function() end end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({kind = kind, parent = parent, scale = 1, shown = true, scripts = {}}, {__index = methods})
    if name then _G[name] = frame end
    return frame
end

function GetTime() return now end
function InCombatLockdown() return locked end
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

assert(loadfile("AlwaysBuffed/Status.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)
A.InitActions()
local bar, grip = AlwaysBuffedBar, AlwaysBuffedBarFold
local anchor = bar.anchor
assert(bar.w == 48 and bar.h == 48 and grip.icon.shown)
local countFace = grip.missingText.anchor[2]
assert(countFace == grip.activeText.anchor[2] and countFace.w == 40 and countFace.h == 40)
assert(countFace.anchor[1] == "CENTER" and grip.missingText.anchor[4] < grip.activeText.anchor[4])
assert(grip.countBackdrop.shown and bar.outline.anchor[2] == bar)
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
locked = false

for _, state in pairs(A.state.categories) do state.tracked = false end
A.RefreshActions()
assert(bar.shown and grip.missingText.shown and grip.activeText.shown)
assert(grip.missingText.text == "0" and grip.activeText.text == "0" and not grip.missingGlow.shown)
assert(grip.missingText.textColor[1] == colors.muted[1], "zero missing uses the quiet count color")
A.ToggleBuffBar(false)
assert(bar.shown and bar.anchor == anchor)
assert(not grip.countBackdrop.shown)
assert(not grip.missingText.shown and not grip.activeText.shown and not grip.countDivider.shown)
assert(GameTooltip.lines[2] ~= "0 missing")
print("Collapsed grip size, ordered counts, tooltip, theme and combat expiry passed.")
