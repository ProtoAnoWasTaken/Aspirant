SMODS.Atlas({
    key = 'moldwarp',
    path = 'moldwarp.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local AG_UTIL = AG.joker_utils or {}
local GOLD_CENTER_KEY = 'm_gold'
local LUCKY_CENTER_KEY = 'm_lucky'
local GOLDEN_TICKET_KEY = 'j_ticket'

AG.moldwarp_state = AG.moldwarp_state or {}

local function is_moldwarp_joker(joker)
    local center = joker and joker.config and joker.config.center
    local key = center and center.key
    local original_key = center and center.original_key

    return joker
        and not joker.getting_sliced
        and center
        and (
            original_key == 'moldwarp'
            or key == 'moldwarp'
            or (type(key) == 'string' and key:match('moldwarp$') ~= nil)
        )
end

local function get_moldwarp_signature(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return 0
    end

    local signature = 17

    for i, joker in ipairs(G.jokers.cards) do
        if joker ~= ignore_card and is_moldwarp_joker(joker) then
            signature = signature * 131 + i
        end
    end

    return signature
end

local function get_active_moldwarp(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return nil, 0
    end

    local active_joker = nil
    local count = 0

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= ignore_card and is_moldwarp_joker(joker) then
            active_joker = joker
            count = count + 1
        end
    end

    return active_joker, count
end

local function peldan_is_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'peldan')
        or false
end

local function get_golden_ticket_bonus()
    if not G or not G.jokers or not G.jokers.cards then
        return 0
    end

    local bonus = 0

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        if joker
            and not joker.debuff
            and not joker.getting_sliced
            and center
            and center.key == GOLDEN_TICKET_KEY
        then
            bonus = bonus + (center.config and center.config.extra or 0)
        end
    end

    return bonus
end

function AG.refresh_moldwarp_state(ignore_card)
    local gold_center = G.P_CENTERS and G.P_CENTERS[GOLD_CENTER_KEY]
    local lucky_center = G.P_CENTERS and G.P_CENTERS[LUCKY_CENTER_KEY]

    if not gold_center or not gold_center.config or not lucky_center or not lucky_center.config then
        return
    end

    if AG.moldwarp_state.refresh_in_progress then
        return
    end

    AG.moldwarp_state.refresh_in_progress = true

    if not AG.moldwarp_state.defaults then
        AG.moldwarp_state.defaults = {
            gold_h_dollars = gold_center.config.h_dollars,
            lucky_mult = lucky_center.config.mult,
            lucky_p_dollars = lucky_center.config.p_dollars,
        }
    end

    local defaults = AG.moldwarp_state.defaults
    local signature = get_moldwarp_signature(ignore_card)
    local active_joker, count = get_active_moldwarp(ignore_card)
    local multiplier = 2 ^ count

    gold_center.config.h_dollars = defaults.gold_h_dollars * multiplier
    lucky_center.config.mult = defaults.lucky_mult * multiplier
    lucky_center.config.p_dollars = defaults.lucky_p_dollars * multiplier

    AG.moldwarp_state.signature = signature
    AG.moldwarp_state.active_joker = active_joker
    AG.moldwarp_state.count = count
    AG.moldwarp_state.multiplier = multiplier

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card and playing_card.ability then
            if SMODS.has_enhancement(playing_card, GOLD_CENTER_KEY) then
                playing_card.ability.h_dollars = gold_center.config.h_dollars
            end

            if SMODS.has_enhancement(playing_card, LUCKY_CENTER_KEY) then
                playing_card.ability.mult = lucky_center.config.mult
                playing_card.ability.p_dollars = lucky_center.config.p_dollars
            end

            if G.GAME and G.GAME.blind then
                G.GAME.blind:debuff_card(playing_card)
            end
        end
    end

    AG.moldwarp_state.refresh_in_progress = false
end

function AG.ensure_moldwarp_state_current(ignore_card)
    if AG.moldwarp_state.refresh_in_progress then
        return
    end

    if AG.moldwarp_state.signature ~= get_moldwarp_signature(ignore_card) then
        AG.refresh_moldwarp_state(ignore_card)
    end
end

SMODS.Joker({
    key = 'moldwarp',
    atlas = 'moldwarp',
    pos = { x = 0, y = 0 },
    name = 'Moldwarp',
    rarity = 3,
    cost = 8,

    loc_txt = {
        name = 'Moldwarp',
        text = {
            "{C:gold,T:m_gold}Gold Cards{} and {C:attention,T:m_lucky}Lucky Cards{}",
            "have a {C:attention}doubled{} effect",
            "{C:inactive}(including{} {C:green,E:1}probabilities{}{C:inactive}){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
        info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
        return { vars = {} }
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_discover_peldan', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and peldan_is_discovered()
    end,

    add_to_deck = function(self, card, from_debuff)
        AG.refresh_moldwarp_state()
    end,

    remove_from_deck = function(self, card, from_debuff)
        AG.refresh_moldwarp_state(card)
    end,

    update = function(self, card, dt)
        AG.ensure_moldwarp_state_current()
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        AG.ensure_moldwarp_state_current()

        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and SMODS.has_enhancement(context.other_card, GOLD_CENTER_KEY)
            and AG.moldwarp_state
            and AG.moldwarp_state.active_joker == card
            and AG.moldwarp_state.multiplier
            and AG.moldwarp_state.multiplier > 1
        then
            local golden_ticket_bonus = get_golden_ticket_bonus()
                * (AG.moldwarp_state.multiplier - 1)

            if golden_ticket_bonus > 0 then
                return {
                    dollars = golden_ticket_bonus,
                }
            end
        end

        if context.fix_probability
            and AG.moldwarp_state
            and AG.moldwarp_state.active_joker == card
            and AG.moldwarp_state.multiplier
            and AG.moldwarp_state.multiplier > 1
            and (
                context.identifier == 'lucky_mult'
                or context.identifier == 'lucky_money'
            )
        then
            return {
                numerator = context.numerator * AG.moldwarp_state.multiplier,
                denominator = context.denominator,
            }
        end
    end,
})
