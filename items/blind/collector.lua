SMODS.Atlas({
    key = 'blind_collector',
    path = 'blind_collector.png',
    px = 34,
    py = 34,
})

local function collector_is_uncommon_joker(card)
    return card
        and card.area == G.jokers
        and card.ability
        and card.ability.set == 'Joker'
        and card.config
        and card.config.center
        and card.config.center.rarity == 2
end

SMODS.Blind({
    key = 'collector',
    atlas = 'blind_collector',
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 80, showdown = false },
    boss_colour = HEX('ed5249'),
    dollars = 5,
    mult = 1.75,
    debuff = {},

    loc_txt = {
        name = 'The Collector',
        text = {
            'Uncommon Jokers',
            'are debuffed',
        }
    },

    recalc_debuff = function(self, card, from_blind)
        if self.disabled then
            return nil
        end

        if collector_is_uncommon_joker(card) then
            return true
        end

        return nil
    end,

    disable = function(self)
        if not G or not G.jokers or not G.jokers.cards then
            return
        end

        for _, joker in ipairs(G.jokers.cards) do
            if collector_is_uncommon_joker(joker) and joker.debuff then
                joker:set_debuff(false)
            end
        end
    end,
})
