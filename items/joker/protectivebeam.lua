SMODS.Atlas({
    key = "protectivebeam",
    path = "protectivebeam.png",
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function get_active(card)
    local e = get_extra(card)
    return e and e.active or false
end

local function set_active(card, active)
    local e = get_extra(card)
    if e then
        e.active = active
    end
end

local function get_adjacent_jokers(card)
    if not G or not G.jokers or not G.jokers.cards then return {} end
    
    local adjacent = {}
    local card_index = nil
    
    for i, joker in ipairs(G.jokers.cards) do
        if joker == card then
            card_index = i
            break
        end
    end
    
    if not card_index then return {} end
    
    if card_index > 1 then
        table.insert(adjacent, G.jokers.cards[card_index - 1])
    end
    if card_index < #G.jokers.cards then
        table.insert(adjacent, G.jokers.cards[card_index + 1])
    end
    
    return adjacent
end

local function destroy(card)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(card, { colours = { G.C.RED }, delay = 0 })
    end
end

local function joker_needs_protection(adjacent_joker)
    local adjacent_extra = adjacent_joker
        and adjacent_joker.ability
        and adjacent_joker.ability.extra

    if type(adjacent_extra) ~= "table" then
        return false
    end

    return adjacent_extra.hands_kept
        and adjacent_extra.delay
        and adjacent_extra.hands_kept >= adjacent_extra.delay
end

SMODS.Joker({
    key = "protectivebeam",
    atlas = "protectivebeam",
    pos = { x = 0, y = 0 },
    name = "Protective Beam",
    rarity = 1,
    cost = 4,

    config = {
        extra = {
            active = false
        }
    },

    loc_txt = {
        name = "Protective Beam",
        text = {
            "Prevents adjacent {c:attention}Jokers{}",
            "from {C:red,E:2}self destructing{},",
            "then {C:red,E:2}self destructs{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {}
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = "ag_unlock_discover_drommo", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args
            and args.type == "discover_amount"
            and AG_UTIL.is_center_discovered
            and AG_UTIL.is_center_discovered("Joker", "drommo")
    end,

    add_to_deck = function(self, card)
        get_extra(card)
    end,

    remove_from_deck = function(self, card)
    end,

    update = function(self, card, dt)
    end,

    calculate = function(self, card, context)
        if context.blueprint or card.getting_sliced then return end

        if context.before
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
        then
            local adjacent = get_adjacent_jokers(card)
            local adjacent_needs_protection = false
            
            for _, adjacent_joker in ipairs(adjacent) do
                if joker_needs_protection(adjacent_joker) then
                    adjacent_needs_protection = true
                    break
                end
            end
            
            if not adjacent_needs_protection then return end
            
            for _, adjacent_joker in ipairs(adjacent) do
                if joker_needs_protection(adjacent_joker) then
                    adjacent_joker.protected_from_destruct = true
                end
            end
            
            card:juice_up(0.8, 0.5)
            play_sound("glass" .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
            destroy(card)
            
            return {
                message = "Saved!",
                colour = G.C.BLUE,
            }
        end

    end,
})
