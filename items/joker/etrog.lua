SMODS.Atlas({
    key = "etrog",
    path = "etrog.png",
    px = 69,
    py = 93,
})

local function get_hands_remaining(card)
    return (card.ability and card.ability.extra and card.ability.extra.hands_remaining) or 8
end

local function get_cash_multiplier(card)
    local multiplier = (card.ability and card.ability.extra and card.ability.extra.cash_multiplier) or 2
    return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(card, multiplier) or multiplier
end

local function get_hands_used_this_round(card)
    return (card.ability and card.ability.extra and card.ability.extra.hands_used_this_round) or 0
end

local function destroy_etrog(card)
    card.getting_sliced = true

    G.E_MANAGER:add_event(Event({
        func = function()
            if card and not card.removed then
                play_sound("glass" .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end,
    }))
end

local function get_interest_payout()
    if not G or not G.GAME or G.GAME.modifiers.no_interest then
        return 0
    end

    local dollars = G.GAME.dollars or 0
    local interest_amount = G.GAME.interest_amount or 0
    local interest_cap = G.GAME.interest_cap or 0
    return interest_amount * math.min(math.floor(dollars / 5), interest_cap / 5)
end

local function get_round_cashout_base()
    local blind_reward = (G and G.GAME and G.GAME.blind and G.GAME.blind.dollars) or 0
    local hands_left = (G and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_left) or 0
    local discards_left = (G and G.GAME and G.GAME.current_round and G.GAME.current_round.discards_left) or 0
    return blind_reward + hands_left + discards_left + get_interest_payout()
end

SMODS.Joker({
    key = "etrog",
    atlas = "etrog",
    pos = { x = 0, y = 0 },
    name = "Etrog",
    rarity = 2,
    cost = 7,

    config = { extra = { cash_multiplier = 2, hands_remaining = 8, hands_used_this_round = 0 } },
    pools = { Food = true },

    loc_txt = {
        name = "Etrog",
        text = {
            "Increases cash payout at",
            "the end of round by {C:money}X#1#{} for {C:attention}#2#{} hands",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_cash_multiplier(card),
                get_hands_remaining(card),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    add_to_deck = function(self, card, from_debuff)
        if Aspirant and Aspirant.queue_unlock_fools_garden then
            Aspirant.queue_unlock_fools_garden()
        elseif Aspirant and Aspirant.unlock_fools_garden then
            Aspirant.unlock_fools_garden()
        end
    end,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and get_hands_remaining(card) > 0
        then
            card.ability.extra.hands_remaining = get_hands_remaining(card) - 1
            card.ability.extra.hands_used_this_round = get_hands_used_this_round(card) + 1

            return {
                message = tostring(get_hands_remaining(card)) .. " left",
                colour = G.C.MONEY,
            }
        end

        if context.end_of_round and not context.blueprint then
            if get_hands_remaining(card) <= 0 and not card.getting_sliced then
                destroy_etrog(card)
                return {
                    message = "Expired!",
                    colour = G.C.RED,
                }
            end
        end
    end,

    calc_dollar_bonus = function(self, card)
        if get_hands_used_this_round(card) <= 0 then
            return
        end

        local bonus = math.max(0, math.floor(get_round_cashout_base() * (get_cash_multiplier(card) - 1)))
        card.ability.extra.hands_used_this_round = 0

        if bonus > 0 then
            return bonus
        end
    end,
})
