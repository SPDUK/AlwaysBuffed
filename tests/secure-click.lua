-- Execute the addon's registered SecureHandlerClickTemplate snippet in Lua 5.1.
-- The mock models dispatch and the combat boundary, not the client's taint engine.
local click = {}
local frames = {}

function click.SetFrameRef(frame, name, target)
    assert(not InCombatLockdown(), "secure frame reference changed during combat")
    assert(target.protected, "secure click frame reference must target a protected frame")
    frames[frame] = frames[frame] or {}
    frames[frame][name] = target
end

local function handle(frame)
    if not frame then return end
    local methods = {}
    function methods:GetFrameRef(name) return handle(frames[frame] and frames[frame][name]) end
    function methods:IsShown() return frame:IsShown() end
    function methods:Show() frame:Show() end
    function methods:Hide() frame:Hide() end
    function methods:GetAttribute(key)
        assert(not key:match("^_"))
        return frame:GetAttribute(key)
    end
    function methods:SetAttribute(key, value)
        assert(not key:match("^_"))
        frame:SetAttribute(key, value)
    end
    function methods:CallMethod(name, ...)
        click.running = false
        frame[name](frame, ...)
        click.running = true
    end
    return methods
end

function click.press(frame, button, down)
    if not frame:IsVisible() then return end
    local edge, registered = down and "Down" or "Up", false
    for _, event in ipairs(frame.clicks or {}) do
        if event == button .. edge or event == "Any" .. edge then registered = true end
    end
    if not registered then return end
    assert(frame.template == "SecureHandlerClickTemplate", "expected a native secure click template")
    assert(not frame.scripts.OnClick, "an insecure OnClick replaces the inherited secure dispatch")
    local snippet = assert(frame:GetAttribute("_onclick"), "native template has no click snippet")
    local run = assert(loadstring(snippet, "SecureHandlerClickTemplate _onclick"))
    setfenv(run, {self = handle(frame), button = button, down = down,
        IsShiftKeyDown = IsShiftKeyDown, IsControlKeyDown = IsControlKeyDown, IsAltKeyDown = IsAltKeyDown})
    click.running = true
    run()
    click.running = false
    if frame.scripts.PostClick then frame.scripts.PostClick(frame, button, down) end
end

return click
