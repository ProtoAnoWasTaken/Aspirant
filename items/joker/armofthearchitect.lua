SMODS.Atlas({
    key = 'armofthearchitect',
    path = 'armofthearchitect.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function get_mult(card)
    local extra = get_extra(card)
    return extra and extra.mult or 0
end

local function get_gain(card)
    local extra = get_extra(card)
    return extra and extra.gain or 10
end

local function try_combine(card)
    if AG_UTIL.try_combine_arms
        and not card.getting_sliced
        and G
        and G.jokers
        and card.area == G.jokers
    then
        AG_UTIL.try_combine_arms(card)
    end
end

SMODS.Joker({
    key = 'armofthearchitect',
    atlas = 'armofthearchitect',
    pos = { x = 0, y = 0 },
    name = 'Arm of the Architect',
    rarity = 2,
    cost = 7,

    config = {
        extra = {
            mult = 0,
            gain = 10,
        }
    },

    loc_txt = {
        name = 'Arm of the Architect',
        text = {
            'This Joker gains {C:mult}+#2#{} Mult',
            'whenever a {C:attention}Lemurian{} Joker',
            'creates a card',
            '{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}',
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_mult(card),
                get_gain(card),
            }
        }
    end,

    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = function(self, card)
        get_extra(card)
        try_combine(card)
    end,

    update = function(self, card, dt)
        try_combine(card)
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if context.ag_lemurian_created_card and context.source_card ~= card then
            local extra = get_extra(card)
            extra.mult = get_mult(card) + get_gain(card)

            return {
                message = '+' .. tostring(get_gain(card)) .. ' Mult',
                colour = G.C.MULT,
            }
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(get_mult(card)) then
            return {
                mult_mod = get_mult(card),
                message = '+' .. tostring(get_mult(card)),
            }
        end
    end,
})
