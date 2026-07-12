SMODS.Atlas({
    key = 'growth',
    path = 'growth.png',
    px = 69,
    py = 93,
})

local function get_debuffed_played_count(context)
    local total = 0
    local scoring_cards = context.scoring_hand or context.full_hand or {}

    for _, played_card in ipairs(scoring_cards) do
        if played_card and played_card.debuff then
            total = total + 1
        end
    end

    return total
end

local function card_is_in_list(target, cards)
    for _, card in ipairs(cards or {}) do
        if card == target then
            return true
        end
    end

    return false
end

local function has_consumeable_room()
    return G.consumeables
        and G.consumeables.cards
        and G.consumeables.config
        and (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0) < G.consumeables.config.card_limit)
end

local function joker_would_proc_this_hand(joker, context)
    if not joker or joker.getting_sliced then
        return false
    end

    local function calculate_without_persisting_state(test_context)
        local original_ability = joker.ability and copy_table(joker.ability) or nil
        local original_edition = joker.edition and copy_table(joker.edition) or nil
        local original_getting_sliced = joker.getting_sliced

        local effect, triggered = joker:calculate_joker(test_context)

        joker.ability = original_ability
        joker.edition = original_edition
        joker.getting_sliced = original_getting_sliced

        return effect ~= nil or triggered
    end

    local base_context = {
        cardarea = G.jokers,
        full_hand = context.full_hand,
        scoring_hand = context.scoring_hand,
        scoring_name = context.scoring_name,
        poker_hands = context.poker_hands,
    }

    if calculate_without_persisting_state({
        cardarea = base_context.cardarea,
        full_hand = base_context.full_hand,
        scoring_hand = base_context.scoring_hand,
        scoring_name = base_context.scoring_name,
        poker_hands = base_context.poker_hands,
        before = true,
    }) then
        return true
    end

    if calculate_without_persisting_state({
        cardarea = base_context.cardarea,
        full_hand = base_context.full_hand,
        scoring_hand = base_context.scoring_hand,
        scoring_name = base_context.scoring_name,
        poker_hands = base_context.poker_hands,
        after = true,
    }) then
        return true
    end

    if calculate_without_persisting_state({
        cardarea = base_context.cardarea,
        full_hand = base_context.full_hand,
        scoring_hand = base_context.scoring_hand,
        scoring_name = base_context.scoring_name,
        poker_hands = base_context.poker_hands,
        joker_main = true,
    }) then
        return true
    end

    for _, scoring_card in ipairs(base_context.scoring_hand or {}) do
        if scoring_card and calculate_without_persisting_state({
            cardarea = base_context.cardarea,
            full_hand = base_context.full_hand,
            scoring_hand = base_context.scoring_hand,
            scoring_name = base_context.scoring_name,
            poker_hands = base_context.poker_hands,
            individual = true,
            other_card = scoring_card,
        }) then
            return true
        end
    end

    for _, other_joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        if other_joker and other_joker ~= joker and not other_joker.getting_sliced then
            if calculate_without_persisting_state({
                full_hand = base_context.full_hand,
                scoring_hand = base_context.scoring_hand,
                scoring_name = base_context.scoring_name,
                poker_hands = base_context.poker_hands,
                other_joker = other_joker,
                other_main = other_joker,
            }) then
                return true
            end
        end
    end

    return false
end

local function get_debuffed_triggering_joker_count(card, context)
    local total = 0

    for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        if joker and joker ~= card and joker.debuff and joker_would_proc_this_hand(joker, context) then
            total = total + 1
        end
    end

    return total
end

local function get_debuffed_before_proc_card_count(context)
    local total = 0
    local scoring_cards = context.scoring_hand or context.full_hand or {}

    for _, played_card in ipairs(scoring_cards) do
        if played_card and played_card.debuff then
            if played_card.seal == 'Gold' then
                total = total + 1
            end

            if played_card.seal == 'Red' then
                total = total + 1
            end
        end
    end

    for _, held_card in ipairs((G.hand and G.hand.cards) or {}) do
        if held_card
            and held_card.debuff
            and not card_is_in_list(held_card, context.full_hand)
            and SMODS.has_enhancement(held_card, 'm_steel')
        then
            total = total + 1
        end
    end

    return total
end

local function get_debuffed_end_of_round_proc_card_count()
    local total = 0

    for _, held_card in ipairs((G.hand and G.hand.cards) or {}) do
        if held_card and held_card.debuff then
            if SMODS.has_enhancement(held_card, 'm_gold') then
                total = total + 1
            end

            if held_card.seal == 'Blue'
                and not (held_card.ability and held_card.ability.extra_enhancement)
                and has_consumeable_room()
            then
                total = total + 1
            end
        end
    end

    return total
end

local function get_debuffed_discard_proc_card_count(context)
    local discarded_card = context.other_card

    if discarded_card
        and discarded_card.debuff
        and discarded_card.seal == 'Purple'
        and has_consumeable_room()
    then
        return 1
    end

    return 0
end

local function grow_chips(card, proc_count)
    if proc_count <= 0 then
        return
    end

    local gained_chips = proc_count * card.ability.extra.gain
    card.ability.extra.chips = card.ability.extra.chips + gained_chips

    return {
        message = '+' .. gained_chips .. ' Chips',
        colour = G.C.CHIPS,
    }
end

SMODS.Joker({
    key = 'growth',
    atlas = 'growth',
    pos = { x = 0, y = 0 },
    name = 'Growth',
    rarity = 2,
    cost = 6,

    config = { extra = { chips = 0, gain = 15 } },

    loc_txt = {
        name = 'Growth',
        text = {
            "Every time a {C:mult}debuffed{} card",
            "would be triggered, this",
            "Joker gains {C:chips}+#3#{} Chips",
            "{C:inactive}(Currently {C:chips}+#2#{}{C:inactive} Chips){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
                card.ability.extra.chips,
                card.ability.extra.gain,
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
        then
            local debuffed_count = get_debuffed_played_count(context)
                + get_debuffed_triggering_joker_count(card, context)
                + get_debuffed_before_proc_card_count(context)

            return grow_chips(card, debuffed_count)
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            return grow_chips(card, get_debuffed_end_of_round_proc_card_count())
        end

        if context.discard and not context.blueprint then
            return grow_chips(card, get_debuffed_discard_proc_card_count(context))
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(card.ability.extra.chips) then
            return {
                chip_mod = card.ability.extra.chips,
                message = '+' .. card.ability.extra.chips .. ' Chips',
            }
        end
    end,
})
