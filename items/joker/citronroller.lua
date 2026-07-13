SMODS.Atlas({
    key = 'citronroller',
    prefix_config = { key = false },
    path = 'citron_lemon.png',
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = 'citron_orange',
    prefix_config = { key = false },
    path = 'citron_orange.png',
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = 'citron_lime',
    prefix_config = { key = false },
    path = 'citron_lime.png',
    px = 69,
    py = 93,
})

local function get_extra(card)
    if not card then
        return nil
    end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    return card.ability.extra
end

local function get_card_index(card)
    if not G or not G.jokers or not G.jokers.cards then
        return nil
    end

    for i, joker in ipairs(G.jokers.cards) do
        if joker == card then
            return i
        end
    end

    return nil
end

local function get_adjacent_targets(card)
    local valid = {}
    local index = get_card_index(card)

    if not index then
        return valid
    end

    local left = G.jokers.cards[index - 1]
    local right = G.jokers.cards[index + 1]

    if left and left ~= card and not left.debuff and left.config and left.config.center and left.config.center.blueprint_compat then
        valid[#valid + 1] = left
    end

    if right and right ~= card and not right.debuff and right.config and right.config.center and right.config.center.blueprint_compat then
        valid[#valid + 1] = right
    end

    return valid
end

local function ensure_manual_movement_lock(card)
    if not card then
        return
    end

    if not G or not G.jokers or card.area ~= G.jokers then
        return
    end

    local extra = get_extra(card)
    local drag_state = card.states and card.states.drag

    if extra
        and extra.ag_manual_movement_lock_applied
        and (not drag_state or drag_state.can == false)
    then
        return
    end

    if extra then
        extra.ag_manual_movement_lock_applied = true
    end

    if drag_state then
        drag_state.can = false
    end
end

local function clear_manual_movement_lock(card)
    if not card then
        return
    end

    local extra = get_extra(card)
    if extra then
        extra.ag_manual_movement_lock_applied = false
    end

    if card.states and card.states.drag then
        card.states.drag.can = true
    end
end

local function move_to_random_slot(card)
    if not card or not G or not G.jokers or card.area ~= G.jokers then
        return false
    end

    local index = get_card_index(card)
    local cards = G.jokers.cards

    if not index or #cards <= 1 then
        return false
    end

    local possible_slots = {}

    for i = 1, #cards do
        if i ~= index then
            possible_slots[#possible_slots + 1] = i
        end
    end

    local target_index = pseudorandom_element(possible_slots, pseudoseed('ag_citronroller_move'))
    if not target_index then
        return false
    end

    table.remove(cards, index)
    table.insert(cards, target_index, card)

    if G.jokers.align_cards then
        G.jokers:align_cards()
    end

    card:juice_up(0.3, 0.3)
    return true
end

local function find_center_by_suffix(suffix)
    if not G or not G.P_CENTERS then
        return nil
    end

    for _, center in pairs(G.P_CENTERS) do
        if center
            and center.set == 'Joker'
            and (
                center.original_key == suffix
                or center.key == suffix
                or (type(center.key) == 'string' and center.key:match(suffix .. '$') ~= nil)
            )
        then
            return center
        end
    end

    return nil
end

local function choose_variant_key(card)
    local extra = get_extra(card)
    if not extra then
        return 'citronroller'
    end

    if extra.variant_key then
        return extra.variant_key
    end

    local roll = pseudorandom('ag_citronroller_variant')

    if roll < 0.02 then
        extra.variant_key = 'citronroller_lime'
    elseif roll < 0.07 then
        extra.variant_key = 'citronroller_orange'
    else
        extra.variant_key = 'citronroller'
    end

    return extra.variant_key
end

local function get_copy_numerator()
    return G and G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1
end

local function apply_variant_if_needed(card)
    local current_center = card and card.config and card.config.center
    local variant_key = choose_variant_key(card)

    if not card or not current_center then
        return
    end

    if current_center.original_key == variant_key
        or current_center.key == variant_key
        or (type(current_center.key) == 'string' and current_center.key:match(variant_key .. '$') ~= nil)
    then
        return
    end

    local target_center = find_center_by_suffix(variant_key)
    if target_center then
        card:set_ability(target_center, nil, true)
    end
end

local function shared_add_to_deck(self, card, from_debuff)
    apply_variant_if_needed(card)
    ensure_manual_movement_lock(card)
end

local function shared_update(self, card, dt)
    ensure_manual_movement_lock(card)
end

local function shared_calculate(self, card, context)
    if card.getting_sliced then
        return
    end

    if context.end_of_round and context.main_eval and not context.blueprint then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0,
            func = function()
                clear_manual_movement_lock(card)
                move_to_random_slot(card)
                ensure_manual_movement_lock(card)
                return true
            end,
        }))

        return {
            message = 'Rolled!',
            colour = G.C.ATTENTION,
        }
    end

    if context.no_blueprint then
        return
    end

    if not context.joker_main
        or context.blueprint
        or context.repetition
        or context.individual
        or context.retrigger_joker
    then
        return
    end

    local targets = get_adjacent_targets(card)
    if #targets == 0 then
        return
    end

    if not SMODS.pseudorandom_probability(card, 'ag_citronroller_copy', get_copy_numerator(), 3, 'ag_citronroller_copy') then
        return {
            message = 'Nope!',
            colour = G.C.RED,
        }
    end

    local target = pseudorandom_element(targets, pseudoseed('ag_citronroller_target'))
    return SMODS.blueprint_effect(card, target, context)
end

SMODS.Joker({
    key = 'citronroller',
    atlas = 'citronroller',
    prefix_config = { atlas = false },
    pos = { x = 0, y = 0 },
    name = 'Citron Roller',
    rarity = 2,
    cost = 6,

    config = {
        extra = {
            variant_key = nil,
        }
    },

    loc_txt = {
        name = 'Citron Roller',
        text = {
            '{C:green}#1# in 3{} chance to copy the',
            '{C:attention}Joker{} to its left or right',
            'Moves after each round',
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_copy_numerator(),
            }
        }
    end,

    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = shared_add_to_deck,
    update = shared_update,
    calculate = shared_calculate,
})

local function create_citron_variant(def)
    SMODS.Joker({
        key = def.key,
        atlas = def.atlas,
        prefix_config = { atlas = false },
        pos = { x = 0, y = 0 },
        name = 'Citron Roller',
        rarity = 2,
        cost = 6,

        config = {
            extra = {
                variant_key = def.fixed_variant_key,
            }
        },

        loc_txt = {
            name = 'Citron Roller',
            text = {
                '{C:green}#1# in 3{} chance to copy the',
                '{C:attention}Joker{} to its left or right',
                'Moves after each round',
            }
        },

        loc_vars = function(self, info_queue, card)
            return {
                vars = {
                    get_copy_numerator(),
                }
            }
        end,

        blueprint_compat = false,
        eternal_compat = true,
        perishable_compat = true,
        no_collection = def.no_collection or false,

        in_pool = def.in_pool,
        add_to_deck = shared_add_to_deck,
        update = shared_update,
        calculate = shared_calculate,
    })
end

create_citron_variant({
    key = 'citronroller_orange',
    atlas = 'citron_orange',
    fixed_variant_key = 'citronroller_orange',
    no_collection = true,
    in_pool = function()
        return false
    end,
})

create_citron_variant({
    key = 'citronroller_lime',
    atlas = 'citron_lime',
    fixed_variant_key = 'citronroller_lime',
    no_collection = true,
    in_pool = function()
        return false
    end,
})
