Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.timebuilder_deck = Aspirant.timebuilder_deck or {}

local AG_TIMEBUILDER_DECK = Aspirant.timebuilder_deck
local AG_UTIL = Aspirant.joker_utils or {}

local TIMEBUILDER_DECK_KEYS = {
    "timebuilder_deck",
    "b_timebuilder_deck",
}

local function is_cloud_cradle_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered("Joker", "cloudcradle")
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

function AG_TIMEBUILDER_DECK.is_active()
    if G and G.GAME and G.GAME.ag_timebuilder_deck_active then
        return true
    end

    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center

    for _, key in ipairs(TIMEBUILDER_DECK_KEYS) do
        if center_matches_key(center, key) then
            return true
        end
    end

    return false
end

local function find_starlight_seal()
    for _, seal in pairs((G and G.P_SEALS) or {}) do
        if center_matches_key(seal, "starlight") then
            return seal
        end
    end

    if SMODS and SMODS.Seals then
        for _, seal in pairs(SMODS.Seals) do
            if center_matches_key(seal, "starlight") then
                return seal
            end
        end
    end

    return nil
end

local function get_unsealed_playing_cards()
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

    return targets
end

local function add_starlight_seals(count, status_message)
    local seal = find_starlight_seal()
    local candidates = get_unsealed_playing_cards()

    if not seal or #candidates == 0 then
        return false
    end

    local added_any = false

    for index = 1, math.min(count or 0, #candidates) do
        local target = pseudorandom_element(candidates, pseudoseed("ag_timebuilder_seal_" .. tostring(index)))

        if not target then
            break
        end

        for candidate_index, candidate in ipairs(candidates) do
            if candidate == target then
                table.remove(candidates, candidate_index)
                break
            end
        end

        target:set_seal(seal.key, true)
        target:juice_up(0.3, 0.3)
        added_any = true

        if status_message then
            card_eval_status_text(target, "extra", nil, nil, nil, {
                message = status_message,
                colour = G.C.STARLIGHT or G.C.ATTENTION,
            })
        end
    end

    return added_any
end

local function add_starting_cryptid()
    if not G or not G.consumeables then
        return false
    end

    return SMODS.add_card({
        key = "c_cryptid",
        area = G.consumeables,
        bypass_discovery_center = true,
        allow_duplicates = true,
    }) ~= nil
end

SMODS.Atlas({
    key = "timebuilder_deck",
    path = "timebuilder_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "timebuilder_deck",
    atlas = "timebuilder_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,

    loc_txt = {
        name = "Timebuilder's Deck",
        text = {
            "{C:red}-1{} hand",
            "Start with a {C:spectral}Cryptid{} card",
            "{C:attention}5{} cards in deck have a",
            "{C:starlight,T:starlight_seal}Starlight Seal{}",
            "Defeating a {C:attention}Boss Blind{}",
            "adds {C:attention}2{} more Seals",
        },
    },

    locked_loc_vars = function()
        return { key = "ag_unlock_discover_cloudcradle", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == "discover_amount" and is_cloud_cradle_discovered()
    end,

    config = {
        hands = -1,
    },

    apply = function(self)
        G.GAME.ag_timebuilder_deck_active = true
        G.GAME.ag_timebuilder_cryptid_added = false
        G.GAME.ag_timebuilder_starting_seals_added = false

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            func = function()
                if not G.playing_cards or not G.consumeables then
                    return false
                end

                if not G.GAME.ag_timebuilder_cryptid_added then
                    G.GAME.ag_timebuilder_cryptid_added = add_starting_cryptid()
                end

                if not G.GAME.ag_timebuilder_starting_seals_added then
                    G.GAME.ag_timebuilder_starting_seals_added = add_starlight_seals(5, nil)
                end

                return G.GAME.ag_timebuilder_cryptid_added and G.GAME.ag_timebuilder_starting_seals_added
            end,
        }))
    end,
})

if Blind and Blind.defeat and not AG_TIMEBUILDER_DECK.hook_installed then
    AG_TIMEBUILDER_DECK.hook_installed = true

    local ag_timebuilder_blind_defeat_ref = Blind.defeat

    function Blind:defeat(...)
        local should_add_seals = AG_TIMEBUILDER_DECK.is_active()
            and self
            and self.get_type
            and self:get_type() == "Boss"

        local results = { ag_timebuilder_blind_defeat_ref(self, ...) }

        if should_add_seals and G and G.E_MANAGER then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0,
                func = function()
                    add_starlight_seals(2, "Sealed!")
                    return true
                end,
            }))
        end

        return unpack(results)
    end
end
