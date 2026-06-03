Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.timebuilder_deck = Aspirant.timebuilder_deck or {}
Aspirant.joker_utils = Aspirant.joker_utils or {}

local AG_TIMEBUILDER_DECK = Aspirant.timebuilder_deck
local AG_UTIL = Aspirant.joker_utils

local TIMEBUILDER_DECK_KEYS = {
    "timebuilder_deck",
    "b_timebuilder_deck",
}

local function is_starlight_obelisk_discovered()
    local discovered = AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered("Joker", "starlightobelisk")
        or false

    if Aspirant.debug_log then
        Aspirant.debug_log("Timebuilder prerequisite: helper="
            .. tostring(AG_UTIL.is_center_discovered ~= nil)
            .. " starlightobelisk_discovered="
            .. tostring(discovered))
    end

    return discovered
end

local function center_matches_key(center, key)
    return center
        and (
            center.original_key == key
            or center.key == key
            or (type(center.key) == "string" and center.key:match(key .. "$") ~= nil)
        )
end

local function find_timebuilder_deck_center()
    for _, center in pairs((G and G.P_CENTERS) or {}) do
        if center and center.set == "Back" then
            for _, key in ipairs(TIMEBUILDER_DECK_KEYS) do
                if center_matches_key(center, key) then
                    return center
                end
            end
        end
    end

    return nil
end

local function unlock_timebuilder_deck_center(center)
    if not center then
        if Aspirant.debug_log then
            Aspirant.debug_log("Timebuilder unlock attempt: no Back center found")
        end
        return false
    end

    if Aspirant.debug_log then
        Aspirant.debug_log("Timebuilder unlock attempt: key="
            .. tostring(center.key)
            .. " original_key="
            .. tostring(center.original_key)
            .. " unlocked_before="
            .. tostring(center.unlocked)
            .. " discovered_before="
            .. tostring(center.discovered)
            .. " unlock_card="
            .. tostring(type(unlock_card) == "function"))
    end

    if unlock_card and G and G.GAME then
        unlock_card(center)
    else
        if G and G.save_notify then
            G:save_notify(center)
        end

        center.unlocked = true
        if discover_card and G and G.GAME then
            discover_card(center)
        else
            center.discovered = true
        end
        center.alerted = true

        for i = #((G and G.P_LOCKED) or {}), 1, -1 do
            local locked_center = G.P_LOCKED[i]
            if locked_center == center or locked_center.key == center.key then
                table.remove(G.P_LOCKED, i)
            end
        end

        if G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Back then
            table.sort(G.P_CENTER_POOLS.Back, function(a, b)
                return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0))
            end)
        end

        if G and G.save_progress then
            G:save_progress()
        end
        if G and G.FILE_HANDLER then
            G.FILE_HANDLER.force = true
        end
    end

    if Aspirant.debug_log then
        local pool_index = nil
        for i, back in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Back) or {}) do
            if back == center or back.key == center.key then
                pool_index = i
                break
            end
        end

        Aspirant.debug_log("Timebuilder unlock result: key="
            .. tostring(center.key)
            .. " unlocked_after="
            .. tostring(center.unlocked)
            .. " discovered_after="
            .. tostring(center.discovered)
            .. " save_notify="
            .. tostring(G and G.save_notify ~= nil)
            .. " back_pool_index="
            .. tostring(pool_index))
    end

    return center.unlocked == true
end

function AG_TIMEBUILDER_DECK.sync_unlock_state()
    local center = find_timebuilder_deck_center()
    local can_unlock_now = not (G and G.GAME)
        or (Aspirant.is_main_menu and Aspirant.is_main_menu())
    local should_unlock = center and not center.unlocked and can_unlock_now and is_starlight_obelisk_discovered()

    if Aspirant.debug_log then
        Aspirant.debug_log("Timebuilder sync: center="
            .. tostring(center and center.key)
            .. " center_unlocked="
            .. tostring(center and center.unlocked)
            .. " can_unlock_now="
            .. tostring(can_unlock_now)
            .. " should_unlock="
            .. tostring(should_unlock))
    end

    if should_unlock then
        return unlock_timebuilder_deck_center(center)
    end

    return should_unlock
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
        unlock = {
            "Unlock by discovering",
            "{C:attention}Starlight Obelisk{}",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        local prerequisite_met = args and args.type == "discover_amount" and is_starlight_obelisk_discovered()
        local on_main_menu = Aspirant.is_main_menu and Aspirant.is_main_menu() or false
        local result = prerequisite_met and on_main_menu

        if Aspirant.debug_log then
            Aspirant.debug_log("Timebuilder check_for_unlock: args_type="
                .. tostring(args and args.type)
                .. " amount="
                .. tostring(args and args.amount)
                .. " self_key="
                .. tostring(self and self.key)
                .. " prerequisite_met="
                .. tostring(prerequisite_met)
                .. " on_main_menu="
                .. tostring(on_main_menu)
                .. " result="
                .. tostring(result))
        end

        return result
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
