SMODS.Atlas({
    key = 'diwygiwryddaear',
    path = 'diwygiwryddaear.png',
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_chips(card)
    return (card.ability and card.ability.extra and card.ability.extra.chips) or 0
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 30
end

local function is_weithiwr_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'weithiwrhaearn')
        or false
end

local function is_playing_card_purchase(context)
    return context
        and context.buying_card
        and context.card
        and context.card.ability
        and context.card.ability.set == 'Default'
end

local function is_inventory_consumable_sale(context)
    return context
        and context.selling_card
        and context.card
        and context.card.area == G.consumeables
        and context.card.ability
        and (
            context.card.ability.consumeable
            or context.card.ability.set == 'Tarot'
            or context.card.ability.set == 'Planet'
            or context.card.ability.set == 'Spectral'
        )
end

SMODS.Joker({
    key = 'diwygiwryddaear',
    atlas = 'diwygiwryddaear',
    pos = { x = 0, y = 0 },
    name = 'Diwygiwr Y Ddaear',
    rarity = 3,
    cost = 8,

    config = {
        extra = {
            chips = 0,
            gain = 30,
        }
    },

    loc_txt = {
        name = 'Diwygiwr Y Ddaear',
        text = {
            'This Joker gains {C:chips}+#2#{} Chips',
            'for each {C:attention}playing card{}',
            'bought at the {C:attention}Shop{}',
            'This Joker gains {C:chips}+#2#{} Chips',
            'for each {C:attention}consumable{} sold',
            'from the {C:attention}inventory{}',
            '{C:inactive}(Currently {C:chips}+#1#{}{C:inactive} Chips){}',
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_chips(card),
                get_gain(card),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = 'ag_unlock_discover_weithiwrhaearn', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and is_weithiwr_discovered()
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if is_playing_card_purchase(context) or is_inventory_consumable_sale(context) then
            card.ability.extra.chips = get_chips(card) + get_gain(card)

            return {
                message = '+' .. tostring(get_gain(card)) .. ' Chips',
                colour = G.C.CHIPS,
            }
        end

        if context.joker_main and Aspirant.joker_utils.is_positive(get_chips(card)) then
            return {
                chip_mod = get_chips(card),
                message = '+' .. tostring(get_chips(card)),
            }
        end
    end,
})
