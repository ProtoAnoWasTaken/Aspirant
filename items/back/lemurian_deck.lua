Aspirant = rawget(_G, "Aspirant") or {}
Aspirant.lemurian_deck = Aspirant.lemurian_deck or {}
Aspirant.joker_utils = Aspirant.joker_utils or {}

local AG_LEMURIAN_DECK = Aspirant.lemurian_deck
local AG_UTIL = Aspirant.joker_utils

local LEMURIAN_DECK_KEYS = {
    "lemurian_deck",
    "b_lemurian_deck",
}

local function is_weithiwr_discovered()
    local discovered = AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered("Joker", "weithiwrhaearn")
        or false

    if Aspirant.debug_log then
        Aspirant.debug_log("Lemurian prerequisite: helper="
            .. tostring(AG_UTIL.is_center_discovered ~= nil)
            .. " weithiwrhaearn_discovered="
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

local function find_lemurian_deck_center()
    for _, center in pairs((G and G.P_CENTERS) or {}) do
        if center and center.set == "Back" then
            for _, key in ipairs(LEMURIAN_DECK_KEYS) do
                if center_matches_key(center, key) then
                    return center
                end
            end
        end
    end

    return nil
end

local function unlock_lemurian_deck_center(center)
    if not center then
        if Aspirant.debug_log then
            Aspirant.debug_log("Lemurian unlock attempt: no Back center found")
        end
        return false
    end

    if Aspirant.debug_log then
        Aspirant.debug_log("Lemurian unlock attempt: key="
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

        Aspirant.debug_log("Lemurian unlock result: key="
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

function AG_LEMURIAN_DECK.sync_unlock_state()
    local center = find_lemurian_deck_center()
    local can_unlock_now = not (G and G.GAME)
        or (Aspirant.is_main_menu and Aspirant.is_main_menu())
    local should_unlock = center and not center.unlocked and can_unlock_now and is_weithiwr_discovered()

    if Aspirant.debug_log then
        Aspirant.debug_log("Lemurian sync: center="
            .. tostring(center and center.key)
            .. " center_unlocked="
            .. tostring(center and center.unlocked)
            .. " can_unlock_now="
            .. tostring(can_unlock_now)
            .. " should_unlock="
            .. tostring(should_unlock))
    end

    if should_unlock then
        return unlock_lemurian_deck_center(center)
    end

    return should_unlock
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
        unlock = {
            "Unlock by discovering",
            "{C:attention}Weithiwr Haearn{}",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        local prerequisite_met = args and args.type == "discover_amount" and is_weithiwr_discovered()
        local on_main_menu = Aspirant.is_main_menu and Aspirant.is_main_menu() or false
        local result = prerequisite_met and on_main_menu

        if Aspirant.debug_log then
            Aspirant.debug_log("Lemurian check_for_unlock: args_type="
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
