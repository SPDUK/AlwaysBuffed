local _, A = ...

local function adjust(base, changes)
    local weights = {}
    for stat, value in pairs(base) do weights[stat] = value end
    for stat, value in pairs(changes) do weights[stat] = value end
    return weights
end

local defense = {
    sta = 0.31, hp = 0.022, armor = 0.013, hp5 = 0.12, resist = 0.24, shadowResist = 0.22,
    fireResist = 0.22, frostResist = 0.22, defense = 0.55, dodge = 2.0, thorns = 0.15, reactiveDamageTaken = 0.12,
}
local mana = adjust(defense, { int = 0.20, spi = 0.27, mp5 = 0.62, mana = 0.009 })
local offHeal = adjust(mana, { heal = 0.14 })
local casterSupport = adjust(mana, {
    fire = 0.12, frost = 0.12, arcane = 0.12, movementSlow = 0.06, attackSlow = 0.08, freezeProc = 0.12,
    fireBlastReset = 0.19, wandHasteProc = 0.24, manaOnHitProc = 0.32,
})
local healerSupport = adjust(mana, { spell = 0.20 })
local rogueUtility = adjust(defense, { movementSlow = 0.16, castSlow = 0.14, healingReduction = 0.18 })
local shamanUtility = adjust(offHeal, { frostbrand = 0.12 })
local warlockUtility = adjust(mana, { hp = 0.032, hp5 = 0.24, fire = 0.22 })

local function profile(key, label, talentGroupID, talentTab, weights, categories, utilityWeights)
    local tracked = { food = true, elixir = true, campfire = true, sleepingBag = true }
    tracked.weapon = (weights.weapon or 0) > 0 or (weights.spell or 0) > 0 or (weights.heal or 0) > 0
    tracked.weaponOffhand = tracked.weapon
    tracked.elixirAttackPower = (weights.map or 0) > 0
    for _, category in ipairs(categories) do tracked[category] = true end
    return {
        key = key, label = label, talentGroupID = talentGroupID, talentTab = talentTab,
        weights = weights, utilityWeights = utilityWeights or defense, tracked = tracked,
    }
end

-- Forever talent sources and the rationale for each preset are in docs/spec-rankings.md.
local strength = {
    str = 1.00, agi = 0.56, ap = 0.46, map = 0.46, phys = 0.68, weapon = 2.10, meleeFireProc = 1.0,
    crit = 4.1, weaponCrit = 4.1, hit = 4.7, haste = 3.0, xp = 1.15,
}
local agility = adjust(strength, { str = 0.39, agi = 1.0, poison = 0.22 })
local ranged = {
    agi = 1.0, ap = 0.52, rap = 0.52, phys = 0.68, crit = 4.3, hit = 4.9, haste = 2.7, xp = 1.15,
}
local caster = {
    int = 0.72, spell = 0.80, spellCrit = 4.1, crit = 3.7, hit = 4.4, haste = 4.0,
    arcaneSpellProc = 0.38, xp = 1.15,
}
local healer = {
    int = 0.83, spi = 0.61, heal = 0.95, spellCrit = 3.0, crit = 3.0,
    haste = 3.5, mp5 = 1.12, mana = 0.017, xp = 1.05,
}
local tank = {
    str = 0.75, agi = 0.72, sta = 1.20, ap = 0.36, map = 0.36, phys = 0.51, weapon = 1.7, meleeFireProc = 0.85,
    crit = 2.4, weaponCrit = 2.4, hit = 3.5, haste = 2.3, hp = 0.095, armor = 0.046,
    defense = 0.95, dodge = 4.5, xp = 1.0,
}

local meleeScroll = { "scrollStrength", "scrollStamina" }
local agilityScroll = { "scrollAgility", "scrollStamina" }
local rogueBuffs = { "scrollAgility", "scrollStamina", "imbue", "imbueOffhand" }
local casterBuffs = { "scrollIntellect", "elixirRegen" }
local healerBuffs = { "scrollIntellect", "scrollSpirit", "elixirRegen" }
local shamanWeapons = { "scrollStrength", "scrollStamina", "imbue", "imbueOffhand" }
local shamanCaster = { "scrollIntellect", "elixirRegen", "imbue" }
local shamanHealer = { "scrollIntellect", "scrollSpirit", "elixirRegen", "imbue" }
local mageBuffs = { "scrollIntellect", "elixirRegen", "scrollFamiliar", "imbue" }
local warlockBuffs = { "scrollIntellect", "scrollStamina", "imbue" }
local tankBuffs = { "scrollStamina", "scrollProtection", "elixirDefense" }

