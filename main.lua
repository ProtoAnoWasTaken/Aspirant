-- =========================================
-- COLORS
-- =========================================

G.C.ASPIRANT = HEX("B1AB70")
G.C.TOOL     = HEX("C19E5B")
G.C.POTION   = HEX("7AF2B5")
G.C.STARLIGHT = HEX("01F9CF")

if type(loc_colour) == "function" then
    local ag_loc_colour_ref = loc_colour

    function loc_colour(_c, _default)
        if _c == "starlight" then
            return G.C.STARLIGHT or _default
        end

        return ag_loc_colour_ref(_c, _default)
    end
end

-- =========================================
-- MOD FEATURES / CONFIG
-- =========================================

SMODS.current_mod.optional_features = {
    object_weights = true,
    retrigger_joker = true,
    post_trigger = true,
    quantum_enhancements = true,
}

local AG_CONFIG_ROOT = SMODS.current_mod.config or {}
local AG_CONFIG = AG_CONFIG_ROOT["Aspirant"] or AG_CONFIG_ROOT
local AG_TEST_DECK_ENABLED = AG_CONFIG.enable_test_deck == true

if AG_CONFIG.enable_test_deck == nil then
    AG_CONFIG.enable_test_deck = false
end

if AG_CONFIG.vinyl_music == nil then
    AG_CONFIG.vinyl_music = true
end

Aspirant = rawget(_G, "Aspirant") or {}

local AG = Aspirant

AG.test_deck = AG.test_deck or {}
AG.config = AG_CONFIG
AG.item_sort_info_cache = AG.item_sort_info_cache or {}

function AG.is_main_menu()
    return G
        and G.STAGES
        and G.STATES
        and G.STAGE == G.STAGES.MAIN_MENU
        and G.STATE == G.STATES.MENU
end

SMODS.current_mod.config_tab = function()
    local nodes = {
        {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.02 },
            nodes = {
                create_toggle({
                    label = "Enable Joker music replacement",
                    ref_table = AG_CONFIG,
                    ref_value = "vinyl_music",
                }),
            }
        },
        {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.02 },
            nodes = {
                create_toggle({
                    label = "Vile, vile, vile! (requires restart)",
                    ref_table = AG_CONFIG,
                    ref_value = "enable_test_deck",
                }),
            }
        },
        {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.12 },
            nodes = {}
        },
    }

    return {
        n = G.UIT.ROOT,
        config = { align = "cm", padding = 0.05, colour = G.C.CLEAR },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cm", padding = 0.1 },
                nodes = nodes
            }
        }
    }
end

-- =========================================
-- TEST DECK SUPPORT
-- =========================================

local function ag_is_test_deck_center(center)
    if not center then
        return false
    end

    return center.original_key == "test_deck"
        or center.key == "test_deck"
        or center.key == "b_test_deck"
        or (type(center.key) == "string" and center.key:match("test_deck$") ~= nil)
        or center.name == "Cheater's Deck"
end

local function ag_get_test_deck_center()
    if not G or not G.P_CENTERS then
        return nil
    end

    for _, center in pairs(G.P_CENTERS) do
        if ag_is_test_deck_center(center) then
            return center
        end
    end

    return nil
end

local function ag_get_back_pool()
    return G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Back or nil
end

local function ag_find_back_pool_index(center)
    local pool = ag_get_back_pool()
    if not pool or not center then
        return nil
    end

    for i, back in ipairs(pool) do
        if back == center or back.key == center.key then
            return i
        end
    end
end

local function ag_sort_back_pool()
    local pool = ag_get_back_pool()
    if not pool then
        return
    end

    table.sort(pool, function(a, b)
        return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0))
    end)
end

local function ag_default_back_center()
    return G and G.P_CENTERS and G.P_CENTERS.b_red or nil
end

local function ag_center_key_matches(center_key, suffix)
    return type(center_key) == "string" and center_key:match(suffix .. "$") ~= nil
