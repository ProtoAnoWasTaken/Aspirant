SMODS.Atlas({
    key = 'blind_doctor',
    path = 'blind_doctor.png',
    px = 34,
    py = 34,
})

local function doctor_is_playing_card(card)
    if not card or not card.ability then
        return false
    end

    if card.ability.set == 'Default' or card.ability.set == 'Enhanced' then
        return true
    end

    if card.base and (card.base.suit or card.base.value or card.base.id) then
        return true
    end

    local center = card.config and card.config.center
    if center == G.P_CENTERS.c_base then
        return true
    end

    return card.config
        and card.config.card
        and card.config.card ~= G.P_CARDS.empty
        and card.config.card.key ~= nil
end

local function doctor_has_enhancement(card)
    local center = card and card.config and card.config.center
    return center and center.set == 'Enhanced'
end

local function doctor_has_edition(card)
    return card and card.edition ~= nil
end

local function doctor_debuffs_card(card)
    return doctor_is_playing_card(card)
        and (doctor_has_edition(card) or doctor_has_enhancement(card))
end

SMODS.Blind({
    key = 'doctor',
    atlas = 'blind_doctor',
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 80, showdown = false },
    boss_colour = HEX('52bdff'),
    dollars = 5,
    mult = 1.75,
    debuff = {},

    loc_txt = {
        name = 'The Doctor',
        text = {
            'Playing cards with editions',
            'or enhancements are debuffed',
        }
    },

    recalc_debuff = function(self, card, from_blind)
        if self.disabled then
            return nil
        end

        if doctor_debuffs_card(card) then
            return true
        end

        return nil
    end,

    disable = function(self)
        if not G or not G.playing_cards then
            return
        end

        for _, playing_card in ipairs(G.playing_cards) do
            if doctor_debuffs_card(playing_card) and playing_card.debuff then
                playing_card:set_debuff(false)
            end
        end
    end,
})
