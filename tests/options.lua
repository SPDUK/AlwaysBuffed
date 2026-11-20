-- Run from the workspace root with Lua 5.1: lua tests/options.lua
local methods = {}
local function widget(name, parent)
    local frame = setmetatable({name = name, parent = parent, scripts = {}, enabled = true, shown = true}, {__index = methods})
    if name then _G[name] = frame end
    return frame
end
function methods:Fire(event, ...) if self.scripts[event] then self.scripts[event](self, ...) end end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:CreateTexture() return widget(nil, self) end
function methods:CreateLine() return widget(nil, self) end
function methods:CreateFontString() return widget(nil, self) end
function methods:SetWidth(n) self.width = n end
function methods:SetHeight(n) self.height = n end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width or 1 end
function methods:GetHeight() return self.height or 1 end
function methods:SetScale(n) self.scale = n end
function methods:GetName() return self.name end
function methods:SetFrameLevel(n) self.level = n end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetPoint(point, ...)
    self.points = self.points or {}
    self.points[point] = {...}
end
function methods:ClearAllPoints() self.points = nil end
function methods:SetText(text)
    self.text = text
    if self.kind == "EditBox" then self:Fire("OnTextChanged", false) end
end
function methods:GetText() return self.text end
function methods:Type(text) self.text = text self:Fire("OnTextChanged", true) end
function methods:HasFocus() return self.focused == true end
function methods:SetFocus() self.focused = true self:Fire("OnEditFocusGained") end
function methods:ClearFocus() self.focused = false self:Fire("OnEditFocusLost") end
function methods:SetFont(face, size) self.font, self.fontSize = face, size return true end
function methods:GetFont() return self.font, self.fontSize end
function methods:SetColorTexture(...) self.tint = {...} end
function methods:SetTextColor(...) self.tint = {...} end
function methods:SetVertexColor(...) self.tint = {...} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false self:Fire("OnHide") end
function methods:IsShown() return self.shown end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetEnabled(value) self.enabled = value end
function methods:EnableKeyboard(value) self.keyboard = value end
function methods:IsKeyboardEnabled() return self.keyboard end
function methods:GetMinMaxValues() return self.min, self.max end
function methods:SetMinMaxValues(min, max) self.min, self.max = min, max end
function methods:GetValue() return self.valueNumber or 0 end
function methods:SetValue(n, input)
    self.valueNumber = math.max(self.min or n, math.min(self.max or n, n))
    self:Fire("OnValueChanged", self.valueNumber, input)
end
function methods:GetVerticalScroll() return self.scrollOffset or 0 end
function methods:SetVerticalScroll(n) self.scrollOffset = n end
for name in ([=[SetAllPoints SetDrawLayer SetThickness SetStartPoint SetEndPoint
    SetJustifyH SetJustifyV SetMaxLines SetWordWrap SetTexture SetTexCoord SetClipsChildren SetScrollChild
    SetThumbTexture SetOrientation SetHighlightTexture SetHitRectInsets SetAlpha SetPropagateKeyboardInput
    SetMovable SetClampedToScreen SetFrameStrata SetValueStep SetObeyStepOnDrag EnableMouse EnableMouseWheel
    SetAutoFocus SetMaxLetters SetTextInsets RegisterEvent RegisterForDrag StartMoving StopMovingOrSizing]=]):gmatch("%S+") do
    methods[name] = function() end
end
function CreateFrame(kind, name, parent)
    local frame = widget(name, parent)
    frame.kind = kind
    return frame
end
UIParent, UISpecialFrames = widget("UIParent"), {}
UIParent:SetSize(1600, 900)
GameTooltip = {IsOwned = function() return false end, SetOwner = function() end,
    SetText = function() end, Show = function() end}
STANDARD_TEXT_FONT = "standard"
function GetLocale() return "koKR" end
function UnitClass() return "Jäger", "HUNTER" end
function GetMoneyString(n) return tostring(n) end
function GetBindingText(key) return key end
local now, cooldownStart, cooldownDuration = 1000, 0, 0
local cooldownCalls = 0
function GetTime() return now end
C_Item = {GetItemCooldown = function()
    cooldownCalls = cooldownCalls + 1
    return cooldownStart, cooldownDuration, 1
end}
function IsAltKeyDown() return true end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
local combat = false
function InCombatLockdown() return combat end

ColorPickerFrame = {}
function ColorPickerFrame:SetupColorPickerAndShow(info)
    self.info, self.rgb = info, {info.r, info.g, info.b}
    info.swatchFunc()
end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb) end
function ColorPickerFrame:Choose(r, g, b)
    self.rgb = {r, g, b}
    self.info.swatchFunc()
end

local A = {}
local function loadAddon(filename)
    assert(loadfile("AlwaysBuffed/" .. filename .. ".lua"))("AlwaysBuffed", A)
end
for _, filename in ipairs({"Locale", "Catalog", "Categories", "Profiles", "Planner", "Theme", "Status", "Options"}) do
    loadAddon(filename)
end
A.db = {preferences = {}, showWheel = true, showBar = true, reminders = false,
    mouseoverOnly = false, highlightMissing = false}
