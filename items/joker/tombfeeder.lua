SMODS.Atlas({
    key = 'tombfeeder',
    path = 'tombfeeder.png',
    px = 69,
    py = 93,
})

local Aspirant = rawget(_G, 'Aspirant') or {}
local AG = Aspirant

local function get_unique_hands_played()
    local total = 0

    for _, hand in pairs(G.GAME.hands or {}) do
        if hand.visible and (hand.played or 0) > 0 then
            total = total + 1
        end
    end

    return total
end

local function get_total_mult(card)
    local unique_hands = get_unique_hands_played()
    local planet_count = card.ability.extra.planets_used or 0

    return unique_hands * card.ability.extra.hand_mult + planet_count * card.ability.extra.planet_mult
end

SMODS.Joker({
    key = 'tombfeeder',
    atlas = 'tombfeeder',
    pos = { x = 0, y = 0 },
    name = 'Tombfeeder',
    rarity = 3,
    cost = 8,

    config = { extra = { hand_mult = 5, planet_mult = 2, planets_used = 0, last_unique_hands = 0 } },

    loc_txt = {
        name = 'Tombfeeder',
        text = {
            "This Joker gains {C:mult}+#2#{} Mult per unique",
            "poker hand this run",
            "{C:mult}+#3#{} Mult for each {C:planet}Planet{} card",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_mult(card), card.ability.extra.hand_mult, card.ability.extra.planet_mult } }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if not context.blueprint and AG.unlock_bejeweled then
            AG.unlock_bejeweled()
        end

        if not context.blueprint then
            local unique_hands = get_unique_hands_played()
            local last_unique_hands = card.ability.extra.last_unique_hands or 0

            if unique_hands > last_unique_hands then
                local gained_mult = (unique_hands - last_unique_hands) * card.ability.extra.hand_mult
                card.ability.extra.last_unique_hands = unique_hands

                return {
                    message = '+' .. gained_mult .. ' Mult',
                    colour = G.C.MULT,
                }
            end
        end

        if context.using_consumeable and not context.blueprint
            and context.consumeable and context.consumeable.ability
            and context.consumeable.ability.set == 'Planet' then
            card.ability.extra.planets_used = (card.ability.extra.planets_used or 0) + 1
            return {
                message = '+' .. card.ability.extra.planet_mult .. ' Mult',
                colour = G.C.MULT,
            }
        end

        if context.joker_main then
            local mult = get_total_mult(card)

            if mult > 0 then
                return {
                    mult_mod = mult,
                    message = '+' .. mult .. ' Mult',
                }
            end
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.last_unique_hands = get_unique_hands_played()

        if AG.unlock_bejeweled then
            AG.unlock_bejeweled()
        end
    end,
})
