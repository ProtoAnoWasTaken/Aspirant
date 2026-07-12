SMODS.Atlas({
    key = 'sandcompass',
    path = 'sandcompass.png',
    px = 69,
    py = 93,
})

local function get_unlocked_hands()
    local hands = {}

    for hand_key, hand_data in pairs(G.GAME.hands or {}) do
        if hand_data and hand_data.visible then
            hands[#hands + 1] = hand_key
        end
    end

    table.sort(hands)
    return hands
end

local SUITS = { 'Hearts', 'Diamonds', 'Clubs', 'Spades' }

local function get_available_deck_cards()
    if G.playing_cards and #G.playing_cards > 0 then
        return G.playing_cards
    end

    if G.deck and G.deck.cards and #G.deck.cards > 0 then
        return G.deck.cards
    end

    return (G.hand and G.hand.cards) or {}
end

local function get_card_rank(card)
    if not card then
        return nil
    end

    if card.get_id then
        local id = card:get_id()
        if type(id) == 'number' and id > 0 then
            return id
        end
    end

    if card.base and type(card.base.id) == 'number' and card.base.id > 0 then
        return card.base.id
    end

    return nil
end

local function get_matching_suits(card)
    local matching_suits = {}

    if not card or not card.is_suit then
        return matching_suits
    end

    for _, suit in ipairs(SUITS) do
        if card:is_suit(suit) then
            matching_suits[#matching_suits + 1] = suit
        end
    end

    return matching_suits
end

local function get_hand_analysis(cards)
    local analysis = {
        rank_counts = {},
        suit_counts = {},
        suit_rank_counts = {},
        ranks = {},
        rank_cards = 0,
        playable_cards = #cards,
    }

    for _, suit in ipairs(SUITS) do
        analysis.suit_counts[suit] = 0
        analysis.suit_rank_counts[suit] = {}
    end

    for _, held_card in ipairs(cards) do
        local rank = get_card_rank(held_card)
        local suits = get_matching_suits(held_card)

        if rank then
            analysis.rank_cards = analysis.rank_cards + 1
            analysis.rank_counts[rank] = (analysis.rank_counts[rank] or 0) + 1
        end

        for _, suit in ipairs(suits) do
            analysis.suit_counts[suit] = analysis.suit_counts[suit] + 1
            if rank then
                analysis.suit_rank_counts[suit][rank] = (analysis.suit_rank_counts[suit][rank] or 0) + 1
            end
        end
    end

    for rank in pairs(analysis.rank_counts) do
        analysis.ranks[#analysis.ranks + 1] = rank
    end

    table.sort(analysis.ranks)
    return analysis
end

local function count_groups_at_least(rank_counts, minimum)
    local total = 0

    for _, count in pairs(rank_counts) do
        if count >= minimum then
            total = total + 1
        end
    end

    return total
end

local function has_n_of_a_kind(rank_counts, amount)
    return count_groups_at_least(rank_counts, amount) > 0
end

local function has_full_house(rank_counts)
    local triple_count = count_groups_at_least(rank_counts, 3)
    local pair_count = count_groups_at_least(rank_counts, 2)

    return triple_count >= 1 and (pair_count >= 2 or triple_count >= 2)
end

local function has_straight(ranks)
    if #ranks < 5 then
        return false
    end

    local unique_ranks = {}

    for _, rank in ipairs(ranks) do
        unique_ranks[#unique_ranks + 1] = rank
    end

    if unique_ranks[#unique_ranks] == 14 then
        unique_ranks[#unique_ranks + 1] = 1
    end

    table.sort(unique_ranks)

    local run = 1
    for i = 2, #unique_ranks do
        if unique_ranks[i] == unique_ranks[i - 1] + 1 then
            run = run + 1
            if run >= 5 then
                return true
            end
        elseif unique_ranks[i] ~= unique_ranks[i - 1] then
            run = 1
        end
    end

    return false
end

local function can_make_hand(hand_key, cards)
    local analysis = get_hand_analysis(cards)

    if hand_key == 'High Card' then
        return analysis.playable_cards > 0
    end

    if hand_key == 'Pair' then
        return has_n_of_a_kind(analysis.rank_counts, 2)
    end

    if hand_key == 'Two Pair' then
        return count_groups_at_least(analysis.rank_counts, 2) >= 2
    end

    if hand_key == 'Three of a Kind' then
        return has_n_of_a_kind(analysis.rank_counts, 3)
    end

    if hand_key == 'Straight' then
        return has_straight(analysis.ranks)
    end

    if hand_key == 'Flush' then
        for _, suit in ipairs(SUITS) do
            if analysis.suit_counts[suit] >= 5 then
                return true
            end
        end

        return false
    end

    if hand_key == 'Full House' then
        return has_full_house(analysis.rank_counts)
    end

    if hand_key == 'Four of a Kind' then
        return has_n_of_a_kind(analysis.rank_counts, 4)
    end

    if hand_key == 'Straight Flush' then
        for _, suit in ipairs(SUITS) do
            local suit_ranks = {}

            if analysis.suit_counts[suit] >= 5 then
                for rank in pairs(analysis.suit_rank_counts[suit]) do
                    suit_ranks[#suit_ranks + 1] = rank
                end

                table.sort(suit_ranks)
                if has_straight(suit_ranks) then
                    return true
                end
            end
        end

        return false
    end

    if hand_key == 'Five of a Kind' then
        return has_n_of_a_kind(analysis.rank_counts, 5)
    end

    if hand_key == 'Flush House' then
        for _, suit in ipairs(SUITS) do
            if analysis.suit_counts[suit] >= 5 and has_full_house(analysis.suit_rank_counts[suit]) then
                return true
            end
        end

        return false
    end

    if hand_key == 'Flush Five' then
        for _, suit in ipairs(SUITS) do
            for _, count in pairs(analysis.suit_rank_counts[suit]) do
                if count >= 5 then
                    return true
                end
            end
        end

        return false
    end

    return false
end

local function set_random_target_hand(card)
    local unlocked_hands = get_unlocked_hands()
    local current_target = card.ability.extra.target_hand
    local makeable_hands = {}
    local valid_hands = {}
    local available_deck_cards = get_available_deck_cards()

    for _, hand_key in ipairs(unlocked_hands) do
        if can_make_hand(hand_key, available_deck_cards) then
            makeable_hands[#makeable_hands + 1] = hand_key

            if hand_key ~= current_target then
                valid_hands[#valid_hands + 1] = hand_key
            end
        end
    end

    local pool = {}

    if #valid_hands > 0 then
        pool = valid_hands
    elseif #makeable_hands > 0 then
        pool = makeable_hands
    elseif #available_deck_cards == 0 then
        pool = unlocked_hands
    end

    local target = #pool > 0 and pseudorandom_element(pool, pseudoseed('ag_sandcompass')) or nil

    card.ability.extra.target_hand = target
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 5
end

local function get_mult(card)
    return (card.ability and card.ability.extra and card.ability.extra.mult) or 0
end

local function scored_target_hand(card, context)
    local target_hand = card.ability.extra.target_hand

    if not target_hand then
        return false
    end

    return context.scoring_name and context.scoring_name == target_hand
end

SMODS.Joker({
    key = 'sandcompass',
    atlas = 'sandcompass',
    pos = { x = 0, y = 0 },
    name = 'Sand Compass',
    rarity = 2,
    cost = 6,

    config = { extra = { mult = 0, gain = 5, target_hand = nil } },

    loc_txt = {
        name = 'Sand Compass',
        text = {
            "This Joker gains {C:mult}+#3#{} Mult if",
            "played hand is {C:attention}#1#{}",
            "Hand changes every round",
            "{C:inactive}(Currently {C:mult}+#2#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.target_hand or '???',
                get_mult(card),
                get_gain(card),
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
            if scored_target_hand(card, context) then
                local gain = get_gain(card)
                card.ability.extra.gain = gain
                card.ability.extra.mult = get_mult(card) + gain
                return {
                    message = '+' .. gain .. ' Mult',
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(get_mult(card)) then
            return {
                mult_mod = get_mult(card),
                message = '+' .. get_mult(card) .. ' Mult',
            }
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            set_random_target_hand(card)
            return {
                message = card.ability.extra.target_hand or '...',
                colour = G.C.ATTENTION,
            }
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        if not card.ability.extra.target_hand then
            set_random_target_hand(card)
        end
    end,
})
