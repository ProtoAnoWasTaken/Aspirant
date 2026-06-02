SMODS.Atlas({
    key = "caurus",
    path = "caurus.png",
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, "Aspirant") or {}

local AG = Aspirant
local GLASS_CENTER_KEY = "m_glass"
local CAURUS_CENTER_KEY = "j_tk9g_caurus"
local SKIRON_CENTER_KEY = "j_tk9g_skiron"

AG.glass_state = AG.glass_state or {}

local function get_glass_state_signature(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return 0
    end

    local signature = 17

    for i, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        local key = center and center.key

        if joker ~= ignore_card
            and not joker.getting_sliced
            and (key == CAURUS_CENTER_KEY or key == SKIRON_CENTER_KEY)
        then
            signature = signature * 131 + i
            signature = signature * 17 + (key == CAURUS_CENTER_KEY and 1 or 2)
        end
    end

    return signature
end

local function get_rightmost_glass_joker_key(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return nil
    end

    local rightmost_key = nil

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        local key = center and center.key

        if joker ~= ignore_card
            and not joker.getting_sliced
            and (key == CAURUS_CENTER_KEY or key == SKIRON_CENTER_KEY)
        then
            rightmost_key = key
        end
    end

    return rightmost_key
end

function AG.refresh_glass_state(ignore_card)
    local glass_center = G.P_CENTERS and G.P_CENTERS[GLASS_CENTER_KEY]
    if not glass_center or not glass_center.config then
        return
    end

    if AG.glass_state.refresh_in_progress then
        return
    end

    AG.glass_state.refresh_in_progress = true

    if not AG.glass_state.defaults then
        AG.glass_state.defaults = {
            Xmult = glass_center.config.Xmult,
            x_mult = glass_center.config.x_mult,
            extra = glass_center.config.extra,
        }
    end

    local defaults = AG.glass_state.defaults
    local signature = get_glass_state_signature(ignore_card)
    local active_key = get_rightmost_glass_joker_key(ignore_card)
    local caurus_active = active_key == CAURUS_CENTER_KEY
    local skiron_active = active_key == SKIRON_CENTER_KEY

    glass_center.config.Xmult = caurus_active and 3 or defaults.Xmult
    glass_center.config.x_mult = caurus_active and 3 or defaults.x_mult
    glass_center.config.extra = caurus_active and 3 or defaults.extra

    AG.glass_state.signature = signature
    AG.glass_state.active_key = active_key
    AG.glass_state.caurus_active = caurus_active
    AG.glass_state.skiron_active = skiron_active

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card.ability and SMODS.has_enhancement(playing_card, GLASS_CENTER_KEY) then
            playing_card.ability.x_mult = glass_center.config.Xmult or glass_center.config.x_mult or 1
            playing_card.ability.extra = glass_center.config.extra

            if G.GAME and G.GAME.blind then
                G.GAME.blind:debuff_card(playing_card)
            end
        end
    end

    AG.glass_state.refresh_in_progress = false
end

function AG.ensure_glass_state_current(ignore_card)
    if AG.glass_state.refresh_in_progress then
        return
    end

    if AG.glass_state.signature ~= get_glass_state_signature(ignore_card) then
        AG.refresh_glass_state(ignore_card)
    end
end

SMODS.Joker({
    key = "caurus",
    atlas = "caurus",
    pos = { x = 0, y = 0 },
    name = "Caurus",
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = "Caurus",
        text = {
            "{C:attention,t:m_glass}Glass Cards{} provide {X:mult,C:white}X3{} Mult,",
            "but break more easily {C:inactive}(1 in 3){}",
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_glass
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = "ag_unlock_achievement_champion_acolyte", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == "champion_acolyte"
    end,

    add_to_deck = function(self, card, from_debuff)
        AG.refresh_glass_state()
    end,

    remove_from_deck = function(self, card, from_debuff)
        AG.refresh_glass_state(card)
    end,

    update = function(self, card, dt)
        AG.ensure_glass_state_current()
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end
    end,
})
