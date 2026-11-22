local BINDING = "ALWAYSBUFFED_TOGGLE_WHEEL"
local cx, cy = 600, 400
local x, y = cx, cy
local now, cooldownStart, cooldownDuration = 1000, 0, 0
local combat = false
local actions, frames, pressed = {}, {}, {}
local bindings = { ["CTRL-G"] = BINDING, G = "MOVEFORWARD" }
local overrides = {}
local callback

local Methods = {}
function Methods:SetSize(w, h) self.w, self.h = w, h end
function Methods:GetWidth() return self.w end
function Methods:GetStringWidth() return #(self.text or "") * 7 end
function Methods:GetSize() return self.w, self.h end
function Methods:SetScale(value) self.scale = value end
function Methods:GetScale() return self.scale end
function Methods:SetAlpha(value) self.alpha = value end
function Methods:GetEffectiveScale() return self.scale end
function Methods:GetCenter() return cx / self.scale, cy / self.scale end
function Methods:GetName() return self.name end
function Methods:SetAttribute(key, value)
    assert(not combat, "insecure action write during lockdown")
    self.attrs[key] = value
end
function Methods:RegisterEvent(event) self.events[event] = true end
function Methods:SetScript(event, script) self.scripts[event] = script end
function Methods:RegisterForClicks(...) self.clicks = {...} end
function Methods:Show() self.shown = true end
function Methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Methods:IsShown() return self.shown end
function Methods:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Methods:SetText(value) self.text = value end
function Methods:SetTexture(value) self.texture = value end
function Methods:SetDesaturated(value) self.desaturated = value end
function Methods:SetPoint(_, relative) self.relative = relative end
function Methods:SetColorTexture(...) self.tint = {...} end
function Methods:SetVertexColor(...) self.vertexColor = {...} end

for _, name in ipairs({"SetTextColor", "SetTexCoord",
    "SetMaxLines", "SetJustifyH", "SetWidth", "SetAllPoints", "SetFrameStrata",
    "SetTextScale", "EnableMouse"}) do
    Methods[name] = function() end
end

function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({
        kind = kind, name = name, parent = parent, template = template, shown = true, scale = 1, alpha = 1,
        attrs = {}, scripts = {}, events = {},
    }, {__index = Methods})
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
function Methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function Methods:CreateFontString() return CreateFrame("FontString", nil, self) end

local function event(name)
    for _, frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent(frame, name) end
    end
end
local function tick(elapsed)
    for _, frame in ipairs(frames) do
        if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, elapsed or 1/60) end
    end
