SMODS.Atlas({
    key = "deadrabbit",
    path = "deadrabbit.png",
    px = 69,
    py = 93,
})

local function enhance_random_hand_cards(source_card)
    if not G.hand or not G.hand.cards or #G.hand.cards == 0 then
        return
    end

    local hand_cards = {}
    for i = 1, #G.hand.cards do
        hand_cards[i] = G.hand.cards[i]
    end

    pseudoshuffle(hand_cards, pseudoseed("ag_deadrabbit"))

    local amount = pseudorandom("ag_deadrabbit_amount", 1, #hand_cards)
    amount = math.max(1, math.floor(amount or 1))

    for i = 1, amount do
        local target_card = hand_cards[i]
        if target_card then
            target_card:set_ability(G.P_CENTERS.m_lucky, nil, true)
            target_card:juice_up()
        end
    end

    card_eval_status_text(source_card, "extra", nil, nil, nil, {
        message = localize("k_upgrade_ex"),
        colour = G.C.SECONDARY_SET.Enhanced,
    })
end

SMODS.Joker({
    key = "deadrabbit",
    atlas = "deadrabbit",
    pos = { x = 0, y = 0 },
    name = "Dead Rabbit",
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = "Dead Rabbit",
        text = {
            "If this Joker is sold or destroyed, give {C:gold,T:m_lucky}Lucky{}",
            "to a random number of cards in hand",
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
    end,

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if context.selling_self or (context.joker_type_destroyed and context.card == card) then
            G.E_MANAGER:add_event(Event({
                func = function()
                    enhance_random_hand_cards(card)
                    return true
                end,
            }))
        end
    end,
})
