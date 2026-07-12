SMODS.Atlas({
    key = 'bombshop',
    path = 'bombshop.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_destroyable_consumables()
    local consumables = {}

    if not G or not G.consumeables or not G.consumeables.cards then
        return consumables
    end

    for _, consumeable in ipairs(G.consumeables.cards) do
        if consumeable and not consumeable.getting_sliced then
            consumables[#consumables + 1] = consumeable
        end
    end

    return consumables
end

local function destroy_random_consumable(card)
    local consumables = get_destroyable_consumables()
    local target = #consumables > 0 and pseudorandom_element(consumables, pseudoseed('ag_bombshop')) or nil

    if not target then
        return false
    end

    card.ability.extra.destroyed = card.ability.extra.destroyed + 1
    card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain

    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(target, {
            silent = true,
            sound = false,
            delay = 0.1,
            source_card = card,
        })
    else
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                if target and not target.removed and not target.getting_sliced then
                    target.getting_sliced = true
                    target:start_dissolve(nil, true)
                end
                return true
            end
        }))
    end

    return true
end

SMODS.Joker({
    key = 'bombshop',
    atlas = 'bombshop',
    pos = { x = 0, y = 0 },
    name = 'Bomb Shop',
    rarity = 2,
    cost = 6,

    config = { extra = { mult = 0, gain = 4, consumable_slots = 1, destroyed = 0 } },

    loc_txt = {
        name = 'Bomb Shop',
        text = {
            "{C:attention}+#3#{} consumable slot",
            "When {C:attention}Blind{} is selected, destroy",
            "a random consumable",
            "This Joker gains {C:mult}+#4#{} Mult for",
            "every consumable destroyed this way",
            "{C:inactive}(Currently {C:mult}+#2#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.destroyed,
                card.ability.extra.mult,
                card.ability.extra.consumable_slots,
                card.ability.extra.gain,
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint and not context.retrigger_joker and not card.getting_sliced then
            if destroy_random_consumable(card) then
                return {
                    message = '+' .. card.ability.extra.gain .. ' Mult',
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(card.ability.extra.mult) then
            return {
                mult_mod = card.ability.extra.mult,
                message = '+' .. card.ability.extra.mult .. ' Mult',
            }
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        G.consumeables.config.card_limit = G.consumeables.config.card_limit + card.ability.extra.consumable_slots
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.consumeables.config.card_limit = G.consumeables.config.card_limit - card.ability.extra.consumable_slots
    end,
})
