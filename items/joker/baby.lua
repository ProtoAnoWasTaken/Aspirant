SMODS.Atlas({
    key = 'baby',
    path = 'baby.png',
    px = 69,
    py = 93,
})

SMODS.Sound({
    key = 'babycry',
    path = 'babycry.ogg',
    prefix_config = { key = false },
})

local function get_face_cards_by_random_suit(excluded_suits)
    if not G.playing_cards or #G.playing_cards == 0 then
        return nil, {}
    end

    local suits = { 'Hearts', 'Diamonds', 'Clubs', 'Spades' }
    local valid_suits = {}

    for _, suit in ipairs(suits) do
        if not (excluded_suits and excluded_suits[suit]) then
            local matching_cards = {}

            for _, playing_card in ipairs(G.playing_cards) do
                if not playing_card.getting_sliced and playing_card:is_face() and playing_card:is_suit(suit) then
                    matching_cards[#matching_cards + 1] = playing_card
                end
            end

            if #matching_cards > 0 then
                valid_suits[#valid_suits + 1] = {
                    suit = suit,
                    cards = matching_cards,
                }
            end
        end
    end

    if #valid_suits == 0 then
        return nil, {}
    end

    local chosen = pseudorandom_element(valid_suits, pseudoseed('ag_baby_suit'))
    return chosen.suit, chosen.cards
end

local function get_negative_target(source_card, excluded_jokers)
    local jokers = {}

    if not G.jokers or not G.jokers.cards then
        return nil
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= source_card
            and not joker.getting_sliced
            and not (joker.edition and joker.edition.negative)
            and not (excluded_jokers and excluded_jokers[joker])
        then
            jokers[#jokers + 1] = joker
        end
    end

    if #jokers == 0 then
        return nil
    end

    return pseudorandom_element(jokers, pseudoseed('ag_baby_negative'))
end

local function trigger_baby_effect(card)
    local repeats = card:is_food() and 2 or 1
    if Aspirant and Aspirant.food and Aspirant.food.scale_value then
        repeats = math.max(1, math.floor(Aspirant.food.scale_value(card, repeats)))
    end
    local destroyed_groups = {}
    local negative_targets = {}
    local used_suits = {}
    local used_jokers = {}

    for _ = 1, repeats do
        local suit, destroyed_cards = get_face_cards_by_random_suit(used_suits)
        local negative_target = get_negative_target(card, used_jokers)

        if suit and #destroyed_cards > 0 then
            used_suits[suit] = true
            destroyed_groups[#destroyed_groups + 1] = destroyed_cards
        end

        if negative_target then
            used_jokers[negative_target] = true
            negative_targets[#negative_targets + 1] = negative_target
        end
    end

    play_sound('babycry')

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            for _, destroyed_cards in ipairs(destroyed_groups) do
                SMODS.destroy_cards(destroyed_cards)
            end

            for _, negative_target in ipairs(negative_targets) do
                negative_target:set_edition({ negative = true }, true, true)
            end

            return true
        end
    }))
end

local function unlock_champion_acolyte_achievement()
    if check_for_unlock then
        check_for_unlock({ type = 'champion_acolyte' })
        return
    end

    if unlock_achievement then
        unlock_achievement('champion_acolyte')
    end
end

SMODS.Joker({
    key = 'baby',
    atlas = 'baby',
    pos = { x = 0, y = 0 },
    name = 'Baby',
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = 'Baby',
        text = {
            "When sold or destroyed, destroy all {C:attention}face{} cards",
            "of a random suit, then apply {C:dark_edition}Negative{}",
            "to a random {C:attention}Joker{}",
        }
    },

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if context.selling_self or (context.joker_type_destroyed and context.card == card) then
            unlock_champion_acolyte_achievement()
            trigger_baby_effect(card)
        end
    end,
})
