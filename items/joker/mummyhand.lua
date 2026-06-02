SMODS.Atlas({
    key = 'mummyhand',
    path = 'mummyhand.png',
    px = 69,
    py = 93,
})

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

SMODS.Joker({
    key = 'mummyhand',
    atlas = 'mummyhand',
    pos = { x = 0, y = 0 },
    name = "The Mummy's Hand",
    rarity = 2,
    cost = 6,

    config = { extra = { xmult = 0.9, hands = 1, hand_size = 2 } },

    loc_txt = {
        name = "The Mummy's Hand",
        text = {
            "{C:blue}+#2#{} hand",
            "{C:attention}+#3#{} hand size",
            "{X:mult,C:white}X#1#{} Mult",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(card.ability.extra.xmult),
                card.ability.extra.hands,
                card.ability.extra.hand_size,
            }
        }
    end,

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                Xmult_mod = card.ability.extra.xmult,
                message = 'X' .. format_xmult(card.ability.extra.xmult),
            }
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.hands
        ease_hands_played(card.ability.extra.hands)
        G.hand:change_size(card.ability.extra.hand_size)
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - card.ability.extra.hands
        ease_hands_played(-card.ability.extra.hands)
        G.hand:change_size(-card.ability.extra.hand_size)
    end,
})
