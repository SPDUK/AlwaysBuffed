local _, A = ...
local L = A.L

A.professions = {
    {key = "fishing", label = L["Fishing"]},
    {key = "herbalism", label = L["Herbalism"]},
    {key = "mining", label = L["Mining"]},
    {key = "comprehension", label = L["Comprehension"], class = "MAGE"},
}

function A.BarModeLabel(mode)
    if mode == "auto" then return L["Automatic"] end
    for _, profession in ipairs(A.professions) do
        if profession.key == mode then return profession.label end
    end
    return L["Combat"]
end

function A.OnActiveBar(category)
    return category.profession == A.state.barProfession
end

local generic = { L["Main-Hand Weapon Imbue"], L["Off-Hand Weapon Imbue"], L["Main-Hand Imbue"], L["Off-Hand Imbue"] }
local weaponBuffs = {
    ROGUE = { L["Main-Hand Poison"], L["Off-Hand Poison"] },
    MAGE = { L["Main-Hand Weapon Scroll"], L["Off-Hand Weapon Scroll"], L["Main-Hand Scroll"], L["Off-Hand Scroll"] },
    WARLOCK = { L["Main-Hand Weapon Stone"], L["Off-Hand Weapon Stone"], L["Main-Hand Stone"], L["Off-Hand Stone"] },
}

function A.ApplyClassLabels(class)
    local family = weaponBuffs[class] or generic
    for _, category in ipairs(A.categories) do
        local offHand = category.slot == 17
        if category.slotType == "imbue" then
            local hand = offHand and 2 or 1
            category.label = family[hand]
            category.shortLabel = family[hand + 2] or category.label
        elseif category.kind == "weapon" and category.slot and not category.profession then
            category.label = offHand and L["Off-Hand Stones & Oils"] or L["Main-Hand Stones & Oils"]
            category.shortLabel = offHand and L["OH Stones & Oils"] or L["MH Stones & Oils"]
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
