SMODS.Atlas({
    key = 'moltenmaggot',
    path = 'moltenmaggot.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.2
end

local function get_threshold(card)
    return (card.ability and card.ability.extra and card.ability.extra.threshold) or 22
end

local function count_self_destructs(context, source_card)
    return AG_UTIL.count_self_destructs and AG_UTIL.count_self_destructs(context, source_card) or 0
end

local function destroy_molten_maggot(card)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(card, {
            colours = { G.C.RED },
            self_destruct = true,
            source_card = card,
        })
        return
    end

    card.getting_sliced = true

    if Aspirant and Aspirant.unlock_secret_stair_2 then
        Aspirant.unlock_secret_stair_2()
    end

    G.E_MANAGER:add_event(Event({
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
    key = 'moltenmaggot',
    atlas = 'moltenmaggot',
    pos = { x = 0, y = 0 },
    name = 'Molten Maggot',
    rarity = 3,
    cost = 8,

    config = { extra = { xmult = 1, gain = 0.2, threshold = 22 } },

    loc_txt = {
        name = 'Molten Maggot',
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "whenever a card {C:red,E:2}self destructs{}",
            "{C:red,E:2}Self destructs{} in {X:mult,C:white}X#3#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
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

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,

    calculate = function(self, card, context)
        if card.getting_sliced then
            return
        end

        local self_destructs = count_self_destructs(context, card)

        if self_destructs > 0 then
            card.ability.extra.xmult = get_xmult(card) + (get_gain(card) * self_destructs)

            if get_xmult(card) >= get_threshold(card) then
                destroy_molten_maggot(card)

                return {
                    message = 'Melted!',
                    colour = G.C.RED,
                }
            end

            return {
                message = 'X' .. format_xmult(get_gain(card) * self_destructs),
                colour = G.C.MULT,
            }
        end

        if context.joker_main and Aspirant.joker_utils.compare_numbers(get_xmult(card), 'gt', 1) then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
