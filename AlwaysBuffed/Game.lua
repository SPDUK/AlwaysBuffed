local _, A = ...

local G = {}
A.game = G

function G.TalentPoints()
    local points = {}
    local config = C_ClassTalents.GetActiveConfigID()
    local info = config and C_Traits.GetConfigInfo(config)
    local tree = info and info.treeIDs and info.treeIDs[1]
    if tree then
        for _, group in ipairs(C_Traits.GetGroupDisplayInfoByTreeID(tree) or {}) do
            local currencies = C_Traits.GetGroupCurrencyInfo(config, {group.groupID})
            local first = currencies and currencies[1]
            local amount = first and first.currencyInfos and first.currencyInfos[1]
            points[group.groupID] = amount and amount.spent or 0
        end
    end
    return points
end

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

-- Numeric weapon subclasses are locale independent. Only melee weapons can
-- receive these enhancements, even when an armor item occupies the off hand.
local sharp = {[0]=true, [1]=true, [6]=true, [7]=true, [8]=true, [15]=true}
local blunt = {[4]=true, [5]=true, [10]=true, [13]=true}
local function weaponType(slot)
    local ok, id = pcall(GetInventoryItemID, "player", slot)
    if not ok or not readable(id) then return end
    if not id then return nil, nil, true end
    local gotInfo, _, _, _, _, _, class, sub = pcall(C_Item.GetItemInfoInstant, id)
    if not gotInfo or not readable(class) or not readable(sub) or class == nil or sub == nil then return end
    if class == 2 then
        if sharp[sub] then return "sharp", sub end
        if blunt[sub] then return "blunt", sub end
    end
    return nil, nil, true
end

local function unitPrice(id)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if api and api.GetAuctionPriceByItemID then
        local price = api.GetAuctionPriceByItemID("AlwaysBuffed", id)
        if type(price) == "number" and price > 0 then return price end
    end
end

local pending = {}
local function requestItem(id)
    if not pending[id] then
        pending[id] = true
        C_Item.RequestLoadItemDataByID(id)
    end
end

function G.ItemArrived(id)
    local requested = pending[id]
    pending[id] = nil
    return requested
end

local function itemDetails(item)
    if item.spell then
        local spell = C_Spell.GetSpellInfo(item.spell)
        return {name = spell and spell.name, icon = spell and spell.iconID}
    end
    local id = item.id
    local name, icon, required
    if C_Item.IsItemDataCachedByID(id) then
        local itemName, _, _, _, level, _, _, _, _, texture = C_Item.GetItemInfo(id)
        name, icon, required = itemName, texture, level
    else
        requestItem(id)
        icon = select(5, C_Item.GetItemInfoInstant(id))
    end
    return {
        name = name, icon = icon, level = math.max(item.level, required or 0),
        count = C_Item.GetItemCount(id, false, false, false, false),
        price = not item.ownedOnly and not item.isBasic and unitPrice(id) or nil,
    }
end

function G.Context(class, level, reminders)
    local ranks, details = {}, {}
    local mainHand, mainSubclass = weaponType(16)
    local offHand, offSubclass = weaponType(17)
    return {
        class = class, level = level, weapons = {[16] = mainHand, [17] = offHand},
        weaponSubclasses = {[16] = mainSubclass, [17] = offSubclass},
        reminders = reminders, known = C_SpellBook.IsSpellKnown,
        info = function(item)
            if not details[item] then details[item] = itemDetails(item) end
            return details[item]
        end,
        skill = function(id)
            if ranks[id] == nil then
                local line = C_SkillInfo.GetSkillLineInfoByID(id)
                ranks[id] = line and line.rank or 0
            end
            return ranks[id]
        end,
    }
end

