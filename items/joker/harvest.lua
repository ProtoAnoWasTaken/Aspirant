SMODS.Atlas({
    key = 'harvest',
    path = 'harvest.png',
    px = 69,
    py = 93,
})

local TARGET_ENHANCEMENTS = {
    'm_gold',
    'm_steel',
    'm_stone',
}

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    local gain = (card.ability and card.ability.extra and card.ability.extra.gain) or 0.1
    return (Aspirant and Aspirant.food and Aspirant.food.scale_value) and Aspirant.food.scale_value(card, gain) or gain
end

local function format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

local function get_harvest_targets()
    local targets = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card and not playing_card.getting_sliced then
            for _, enhancement_key in ipairs(TARGET_ENHANCEMENTS) do
                if SMODS.has_enhancement(playing_card, enhancement_key) then
                    targets[#targets + 1] = playing_card
                    break
                end
            end
        end
    end

    return targets
end

local function harvest_random_enhancement(card)
    local targets = get_harvest_targets()
    local target = #targets > 0 and pseudorandom_element(targets, pseudoseed('ag_harvest')) or nil

    if not target then
        return false
    end

    target:set_ability(G.P_CENTERS.c_base, nil, true)
    target:juice_up()

    card.ability.extra.xmult = get_xmult(card) + get_gain(card)

    return true
end

SMODS.Joker({
    key = 'harvest',
    atlas = 'harvest',
    pos = { x = 0, y = 0 },
    name = 'Harvest',
    rarity = 2,
    cost = 6,

    config = { extra = { xmult = 1, gain = 0.1 } },

    loc_txt = {
        name = 'Harvest',
        text = {
            "Every hand removes the {C:gold,T:m_gold}Gold{},",
            "{C:attention,T:m_steel}Steel{}, or {C:attention,T:m_stone}Stone{} enhancement",
            "from a random card in the {C:attention}full deck{}",
            "Gains {X:mult,C:white}X#2#{} Mult for every",
            "enhancement lost this way",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
        info_queue[#info_queue + 1] = G.P_CENTERS.m_steel
        info_queue[#info_queue + 1] = G.P_CENTERS.m_stone

        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
            }
        }
    end,

    unlocked = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            if harvest_random_enhancement(card) then
                return {
                    message = 'X' .. format_xmult(get_gain(card)),
                    colour = G.C.MULT,
                }
            end
        end

        if context.joker_main and Aspirant.joker_utils.compare_numbers(get_xmult(card), 'gt', 1) then
            return {
                Xmult_mod = get_xmult(card),
                message = 'X' .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
