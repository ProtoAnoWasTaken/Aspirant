SMODS.Atlas({
    key = 'gelwell',
    path = 'gelwell.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local SUITS = {
    'Spades',
    'Hearts',
    'Clubs',
    'Diamonds',
}

local function get_extra(card)
    if not card.ability then
        card.ability = {}
    end

    card.ability.extra = card.ability.extra or {}
    return card.ability.extra
end

local function through_solid_ground_is_unlocked()
    if G and G.ACHIEVEMENTS and G.ACHIEVEMENTS.through_solid_ground then
        return G.ACHIEVEMENTS.through_solid_ground.earned or false
    end

    return G
        and G.SETTINGS
        and G.SETTINGS.ACHIEVEMENTS_EARNED
        and G.SETTINGS.ACHIEVEMENTS_EARNED.through_solid_ground
        or false
end

local function get_played_suits(context)
    local seen = {}
    local suits = {}

    for _, played_card in ipairs(context and context.full_hand or {}) do
        if played_card and not played_card.debuff then
            for _, suit in ipairs(SUITS) do
                if played_card:is_suit(suit) and not seen[suit] then
                    seen[suit] = true
                    suits[#suits + 1] = suit
                end
            end
        end
    end

    return suits
end

local function get_played_enhancements(context)
    local seen = {}
    local enhancements = {}

    for _, played_card in ipairs(context and context.full_hand or {}) do
        local center = played_card and played_card.config and played_card.config.center
        local enhancement_key = center and center.set == 'Enhanced' and center.key or nil

        if enhancement_key and not seen[enhancement_key] then
            seen[enhancement_key] = true
            enhancements[#enhancements + 1] = enhancement_key
        end
    end

    return enhancements
end

local function roll_effects(card, context)
    local extra = get_extra(card)
    local played_suits = get_played_suits(context)
    local played_enhancements = get_played_enhancements(context)

    extra.did_nothing = SMODS.pseudorandom_probability(card, 'ag_gelwell_nope', 1, 3, 'ag_gelwell_nope')
    extra.active_suit = nil
    extra.active_enhancement = nil

    if extra.did_nothing then
        return {
            message = 'Nope!',
            colour = G.C.RED,
        }
    end

    if #played_suits > 0
        and SMODS.pseudorandom_probability(card, 'ag_gelwell_suit', 1, 3, 'ag_gelwell_suit')
    then
        extra.active_suit = pseudorandom_element(played_suits, pseudoseed('ag_gelwell_suit_choice'))
    end

    if #played_enhancements > 0
        and SMODS.pseudorandom_probability(card, 'ag_gelwell_enhancement', 1, 3, 'ag_gelwell_enhancement')
    then
        extra.active_enhancement = pseudorandom_element(played_enhancements, pseudoseed('ag_gelwell_enhancement_choice'))
    end

    if extra.active_suit or extra.active_enhancement then
        return {
            message = 'Again!',
            colour = G.C.ATTENTION,
        }
    end
end

local function get_repetitions(card, context)
    local extra = get_extra(card)
    local repetitions = 0

    if extra.did_nothing or not context or not context.other_card then
        return 0
    end

    if extra.active_suit and context.other_card:is_suit(extra.active_suit) then
        repetitions = repetitions + 1
    end

    if extra.active_enhancement and SMODS.has_enhancement(context.other_card, extra.active_enhancement) then
        repetitions = repetitions + 1
    end

    return repetitions
end

SMODS.Joker({
    key = 'gelwell',
    atlas = 'gelwell',
    pos = { x = 0, y = 0 },
    name = 'Gel Well',
    rarity = 3,
    cost = 8,

    config = { extra = { active_suit = nil, active_enhancement = nil, did_nothing = false } },

    loc_txt = {
        name = 'Gel Well',
        text = {
            "{C:green}1 in 3{} chance to retrigger all played cards",
            "of a played {C:attention}suit{}",
            "{C:green}1 in 3{} chance to retrigger all played cards",
            "of a played {C:attention}enhancement{}",
            "{C:green}1 in 3{} chance to do nothing",
        }
    },

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_achievement_through_solid_ground', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return through_solid_ground_is_unlocked()
    end,

    calculate = function(self, card, context)
        if context.before
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            return roll_effects(card, context)
        end

        if context.repetition
            and context.cardarea == G.play
            and not context.blueprint
            and not card.getting_sliced
        then
            local repetitions = get_repetitions(card, context)

            if repetitions > 0 then
                return {
                    repetitions = repetitions,
                    message = 'Again!',
                    colour = G.C.ATTENTION,
                }
            end
        end

        if context.after
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
        then
            local extra = get_extra(card)
            extra.active_suit = nil
            extra.active_enhancement = nil
            extra.did_nothing = false
        end
    end,
})
