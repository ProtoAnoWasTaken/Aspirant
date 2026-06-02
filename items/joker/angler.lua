SMODS.Atlas({
    key = 'angler',
    path = 'angler.png',
    px = 69,
    py = 93,
})

local function is_legendary_joker(joker)
    local center = joker and joker.config and joker.config.center
    local rarity = center and center.rarity

    if rarity == 'Legendary' then
        rarity = 4
    end

    if type(rarity) == 'string' then
        rarity = rarity:lower()
    end

    return joker
        and not joker.getting_sliced
        and center
        and (
            rarity == 4
            or rarity == 'legendary'
        )
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

local function get_mult(card)
    return (card.ability and card.ability.extra and card.ability.extra.mult) or 0
end

local function get_mult_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.mult_gain) or 1
end

local function get_legendary_bonus(card)
    return 5
end

local function card_is_in_list(target, cards)
    for _, card in ipairs(cards or {}) do
        if card == target then
            return true
        end
    end

    return false
end

local function is_scored_face_card(target_card, context)
    return target_card
        and target_card:is_face()
        and card_is_in_list(target_card, context and context.scoring_hand)
end

local function get_legendary_jokers(card)
    local legendary_jokers = {}

    if not G or not G.jokers or not G.jokers.cards then
        return legendary_jokers
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= card and is_legendary_joker(joker) then
            legendary_jokers[#legendary_jokers + 1] = joker
        end
    end

    return legendary_jokers
end

local function destroy_jokers(card, jokers)
    for _, joker in ipairs(jokers) do
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                if joker and not joker.removed and not joker.getting_sliced then
                    joker.getting_sliced = true
                    play_sound('glass' .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                    joker:start_dissolve({ G.C.RED }, nil, 1.6)
                end

                return true
            end,
        }))
    end

    if #jokers > 0 then
        if Aspirant and Aspirant.unlock_theovectivorous then
            Aspirant.unlock_theovectivorous()
        end

        ease_dollars(15 * #jokers)
    end
end

SMODS.Joker({
    key = 'angler',
    atlas = 'angler',
    pos = { x = 0, y = 0 },
    name = 'Angler',
    rarity = 3,
    cost = 8,

    config = { extra = { mult = 0, mult_gain = 1 } },

    loc_txt = {
        name = 'Angler',
        text = {
            "Played {C:attention}face{} cards are",
            "destroyed after scoring",
            "This Joker gains {C:mult}+#2#{} Mult for",
            "every card lost this way",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}",
        },
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_mult(card),
                get_mult_gain(card),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.destroy_card
            and not context.blueprint
            and not card.getting_sliced
            and is_scored_face_card(context.destroy_card, context)
        then
            return { remove = true }
        end

        if context.remove_playing_cards
            and not context.blueprint
            and not card.getting_sliced
        then
            local destroyed_face_count = 0

            for _, removed_card in ipairs(context.removed or {}) do
                if removed_card and removed_card:is_face() then
                    destroyed_face_count = destroyed_face_count + 1
                end
            end

            if destroyed_face_count == 0 then
                return
            end

            card.ability.extra.mult = get_mult(card) + (get_mult_gain(card) * destroyed_face_count)

            return {
                message = '+' .. tostring(get_mult_gain(card) * destroyed_face_count) .. ' Mult',
                colour = G.C.MULT,
            }
        end

        if context.end_of_round
            and context.main_eval
            and not context.blueprint
            and not card.getting_sliced
        then
            local jokers_to_devour = get_legendary_jokers(card)
            local bonus_mult_gain = 0

            for _, joker in ipairs(jokers_to_devour) do
                bonus_mult_gain = bonus_mult_gain + get_legendary_bonus(joker)
            end

            if #jokers_to_devour > 0 then
                card.ability.extra.mult_gain = get_mult_gain(card) + bonus_mult_gain
                if card.set_cost then
                    card:set_cost()
                end
                card:juice_up(0.3, 0.4)
                destroy_jokers(card, jokers_to_devour)

                return {
                    message = '+' .. format_xmult(bonus_mult_gain) .. ' Gain',
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main then
            if get_mult(card) > 0 then
                return {
                    mult_mod = get_mult(card),
                    message = '+' .. tostring(get_mult(card)) .. ' Mult',
                }
            end
        end
    end,
})