end

function AG.test_deck.is_enabled()
    return AG_TEST_DECK_ENABLED
end

function AG.test_deck.sync_unlock_state(center)
    local back_center = center
    if not ag_is_test_deck_center(back_center) then
        back_center = ag_get_test_deck_center()
    end
    if ag_is_test_deck_center(back_center) then
        back_center.unlocked = AG.test_deck.is_enabled()
    end
    return back_center
end

function AG.test_deck.sync_pool_state()
    local back_center = AG.test_deck.sync_unlock_state()
    local pool = ag_get_back_pool()

    if not ag_is_test_deck_center(back_center) or not pool then
        return back_center
    end

    local index = ag_find_back_pool_index(back_center)

    if AG.test_deck.is_enabled() then
        if not index then
            table.insert(pool, back_center)
            ag_sort_back_pool()
        end
    elseif index then
        table.remove(pool, index)
    end

    return back_center
end

function AG.test_deck.sync_memory_deck()
    if not G or not G.PROFILES or not G.SETTINGS or not G.SETTINGS.profile then
        return
    end

    local profile = G.PROFILES[G.SETTINGS.profile]
    local memory = profile and profile.MEMORY
    local back_center = ag_get_test_deck_center()
    local fallback = ag_default_back_center()

    if not memory or not back_center or not fallback then
        return
    end

    if not AG.test_deck.is_enabled() and memory.deck == back_center.name then
        memory.deck = fallback.name
    end
end

function AG.test_deck.sync_availability()
    AG.test_deck.sync_pool_state()
    AG.test_deck.sync_memory_deck()
end

function AG.test_deck.is_active()
    if G and G.GAME and G.GAME.ag_test_deck_active then
        return true
    end

    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center
    return center and ag_center_key_matches(center.key, "test_deck") or false
end

local function ag_default_front()
    local _, fallback = next(G.P_CARDS)
    return G.P_CARDS.S_A or G.P_CARDS.H_A or G.P_CARDS.D_A or G.P_CARDS.C_A or fallback
end

local function ag_next_playing_card_id()
    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
    return G.playing_card
end

local function ag_make_base_playing_card(source_card)
    local card = Card(
        G.deck.T.x,
        G.deck.T.y,
        G.CARD_W,
        G.CARD_H,
        ag_default_front(),
        G.P_CENTERS.c_base,
        { playing_card = ag_next_playing_card_id(), bypass_back = G.GAME.selected_back.pos }
    )

    if source_card and source_card.edition then
        card:set_edition(source_card.edition, true, true)
    end
    if source_card and source_card.seal then
        card:set_seal(source_card.seal, true, true)
    end

    return card
end

local function ag_spawn_playing_card(source_card)
    if source_card.config and source_card.config.center and source_card.config.center.set == "Edition" then
        local card = ag_make_base_playing_card(source_card)
        card:add_to_deck()
        card:start_materialize()
        G.deck:emplace(card)
        table.insert(G.playing_cards, card)
        playing_card_joker_effects({ card })
        return true
    else
        local params = {
            set = source_card.ability and source_card.ability.set == "Enhanced" and "Enhanced" or "Base",
            area = G.deck,
            no_edition = true,
            bypass_discovery_center = true,
            allow_duplicates = true,
        }

        if source_card.config and source_card.config.card and source_card.config.card.key and source_card.config.card ~= G.P_CARDS.empty then
            params.front = source_card.config.card.key
        end
        if source_card.config and source_card.config.center and source_card.config.center.set == "Enhanced" then
            params.enhancement = source_card.config.center.key
        end
        if source_card.edition then
            params.edition = source_card.edition
        end
        if source_card.seal then
            params.seal = source_card.seal
        end

        local card = SMODS.add_card(params)
        playing_card_joker_effects({ card })
        return true
    end
end

