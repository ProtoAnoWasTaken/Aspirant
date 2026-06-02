SMODS.Atlas({
    key = 'starlightobelisk',
    path = 'starlightobelisk.png',
    px = 69,
    py = 93,
})

local AG = rawget(_G, 'Aspirant') or {}
local AG_UTIL = AG.joker_utils or {}

local function format_xmult(value)
    return AG_UTIL.format_xmult and AG_UTIL.format_xmult(value) or tostring(value)
end

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or {}
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.1
end

local function get_upgrade_denominator(card)
    return (card.ability and card.ability.extra and card.ability.extra.upgrade_odds) or 5
end

local function center_matches(center, suffix)
    local key = center and center.key
    local original_key = center and center.original_key

    return center
        and (
            original_key == suffix
            or key == suffix
            or (type(key) == 'string' and key:match(suffix .. '$') ~= nil)
        )
end

local function cloud_cradle_is_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'cloudcradle')
        or false
end

local function is_joker_card(card)
    local center = card and card.config and card.config.center
    return center and center.set == 'Joker'
end

local function was_joker_destroyed_by_another_joker(card, context)
    if context.blueprint then
        return false
    end

    if context.destroyed_card
        and context.source_card
        and context.destroyed_card ~= card
        and context.source_card ~= context.destroyed_card
        and is_joker_card(context.destroyed_card)
        and is_joker_card(context.source_card)
    then
        return true
    end

    return context.joker_type_destroyed
        and not context.selling_self
        and context.card
        and context.card ~= card
        and is_joker_card(context.card)
end

local function find_starlight_seal()
    for _, seal in pairs((G and G.P_SEALS) or {}) do
        if center_matches(seal, 'starlight') then
            return seal
        end
    end

    if SMODS and SMODS.Seals then
        for _, seal in pairs(SMODS.Seals) do
            if center_matches(seal, 'starlight') then
                return seal
            end
        end
    end

    return nil
end

local function get_random_seal_target()
    local targets = {}

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if playing_card
            and not playing_card.removed
            and not playing_card.getting_sliced
            and not playing_card.seal
        then
            targets[#targets + 1] = playing_card
        end
    end

    if #targets == 0 then
        return nil
    end

    return pseudorandom_element(targets, pseudoseed('ag_starlight_obelisk_target'))
end

local function try_create_starlight_seal(source_card)
    local seal = find_starlight_seal()
    local target = get_random_seal_target()
    local numerator = G and G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1

    if not seal or not target then
        return false
    end

    if not SMODS.pseudorandom_probability(
        source_card,
        'ag_starlight_obelisk_seal',
        numerator,
        get_upgrade_denominator(source_card),
        'ag_starlight_obelisk_seal'
    ) then
        return false
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            if target and not target.removed then
                target:set_seal(seal.key, true)
                target:juice_up(0.3, 0.3)

                card_eval_status_text(target, 'extra', nil, nil, nil, {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.STARLIGHT or G.C.ATTENTION,
                })
            end
            return true
        end,
    }))

    return true
end

SMODS.Joker({
    key = 'starlightobelisk',
    atlas = 'starlightobelisk',
    pos = { x = 0, y = 0 },
    name = 'Starlight Obelisk',
    rarity = 3,
    cost = 8,

    config = {
        extra = {
            xmult = 1,
            gain = 0.1,
            upgrade_odds = 5,
        }
    },

    loc_txt = {
        name = 'Starlight Obelisk',
        text = {
            'This Joker gains {X:mult,C:white}X#2#{} Mult',
            'per {C:attention}Joker{} destroyed by another {C:attention}Joker{}',
            '{C:green}#3# in #4#{} chance to create a {C:starlight,T:starlight_seal}Starlight Seal{}',
            'on a random card when upgraded',
            '{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive}){}',
        }
    },

    loc_vars = function(self, info_queue, card)
        local seal = find_starlight_seal()
        if seal then
            info_queue[#info_queue + 1] = seal
        end

        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
                G and G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1,
                get_upgrade_denominator(card),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = 'ag_unlock_discover_cloudcradle', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and cloud_cradle_is_discovered()
    end,

    calculate = function(self, card, context)
        if context.blueprint or card.getting_sliced then
            return
        end

        if was_joker_destroyed_by_another_joker(card, context) then
            local extra = get_extra(card)
            extra.xmult = get_xmult(card) + get_gain(card)
            try_create_starlight_seal(card)

            return {
                message = 'X' .. format_xmult(get_gain(card)),
                colour = G.C.MULT,
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
