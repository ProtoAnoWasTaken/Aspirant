local Aspirant = rawget(_G, 'Aspirant') or {}
local AG = Aspirant

local TOMBFEEDER_CENTER_KEY = 'j_tk9g_tombfeeder'
local REQUIRED_ENHANCEMENTS = { 'm_bonus', 'm_mult', 'm_gold', 'm_steel' }

local function has_tombfeeder()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and joker.config.center.key == TOMBFEEDER_CENTER_KEY
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

local function held_hand_has_diverse_cards()
    if not G or not G.hand or not G.hand.cards then
        return false
    end

    for _, enhancement_key in ipairs(REQUIRED_ENHANCEMENTS) do
        local found = false

        for _, held_card in ipairs(G.hand.cards) do
            if held_card and SMODS.has_enhancement(held_card, enhancement_key) then
                found = true
                break
            end
        end

        if not found then
            return false
        end
    end

    return true
end

function AG.unlock_bejeweled()
    if not has_tombfeeder() or not held_hand_has_diverse_cards() then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'bejeweled' })
        return
    end

    if unlock_achievement then
        unlock_achievement('bejeweled')
    end
end

SMODS.Achievement({
    key = 'bejeweled',
    loc_txt = {
        name = 'Bejeweled',
        description = {
            'Present diverse cards',
            'to the Tombfeeder',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'bejeweled'
    end,
})