local indexedFood
function G.FoodWithBagFallback(catalog)
    if not indexedFood then
        indexedFood = {}
        for _, item in ipairs(catalog) do indexedFood[item.id] = true end
    end
    -- Food and drinks share one item subclass. Match localized eating spells
    -- to avoid putting water, alcohol, recipes or pet treats on the food button.
    local useNames = {}
    for _, spell in ipairs({433, 1248377}) do
        local name = C_Spell.GetSpellName(spell)
        if name then useNames[name] = true end
    end
    local found, extra = {}, {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id and not indexedFood[id] and not found[id] then
                found[id] = true
                local _, _, _, _, _, class, sub = C_Item.GetItemInfoInstant(id)
                if class == 0 and sub == 5 then
                    if C_Item.IsItemDataCachedByID(id) then
                        local use = C_Item.GetItemSpell(id)
                        if use and useNames[use] then
                            local name, _, _, _, level = C_Item.GetItemInfo(id)
                            if name then
                                extra[#extra + 1] = {id = id, name = name, level = math.max(1, level or 0),
                                    stats = {}, isBasic = true, ownedOnly = true, note = "Bag food fallback"}
                            end
                        end
                    else
                        requestItem(id)
                    end
                end
            end
        end
    end
    if #extra == 0 then return catalog end
    for _, item in ipairs(catalog) do extra[#extra + 1] = item end
    return extra
end

local function numberField(value)
    if readable(value) and type(value) == "number" then return value end
end

local function indexAura(ids, names, aura)
    if not readable(aura) or type(aura) ~= "table" then return false end
    local id = numberField(aura.spellId)
    local name = readable(aura.name) and aura.name or nil
    if id then ids[id] = aura end
    if name then names[name] = aura end
    return id ~= nil and name ~= nil
end

function G.AuraIndex()
    local limit = 255
    local ids, names, complete = {}, {}, true
    local bulk = C_UnitAuras.GetUnitAuras
    if bulk then
        local ok, list = pcall(bulk, "player", "HELPFUL", limit)
        if not ok or not readable(list) or type(list) ~= "table" then return ids, names, false end
        for index = 1, #list do
            if not indexAura(ids, names, list[index]) then complete = false end
        end
        return ids, names, complete and #list < limit
    end
    for index = 1, limit do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
        if not ok then break end
        if readable(aura) and aura == nil then return ids, names, complete end
        if not indexAura(ids, names, aura) then complete = false end
    end
    return ids, names, false
end

function G.RemovedAuras(update, removed)
    if not readable(update) or type(update) ~= "table" then return end
    local ids = update.removedAuraInstanceIDs
    if not readable(ids) or type(ids) ~= "table" then return end
    for index = 1, #ids do
        local id = numberField(ids[index])
        if id then removed[id] = true end
    end
end

-- Presence, timing and identity are independently readable. Only a complete
-- scan or an explicit removal can prove that a previously tracked aura is gone.
local function effect(aura, fallback, defaultIcon, expectedID)
    local expires = numberField(aura.expirationTime)
    if expires and expires > 0 and expires <= GetTime() then return end
    local name = readable(aura.name) and aura.name or nil
    if not name or name == "" then
        name = expectedID and C_Spell.GetSpellName(expectedID)
        if not readable(name) or not name or name == "" then name = fallback end
    end
    local stacks = numberField(aura.applications)
    local icon = numberField(aura.icon)
    if stacks and stacks > 1 then name = name .. " ×" .. stacks end
    return name, expires and expires > 0 and expires or nil,
        icon and icon > 0 and icon or defaultIcon, numberField(aura.spellId) or expectedID,
        numberField(aura.duration), nil, stacks, expires ~= nil, numberField(aura.auraInstanceID)
end

local function reminderAura(id, indexed, fallback, icon, complete)
    local lookup = C_UnitAuras.GetPlayerAuraBySpellID
    -- Some reminder auras are visible only to the direct spell lookup.
    local absent = not lookup and complete
    if lookup then
        local ok, aura = pcall(lookup, id)
        if ok and readable(aura) then
            if aura then
                local name, expires, texture, spellID, duration, _, stacks, timed, instance = effect(aura, fallback, icon, id)
                if name then return name, expires, texture, spellID, duration, nil, stacks, timed, instance end
            end
            absent = true
        end
    end
    local aura = indexed and indexed[id]
    if aura then
        local name, expires, texture, spellID, duration, _, stacks, timed, instance = effect(aura, fallback, icon, id)
        if name then return name, expires, texture, spellID, duration, nil, stacks, timed, instance end
    end
    return nil, nil, nil, nil, nil, absent
end

function G.PendingEffect(category, ids, complete)
    local auraIDs = category.pendingAuras
    if not auraIDs then return end
    local allAbsent = true
    for _, id in ipairs(auraIDs) do
        local name, expires, icon, spellID, duration, absent, _, timed, instance =
            reminderAura(id, ids, "Welcoming Campfire", category.icon, complete)
        if name then return name, expires, icon, spellID, duration, nil, nil, timed, instance end
        allAbsent = allAbsent and absent
    end
    return nil, nil, nil, nil, nil, allAbsent
end

local function weaponEnchants(slot)
    local weapon, _, empty = weaponType(slot)
    if not weapon then return empty and {} or false end
    local weaponSlot = slot == 17 and Enum.WeaponSlot.OffHand or Enum.WeaponSlot.MainHand
    local ok, list = pcall(C_Item.GetWeaponEnchantInfo, weaponSlot)
    if ok and readable(list) and type(list) == "table" then return list end
    return false
end

local function weaponEffect(category, rows, cache)
    local slot = category.slot
    if cache[slot] == nil then cache[slot] = weaponEnchants(slot) end
    local list = cache[slot]
    if not list then return end
    if not next(list) then return nil, nil, nil, nil, nil, true end
    local kind = category.slotType == "imbue" and Enum.ItemEnchantType.Imbue or Enum.ItemEnchantType.Temporary
    local complete = true
    for index = 1, #list do
        local e = list[index]
        if not readable(e) or type(e) ~= "table" then
            complete = false
        else
            local enchantType = numberField(e.enchantType)
            local hasEnchant
            if readable(e.hasEnchant) then hasEnchant = e.hasEnchant end
            if hasEnchant ~= false and not enchantType then
                complete = false
            elseif enchantType == kind and hasEnchant == nil then
                complete = false
            elseif enchantType == kind and hasEnchant then
                local left, enchant = numberField(e.timeLeft), numberField(e.enchantID)
                if not left or left > 0 then
                    local name = category.label
                    if enchant then
                        for _, row in ipairs(rows) do
                            if row.item.enchant == enchant then name = row.name break end
                        end
                    end
                    local icon = numberField(e.enchantIconID)
                    return name, left and GetTime() + left / 1000 or nil, icon and icon > 0 and icon or nil,
                        nil, nil, nil, nil, left ~= nil, enchant
                end
            end
        end
    end
    return nil, nil, nil, nil, nil, complete
end

function G.ActiveEffect(category, rows, ids, names, complete, weaponCache)
    if category.kind == "weapon" then return weaponEffect(category, rows, weaponCache or {}) end
    local activeAura = category.activeAura
    if activeAura then return reminderAura(activeAura.id, ids, activeAura.name, activeAura.icon, complete) end
    for _, row in ipairs(rows) do
        for _, id in ipairs(row.item.auras or {}) do
            if ids[id] then
                local name, expires, icon, spellID, duration, _, stacks, timed, instance = effect(ids[id], row.name)
                if name then return name, expires, icon, spellID, duration, nil, stacks, timed, instance end
            end
        end
        for _, name in ipairs(row.item.auraNames or {}) do
            if names[name] then
                local active, expires, icon, spellID, duration, _, stacks, timed, instance = effect(names[name], row.name)
                if active then return active, expires, icon, spellID, duration, nil, stacks, timed, instance end
            end
        end
    end
    if category.kind == "food" then
        local wellFed = C_Spell.GetSpellName(19705)
        if readable(wellFed) and wellFed and names[wellFed] then
            local name, expires, icon, spellID, duration, _, stacks, timed, instance = effect(names[wellFed], wellFed)
            if name then return name, expires, icon, spellID, duration, nil, stacks, timed, instance end
        end
    end
    return nil, nil, nil, nil, nil, complete
end
