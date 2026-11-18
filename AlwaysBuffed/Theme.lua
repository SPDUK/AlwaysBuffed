local _, A = ...
local T = { colors = {} }
A.theme = T
local callbacks, fonts = {}, setmetatable({}, { __mode = "k" })
local base = { 0.085, 0.100, 0.122 }
local white, black = { 0.96, 0.97, 0.99 }, { 0.035, 0.045, 0.058 }
local fallbackAccent = { 0.67, 0.83, 0.45 }
local folder = "Interface\\AddOns\\AlwaysBuffed\\Media\\Barlow\\Barlow-"
local nativeFont = ({ koKR=true, zhCN=true, zhTW=true, ruRU=true })[GetLocale()]

local function valid(color)
    if type(color) ~= "table" then return false end
    for i = 1, 3 do
        if type(color[i]) ~= "number" or not (color[i] >= 0 and color[i] <= 1) then return false end
    end
    return true
end

local function blend(name, a, b, amount)
    local c = T.colors[name] or {}
    for i = 1, 3 do c[i] = a[i] + (b[i] - a[i]) * amount end
    T.colors[name] = c
    return c
end

local function luminance(c)
    local function linear(v) return v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * linear(c[1]) + 0.7152 * linear(c[2]) + 0.0722 * linear(c[3])
end

local function readableTone(name, color, towards, backgroundLuminance)
    local mix, tone = 0, blend(name, color, towards, 0)
    local lum = luminance(tone)
    while mix < 1 and (math.max(lum, backgroundLuminance) + 0.05) / (math.min(lum, backgroundLuminance) + 0.05) < 4.5 do
        mix = math.min(1, mix + 0.06)
        tone = blend(name, color, towards, mix)
        lum = luminance(tone)
    end
    return tone
end

local function applyFont(fs, spec)
    local face = nativeFont and STANDARD_TEXT_FONT or folder .. (spec.strong and "Bold.ttf" or "SemiBold.ttf")
    local size = math.floor(spec.size * (A.db and A.db.fontScale or 1) + 0.5)
    if spec.maxSize then size = math.min(size, spec.maxSize) end
    if not fs:SetFont(face, size, spec.flags) then fs:SetFont(STANDARD_TEXT_FONT, size, spec.flags) end
end

function T.Font(fs, size, strong, flags, maxSize)
    local spec = { size = size, strong = strong, flags = flags or "", maxSize = maxSize }
    fonts[fs] = spec
    applyFont(fs, spec)
    return fs
end

function T.OnChange(fn) callbacks[#callbacks + 1] = fn end

function T.Refresh()
    local db = A.db or {}
    if db.customAccent and not valid(db.customAccent) then db.customAccent = nil end
    if db.customBackground and not valid(db.customBackground) then db.customBackground = nil end
    local class = A.state and A.state.class or select(2, UnitClass("player"))
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local accent = db.customAccent
        or (classColor and { classColor.r, classColor.g, classColor.b }) or fallbackAccent
    local panel = db.customBackground or base
    local light = luminance(panel) > 0.25
    local fg = light and black or white
    blend("panel", panel, panel, 0)
    blend("sidebar", panel, black, light and 0.06 or 0.32)
    blend("raised", panel, fg, light and 0.045 or 0.048)
    blend("hover", panel, fg, 0.12)
    blend("line", panel, fg, 0.13)
    blend("edge", panel, fg, 0.24)
    blend("selected", panel, accent, light and 0.21 or 0.20)
    blend("text", fg, fg, 0)
    blend("muted", fg, panel, 0.24)
    blend("accent", accent, accent, 0)
    -- Preserve the chosen hue while lifting or darkening lettering for the surface.
    local bgLum = luminance(panel)
    local tone = readableTone("mint", accent, fg, bgLum)
    if bgLum > 0.18 then
        readableTone("missing", {0.59, 0.33, 0.34}, {0, 0, 0}, bgLum)
    else
        readableTone("missing", {0.92, 0.65, 0.64}, {1, 1, 1}, bgLum)
    end
    local ink = luminance(tone) > 0.19 and black or white
    blend("ink", ink, ink, 0)
    local gold = light and { 0.42, 0.28, 0.09 } or { 0.96, 0.79, 0.49 }
    blend("gold", gold, gold, 0)
    for fs, spec in pairs(fonts) do applyFont(fs, spec) end
    for _, callback in ipairs(callbacks) do callback() end
end
T.Refresh()
