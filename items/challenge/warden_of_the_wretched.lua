local WARDEN_KEY = 'c_tk9g_warden_of_the_wretched'
local ERBARIO_ONLY_RULE_2 = {
    id = 'ag_erbario_only_2',
    equal_edition_weights = true,
}

local function is_warden_challenge()
    return G and G.GAME and (
        G.GAME.challenge == WARDEN_KEY
        or G.GAME.challenge == 'warden_of_the_wretched'
    )
end

local function equal_edition_weights_enabled()
    return is_warden_challenge() and ERBARIO_ONLY_RULE_2.equal_edition_weights
end

local function polling_erbario_edition()
    return equal_edition_weights_enabled()
        and Aspirant
        and Aspirant.voucher_effects
        and Aspirant.voucher_effects.polling_joker_edition
end

local warden_poll_rarity_ref = SMODS.poll_rarity

function SMODS.poll_rarity(pool_key, rand_key)
    if is_warden_challenge() and pool_key == 'Joker' then
        return 1
    end

    return warden_poll_rarity_ref(pool_key, rand_key)
end

local warden_poll_edition_ref = poll_edition

function poll_edition(key, modifier, no_negative, guaranteed, options)
    if not polling_erbario_edition() then
        return warden_poll_edition_ref(key, modifier, no_negative, guaranteed, options)
    end

    local roll_key = (key or 'edition_generic') .. '_warden_erbario'
    if pseudorandom(pseudoseed(roll_key)) >= 0.5 then
        return nil
    end

    if SMODS.optional_features and SMODS.optional_features.object_weights then
        return warden_poll_edition_ref(key, modifier, no_negative, true, options)
    end

    local equal_options = {}
    local source = options or get_current_pool('Edition', nil, nil, key or 'edition_generic')

    for _, option in ipairs(source) do
        local edition_key = type(option) == 'table' and (option.name or option.key) or option
        if edition_key ~= 'UNAVAILABLE' and not (no_negative and edition_key == 'e_negative') then
            equal_options[#equal_options + 1] = { name = edition_key, weight = 1 }
        end
    end

    return warden_poll_edition_ref(key, modifier, no_negative, true, equal_options)
end

local function all_jokers_except_erbario()
    local banned = {}

    for _, center in pairs((G and G.P_CENTERS) or {}) do
        local is_erbario = center.original_key == 'erbario'
            or center.key == 'erbario'
            or center.key == 'j_tk9g_erbario'

        if center.key and center.set == 'Joker' and not is_erbario then
            banned[#banned + 1] = { id = center.key }
        end
    end

    table.sort(banned, function(a, b) return a.id < b.id end)
    return banned
end

local function joker_creating_tags()
    local banned = {}

    for key, tag in pairs((G and G.P_TAGS) or {}) do
        local config = tag.config or {}
        local tag_key = tag.key or key
        if config.type == 'store_joker_create'
            or (type(config.spawn_jokers) == 'number' and config.spawn_jokers > 0)
            or tag_key == 'tag_buffoon'
        then
            banned[#banned + 1] = { id = tag_key }
        end
    end

    table.sort(banned, function(a, b) return a.id < b.id end)
    return banned
end

SMODS.Challenge({
    key = 'warden_of_the_wretched',
    loc_txt = {
        name = 'Warden of the Wretched',
    },
    rules = {
        custom = {
            { id = 'ag_erbario_only' },
            ERBARIO_ONLY_RULE_2,
            { id = 'ag_erbario_only_3' },
            { id = 'ag_erbario_only_4' },
            { id = 'ag_erbario_only_5' },
        },
        modifiers = {
            { id = 'hands', value = 6 },
            { id = 'discards', value = 2 },
        },
    },
    jokers = {},
    consumeables = {},
    vouchers = {
        { id = 'v_tk9g_hyperdontia' },
        { id = 'v_overstock_norm' },
    },
    deck = {
        type = 'Challenge Deck',
    },
    restrictions = {
        banned_cards = all_jokers_except_erbario,
        banned_tags = joker_creating_tags,
        banned_other = {},
    },
    calculate = function(self, context)
        if polling_erbario_edition()
            and context.modify_weights
            and context.pool_types
            and context.pool_types.Edition
        then
            local total_weight = 0
            local count = #(context.pool or {})

            for _, weight in ipairs(context.pool or {}) do
                total_weight = total_weight + weight.weight
            end

            if count > 0 then
                local equal_weight = total_weight / count
                for _, weight in ipairs(context.pool) do
                    weight.weight = equal_weight
                end
            end
        end
    end,
})
