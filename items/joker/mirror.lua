SMODS.Atlas({
    key = 'mirror',
    path = 'mirror.png',
    px = 69,
    py = 93,
})

local function is_valid_card_object(card)
    return type(card) == 'table' and card.ability ~= nil
end

local function get_self_debuff_source(card)
    return 'ag_mirror_self_' .. tostring(card)
end

local function get_protect_source(card)
    return 'ag_mirror_protect_' .. tostring(card)
end

local function has_round_state(card)
    if not is_valid_card_object(card) or not card.ability.debuff_sources then
        return false
    end

    if card.ability.debuff_sources[get_self_debuff_source(card)] ~= nil then
        return true
    end

    if G and G.jokers and G.jokers.cards then
        for _, joker in ipairs(G.jokers.cards) do
            if is_valid_card_object(joker)
                and joker.ability.debuff_sources
                and joker.ability.debuff_sources[get_protect_source(card)] ~= nil
            then
                return true
            end
        end
    end

    return false
end

local function get_adjacent_jokers(source_card)
    local adjacent = {}

    if not G or not G.jokers or not G.jokers.cards then
        return adjacent
    end

    for i, joker in ipairs(G.jokers.cards) do
        if joker == source_card then
            local left_joker = G.jokers.cards[i - 1]
            local right_joker = G.jokers.cards[i + 1]

            if left_joker and not left_joker.getting_sliced then
                adjacent[#adjacent + 1] = left_joker
            end

            if right_joker and not right_joker.getting_sliced then
                adjacent[#adjacent + 1] = right_joker
            end

            break
        end
    end

    return adjacent
end

local function clear_round_state(card)
    if G and G.jokers and G.jokers.cards then
        for _, joker in ipairs(G.jokers.cards) do
            if is_valid_card_object(joker) then
                SMODS.debuff_card(joker, false, get_protect_source(card))
            end
        end
    end

    if is_valid_card_object(card) then
        SMODS.debuff_card(card, false, get_self_debuff_source(card))
    end
end

local function get_debuffed_adjacent_joker(card)
    for _, joker in ipairs(get_adjacent_jokers(card)) do
        if joker.debuff then
            return joker
        end
    end

    return nil
end

local function reflect_debuff(card)
    if not is_valid_card_object(card) or card.getting_sliced then
        return
    end

    clear_round_state(card)

    local target = get_debuffed_adjacent_joker(card)

    if not target then
        return
    end

    SMODS.debuff_card(target, 'prevent_debuff', get_protect_source(card))
    SMODS.debuff_card(card, true, get_self_debuff_source(card))

    target:juice_up()
    card:juice_up()

    card_eval_status_text(target, 'extra', nil, nil, nil, {
        message = 'Reflected!',
        colour = G.C.GREEN,
    })

    card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = localize('k_debuffed'),
        colour = G.C.RED,
    })
end

SMODS.Joker({
    key = 'mirror',
    atlas = 'mirror',
    pos = { x = 0, y = 0 },
    name = 'Mirror',
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = 'Mirror',
        text = {
            "Assumes the debuff of an",
            "adjacent {C:attention}Joker{} in its stead",
        }
    },

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0,
                func = function()
                    reflect_debuff(card)
                    return true
                end,
            }))
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            clear_round_state(card)
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        if not from_debuff then
            clear_round_state(card)
        end
    end,

    update = function(self, card, dt)
        if not is_valid_card_object(card) or card.getting_sliced then
            return
        end

        if G
            and G.GAME
            and G.GAME.blind
            and not G.GAME.blind.in_blind
            and has_round_state(card)
        then
            clear_round_state(card)
        end
    end,
})
