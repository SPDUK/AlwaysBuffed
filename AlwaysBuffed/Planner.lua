local _, A = ...
local L = A.L

local COOKING = 185

local function defaultTracked(category, profile, ctx)
    if category.key == "herbalismTea" then
        -- Forever exposes both the parent Herbalism skill and its expansion skill.
        return ctx.skill(182) > 0 or ctx.skill(2944) > 0
    end
    return category.profession ~= nil or profile.tracked[category.key] == true
end

-- Only Game.lua reads gameplay state. The planner can rank a snapshot
-- before item names have loaded or on a machine without WoW installed.
function A.SelectProfile(profiles, choice, talentPoints)
    local best, most = profiles[1], 0
    for _, profile in ipairs(profiles) do
        if choice == profile.key then return profile end
        local spent = talentPoints[profile.talentGroupID] or 0
        if spent > most then
            best, most = profile, spent
        end
    end
    return best
end

function A.Prefs(key)
    local byProfile = A.db.preferences
    local profile = A.state.profile.key
    byProfile[profile] = byProfile[profile] or {}
    local categories = byProfile[profile]
    categories[key] = categories[key] or {}
    return categories[key]
end

local rankGroups = {best = 1, utility = 2, notUseful = 3}
local function rankOrder(left, right)
    if left.eligible ~= right.eligible then return left.eligible end
    if left.group ~= right.group then return rankGroups[left.group] < rankGroups[right.group] end
    if not left.eligible and left.level ~= right.level then return left.level < right.level end
    if left.item.isBasic ~= right.item.isBasic then return not left.item.isBasic end
    if left.score ~= right.score then return left.score > right.score end
    -- When a ready equipped lure matches a consumable, save the consumable.
    if left.equipped ~= right.equipped then return left.equipped end
    if left.level ~= right.level then return left.level > right.level end
    if left.price ~= right.price then return (left.price or math.huge) < (right.price or math.huge) end
    if left.item.name ~= right.item.name then return left.item.name < right.item.name end
    return left.item.id < right.item.id
end

local function improves(candidate, current)
    if not candidate or candidate.group == "notUseful" then return false end
    if not current then return true end
    if candidate.group ~= current.group then return rankGroups[candidate.group] < rankGroups[current.group] end
    -- Ranking ties can change the recommended item without improving its effect.
    return candidate.score - current.score > 1e-9
end

local function viable(row)
    return row.eligible and (row.canBuy or row.count > 0 or row.item.spell)
end

local function trackedOptions(prefs)
    local saved = prefs.trackedOptions
    if type(saved) == "table" and saved.pin == prefs.pin and type(saved.items) == "table" then return saved.items end
end

function A.SetTrackedItem(prefs, pin, plan)
    prefs.pin, prefs.trackedOptions = pin, nil
    if not pin or not plan then return end
    local items = {}
    for _, row in ipairs(plan.rows) do
        if viable(row) then items[row.item.id] = true end
    end
    prefs.trackedOptions = {pin = pin, items = items}
end

function A.SeedTrackedOptions(prefs, plan)
    if plan.trackedItem and not trackedOptions(prefs) then A.SetTrackedItem(prefs, prefs.pin, plan) end
end

local function newTrackedUpgrade(rows, seen, pinned, bag)
    local baseline = improves(bag, pinned) and bag or pinned
    local candidate
    for _, row in ipairs(rows) do
        if row.eligible and row.canBuy and row.count == 0
            and not seen[row.item.id] and improves(row, candidate) then
            candidate = row
        end
    end
    if improves(candidate, baseline) then return candidate end
end

local function restriction(item, level, count, ctx, weapon, weaponSubclass, weaponRequired, info)
    if ctx.level < level then return L["Level %d"]:format(level) end
    if item.maxLevel and ctx.level > item.maxLevel then return L["Through level %d"]:format(item.maxLevel) end
    if item.class and item.class ~= ctx.class then return L["Class restricted"] end
    local anyMelee = item.weapon == "any" and weapon and weapon ~= "fishingPole"
    if (item.weapon and item.weapon ~= weapon and not anyMelee)
        or (item.weaponSubclass and item.weaponSubclass ~= weaponSubclass) then
        return weaponRequired
    end
    if item.skillLine and ctx.skill(item.skillLine) < (item.skillRank or 1) then
        local required = item.skillLine == COOKING and L["Requires Cooking %d"]
            or item.skillLine == 356 and L["Requires Fishing %d"] or L["Requires profession skill %d"]
        return required:format(item.skillRank or 1)
    end
    if item.spell and not ctx.known(item.spell) then return L["Spell not learned"] end
    if (item.requireOwned or item.ownedOnly) and count == 0 and not item.spell then return L["Carried items only"] end
    if item.equipSlot and not info.equipped then return L["Must be equipped"] end
    if info.cooldownEnds then return L["On cooldown"] end
end