local function ag_spawn_consumable(source_card)
    if not G.consumeables then
        return false
    end

    SMODS.add_card({
        key = source_card.config.center.key,
        area = G.consumeables,
        no_edition = not source_card.edition,
        edition = source_card.edition,
        bypass_discovery_center = true,
        allow_duplicates = true,
    })
    return true
end

local function ag_spawn_joker(source_card)
    if not G.jokers then
        return false
    end

    local card = SMODS.add_card({
        key = source_card.config.center.key,
        area = G.jokers,
        no_edition = not source_card.edition,
        edition = source_card.edition,
        stickers = source_card.sticker and { source_card.sticker } or nil,
        bypass_discovery_center = true,
        allow_duplicates = true,
    })

    if #G.jokers.cards >= G.jokers.config.card_limit and not (card.edition and card.edition.negative) then
        card:set_edition({ negative = true }, true, true)
    end
    return true
end

local function ag_redeem_voucher(source_card)
    if not G.vouchers then
        return false
    end

    local center = source_card.config and source_card.config.center
    if not center or center.set ~= "Voucher" then
        return false
    end

    if not center.discovered then
        discover_card(center)
    end

    G.GAME.used_vouchers[center.key] = true
    Card.apply_to_run(nil, center)
    return true
end

local function ag_blind_pools()
    return {
        (G and G.P_BLINDS) or nil,
        (G and G.P_CENTERS) or nil,
    }
end

local function ag_tag_pools()
    return {
        (G and G.P_TAGS) or nil,
        (G and G.P_CENTERS) or nil,
    }
end

local function ag_is_known_tag_center(center)
    if not center or not G or not G.P_TAGS then
        return false
    end

    for _, tag_center in pairs(G.P_TAGS) do
        if tag_center == center
            or (tag_center and center.key and tag_center.key == center.key)
            or (tag_center and center.original_key and tag_center.key == center.original_key)
        then
            return true
        end
    end

    return false
end

local function ag_center_looks_like_tag(center)
    return center
        and (
            ag_is_known_tag_center(center)
            or center.set == "Tag"
        )
end

local function ag_collect_lookup_values(source_card)
    local direct_center = source_card and source_card.config and source_card.config.center
    local lookup_values = {}

    local function add_value(value)
        if type(value) == "string" and value ~= "" then
            lookup_values[value] = true
            lookup_values[value:lower()] = true
        end
    end

    local function add_named_fields(subject, depth, seen)
        if type(subject) ~= "table" or depth <= 0 or seen[subject] then
            return
        end
        seen[subject] = true

        add_value(subject.key)
        add_value(subject.original_key)
        add_value(subject.name)
        add_value(subject.label)
        add_value(subject.set)
        add_value(subject.text)
        add_value(subject.desc)
        add_value(subject.tooltip)
        add_value(subject.loc_txt and subject.loc_txt.name)

        for key, value in pairs(subject) do
            if type(key) == "string" then
                add_value(key)
            end

            if type(value) == "string" then
                add_value(value)
            elseif type(value) == "table" then
                add_named_fields(value, depth - 1, seen)
            end
        end
    end

    add_named_fields(direct_center, 3, {})
    add_named_fields(source_card and source_card.ability, 3, {})
    add_named_fields(source_card and source_card.base, 3, {})
    add_named_fields(source_card and source_card.ability_UIBox_table, 3, {})
    add_named_fields(source_card and source_card.config, 3, {})
    add_named_fields(source_card, 2, {})

    return direct_center, lookup_values
end

local function ag_center_looks_like_blind(center)
    return center
        and (
            center.set == "Blind"
            or center.boss ~= nil
            or center.boss_colour ~= nil
        )
end

