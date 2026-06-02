SMODS.Atlas({
    key = "drommo",
    path = "drommo.png",
    px = 69,
    py = 93,
})

local function get_mult(card)
    return (card.ability and card.ability.extra and card.ability.extra.mult) or 0
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 4
end

local function is_food_joker(card)
    return card and card.is_food and card:is_food()
end

local function should_gain_from_food_use(context, source_card)
    if not context or context.blueprint then
        return false
    end

    if context.selling_card and context.card and context.card ~= source_card and is_food_joker(context.card) then
        return true
    end

    if context.joker_type_destroyed and context.card and context.card ~= source_card and is_food_joker(context.card) then
        return true
    end

    return false
end

local function is_primary_drommo(card)
    if not G or not G.jokers or not G.jokers.cards then
        return true
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        if joker
            and not joker.debuff
            and not joker.getting_sliced
            and center
            and (
                center.original_key == "drommo"
                or center.key == "drommo"
                or (type(center.key) == "string" and center.key:match("drommo$") ~= nil)
            )
        then
            return joker == card
        end
    end

    return true
end

SMODS.Joker({
    key = "drommo",
    atlas = "drommo",
    pos = { x = 0, y = 0 },
    name = "Drommo",
    rarity = 3,
    cost = 8,

    config = { extra = { mult = 0, gain = 4 } },

    loc_txt = {
        name = "Drommo",
        text = {
            "Double values of all {C:attention}Food Jokers{}",
            "This Joker gains {C:mult}+#2#{} Mult",
            "for every {C:attention}Food Joker{} used",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}",
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

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if should_gain_from_food_use(context, card) then
            card.ability.extra.mult = get_mult(card) + get_gain(card)
            return {
                message = "+" .. tostring(get_gain(card)),
                colour = G.C.MULT,
            }
        end

        if context.fix_probability
            and is_primary_drommo(card)
            and context.card
            and context.card ~= card
            and is_food_joker(context.card)
            and Aspirant
            and Aspirant.food
            and Aspirant.food.scale_probability
        then
            return Aspirant.food.scale_probability(context.card, context.numerator, context.denominator)
        end

        if context.joker_main and get_mult(card) > 0 then
            return {
                mult_mod = get_mult(card),
                message = "+" .. tostring(get_mult(card)),
            }
        end
    end,
})