end
function GetBindingKey(action)
    local keys = {}
    for key, bound in pairs(bindings) do
        if bound == action then keys[#keys + 1] = key end
    end
    table.sort(keys)
    return unpack(keys)
end
function GetBindingAction(key, checkOverride)
    return checkOverride and overrides[key] and "CLICK " .. overrides[key].name or bindings[key]
end
function SetBinding(key, action) bindings[key] = action; event("UPDATE_BINDINGS"); return true end
function GetCurrentBindingSet() return 1 end
function SaveBindings() end
function SetOverrideBindingClick(owner, _, key, name)
    overrides[key] = { owner = owner, name = name }
    event("UPDATE_BINDINGS")
end
function ClearOverrideBindings(owner)
    for key, data in pairs(overrides) do
        if data.owner == owner then overrides[key] = nil end
    end
    event("UPDATE_BINDINGS")
end
function RegisterStateDriver() end
function InCombatLockdown() return combat end
function IsKeyDown(key) return pressed[key] end
function GetCursorPosition() return x, y end
function GetTime() return now end
C_Item = {GetItemCooldown = function() return cooldownStart, cooldownDuration, 1 end}

-- Dispatch the layout scripts around one mocked native secure click. The client
-- chooses the action via the attributes set by the production A.SetAction.
local function click(frame, button, down)
    local scripts, attrs = frame.scripts, frame.attrs
    if scripts.PreClick then scripts.PreClick(frame, button, down) end
    if scripts.OnClick then scripts.OnClick(frame, button, down) end
    if not down and button == "LeftButton" and attrs["*type1"] then
        actions[#actions + 1] = {
            item = attrs["*item1"], spell = attrs["*spell1"],
            slot = attrs["*target-slot1"], unit = attrs["*unit1"],
        }
    end
    if scripts.PostClick then scripts.PostClick(frame, button, down) end
end
local function useKey(down, key, base)
    key, base = key or "CTRL-G", base or "G"
    pressed[base] = down
    click(_G[assert(overrides[key]).name], "LeftButton", down)
end

UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(cx * 2, cy * 2)
local color = { 0.5, 0.5, 0.5, 1 }
local colors = setmetatable({ mint = { 0.2, 0.6, 0.8 } }, { __index = function() return color end })
local A = {
    theme = {
        colors = colors, Font = function() end,
        OnChange = function(fn) callback = fn end,
    },
    db = { showWheel = true },
    state = { categories = {} },
    categories = {
        { key = "food", label = "Food" },
        { key = "weaponOffhand", label = "Off-Hand Enhancement", kind = "weapon", slot = 17 },
        { key = "scrollIntellect", label = "Intellect", kind = "item" },
        { key = "campfire", label = "Campfire", kind = "reminder", icon = 135805 },
        { key = "fishingLure", label = "Fishing Lure", kind = "weapon", slot = 16, profession = "fishing" },
    },
}
local states = A.state.categories
states.food = { tracked = true, bag = { item = { id = 1 }, count = 4, name = "Food" } }
states.weaponOffhand = { tracked = true, bag = { item = { id = 2 }, count = 5, name = "Oil" } }
states.scrollIntellect = { tracked = true, bag = { item = { id = 3 }, count = 2, name = "Scroll" } }
states.campfire = { tracked = true, bag = { item = { id = 4, spell = 7 }, name = "Campfire" } }

assert(loadfile("AlwaysBuffed/Locale.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Categories.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Status.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/BuffBindings.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Wheel.lua"))("AlwaysBuffed", A)
A.InitWheel()
local wheel = AlwaysBuffedWheel
local function findRegion(key, value)
    for _, frame in ipairs(frames) do
        if frame.shown and frame[key] == value then return frame end
    end
end
local preview
for _, frame in ipairs(frames) do
    if frame.template == "SecureActionButtonTemplate,SecureHandlerStateTemplate" then preview = frame end
end
assert(A.GetWheelBinding() == "CTRL-G")
assert(overrides["CTRL-G"])
assert(AlwaysBuffedWheelBinding1.attrs.useOnKeyDown == false)
assert(table.concat(AlwaysBuffedWheelBinding1.clicks, ",") == "AnyDown,AnyUp")
assert(not A.SetWheelBinding("G") and bindings.G == "MOVEFORWARD")
assert(not A.SetWheelBinding("MOUSEWHEELUP"))

-- Pressing while the physical cursor is off-center starts with no selection.
x, y = 125, 150
useKey(true)
local ringArt = assert(findRegion("texture", "Interface\\AddOns\\AlwaysBuffed\\Media\\WheelFill.png")).parent
assert(wheel:IsShown() and ringArt.alpha == 0 and #actions == 0, "first frame starts transparent")
local openingScale = ringArt.scale
tick(0.06)
local earlyAlpha = ringArt.alpha
assert(earlyAlpha > 0 and earlyAlpha < 0.5 and ringArt.scale < openingScale, "the ring fades and settles across frames")
A.RefreshWheel()
assert(ringArt.alpha == earlyAlpha, "a status refresh does not restart the entrance")
tick(0.06)
assert(ringArt.alpha > earlyAlpha and ringArt.alpha < 1)
tick(0.14)
assert(ringArt.alpha == 1 and ringArt.scale == wheel.scale and not ringArt.scripts.OnUpdate)
assert(findRegion("text", "OH") and not findRegion("text", "Off-Hand Enhancement"))
useKey(false)
assert(not wheel:IsShown() and not overrides.ESCAPE and #actions == 0)
tick(0.06)
assert(ringArt:IsShown() and ringArt.alpha > 0 and ringArt.alpha < 1, "the closing artwork releases input immediately")
tick(0.10)
assert(not ringArt:IsShown() and not ringArt.scripts.OnUpdate)
useKey(true)
x = x + 100
tick()
useKey(false)
assert(not wheel:IsShown() and #actions == 1 and actions[1].item == "item:2" and actions[1].slot == 17)

-- Resolve the release even when there was no intermediate UI update.
x, y = cx, cy
useKey(true)
y = cy + 100
useKey(false)
assert(#actions == 2 and actions[2].item == "item:1")
x, y = cx, cy
useKey(true)
y = cy - 100
useKey(false)
assert(#actions == 3 and actions[3].unit == "player")
x, y = cx, cy
useKey(true)
x = cx - 100
useKey(false)
assert(#actions == 4 and actions[4].spell == 7)

-- Either center cancels. Re-entering the visible hub resets the gesture origin.
x, y = 125, 150
useKey(true)
x = x + 100
tick()
x = 125
useKey(false)
assert(#actions == 4)
useKey(true)
x, y = cx, cy
useKey(false)
assert(#actions == 4)
x, y = 125, 150
useKey(true)
x, y = cx, cy
tick()
x, y = cx, cy + 90
useKey(false)
assert(#actions == 5 and actions[5].item == "item:1")

-- Bag or tracking changes during a hold cannot retarget the pending gesture.
x, y = cx, cy
useKey(true)
x = cx + 100
states.food.tracked = false
A.RefreshWheel()
useKey(false)
assert(#actions == 6 and actions[6].item == "item:2")
states.food.tracked = true
x, y = cx, cy
useKey(true)
y = cy + 90
local food = states.food.bag
states.food.bag = { item = { id = 9 }, count = 3, name = "New food" }
A.RefreshWheel()
useKey(false)
assert(#actions == 6)
states.food.bag = food

-- Escape, combat, and lost releases cancel without arming the secure action.
x, y = cx, cy
useKey(true)
y = cy + 100
click(AlwaysBuffedWheelCancel, "LeftButton", true)
useKey(true)
assert(not wheel:IsShown())
useKey(false)
assert(#actions == 6)
x, y = cx, cy
useKey(true)
y = cy + 100
combat = true
event("PLAYER_REGEN_DISABLED")
useKey(false)
assert(not wheel:IsShown() and #actions == 6 and not A.ToggleWheel())
combat = false
event("PLAYER_REGEN_ENABLED")
x, y = cx, cy
useKey(true)
pressed.G = false
tick()
assert(not wheel:IsShown() and #actions == 6)

-- Preview supports real left-click slices, but center and gaps only close it.
x, y = cx, cy
tick(0.13)
assert(A.ToggleWheel() and preview:IsShown())
assert(ringArt.alpha == 0)
tick(0.06)
assert(ringArt.alpha > 0 and ringArt.alpha < 0.5)
click(preview, "LeftButton", false)
assert(not preview:IsShown() and not wheel:IsShown() and #actions == 6)
local interruptedAlpha = ringArt.alpha
assert(A.ToggleWheel())
assert(ringArt.alpha == interruptedAlpha, "reopening during the fade continues from the visible opacity")
tick(0.02)
assert(ringArt.alpha > interruptedAlpha)
x, y = cx + 100, cy + 100
click(preview, "LeftButton", false)
assert(#actions == 6)
assert(A.ToggleWheel())
x, y = cx + 100, cy
click(preview, "LeftButton", false)
assert(#actions == 7 and actions[7].slot == 17 and not preview:IsShown())

-- With two slices, the whole lower half can select slot 2. One slice fills
-- the entire annulus, and preview continues to update if the theme changes.
states.campfire.tracked = false
states.scrollIntellect.tracked = false
x, y = cx, cy
assert(A.ToggleWheel())
x, y = cx - 100, cy - 20
click(preview, "LeftButton", false)
assert(#actions == 8 and actions[8].slot == 17)
states.weaponOffhand.tracked = false
x, y = cx, cy
assert(A.ToggleWheel())
callback()
x, y = cx - 100, cy - 20
click(preview, "LeftButton", false)
assert(#actions == 9 and actions[9].item == "item:1")

-- Two configured keys cannot finish each other's gesture.
bindings["ALT-K"] = BINDING
event("UPDATE_BINDINGS")
x, y = cx, cy
useKey(true)
useKey(true, "ALT-K", "K")
y = cy + 100
useKey(false, "ALT-K", "K")
assert(wheel:IsShown() and #actions == 9)
useKey(false)
assert(not wheel:IsShown() and #actions == 10)

-- The active aura replaces the kit icon and summary, and expires while the
-- wheel remains open. Changing its presentation must not cast anything.
states.food.tracked = false
states.campfire.tracked = true
states.campfire.bag = {item = {id = 279981}, name = "Basic Campfire Kit", count = 1}
states.campfire.active, states.campfire.expires, states.campfire.activeIcon = "Camp Benefits", 1002, 99300
cooldownStart, cooldownDuration = 990, 30
x, y = cx, cy + 100
assert(A.ToggleWheel())
tick()
assert(findRegion("text", "Camp Benefits") and findRegion("text", "2s left"))
assert(findRegion("text", "2s") and not findRegion("text", "OH"))
local activeIcon = assert(findRegion("texture", 99300))
assert(activeIcon.relative.tint[1] == A.activeBorderColor[1])
assert(activeIcon.relative.tint[2] == A.activeBorderColor[2])
local selectedOutline
for _, frame in ipairs(frames) do
    if frame.shown and type(frame.texture) == "string" and frame.texture:match("WheelStroke%.png$")
        and frame.vertexColor[1] == colors.mint[1] then selectedOutline = frame end
end
assert(selectedOutline, "the selected wedge keeps the class tint")
now = 1001
tick()
assert(findRegion("text", "1s left") and findRegion("text", "1s"))
now = 1003
tick()
assert(not findRegion("texture", 99300) and not findRegion("text", "1s"))
assert(findRegion("text", "Ready to use"))
assert(findRegion("texture", 135805).desaturated)
states.campfire.pending, states.campfire.pendingExpires, states.campfire.pendingIcon = "Welcoming Campfire", 1013, 99302
A.RefreshWheel()
assert(findRegion("text", "Welcoming Campfire") and findRegion("texture", 135805).desaturated)
assert(findRegion("text", "Settling · 10s"))
states.campfire.tracked = false
local sleepingBag = { key = "sleepingBag", label = "Cozy Sleeping Bag", kind = "reminder" }
A.categories[#A.categories + 1] = sleepingBag
states.sleepingBag = {
    tracked = true, bag = {item = {id = 211527}, name = "Cozy Sleeping Bag", count = 1},
    active = "Well-Rested", expires = 1006, activeIcon = 99301,
}
A.RefreshWheel()
assert(findRegion("text", "Well-Rested") and findRegion("text", "3s left"))
now = 1007
tick()
assert(not findRegion("texture", 99301))
assert(findRegion("text", "Ready in 13s"))
assert(A.ToggleWheel() and #actions == 10)

-- A profession switch cancels a held combat gesture and refreshes an open preview.
states.food.tracked = true
states.sleepingBag.tracked = false
states.fishingLure = { tracked = true, bag = { item = { id = 6532 }, count = 1, name = "Bright Baubles" } }
x, y = cx, cy
useKey(true)
assert(wheel:IsShown())
A.state.barProfession = "fishing"
A.RefreshWheel()
assert(not wheel:IsShown(), "switching loadouts cancels the previous held gesture")
y = cy + 100
useKey(false)
assert(#actions == 10, "releasing the previous loadout gesture sends no action")
assert(A.ToggleWheel() and findRegion("text", "MH") and not findRegion("text", "Fishing Lure"))
click(preview, "LeftButton", false)
assert(#actions == 11 and actions[11].item == "item:6532" and actions[11].slot == 16)
assert(A.ToggleWheel() and findRegion("text", "MH"))
A.state.barProfession = nil
click(preview, "LeftButton", false)
assert(#actions == 11, "clicking an old loadout snapshot sends no action even before refresh")
A.state.barProfession = "fishing"
assert(A.ToggleWheel() and findRegion("text", "MH"))
A.state.barProfession = nil
A.RefreshWheel()
assert(findRegion("text", "Food") and not findRegion("text", "MH"))
assert(A.ToggleWheel())

assert(A.SetWheelBinding("SHIFT-H"))
assert(not bindings["CTRL-G"] and not overrides["CTRL-G"] and not overrides["ALT-K"])
assert(bindings["SHIFT-H"] == BINDING)
assert(A.SetWheelBinding(nil) and not overrides["SHIFT-H"])
bindings["SHIFT-J"] = "ALWAYSBUFFED_USE_BUFFDRINKS"
assert(A.SetWheelBinding("SHIFT-J") and bindings["SHIFT-J"] == BINDING)
print("wheel tests passed")
