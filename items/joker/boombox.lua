SMODS.Atlas({
    key = 'boombox',
    path = 'boombox.png',
    px = 69,
    py = 93,
})

local BOOMBOX_CENTER_KEY = 'j_tk9g_boombox'
local CHERISHED_VINYL_CENTER_KEY = 'j_tk9g_cherishedvinyl'

local function vinyl_music_enabled()
    return Aspirant and Aspirant.config and Aspirant.config.vinyl_music == true
end

local function in_active_boss_blind()
    return G
        and G.GAME
        and G.GAME.blind
        and G.GAME.blind.boss
        and G.GAME.blind.in_blind
end

local function has_cherished_vinyl()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and joker.config.center.key == CHERISHED_VINYL_CENTER_KEY
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

local function streak_is_active(card)
    local extra = card and card.ability and card.ability.extra

    return extra
        and extra.streak_hand
        and (extra.streak_count or 0) > 0
        and not card.getting_sliced
end

local function boombox_music_blocked_by_vinyl()
    return in_active_boss_blind() and has_cherished_vinyl()
end

local function boombox_music_active(card)
    return vinyl_music_enabled()
        and streak_is_active(card)
        and not boombox_music_blocked_by_vinyl()
end

local function any_boombox_music_active()
    if not vinyl_music_enabled() or boombox_music_blocked_by_vinyl() then
        return false
    end

    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and joker.config.center.key == BOOMBOX_CENTER_KEY
            and streak_is_active(joker)
        then
            return true
        end
    end

    return false
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.25
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

local function reset_streak(card, scoring_name)
    card.ability.extra.xmult = 1
    card.ability.extra.streak_hand = scoring_name
    card.ability.extra.streak_count = scoring_name and 1 or 0
    card.ability.extra.misses = 0
end

local function update_streak(card, scoring_name)
    local extra = card.ability.extra

    if not scoring_name then
        return nil
    end

    if not extra.streak_hand then
        extra.streak_hand = scoring_name
        extra.streak_count = 1
        extra.misses = 0
        return {
            message = scoring_name,
            colour = G.C.ATTENTION,
        }
    end

    if scoring_name == extra.streak_hand then
        extra.streak_count = (extra.streak_count or 0) + 1
        extra.misses = 0
        extra.xmult = get_xmult(card) + get_gain(card)

        return {
            message = 'X' .. format_xmult(get_gain(card)),
            colour = G.C.MULT,
        }
    end

    extra.misses = (extra.misses or 0) + 1

    if extra.misses >= 2 then
        reset_streak(card, scoring_name)
        return {
            message = 'Reset!',
            colour = G.C.RED,
        }
    end

    return {
        message = 'Hold...',
        colour = G.C.ATTENTION,
    }
end

SMODS.Sound({
    key = 'music_egyptian',
    path = 'egyptian.ogg',
    sync = false,
    pitch = 1,
    volume = 1,
    select_music_track = function()
        return any_boombox_music_active() and 1e9 or nil
    end,
})

SMODS.Joker({
    key = 'boombox',
    atlas = 'boombox',
    pos = { x = 0, y = 0 },
    name = "Madman's Boombox",
    rarity = 3,
    cost = 8,

    config = { extra = { xmult = 1, gain = 0.25, streak_hand = nil, streak_count = 0, misses = 0, next_pulse = 0, was_music_active = false } },

    loc_txt = {
        name = "Madman's Boombox",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult for every",
            "consecutive same poker hand",
            "Resets {C:mult}Mult{} after {C:attention}2{} hands",
            "do not follow the streak",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive}){}",
            "{C:inactive}(Current Hand: {C:attention}#3#{}{C:inactive}){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
                (card.ability and card.ability.extra and card.ability.extra.streak_hand) or 'None',
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    draw = function(self, card, layer)
        if boombox_music_active(card) and card:should_draw_base_shader() then
            card.children.center:draw_shader('voucher', nil, card.ARGS.send_to_shader)
        end
    end,

    update = function(self, card, dt)
        if not card.ability or not card.ability.extra then
            return
        end

        local music_active = boombox_music_active(card)

        if music_active and not card.ability.extra.was_music_active then
            card.ability.extra.next_pulse = 0
        end

        card.ability.extra.was_music_active = music_active

        if music_active then
            local now = (G.TIMERS and G.TIMERS.REAL) or 0

            if now >= (card.ability.extra.next_pulse or 0) then
                card:juice_up(0.1, 0.1)
                card.ability.extra.next_pulse = now + 0.8
            end
        else
            card.ability.extra.next_pulse = 0
        end
    end,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            return update_streak(card, context.scoring_name)
        end

        if context.joker_main and Aspirant.joker_utils.compare_numbers(get_xmult(card), 'gt', 1) then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
