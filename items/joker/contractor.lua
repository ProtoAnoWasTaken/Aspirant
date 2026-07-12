SMODS.Atlas({
    key = 'contractor',
    path = 'contractor.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_chips(card)
    return (card.ability and card.ability.extra and card.ability.extra.chips) or 0
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 15
end

local function is_unleveled_hand(context)
    local scoring_name = context and context.scoring_name
    local hand = scoring_name and G and G.GAME and G.GAME.hands and G.GAME.hands[scoring_name]

    return hand and hand.level == 1 or false
end

local function grisial_feistr_is_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'grisialfeistr')
        or false
end

SMODS.Joker({
    key = 'contractor',
    atlas = 'contractor',
    pos = { x = 0, y = 0 },
    name = 'Contractor',
    rarity = 1,
    cost = 4,

    config = {
        extra = {
            chips = 0,
            gain = 15,
        }
    },

    loc_txt = {
        name = 'Contractor',
        text = {
            "Gains {C:chips}+#2#{} Chips if",
            "played hand is {C:attention}unleveled{}",
            "{C:inactive}(Currently {C:chips}+#1#{}{C:inactive} Chips){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_chips(card),
                get_gain(card),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_discover_grisialfeistr', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and grisial_feistr_is_discovered()
    end,

    add_to_deck = function(self, card, from_debuff)
        local AG = rawget(_G, 'Aspirant')
        if AG and AG.unlock_cosmic_tapestry then
            AG.unlock_cosmic_tapestry()
        end
    end,

    update = function(self, card, dt)
        local AG = rawget(_G, 'Aspirant')
        if AG and AG.unlock_cosmic_tapestry then
            AG.unlock_cosmic_tapestry()
        end
    end,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and is_unleveled_hand(context)
        then
            card.ability.extra.chips = get_chips(card) + get_gain(card)

            return {
                message = '+' .. tostring(get_gain(card)) .. ' Chips',
                colour = G.C.CHIPS,
            }
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(get_chips(card)) then
            return {
                chip_mod = get_chips(card),
                message = '+' .. tostring(get_chips(card)),
            }
        end
    end,
})
