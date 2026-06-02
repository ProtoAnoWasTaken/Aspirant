SMODS.Atlas({
    key = 'sitehbar',
    path = 'sitehbar.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local STEEL_CENTER_KEY = 'm_steel'
local SITEHBAR_CENTER_KEY = 'j_tk9g_sitehbar'

AG.steel_state = AG.steel_state or {}

local function get_steel_state_signature(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return 0
    end

    local signature = 17

    for i, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        local key = center and center.key

        if joker ~= ignore_card
            and not joker.getting_sliced
            and key == SITEHBAR_CENTER_KEY
        then
            signature = signature * 131 + i
        end
    end

    return signature
end

local function get_rightmost_steel_joker_key(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return nil
    end

    local rightmost_key = nil

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        local key = center and center.key

        if joker ~= ignore_card
            and not joker.getting_sliced
            and key == SITEHBAR_CENTER_KEY
        then
            rightmost_key = key
        end
    end

    return rightmost_key
end

function AG.refresh_steel_state(ignore_card)
    local steel_center = G.P_CENTERS and G.P_CENTERS[STEEL_CENTER_KEY]
    if not steel_center or not steel_center.config then
        return
    end

    if AG.steel_state.refresh_in_progress then
        return
    end

    AG.steel_state.refresh_in_progress = true

    if not AG.steel_state.defaults then
        AG.steel_state.defaults = {
            x_mult = steel_center.config.x_mult,
            h_x_mult = steel_center.config.h_x_mult,
        }
    end

    local defaults = AG.steel_state.defaults
    local signature = get_steel_state_signature(ignore_card)
    local active_key = get_rightmost_steel_joker_key(ignore_card)
    local sitehbar_active = active_key == SITEHBAR_CENTER_KEY

    steel_center.config.x_mult = sitehbar_active and 2 or defaults.x_mult
    steel_center.config.h_x_mult = sitehbar_active and 1.25 or defaults.h_x_mult

    AG.steel_state.signature = signature
    AG.steel_state.active_key = active_key
    AG.steel_state.sitehbar_active = sitehbar_active

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card.ability and SMODS.has_enhancement(playing_card, STEEL_CENTER_KEY) then
            playing_card.ability.x_mult = steel_center.config.x_mult or playing_card.ability.x_mult or 1
            playing_card.ability.h_x_mult = steel_center.config.h_x_mult or playing_card.ability.h_x_mult or 1

            if G.GAME and G.GAME.blind then
                G.GAME.blind:debuff_card(playing_card)
            end
        end
    end

    AG.steel_state.refresh_in_progress = false
end

function AG.ensure_steel_state_current(ignore_card)
    if AG.steel_state.refresh_in_progress then
        return
    end

    if AG.steel_state.signature ~= get_steel_state_signature(ignore_card) then
        AG.refresh_steel_state(ignore_card)
    end
end

SMODS.Joker({
    key = 'sitehbar',
    atlas = 'sitehbar',
    pos = { x = 0, y = 0 },
    name = 'Sitehbar',
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = 'Sitehbar',
        text = {
            "{C:attention,T:m_steel}Steel Cards{} give {X:mult,C:white}X2{} Mult",
            "when scored and {X:mult,C:white}X1.25{}",
            "when held in hand",
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_steel
    end,

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = function(self, card, from_debuff)
        AG.refresh_steel_state()
    end,

    remove_from_deck = function(self, card, from_debuff)
        AG.refresh_steel_state(card)
    end,

    update = function(self, card, dt)
        AG.ensure_steel_state_current()
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end
    end,
})
