SMODS.Atlas({
    key = 'blind_killer',
    path = 'blind_killer.png',
    px = 34,
    py = 34,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function card_is_in_list(target, cards)
    for _, card in ipairs(cards or {}) do
        if card == target then
            return true
        end
    end

    return false
end

local function get_unplayed_held_cards()
    local held_cards = {}
    local highlighted = G and G.hand and G.hand.highlighted or {}

    for _, playing_card in ipairs((G and G.hand and G.hand.cards) or {}) do
        if playing_card
            and not playing_card.removed
            and not playing_card.getting_sliced
            and not card_is_in_list(playing_card, highlighted)
        then
            held_cards[#held_cards + 1] = playing_card
        end
    end

    return held_cards
end

local function should_destroy_held_card()
    local numerator = G and G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1

    if SMODS and SMODS.pseudorandom_probability then
        return SMODS.pseudorandom_probability(
            G and G.GAME and G.GAME.blind or nil,
            'ag_blind_killer_destroy',
            numerator,
            6,
            'ag_blind_killer_destroy'
        )
    end

    return pseudorandom('ag_blind_killer_destroy') < (numerator / 3)
end

local function try_destroy_random_unplayed_card()
    local targets = get_unplayed_held_cards()
    local target = #targets > 0 and pseudorandom_element(targets, pseudoseed('ag_blind_killer_target')) or nil

    if not target or not should_destroy_held_card() then
        return false
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            if not target or target.removed or target.getting_sliced then
                return true
            end

            if AG_UTIL.destroy_card then
                AG_UTIL.destroy_card(target, {
                    colours = { G.C.RED },
                    delay = 0,
                })
            else
                target.getting_sliced = true
                target:start_dissolve({ G.C.RED }, nil, 1.6)
            end

            card_eval_status_text(target, 'extra', nil, nil, nil, {
                message = 'Destroyed!',
                colour = G.C.RED,
            })

            return true
        end,
    }))

    return true
end

SMODS.Blind({
    key = 'killer',
    atlas = 'blind_killer',
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 80, showdown = false },
    boss_colour = HEX('f03464'),
    dollars = 5,
    mult = 1.75,
    debuff = {},
    in_pool = function()
        return not (Aspirant and Aspirant.is_showdown_ante and Aspirant.is_showdown_ante())
    end,

    loc_txt = {
        name = 'The Killer',
        text = {
            '1 in 3 chance to destroy',
            'a card held in hand',
        }
    },

    press_play = function(self)
        if self.disabled or not G or not G.E_MANAGER then
            return
        end

        try_destroy_random_unplayed_card()
    end,
})
