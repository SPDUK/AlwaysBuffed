local _, A = ...

-- A state color over item artwork. The class accent remains the selection color.
A.activeBorderColor = { 1, 0.80, 0.22 }

function A.BuffDuration(seconds, compact)
    seconds = math.max(0, math.ceil(seconds))
    if seconds >= 3600 then
        local hours = math.floor(seconds / 3600)
        if compact then return math.ceil(seconds / 3600) .. "h" end
        if seconds % 3600 < 60 then return hours .. "h" end
        return ("%dh %02dm"):format(hours, math.floor(seconds / 60) % 60)
    end
    if seconds >= 60 then
        local minutes = math.floor(seconds / 60)
        if compact then return math.ceil(seconds / 60) .. "m" end
        if seconds % 60 == 0 then return minutes .. "m" end
        return ("%dm %02ds"):format(minutes, seconds % 60)
    end
    return seconds .. "s"
end

function A.EffectIsCurrent(name, expires, now)
    return name ~= nil and name ~= false and (not expires or expires <= 0 or expires > now)
end

function A.ReminderCooldown(category, row, now)
    if category.key ~= "sleepingBag" or not row or not row.item or not row.item.id then return end
    local read = (C_Container and C_Container.GetItemCooldown) or (C_Item and C_Item.GetItemCooldown)
    if not read then return end
    local start, duration, enabled = read(row.item.id)
    if issecretvalue and (issecretvalue(start) or issecretvalue(duration) or issecretvalue(enabled)) then return end
    if enabled == false or enabled == 0 or not start or not duration or start <= 0 or duration <= 1.6 then return end
    if start + duration > now then return start, duration, start + duration end
end

function A.ReminderStatus(category, state, now)
    if A.EffectIsCurrent(state.active, state.expires, now) then
        local detail = state.expires and state.expires > 0 and A.BuffDuration(state.expires - now) .. " left" or "Active"
        if state.violetCamp then detail = "Violet · " .. detail end
        return state.active, detail, "active", state.activeIcon
    end
    if A.EffectIsCurrent(state.pending, state.pendingExpires, now) then
        local detail = state.pendingExpires and state.pendingExpires > 0 and
            ("Settling · " .. A.BuffDuration(state.pendingExpires - now, true)) or "Settling in"
        return state.pending, detail, "pending", state.pendingIcon
    end
    local _, _, readyAt = A.ReminderCooldown(category, state.bag, now)
    if readyAt then return category.label, "Ready in " .. A.BuffDuration(readyAt - now), "cooldown" end
    if state.bag then return category.label, "Ready to use", "ready" end
    return category.label, category.key == "campfire" and "Find a campfire" or "Not in bags", "missing"
end
