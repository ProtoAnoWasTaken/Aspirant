SMODS.Atlas({
    key = "lolhoo",
    path = "lolhoo.png",
    px = 69,
    py = 93,
})

SMODS.Sound({
    key = "chomp",
    path = "chomp.ogg",
    prefix_config = { key = false },
})

local function format_xmult(value)
    local formatted = string.format("%.2f", value)
    formatted = formatted:gsub("(%..-)0+$", "%1")
    return formatted:gsub("%.$", "")
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    local gain = (card.ability and card.ability.extra and card.ability.extra.gain) or 0.5
    return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(card, gain) or gain
end

local function get_rounds(card)
    return (card.ability and card.ability.extra and card.ability.extra.rounds) or 8
end

local function get_food_rarety_rounds(joker)
    local rarity = joker and joker.config and joker.config.center and joker.config.center.rarity
    local rarity_map = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Legendary = 4,
    }

    if type(rarity) == "string" and rarity_map[rarity] then
        local rounds = rarity_map[rarity]
        return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(joker, rounds) or rounds
    end

    if type(rarity) == "number" then
        local rounds = math.max(1, math.floor(rarity))
        return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(joker, rounds) or rounds
    end

    return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(joker, 1) or 1
end

local function get_consumable_food_targets(source_card)
    local jokers = {}

    if not G or not G.jokers or not G.jokers.cards then
        return jokers
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= source_card
            and not joker.removed
            and not joker.getting_sliced
            and not (joker.ability and joker.ability.eternal)
            and joker.is_food
            and joker:is_food()
        then
            jokers[#jokers + 1] = joker
        end
    end

    return jokers
end

local function destroy_lolhoo(card)
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

local function consume_food_joker(source_card, target)
    local gained_rounds = get_food_rarety_rounds(target)

    target.getting_sliced = true
    source_card.ability.extra.rounds = get_rounds(source_card) + gained_rounds

    G.E_MANAGER:add_event(Event({
        func = function()
            if target and not target.removed then
                play_sound("chomp")
                target:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end,
    }))

    return gained_rounds
end

SMODS.Joker({
    key = "lolhoo",
    atlas = "lolhoo",
    pos = { x = 0, y = 0 },
    name = "Lolhoo",
    rarity = 2,
    cost = 6,

    config = { extra = { xmult = 1, gain = 0.5, rounds = 8 } },
    pools = { Food = true },

    loc_txt = {
        name = "Lolhoo",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult at end of round",
            "{C:red,E:2}Self-destructs{} in {C:attention}#3#{} rounds",
            "Can consume other {C:attention}Food Jokers{}",
            "for additional rounds based on rarity",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
                get_rounds(card),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.joker_main and get_xmult(card) > 1 then
            return {
                Xmult_mod = get_xmult(card),
                message = "X" .. format_xmult(get_xmult(card)),
            }
        end

        if context.end_of_round and context.main_eval and not context.blueprint and not card.getting_sliced then
            card.ability.extra.xmult = get_xmult(card) + get_gain(card)
            card.ability.extra.rounds = get_rounds(card) - 1

            if get_rounds(card) <= 0 then
                local food_targets = get_consumable_food_targets(card)
                local target = #food_targets > 0 and pseudorandom_element(food_targets, pseudoseed("ag_lolhoo_food")) or nil

                if target then
                    local gained_rounds = consume_food_joker(card, target)
                    return {
                        message = "+" .. tostring(gained_rounds) .. " rounds",
                        colour = G.C.GREEN,
                    }
                end

                destroy_lolhoo(card)
                return {
                    message = "Consumed!",
                    colour = G.C.RED,
                }
            end

            return {
                message = "+X" .. format_xmult(get_gain(card)),
                colour = G.C.MULT,
            }
        end
    end,
})
