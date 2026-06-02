SMODS.Atlas({
    key = 'desecratedobelisk',
    path = 'desecratedobelisk.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function format_xmult(value)
    return AG_UTIL.format_xmult and AG_UTIL.format_xmult(value) or tostring(value)
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.2
end

local function get_top_played_hands()
    local top_hands = {}
    local top_played = 0

    if not G or not G.GAME or not G.GAME.hands then
        return top_hands, top_played
    end

    for hand_name, hand in pairs(G.GAME.hands) do
        local played = hand and hand.played or 0

        if hand and hand.visible and played > 0 then
            if played > top_played then
                top_played = played
                top_hands = { [hand_name] = true }
            elseif played == top_played then
                top_hands[hand_name] = true
            end
        end
    end

    return top_hands, top_played
end

local function find_matching_hand_name(value)
    if type(value) == 'string' then
        return G and G.GAME and G.GAME.hands and G.GAME.hands[value] and value or nil
    end

    if type(value) ~= 'table' then
        return nil
    end

    for key, nested in pairs(value) do
        if G and G.GAME and G.GAME.hands and G.GAME.hands[key] then
            return key
        end

        local nested_match = find_matching_hand_name(nested)
        if nested_match then
            return nested_match
        end
    end

    for _, nested in ipairs(value) do
        local nested_match = find_matching_hand_name(nested)
        if nested_match then
            return nested_match
        end
    end

    return nil
end

local function evaluate_discarded_hand_name(cards)
    if not cards or #cards == 0 then
        return nil
    end

    local evaluators = {
        function()
            return G and G.FUNCS and G.FUNCS.get_poker_hand_info and G.FUNCS.get_poker_hand_info(cards)
        end,
        function()
            return get_poker_hand_info and get_poker_hand_info(cards)
        end,
        function()
            return evaluate_poker_hand and evaluate_poker_hand(cards)
        end,
    }

    for _, evaluator in ipairs(evaluators) do
        local ok, a, b, c, d, e = pcall(evaluator)
        if ok then
            local hand_name = find_matching_hand_name(a)
                or find_matching_hand_name(b)
                or find_matching_hand_name(c)
                or find_matching_hand_name(d)
                or find_matching_hand_name(e)

            if hand_name then
                return hand_name
            end
        end
    end

    return nil
end

local function discarded_most_played_hand(context)
    local top_hands, top_played = get_top_played_hands()
    if top_played <= 0 then
        return false
    end

    local discarded_hand = evaluate_discarded_hand_name((context and context.full_hand) or {})
    return discarded_hand and top_hands[discarded_hand] or false
end

SMODS.Joker({
    key = 'desecratedobelisk',
    atlas = 'desecratedobelisk',
    pos = { x = 0, y = 0 },
    name = 'Desecrated Obelisk',
    rarity = 3,
    cost = 8,

    config = { extra = { xmult = 1, gain = 0.2 } },

    loc_txt = {
        name = 'Desecrated Obelisk',
        text = {
            'This Joker gains {X:mult,C:white}X#2#{} Mult',
            'per hands of your most played',
            'poker hand discarded',
            'Resets at end of {C:attention}Ante{}',
            '{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}',
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.pre_discard
            and not context.blueprint
            and not card.getting_sliced
            and discarded_most_played_hand(context)
        then
            card.ability.extra.xmult = get_xmult(card) + get_gain(card)

            return {
                message = 'X' .. format_xmult(get_gain(card)),
                colour = G.C.MULT,
            }
        end

        if context.end_of_round
            and context.main_eval
            and not context.blueprint
            and G
            and G.GAME
            and G.GAME.blind
            and G.GAME.blind.boss
            and get_xmult(card) > 1
        then
            card.ability.extra.xmult = 1

            return {
                message = 'Reset!',
                colour = G.C.RED,
            }
        end

        if context.joker_main and get_xmult(card) > 1 then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