local function rankEffect(item, category, profile, level)
    if category.key == "campfire" then return "utility", item.capacity or 0 end
    local stats = item.stats or {}
    if category.profession then
        return "utility", stats[category.profession] or stats.catchQuality or 1
    end
    local direct, situational, hasOtherStat = 0, 0, false
    for stat, amount in pairs(stats) do
        if stat ~= "xp" and amount ~= 0 then
            hasOtherStat = true
            local weight = profile.weights[stat]
            if weight then
                direct = direct + amount * weight
            else
                situational = situational + amount * (profile.utilityWeights[stat] or 0)
            end
        end
    end
    local experience = level < 60 and (stats.xp or 0) * (profile.weights.xp or 0) or 0
    local value = direct + situational + experience
    if item.isBasic or category.kind == "reminder" then return "utility", value end
    if item.utility and (not hasOtherStat or direct + situational > 0) then return "utility", value end
    if direct > 0 then return "best", value end
    if situational > 0 or experience > 0 then return "utility", value end
    return "notUseful", 0
end

A.statLabels = {
    fishing = L["Fishing"],
    herbalism = L["Herbalism"],
    comprehension = L["Comprehension"],
    agi = L["Agi"],
    str = L["Str"],
    sta = L["Sta"],
    int = L["Int"],
    spi = L["Spirit"],
    ap = L["AP"],
    map = L["Melee AP"],
    spell = L["Spell power"],
    spellCrit = L["Spell crit"],
    mp5 = L["MP5"],
    hp5 = L["HP5"],
    armor = L["Armor"],
    hp = L["Health"],
    mana = L["Mana"],
    crit = L["Crit"],
    hit = L["Hit"],
    defense = L["Defense"],
    haste = L["Haste"],
    phys = L["Physical damage"],
    weapon = L["Weapon damage"],
    heal = L["Healing"],
    holy = L["Holy damage"],
    xp = L["XP"],
    arcane = L["Arcane damage"],
    fire = L["Fire damage"],
    frost = L["Frost damage"],
    nature = L["Nature damage"],
    shadow = L["Shadow damage"],
    resist = L["All resistance"],
    weaponCrit = L["Weapon crit"],
    spellPenFire = L["Fire spell pen."],
    spellPenFrost = L["Frost spell pen."],
    shadowResist = L["Shadow resistance"],
    fireResist = L["Fire resistance"],
    frostResist = L["Frost resistance"],
    reactiveDamageTaken = L["Enemy damage taken"],
    thorns = L["Reflected damage"],
}

local statSearchTerms = {
    str = "strength", agi = "agility", sta = "stamina", int = "intellect intelligence mana pool",
    spi = "spirit regeneration", hp = "health maximum health hit points", hp5 = "hp5 health regen health regeneration health per 5 seconds",
    mp5 = "mp5 mp/5 mana per 5 seconds mana regen mana regeneration", mana = "mana maximum mana mana pool",
    ap = "attack power melee attack power ranged attack power", map = "melee attack power", rap = "ranged attack power",
    phys = "physical damage", weapon = "weapon damage", crit = "critical strike critical hit",
    weaponCrit = "weapon crit melee critical strike", spellCrit = "spell crit spell critical strike", haste = "haste attack speed cast speed",
    hit = "hit chance accuracy", spell = "spell damage spell power", heal = "healing power healing spells bonus healing",
    fire = "fire damage fire spell power", frost = "frost damage frost spell power", holy = "holy damage holy spell power",
    shadow = "shadow damage shadow spell power", nature = "nature damage nature spell power", arcane = "arcane damage arcane spell power",
    resist = "resistance magic resistance", shadowResist = "shadow resistance", fireResist = "fire resistance",
    frostResist = "frost resistance", armor = "armor armour physical defense", defense = "defense skill defence skill", dodge = "dodge avoidance",
    spellPenFire = "fire spell penetration fire resistance", spellPenFrost = "frost spell penetration frost resistance",
    meleeFireProc = "fire damage melee proc on hit", arcaneSpellProc = "arcane damage spell proc arcane missile",
    reactiveDamageTaken = "reactive physical damage taken on hit proc",
    thorns = "thorns retaliate reflect damage defensive proc", poison = "poison nature damage melee proc on hit",
    castSlow = "slow casting speed casting time", movementSlow = "slow movement speed snare",
    attackSlow = "slow attack speed", freezeProc = "freeze frozen root crowd control proc", fireBlastReset = "fire blast cooldown reset proc",
    wandHasteProc = "wand haste attack speed proc", manaOnHitProc = "mana restore mana restoration melee proc on hit",
    healingReduction = "reduce healing received healing reduction anti-heal", xp = "xp experience experience from kills",
    windfury = "windfury additional attacks melee proc", flametongue = "flametongue fire damage melee proc",
    frostbrand = "frostbrand frost damage slow melee proc", rockbiter = "rockbiter attack power threat", imbue = "weapon imbue",
}

local fullStatNames = {
    str = L["Strength"],
    agi = L["Agility"],
    sta = L["Stamina"],
    int = L["Intellect"],
    ap = L["Attack Power"],
    xp = L["kill XP"],
}

local foldCase = C_Intl and C_Intl.FoldCase or string.lower