local function ag_find_boss_blind_center(source_card)
    local direct_center, lookup_values = ag_collect_lookup_values(source_card)
    if ag_center_looks_like_blind(direct_center) and direct_center.boss then
        return direct_center
    end

    for _, pool in ipairs(ag_blind_pools()) do
        for _, center in pairs(pool or {}) do
            if ag_center_looks_like_blind(center) and center.boss then
                if lookup_values[center.key]
                    or lookup_values[string.lower(center.key or "")]
                    or lookup_values[center.original_key]
                    or lookup_values[string.lower(center.original_key or "")]
                    or lookup_values[center.name]
                    or lookup_values[string.lower(center.name or "")]
                    or lookup_values[center.loc_txt and center.loc_txt.name]
                    or lookup_values[string.lower(center.loc_txt and center.loc_txt.name or "")]
                then
                    return center
                end
            end
        end
    end

    return nil
end

local function ag_find_tag_center(source_card)
    local direct_center, lookup_values = ag_collect_lookup_values(source_card)
    if ag_center_looks_like_tag(direct_center) then
        return direct_center
    end

    for _, pool in ipairs(ag_tag_pools()) do
        for _, center in pairs(pool or {}) do
            if ag_center_looks_like_tag(center) then
                if lookup_values[center.key]
                    or lookup_values[string.lower(center.key or "")]
                    or lookup_values[center.original_key]
                    or lookup_values[string.lower(center.original_key or "")]
                    or lookup_values[center.name]
                    or lookup_values[string.lower(center.name or "")]
                    or lookup_values[center.loc_txt and center.loc_txt.name]
                    or lookup_values[string.lower(center.loc_txt and center.loc_txt.name or "")]
                then
                    return center
                end
            end
        end
    end

    return nil
end

local function ag_get_tag_spawn_key(center)
    if not center then
        return nil
    end

    for pool_key, tag_center in pairs((G and G.P_TAGS) or {}) do
        if tag_center == center
            or (tag_center and center.key and tag_center.key == center.key)
            or (tag_center and center.original_key and tag_center.key == center.original_key)
            or (tag_center and center.original_key and tag_center.original_key == center.original_key)
        then
            return pool_key
        end
    end

    return center.original_key or center.key
end

local function ag_spawn_tag(source_card)
    local center = ag_find_tag_center(source_card)
    if not center then
        return false
    end

    local spawn_key = ag_get_tag_spawn_key(center)
    if not spawn_key then
        return false
    end

    if not center.discovered then
        discover_card(center)
    end

    add_tag(Tag(spawn_key))
    return true
end

local function ag_get_hovered_tag_source()
    local controller = G and G.CONTROLLER or nil
    local candidates = {
        controller and controller.hovering,
        controller and controller.hovering and controller.hovering.target,
        controller and controller.focused,
        controller and controller.focused and controller.focused.target,
    }
    local seen = {}

    for _, candidate in ipairs(candidates) do
        if type(candidate) == "table" and not seen[candidate] then
            seen[candidate] = true
            if ag_find_tag_center(candidate) then
                return candidate
            end
        end
    end

    return nil
end

local function ag_try_clone_hovered_tag()
    if not AG.test_deck.is_active() or G.STATE == G.STATES.GAME_OVER then
        return false
    end

    local hovered_source = ag_get_hovered_tag_source()
    if not hovered_source then
        return false
    end

    if not ag_spawn_tag(hovered_source) then
        return false
    end

    play_sound("card1", 0.9, 0.6)
    play_sound("generic1")
    return true
end

local function ag_set_boss_blind(source_card)
    local center = ag_find_boss_blind_center(source_card)
    if not center then
        return false
    end

    if G.GAME and G.GAME.blind and G.GAME.blind.in_blind then
        return false
    end

    if not center.discovered then
        discover_card(center)
    end

    if not G or not G.GAME or not G.GAME.round_resets then
        return false
    end

    G.GAME.round_resets.blind_choices = G.GAME.round_resets.blind_choices or {}
    G.GAME.round_resets.blind_choices.Boss = center.key
    return true
end

