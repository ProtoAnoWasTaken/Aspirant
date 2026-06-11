SMODS.Atlas({
    key = 'cherishedvinyl',
    path = 'cherishedvinyl.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}
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
            and not joker.getting_sliced then
            return true
        end
    end

    return false
end

local function vinyl_music_active()
    return vinyl_music_enabled() and in_active_boss_blind() and has_cherished_vinyl()
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

SMODS.Sound({
    key = 'music_astrofiends',
    path = 'astrofiends.ogg',
    sync = false,
    pitch = 1,
    volume = 1,
    select_music_track = function()
        return vinyl_music_active() and 1e9 or nil
    end,
})

SMODS.Joker({
    key = 'cherishedvinyl',
    atlas = 'cherishedvinyl',
    pos = { x = 0, y = 0 },
    name = 'Cherished Vinyl',
    rarity = 2,
    cost = 6,

    config = { extra = { xmult = 2, next_pulse = 0, was_music_active = false } },

    loc_txt = {
        name = 'Cherished Vinyl',
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "{C:attention}Boss Blind{} uses {C:attention}Astrofiends{}",
            "{C:green}1 in 3{} chance this Joker {C:red,E:2}self destructs{}",
            "at end of round",
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { format_xmult(card.ability.extra.xmult) } }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    draw = function(self, card, layer)
        if vinyl_music_active() and card:should_draw_base_shader() then
            card.children.center:draw_shader('voucher', nil, card.ARGS.send_to_shader)
        end
    end,

    update = function(self, card, dt)
        if not card.ability or not card.ability.extra then
            return
        end

        local music_active = vinyl_music_active() and not card.getting_sliced

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
        if context.joker_main then
            return {
                Xmult_mod = card.ability.extra.xmult,
                message = 'X' .. format_xmult(card.ability.extra.xmult),
            }
        end

        if context.end_of_round and context.main_eval and not context.blueprint and not card.getting_sliced then
            if pseudorandom('ag_cherishedvinyl_destroy') > 0.66 then
                local destroy_message = pseudorandom('ag_cherishedvinyl_destroy_message') > 0.95
                    and 'He was destroyed!'
                    or 'Destroyed!'

                if Aspirant and Aspirant.unlock_dear_sweet_music then
                    Aspirant.unlock_dear_sweet_music()
                end

                if AG_UTIL.destroy_card then
                    AG_UTIL.destroy_card(card, {
                        colours = { G.C.RED },
                        self_destruct = true,
                        source_card = card,
                    })
                else
                    card.getting_sliced = true
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            if card and not card.removed then
                                play_sound('glass' .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                                card:start_dissolve({ G.C.RED }, nil, 1.6)
                            end
                            return true
                        end,
                    }))
                end

                return {
                    message = destroy_message,
                    colour = G.C.RED,
                }
            end

            return {
                message = 'Safe!',
                colour = G.C.GREEN,
            }
        end
    end,
})
