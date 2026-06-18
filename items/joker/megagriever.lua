SMODS.Atlas({
    key = 'megagriever',
    path = 'megagriever.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}
local UNIQUE_TARGET = 3

local function get_unique_consumed(card)
    return (card.ability and card.ability.extra and card.ability.extra.unique_consumed) or 0
end

local function get_consumed_types(card)
    if not card.ability then
        card.ability = {}
    end

    if not card.ability.extra then
        card.ability.extra = {}
    end

    card.ability.extra.consumed_types = card.ability.extra.consumed_types or {}
    return card.ability.extra.consumed_types
end

local function get_enhanced_targets()
    local targets = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.getting_sliced
            and playing_card.config
            and playing_card.config.center
            and playing_card.config.center.set == 'Enhanced'
        then
            targets[#targets + 1] = playing_card
        end
    end

    return targets
end

local function consume_random_enhanced_card(card)
    local targets = get_enhanced_targets()
    local target = #targets > 0 and pseudorandom_element(targets, pseudoseed('ag_megagriever_consume')) or nil

    if not target then
        return nil, false
    end

    local enhancement_key = target.config.center.key
    local consumed_types = get_consumed_types(card)
    local is_new_type = not consumed_types[enhancement_key]

    if is_new_type then
        consumed_types[enhancement_key] = true
        card.ability.extra.unique_consumed = get_unique_consumed(card) + 1
    end

    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(target, {
            silent = true,
            sound = false,
            delay = 0.1,
            source_card = card,
        })
    else
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                if target and not target.removed and not target.getting_sliced then
                    target.getting_sliced = true
                    target:start_dissolve(nil, true)
                end
                return true
            end
        }))
    end

    return target, is_new_type
end

local function create_reward_tags(amount)
    for _ = 1, amount do
        add_tag(Tag(get_next_tag_key()))
    end
end

local function trigger_payoff(card)
    create_reward_tags(UNIQUE_TARGET)

    if AG_UTIL.consume_protective_beam and AG_UTIL.consume_protective_beam(card) then
        return
    end

    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(card, {
            colours = { G.C.RED },
            delay = 0.2,
            self_destruct = true,
            source_card = card,
        })
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.2,
        func = function()
            if card and not card.removed and not card.getting_sliced then
                card.getting_sliced = true
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end
    }))
end

SMODS.Joker({
    key = 'megagriever',
    atlas = 'megagriever',
    pos = { x = 0, y = 0 },
    name = 'Mega Griever',
    rarity = 2,
    cost = 6,

    config = { extra = { unique_consumed = 0, consumed_types = {} } },

    loc_txt = {
        name = 'Mega Griever',
        text = {
            "When {C:attention}Blind{} is selected,",
            "this Joker consumes a random",
            "{C:attention}enhanced card{}",
            "If it consumes {C:attention}3{} uniquely enhanced",
            "cards, create {C:attention}3{} Tags and {C:red,E:2}self destructs{}",
            "{C:inactive}(Currently #1#/3){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_unique_consumed(card),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            local target, is_new_type = consume_random_enhanced_card(card)

            if not target then
                return
            end

            if get_unique_consumed(card) >= UNIQUE_TARGET then
                trigger_payoff(card)

                return {
                    message = '3 Tags',
                    colour = G.C.ATTENTION,
                }
            end

            return {
                message = is_new_type and (get_unique_consumed(card) .. '/' .. UNIQUE_TARGET) or 'Consumed!',
                colour = G.C.ATTENTION,
            }
        end
    end,
})
