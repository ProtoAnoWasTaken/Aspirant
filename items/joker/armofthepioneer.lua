SMODS.Atlas({
    key = 'armofthepioneer',
    path = 'armofthepioneer.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function try_combine(card)
    if AG_UTIL.try_combine_arms
        and not card.getting_sliced
        and G
        and G.jokers
        and card.area == G.jokers
    then
        AG_UTIL.try_combine_arms(card)
    end
end

SMODS.Joker({
    key = 'armofthepioneer',
    atlas = 'armofthepioneer',
    pos = { x = 0, y = 0 },
    name = 'Arm of the Pioneer',
    rarity = 2,
    cost = 7,

    loc_txt = {
        name = 'Arm of the Pioneer',
        text = {
            '{C:inactive}The arm lays inert... for now{}',
        }
    },

    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = function(self, card)
        try_combine(card)
    end,

    update = function(self, card, dt)
        try_combine(card)
    end,
})
