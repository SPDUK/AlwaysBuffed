-- Check the language files shipped in the release manifest. Run from the repository root.
local root = "AlwaysBuffed/"
local localeFiles, sourceKeys, bundled = {}, {}, {}
for line in io.lines(root .. "AlwaysBuffed.toc") do
    local file = line:match("^%s*([%w_/]+%.lua)%s*$")
    if file then
        local locale = file:match("^Locales/(%w+)%.lua$")
        if locale then
            assert(not bundled[locale], "Duplicate locale in manifest: " .. locale)
            bundled[locale] = true
            localeFiles[#localeFiles + 1] = {code = locale, file = file}
        else
            local source = assert(io.open(root .. file, "r"))
            for key in source:read("*a"):gmatch('L%["([^"\n]+)"%]') do sourceKeys[key] = true end
            source:close()
        end
    end
end
assert(sourceKeys["Icons grow"])
for _, code in ipairs({"deDE", "esES", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW"}) do
    assert(bundled[code], "Missing locale in manifest: " .. code)
end

local function loadLocale(code)
    GetLocale = function() return code end
    local A = {}
    assert(loadfile(root .. "Locale.lua"))("AlwaysBuffed", A)
    for _, entry in ipairs(localeFiles) do
        assert(loadfile(root .. entry.file))("AlwaysBuffed", A)
    end
    return A
end

-- Skip literal percentages in prose, such as "30% chance". Exercise the
-- translated format strings with the same arguments their callers supply.
local function signature(text)
    local tokens, args = {}, {}
    for spec in text:gmatch("%%[-+0-9.]*[dgfs%%]") do
        tokens[#tokens + 1] = spec
        if spec ~= "%%" then args[#args + 1] = spec:sub(-1) == "s" and "Buff" or 7 end
    end
    return table.concat(tokens), args
end

local count = 0
for key in pairs(sourceKeys) do count = count + 1 end
for _, entry in ipairs(localeFiles) do
    local L = loadLocale(entry.code).L
    for key in pairs(sourceKeys) do
        local translated = rawget(L, key)
        local message = entry.code .. " / " .. key
        assert(type(translated) == "string" and translated ~= "", "Missing translation: " .. message)
        local expected, args = signature(key)
        assert(signature(translated) == expected, "Changed format placeholders: " .. message)
        if #args > 0 then assert(string.format(translated, unpack(args)), message) end
    end
    for key in pairs(L) do assert(sourceKeys[key], "Unused translation: " .. entry.code .. " / " .. key) end
    assert(L["An untranslated phrase"] == "An untranslated phrase")
end
for _, code in ipairs({"enUS", "enGB", "unknown"}) do
    local L = loadLocale(code).L
    assert(not next(L) and L["Icons grow"] == "Icons grow", code)
end
for regional, shared in pairs({esMX = "esES", ptPT = "ptBR"}) do
    local L, expected = loadLocale(regional).L, loadLocale(shared).L
    assert(rawget(L, "Food") and L["Food"] == expected["Food"], regional)
end
print(("%d source strings checked in %d language files; regional aliases and English fallback passed"):format(count, #localeFiles))