-- The first entry is the leveling default until there are committed talent points.
A.profiles = {
    WARRIOR = {
        profile("arms", "Arms", 11650, 1, adjust(strength, { weapon = 2.4, crit = 4.5 }), meleeScroll),
        profile("fury", "Fury", 11657, 2,
            adjust(strength, { agi = 0.77, crit = 5.5, haste = 4.1, hit = 5.4 }), meleeScroll),
        profile("protection", "Protection", 11670, 3, tank, tankBuffs),
    },
    PALADIN = {
        profile("retribution", "Retribution", 11559, 3,
            adjust(strength, { int = 0.42, holy = 0.66, spell = 0.38, weapon = 2.25 }), meleeScroll, offHeal),
        profile("holy", "Holy", 11486, 1,
            adjust(healer, { holy = 0.52, spi = 0.72, spellCrit = 4.2 }), healerBuffs, healerSupport),
        profile("protection", "Protection", 11541, 2,
            adjust(tank, { int = 0.43, spell = 0.61, holy = 0.74, armor = 0.055 }), tankBuffs, offHeal),
    },
    HUNTER = {
        profile("beastMastery", "Beast Mastery", 11372, 1, ranged, agilityScroll, mana),
        profile("marksmanship", "Marksmanship", 11371, 2,
            adjust(ranged, { int = 0.49, crit = 5.35, rap = 0.58 }), agilityScroll, mana),
        profile("survival", "Survival", 11370, 3,
            adjust(strength, { str = 0.46, agi = 1.12, ap = 0.53, map = 0.54, weapon = 2.0, phys = 0.77 }),
            agilityScroll, adjust(defense, { rap = 0.17 })),
    },
    ROGUE = {
        profile("combat", "Combat", 11573, 2,
            adjust(agility, { weapon = 2.30, hit = 5.25, haste = 3.55 }), rogueBuffs, rogueUtility),
        profile("assassination", "Assassination", 11580, 1,
            adjust(agility, { poison = 0.36, crit = 4.7 }), rogueBuffs, rogueUtility),
        profile("subtlety", "Subtlety", 11572, 3,
            adjust(agility, { weapon = 2.40, crit = 4.8, phys = 0.80 }), rogueBuffs, rogueUtility),
    },
    PRIEST = {
        profile("shadow", "Shadow", 11622, 3,
            adjust(caster, { shadow = 1.02, spellCrit = 3.65 }), casterBuffs, adjust(mana, { spi = 0.47 })),
        profile("discipline", "Discipline", 11608, 1,
            adjust(healer, { spell = 0.46, holy = 0.52, int = 0.96 }), healerBuffs, mana),
        profile("holy", "Holy", 11615, 2,
            adjust(healer, { heal = 1.12, holy = 0.36, spi = 0.83 }), healerBuffs, healerSupport),
    },
    SHAMAN = {
        profile("enhancement", "Enhancement", 11363, 2,
            adjust(strength, { int = 0.58, spell = 0.40, nature = 0.48, fire = 0.34,
                imbue = 1, windfury = 2.05, rockbiter = 0.55, flametongue = 0.48 }), shamanWeapons, shamanUtility),
        profile("elemental", "Elemental", 11326, 1,
            adjust(caster, { nature = 1.04, fire = 0.57, spellCrit = 4.85 }), shamanCaster,
            adjust(offHeal, { imbue = 0.22, flametongue = 0.52 })),
        profile("restoration", "Restoration", 11362, 3,
            adjust(healer, { heal = 1.04, mp5 = 1.29 }), shamanHealer,
            adjust(healerSupport, { imbue = 0.20, flametongue = 0.44, nature = 0.15 })),
    },
    MAGE = {
        profile("frost", "Frost", 11601, 3,
            adjust(caster, { frost = 1.03 }), mageBuffs, adjust(casterSupport, { spellPenFrost = 0.35 })),
        profile("arcane", "Arcane", 11582, 1,
            adjust(caster, { arcane = 1.03, int = 0.91 }), mageBuffs,
            adjust(casterSupport, { spellPenFire = 0.14, spellPenFrost = 0.14 })),
        profile("fire", "Fire", 11594, 2,
            adjust(caster, { fire = 1.05, spellCrit = 5.65, crit = 5.35 }), mageBuffs,
            adjust(casterSupport, { spellPenFire = 0.35, fireBlastReset = 0.28 })),
    },
    WARLOCK = {
        profile("affliction", "Affliction", 11629, 1,
            adjust(caster, { shadow = 1.02, sta = 0.39, spellCrit = 3.90 }), warlockBuffs, warlockUtility),
        profile("demonology", "Demonology", 11636, 2,
            adjust(caster, { shadow = 0.70, fire = 0.70, sta = 0.55 }), warlockBuffs, warlockUtility),
        profile("destruction", "Destruction", 11637, 3,
            adjust(caster, { fire = 1.03, shadow = 0.70, spellCrit = 5.5, crit = 4.8 }), warlockBuffs, warlockUtility),
    },
    DRUID = {
        profile("feral", "Feral Combat (Cat)", 11347, 2,
            adjust(agility, { str = 0.89, weapon = 2.3, poison = 0 }), agilityScroll),
        profile("balance", "Balance", 11328, 1,
            adjust(caster, { nature = 0.94, arcane = 0.86, haste = 4.35 }), casterBuffs, offHeal),
        profile("restoration", "Restoration", 11340, 3,
            adjust(healer, { heal = 1.15, spi = 0.76 }), healerBuffs, healerSupport),
        profile("bear", "Feral Combat (Bear)", nil, nil,
            adjust(tank, { armor = 0.061, sta = 1.31, agi = 0.82 }), tankBuffs),
    },
}

A.defaultProfile = profile("leveling", "Leveling", nil, nil,
    adjust(strength, { int = 0.65, spell = 0.65, heal = 0.55 }), {}, offHeal)
