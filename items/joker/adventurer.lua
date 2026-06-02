SMODS.Atlas({
    key = 'adventurer',
    path = 'adventurer.png',
    px = 69,
    py = 93,
})

local function get_chips(card)
    return (card.ability and card.ability.extra and card.ability.extra.chips) or 0
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 15
end

local function hand_has_face_card_or_ace(context)
    local scoring_cards = (context and context.scoring_hand) or (context and context.full_hand) or {}

    for _, playing_card in ipairs(scoring_cards) do
        local id = playing_card and playing_card.get_id and playing_card:get_id() or nil

        if (playing_card and playing_card.is_face and playing_card:is_face())
            or id == 14
        then
            return true
        end
    end

    return false
end

SMODS.Joker({
    key = 'adventurer',
    atlas = 'adventurer',
    pos = { x = 0, y = 0 },
    name = 'Adventurer',
    rarity = 1,
    cost = 4,

    config = {
        extra = {
            chips = 0,
            gain = 15,
        }
    },

    loc_txt = {
        name = 'Adventurer',
        text = {
            'Gains {C:chips}+#2#{} Chips if',
            'played hand contains',
            'a {C:attention}face card{} or {C:attention}Ace{}',
            '{C:inactive}(Currently {C:chips}+#1#{}{C:inactive} Chips){}',
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

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

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
            and hand_has_face_card_or_ace(context)
        then
            card.ability.extra.chips = get_chips(card) + get_gain(card)

            return {
                message = '+' .. tostring(get_gain(card)) .. ' Chips',
                colour = G.C.CHIPS,
            }
        end

        if context.joker_main and get_chips(card) > 0 then
            return {
                chip_mod = get_chips(card),
                message = '+' .. tostring(get_chips(card)),
            }
        end
    end,
})
