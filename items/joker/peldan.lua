SMODS.Atlas({
    key = 'peldan',
    path = 'peldan.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function format_xmult(value)
    return AG_UTIL.format_xmult and AG_UTIL.format_xmult(value) or tostring(value)
end

local function get_steel_count()
    local total = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.getting_sliced
            and SMODS.has_enhancement(playing_card, 'm_steel')
        then
            total = total + 1
        end
    end

    return total
end

local function get_threshold(card)
    return (card.ability and card.ability.extra and card.ability.extra.threshold) or 7
end

local function get_base_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.base_xmult) or 3
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.1
end

local function get_xmult(card)
    local steel_count = get_steel_count()
    local threshold = get_threshold(card)

    if steel_count < threshold then
        return 1, steel_count
    end

    local extra_steel = steel_count - threshold
    return get_base_xmult(card) + (get_gain(card) * extra_steel), steel_count
end

local function grisial_feistr_is_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'grisialfeistr')
        or false
end

SMODS.Joker({
    key = 'peldan',
    atlas = 'peldan',
    pos = { x = 0, y = 0 },
    name = "Pêl Dân",
    rarity = 3,
    cost = 8,

    config = { extra = { threshold = 7, base_xmult = 3, gain = 0.1 } },

    loc_txt = {
        name = "Pêl Dân",
        text = {
            "{X:mult,C:white}X#2#{} Mult if you have at least",
            "{C:attention}#3#{} {C:attention,T:m_steel}Steel Cards{} in your {C:attention}full deck{}",
            "Gain {X:mult,C:white}X#4#{} Mult for each",
            "additional {C:attention,T:m_steel}Steel Card{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} with #5# Steel Cards){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        local xmult, steel_count = get_xmult(card)

        info_queue[#info_queue + 1] = G.P_CENTERS.m_steel

        return {
            vars = {
                format_xmult(xmult),
                format_xmult(get_base_xmult(card)),
                get_threshold(card),
                format_xmult(get_gain(card)),
                steel_count,
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_discover_grisialfeistr', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and grisial_feistr_is_discovered()
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = get_xmult(card)

            if xmult > 1 then
                return {
                    Xmult_mod = xmult,
                    message = 'X' .. format_xmult(xmult),
                }
            end
        end
    end,
})
