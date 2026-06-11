SMODS.Atlas({
    key = 'tombfeeder',
    path = 'tombfeeder.png',
    px = 69,
    py = 93,
})

local Aspirant = rawget(_G, 'Aspirant') or {}
local AG = Aspirant
AG.tombfeeder_state = AG.tombfeeder_state or {}

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

local function get_level_ups(context)
    if not context then
        return 0
    end

    if context.ag_tombfeeder_level_up then
        return math.max(0, tonumber(context.level_ups) or 0)
    end

    if not context.poker_hand_changed then
        return 0
    end

    if AG.tombfeeder_state.suppressed_level_up_card
        and context.card == AG.tombfeeder_state.suppressed_level_up_card
    then
        return 0
    end

    local old_level = tonumber(context.old_level)
    local new_level = tonumber(context.new_level)

    if old_level and new_level then
        return math.max(0, new_level - old_level)
    end

    return 1
end

local function get_hand_level(hand)
    local hand_data = type(hand) == 'string' and G and G.GAME and G.GAME.hands and G.GAME.hands[hand] or nil
    return hand_data and tonumber(hand_data.level) or nil
end

local function get_level_up_amount(old_level, new_level, amount)
    if old_level and new_level then
        return math.max(0, new_level - old_level)
    end

    return math.max(0, tonumber(amount) or 1)
end

local function ensure_tombfeeder_level_up_hook()
    if AG.tombfeeder_state.level_up_hand_hooked or type(level_up_hand) ~= 'function' then
        return
    end

    AG.tombfeeder_state.original_level_up_hand = level_up_hand

    level_up_hand = function(card, hand, instant, amount, statustext)
        local old_level = get_hand_level(hand)
        local previous_suppressed_card = AG.tombfeeder_state.suppressed_level_up_card
        AG.tombfeeder_state.suppressed_level_up_card = card

        local result = AG.tombfeeder_state.original_level_up_hand(card, hand, instant, amount, statustext)

        AG.tombfeeder_state.suppressed_level_up_card = previous_suppressed_card

        local new_level = get_hand_level(hand)
        local level_ups = get_level_up_amount(old_level, new_level, amount)

        if level_ups > 0 and SMODS and SMODS.calculate_context then
            SMODS.calculate_context({
                ag_tombfeeder_level_up = true,
                card = card,
                scoring_name = hand,
                old_level = old_level,
                new_level = new_level,
                level_ups = level_ups,
            })
        end

        return result
    end

    AG.tombfeeder_state.level_up_hand_hooked = true
end

ensure_tombfeeder_level_up_hook()

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

        local level_ups = get_level_ups(context)
        if level_ups > 0 and not context.blueprint then
            card.ability.extra.planets_used = (card.ability.extra.planets_used or 0) + level_ups
            local gained_mult = card.ability.extra.planet_mult * level_ups
            return {
                message = '+' .. gained_mult .. ' Mult',
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
