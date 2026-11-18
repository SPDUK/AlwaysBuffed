-- Lua 5.1. Exercise the shared secure attributes and character themes without a client.
local A = {db = { fontScale = 1 }, state = { class = "HUNTER" }}
function GetLocale() return "enUS" end
function UnitClass() return "Hunter", "HUNTER" end
RAID_CLASS_COLORS = { HUNTER = { r = 0.67, g = 0.83, b = 0.45 } }
local locked = false
function InCombatLockdown() return locked end
assert(loadfile("AlwaysBuffed/Theme.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Actions.lua"))("AlwaysBuffed", A)

local button = { attributes = {} }
function button:SetAttribute(k, value) self.attributes[k] = value end
local row = { item = { id = 2892 }, count = 2 }
A.SetAction(button, { key = "imbue", slot = 16 }, row)
assert(button.attributes["*type1"] == "item" and button.attributes["*item1"] == "item:2892")
assert(button.attributes["*target-slot1"] == 16)
A.SetAction(button, { key = "imbueOffhand", slot = 17 }, row)
assert(button.attributes["*target-slot1"] == 17)
locked = true
A.SetAction(button, nil, nil)
assert(button.attributes["*target-slot1"] == 17)
locked = false
A.SetAction(button, { key = "scrollStamina" }, row)
assert(button.attributes["*target-slot1"] == nil and button.attributes["*unit1"] == "player")
A.SetAction(button, { key = "crystal" }, { item = {id = 11564, selfTarget = true}, count = 1 })
assert(button.attributes["*unit1"] == "player" and button.attributes["*item1"] == "item:11564")
A.SetAction(button, { key = "imbueOffhand", slot = 17 }, { item = { spell = 8024 } })
assert(button.attributes["*type1"] == "spell" and button.attributes["*spell1"] == 8024)
assert(button.attributes["*item1"] == nil and button.attributes["*unit1"] == nil)
A.SetAction(button, nil, nil)
assert(next(button.attributes) == nil)

assert(loadfile("AlwaysBuffed/Catalog.lua"))("AlwaysBuffed", A)
assert(loadfile("AlwaysBuffed/Categories.lua"))("AlwaysBuffed", A)
local offhand
for _, category in ipairs(A.categories) do
    if category.key == "imbueOffhand" then offhand = category end
end
A.ApplyClassLabels("ROGUE")
assert(offhand.label == "Off-Hand Poison" and A.CategoryForClass(offhand, "ROGUE"))
A.ApplyClassLabels("SHAMAN")
assert(offhand.label == "Off-Hand Weapon Imbue" and A.CategoryForClass(offhand, "SHAMAN"))
assert(not A.CategoryForClass(offhand, "HUNTER"))

local c = A.theme.colors
local accent, panel = c.accent, c.panel
assert(accent[1] == RAID_CLASS_COLORS.HUNTER.r)
local fs = {}
function fs:SetFont(path, size) self.path, self.size = path, size return true end
A.theme.Font(fs, 16, true)
assert(fs.path:match("Barlow%-Bold.ttf$") and fs.size == 16)
local changed = false
A.theme.OnChange(function() changed = true end)
A.db.customAccent, A.db.customBackground, A.db.fontScale = {0.5, 0.5, 0.5}, {1, 1, 1}, 1.25
A.theme.Refresh()
assert(changed and fs.size == 20)
assert(c.accent == accent and c.panel == panel and accent[1] == 0.5 and panel[3] == 1)
assert(c.text[1] < 0.1 and c.mint[1] < 0.5)
A.db.customAccent, A.db.customBackground = {0, 0, 0}, {0, 0, 0}
A.theme.Refresh()
assert(c.text[1] > 0.9 and c.mint[1] > 0.4)
print("Secure action attributes and theme changes passed.")