local function ag_looks_like_playing_card(source_card)
    if not source_card then
        return false
    end

    if source_card.base and (source_card.base.suit or source_card.base.value or source_card.base.id) then
        return true
    end

    local center = source_card.config and source_card.config.center
    if center == G.P_CENTERS.c_base then
        return true
    end

    return source_card.config
        and source_card.config.card
        and source_card.config.card ~= G.P_CARDS.empty
        and source_card.config.card.key ~= nil
end

function AG.test_deck.try_summon(source_card)
    if not AG.test_deck.is_active() or not source_card then
        return false
    end

    if G.STATE == G.STATES.GAME_OVER then
        return false
    end

    local center = source_card.config and source_card.config.center or nil

    if center and (center == G.j_locked or center == G.v_locked or center.key == "j_locked" or center.key == "v_locked") then
        return false
    end

    if center and (center.set == "Back" or center.set == "Booster") then
        return false
    end

    if (center and center.set == "Tag") or ag_find_tag_center(source_card) then
        return ag_spawn_tag(source_card)
    end

    if (center and center.set == "Blind") or ag_find_boss_blind_center(source_card) then
        return ag_set_boss_blind(source_card)
    end

    if source_card.ability and source_card.ability.set == "Voucher" then
        return ag_redeem_voucher(source_card)
    end

    if source_card.ability and source_card.ability.set == "Joker" then
        return ag_spawn_joker(source_card)
    end

    if source_card.ability and source_card.ability.consumeable then
        return ag_spawn_consumable(source_card)
    end

    if center and center.set == "Edition" then
        return false
    end

    if source_card.ability and source_card.ability.set == "Enhanced" then
        return false
    end

    if source_card.ability and source_card.ability.set == "Default" then
        return ag_looks_like_playing_card(source_card) and ag_spawn_playing_card(source_card) or false
    end

    if source_card.seal and source_card.config.center == G.P_CENTERS.c_base then
        return ag_spawn_playing_card(source_card)
    end

    return false
end

local function ag_is_collection_card(card)
    return card
        and card.area
        and card.area.config
        and card.area.config.collection
end

-- =========================================
-- LOADER
-- =========================================

local MOD_ID    = "Aspirant"
local FS_PREFIX = "Mods/" .. MOD_ID .. "/"

local function ag_parse_named_sort_infos(rel_path, fs_item_path)
    local contents = love.filesystem.read(fs_item_path)
    if not contents then
        return {}
    end

    local sort_infos = {}
    local source_index = 0

    for _, object_type in ipairs({
        "Joker",
        "Back",
        "Blind",
        "Seal",
        "Voucher",
        "Tarot",
        "Spectral",
        "Booster",
        "Tag",
        "Achievement",
        "Challenge",
        "Consumable",
        "Edition",
        "Enhancement",
        "ObjectType",
    }) do
        for block in contents:gmatch("SMODS%." .. object_type .. "%s*%(%s*(%b{})") do
            source_index = source_index + 1
            local rarity = tonumber(block:match("rarity%s*=%s*(%d+)")) or 999
            local order = tonumber(block:match("order%s*=%s*(%-?%d+%.?%d*)"))
            local name = block:match("name%s*=%s*'([^']+)'")
                or block:match('name%s*=%s*"([^"]+)"')
                or block:match("loc_txt%s*=%s*%b{}.-name%s*=%s*'([^']+)'")
                or block:match('loc_txt%s*=%s*%b{}.-name%s*=%s*"([^"]+)"')
                or rel_path
            local key = block:match("key%s*=%s*'([^']+)'") or block:match('key%s*=%s*"([^"]+)"')

            if key then
                sort_infos[#sort_infos + 1] = {
                    rel_path = rel_path,
                    source_index = source_index,
                    key = key,
                    object_type = object_type,
                    order = order,
                    rarity = rarity,
                    name = name:lower(),
                }
            end
        end
    end

    return sort_infos
end

local function ag_get_item_sort_infos(rel_path, fs_item_path)
    local cache_key = rel_path:lower()
    if AG.item_sort_info_cache[cache_key] ~= nil then
        return AG.item_sort_info_cache[cache_key] or {}
    end

    local sort_infos = ag_parse_named_sort_infos(rel_path, fs_item_path)
    AG.item_sort_info_cache[cache_key] = sort_infos
    return sort_infos
