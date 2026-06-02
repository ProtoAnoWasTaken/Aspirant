SMODS.Atlas({
    key = 'grassbewrayer',
    path = 'grassbewrayer.png',
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = 'grassbewrayer',
    atlas = 'grassbewrayer',
    pos = { x = 0, y = 0 },
    name = 'Grass Bewrayer',
    rarity = 3,
    cost = 8,

    config = { extra_value = 4 },

    loc_txt = {
        name = 'Grass Bewrayer',
        text = {
            "1 in 4 chance to copy the {C:attention}Joker{}",
            "to its left and its right",
        }
    },

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,

    add_to_deck = function(self, card, from_debuff)
        card.ability.extra_value = 4
        if card.set_cost then
            card:set_cost()
        end
    end,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint and not card.getting_sliced then
            return {
                message = 'Nope!',
                Xmult_mod = 1,
            }
        end
    end,
})