A.state = {class = "HUNTER", level = 32, categories = {}, profile = A.profiles.HUNTER[1]}
A.ApplyClassLabels(A.state.class)
local binding, previews, actionRefreshes, wheelRefreshes = nil, 0, 0, 0
function A.GetWheelBinding() return binding end
function A.SetWheelBinding(key) binding = key return true end
local barBinding
function A.GetBarToggleBinding() return barBinding end
function A.SetBarToggleBinding(key)
    if key == "ALT-W" then return false, "ALT-W is already bound to the wheel." end
    barBinding = key
    return true
end
local buffBindings = {}
function A.GetBuffBinding(category) return buffBindings[category] end
function A.SetBuffBinding(category, key)
    if key == "ALT-X" then return false, "ALT-X is already bound to Sit." end
    buffBindings[category] = key
    return true
end
function A.ToggleWheel() previews = previews + 1 return true end
function A.RefreshActions() actionRefreshes = actionRefreshes + 1 end
function A.RefreshWheel() wheelRefreshes = wheelRefreshes + 1 end
local weapons, bagCounts = {[16] = "sharp"}, {[279981] = 2}
function A.SetBarMode(mode)
    A.db.barMode = mode
    A.Update()
end
function A.Update()
    local mode = A.db.barMode or "auto"
    if mode == "auto" then
        A.state.barProfession = weapons[16] == "fishingPole" and "fishing" or nil
    else
        A.state.barProfession = mode ~= "combat" and mode or nil
    end
    if A.db.profile then
        A.state.profile = A.SelectProfile(A.profiles[A.state.class], A.db.profile, {})
    end
    local ctx = {class = A.state.class, level = A.state.level, reminders = A.db.reminders,
        weapons = weapons, skill = function() return 1 end, known = function() return false end,
        info = function(item) return {name = item.name, count = bagCounts[item.id] or 0} end}
    for _, category in ipairs(A.categories) do
        A.state.categories[category.key] = A.PlanCategory(category, A.catalog[category.key], ctx, A.Prefs(category.key), A.state.profile)
    end
    A.RefreshOptions()
end

local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local function click(control) control:Fire("OnClick") end
local function visibleItem(panel, name)
    for _, widget in ipairs(panel.itemWidgets) do
        if widget:IsShown() and widget.itemRow and widget.itemRow.name == name then return widget end
    end
end
local function shoppingShows(panel, key)
    for _, widget in ipairs(panel.itemWidgets) do
        if widget:IsShown() and widget.shopping and widget.category.key == key then return true end
    end
    return false
end
local function indexNavigation(panel)
    local index = {}
    local latest = -1
    for _, control in ipairs(panel.navigation) do
        equal(index[control.key], nil, control.key .. " appears only once")
        index[control.key] = control
        if control.category then
            equal(control.offset > latest, true, control.key .. " is visually below the previous category")
            latest = control.offset
        end
    end
    for _, category in ipairs(A.categories) do
        equal(index[category.key] ~= nil, A.CategoryForClass(category, A.state.class), category.key .. " appears for eligible classes")
    end
    return index