end

local function ag_get_item_sort_info(rel_path, fs_item_path)
    local sort_infos = ag_get_item_sort_infos(rel_path, fs_item_path)
    return sort_infos[1]
end

local function ag_compare_item_sort_info(a, b)
    if a.object_type ~= b.object_type then
        return tostring(a.object_type) < tostring(b.object_type)
    end

    if a.order or b.order then
        local order_a = a.order or 999999
        local order_b = b.order or 999999
        if order_a ~= order_b then
            return order_a < order_b
        end
    end

    if a.rarity ~= b.rarity then
        return a.rarity < b.rarity
    end

    if a.rel_path == b.rel_path and a.source_index ~= b.source_index then
        return a.source_index < b.source_index
    end

    if a.name ~= b.name then
        return a.name < b.name
    end

    return a.rel_path:lower() < b.rel_path:lower()
end

local function ag_get_collection_mod(center)
    local mod = center and (center.mod or center.original_mod)
    if not mod or mod.id == "Balatro" or mod.id == "Steamodded" then
        return nil
    end
    return mod
end

local function ag_get_collection_mod_priority(mod)
    return tonumber(mod and mod.priority)
        or tonumber(mod and mod.manifest and mod.manifest.priority)
        or 0
end

local function ag_get_collection_sort_rarity(center)
    return tonumber(center and center.rarity) or 999
end

local function ag_get_collection_sort_name(center)
    return tostring((center and (center.name or center.original_key or center.key)) or ""):lower()
end

local function ag_compare_collection_entries(a, b)
    if a.mod ~= b.mod then
        if not a.mod then
            return true
        end
        if not b.mod then
            return false
        end

        local priority_a = ag_get_collection_mod_priority(a.mod)
        local priority_b = ag_get_collection_mod_priority(b.mod)
        if priority_a ~= priority_b then
            return priority_a < priority_b
        end

        local id_a = tostring(a.mod.id or "")
        local id_b = tostring(b.mod.id or "")
        if id_a ~= id_b then
            return id_a < id_b
        end
    end

    if a.mod and b.mod then
        local rarity_a = ag_get_collection_sort_rarity(a.center)
        local rarity_b = ag_get_collection_sort_rarity(b.center)
        if rarity_a ~= rarity_b then
            return rarity_a < rarity_b
        end

        local name_a = ag_get_collection_sort_name(a.center)
        local name_b = ag_get_collection_sort_name(b.center)
        if name_a ~= name_b then
            return name_a < name_b
        end
    end

    return a.index < b.index
end

local function ag_reorder_center_pool(pool)
    if type(pool) ~= "table" or not pool[1] then
        return
    end

    if pool[1].set == "Voucher" then
        return
    end

    local entries = {}
    for index, center in ipairs(pool) do
        entries[index] = {
            center = center,
            mod = ag_get_collection_mod(center),
            index = index,
        }
    end

    table.sort(entries, ag_compare_collection_entries)

    local mod_counts = {}
    for index, entry in ipairs(entries) do
        if entry.mod then
            local mod_key = tostring(entry.mod.id or entry.mod)
            mod_counts[mod_key] = (mod_counts[mod_key] or 0) + 1
            entry.center.order = 1000000000 + ag_get_collection_mod_priority(entry.mod) + (mod_counts[mod_key] / 10000)
        end
        pool[index] = entry.center
    end
end

