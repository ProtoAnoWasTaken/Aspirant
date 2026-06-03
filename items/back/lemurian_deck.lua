Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.lemurian_deck = Aspirant.lemurian_deck or {}

local AG_LEMURIAN_DECK = Aspirant.lemurian_deck
local AG_UTIL = Aspirant.joker_utils or {}

local LEMURIAN_DECK_KEYS = {
    "lemurian_deck",
    "b_lemurian_deck",
}

local function is_weithiwr_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered("Joker", "weithiwrhaearn")
        or false
end

local function center_matches_key(center, key)
    return center
        and (
            center.original_key == key
            or center.key == key
            or (type(center.key) == "string" and center.key:match(key .. "$") ~= nil)
        )
end

function AG_LEMURIAN_DECK.is_active()
    if G and G.GAME and G.GAME.ag_lemurian_deck_active then
        return true
    end

    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center

    for _, key in ipairs(LEMURIAN_DECK_KEYS) do
        if center_matches_key(center, key) then
            return true
        end
    end

    return false
end

local function convert_starting_deck_to_diamonds()
    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if playing_card and not playing_card.removed and not playing_card.getting_sliced then
            playing_card:change_suit("Diamonds")
        end
    end
end

local function add_starting_metalworker()
    local center = AG_UTIL.find_center_by_suffix and AG_UTIL.find_center_by_suffix("Joker", "weithiwrhaearn") or nil
    if not G or not G.jokers then
        return false
    end

    for _, joker in ipairs(G.jokers.cards or {}) do
        local joker_center = joker and joker.config and joker.config.center
        if AG_UTIL.center_matches and AG_UTIL.center_matches(joker_center, "weithiwrhaearn") then
            return true
        end
    end

    local metalworker_key = center and center.key or "j_tk9g_weithiwrhaearn"
    local added_card = SMODS.add_card({
        key = metalworker_key,
        area = G.jokers,
        bypass_discovery_center = true,
        allow_duplicates = true,
    })

    if added_card then
        return true
    end

    if center then
        local created_card = create_card("Joker", G.jokers, nil, nil, true, nil, center.key, "ag_lemurian_deck")
        if created_card then
            created_card:add_to_deck()
            G.jokers:emplace(created_card)
            created_card:start_materialize()

            if G.jokers.align_cards then
                G.jokers:align_cards()
            end

            return true
        end
    end

    return false
end

SMODS.Atlas({
    key = "lemurian_deck",
    path = "lemurian_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "lemurian_deck",
    atlas = "lemurian_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,

    loc_txt = {
        name = "Lemurian Deck",
        text = {
            "Start run with 52 {C:diamonds}Diamonds{}",
            "in deck and the",
            "{C:attention}Metalworker{}",
        },
    },

    locked_loc_vars = function()
        return { key = "ag_unlock_lemurian_deck", set = "Back" }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == "discover_amount" and is_weithiwr_discovered()
    end,

    config = {},

    apply = function(self)
        G.GAME.ag_lemurian_deck_active = true

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            func = function()
                if not G.playing_cards or not G.jokers then
                    return false
                end

                convert_starting_deck_to_diamonds()
                return add_starting_metalworker()
            end,
        }))
    end,
})
