SMODS.Atlas({
    key = 'andromeda',
    path = 'andromeda.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local AG_UTIL = AG.joker_utils or {}
AG.andromeda_state = AG.andromeda_state or {}

local function format_xmult(value)
    return AG_UTIL.format_xmult and AG_UTIL.format_xmult(value) or tostring(value)
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.1
end

local function get_threshold(card)
    return (card.ability and card.ability.extra and card.ability.extra.threshold) or 4
end

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or {}
end

local function is_andromeda_card(card)
    local center = card and card.config and card.config.center
    local key = center and center.key
    local original_key = center and center.original_key

    return card
        and center
        and (
            original_key == 'andromeda'
            or key == 'andromeda'
            or (type(key) == 'string' and key:match('andromeda$') ~= nil)
        )
end
local function apply_upgrade_gain(card, show_message)
    local extra = get_extra(card)

    if not card or card.getting_sliced or extra.supernova_ready then
        return
    end

    extra.xmult = math.min(get_threshold(card), get_xmult(card) + get_gain(card))

    if get_xmult(card) >= get_threshold(card) then
        extra.supernova_ready = true
        extra.next_pulse = 0
        card:juice_up(0.3, 0.4)
        return
    end

    if show_message and card_eval_status_text then
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = 'X' .. format_xmult(get_gain(card)),
            colour = G.C.MULT,
        })
    end
end

local function trigger_andromeda_upgrade(source_card)
    if not G or not G.jokers or not G.jokers.cards then
        return
    end

    if is_andromeda_card(source_card) then
        return
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker and is_andromeda_card(joker) and not joker.getting_sliced then
            apply_upgrade_gain(joker, true)
        end
    end
end

local function peldan_is_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'peldan')
        or false
end

local function get_visible_hands()
    local hands = {}

    for _, hand_name in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_name]
        if hand then
            hands[#hands + 1] = hand_name
        end
    end

    return hands
end

local function get_scoring_parameters()
    local parameters = SMODS
        and SMODS.Scoring_Parameter
        and SMODS.Scoring_Parameter.obj_buffer

    return type(parameters) == 'table' and parameters or { 'chips', 'mult' }
end

local function upgrade_hand_direct(card, hand_name, amount)
    local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_name]

    if not hand then
        return
    end

    local context = {
        card = card,
        poker_hand_changed = true,
        scoring_name = hand_name,
        old_parameters = {},
        new_parameters = {},
        old_level = hand.level,
    }

    for _, parameter in ipairs(get_scoring_parameters()) do
        if hand[parameter] then
            context.old_parameters[parameter] = hand[parameter]
            hand[parameter] = hand[parameter] + ((hand['l_' .. parameter] or 0) * amount)
            context.new_parameters[parameter] = hand[parameter]
        end
    end

    hand.level = hand.level + amount
    context.new_level = hand.level

    if SMODS and SMODS.calculate_context then
        SMODS.calculate_context(context)
    end

    if G and G.E_MANAGER and Event and check_for_unlock then
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                check_for_unlock({ type = 'upgrade_hand', hand = hand_name, level = hand.level })
                return true
            end,
        }))
    end
end

local function upgrade_visible_hands(card)
    for _, hand_name in ipairs(get_visible_hands()) do
        upgrade_hand_direct(card, hand_name, 2)
    end
end

local function grant_bonus_chips(bonus_chips)
    if bonus_chips <= 0 then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.7,
        func = function()
            ease_chips((G.GAME and G.GAME.chips or 0) + bonus_chips)
            return true
        end,
    }))
end

local function trigger_supernova(card)
    local extra = get_extra(card)
    local blind_chips = (G and G.GAME and G.GAME.blind and G.GAME.blind.chips) or 0
    local bonus_chips = math.floor(blind_chips * 0.1)

    if G and G.GAME then
        G.GAME.ag_andromeda_self_destructed = true
    end

    grant_bonus_chips(bonus_chips)
    upgrade_visible_hands(card)

    if AG.unlock_through_solid_ground then
        AG.unlock_through_solid_ground({ force = true })
    end

    extra.supernova_active = false
    extra.supernova_resolving = true

    if AG_UTIL.consume_protective_beam and AG_UTIL.consume_protective_beam(card) then
        extra.supernova_resolving = false
        return bonus_chips
    end

    if G and G.GAME then
        G.GAME.ag_andromeda_self_destructed = true
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            if card and not card.removed and not card.getting_sliced and AG_UTIL.destroy_card then
                AG_UTIL.destroy_card(card, {
                    colours = { G.C.RED },
                    delay = 0,
                    self_destruct = true,
                    source_card = card,
                })
            end
            return true
        end,
    }))

    return bonus_chips
end

local function ensure_andromeda_upgrade_hook()
    if AG.andromeda_state.level_up_hand_hooked or type(level_up_hand) ~= 'function' then
        return
    end

    AG.andromeda_state.original_level_up_hand = level_up_hand

    level_up_hand = function(card, hand, instant, amount, statustext)
        local result = AG.andromeda_state.original_level_up_hand(card, hand, instant, amount, statustext)
        trigger_andromeda_upgrade(card)
        return result
    end

    AG.andromeda_state.level_up_hand_hooked = true
end

ensure_andromeda_upgrade_hook()

SMODS.Joker({
    key = 'andromeda',
    atlas = 'andromeda',
    pos = { x = 0, y = 0 },
    name = 'Andromeda',
    rarity = 3,
    cost = 8,

    config = {
        extra = {
            xmult = 1,
            gain = 0.1,
            threshold = 4,
            supernova_ready = false,
            supernova_active = false,
            supernova_resolving = false,
            next_pulse = 0,
        }
    },

    loc_txt = {
        name = 'Andromeda',
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "every time a {C:planet}Planet{} card is used",
            "{C:attention}Supernova{} in {X:mult,C:white}X#3#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive}){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
                format_xmult(get_threshold(card)),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_discover_peldan', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and peldan_is_discovered()
    end,

    update = function(self, card, dt)
        local extra = card and card.ability and card.ability.extra

        if not extra then
            return
        end

        if (extra.supernova_ready or extra.supernova_active) and not card.getting_sliced then
            AG_UTIL.update_ready_pulse(card, true)
        else
            AG_UTIL.update_ready_pulse(card, false)
        end
    end,

    calculate = function(self, card, context)
        local extra = get_extra(card)

        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
            and extra.supernova_ready
            and not extra.supernova_active
        then
            extra.supernova_ready = false
            extra.supernova_active = true
            extra.next_pulse = 0
            card:juice_up(0.4, 0.6)
            return
        end

        if context.joker_main and get_xmult(card) > 1 then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end

        if context.after
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
            and extra.supernova_active
            and not extra.supernova_resolving
        then
            local bonus_chips = trigger_supernova(card)

            return {
                message = bonus_chips > 0 and ('+' .. number_format(bonus_chips) .. ' Chips') or 'Supernova!',
                colour = G.C.ATTENTION,
            }
        end
    end,
})
