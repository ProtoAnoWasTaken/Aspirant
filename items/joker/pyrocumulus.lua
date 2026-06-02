SMODS.Atlas({
    key = 'pyrocumulus',
    path = 'pyrocumulus.png',
    px = 69,
    py = 93,
})

local function get_debuff_source(card)
    return 'ag_pyrocumulus_' .. tostring(card)
end

local function is_valid_card_object(card)
    return type(card) == 'table' and card.ability ~= nil
end

local function clear_debuffed_joker(card)
    local debuffed_joker = card.ability.extra.debuffed_joker

    if is_valid_card_object(debuffed_joker) then
        SMODS.debuff_card(debuffed_joker, false, get_debuff_source(card))
    end

    card.ability.extra.debuffed_joker = nil
end

SMODS.Joker({
    key = 'pyrocumulus',
    atlas = 'pyrocumulus',
    pos = { x = 0, y = 0 },
    name = 'Pyrocumulus',
    rarity = 3,
    cost = 8,

    config = { extra = { mult = 0, gain = 5, debuffed_joker = nil } },

    loc_txt = {
        name = 'Pyrocumulus',
        text = {
            "When {C:attention}Small Blind{} or {C:attention}Big Blind{} is selected,",
            "debuff a random {C:attention}Joker{} for",
            "the round and gain {C:mult}+#2#{} Mult",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.gain } }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint and not context.retrigger_joker
            and not card.getting_sliced and not context.blind.boss then
            local jokers = {}

            clear_debuffed_joker(card)

            for _, joker in ipairs(G.jokers.cards) do
                if joker ~= card and not joker.getting_sliced then
                    jokers[#jokers + 1] = joker
                end
            end

            local target = #jokers > 0 and pseudorandom_element(jokers, pseudoseed('ag_pyrocumulus')) or nil

            if not target then
                return
            end

            card.ability.extra.debuffed_joker = target
            SMODS.debuff_card(target, true, get_debuff_source(card))
            card_eval_status_text(target, 'extra', nil, nil, nil, {
                message = localize('k_debuffed'),
                colour = G.C.RED,
            })

            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain
            return {
                message = '+' .. card.ability.extra.gain .. ' Mult',
                colour = G.C.MULT,
            }
        end

        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult_mod = card.ability.extra.mult,
                message = '+' .. card.ability.extra.mult .. ' Mult',
            }
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            clear_debuffed_joker(card)
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        clear_debuffed_joker(card)
    end,
})
