SMODS.Atlas({
    key = 'mandragora',
    path = 'mandragora.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local AG_UTIL = AG.joker_utils or {}

AG.mandragora = AG.mandragora or {}

local function is_valid_card_object(card)
    return type(card) == 'table' and card.ability ~= nil
end

local function get_self_protect_source(card)
    return 'ag_mandragora_self_' .. tostring(card)
end

local function has_self_protect(card)
    return is_valid_card_object(card)
        and card.ability.debuff_sources
        and card.ability.debuff_sources[get_self_protect_source(card)] ~= nil
end

local function clear_self_protect(card)
    if is_valid_card_object(card) then
        SMODS.debuff_card(card, false, get_self_protect_source(card))
    end
end

local function protect_self(card)
    if not is_valid_card_object(card) or card.getting_sliced then
        return
    end

    clear_self_protect(card)
    SMODS.debuff_card(card, 'prevent_debuff', get_self_protect_source(card))
end

local function is_mandragora_card(card)
    local center = card and card.config and card.config.center
    local key = center and center.key
    local original_key = center and center.original_key

    return key == 'j_tk9g_mandragora'
        or original_key == 'mandragora'
        or (type(key) == 'string' and key:match('mandragora$') ~= nil)
end

local function has_active_mandragora()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and not joker.getting_sliced
            and not joker.debuff
            and is_mandragora_card(joker)
        then
            return true
        end
    end

    return false
end

local function is_permanently_disabled(card)
    local ability = card and card.ability

    if not ability then
        return false
    end

    if ability.perma_debuff then
        return true
    end

    if ability.perishable and ability.perish_tally == 0 then
        return true
    end

    return false
end

local function should_proxy_debuff(card, context)
    if not is_valid_card_object(card) or not card.debuff then
        return false
    end

    if context and context.ag_mandragora_proxy then
        return false
    end

    if is_permanently_disabled(card) then
        return false
    end

    return has_active_mandragora()
end

local function with_debuff_suppressed(card, callback)
    local original_debuff = card.debuff
    card.debuff = false

    local results = { n = 0 }

    local function capture(...)
        results.n = select('#', ...)
        for i = 1, results.n do
            results[i] = select(i, ...)
        end
    end

    capture(pcall(callback))

    card.debuff = original_debuff

    if not results[1] then
        error(results[2])
    end

    return unpack(results, 2, results.n)
end

local function copy_context_with_proxy_flag(context)
    local copied = {}

    if context then
        for k, v in pairs(context) do
            copied[k] = v
        end
    end

    copied.ag_mandragora_proxy = true
    return copied
end

local function find_center_by_suffix(suffix)
    return AG_UTIL.find_center_by_suffix and AG_UTIL.find_center_by_suffix('Joker', suffix) or nil
end

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function has_joker_room()
    return G
        and G.jokers
        and G.jokers.cards
        and G.jokers.config
        and (#G.jokers.cards + (G.GAME.joker_buffer or 0) < G.jokers.config.card_limit)
end

local function create_readied_erbario()
    local erbario_center = find_center_by_suffix('erbario')

    if not erbario_center or not has_joker_room() then
        return false
    end

    local erbario = create_card('Joker', G.jokers, nil, nil, true, nil, erbario_center.key, 'ag_mandragora')

    erbario:add_to_deck()
    G.jokers:emplace(erbario)
    erbario:start_materialize()

    local extra = erbario.ability and erbario.ability.extra
    if extra then
        extra.hands_kept = extra.delay or 5
        extra.destroy_ready = true
        extra.next_pulse = 0
    end

    if G.jokers.align_cards then
        G.jokers:align_cards()
    end

    erbario:juice_up(0.4, 0.5)
    return true
end

if not AG.mandragora.hooks_installed then
    AG.mandragora.hooks_installed = true

    AG.mandragora.original_eval_card = eval_card

    function eval_card(card, context)
        if should_proxy_debuff(card, context) then
            return with_debuff_suppressed(card, function()
                return AG.mandragora.original_eval_card(card, copy_context_with_proxy_flag(context))
            end)
        end

        return AG.mandragora.original_eval_card(card, context)
    end

    AG.mandragora.original_calculate_joker = Card.calculate_joker

    function Card:calculate_joker(context)
        if should_proxy_debuff(self, context) then
            return with_debuff_suppressed(self, function()
                return AG.mandragora.original_calculate_joker(self, copy_context_with_proxy_flag(context))
            end)
        end

        return AG.mandragora.original_calculate_joker(self, context)
    end

    AG.mandragora.original_calculate_seal = Card.calculate_seal

    function Card:calculate_seal(context)
        if should_proxy_debuff(self, context) then
            return with_debuff_suppressed(self, function()
                return AG.mandragora.original_calculate_seal(self, copy_context_with_proxy_flag(context))
            end)
        end

        return AG.mandragora.original_calculate_seal(self, context)
    end

    AG.mandragora.original_get_end_of_round_effect = Card.get_end_of_round_effect

    function Card:get_end_of_round_effect(context)
        if should_proxy_debuff(self, context) then
            return with_debuff_suppressed(self, function()
                return AG.mandragora.original_get_end_of_round_effect(self, copy_context_with_proxy_flag(context))
            end)
        end

        return AG.mandragora.original_get_end_of_round_effect(self, context)
    end
end

SMODS.Joker({
    key = 'mandragora',
    atlas = 'mandragora',
    pos = { x = 0, y = 0 },
    name = 'Mandragora',
    rarity = 4,
    cost = 20,

    loc_txt = {
        name = 'Mandragora',
        text = {
            'Reinstates effects of',
            '{C:attention}debuffed{} cards',
            'Create a readied {C:attention}Erbario{}',
            'in final hand of a {C:attention}Boss Blind{}',
        }
    },

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = 'joker_locked_legendary', set = 'Other' }
    end,

    calculate = function(self, card, context)
        local extra = get_extra(card)

        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            if extra then
                extra.ag_erbario_spawned_this_round = false
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0,
                func = function()
                    protect_self(card)
                    return true
                end,
            }))
        end

        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and G
            and G.GAME
            and G.GAME.blind
            and G.GAME.blind:get_type() == 'Boss'
            and G.GAME.current_round
            and G.GAME.current_round.hands_left <= 0
            and extra
            and not extra.ag_erbario_spawned_this_round
        then
            if create_readied_erbario() then
                extra.ag_erbario_spawned_this_round = true
                return {
                    message = '+Erbario',
                    colour = G.C.BLUE,
                }
            end
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            if extra then
                extra.ag_erbario_spawned_this_round = false
            end
            clear_self_protect(card)
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        local extra = get_extra(card)
        if extra then
            extra.ag_erbario_spawned_this_round = false
        end

        if not from_debuff then
            clear_self_protect(card)
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
            and has_self_protect(card)
        then
            clear_self_protect(card)
        end
    end,
})
