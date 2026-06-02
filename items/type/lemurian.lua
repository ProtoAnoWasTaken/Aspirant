Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.lemurian = Aspirant.lemurian or {}

local AG_LEMURIAN = Aspirant.lemurian

AG_LEMURIAN.jokers = AG_LEMURIAN.jokers or {
    "j_tk9g_armofthearchitect",
    "j_tk9g_armofthepioneer",
    "j_tk9g_armofthedemolitionist",
    "j_tk9g_armofthewarrior",
    "j_tk9g_manmadenephilim",
    "j_tk9g_diwygiwryddaear",
    "j_tk9g_weithiwrhaearn",
    "j_tk9g_starlightobelisk",
}

local LEMURIAN_LOOKUP = {}
for _, key in ipairs(AG_LEMURIAN.jokers) do
    LEMURIAN_LOOKUP[key] = true
end

local function ag_key_matches(center, key)
    if not center or not key then
        return false
    end

    return center.original_key == key
        or center.key == key
        or (type(center.key) == "string" and center.key:match(key .. "$") ~= nil)
end

local function ag_mark_lemurian(joker)
    if not joker then
        return
    end

    joker.pools = joker.pools or {}
    joker.pools.Lemurian = true
end

local function ag_find_joker(key)
    if SMODS and SMODS.Jokers then
        for _, joker in pairs(SMODS.Jokers) do
            if joker and joker.set == "Joker" and ag_key_matches(joker, key) then
                return joker
            end
        end
    end

    if G and G.P_CENTERS then
        for _, center in pairs(G.P_CENTERS) do
            if center and center.set == "Joker" and ag_key_matches(center, key) then
                return center
            end
        end
    end

    return nil
end

local function ag_apply_lemurian_tags()
    for _, key in ipairs(AG_LEMURIAN.jokers) do
        ag_mark_lemurian(ag_find_joker(key))
    end
end

local function ag_insert_center_without_reordering(pool, center)
    if not pool or not center then
        return
    end

    for _, existing in ipairs(pool) do
        if existing == center or existing.key == center.key then
            return
        end
    end

    pool[#pool + 1] = center
end

local function ag_remove_center_from_pool(pool, key)
    if not pool or not key then
        return
    end

    for index, center in ipairs(pool) do
        if center and center.key == key then
            table.remove(pool, index)
            return
        end
    end
end

SMODS.ObjectType({
    key = "Lemurian",
    default = "j_tk9g_weithiwrhaearn",
    cards = {},
    inject_card = function(self, center)
        if center.set ~= self.key then
            ag_insert_center_without_reordering(G.P_CENTER_POOLS[self.key], center)
        end

        center.pools = center.pools or {}
        center.pools[self.key] = true
    end,
    delete_card = function(self, center)
        if center.set ~= self.key then
            ag_remove_center_from_pool(G.P_CENTER_POOLS[self.key], center.key)
        end

        if center.pools then
            center.pools[self.key] = nil
        end
    end,
    inject = function(self)
        SMODS.ObjectType.inject(self)

        ag_apply_lemurian_tags()

        for _, key in ipairs(AG_LEMURIAN.jokers) do
            local joker = ag_find_joker(key)
            if joker then
                self:inject_card(joker)
            end
        end
    end,
})

ag_apply_lemurian_tags()

function Card:is_lemurian()
    local center = self and self.config and self.config.center
    if not center then
        return false
    end

    return LEMURIAN_LOOKUP[center.key] == true
        or LEMURIAN_LOOKUP[center.original_key] == true
        or (center.pools and center.pools.Lemurian == true)
end