local function ag_reorder_keyed_collection(collection)
    if type(collection) ~= "table" then
        return
    end

    local entries = {}
    for key, center in pairs(collection) do
        local mod = ag_get_collection_mod(center)
        if mod then
            entries[#entries + 1] = {
                center = center,
                mod = mod,
                index = tonumber(center.order) or #entries + 1,
                key = tostring(key),
            }
        end
    end

    table.sort(entries, function(a, b)
        if ag_compare_collection_entries(a, b) then
            return true
        end
        if ag_compare_collection_entries(b, a) then
            return false
        end
        return a.key < b.key
    end)

    for index, entry in ipairs(entries) do
        entry.center.order = 1000000000 + ag_get_collection_mod_priority(entry.mod) + (index / 10000)
    end
end

local function ag_normalize_collection_order()
    if G and G.P_CENTER_POOLS then
        for _, pool in pairs(G.P_CENTER_POOLS) do
            ag_reorder_center_pool(pool)
        end
    end

    ag_reorder_keyed_collection(G and G.P_TAGS)
    ag_reorder_keyed_collection(G and G.P_BLINDS)
end

local function ag_recheck_unlocks()
    if type(check_for_unlock) ~= "function" then
        return
    end

    local fired = {}

    local function fire_unlock(args)
        if not (G and G.GAME) then
            return
        end

        local unlock_type = args and args.type
        if not unlock_type or fired[unlock_type] then
            return
        end

        fired[unlock_type] = true

        pcall(check_for_unlock, args)
    end

    -- Re-run discovery-gated unlocks only after discovery tallies exist.
    if G and G.DISCOVER_TALLIES and G.DISCOVER_TALLIES.total then
        fire_unlock({ type = "discover_amount", amount = G.DISCOVER_TALLIES.total.tally or 0 })
    end

    -- Re-run achievement-gated unlocks for achievements already earned.
    local earned = {}

    if G and G.ACHIEVEMENTS then
        for achievement_key, achievement in pairs(G.ACHIEVEMENTS) do
            if achievement and achievement.mod and achievement.earned then
                earned[achievement_key] = true
            end
        end
    end

    if G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED then
        for achievement_key, is_earned in pairs(G.SETTINGS.ACHIEVEMENTS_EARNED) do
            if is_earned
                and G
                and G.ACHIEVEMENTS
                and G.ACHIEVEMENTS[achievement_key]
                and G.ACHIEVEMENTS[achievement_key].mod
            then
                earned[achievement_key] = true
            end
        end
    end

    for achievement_key in pairs(earned) do
        fire_unlock({ type = achievement_key })
    end

    if AG.lemurian_deck and AG.lemurian_deck.sync_unlock_state then
        AG.lemurian_deck.sync_unlock_state()
    end

    if AG.timebuilder_deck and AG.timebuilder_deck.sync_unlock_state then
        AG.timebuilder_deck.sync_unlock_state()
    end

    ag_normalize_collection_order()
end

local function ag_install_unlock_recheck_hook()
    if not SMODS or type(SMODS.SAVE_UNLOCKS) ~= "function" or AG.unlock_recheck_hook_installed then
        return
    end

    AG.unlock_recheck_hook_installed = true
    local ag_save_unlocks_ref = SMODS.SAVE_UNLOCKS

    function SMODS.SAVE_UNLOCKS(...)
        local results = { ag_save_unlocks_ref(...) }
        ag_recheck_unlocks()
        return unpack(results)
    end
end

