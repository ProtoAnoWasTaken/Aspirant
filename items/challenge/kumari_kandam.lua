local AG = rawget(_G, 'Aspirant') or {}
AG.challenge_effects = AG.challenge_effects or {}

local KUMARI_KEY = 'c_tk9g_kumari_kandam'
local LEMURIAN_WEIGHT_MULT = 2

local function current_challenge_is_kumari()
    return G and G.GAME and G.GAME.challenge == KUMARI_KEY
end

local function is_lemurian_center(center)
    return center and center.pools and center.pools.Lemurian == true
end

local function install_lemurian_weights()
    if not (G and G.P_CENTERS) or AG.challenge_effects.kumari_lemurian_weights_installed then
        return
    end

    for _, center in pairs(G.P_CENTERS) do
        if is_lemurian_center(center) then
            local get_weight_ref = center.get_weight

            center.get_weight = function(self, ...)
                local weight = get_weight_ref and get_weight_ref(self, ...) or self.weight or 1

                if current_challenge_is_kumari() then
                    return weight * LEMURIAN_WEIGHT_MULT
                end

                return weight
            end
        end
    end

    AG.challenge_effects.kumari_lemurian_weights_installed = true
end

local function red_half_deck()
    local cards = {}
    local ranks = { '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' }

    for _, suit in ipairs({ 'D', 'H' }) do
        for _, rank in ipairs(ranks) do
            cards[#cards + 1] = { s = suit, r = rank }
        end
    end

    return cards
end

SMODS.Challenge({
    key = 'kumari_kandam',
    loc_txt = {
        name = 'Kumari Kandam',
    },
    rules = {
        custom = {},
        modifiers = {
            { id = 'hands', value = 3 },
            { id = 'discards', value = 3 },
        },
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck',
        cards = red_half_deck(),
    },
    restrictions = {
        banned_cards = {
            { id = 'j_erosion' },
        },
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        install_lemurian_weights()
    end,
})
