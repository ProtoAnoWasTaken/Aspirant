SMODS.Atlas({
    key = "cherrybomb",
    path = "cherrybomb.png",
    px = 69,
    py = 93,
})

local function get_chips(card)
    return (card.ability and card.ability.extra and card.ability.extra.chips) or 0
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 76
end

local function destroy_cherry_bomb(card)
    card.getting_sliced = true

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()
            if card and not card.removed then
                play_sound("glass" .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end
    }))
end

SMODS.Joker({
    key = "cherrybomb",
    atlas = "cherrybomb",
    pos = { x = 0, y = 0 },
    name = "Cherry Bomb",
    rarity = 2,
    cost = 6,

    config = {
        extra = {
            chips = 0,
            gain = 76,
            triggered_this_hand = false
        }
    },

    loc_txt = {
        name = "Cherry Bomb",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips if played hand",
            "causes the score to {C:attention}catch fire{}",
            "{C:green}1 in 3{} chance to {C:red,E:2}self destruct{}",
            "on activation",
            "{C:inactive}(Currently {C:chips}+#1#{}{C:inactive} Chips){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_chips(card),
                get_gain(card)
            }
        }
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = "ag_locked_joker", set = "Other" }
    end,

    calculate = function(self, card, context)
        if context.blueprint or card.getting_sliced then
            return
        end

        if context.final_scoring_step and not context.retrigger_joker then
            card.ability.extra.triggered_this_hand = false

            G.E_MANAGER:add_event(Event({
                func = function()
                    if not card or card.removed or card.getting_sliced then
                        return true
                    end

                    local score_intensity = G.ARGS and G.ARGS.score_intensity
                    local earned_score = score_intensity and score_intensity.earned_score or 0
                    local required_score = score_intensity and score_intensity.required_score or 0

                    if required_score > 0 and earned_score >= required_score and not card.ability.extra.triggered_this_hand then
                        card.ability.extra.triggered_this_hand = true
                        card.ability.extra.chips = get_chips(card) + get_gain(card)

                        card_eval_status_text(card, "extra", nil, nil, nil, {
                            message = "+" .. tostring(get_gain(card)) .. " Chips",
                            colour = G.C.CHIPS,
                        })

                        if pseudorandom("ag_cherrybomb_self_destruct") < (1 / 3) then
                            card_eval_status_text(card, "extra", nil, nil, nil, {
                                message = "Destroyed!",
                                colour = G.C.RED,
                            })
                            destroy_cherry_bomb(card)
                        end
                    end

                    return true
                end
            }))
        end

        if context.joker_main and get_chips(card) > 0 then
            return {
                chip_mod = get_chips(card),
                message = "+" .. tostring(get_chips(card))
            }
        end
    end
})