function A.MatchesItemSearch(row, query)
    query = query:match("^%s*(.-)%s*$")
    if query == "" then return true end
    query = foldCase(query) or query:lower()
    local function matches(value)
        return value and (foldCase(value) or value:lower()):find(query, 1, true) ~= nil
    end
    local item = row.item
    if matches(row.name) or matches(item.name) or matches(item.note) then return true end
    for stat, amount in pairs(item.stats or {}) do
        if amount ~= 0 and (matches(stat) or matches(A.statLabels[stat]) or matches(fullStatNames[stat])
            or matches(statSearchTerms[stat])) then return true end
    end
    for _, aura in ipairs(item.auraNames or {}) do
        if matches(aura) then return true end
    end
    for _, term in ipairs(item.searchTerms or {}) do
        if matches(term) then return true end
    end
    return false
end

function A.UpdateReminderVisibility(category, plan)
    plan.applicable = category.key ~= "sleepingBag" or plan.bag ~= nil or plan.active ~= nil
    plan.tracked = plan.reminderEnabled and plan.applicable
end

function A.PlanCategory(category, catalog, ctx, prefs, profile)
    local tracked = prefs.enabled
    if tracked == nil then tracked = defaultTracked(category, profile, ctx) end
    local weapon = category.slot and ctx.weapons[category.slot]
    local weaponSubclass = category.slot and ctx.weaponSubclasses and ctx.weaponSubclasses[category.slot]
    local lure = category.profession == "fishing" and category.slot ~= nil
    local weaponRequired = lure and L["Requires a fishing pole"]
        or category.slot == 17 and L["Requires a compatible off-hand weapon"]
        or L["Requires a compatible main-hand weapon"]
    local applicable = not category.slot or (weapon ~= nil and (weapon == "fishingPole") == lure)
    local result = {rows = {}, enabled = tracked, applicable = applicable}
    local pinnedBuy, pinnedBag, cheapest
    for _, item in ipairs(catalog) do
        if not item.class or item.class == ctx.class then
            local info = ctx.info(item)
            if info.equipped then result.equippedSlot, result.cooldownEnds = item.equipSlot, info.cooldownEnds end
            local level = info.level or item.level
            local count = info.count or 0
            local reason = restriction(item, level, count, ctx, weapon, weaponSubclass, weaponRequired, info)
            local group, score = rankEffect(item, category, profile, ctx.level)
            local row = {
                item = item, name = info.name or item.name, icon = info.icon or category.icon,
                level = level, count = count, price = info.price, eligible = not reason, equipped = info.equipped == true,
                reason = reason, group = group, score = score,
                canBuy = not (category.kind == "reminder" or item.ownedOnly or item.isBasic or item.spell or item.requireOwned),
            }
            result.rows[#result.rows + 1] = row
        end
    end
    table.sort(result.rows, rankOrder)
    for _, row in ipairs(result.rows) do
        local pinned = prefs.pin == row.item.id
        if pinned and category.kind ~= "reminder" then result.trackedItem = row end
        if row.eligible then
            local useful = row.group ~= "notUseful"
            if row.canBuy then
                if useful and not result.buy then result.buy = row end
                if pinned then pinnedBuy = row end
                if useful and row.price and (not cheapest or row.price < cheapest.price) then cheapest = row end
            end
            if row.count > 0 or row.item.spell then
                if useful and not result.bag then result.bag = row end
                if pinned then pinnedBag = row end
            end
        end
    end
    result.buy = pinnedBuy or (prefs.cheapest and cheapest) or result.buy
    local bestBag = result.bag
    result.bag = pinnedBag or result.bag
    if #result.rows == 0 then result.applicable = false end
    if category.key == "campfire" and not result.bag then
        local cooking = ctx.skill(COOKING)
        local required
        for _, row in ipairs(result.rows) do
            local rank = row.item.skillRank
            if row.count > 0 and rank and rank > cooking and (not required or rank < required) then
                required = rank
            end
        end
        if cooking < 1 then
            result.reminderReason = L["Train Cooking to place a campfire kit."]
        elseif required then
            result.reminderReason = L["Requires Cooking %d."]:format(required)
        else
            result.reminderReason = L["Carry a campfire kit or use a nearby campsite."]
        end
    elseif category.key == "sleepingBag" and not result.bag then
        local row = result.rows[1]
        if row and row.item.maxLevel and ctx.level > row.item.maxLevel then
            result.reminderReason = L["Available through level %d."]:format(row.item.maxLevel)
        else
            result.reminderReason = L["Requires Cozy Sleeping Bag in your bags."]
        end
    end
    if category.kind == "reminder" then
        result.reminderEnabled = tracked and ctx.reminders == true
        A.UpdateReminderVisibility(category, result)
    else
        result.tracked = tracked and result.applicable
        if result.tracked then
            local seen, pinned = trackedOptions(prefs), result.trackedItem
            if seen and pinned and viable(pinned) then
                result.upgrade = newTrackedUpgrade(result.rows, seen, pinned, bestBag)
            end
            if not result.upgrade and not pinnedBag and result.buy and result.buy.count == 0
                and improves(result.buy, result.bag) then
                result.upgrade = result.buy
            end
        end
    end
    return result
end
