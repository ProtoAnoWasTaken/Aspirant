SMODS.Atlas({
    key = 'maingalarpar',
    path = 'maingalarpar.png',
    px = 69,
    py = 93,
})

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

SMODS.Joker({
    key = 'maingalarpar',
    atlas = 'maingalarpar',
    pos = { x = 0, y = 0 },
    name = 'Maingalarpar',
    rarity = 3,
    cost = 8,

    config = { extra = { mult = 1 } },

    loc_txt = {
        name = 'Maingalarpar',
        text = {
            "Gains {X:mult,C:white}X0.2{} Mult for every {C:blue}Play{} or {C:red}Discard{}",
            "Resets at end of round",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { format_xmult(card.ability.extra.mult) } }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
    if context.before and not context.blueprint then
        local has_heart = false
        for _, c in ipairs(context.full_hand) do
            if c:is_suit("Hearts") then
                has_heart = true
                break
            end
        end
        card.ability.extra.mult = card.ability.extra.mult + (has_heart and 0.6 or 0.2)
    end

    if context.pre_discard and not context.blueprint then
        card.ability.extra.mult = card.ability.extra.mult + 0.2
    end

    if context.joker_main then
        return {
            Xmult_mod = card.ability.extra.mult,
            message = 'X' .. format_xmult(card.ability.extra.mult), 
        }
    end

    if context.end_of_round and not context.repetition and not context.individual then
        card.ability.extra.mult = 1
        return { message = "Reset!" }
    end
end,
})
