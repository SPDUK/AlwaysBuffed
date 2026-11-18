local _, A = ...

local COOKING = 185

-- Only Game.lua knows how to read the client. The planner can rank a snapshot
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
    if left.level ~= right.level then return left.level > right.level end
    if left.price ~= right.price then return (left.price or math.huge) < (right.price or math.huge) end
    if left.name ~= right.name then return left.name < right.name end
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

local function restriction(item, level, count, ctx, weapon, weaponSubclass, weaponRequired)
    if ctx.level < level then return "Level " .. level end
    if item.maxLevel and ctx.level > item.maxLevel then return "Through level " .. item.maxLevel end
    if item.class and item.class ~= ctx.class then return "Class restricted" end
    if (item.weapon and (not weapon or (item.weapon ~= "any" and item.weapon ~= weapon)))
        or (item.weaponSubclass and item.weaponSubclass ~= weaponSubclass) then
        return weaponRequired
    end
    if item.skillLine and ctx.skill(item.skillLine) < (item.skillRank or 1) then
        local skill = item.skillLine == COOKING and "Cooking " or "profession skill "
        return "Requires " .. skill .. (item.skillRank or 1)
    end
    if item.spell and not ctx.known(item.spell) then return "Spell not learned" end
    if (item.requireOwned or item.ownedOnly) and count == 0 and not item.spell then return "Carried items only" end
end

local function rankEffect(item, category, profile, level)
    if category.key == "campfire" then return "utility", item.capacity or 0 end
    local stats = item.stats or {}
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

function A.MatchesItemSearch(row, query)
    query = query:match("^%s*(.-)%s*$"):lower()
    if query == "" then return true end
    local function matches(value)
        return value and value:lower():find(query, 1, true) ~= nil
    end
    local item = row.item
    if matches(row.name) or matches(item.name) or matches(item.note) then return true end
    for stat, amount in pairs(item.stats or {}) do
        if amount ~= 0 and (matches(stat) or matches(statSearchTerms[stat])) then return true end
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
    if tracked == nil then tracked = profile.tracked[category.key] == true end
    local weapon = category.slot and ctx.weapons[category.slot]
    local weaponSubclass = category.slot and ctx.weaponSubclasses and ctx.weaponSubclasses[category.slot]
    local weaponRequired = category.slot == 17 and "Requires a compatible off-hand weapon"
        or "Requires a compatible main-hand weapon"
    local result = {rows = {}, applicable = category.slot == nil or weapon ~= nil}
    local pinnedBuy, pinnedBag, cheapest
    for _, item in ipairs(catalog) do
        if not item.class or item.class == ctx.class then
            local info = ctx.info(item)
            local level = info.level or item.level
            local count = info.count or 0
            local reason = restriction(item, level, count, ctx, weapon, weaponSubclass, weaponRequired)
            local group, score = rankEffect(item, category, profile, ctx.level)
            local row = {
                item = item, name = info.name or item.name, icon = info.icon or category.icon,
                level = level, count = count, price = info.price, eligible = not reason,
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
    if category.slot and #result.rows == 0 then result.applicable = false end
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
            result.reminderReason = "Train Cooking to place a campfire kit."
        elseif required then
            result.reminderReason = "Requires Cooking " .. required .. "."
        else
            result.reminderReason = "Carry a campfire kit or use a nearby campsite."
        end
    elseif category.key == "sleepingBag" and not result.bag then
        local row = result.rows[1]
        if row and row.item.maxLevel and ctx.level > row.item.maxLevel then
            result.reminderReason = "Available through level " .. row.item.maxLevel .. "."
        else
            result.reminderReason = "Requires Cozy Sleeping Bag in your bags."
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
