SMODS.Atlas({
    key = 'manmadenephilim',
    path = 'manmadenephilim.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG_UTIL = Aspirant.joker_utils or {}
local SUITS = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function get_mult(card)
    local extra = get_extra(card)
    return extra and extra.mult or 0
end

local function get_gain(card)
    local extra = get_extra(card)
    return extra and extra.gain or 10
end

local function get_base_retriggers(card)
    local extra = get_extra(card)
    return extra and extra.base_retriggers or 4
end

local function get_suit_penalty(card)
    local extra = get_extra(card)
    return extra and extra.suit_penalty or 1
end

local function get_played_cards(context)
    local c = context and (context.other_context or context)
    if c and c.full_hand then
        return c.full_hand
    end
    if c and c.scoring_hand then
        return c.scoring_hand
    end
    if G and G.play and G.play.cards then
        return G.play.cards
    end
    return {}
end

local function get_unique_suit_count(cards)
    local unique_suits = 0
    for _, suit in ipairs(SUITS) do
        for _, playing_card in ipairs(cards or {}) do
            if playing_card and not playing_card.debuff and playing_card:is_suit(suit) then
                unique_suits = unique_suits + 1
                break
            end
        end
    end
    return unique_suits
end

local function get_retriggers(card, context)
    local cards = get_played_cards(context)
    local unique_suits = get_unique_suit_count(cards)

    local retriggers = get_base_retriggers(card) - (get_suit_penalty(card) * unique_suits)
    if unique_suits >= 4 then
        retriggers = math.max(1, retriggers)
    end

    return math.max(0, math.floor(retriggers))
end

local function sunken_below_is_unlocked()
    if G and G.ACHIEVEMENTS and G.ACHIEVEMENTS.sunken_below then
        return G.ACHIEVEMENTS.sunken_below.earned or false
    end
    return G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED and G.SETTINGS.ACHIEVEMENTS_EARNED.sunken_below or false
end

SMODS.Joker({
    key = 'manmadenephilim',
    atlas = 'manmadenephilim',
    pos = { x = 0, y = 0 },
    name = 'Manmade Nephilim',
    rarity = 4,
    cost = 20,

    config = {
        extra = {
            mult = 0,
            gain = 10,
            base_retriggers = 4,
            suit_penalty = 1,
        }
    },

    loc_txt = {
        name = 'Manmade Nephilim',
        text = {
            'Has the effects of the {C:attention}4 gathered Arms{}',
            'This Joker starts with {C:attention}#2#{} retriggers',
            'Lose {C:attention}#3#{} retrigger per unique suit in play',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult){}',
        }
    },

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    loc_vars = function(self, info_queue, card)
        local current_retriggers = get_retriggers(card)
        local extra = get_extra(card)

        info_queue[#info_queue + 1] = {
            key = 'ag_proposed_card',
            set = 'Other',
            vars = { 'v_ordhosbn' },
        }

        return {
            vars = {
                (extra and extra.mult) or 0,
                current_retriggers,
                (extra and extra.suit_penalty) or 1,
                (extra and extra.gain) or 10,
            }
        }
    end,

    locked_loc_vars = function()
        return { key = 'ag_unlock_achievement_sunken_below', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return sunken_below_is_unlocked()
    end,

    in_pool = function()
        return sunken_below_is_unlocked()
    end,

    calculate = function(self, card, context)
        if context.blueprint then return end

        local extra = get_extra(card)
        if not extra then return end
        local gain = extra.gain or 10

        local self_destructs = AG_UTIL.count_self_destructs and AG_UTIL.count_self_destructs(context, card) or 0

        if context.ag_lemurian_destroyed_card
            or context.ag_lemurian_created_card
            or self_destructs > 0
        then
            local gained_mult = self_destructs > 0 and (gain * self_destructs) or gain
            extra.mult = (extra.mult or 0) + gained_mult
            return {
                message = '+' .. tostring(gained_mult) .. ' Mult',
                colour = G.C.MULT,
            }
        end

        if context.retrigger_joker_check and context.other_card == card and not context.retrigger_joker then
            local retriggers = get_retriggers(card, context.other_context or context)
            if retriggers > 0 then
                return {
                    repetitions = retriggers,
                }
            end
        end

        if context.joker_main then
            local mult = extra.mult or 0
            if mult > 0 then
                return {
                    mult_mod = mult,
                    message = '+' .. tostring(mult),
                }
            end
        end
    end,
})
