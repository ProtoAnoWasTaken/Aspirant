SMODS.Atlas({
    key = 'seal_starlight',
    path = 'seal_starlight.png',
    px = 69,
    py = 93,
})

local AG = rawget(_G, 'Aspirant') or {}
local AG_UTIL = AG.joker_utils or {}

local function compare_numbers(left, operator, right)
    if AG_UTIL.compare_numbers then
        return AG_UTIL.compare_numbers(left, operator, right)
    end

    if operator == 'gt' then return left > right end
    if operator == 'neq' then return left ~= right end
    return false
end

local function get_rank(card)
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

local function same_rank_card_scored(card, context)
    local held_rank = get_rank(card)
    if not held_rank then
        return false
    end

    for _, scored_card in ipairs((context and context.scoring_hand) or {}) do
        if scored_card ~= card and get_rank(scored_card) == held_rank then
            return true
        end
    end

    return false
end

local function get_seal_state(card)
    card.ability = card.ability or {}
    card.ability.seal = card.ability.seal or {}
    return card.ability.seal
end

local function get_glass_break_denominator(card)
    local denominator = card and card.ability and card.ability.extra or 4

    if type(denominator) ~= 'number' or denominator <= 0 then
        return 4
    end

    return denominator
end

local function try_trigger_glass_break(card)
    if not card or card.removed or card.getting_sliced then
        return
    end

    if AG.ensure_glass_state_current then
        AG.ensure_glass_state_current()
    end

    local numerator = G
        and G.GAME
        and G.GAME.probabilities
        and G.GAME.probabilities.normal
        or 1

    if not SMODS.pseudorandom_probability(
        card,
        'ag_starlight_glass_break',
        numerator,
        get_glass_break_denominator(card),
        'glass'
    ) then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.05,
        func = function()
            if not card or card.removed or card.getting_sliced then
                return true
            end

            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = 'Destroyed!',
                colour = G.C.RED,
            })

            if AG_UTIL.destroy_card then
                AG_UTIL.destroy_card(card, {
                    colours = { G.C.RED },
                    delay = 0,
                    self_destruct = true,
                    source_card = card,
                })
            else
                card.getting_sliced = true
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end

            return true
        end,
    }))
end

local function get_held_trigger_effect(card)
    local effect = {}

    local h_mult = card:get_chip_h_mult()
    if compare_numbers(h_mult, 'neq', 0) then
        effect.h_mult = h_mult
    end

    local h_x_mult = card:get_chip_h_x_mult()
    if compare_numbers(h_x_mult, 'gt', 1) then
        effect.x_mult = h_x_mult
    end

    local h_chips = card:get_chip_h_bonus()
    if compare_numbers(h_chips, 'neq', 0) then
        effect.h_chips = h_chips
    end

    local h_x_chips = card:get_chip_h_x_bonus()
    if compare_numbers(h_x_chips, 'gt', 1) then
        effect.x_chips = h_x_chips
    end

    local h_score = card:get_bonus_h_score()
    if compare_numbers(h_score, 'neq', 0) then
        effect.h_score = h_score
    end

    local h_x_score = card:get_bonus_h_x_score()
    if compare_numbers(h_x_score, 'gt', 1) then
        effect.h_x_score = h_x_score
    end

    local h_blind_size = card:get_bonus_h_blind_size()
    if compare_numbers(h_blind_size, 'neq', 0) then
        effect.blind_size = h_blind_size
    end

    local h_x_blind_size = card:get_bonus_h_x_blind_size()
    if compare_numbers(h_x_blind_size, 'gt', 1) then
        effect.x_blind_size = h_x_blind_size
    end

    if next(effect) then
        effect.message = localize('k_again_ex')
        effect.colour = G.C.STARLIGHT or G.C.ATTENTION
    end

    return next(effect) and effect or nil
end

local function get_scored_trigger_effect(card, context)
    if card
        and card.ability
        and card.ability.effect == 'Glass Card'
    then
        try_trigger_glass_break(card)

        local x_mult = card.ability.x_mult or 1
        if compare_numbers(x_mult, 'gt', 1) then
            return {
                x_mult = x_mult,
            }
        end

        return nil
    end

    local effect = {}

    local chips = card:get_chip_bonus()
    if compare_numbers(chips, 'neq', 0) then
        effect.chips = chips
    end

    local mult = card:get_chip_mult()
    if compare_numbers(mult, 'neq', 0) then
        effect.mult = mult
    end

    local x_mult = card:get_chip_x_mult(context)
    if compare_numbers(x_mult, 'gt', 1) then
        effect.x_mult = x_mult
    end

    local p_dollars = card:get_p_dollars()
    if compare_numbers(p_dollars, 'neq', 0) then
        effect.p_dollars = p_dollars
    end

    local x_chips = card:get_chip_x_bonus()
    if compare_numbers(x_chips, 'gt', 1) then
        effect.x_chips = x_chips
    end

    local score = card:get_bonus_score()
    if compare_numbers(score, 'neq', 0) then
        effect.score = score
    end

    local x_score = card:get_bonus_x_score()
    if compare_numbers(x_score, 'gt', 1) then
        effect.x_score = x_score
    end

    local blind_size = card:get_bonus_blind_size()
    if compare_numbers(blind_size, 'neq', 0) then
        effect.blind_size = blind_size
    end

    local x_blind_size = card:get_bonus_x_blind_size()
    if compare_numbers(x_blind_size, 'gt', 1) then
        effect.x_blind_size = x_blind_size
    end

    return next(effect) and effect or nil
end

local function uses_held_trigger_mode(card)
    return card
        and card.ability
        and (
            card.ability.effect == 'Steel Card'
            or card.ability.effect == 'Gold Card'
            or (card.ability.h_mult or 0) ~= 0
            or (card.ability.h_x_mult or 0) > 0
            or (card.ability.h_chips or 0) ~= 0
            or (card.ability.h_x_chips or 0) > 1
            or (card.ability.h_dollars or 0) ~= 0
        )
end

local function get_end_of_round_trigger_effect(card, context)
    local effect = card:get_end_of_round_effect(context)
    if effect and next(effect) then
        effect.message = effect.message or localize('k_again_ex')
        effect.colour = effect.colour or (G.C.STARLIGHT or G.C.ATTENTION)
        return effect
    end

    return nil
end

SMODS.Seal({
    key = 'starlight',
    atlas = 'seal_starlight',
    pos = { x = 0, y = 0 },
    badge_colour = G.C.STARLIGHT,
    discovered = true,

    loc_txt = {
        label = 'Starlight Seal',
        name = 'Starlight Seal',
        text = {
            'Triggers in hand if',
            'a card of the same',
            'rank scores',
        }
    },

    calculate = function(self, card, context)
        local seal_state = get_seal_state(card)

        if context.setting_blind then
            seal_state.ag_starlight_triggered = false
            return
        end

        if context.main_scoring
            and context.cardarea == G.hand
            and not context.end_of_round
            and not card.debuff
            and same_rank_card_scored(card, context)
        then
            seal_state.ag_starlight_triggered = true
            if uses_held_trigger_mode(card) then
                return get_held_trigger_effect(card)
            end

            return get_scored_trigger_effect(card, context)
        end

        if context.end_of_round
            and context.playing_card_end_of_round
            and context.cardarea == G.hand
            and not card.debuff
            and seal_state.ag_starlight_triggered
        then
            local effect = get_end_of_round_trigger_effect(card, context)
            seal_state.ag_starlight_triggered = false
            return effect
        end

        if context.end_of_round and context.main_eval then
            seal_state.ag_starlight_triggered = false
        end
    end,
})
