SMODS.Atlas({
    key = 'grisialfeistr',
    path = 'grisialfeistr.png',
    px = 69,
    py = 93,
})

local SUITS = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }

local function get_unique_suit_count(cards)
    local unique_suits = 0

    for _, suit in ipairs(SUITS) do
        for _, playing_card in ipairs(cards or {}) do
            if playing_card and playing_card:is_suit(suit) then
                unique_suits = unique_suits + 1
                break
            end
        end
    end

    return unique_suits
end

local function get_xmult(card, context)
    local base_xmult = (card.ability and card.ability.extra and card.ability.extra.base_xmult) or 4
    local unique_suits = get_unique_suit_count((context and context.scoring_hand) or (context and context.full_hand))

    return math.max(0, base_xmult - unique_suits), unique_suits
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

SMODS.Joker({
    key = 'grisialfeistr',
    atlas = 'grisialfeistr',
    pos = { x = 0, y = 0 },
    name = 'Grisial Feistr',
    rarity = 3,
    cost = 8,

    config = { extra = { base_xmult = 4, suit_penalty = 1 } },

    loc_txt = {
        name = 'Grisial Feistr',
        text = {
            "This Joker starts with a base {c:Mult}Mult{} of {X:mult,C:white}X#1#{}",
            "Effective {X:mult,C:white}-X#2#{} for each unique suit in the played hand",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local current_xmult = card and card.ability and card.ability.extra and card.ability.extra.base_xmult or 4

        if G and G.play and G.play.cards and #G.play.cards > 0 then
            current_xmult = get_xmult(card, { scoring_hand = G.play.cards })
        end

        return {
            vars = {
                card.ability.extra.base_xmult,
                card.ability.extra.suit_penalty,
                format_xmult(current_xmult),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = get_xmult(card, context)

            return {
                Xmult_mod = xmult,
                message = 'X' .. format_xmult(xmult),
            }
        end
    end,
})
