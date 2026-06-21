local function is_food(center)
    return Aspirant
        and Aspirant.food
        and Aspirant.food.is_food_center
        and Aspirant.food.is_food_center(center)
end

local function non_food_jokers()
    local banned = {}

    for _, center in pairs((G and G.P_CENTERS) or {}) do
        if center.key and center.set == 'Joker' and not is_food(center) then
            banned[#banned + 1] = { id = center.key }
        end
    end

    table.sort(banned, function(a, b) return a.id < b.id end)
    return banned
end

local function is_lolhoo(card)
    local center = card and card.config and card.config.center
    return center and (
        center.original_key == 'lolhoo'
        or center.key == 'lolhoo'
        or center.key == 'j_tk9g_lolhoo'
    )
end

SMODS.Challenge({
    key = 'survive_a_giant_garden',
    loc_txt = {
        name = 'Survive a Giant Garden',
    },
    rules = {
        custom = {
            { id = 'ag_lolhoo_lifeline' },
            { id = 'ag_food_jokers_only' },
        },
        modifiers = {},
    },
    jokers = {
        { id = 'j_tk9g_lolhoo', eternal = true },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck',
    },
    restrictions = {
        banned_cards = non_food_jokers,
        banned_tags = {},
        banned_other = {},
    },
    calculate = function(self, context)
        if context.ag_card_self_destructed and is_lolhoo(context.destroyed_card) then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.8,
                func = function()
                    G.STATE = G.STATES.GAME_OVER
                    G.STATE_COMPLETE = false
                    return true
                end,
            }))
        end
    end,
})
