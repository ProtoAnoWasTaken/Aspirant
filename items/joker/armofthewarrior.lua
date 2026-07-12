SMODS.Atlas({
    key = 'armofthewarrior',
    path = 'armofthewarrior.png',
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
    return extra and extra.gain or 5
end

local function count_destroyed_by_card(context, card)
    if AG_UTIL.install_destroy_source_hooks then
        AG_UTIL.install_destroy_source_hooks()
    end

    return AG_UTIL.count_cards_destroyed_by_card and AG_UTIL.count_cards_destroyed_by_card(context, card) or 0
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
    key = 'armofthewarrior',
    atlas = 'armofthewarrior',
    pos = { x = 0, y = 0 },
    name = 'Arm of the Warrior',
    rarity = 2,
    cost = 7,

    config = {
        extra = {
            mult = 0,
            gain = 5,
        }
    },

    loc_txt = {
        name = 'Arm of the Warrior',
        text = {
            'This Joker gains {C:mult}+#2#{} Mult',
            'whenever a {C:attention}card{}',
            'destroys another {C:attention}card{}',
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

        local destroyed_count = count_destroyed_by_card(context, card)

        if destroyed_count > 0 then
            local extra = get_extra(card)
            local gained_mult = get_gain(card) * destroyed_count
            extra.mult = get_mult(card) + gained_mult

            return {
                message = '+' .. tostring(gained_mult) .. ' Mult',
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
