Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local ANGLER_CENTER_KEY = 'j_tk9g_angler'

local function has_angler()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and joker.config.center.key == ANGLER_CENTER_KEY
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

function AG.unlock_theovectivorous()
    if not has_angler() then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'theovectivorous' })
        return
    end

    if unlock_achievement then
        unlock_achievement('theovectivorous')
    end
end

SMODS.Achievement({
    key = 'theovectivorous',
    loc_txt = {
        name = "Theovectivorous",
        description = {
            "Jonah and the Whale",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'theovectivorous'
    end,
})
