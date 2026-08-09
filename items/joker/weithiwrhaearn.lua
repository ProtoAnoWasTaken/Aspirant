SMODS.Atlas({
    key = 'weithiwrhaearn',
    path = 'weithiwirhaearn.png',
    px = 69,
    py = 93,
})

SMODS.Sound({
    key = 'forge',
    path = 'forge.ogg',
    prefix_config = { key = false },
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}
local AG_LEMURIAN_DECK = (rawget(_G, 'Aspirant') or {}).lemurian_deck or {}
local FORGE_STEP_DELAY = 0.75

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function center_matches(center, suffix)
    return AG_UTIL.center_matches and AG_UTIL.center_matches(center, suffix) or false
end

local function is_arm_center(center)
    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        if center_matches(center, suffix) then
            return true
        end
    end

    return false
end

local function is_drommo_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'drommo')
        or false
end

local function normalize_rarity(rarity)
    if rarity == 'Common' then
        return 1
    end

    if rarity == 'Uncommon' then
        return 2
    end

    if rarity == 'Rare' then
        return 3
    end

    if rarity == 'Legendary' then
        return 4
    end

    if type(rarity) == 'string' then
        rarity = rarity:lower()
        if rarity == 'common' then return 1 end
        if rarity == 'uncommon' then return 2 end
        if rarity == 'rare' then return 3 end
        if rarity == 'legendary' then return 4 end
    end

    return rarity
end

local function is_common_joker(card, source_card)
    local center = card and card.config and card.config.center
    local rarity = normalize_rarity(center and center.rarity)

    return card
        and card ~= source_card
        and not card.getting_sliced
        and center
        and not is_arm_center(center)
        and rarity == 1
end

local function is_uncommon_joker(card, source_card)
    local center = card and card.config and card.config.center
    local rarity = normalize_rarity(center and center.rarity)

    return card
        and card ~= source_card
        and not card.getting_sliced
        and center
        and not is_arm_center(center)
        and rarity == 2
end

local function get_destroyable_consumables()
    local consumables = {}

    if not G or not G.consumeables or not G.consumeables.cards then
        return consumables
    end

    for _, consumable in ipairs(G.consumeables.cards) do
        if consumable and not consumable.getting_sliced then
            consumables[#consumables + 1] = consumable
        end
    end

    return consumables
end

local function get_destroyable_jokers(source_card, predicate)
    local jokers = {}

    if not G or not G.jokers or not G.jokers.cards then
        return jokers
    end

    for _, joker in ipairs(G.jokers.cards) do
        if predicate(joker, source_card) then
            jokers[#jokers + 1] = joker
        end
    end

    return jokers
end

local function has_forge_materials(card)
    return #get_destroyable_consumables() > 0
        and #get_destroyable_jokers(card, is_common_joker) > 0
        and #get_destroyable_jokers(card, is_uncommon_joker) > 0
end

local function destroy_card(target, dissolve_colours, silent, delay, sound, source_card)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(target, {
            colours = dissolve_colours,
            silent = silent,
            sound = sound,
            pitch = 1,
            volume = 1,
            delay = delay,
            source_card = source_card,
        })
    end
end

local function create_rare_joker(source_card)
    if not G or not G.jokers then
        return nil
    end

    local rare_joker = create_card('Joker', G.jokers, nil, 0.96, true, nil, nil, 'ag_weithiwrhaearn')
    rare_joker:add_to_deck()
    G.jokers:emplace(rare_joker)
    rare_joker:start_materialize()

    if G.jokers.align_cards then
        G.jokers:align_cards()
    end

    if AG_UTIL.notify_card_created then
        AG_UTIL.notify_card_created(source_card, rare_joker)
    end

    return rare_joker
end

local function forge(card)
    local consumables = get_destroyable_consumables()
    local common_jokers = get_destroyable_jokers(card, is_common_joker)
    local uncommon_jokers = get_destroyable_jokers(card, is_uncommon_joker)

    -- Multiplayer's TheOrder compatibility wrapper expects every random pool to
    -- contain at least one keyed card. Materials can disappear between the
    -- readiness check and this deferred calculation, so do not pass an empty
    -- pool through pseudorandom_element.
    if #consumables == 0 or #common_jokers == 0 or #uncommon_jokers == 0 then
        return nil
    end

    local consumable = pseudorandom_element(consumables, pseudoseed('ag_weithiwrhaearn_consumable'))
    local common_joker = pseudorandom_element(common_jokers, pseudoseed('ag_weithiwrhaearn_common'))
    local uncommon_joker = pseudorandom_element(uncommon_jokers, pseudoseed('ag_weithiwrhaearn_uncommon'))

    if not consumable or not common_joker or not uncommon_joker then
        return nil
    end

    destroy_card(consumable, nil, true, 0.1, 'forge', card)
    destroy_card(common_joker, { G.C.RED }, nil, 0.1 + FORGE_STEP_DELAY, 'forge', card)
    destroy_card(uncommon_joker, { G.C.RED }, nil, 0.1 + FORGE_STEP_DELAY * 2, 'forge', card)
    if not (AG_LEMURIAN_DECK.is_active and AG_LEMURIAN_DECK.is_active()) then
        destroy_card(card, { G.C.RED }, nil, 0.1 + FORGE_STEP_DELAY * 3, false, card)
    end

    local forged_joker = nil

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1 + FORGE_STEP_DELAY * 2 + 0.05,
        func = function()
            forged_joker = create_rare_joker(card)
            return true
        end,
    }))

    return true
end

SMODS.Joker({
    key = 'weithiwrhaearn',
    atlas = 'weithiwrhaearn',
    pos = { x = 0, y = 0 },
    name = 'Weithiwr Haearn',
    rarity = 2,
    cost = 6,

    config = {
        extra = {
            forge_ready = false,
            next_pulse = 0,
        }
    },

    loc_txt = {
        name = 'Weithiwr Haearn',
        text = {
            'When selecting a {C:attention}Blind{},',
            'destroy {C:attention}1{} consumable,',
            '{C:blue}Common{} Joker, and',
            '{C:green}Uncommon{} Joker to',
            'create a {C:red}Rare{} Joker,',
            'then {C:red,E:2}self destruct{}',
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = 'ag_unlock_discover_drommo', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and is_drommo_discovered()
    end,

    add_to_deck = function(self, card)
        get_extra(card)
    end,

    update = function(self, card, dt)
        local extra = get_extra(card)
        local ready = not card.getting_sliced
            and G
            and G.GAME
            and G.STATE == G.STATES.BLIND_SELECT
            and has_forge_materials(card)

        extra.forge_ready = ready

        AG_UTIL.update_ready_pulse(card, ready)
    end,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            local forged = forge(card)

            if forged then
                return {
                    message = 'Forged!',
                    colour = G.C.RED,
                    card = card,
                }
            end
        end
    end,
})