end
local function sidebarOrder(panel, count)
    local keys = {}
    for _, nav in ipairs(panel.navigation) do
        if nav.category then
            keys[#keys + 1] = nav.key
            if #keys == count then break end
        end
    end
    return table.concat(keys, ",")
end
A.Update()
A.ToggleOptions()
local panel = AlwaysBuffedOptionsPanel
panel.scroll:SetHeight(230)
local nav = indexNavigation(panel)
equal(panel.heading:GetText(), "Shopping list", "shopping opens at launch")
equal(panel.navigation[1].key .. "," .. panel.navigation[2].key .. "," .. panel.navigation[3].key .. "," .. panel.navigation[4].key,
    "general,appearance,shopping,professions", "profession controls are discoverable above buff categories")
equal(sidebarOrder(panel, 4), "food,elixir,scrollAgility,scrollStamina", "Hunter starts with leveling staples and useful scrolls")
equal(panel.heading.font, STANDARD_TEXT_FONT, "native glyph coverage for Korean")
equal(panel.tableHeader.bags:GetText(), "In bags", "shopping bag count heading")
equal(panel.tableHeader.price:GetText(), "Auction price", "shopping price heading")
equal(nav.campfire.inScroll, true, "campfire belongs to the scrollable category list")
equal(nav.sleepingBag.inScroll, true, "sleeping bag belongs to the scrollable category list")
equal(nav.campfire.offset < nav.sleepingBag.offset, true, "campfire and sleeping bag keep their reminder order")
equal(nav.sleepingBag.offset < nav.fishingLure.offset, true, "profession categories follow regular sidebar sections")
equal(nav.fishingLure.offset < nav.herbalismTea.offset, true, "profession categories follow their section order")
equal(nav.imbue, nil, "Hunter has no class imbue page")
equal(nav.imbueOffhand, nil, "Hunter has no off-hand class imbue page")
equal(nav.scrollFamiliar, nil, "Hunter has no Mage familiar scroll page")
local hunterOrder = sidebarOrder(panel)
click(nav.scrollAgility.track)
equal(A.Prefs("scrollAgility").enabled, false, "sidebar checkbox still changes the tracking setting")
equal(sidebarOrder(panel), hunterOrder, "tracking overrides leave sidebar order unchanged")
A.Prefs("scrollAgility").enabled = nil
bagCounts[2680] = 5
A.Update()
equal(sidebarOrder(panel), hunterOrder, "inventory changes leave sidebar order unchanged")
bagCounts[2680] = nil
A.Update()

equal(shoppingShows(panel, "fishingLure"), false, "combat shopping keeps profession purchases out of the list")
click(nav.professions)
local professionPage = panel.professions
equal(panel.heading:GetText(), "Professions", "fixed navigation opens profession settings")
equal(professionPage.modes.auto.selected, true, "automatic is the default bar mode")
equal(professionPage.activeBar:GetText(), "Active bar: Combat", "settings show the active bar")
equal(professionPage.modes.comprehension, nil, "class-specific bar is unavailable to a Hunter")
equal(professionPage.links.comprehensionScroll, nil, "class-specific category is absent from the Hunter hub")
click(professionPage.links.fishingLure)
equal(panel.heading:GetText(), "Fishing Lure", "profession link opens the regular category")
equal(panel.subheading:GetText(), "Shown on the Fishing bar.", "inactive profession remains browsable with context")
equal(panel.category.track.checked, true, "profession categories are tracked by default")
local lureShortcut = panel.category.shortcut
equal(lureShortcut.status:GetText(), "Use this category’s selected item or spell while its profession bar is active.",
    "profession shortcuts explain when they can be used")
click(lureShortcut.pick)
panel.capture:Fire("OnKeyDown", "L")
equal(A.GetBuffBinding("fishingLure"), "ALT-L", "profession shortcuts can be set outside their bar mode")
click(lureShortcut.clear)
click(panel.category.track)
equal(nav.fishingLure.track.checked, false, "profession tracking can be turned off outside its mode")
click(panel.category.restore)
equal(nav.fishingLure.track.checked, true, "restoring defaults re-enables the profession category")
local lure = A.catalog.fishingLure[1]
click(panel.category.showUnusable)
panel.category.search:Type(lure.name)
click(assert(visibleItem(panel, lure.name)).action)
equal(A.Prefs("fishingLure").pin, lure.id, "profession search and pin work outside its mode")
click(panel.category.clear)
equal(A.Prefs("fishingLure").pin, nil, "automatic selection clears the profession pin")
click(panel.category.showUnusable)

click(nav.professions)
click(professionPage.modes.fishing)
equal(A.db.barMode, "fishing", "specific profession mode can be selected")
equal(professionPage.activeBar:GetText(), "Active bar: Fishing", "selector shows the active profession")
click(professionPage.links.fishingLure)
equal(panel.subheading:GetText(), "Requires a fishing pole", "lures explain their equipment requirement")
weapons[16] = "fishingPole"
A.Update()
click(nav.shopping)
equal(shoppingShows(panel, "fishingLure"), true, "fishing shopping shows lure recommendations")
equal(shoppingShows(panel, "food"), false, "fishing shopping omits combat recommendations")
click(nav.professions)
click(professionPage.modes.herbalism)
equal(professionPage.activeBar:GetText(), "Active bar: Herbalism", "a profession without an equipment trigger is selectable")
click(professionPage.modes.mining)
equal(professionPage.activeBar:GetText(), "Active bar: Mining", "mining can be selected directly")
weapons[16] = "sharp"
click(professionPage.modes.auto)
weapons[16] = "fishingPole"
A.Update()
equal(professionPage.modes.auto.selected, true, "an equipment change preserves the automatic preference")
equal(professionPage.activeBar:GetText(), "Active bar: Fishing", "automatic displays the equipped profession bar")
click(professionPage.modes.combat)
equal(professionPage.activeBar:GetText(), "Active bar: Combat", "manual combat overrides fishing equipment")
weapons[16] = "sharp"
click(professionPage.modes.auto)
click(nav.shopping)

panel.sidebarScroll:SetHeight(260)
panel.sidebarScroll.updateRange()
click(nav.weapon)
panel.sidebarScroll.bar:SetValue(nav.weapon.offset - 100)
local sidebarPosition = nav.weapon.offset - panel.sidebarScroll:GetVerticalScroll()
local originalWeaponOffset = nav.weapon.offset
panel.scroll.updateRange()
panel.scroll.bar:SetValue(125)
local contentOffset = panel.scroll:GetVerticalScroll()
click(panel.profile)
click(panel.profileItems[4])
equal(A.state.profile.key, "survival", "the profile picker changes the active Hunter spec")
equal(sidebarOrder(panel, 6), "food,elixir,elixirAttackPower,scrollAgility,scrollStamina,weapon",
    "Survival promotes Attack Power and main-hand stones and oils")
equal(nav.weapon.offset < originalWeaponOffset, true, "the promoted category actually moves higher")
equal(panel.heading:GetText(), "Main-Hand Stones & Oils", "profile changes keep the selected category open")
equal(nav.weapon.mark:IsShown(), true, "sidebar preserves the selected category accent")
equal(nav.weapon.offset - panel.sidebarScroll:GetVerticalScroll(), sidebarPosition, "visible selection retains its sidebar position")
equal(panel.scroll:GetVerticalScroll(), contentOffset, "profile picker keeps the detail pane scroll position")
A.db.profile = nil
A.state.profile = A.profiles.HUNTER[1]
A.Update()
equal(sidebarOrder(panel), hunterOrder, "switching back restores the original sidebar order")
click(nav.food)
local ranking, search = panel.category.groupHeaders, panel.category.search
local direct = panel.category.shortcut
search:SetFocus()
click(direct.pick)
equal(search:HasFocus(), false, "binding capture releases search focus")
equal(direct.pick.title:GetText(), "Cancel", "buff shortcut indicates binding capture")
panel.capture:Fire("OnKeyDown", "X")
equal(A.GetBuffBinding("food"), nil, "conflicting shortcut is rejected")
equal(direct.status:GetText(), "ALT-X is already bound to Sit.", "binding conflict explains why the shortcut was rejected")
click(direct.pick)
panel.capture:Fire("OnKeyDown", "F")
equal(A.GetBuffBinding("food"), "ALT-F", "food captures its own shortcut")
equal(direct.pick.title:GetText(), "ALT-F", "bound buff shortcut is shown")
click(direct.pick)
panel.capture:Fire("OnKeyDown", "ESCAPE")
equal(A.GetBuffBinding("food"), "ALT-F", "escape preserves an existing shortcut")
equal(panel.capture:IsKeyboardEnabled(), false, "escape exits shortcut capture")
click(direct.pick)
search:SetFocus()
equal(panel.capture:IsKeyboardEnabled(), false, "focusing the search cancels shortcut capture")
panel.capture:Fire("OnKeyDown", "Q")
equal(A.GetBuffBinding("food"), "ALT-F", "typing after capture cancellation preserves the shortcut")
equal(ranking.best.title:GetText(), "Best for your spec", "first ranking section")
equal(ranking.utility.title:GetText(), "Utility", "utility ranking section")
equal(ranking.notUseful.title:GetText(), "Not useful", "irrelevant ranking section")
equal(ranking.best.expanded and ranking.utility.expanded and ranking.notUseful.expanded, true, "all ranking groups start open")
equal(visibleItem(panel, "Poached Sunscale Salmon"), nil, "upcoming recipes start hidden in rankings")
equal(panel.category.showUnusable.checked, false, "each category starts with unusable items hidden")
local summary = panel.category.status
equal(summary[3]:IsShown(), false, "the next unlock preview follows the default filter")
equal(summary[3].itemRow, nil, "a hidden preview has no unavailable item tooltip")
local summaryWidth = summary[1]:GetWidth()
equal(summary[2]:GetWidth(), summaryWidth, "the two visible summaries each use half the row")
click(ranking.best)
equal(ranking.best.expanded, false, "hide rows in one group")
equal(ranking.utility.expanded, true, "other ranking groups stay open")
A.Update()
equal(ranking.best.expanded, false, "automatic refresh preserves collapsed group")
search:SetFocus()
equal(search.placeholder:IsShown(), false, "placeholder clears on focus")
search:Type("  mItHrIl HeAd  ")
equal(panel.category.searchRow.count:GetText(), "1 result", "search matches item name substring")
equal(ranking.best.expanded, false, "matching search preserves collapsed group")
click(panel.category.searchRow.clear)
equal(search:GetText(), "", "clear restores full rankings")
equal(ranking.best.expanded, false, "clearing search preserves collapsed group")
click(ranking.best)
search:Type("Poached Sunscale Salmon")
equal(panel.category.searchRow.count:GetText(), "0 results", "search excludes upcoming items")
equal(panel.empty:GetText(), "No usable items match your search.", "search empty state explains usable-item requirement")
equal(panel.itemWidgets[1]:IsShown(), false, "no results hide old rows")
click(panel.category.showUnusable)
equal(panel.category.searchRow.count:GetText(), "1 result", "the filter also includes unusable search results")
equal(summary[3]:IsShown(), true, "enabling unusable items also reveals the next unlock preview")
equal(summary[3].itemRow.level > A.state.level, true, "the preview points to a future unlock")
equal(summary[1]:GetWidth() < summaryWidth, true, "the visible summaries reflow to make room for the preview")
equal(2 * summary[1]:GetWidth() + summary[3]:GetWidth(), 2 * summaryWidth, "both summary layouts use all available width")
local upcoming = visibleItem(panel, "Poached Sunscale Salmon")
equal(upcoming.detail:GetText():find("At level 35", 1, true), 1, "shown upcoming items identify their level")
A.ToggleOptions()
A.ToggleOptions()
equal(panel.category.showUnusable.checked, true, "unusable-item preference persists across reopen")
local hunterProfile = A.state.profile
A.state.profile = A.profiles.HUNTER[2]
A.Update()
equal(panel.category.showUnusable.checked, false, "other specs keep their own unusable-item preference")
equal(panel.category.searchRow.count:GetText(), "0 results", "search re-applies the active spec’s filter")
equal(summary[3]:IsShown(), false, "switching to a spec with the filter off hides the preview again")
A.state.profile = hunterProfile
A.Update()
click(panel.category.showUnusable)

local foodPlan = A.state.categories.food
local upgrade
for _, row in ipairs(foodPlan.rows) do
    if row.name == "Mithril Head Trout" and row.eligible then upgrade = row end
end
assert(upgrade, "the fixture has an eligible upgrade")
foodPlan.upgrade = upgrade
search:Type("")
click(panel.category.groupHeaders[upgrade.group])
equal(panel.category.groupHeaders[upgrade.group].expanded, false, "upgrade fixture starts in a closed group")
search:Type("Poached Sunscale Salmon")
A.OpenCategory("food", upgrade.item.id)
equal(search:GetText(), "", "opening an upgrade clears a conflicting search on the same page")
equal(panel.category.groupHeaders[upgrade.group].expanded, true, "opening an upgrade expands its group")
local shownUpgrade = visibleItem(panel, upgrade.name)
equal(shownUpgrade.itemRow.item.id, upgrade.item.id, "the exact upgrade item is marked")
equal(shownUpgrade.detail:GetText():find("Upgrade", 1, true), 1, "upgrade row has an explicit text label")
equal(shownUpgrade.upgradeMark:IsShown(), true, "upgrade row has an accent marker")
local rowY = -shownUpgrade.points.TOPLEFT[2]
local offset = panel.scroll:GetVerticalScroll()
equal(offset > 0 and offset <= rowY and offset + panel.scroll:GetHeight() >= rowY + shownUpgrade:GetHeight(), true,
    "the whole upgrade row scrolls into view")
search:Type(upgrade.name)
A.OpenCategory("food", upgrade.item.id)
equal(search:GetText(), upgrade.name, "opening the upgrade keeps a matching search")
A.ToggleOptions()
A.OpenCategory("food", upgrade.item.id)
equal(panel:IsShown(), true, "opening an upgrade shows closed options")
foodPlan.upgrade = nil
A.RefreshOptions()
equal(visibleItem(panel, upgrade.name).upgradeMark:IsShown(), false, "stale upgrades lose the highlight on refresh")

local previousLevel, previousProfile = A.state.level, A.state.profile
A.state.level, A.state.profile = 20, A.SelectProfile(A.profiles.HUNTER, "survival", {})
bagCounts[3664] = 6
search:Type("")
A.Update()
click(assert(visibleItem(panel, "Crocolisk Gumbo")).action)
equal(A.Prefs("food").pin, 3664, "tracking explicitly chooses the current food")
equal(A.state.categories.food.upgrade, nil, "tracking acknowledges the available options")
A.state.level = 25
A.Update()
local newUpgrade = assert(A.state.categories.food.upgrade)
local survivalProfile = A.state.profile
A.state.profile = previousProfile
A.SetTrackedItem(A.Prefs("food"), 3664, A.state.categories.food)
A.Update()
equal(A.state.categories.food.upgrade, nil, "tracking at the current level acknowledges its options only for this spec")
A.SetTrackedItem(A.Prefs("food"))
A.state.profile = survivalProfile
A.Update()
equal(A.state.categories.food.upgrade.item.id, newUpgrade.item.id, "another spec cannot acknowledge this spec's upgrade")
equal(A.Prefs("elixir").trackedOptions, nil, "tracking food has no effect on other categories")
A.OpenCategory("food", newUpgrade.item.id)
equal(visibleItem(panel, "Heavy Crocolisk Stew").upgradeMark:IsShown(), true, "right-click destination reveals the unlocked upgrade")
equal(A.state.categories.food.upgrade.item.id, newUpgrade.item.id, "inspecting the upgrade does not dismiss it")
equal(panel.keepTracked:IsShown(), true, "the category offers a single action to keep the current item")
equal(panel.category.status[1].caption:GetText(), "Tracked item", "the pinned purchase is distinct from the suggested upgrade")
click(panel.keepTracked)
equal(A.Prefs("food").pin, 3664, "keeping the current item preserves its pin")
equal(A.state.categories.food.bag.item.id, 3664, "keeping the current item preserves its action")
equal(A.state.categories.food.upgrade, nil, "keeping the current item acknowledges the unlock")
equal(panel.keepTracked:IsShown(), false, "the keep button hides when there is no pending upgrade")
A.state.level = 35
A.Update()
local laterUpgrade = assert(A.state.categories.food.upgrade)
equal(laterUpgrade.item.id, 13932, "a later stronger unlock brings the alert back")
A.OpenCategory("food", laterUpgrade.item.id)
click(assert(visibleItem(panel, laterUpgrade.name)).action)
equal(A.Prefs("food").pin, laterUpgrade.item.id, "tracking a highlighted upgrade chooses that item")
click(panel.category.clear)
equal(A.Prefs("food").trackedOptions, nil, "use automatic discards the tracking history")
A.state.level, A.state.profile, bagCounts[3664] = previousLevel, previousProfile, nil
A.Update()

click(nav.elixirRegen)
equal(search:GetText(), "", "changing category clears search")
equal(panel.category.showUnusable.checked, false, "the unusable-item filter is stored per category")
equal(direct.pick.title:GetText(), "Set shortcut", "different category has its own shortcut")
search:Type("mp5")
equal(panel.category.searchRow.count:GetText(), "2 results", "stat alias matches eligible mana regeneration elixirs")
equal(panel.itemWidgets[1].category.key, "elixirRegen", "search is scoped to the current category")
equal(panel.itemWidgets[1].itemRow.eligible, true, "matches can be used at current level")
click(nav.draughtWaterBreathing)
search:Type("Breathe underwater")
equal(panel.category.searchRow.count:GetText(), "1 result", "search matches effect text for the new utility consumables")
equal(panel.itemWidgets[1].itemRow.item.id, 5996, "effect search omits the upcoming greater draught")

equal(nav.campfire.track.checked, false, "master reminder switch governs sidebar")
click(nav.campfire.track)
equal(A.db.reminders, true, "sidebar reminder switch enables master")
equal(A.Prefs("campfire").enabled, true, "sidebar enables this profile reminder")
click(nav.campfire)
equal(panel.category.reminder.title:GetText(), "Campfire kit ready", "owned campfire kit is ready")
click(direct.pick)
panel.capture:Fire("OnKeyDown", "C")
equal(A.GetBuffBinding("campfire"), "ALT-C", "reminders have independent shortcuts")
equal(A.GetBuffBinding("food"), "ALT-F", "reminder shortcut preserves food shortcut")
click(direct.clear)
equal(A.GetBuffBinding("campfire"), nil, "clear removes this buff’s shortcut")
equal(A.GetBuffBinding("food"), "ALT-F", "clear preserves other buff shortcuts")
assert(panel.category.reminder.detail:GetText():find("share another player", 1, true))
local camp = A.state.categories.campfire
camp.active, camp.expires, camp.activeIcon = "Camp Benefits", 1002, 98765
cooldownStart, cooldownDuration = 990, 30
local previousCooldownCalls = cooldownCalls
A.RefreshOptions()
equal(panel.category.reminder.title:GetText(), "Camp Benefits", "actual campfire aura replaces ready instructions")
equal(panel.category.reminder.detail:GetText(), "2s left", "active reminder shows its own duration")
equal(cooldownCalls, previousCooldownCalls, "active reminder skips the kit cooldown")
now = 1001
panel.category.reminder:Fire("OnUpdate")
equal(panel.category.reminder.detail:GetText(), "1s left", "reminder timer updates while the page stays open")
now = 1003
panel.category.reminder:Fire("OnUpdate")
equal(panel.category.reminder.title:GetText(), "Campfire kit ready", "expired campfire restores kit guidance")
click(nav.sleepingBag)
equal(panel.category.reminder.title:GetText(), "Requires Cozy Sleeping Bag in your bags.", "missing sleeping bag guidance")
local bag = A.state.categories.sleepingBag
bag.active, bag.expires = "Well-Rested", 1009
A.RefreshOptions()
equal(panel.category.reminder.title:GetText(), "Well-Rested", "actual sleeping bag aura precedes missing item guidance")
equal(panel.category.reminder.detail:GetText(), "6s left", "sleeping bag tracks the buff duration")
bag.bag = { item = A.catalog.sleepingBag[1], count = 1, name = "Cozy Sleeping Bag" }
previousCooldownCalls = cooldownCalls
A.RefreshOptions()
equal(cooldownCalls, previousCooldownCalls, "active sleeping bag never checks its cooldown")
now = 1010
panel.category.reminder:Fire("OnUpdate")
equal(panel.category.reminder.detail:GetText(), "Ready in 10s", "cooldown appears after Well-Rested expires")
cooldownStart, cooldownDuration = 0, 0
A.state.level = 60
A.Update()
equal(panel.category.reminder.title:GetText(), "Available through level 59.", "sleeping bag level cap")
equal(panel.category.showUnusable:IsShown(), true, "the filter remains visible on reminders with no usable items")
equal(visibleItem(panel, "Cozy Sleeping Bag"), nil, "an unusable reminder option is hidden by default")
click(panel.category.showUnusable)
equal(visibleItem(panel, "Cozy Sleeping Bag") ~= nil, true, "the filter can reveal an unusable reminder option")
A.db.reminders = false
A.Update()
click(panel.category.track)
equal(A.db.reminders, true, "detail reminder switch enables master")
equal(A.Prefs("sleepingBag").enabled, true, "detail enables this profile reminder")

click(nav.weaponOffhand)
equal(panel.heading:GetText(), "Off-Hand Stones & Oils", "off-hand stone and oil page name")
A.Prefs("weaponOffhand").enabled = true
A.Update()
equal(panel.subheading:GetText(), "Equip a compatible off-hand weapon", "off-hand gear guidance")
equal(panel.empty:GetText():find("Show unusable items", 1, true) ~= nil, true, "zero usable items explain the filter")
click(panel.category.showUnusable)
click(panel.itemWidgets[1].action)
equal(A.Prefs("weaponOffhand").pin, panel.itemWidgets[1].itemRow.item.id, "item tracking saves the off-hand preference")
equal(panel.itemWidgets[1].action.title:GetText(), "Tracked", "tracked row action text")
equal(A.Prefs("weapon").pin, nil, "off-hand preference preserves the main hand")
click(panel.category.clear)
equal(A.Prefs("weaponOffhand").pin, nil, "automatic selection clears the preference")

click(nav.general)
click(panel.general.reminderLinks.campfire)
equal(panel.heading:GetText(), "Campfire", "General links to Campfire when reminders are at the bottom")
click(direct.pick)
click(nav.general)
panel.capture:Fire("OnKeyDown", "R")
equal(A.GetBuffBinding("campfire"), nil, "navigating away cancels pending capture")
local directions = panel.general.directions
equal(directions.right.selected, true, "the bar grows right by default")
for _, direction in ipairs({"left", "up", "down", "right"}) do
    click(directions[direction])
    equal(A.db.barDirection, direction, "the selected growth direction is saved")
    for key, control in pairs(directions) do
        equal(control.selected, key == direction, "growth direction controls are mutually exclusive")
    end
end
equal(panel.general.checks.mouseoverOnly.checked, false, "mouseover-only visibility is off by default")
click(panel.general.checks.mouseoverOnly)
equal(A.db.mouseoverOnly, true, "mouseover-only visibility is saved")
equal(A.GetBuffBinding("food"), "ALT-F", "mouseover visibility preserves direct buff shortcuts")
click(panel.general.checks.collapsed)
equal(panel.general.checks.highlightMissing.checked, false, "collapsed-grip glow is off by default")
click(panel.general.checks.highlightMissing)
equal(A.db.collapsed, true, "collapse visibility preference")
equal(A.db.highlightMissing, true, "collapsed-grip glow preference")
click(panel.general.shortcut.pick)
panel.capture:Fire("OnKeyDown", "W")
equal(binding, "ALT-W", "keyboard shortcut capture")
equal(A.GetBuffBinding("food"), "ALT-F", "wheel shortcut preserves direct buff shortcuts")
local barShortcut = panel.general.barShortcut
click(barShortcut.pick)
panel.capture:Fire("OnKeyDown", "W")
equal(barBinding, nil, "bar toggle cannot reuse the wheel’s shortcut")
equal(barShortcut.status:GetText(), "ALT-W is already bound to the wheel.", "bar shortcut displays the conflict")
equal(panel.general.shortcut.status:GetText(), "Also available in WoW Keybindings.", "wheel status does not display the bar conflict")
click(barShortcut.pick)
panel.capture:Fire("OnKeyDown", "B")
equal(barBinding, "ALT-B", "bar toggle captures an independent shortcut")
click(barShortcut.clear)
equal(barBinding, nil, "bar toggle shortcut can be cleared")
equal(binding, "ALT-W", "clearing the bar shortcut preserves the wheel shortcut")
click(panel.general.preview)
equal(previews, 1, "preview opens the wheel")
combat = true
panel:Fire("OnEvent", "PLAYER_REGEN_DISABLED")
equal(panel.general.preview.enabled, false, "preview disabled in combat")
equal(panel.general.shortcut.pick.enabled, false, "wheel shortcut editing disabled in combat")
equal(barShortcut.pick.enabled, false, "bar toggle shortcut editing disabled in combat")
click(nav.food)
equal(direct.pick.enabled, false, "buff shortcut editing disabled in combat")
equal(direct.clear.enabled, false, "buff shortcut cannot be cleared in combat")
combat = false
panel:Fire("OnEvent", "PLAYER_REGEN_ENABLED")

click(nav.appearance)
local page = panel.appearance
local accent = page.colors.customAccent
equal(accent.mode:GetText(), "Class color", "accent follows class initially")
equal(accent.mode:GetWidth() > 350, true, "appearance description has concrete layout width")
equal(accent.mode:GetHeight() > accent.mode.fontSize, true, "appearance description has concrete layout height")
accent.pick:Fire("OnEnter")
click(accent.pick)
equal(A.db.customAccent, nil, "opening color picker retains class color")
ColorPickerFrame:Choose(0.2, 0.6, 1)
equal(A.db.customAccent[3], 1, "native picker saves live accent")
equal(nav.appearance.title.tint[3], A.theme.colors.mint[3], "active navigation follows accent immediately")
equal(accent.swatch.tint[3], 1, "swatch matches custom choice")
ColorPickerFrame.info.cancelFunc()
equal(A.db.customAccent, nil, "cancel restores the class color")

local background = page.colors.customBackground
click(background.pick)
ColorPickerFrame:Choose(0.24, 0.27, 0.3)
equal(A.db.customBackground[1], 0.24, "native picker saves live background")
equal(accent.pick.face.tint[1], A.theme.colors.hover[1], "hovered control follows background immediately")
equal(panel.category.reminder.title.tint[1], A.theme.colors.gold[1], "previously rendered state follows theme")
local startingSize = panel.heading.fontSize
page.scales.fontScale:SetValue(1.25, true)
equal(panel.heading.fontSize > startingSize, true, "font size updates live")
local wheelSetting = panel.general.checks.showWheel
local description = wheelSetting.description
local descriptionBottom = -description.points.TOPLEFT[2] + description:GetHeight()
equal(descriptionBottom <= wheelSetting:GetHeight(), true, "two lines of translated help fit at maximum text size")
local beforeBar, beforeWheel = actionRefreshes, wheelRefreshes
page.scales.barScale:SetValue(1.50, true)
equal(A.db.barScale, 1.50, "bar size persists")
equal(actionRefreshes, beforeBar + 1, "bar size refreshes live")
equal(wheelRefreshes, beforeWheel + 1, "wheel layout refreshes after size settings")
click(background.reset)
equal(A.db.customBackground, nil, "slate reset clears color")

UIParent:SetSize(720, 480)
panel:Fire("OnEvent", "DISPLAY_SIZE_CHANGED")
equal(panel:GetWidth() * panel.scale < UIParent:GetWidth(), true, "panel fits a narrow screen")
equal(panel:GetHeight() * panel.scale < UIParent:GetHeight(), true, "panel fits a short screen")
A.ToggleOptions()
A.ToggleOptions()
equal(panel.heading:GetText(), "Appearance", "reopening retains the current page")

local function openAs(class)
    A.ToggleOptions()
    A.state.class, A.state.profile = class, A.profiles[class][1]
    A.ApplyClassLabels(class)
    loadAddon("Options")
    A.Update()
    A.ToggleOptions()
    return indexNavigation(AlwaysBuffedOptionsPanel)
end

local rogueNav = openAs("ROGUE")
equal(sidebarOrder(AlwaysBuffedOptionsPanel, 7), "food,elixir,imbue,elixirAttackPower,scrollAgility,scrollStamina,weapon",
    "Rogue main-hand poison leads spec options with no off-hand equipped")
weapons[17] = "blunt"
A.Update()
equal(sidebarOrder(AlwaysBuffedOptionsPanel, 4), "food,elixir,imbue,imbueOffhand",
    "equipping an off-hand puts both Rogue poisons near the top")
weapons[17] = nil
A.Update()
equal(indexNavigation(AlwaysBuffedOptionsPanel).imbueOffhand, rogueNav.imbueOffhand,
    "unequipping the off-hand keeps its category browsable and reuses its row")
assert(rogueNav.imbue.title:GetText():find("Main%-Hand Poison"))
assert(rogueNav.imbueOffhand.title:GetText():find("Off%-Hand Poison"))
equal(rogueNav.weapon.title:GetText(), "MH Stones & Oils", "Rogue stone and oil page remains separate from poison")
click(rogueNav.imbueOffhand)
assert(AlwaysBuffedOptionsPanel.heading:GetText():find("Off%-Hand Poison"))
equal(AlwaysBuffedOptionsPanel.category.searchRow:IsShown(), true, "Rogue poison remains browsable without off-hand gear")

local mageNav = openAs("MAGE")
equal(mageNav.scrollFamiliar ~= nil, true, "Mage familiar scroll category is visible")
equal(mageNav.imbue ~= nil, true, "Mage weapon scroll category is visible")
equal(sidebarOrder(AlwaysBuffedOptionsPanel, 7), "food,elixir,scrollFamiliar,imbue,elixirRegen,scrollIntellect,weapon",
    "Mage places class buffs, mana support and intellect near the top")
click(mageNav.professions)
local mageProfessions = AlwaysBuffedOptionsPanel.professions
equal(mageProfessions.modes.comprehension ~= nil, true, "Mage can choose the class-specific profession mode")
equal(mageProfessions.links.comprehensionScroll ~= nil, true, "Mage can browse its class-specific profession category")
click(mageProfessions.modes.comprehension)
equal(mageProfessions.activeBar:GetText(), "Active bar: Comprehension", "Mage can activate the class-specific bar")
click(mageProfessions.modes.auto)

openAs("PRIEST")
A.state.profile = A.profiles.PRIEST[3]
A.Update()
equal(sidebarOrder(AlwaysBuffedOptionsPanel, 6), "food,elixir,elixirRegen,scrollIntellect,scrollSpirit,weapon",
    "Holy Priest puts both recommended spellcasting scrolls near the top")

A.ToggleOptions()
function GetLocale() return "ruRU" end
for _, filename in ipairs({ "Locale", "Locales/ruRU", "Catalog", "Categories", "Profiles", "Planner", "Theme", "Status", "Options" }) do
    loadAddon(filename)
end
A.state.class, A.state.profile = "HUNTER", A.profiles.HUNTER[1]
A.ApplyClassLabels(A.state.class)
A.Update()
A.ToggleOptions()
panel = AlwaysBuffedOptionsPanel
nav = indexNavigation(panel)
equal(panel.heading:GetText(), "Список покупок", "Russian shopping heading")
equal(nav.food.title:GetText(), "Еда", "Russian category navigation")
equal(panel.heading.font, STANDARD_TEXT_FONT, "native glyph coverage for Russian")

local tooltipTitle, tooltipDetail
function GameTooltip:SetText(text) tooltipTitle = text end
function GameTooltip:AddLine(text) tooltipDetail = text end
nav.food.title.IsTruncated = function() return true end
nav.food:Fire("OnEnter")
equal(tooltipTitle, "Еда", "clipped navigation exposes the complete label")
click(nav.food)
local showUnusable = panel.category.showUnusable
showUnusable.title.IsTruncated = function() return true end
showUnusable:Fire("OnEnter")
equal(tooltipTitle, showUnusable.title:GetText(), "clipped checkbox exposes the complete label")
equal(tooltipDetail, showUnusable.hint, "clipped checkbox keeps the existing help text")
panel.category.search:Type("Mithril Head Trout")
equal(panel.category.searchRow.count:GetText(), "Результатов: 1", "Russian search result count")

print(("%d options checks passed"):format(checks))
