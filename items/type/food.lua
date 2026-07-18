Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.food = Aspirant.food or {}

local AG_FOOD = Aspirant.food

-- ADD MODDED ONES HERE
AG_FOOD.jokers = AG_FOOD.jokers or {
    "j_tk9g_scenesteapot",
    "j_tk9g_harvest",
    "j_tk9g_lolhoo",
    "j_tk9g_cherrybomb",
    "j_tk9g_etrog",
    "j_tk9g_picklejar"
}

local BASE_GAME_FOOD_KEYS = {
    "j_gros_michel",
    "j_egg",
    "j_ice_cream",
    "j_cavendish",
    "j_turtle_bean",
    "j_diet_cola",
    "j_popcorn",
    "j_ramen",
    "j_selzer",
}

local BASE_GAME_FOOD_LOOKUP = {}
for _, key in ipairs(BASE_GAME_FOOD_KEYS) do
    BASE_GAME_FOOD_LOOKUP[key] = true
end

local HERBALIST_DECK_KEYS = {
    "herbalist_deck",
    "b_herbalist_deck",
}

local function ag_is_herbalist_deck_active()
    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center
    local center_key = center and (center.original_key or center.key)

    if type(center_key) ~= "string" then
        return false
    end

    for _, key in ipairs(HERBALIST_DECK_KEYS) do
        if center_key == key or center_key:match(key .. "$") ~= nil then
            return true
        end
    end

    return false
end

local function ag_is_baby_center(center)
    return center
        and (
            center.original_key == "baby"
            or center.key == "baby"
            or (type(center.key) == "string" and center.key:match("baby$") ~= nil)
        )
end

local function ag_key_matches(center, key)
    if not center or not key then
        return false
    end

    return center.original_key == key
        or center.key == key
        or (type(center.key) == "string" and center.key:match(key .. "$") ~= nil)
end

local function ag_mark_food(joker)
    if not joker then
        return
    end

    joker.pools = joker.pools or {}
    joker.pools.Food = true
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

local function ag_apply_food_tags()
    for _, key in ipairs(AG_FOOD.jokers) do
        ag_mark_food(ag_find_joker(key))
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
    key = "Food",
    default = "j_gros_michel",
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

        for _, key in ipairs(BASE_GAME_FOOD_KEYS) do
            if G and G.P_CENTERS and G.P_CENTERS[key] then
                self:inject_card(G.P_CENTERS[key])
            end
        end

        ag_apply_food_tags()

        for _, key in ipairs(AG_FOOD.jokers) do
            local joker = ag_find_joker(key)
            if joker then
                self:inject_card(joker)
            end
        end
    end,
})

ag_apply_food_tags()

function AG_FOOD.is_food_center(center)
    if not center then
        return false
    end

    return BASE_GAME_FOOD_LOOKUP[center.key] == true
        or BASE_GAME_FOOD_LOOKUP[center.original_key] == true
        or (ag_is_herbalist_deck_active() and ag_is_baby_center(center))
        or (center.pools and center.pools.Food == true)
end

function AG_FOOD.is_food_subject(subject)
    local center = subject and subject.config and subject.config.center or subject
    if not center then
        return false
    end

    return AG_FOOD.is_food_center(center)
end

function AG_FOOD.is_drommo_subject(subject)
    local center = subject and subject.config and subject.config.center or subject
    if not center then
        return false
    end

    return center.original_key == "drommo"
        or center.key == "drommo"
        or (type(center.key) == "string" and center.key:match("drommo$") ~= nil)
end

function AG_FOOD.get_drommo_count()
    if not G or not G.jokers or not G.jokers.cards then
        return 0
    end

    local count = 0

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.added_to_deck
            and not joker.debuff
            and not joker.getting_sliced
            and AG_FOOD.is_drommo_subject(joker)
        then
            count = count + 1
        end
    end

    return count
end

function AG_FOOD.get_value_multiplier(subject)
    if not AG_FOOD.is_food_subject(subject) then
        return 1
    end

    return 2 ^ AG_FOOD.get_drommo_count()
end

function AG_FOOD.scale_value(subject, value)
    return value * AG_FOOD.get_value_multiplier(subject)
end

function AG_FOOD.scale_probability(subject, numerator, denominator)
    return {
        numerator = numerator * AG_FOOD.get_value_multiplier(subject),
        denominator = denominator,
    }
end

local function ag_scale_food_instance_values(target, config, multiplier)
    if type(target) ~= "table" or type(config) ~= "table" or multiplier == 1 then
        return
    end

    for key, value in pairs(config) do
        if type(value) == "number" and type(target[key]) == "number" then
            target[key] = target[key] * multiplier
        elseif type(value) == "table" and type(target[key]) == "table" then
            ag_scale_food_instance_values(target[key], value, multiplier)
        end
    end
end

function AG_FOOD.sync_card_values(card)
    if not card or not card.ability or not AG_FOOD.is_food_subject(card) then
        return
    end

    local center = card.config and card.config.center
    local config = center and center.config
    if type(config) ~= "table" then
        return
    end

    local applied_multiplier = card.ability.ag_food_value_multiplier or 1
    local current_multiplier = AG_FOOD.get_value_multiplier(card)
    if applied_multiplier == current_multiplier then
        return
    end

    ag_scale_food_instance_values(card.ability, config, current_multiplier / applied_multiplier)
    card.ability.ag_food_value_multiplier = current_multiplier
end

function AG_FOOD.sync_drommo_values()
    if not G or not G.jokers or not G.jokers.cards then
        return
    end

    for _, joker in ipairs(G.jokers.cards) do
        AG_FOOD.sync_card_values(joker)
    end
end

if not AG_FOOD.original_card_set_ability then
    AG_FOOD.original_card_set_ability = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites)
        AG_FOOD.original_card_set_ability(self, center, initial, delay_sprites)
        AG_FOOD.sync_card_values(self)
    end
end

if Card.set_debuff and not AG_FOOD.original_card_set_debuff then
    AG_FOOD.original_card_set_debuff = Card.set_debuff

    function Card:set_debuff(should_debuff)
        local is_drommo = AG_FOOD.is_drommo_subject(self)
        local results = { AG_FOOD.original_card_set_debuff(self, should_debuff) }

        if is_drommo then
            AG_FOOD.sync_drommo_values()
        end

        return unpack(results)
    end
end

if Card.start_dissolve and not AG_FOOD.original_card_start_dissolve then
    AG_FOOD.original_card_start_dissolve = Card.start_dissolve

    function Card:start_dissolve(dissolve_colours, silent, dissolve_time_fac, no_juice)
        local is_drommo = AG_FOOD.is_drommo_subject(self)
        local results = {
            AG_FOOD.original_card_start_dissolve(
                self,
                dissolve_colours,
                silent,
                dissolve_time_fac,
                no_juice
            )
        }

        if is_drommo then
            AG_FOOD.sync_drommo_values()
        end

        return unpack(results)
    end
end

function Card:is_food()
    return AG_FOOD.is_food_subject(self)
end
