Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local VLAD_CENTER_KEY = 'j_tk9g_vlad'

local function has_vlad()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and joker.config.center.key == VLAD_CENTER_KEY
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

function AG.unlock_dear_sweet_music()
    if not has_vlad() then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'dear_sweet_music' })
        return
    end

    if unlock_achievement then
        unlock_achievement('dear_sweet_music')
    end
end

SMODS.Achievement({
    key = 'dear_sweet_music',
    loc_txt = {
        name = 'Dear Sweet Precious Music',
        description = {
            "Destroy the Cherished Vinyl",
            "in front of its owner",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'dear_sweet_music'
    end,
})
