SMODS.Atlas({
    key = 'takethetrain',
    path = 'takethetrain.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local AG_UTIL = AG.joker_utils or {}
local TAKE_THE_TRAIN_CENTER_KEY = 'j_tk9g_takethetrain'
local RIDE_THE_BUS_CENTER_KEY = 'j_ride_the_bus'

AG.train_state = AG.train_state or {}

local function format_mult(value)
    return tostring(math.floor(value or 0))
end

local function get_run_key()
    return G and G.GAME and tostring(G.GAME) or nil
end

local function ensure_train_state_current()
    local run_key = get_run_key()

    if AG.train_state.run_key ~= run_key then
        AG.train_state.run_key = run_key
        AG.train_state.ride_the_bus_purchased = false
        AG.train_state.active_take_the_train = 0
    end
end

local function has_active_take_the_train(ignore_card)
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center

        if joker ~= ignore_card
            and not joker.getting_sliced
            and center
            and center.key == TAKE_THE_TRAIN_CENTER_KEY
        then
            return true
        end
    end

    return false
end

local function has_ride_the_bus()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center

        if joker
            and not joker.getting_sliced
            and center
            and center.key == RIDE_THE_BUS_CENTER_KEY
        then
            return true
        end
    end

    return false
end

local function ride_the_bus_locked(ignore_card)
    ensure_train_state_current()
    return (AG.train_state.active_take_the_train or 0) > 0 or has_active_take_the_train(ignore_card)
end

local function mark_ride_the_bus_purchased()
    ensure_train_state_current()
    AG.train_state.ride_the_bus_purchased = true
end

local function get_ride_the_bus_center()
    if not G or not G.P_CENTERS then
        return nil
    end

    return G.P_CENTERS[RIDE_THE_BUS_CENTER_KEY]
end

local function ensure_ride_the_bus_patched()
    local ride_the_bus = get_ride_the_bus_center()

    if not ride_the_bus or AG.train_state.ride_the_bus_patch_applied then
        return
    end

    AG.train_state.original_ride_the_bus_in_pool = ride_the_bus.in_pool
    AG.train_state.original_ride_the_bus_add_to_deck = ride_the_bus.add_to_deck

    ride_the_bus.in_pool = function(self, args)
        if ride_the_bus_locked() then
            return false
        end

        if AG.train_state.original_ride_the_bus_in_pool then
            return AG.train_state.original_ride_the_bus_in_pool(self, args)
        end

        return true
    end

    ride_the_bus.add_to_deck = function(self, card, from_debuff)
        mark_ride_the_bus_purchased()

        if AG.train_state.original_ride_the_bus_add_to_deck then
            return AG.train_state.original_ride_the_bus_add_to_deck(self, card, from_debuff)
        end
    end

    AG.train_state.ride_the_bus_patch_applied = true
end

local function get_mult(card)
    return (card.ability and card.ability.extra and card.ability.extra.mult) or 0
end

local function set_fresh_destroy_ante(card)
    if not (card and card.ability) then
        return
    end

    card.ability.extra = card.ability.extra or {}

    local current_ante = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 1
    card.ability.extra.destroy_ante = current_ante + 5
end

local function get_antes_left(card)
    local current_ante = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 1
    local destroy_ante = (card.ability and card.ability.extra and card.ability.extra.destroy_ante) or (current_ante + 5)

    return math.max(0, destroy_ante - current_ante)
end

local function hand_scores_face_card(scoring_hand)
    for _, playing_card in ipairs(scoring_hand or {}) do
        local id = playing_card and playing_card.get_id and playing_card:get_id() or nil

        if id and id >= 11 and id <= 13 then
            return true
        end
    end

    return false
end

local function destroy_take_the_train(card)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(card, {
            colours = { G.C.RED },
            self_destruct = true,
            source_card = card,
        })
        return
    end

    card.getting_sliced = true

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            if card and not card.removed then
                play_sound('glass' .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end,
    }))
end

SMODS.Joker({
    key = 'takethetrain',
    atlas = 'takethetrain',
    pos = { x = 0, y = 0 },
    name = 'Take the Train',
    rarity = 1,
    cost = 4,

    config = { extra = { mult = 0, gain = 2 } },

    loc_txt = {
        name = 'Take the Train',
        text = {
            "This Joker gains {C:mult}+#2#{} Mult for each",
            "consecutive hand played while",
            "scoring a {C:attention}face{} card",
            "{C:red,E:2}Self destructs{} in {C:attention}5{} Antes",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult, #3# Antes left){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_mult(get_mult(card)),
                format_mult((card.ability and card.ability.extra and card.ability.extra.gain) or 1),
                format_mult(get_antes_left(card)),
            }
        }
    end,

    set_ability = function(self, card, initial, delay_sprites)
        set_fresh_destroy_ante(card)
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    in_pool = function(self, args)
        ensure_train_state_current()
        ensure_ride_the_bus_patched()

        return not AG.train_state.ride_the_bus_purchased and not has_ride_the_bus()
    end,

    add_to_deck = function(self, card, from_debuff)
        ensure_train_state_current()
        ensure_ride_the_bus_patched()

        AG.train_state.active_take_the_train = (AG.train_state.active_take_the_train or 0) + 1

        set_fresh_destroy_ante(card)
    end,

    remove_from_deck = function(self, card, from_debuff)
        ensure_train_state_current()
        ensure_ride_the_bus_patched()

        AG.train_state.active_take_the_train = math.max(0, (AG.train_state.active_take_the_train or 0) - 1)
    end,

    calculate = function(self, card, context)
        ensure_train_state_current()
        ensure_ride_the_bus_patched()

        if context.buying_card and context.card then
            local center = context.card.config and context.card.config.center

            if center and center.key == RIDE_THE_BUS_CENTER_KEY then
                mark_ride_the_bus_purchased()
            end
        end

        if card.getting_sliced then
            return
        end

        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
        then
            if hand_scores_face_card(context.scoring_hand) then
                card.ability.extra.mult = get_mult(card) + card.ability.extra.gain

                return {
                    message = '+' .. format_mult(card.ability.extra.gain) .. ' Mult',
                    colour = G.C.MULT,
                }
            end

            if get_mult(card) > 0 then
                card.ability.extra.mult = 0

                return {
                    message = 'Reset!',
                    colour = G.C.RED,
                }
            end
        end

        if context.joker_main and get_mult(card) > 0 then
            return {
                mult_mod = get_mult(card),
                message = '+' .. format_mult(get_mult(card)) .. ' Mult',
            }
        end

        if context.ante_change and not context.blueprint and get_antes_left(card) <= 0 then
            destroy_take_the_train(card)

            return {
                message = 'Departed!',
                colour = G.C.RED,
            }
        end
    end,
})
