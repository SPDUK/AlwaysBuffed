local _, A = ...

local weaponBuffs = {
    ROGUE = { "Poison", "Poison" },
    SHAMAN = { "Weapon Imbue", "Imbue" },
    MAGE = { "Weapon Scroll", "Scroll" },
    WARLOCK = { "Weapon Stone", "Stone" },
}

function A.ApplyClassLabels(class)
    local family = weaponBuffs[class] or { "Weapon Imbue", "Imbue" }
    for _, category in ipairs(A.categories) do
        local hand = category.slot == 17 and "Off-Hand " or "Main-Hand "
        if category.slotType == "imbue" then
            category.label = hand .. family[1]
            category.shortLabel = hand .. family[2]
        elseif category.kind == "weapon" and category.slot then
            category.label = hand .. "Stones & Oils"
            category.shortLabel = (category.slot == 17 and "OH" or "MH") .. " Stones & Oils"
        end
    end
end

function A.CategoryForClass(category, class)
    if category.class then return category.class == class end
    -- Check catalog membership independently of level, bags and equipment.
    for _, item in ipairs(A.catalog[category.key] or {}) do
        if not item.class or item.class == class then return true end
    end
    return false
end
