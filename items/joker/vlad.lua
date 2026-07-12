SMODS.Atlas({
    key = 'vlad',
    path = 'vlad.png',
    px = 69,
    py = 93,
})

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.25
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

local function get_drainable_jokers(source_card)
    local jokers = {}

    if not G or not G.jokers or not G.jokers.cards then
        return jokers
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= source_card
            and not joker.getting_sliced
            and joker.edition
            and not joker.edition.negative
        then
            jokers[#jokers + 1] = joker
        end
    end

    return jokers
end

local function drain_random_joker_edition(card)
    local jokers = get_drainable_jokers(card)
    local target = #jokers > 0 and pseudorandom_element(jokers, pseudoseed('ag_vlad')) or nil

    if not target then
        return false
    end

    target:set_edition(nil, true, true)
    target:juice_up()

    card.ability.extra.xmult = get_xmult(card) + get_gain(card)

    return true
end

SMODS.Joker({
    key = 'vlad',
    atlas = 'vlad',
    pos = { x = 0, y = 0 },
    name = 'Vlad',
    rarity = 2,
    cost = 6,

    config = { extra = { xmult = 1, gain = 0.25 } },

    loc_txt = {
        name = 'Vlad',
        text = {
            "When {C:attention}Blind{} is selected, remove",
            "edition from a random {C:attention}Joker{}",
            "and gain {X:mult,C:white}X#2#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            if drain_random_joker_edition(card) then
                return {
                    message = 'X' .. format_xmult(get_gain(card)),
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main and Aspirant.joker_utils.compare_numbers(get_xmult(card), 'gt', 1) then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