local function load_folder(rel_folder)
    local fs_path = FS_PREFIX .. rel_folder
    if not love.filesystem.getInfo(fs_path) then return end

    local items = love.filesystem.getDirectoryItems(fs_path)
    table.sort(items, function(a, b)
        local rel_a = rel_folder .. "/" .. a
        local rel_b = rel_folder .. "/" .. b
        local fs_a = FS_PREFIX .. rel_a
        local fs_b = FS_PREFIX .. rel_b
        local info_a = love.filesystem.getInfo(fs_a)
        local info_b = love.filesystem.getInfo(fs_b)

        if info_a and info_b and info_a.type ~= info_b.type then
            return info_a.type == "directory"
        end

        local sort_a = ag_get_item_sort_info(rel_a, fs_a)
        local sort_b = ag_get_item_sort_info(rel_b, fs_b)

        if sort_a and sort_b then
            return ag_compare_item_sort_info(sort_a, sort_b)
        end

        return a:lower() < b:lower()
    end)

    for _, item in ipairs(items) do
        local rel_path     = rel_folder .. "/" .. item
        local fs_item_path = FS_PREFIX .. rel_path
        local info         = love.filesystem.getInfo(fs_item_path)

        if info then
            if info.type == "file" and item:lower():match("%.lua$") then
                local init, err = SMODS.load_file(rel_path)
                if init then
                    local ok, result = pcall(init)
                    if not ok then
                        sendErrorMessage("[Aspirant] Error in " .. rel_path .. ": " .. tostring(result))
                    end
                else
                    sendErrorMessage("[Aspirant] Failed to load " .. rel_path .. ": " .. tostring(err))
                end
            elseif info.type == "directory" then
                load_folder(rel_path)
            end
        end
    end
end

-- =========================================
-- LOAD ALL
-- =========================================

load_folder("localization")
load_folder("items")
ag_normalize_collection_order()
ag_install_unlock_recheck_hook()

AG.test_deck.sync_availability()

if Back then
    local ag_back_init_ref = Back.init
    function Back:init(selected_back)
        if ag_is_test_deck_center(selected_back) then
            AG.test_deck.sync_availability()
            AG.test_deck.sync_unlock_state(selected_back)
        end
        return ag_back_init_ref(self, selected_back)
    end

    local ag_back_change_to_ref = Back.change_to
    function Back:change_to(new_back)
        if ag_is_test_deck_center(new_back) then
            AG.test_deck.sync_availability()
            AG.test_deck.sync_unlock_state(new_back)
        end
        return ag_back_change_to_ref(self, new_back)
    end

    local ag_back_generate_ui_ref = Back.generate_UI
    function Back:generate_UI(other, ui_scale, min_dims, challenge)
        local back_center = other or (self and self.effect and self.effect.center)
        if ag_is_test_deck_center(back_center) then
            AG.test_deck.sync_unlock_state(back_center)
        end
        return ag_back_generate_ui_ref(self, other, ui_scale, min_dims, challenge)
    end
end

if type(set_main_menu_UI) == "function" and not AG.main_menu_unlock_recheck_hook_installed then
    AG.main_menu_unlock_recheck_hook_installed = true
    local ag_set_main_menu_ui_ref = set_main_menu_UI

    function set_main_menu_UI(...)
        local results = { ag_set_main_menu_ui_ref(...) }

        ag_recheck_unlocks()
        return unpack(results)
    end
end

if G and G.UIDEF and G.UIDEF.run_setup_option then
    local ag_run_setup_option_ref = G.UIDEF.run_setup_option
    function G.UIDEF.run_setup_option(type)
        AG.test_deck.sync_availability()
        ag_normalize_collection_order()
        return ag_run_setup_option_ref(type)
    end
end

if Galdur and Galdur.prepare_run_setup then
    local ag_galdur_prepare_run_setup_ref = Galdur.prepare_run_setup
    function Galdur.prepare_run_setup(...)
        AG.test_deck.sync_availability()
        return ag_galdur_prepare_run_setup_ref(...)
    end
end

local ag_card_click_ref = Card.click

function Card:click(...)
    if ag_is_collection_card(self) then
        ag_normalize_collection_order()
    end

    if ag_is_collection_card(self) and AG.test_deck.try_summon(self) then
        play_sound("card1", 0.9, 0.6)
        play_sound("generic1")
        return
    end

    return ag_card_click_ref(self, ...)
end

if love then
    local ag_mousepressed_ref = love.mousepressed

    function love.mousepressed(x, y, button, istouch, presses)
        if button == 1 and ag_try_clone_hovered_tag() then
            return
        end

        if ag_mousepressed_ref then
            return ag_mousepressed_ref(x, y, button, istouch, presses)
        end
    end
end
